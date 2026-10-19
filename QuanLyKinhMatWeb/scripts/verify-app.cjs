const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const credentials = require('./qa-credentials.cjs').getQaCredentials();
const { chromium } = require('./qa-browser.cjs');
const base = process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5088';
const directory = path.resolve(__dirname, '../artifacts');
fs.mkdirSync(directory, { recursive: true });
const tag = 'QA' + Date.now();
const state = { tag, createdAt: new Date().toISOString(), fixtures: { products: [], customers: [], suppliers: [], catalogs: [], users: [], sales: [], purchases: [] }, tests: [], browserErrors: [], mobile: [] };
const output = path.join(directory, tag + '.json');
function save() { fs.writeFileSync(output, JSON.stringify(state, null, 2)); }
function check(name, condition, details = '') { state.tests.push({ name, pass: !!condition, details }); save(); assert.ok(condition, name + ' ' + details); }
function fixture(type, value) { state.fixtures[type].push(value); save(); return value; }
async function login(browser, userName, password) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  page.on('pageerror', error => { state.browserErrors.push(error.message); save(); });
  await page.goto(base + '/account/login');
  await page.locator('input[name="UserName"]').fill(userName);
  await page.locator('input[name="Password"]').fill(password);
  await page.locator('button[type="submit"]').click();
  await page.waitForURL(base + '/');
  await page.waitForFunction(() => !!window.KINHMAT_BOOTSTRAP && !!document.querySelector('#main h1'));
  const user = await page.evaluate(() => window.KINHMAT_BOOTSTRAP);
  return { context, page, user };
}
async function api(session, method, endpoint, body, token = true) {
  const response = await session.context.request.fetch(base + endpoint, {
    method, headers: token ? { 'X-CSRF-TOKEN': session.user.csrfToken } : {},
    ...(body === undefined ? {} : { data: body })
  });
  let value = null; const text = await response.text();
  if (text) { try { value = JSON.parse(text); } catch { value = text.slice(0, 300); } }
  return { status: response.status(), value };
}
async function ok(session, method, endpoint, body, expected = 200) {
  const response = await api(session, method, endpoint, body);
  assert.equal(response.status, expected, method + ' ' + endpoint + ': ' + JSON.stringify(response.value));
  return response.value;
}
(async () => {
  let browser;
  try {
    browser = await chromium.launch({ headless: true, channel: 'msedge' });
    const anonymous = await browser.newContext();
    check('Anonymous API requires login', (await anonymous.request.get(base + '/api/products')).status() === 401);
    const admin = await login(browser, credentials.userName, credentials.password);
    check('Admin login and bootstrap', admin.user.role === 'Admin');
    const catalog = await ok(admin, 'GET', '/api/catalogs');
    check('Five catalogs loaded from SQL', ['categories','brands','materials','colors','shapes'].every(key => Array.isArray(catalog[key])));
    const original = await ok(admin, 'GET', '/api/products');
    check('Original products loaded', original.length >= 8);
    check('CSRF token required for mutations', (await api(admin, 'POST', '/api/customers', { name: tag }, false)).status === 400);
    check('Phone without digits rejected', (await api(admin, 'POST', '/api/customers', { name: tag, phone: '--------' })).status === 400);
    check('Customer SQL length enforced', (await api(admin, 'POST', '/api/customers', { name: 'x'.repeat(101) })).status === 400);
    const customer = fixture('customers', await ok(admin, 'POST', '/api/customers', { name: tag + " O'Brien", phone: '0901234567', email: 'qa@example.test', address: 'Địa chỉ kiểm thử', note: 'Dữ liệu tạo bởi kiểm thử tự động' }));
    const supplier = fixture('suppliers', await ok(admin, 'POST', '/api/suppliers', { name: tag, phone: '0901234568', email: 'supplier@example.test', address: 'Địa chỉ kiểm thử' }));
    const newCategory = fixture('catalogs', { type: 'categories', ...await ok(admin, 'POST', '/api/catalogs/categories', { name: tag }) });
    await ok(admin, 'PUT', '/api/catalogs/categories/' + newCategory.id, { name: tag + ' sửa' });
    check('Catalog create and update', (await ok(admin, 'GET', '/api/catalogs')).categories.some(row => row.id === newCategory.id && row.name.endsWith('sửa')));
    const productInput = { name: tag, categoryId: newCategory.id, brandId: catalog.brands[0]?.id || null, cost: 100000, price: 110000, stock: 20, active: true, description: 'Sản phẩm kiểm thử' };
    const product = fixture('products', await ok(admin, 'POST', '/api/products', productInput));
    const getProduct = async () => ok(admin, 'GET', '/api/products/' + product.id);
    check('Product saved to SQL', product.stock === 20 && product.price === 110000);
    const purchaseInput = { token: randomUUID(), supplierId: supplier.id, items: [{ productId: product.id, quantity: 5, unitPrice: 120000, discount: 5 }] };
    const purchase = fixture('purchases', { ...await ok(admin, 'POST', '/api/purchases', purchaseInput), token: purchaseInput.token });
    check('Purchase total includes discount', purchase.total === 570000);
    check('Purchase updates stock and price', (await getProduct()).stock === 25 && (await getProduct()).price === 132000);
    const stale = await api(admin, 'POST', '/api/sales', { token: randomUUID(), customerId: customer.id, items: [{ productId: product.id, quantity: 1, unitPrice: 110000, discount: 0 }] });
    check('Stale sale price rejected without stock change', stale.status === 409 && (await getProduct()).stock === 25);
    const saleInput = { token: randomUUID(), customerId: customer.id, items: [{ productId: product.id, quantity: 3, unitPrice: 132000, discount: 10 }] };
    const sale = fixture('sales', { ...await ok(admin, 'POST', '/api/sales', saleInput), token: saleInput.token });
    check('Sale total and stock correct', sale.total === 356400 && (await getProduct()).stock === 22);
    const repeated = await ok(admin, 'POST', '/api/sales', saleInput);
    check('Repeated token returns same invoice once', repeated.id === sale.id && (await getProduct()).stock === 22);
    check('Same token with changed payload rejected', (await api(admin, 'POST', '/api/sales', { ...saleInput, items: [{ ...saleInput.items[0], quantity: 2 }] })).status === 409);
    const excessive = await api(admin, 'POST', '/api/sales', { token: randomUUID(), items: [{ productId: product.id, quantity: 1000, unitPrice: 132000, discount: 0 }] });
    check('Overselling rejected atomically', excessive.status === 409 && (await getProduct()).stock === 22);
    check('Referenced product cannot be deleted', (await api(admin, 'DELETE', '/api/products/' + product.id)).status === 409);
    check('Referenced customer cannot be deleted', (await api(admin, 'DELETE', '/api/customers/' + customer.id)).status === 409);
    check('Referenced catalog cannot be deleted', (await api(admin, 'DELETE', '/api/catalogs/categories/' + newCategory.id)).status === 409);
    const concurrentInput = { token: randomUUID(), customerId: customer.id, items: [{ productId: product.id, quantity: 1, unitPrice: 132000, discount: 0 }] };
    const concurrent = await Promise.all([ok(admin, 'POST', '/api/sales', concurrentInput), ok(admin, 'POST', '/api/sales', concurrentInput)]);
    fixture('sales', { ...concurrent[0], token: concurrentInput.token });
    check('Concurrent duplicate submits subtract stock once', concurrent[0].id === concurrent[1].id && (await getProduct()).stock === 21);
    await ok(admin, 'POST', '/api/sales/' + concurrent[0].id + '/cancel', {});
    await ok(admin, 'POST', '/api/sales/' + sale.id + '/cancel', {});
    await ok(admin, 'POST', '/api/sales/' + sale.id + '/cancel', {});
    check('Sale cancellation restores stock once', (await getProduct()).stock === 25);
    await ok(admin, 'POST', '/api/purchases/' + purchase.id + '/cancel', {});
    check('Purchase cancellation restores original stock and price', (await getProduct()).stock === 20 && (await getProduct()).price === 110000);
    const scarce = fixture('products', await ok(admin, 'POST', '/api/products', { ...productInput, name: tag + ' last-unit', stock: 1 }));
    const finalUnitRequests = [randomUUID(), randomUUID()].map(token => ({ token, items: [{ productId: scarce.id, quantity: 1, unitPrice: 110000, discount: 0 }] }));
    const finalUnitResults = await Promise.all(finalUnitRequests.map(input => api(admin, 'POST', '/api/sales', input)));
    check('Two buyers compete for last unit: exactly one succeeds', finalUnitResults.filter(result => result.status === 200).length === 1 && finalUnitResults.filter(result => result.status === 409).length === 1);
    const winnerIndex = finalUnitResults.findIndex(result => result.status === 200);
    const lastUnitSale = fixture('sales', { ...finalUnitResults[winnerIndex].value, token: finalUnitRequests[winnerIndex].token });
    check('Last-unit concurrency never makes stock negative', (await ok(admin, 'GET', '/api/products/' + scarce.id)).stock === 0);
    await ok(admin, 'POST', '/api/sales/' + lastUnitSale.id + '/cancel', {});
    const atomicBefore = await getProduct();
    const multiLineError = await api(admin, 'POST', '/api/sales', { token: randomUUID(), items: [{ productId: product.id, quantity: 1, unitPrice: 110000, discount: 0 }, { productId: scarce.id, quantity: 2, unitPrice: 110000, discount: 0 }] });
    check('Multi-line transaction rolls back when one product lacks stock', multiLineError.status === 409 && (await getProduct()).stock === atomicBefore.stock);
    const insufficientPurchaseInput = { token: randomUUID(), supplierId: supplier.id, items: [{ productId: scarce.id, quantity: 2, unitPrice: 120000, discount: 0 }] };
    const insufficientPurchase = fixture('purchases', { ...await ok(admin, 'POST', '/api/purchases', insufficientPurchaseInput), token: insufficientPurchaseInput.token });
    const consumeInput = { token: randomUUID(), items: [{ productId: scarce.id, quantity: 3, unitPrice: 132000, discount: 0 }] };
    const consumeSale = fixture('sales', { ...await ok(admin, 'POST', '/api/sales', consumeInput), token: consumeInput.token });
    check('Cannot cancel purchase when its stock has been consumed', (await api(admin, 'POST', '/api/purchases/' + insufficientPurchase.id + '/cancel', {})).status === 409 && (await ok(admin, 'GET', '/api/products/' + scarce.id)).stock === 0);
    await ok(admin, 'POST', '/api/sales/' + consumeSale.id + '/cancel', {});
    await ok(admin, 'POST', '/api/purchases/' + insufficientPurchase.id + '/cancel', {});
    const accounts = await ok(admin, 'GET', '/api/users');
    check('User API never exposes password hash', accounts.every(user => !('passwordHash' in user) && !('password' in user)));
    check('Last active admin protected', (await api(admin, 'PUT', '/api/users/' + admin.user.userId, { displayName: admin.user.displayName, role: 'Staff', isActive: true })).status === 409);
    const qaUser = fixture('users', await ok(admin, 'POST', '/api/users', { userName: tag.toLowerCase(), displayName: tag + ' nhân viên', password: 'KiemThu@12345', role: 'Staff' }));
    const staff = await login(browser, qaUser.userName, 'KiemThu@12345');
    check('Staff has separate identity and role', staff.user.role === 'Staff' && staff.user.employeeId === qaUser.employeeId && staff.user.userId !== admin.user.userId);
    check('Staff cannot create products', (await api(staff, 'POST', '/api/products', productInput)).status === 403);
    check('Staff cannot view purchases or users', (await api(staff, 'GET', '/api/purchases')).status === 403 && (await api(staff, 'GET', '/api/users')).status === 403);
    const staffSaleInput = { token: randomUUID(), items: [{ productId: product.id, quantity: 1, unitPrice: 110000, discount: 0 }] };
    const staffSale = fixture('sales', { ...await ok(staff, 'POST', '/api/sales', staffSaleInput), token: staffSaleInput.token });
    check('Invoice employee comes from current authenticated user', staffSale.employeeId === qaUser.employeeId);
    check('Staff cannot cancel invoices', (await api(staff, 'POST', '/api/sales/' + staffSale.id + '/cancel', {})).status === 403);
    await ok(admin, 'POST', '/api/sales/' + staffSale.id + '/cancel', {});
    check('Incorrect current password rejected', (await api(staff, 'POST', '/api/account/password', { currentPassword: 'incorrect', newPassword: 'KiemThuMoi@12345', confirmPassword: 'KiemThuMoi@12345' })).status === 400);
    await ok(staff, 'POST', '/api/account/password', { currentPassword: 'KiemThu@12345', newPassword: 'KiemThuMoi@12345', confirmPassword: 'KiemThuMoi@12345' });
    check('Password change keeps current session valid', (await api(staff, 'GET', '/api/customers')).status === 200);
    await ok(admin, 'PUT', '/api/users/' + qaUser.id, { displayName: qaUser.displayName, role: 'Staff', isActive: false });
    check('Disabling account revokes existing session', (await api(staff, 'GET', '/api/customers')).status === 401);
    const routes = ['overview','sale','import','products','customers','suppliers','catalogs','search','reports','users'];
    for (const route of routes) {
      await admin.page.evaluate(hash => { location.hash = hash; }, route);
      await admin.page.waitForFunction(route => document.querySelector('.nav-link.active')?.getAttribute('href') === '#' + route && document.querySelector('#main h1'), route);
      check('UI route ' + route, !(await admin.page.locator('#main h1').innerText()).includes('Chưa tải'));
    }
    await admin.page.evaluate(() => { location.hash = 'overview'; });
    await admin.page.waitForTimeout(200);
    await admin.page.screenshot({ path: path.join(directory, 'dashboard-desktop.png'), fullPage: true });
    // Reproduce and verify the original stale-price UI issue without changing seed products.
    await admin.page.evaluate(() => { location.hash = 'sale'; });
    await admin.page.locator(`[data-action="add-cart"][data-id="${product.id}"]`).click();
    await ok(admin, 'PUT', '/api/products/' + product.id, { ...productInput, price: 115000, stock: 20 });
    await admin.page.locator('[data-action="confirm-invoice"]').click();
    await admin.page.waitForFunction(() => document.querySelector('#cart [data-cart-total]')?.textContent.includes('115.000'));
    check('UI requires reconfirmation after price changed', !(await admin.page.locator('#modal').evaluate(element => element.open)));
    await admin.page.locator('[data-action="confirm-invoice"]').click();
    await admin.page.locator('#invoice-form').waitFor();
    check('UI confirmation refreshes changed price', (await admin.page.locator('#invoice-form').innerText()).includes('115.000'));
    await admin.page.locator('#close-modal').click();
    await ok(admin, 'PUT', '/api/products/' + product.id, productInput);
    // Skip link must keep the current route.
    await admin.page.evaluate(() => { location.hash = 'customers'; });
    await admin.page.locator('#skip-link').focus(); await admin.page.keyboard.press('Enter');
    check('Skip link preserves route', await admin.page.evaluate(() => location.hash === '#customers'));
    await admin.page.setViewportSize({ width: 390, height: 844 });
    for (const route of ['overview','products','sale','customers','reports']) {
      await admin.page.evaluate(hash => { location.hash = hash; }, route); await admin.page.waitForTimeout(250);
      const width = await admin.page.evaluate(() => ({ viewport: innerWidth, content: document.documentElement.scrollWidth }));
      state.mobile.push({ route, ...width }); save();
      check('Mobile width ' + route, width.content <= width.viewport + 3, JSON.stringify(width));
    }
    await admin.page.evaluate(() => { location.hash = 'overview'; }); await admin.page.waitForTimeout(250);
    await admin.page.screenshot({ path: path.join(directory, 'dashboard-mobile.png'), fullPage: true });
    check('No JavaScript errors in exercised UI', state.browserErrors.length === 0, state.browserErrors.join('; '));
    state.completed = true; save();
  } catch (error) { state.error = error.stack; save(); process.stderr.write(error.stack + '\n'); process.exitCode = 1; }
  finally { if (browser) await browser.close(); process.stdout.write(JSON.stringify({ output, tests: state.tests.length, passed: state.tests.filter(test => test.pass).length, completed: !!state.completed }) + '\n'); }
})();
