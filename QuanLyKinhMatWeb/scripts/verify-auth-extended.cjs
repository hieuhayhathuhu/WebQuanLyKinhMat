const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const credentials = require('./qa-credentials.cjs').getQaCredentials();
const { chromium } = require('./qa-browser.cjs');

// Run after the other suites finish: the server limits all login attempts to 12/minute.
// This suite performs exactly seven login POSTs and never changes existing accounts.
const base = (process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5080').replace(/\/$/, '');
const directory = path.resolve(__dirname, '../artifacts');
fs.mkdirSync(directory, { recursive: true });
const tag = 'QA' + Date.now();
const state = {
  tag, suite: 'auth-extended', createdAt: new Date().toISOString(),
  fixtures: { products: [], customers: [], suppliers: [], catalogs: [], users: [], sales: [], purchases: [] },
  tests: [], browserErrors: [], loginPosts: 0
};
const output = path.join(directory, tag + '.json');
const staffPassword = 'KiemThu@12345';
const changedPassword = 'KiemThuMoi@12345';
const loginTimes = [];
const save = () => fs.writeFileSync(output, JSON.stringify(state, null, 2));
function check(name, condition, details = '') {
  state.tests.push({ name, pass: !!condition, details }); save();
  assert.ok(condition, name + (details ? ': ' + details : ''));
}
function fixture(type, value) { state.fixtures[type].push(value); save(); return value; }
function sameRows(left, right) {
  const ordered = rows => [...rows].sort((a, b) => a.id - b.id);
  return JSON.stringify(ordered(left)) === JSON.stringify(ordered(right));
}
async function login(browser, userName, password, succeeds) {
  // Also protect against accidental additions that exceed eight POSTs per rolling minute.
  const now = Date.now();
  while (loginTimes.length && now - loginTimes[0] >= 60000) loginTimes.shift();
  if (loginTimes.length >= 8) throw new Error('Login budget exceeded; wait before rerunning this suite.');
  loginTimes.push(now); state.loginPosts++; save();
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  page.on('pageerror', error => { state.browserErrors.push(error.message); save(); });
  await page.goto(base + '/account/login');
  await page.locator('input[name="UserName"]').fill(userName);
  await page.locator('input[name="Password"]').fill(password);
  const posted = page.waitForResponse(response => response.request().method() === 'POST' && new URL(response.url()).pathname === '/account/login');
  await page.locator('button[type="submit"]').click();
  const response = await posted;
  if (response.status() === 429) throw new Error('Login rate limit reached; wait one minute after the previous suite.');
  if (succeeds) {
    assert.equal(response.status(), 302, 'Expected successful login redirect.');
    await page.waitForURL(base + '/');
    await page.waitForFunction(() => !!window.KINHMAT_BOOTSTRAP && !!document.querySelector('#main h1'));
    return { context, page, user: await page.evaluate(() => window.KINHMAT_BOOTSTRAP) };
  }
  await page.waitForLoadState('domcontentloaded');
  assert.equal(response.status(), 200, 'Rejected credentials must return the login form.');
  assert.equal(new URL(page.url()).pathname, '/account/login', 'Rejected credentials must stay on login.');
  const message = (await page.locator('.login-errors').innerText()).trim();
  const apiStatus = (await context.request.get(base + '/api/customers')).status();
  assert.equal(apiStatus, 401, 'Rejected credentials must not establish an API session.');
  await context.close();
  return { message, apiStatus };
}
async function api(session, method, endpoint, body, tokenMode = 'valid') {
  const headers = tokenMode === 'missing' ? {} : {
    'X-CSRF-TOKEN': tokenMode === 'wrong' ? 'not-a-valid-csrf-token' : session.user.csrfToken
  };
  const response = await session.context.request.fetch(base + endpoint, {
    method, headers, ...(body === undefined ? {} : { data: body })
  });
  let value = null;
  const bodyText = await response.text();
  if (bodyText) { try { value = JSON.parse(bodyText); } catch { /* Status is sufficient for HTML errors. */ } }
  return { status: response.status(), value };
}
async function ok(session, method, endpoint, body, expected = 200) {
  const result = await api(session, method, endpoint, body);
  // Do not print request/response bodies: credentials and cookies stay out of QA artifacts.
  assert.equal(result.status, expected, method + ' ' + endpoint + ' returned unexpected status.');
  return result.value;
}
async function anonymousHome(context) {
  const response = await context.request.get(base + '/', { maxRedirects: 0 });
  const location = response.headers().location;
  const redirected = location ? new URL(location, base) : null;
  return response.status() === 302 && redirected?.origin === new URL(base).origin && redirected.pathname === '/account/login';
}

(async () => {
  let browser;
  try {
    const target = new URL(base);
    check('Test target is a local server', ['localhost', '127.0.0.1', '[::1]'].includes(target.hostname));
    const settings = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../appsettings.json'), 'utf8').replace(/^\uFEFF/, ''));
    check('Project configuration targets the separate test copy', /(?:^|;)\s*(?:Database|Initial Catalog)\s*=\s*QuanLyKinhMatWeb\s*(?:;|$)/i.test(settings.ConnectionStrings?.Store || ''));
    browser = await chromium.launch({ headless: true, channel: 'msedge' });
    const anonymous = await browser.newContext();
    check('AU03 Anonymous home redirects to local login', await anonymousHome(anonymous));
    check('AU03 Anonymous API requires authentication', (await anonymous.request.get(base + '/api/customers')).status() === 401);
    await anonymous.close();

    const admin = await login(browser, credentials.userName, credentials.password, true);
    check('AU01 Admin authentication succeeds', admin.user.role === 'Admin');
    const qaUser = fixture('users', await ok(admin, 'POST', '/api/users', {
      userName: tag.toLowerCase(), displayName: tag + ' auth nhân viên', password: staffPassword, role: 'Staff'
    }));
    const unknown = await login(browser, tag.toLowerCase() + '-missing', staffPassword, false);
    check('AU02 Unknown username rejected without authentication', unknown.apiStatus === 401 && unknown.message.length > 0);
    const wrong = await login(browser, qaUser.userName, 'Incorrect@12345', false);
    check('AU02 Wrong password rejected without authentication', wrong.apiStatus === 401 && wrong.message.length > 0);
    check('AU02 Unknown user and wrong password use the same message', unknown.message === wrong.message);
    const staff = await login(browser, qaUser.userName, staffPassword, true);
    check('AU01 QA staff has an independent Staff identity', staff.user.role === 'Staff' && staff.user.userId === qaUser.id && staff.user.employeeId === qaUser.employeeId);

    const usersBefore = await ok(admin, 'GET', '/api/users');
    // The duplicate username remains safe if authorization regresses: it still cannot create an untracked account.
    const createAdmin = await api(staff, 'POST', '/api/users', {
      userName: qaUser.userName, displayName: qaUser.displayName, password: staffPassword, role: 'Admin'
    });
    check('AU05 Staff cannot POST an Admin account', createAdmin.status === 403);
    const promoteSelf = await api(staff, 'PUT', '/api/users/' + qaUser.id, {
      displayName: qaUser.displayName, role: 'Admin', isActive: true
    });
    check('AU05 Staff cannot PUT its own role to Admin', promoteSelf.status === 403);
    const promoteOther = await api(staff, 'PUT', '/api/users/' + admin.user.userId, {
      displayName: admin.user.displayName, role: 'Admin', isActive: true
    });
    check('AU05 Staff cannot PUT another account', promoteOther.status === 403);
    check('AU05 Denied account writes leave users unchanged', sameRows(usersBefore, await ok(admin, 'GET', '/api/users')));

    const customer = fixture('customers', await ok(admin, 'POST', '/api/customers', {
      name: tag + ' csrf customer', phone: '0901234567', email: 'auth-qa@example.test', address: 'Dữ liệu kiểm thử CSRF', note: 'Kiểm thử tự động'
    }));
    const customersBefore = await ok(admin, 'GET', '/api/customers');
    for (const method of ['POST', 'PUT', 'DELETE']) {
      for (const tokenMode of ['missing', 'wrong']) {
        const endpoint = '/api/customers' + (method === 'POST' ? '' : '/' + customer.id);
        const payload = method === 'DELETE' ? undefined : {
          name: tag + ' csrf unauthorized ' + tokenMode, phone: '0901234567', email: 'auth-qa@example.test', address: 'Không được ghi', note: 'Không được ghi'
        };
        const result = await api(admin, method, endpoint, payload, tokenMode);
        // Track any unexpected create before asserting, so failed runs can still be cleaned safely.
        if (method === 'POST' && result.status === 200 && result.value?.id) fixture('customers', result.value);
        check('SC01 ' + method + ' with ' + tokenMode + ' CSRF token rejected', result.status === 400);
        check('SC01 ' + method + ' with ' + tokenMode + ' CSRF leaves customer data unchanged', sameRows(customersBefore, await ok(admin, 'GET', '/api/customers')));
      }
    }

    const invalidPasswordInputs = [
      ['wrong current password', { currentPassword: 'Incorrect@12345', newPassword: changedPassword, confirmPassword: changedPassword }],
      ['mismatched confirmation', { currentPassword: staffPassword, newPassword: changedPassword, confirmPassword: 'Different@12345' }],
      ['short new password', { currentPassword: staffPassword, newPassword: 'short', confirmPassword: 'short' }]
    ];
    for (const [label, input] of invalidPasswordInputs) {
      check('AU06 Reject ' + label, (await api(staff, 'POST', '/api/account/password', input)).status === 400);
      check('AU06 ' + label + ' leaves the current session valid', (await api(staff, 'GET', '/api/customers')).status === 200);
    }

    // Copy the pre-change cookie into a separate context: no additional login POST is needed.
    const oldCookieContext = await browser.newContext({ storageState: await staff.context.storageState() });
    const previousSession = { context: oldCookieContext, user: { ...staff.user } };
    check('AU07 Other context is authenticated before password change', (await api(previousSession, 'GET', '/api/customers')).status === 200);
    await ok(staff, 'POST', '/api/account/password', {
      currentPassword: staffPassword, newPassword: changedPassword, confirmPassword: changedPassword
    });
    check('AU07 Password change keeps the initiating session valid', (await api(staff, 'GET', '/api/customers')).status === 200);
    check('AU07 Password change revokes the previous cookie in another context', (await api(previousSession, 'GET', '/api/customers')).status === 401);
    const oldPassword = await login(browser, qaUser.userName, staffPassword, false);
    check('AU07 Old password can no longer authenticate', oldPassword.apiStatus === 401);
    const fresh = await login(browser, qaUser.userName, changedPassword, true);
    check('AU07 New password authenticates the same Staff account', fresh.user.userId === qaUser.id && fresh.user.role === 'Staff');

    await ok(fresh, 'POST', '/account/logout', {});
    check('AU04 Logout removes API authentication', (await api(fresh, 'GET', '/api/customers')).status === 401);
    check('AU04 Logout makes home require login again', await anonymousHome(fresh.context));
    check('AU04 Logout does not terminate an independent active session', (await api(staff, 'GET', '/api/customers')).status === 200);

    await ok(admin, 'PUT', '/api/users/' + qaUser.id, { displayName: qaUser.displayName, role: 'Staff', isActive: false });
    check('AU02 Disabling QA account revokes its active session', (await api(staff, 'GET', '/api/customers')).status === 401);
    const disabled = await login(browser, qaUser.userName, changedPassword, false);
    check('AU02 Disabled user cannot log in with the correct password', disabled.apiStatus === 401 && disabled.message === wrong.message);
    const finalUser = (await ok(admin, 'GET', '/api/users')).find(row => row.id === qaUser.id);
    check('QA fixture is left disabled for controlled SQL cleanup', finalUser?.isActive === false && finalUser.role === 'Staff');
    check('Admin session remains valid and unchanged', (await api(admin, 'GET', '/api/users')).status === 200);
    check('Seven login POSTs stay below the server rate limit', state.loginPosts === 7);
    check('No JavaScript errors during auth checks', state.browserErrors.length === 0);
    await oldCookieContext.close();
    state.completed = true; save();
  } catch (error) {
    state.error = error.stack; save(); process.stderr.write(error.stack + '\n'); process.exitCode = 1;
  } finally {
    if (browser) await browser.close();
    process.stdout.write(JSON.stringify({ output, tests: state.tests.length, passed: state.tests.filter(test => test.pass).length, completed: !!state.completed, loginPosts: state.loginPosts }) + '\n');
  }
})();
