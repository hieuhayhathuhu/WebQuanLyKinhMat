const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const credentials = require('./qa-credentials.cjs').getQaCredentials();
const { chromium } = require('./qa-browser.cjs');

// Run against an already running, isolated test database. All mutations below use UI forms.
const base = (process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5088').replace(/\/$/, '');
const directory = path.resolve(__dirname, '../artifacts');
fs.mkdirSync(directory, { recursive: true });
const tag = 'QA' + Date.now();
const state = {
  tag, createdAt: new Date().toISOString(), suite: 'forms',
  fixtures: { products: [], customers: [], suppliers: [], catalogs: [], users: [], sales: [], purchases: [] },
  tests: [], browserErrors: [], screenshots: []
};
const output = path.join(directory, tag + '-forms.json');
function save() { fs.writeFileSync(output, JSON.stringify(state, null, 2)); }
function check(name, condition, details = '') {
  state.tests.push({ name, pass: !!condition, details }); save();
  assert.ok(condition, name + (details ? ': ' + details : ''));
}
function fixture(type, value) { state.fixtures[type].push(value); save(); return value; }
function updateFixture(type, value) {
  const index = state.fixtures[type].findIndex(row => row.id === value.id);
  assert.ok(index >= 0, 'Fixture must already be tracked');
  state.fixtures[type][index] = { ...state.fixtures[type][index], ...value }; save();
}
async function login(browser, userName, password) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  page.on('pageerror', error => { state.browserErrors.push(error.message); save(); });
  await page.goto(base + '/account/login');
  await page.locator('input[name="UserName"]').fill(userName);
  await page.locator('input[name="Password"]').fill(password);
  await page.locator('button[type="submit"]').click();
  await page.waitForURL(base + '/');
  await page.waitForFunction(() => window.KINHMAT_BOOTSTRAP && document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false');
  return { context, page, user: await page.evaluate(() => window.KINHMAT_BOOTSTRAP) };
}
async function get(session, endpoint, expected = 200) {
  const response = await session.context.request.get(base + endpoint);
  assert.equal(response.status(), expected, 'GET ' + endpoint);
  return expected === 200 ? response.json() : null;
}
async function route(page, name) {
  await page.evaluate(hash => { location.hash = hash; }, name);
  await page.waitForFunction(hash => document.querySelector('.nav-link.active')?.getAttribute('href') === '#' + hash && document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false', name);
  if (name === 'users') await page.locator('[data-action="new-user"]').waitFor();
}
async function open(page, action, id, extra = '') {
  const selector = `[data-action="${action}"]${id == null ? '' : `[data-id="${id}"]`}${extra}`;
  await page.locator(selector).click();
  await page.locator('#modal[open]').waitFor();
}
async function submit(page, form, method, endpoint, createdType, additions = {}) {
  const responsePromise = page.waitForResponse(response => new URL(response.url()).pathname === endpoint && response.request().method() === method);
  await page.locator(form + ' button[type="submit"]').click();
  const response = await responsePromise;
  const expectedStatus = method === 'DELETE' ? 204 : 200;
  assert.equal(response.status(), expectedStatus, method + ' ' + endpoint + ' returned ' + response.status());
  const value = expectedStatus === 204 ? null : await response.json();
  if (createdType) fixture(createdType, { ...value, ...additions });
  await page.locator('#modal').waitFor({ state: 'hidden' });
  await page.waitForFunction(() => document.querySelector('#main').getAttribute('aria-busy') === 'false');
  return value;
}
async function screenshot(page, name) {
  const destination = path.join(directory, tag + '-' + name + '.png');
  await page.screenshot({ path: destination, fullPage: true });
  state.screenshots.push(destination); save();
}
async function deleteOpenRecord(page, resource, id) {
  await page.locator(`#modal [data-action="delete-record"][data-id="${id}"]`).click();
  await page.locator(`#delete-form[data-id="${id}"][data-resource="${resource}"]`).waitFor();
  await submit(page, '#delete-form', 'DELETE', '/api/' + resource + '/' + id);
}
async function productForm(page, values) {
  for (const key of ['name', 'price', 'cost', 'stock', 'description']) if (values[key] !== undefined) await page.locator(`#product-form [name="${key}"]`).fill(String(values[key]));
  for (const key of ['categoryId', 'brandId', 'active']) if (values[key] !== undefined) await page.locator(`#product-form [name="${key}"]`).selectOption(String(values[key]));
}
async function partyForm(page, values) {
  for (const [key, value] of Object.entries(values)) await page.locator(`#party-form [name="${key}"]`).fill(String(value));
}

(async () => {
  let browser, admin;
  try {
    browser = await chromium.launch({ headless: true, channel: 'msedge' });
    admin = await login(browser, credentials.userName, credentials.password);
    const page = admin.page;
    check('Admin form session ready', admin.user.role === 'Admin');
    const catalogs = await get(admin, '/api/catalogs');
    assert.ok(catalogs.categories.length, 'A category is required to create test products');

    // Category and brand fixtures stay unused, so both can be deleted through the UI.
    await route(page, 'catalogs');
    for (const type of ['categories', 'brands']) {
      const name = tag + (type === 'categories' ? ' Loại kính UI' : ' Thương hiệu UI');
      await open(page, 'new-catalog', null, `[data-type="${type}"]`);
      await page.locator('#catalog-form input[name="name"]').fill(name);
      if (type === 'brands') await page.locator('#catalog-form input[name="country"]').fill('Việt Nam');
      const row = await submit(page, '#catalog-form', 'POST', '/api/catalogs/' + type, 'catalogs', { type });
      check('UI creates ' + type, row.name === name && (await get(admin, '/api/catalogs'))[type].some(item => item.id === row.id));
      await open(page, 'edit-catalog', row.id, `[data-type="${type}"]`);
      await page.locator('#catalog-form input[name="name"]').fill(name + ' đã sửa');
      const changed = await submit(page, '#catalog-form', 'PUT', '/api/catalogs/' + type + '/' + row.id);
      updateFixture('catalogs', { ...changed, type });
      check('UI updates ' + type, (await get(admin, '/api/catalogs'))[type].some(item => item.id === row.id && item.name === name + ' đã sửa'));
      await open(page, 'edit-catalog', row.id, `[data-type="${type}"]`);
      await deleteOpenRecord(page, 'catalogs/' + type, row.id);
      check('UI deletes unused ' + type, !(await get(admin, '/api/catalogs'))[type].some(item => item.id === row.id));
    }

    await route(page, 'products');
    await open(page, 'new-product');
    await page.locator('#product-form button[type="submit"]').click();
    check('Product form prevents missing required values', await page.locator('#product-form').evaluate(form => !form.checkValidity()) && await page.locator('#modal').evaluate(modal => modal.open));
    await productForm(page, { name: tag + ' Kính CRUD', categoryId: catalogs.categories[0].id, price: 220000, cost: 200000, stock: 12, description: 'Sản phẩm kiểm thử form, không phải dữ liệu bán hàng thật.' });
    await screenshot(page, 'product-form');
    const disposable = await submit(page, '#product-form', 'POST', '/api/products', 'products');
    check('UI creates product with price and stock', disposable.name === tag + ' Kính CRUD' && disposable.price === 220000 && disposable.stock === 12);
    await page.locator('#product-search').fill(tag);
    await open(page, 'edit-product', disposable.id);
    await productForm(page, { name: tag + ' Kính CRUD đã sửa', price: 242000, stock: 15 });
    const changedProduct = await submit(page, '#product-form', 'PUT', '/api/products/' + disposable.id);
    updateFixture('products', changedProduct);
    const persisted = await get(admin, '/api/products/' + disposable.id);
    check('UI updates product and persists values', persisted.name.endsWith('đã sửa') && persisted.price === 242000 && persisted.stock === 15);
    await screenshot(page, 'products');
    await open(page, 'edit-product', disposable.id);
    await deleteOpenRecord(page, 'products', disposable.id);
    check('UI deletes an unused product', !(await get(admin, '/api/products')).some(row => row.id === disposable.id));

    // Keep a customer for the sale, while the supplier exercises delete as well.
    let customer;
    for (const resource of ['customers', 'suppliers']) {
      await route(page, resource);
      await open(page, 'new-party', null, `[data-resource="${resource}"]`);
      const name = tag + (resource === 'customers' ? " Khách O'Brien" : ' Nhà cung cấp UI');
      await partyForm(page, { name, phone: (resource === 'customers' ? '09' : '08') + tag.slice(-8), email: resource + '@example.test', address: 'Địa chỉ kiểm thử form' });
      if (resource === 'customers') await page.locator('#party-form [name="note"]').fill('Kiểm thử lưu ghi chú tiếng Việt.');
      const created = await submit(page, '#party-form', 'POST', '/api/' + resource, resource);
      check('UI creates ' + resource, (await get(admin, '/api/' + resource)).some(row => row.id === created.id && row.name === name));
      await page.locator('#party-search').fill(tag);
      await open(page, 'edit-party', created.id, `[data-resource="${resource}"]`);
      await partyForm(page, { name: name + ' đã sửa', address: 'Địa chỉ mới được lưu từ giao diện' });
      const changed = await submit(page, '#party-form', 'PUT', '/api/' + resource + '/' + created.id);
      updateFixture(resource, changed);
      check('UI updates ' + resource, (await get(admin, '/api/' + resource)).some(row => row.id === created.id && row.name.endsWith('đã sửa') && row.address === 'Địa chỉ mới được lưu từ giao diện'));
      if (resource === 'customers') customer = changed;
      else {
        await open(page, 'edit-party', created.id, `[data-resource="${resource}"]`);
        await deleteOpenRecord(page, resource, created.id);
        check('UI deletes an unused supplier', !(await get(admin, '/api/' + resource)).some(row => row.id === created.id));
      }
    }

    await route(page, 'users');
    await open(page, 'edit-user', admin.user.userId);
    check('Current admin role and active status cannot be changed in form', await page.locator('#user-form select[name="role"]').isDisabled() && await page.locator('#user-form select[name="isActive"]').isDisabled());
    await page.locator('#close-modal').click();
    await page.locator('#modal').waitFor({ state: 'hidden' });
    await open(page, 'new-user');
    await page.locator('#user-form [name="userName"]').fill(tag.toLowerCase());
    await page.locator('#user-form [name="displayName"]').fill(tag + ' Nhân viên form');
    await page.locator('#user-form [name="password"]').fill('KiemThu@12345');
    const employee = await submit(page, '#user-form', 'POST', '/api/users', 'users');
    check('UI creates staff account', employee.userName === tag.toLowerCase() && employee.role === 'Staff' && employee.isActive);
    const staff = await login(browser, employee.userName, 'KiemThu@12345');
    check('Form-created staff has no account administration access', staff.user.role === 'Staff' && (await staff.context.request.get(base + '/api/users')).status() === 403);
    await open(page, 'edit-user', employee.id);
    check('User name is readonly while editing', await page.locator('#user-form [name="userName"]').evaluate(input => input.readOnly));
    await page.locator('#user-form [name="displayName"]').fill(tag + ' Nhân viên form đã sửa');
    await page.locator('#user-form [name="isActive"]').selectOption('false');
    const disabled = await submit(page, '#user-form', 'PUT', '/api/users/' + employee.id);
    updateFixture('users', disabled);
    const users = await get(admin, '/api/users');
    check('UI updates and disables staff account', users.some(row => row.id === employee.id && row.displayName.endsWith('đã sửa') && !row.isActive));
    check('UI account disable revokes existing staff session', (await staff.context.request.get(base + '/api/customers')).status() === 401);
    await staff.context.close();

    // Invoice uses a dedicated test product and the exact token sent by the UI.
    await route(page, 'products');
    await open(page, 'new-product');
    await productForm(page, { name: tag + ' Kính bán UI', categoryId: catalogs.categories[0].id, price: 110000, cost: 100000, stock: 20, description: 'Sản phẩm dành riêng cho kiểm thử hóa đơn.' });
    const saleProduct = await submit(page, '#product-form', 'POST', '/api/products', 'products');
    await route(page, 'sale');
    await page.locator('#sale-search').fill(saleProduct.name);
    await page.locator('#invoice-party').selectOption(String(customer.id));
    await page.locator(`[data-action="add-cart"][data-id="${saleProduct.id}"]`).click();
    await page.locator(`[data-quantity="${saleProduct.id}"]`).fill('2');
    await page.locator(`[data-quantity="${saleProduct.id}"]`).press('Tab');
    await page.locator(`[data-discount="${saleProduct.id}"]`).fill('10');
    await page.locator(`[data-discount="${saleProduct.id}"]`).press('Tab');
    check('Cart UI computes quantity and discount before saving', (await page.locator('#cart [data-cart-quantity]').innerText()).includes('2 sản phẩm') && (await page.locator('#cart [data-cart-total]').innerText()).includes('198.000'));
    // Scope the before/after set to this fixture customer; never track existing invoices.
    const beforeSales = new Set((await get(admin, '/api/sales')).filter(row => row.customerId === customer.id).map(row => row.id));
    await page.locator('[data-action="confirm-invoice"]').click();
    await page.locator('#invoice-form').waitFor();
    const confirmation = await page.locator('#invoice-form').innerText();
    check('Invoice confirmation shows selected customer and discounted total', confirmation.includes(customer.name) && confirmation.includes(saleProduct.name) && confirmation.includes('198.000') && confirmation.includes('10%'));
    await screenshot(page, 'invoice-form');
    const invoiceResponse = page.waitForResponse(response => new URL(response.url()).pathname === '/api/sales' && response.request().method() === 'POST');
    await page.locator('#invoice-form button[type="submit"]').click();
    const response = await invoiceResponse;
    assert.equal(response.status(), 200, 'Sale form submission');
    const payload = response.request().postDataJSON();
    const sale = fixture('sales', { ...await response.json(), token: payload.token });
    assert.match(payload.token, /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
    await page.locator('#modal').waitFor({ state: 'hidden' });
    await page.locator(`#invoice-history [data-action="invoice-detail"][data-id="${sale.id}"]`).first().waitFor();
    const afterSales = (await get(admin, '/api/sales')).filter(row => row.customerId === customer.id && !beforeSales.has(row.id));
    check('Invoice UI saves exactly one sale for fixture customer', afterSales.length === 1 && afterSales[0].id === sale.id && sale.total === 198000 && sale.items.length === 1 && sale.items[0].quantity === 2 && sale.employeeId === admin.user.employeeId);
    check('Invoice UI subtracts the correct stock', (await get(admin, '/api/products/' + saleProduct.id)).stock === 18);
    await page.locator(`#invoice-history [data-action="invoice-detail"][data-id="${sale.id}"]`).first().click();
    await page.locator('#modal[open]').waitFor();
    const detail = await page.locator('#modal-body').innerText();
    check('Invoice detail displays stored line and total', detail.includes(saleProduct.name) && detail.includes('198.000') && detail.includes('10%') && (await page.locator('#modal-title').innerText()) === sale.code);
    await page.locator(`[data-action="cancel-invoice"][data-id="${sale.id}"]`).click();
    await page.locator('#cancel-invoice-form').waitFor();
    await submit(page, '#cancel-invoice-form', 'POST', '/api/sales/' + sale.id + '/cancel');
    updateFixture('sales', { id: sale.id, cancelled: true });
    check('Invoice cancellation UI restores stock and retains cancelled history', (await get(admin, '/api/products/' + saleProduct.id)).stock === 20 && (await get(admin, '/api/sales/' + sale.id)).status === 'cancelled');
    check('No JavaScript errors during form workflows', state.browserErrors.length === 0, state.browserErrors.join('; '));
    state.completed = true; save();
  } catch (error) {
    state.error = error.stack; save();
    if (admin) { try { await screenshot(admin.page, 'form-failure'); } catch {} }
    process.stderr.write(error.stack + '\n'); process.exitCode = 1;
  } finally {
    // If a later UI assertion fails, still restore stock for this run's own invoice.
    if (admin) for (const invoice of state.fixtures.sales.filter(row => !row.cancelled)) {
      try {
        const current = await get(admin, '/api/sales/' + invoice.id);
        if (current.status !== 'cancelled') {
          const response = await admin.context.request.post(base + '/api/sales/' + invoice.id + '/cancel', { headers: { 'X-CSRF-TOKEN': admin.user.csrfToken }, data: {} });
          assert.equal(response.status(), 200, 'Recovery cancellation of test invoice');
        }
        updateFixture('sales', { id: invoice.id, cancelled: true, recoveredAfterFailure: true });
      } catch (error) { state.recoveryError = error.message; save(); process.exitCode = 1; }
    }
    if (browser) await browser.close();
    process.stdout.write(JSON.stringify({ output, tests: state.tests.length, passed: state.tests.filter(test => test.pass).length, completed: !!state.completed, screenshots: state.screenshots }) + '\n');
  }
})();
