const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require('./qa-browser.cjs');
const base = process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5080';
const password = process.env.KINHMAT_EMPLOYEE_TEST_PASSWORD;
if (!password) throw new Error('Set KINHMAT_EMPLOYEE_TEST_PASSWORD for this QA run.');
const result = { recordedAt: new Date().toISOString(), tests: [], browserErrors: [] };
function check(name, condition) { result.tests.push({ name, pass: !!condition }); assert.ok(condition, name); }
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  try {
    for (const id of [1, 2, 3]) {
      const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
      try {
        const page = await context.newPage();
        page.on('pageerror', error => result.browserErrors.push(error.message));
        await page.goto(base + '/account/login');
        check('Login form labels employee ID', (await page.locator('.login-form').innerText()).includes('Mã nhân viên'));
        await page.locator('[name="UserName"]').fill(String(id));
        await page.locator('[name="Password"]').fill(password);
        await page.locator('button[type="submit"]').click();
        await page.waitForURL(base + '/');
        await page.waitForFunction(() => window.KINHMAT_BOOTSTRAP && document.querySelector('#main').getAttribute('aria-busy') === 'false');
        const user = await page.evaluate(() => window.KINHMAT_BOOTSTRAP);
        check('Employee ' + id + ' uses the original employee identity', user.employeeId === id);
        check('Employee ' + id + ' has its mapped role', user.role === (id === 1 ? 'Admin' : 'Staff'));
        check('Employee ' + id + ' reads business data', (await context.request.get(base + '/api/products')).status() === 200);
        const users = await context.request.get(base + '/api/users');
        check('Employee ' + id + ' account administration permission', users.status() === (id === 1 ? 200 : 403));
        if (id === 1) {
          const rows = await users.json();
          check('All three imported accounts link to matching employee IDs', [1, 2, 3].every(employee => rows.some(row => row.userName === String(employee) && row.employeeId === employee)));
          check('Account API contains no password or hash fields', rows.every(row => !('passwordHash' in row) && !('password' in row)));
          check('Only the three employee accounts remain', rows.length === 3 && rows.every(row => ['1', '2', '3'].includes(row.userName)));
          await page.evaluate(() => { location.hash = 'users'; });
          await page.waitForFunction(() => document.querySelector('#main').getAttribute('aria-busy') === 'false' && document.querySelectorAll('#main tbody tr').length === 3);
          check('Accounts screen shows three employee rows and no demo names', await page.locator('#main tbody tr').count() === 3 && !/\badmin\b|\bnhanvien\b/.test(await page.locator('#main tbody').innerText()));
          const previewDirectory = path.resolve(__dirname, '../artifacts/previews');
          fs.mkdirSync(previewDirectory, { recursive: true });
          await page.screenshot({ path: path.join(previewDirectory, 'users-after-demo-removal.png'), fullPage: true });
        }
        await context.request.post(base + '/account/logout', { headers: { 'X-CSRF-TOKEN': user.csrfToken } });
        check('Employee ' + id + ' logout removes authentication', (await context.request.get(base + '/api/products')).status() === 401);
      } finally { await context.close(); }
    }
    const anonymous = await browser.newContext();
    try {
      const page = await anonymous.newPage();
      await page.goto(base + '/account/login');
      await page.locator('[name="UserName"]').fill('1');
      await page.locator('[name="Password"]').fill('Incorrect-QA-password');
      await page.locator('button[type="submit"]').click();
      await page.locator('.login-errors').filter({ hasText: 'không đúng' }).waitFor();
      check('Wrong password for employee ID is rejected', (await anonymous.request.get(base + '/api/products')).status() === 401);
    } finally { await anonymous.close(); }
    for (const [name, oldPassword] of [['admin', 'Admin@12345'], ['nhanvien', 'NhanVien@12345']]) {
      const context = await browser.newContext();
      try {
        const page = await context.newPage();
        await page.goto(base + '/account/login');
        await page.locator('[name="UserName"]').fill(name);
        await page.locator('[name="Password"]').fill(oldPassword);
        await page.locator('button[type="submit"]').click();
        await page.locator('.login-errors').filter({ hasText: 'không đúng' }).waitFor();
        check('Removed demo ' + name + ' cannot authenticate', (await context.request.get(base + '/api/products')).status() === 401);
      } finally { await context.close(); }
    }
    check('No uncaught browser errors', result.browserErrors.length === 0);
    result.completed = true;
  } catch (error) { result.error = error.message; process.exitCode = 1; }
  finally {
    await browser.close();
    const output = path.resolve(__dirname, '../docs/employee-login-check.json');
    fs.writeFileSync(output, JSON.stringify(result, null, 2));
    console.log(JSON.stringify({ output, passed: result.tests.filter(test => test.pass).length, total: result.tests.length, completed: !!result.completed }));
  }
})();
