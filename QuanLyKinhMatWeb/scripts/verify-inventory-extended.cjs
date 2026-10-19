const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const credentials = require('./qa-credentials.cjs').getQaCredentials();
const { chromium } = require('./qa-browser.cjs');
const base = process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5080';
const directory = path.resolve(__dirname, '../artifacts');
fs.mkdirSync(directory, { recursive: true });
const state = { tag: 'QA' + Date.now(), suite: 'inventory-extended', fixtures: { products: [], customers: [], suppliers: [], catalogs: [], users: [], sales: [], purchases: [] }, tests: [], browserErrors: [] };
const output = path.join(directory, state.tag + '-inventory-extended.json');
const save = () => fs.writeFileSync(output, JSON.stringify(state, null, 2));
function check(name, condition, details = '') { state.tests.push({ name, pass: !!condition, details }); save(); assert.ok(condition, name + ' ' + details); }
function track(kind, value) { state.fixtures[kind].push(value); save(); return value; }
(async () => {
  let browser, context, page, user;
  async function api(method, endpoint, data) {
    const response = await context.request.fetch(base + endpoint, { method, headers: { 'X-CSRF-TOKEN': user.csrfToken }, ...(data === undefined ? {} : { data }) });
    let value = null; const raw = await response.text(); if (raw) { try { value = JSON.parse(raw); } catch { value = raw; } }
    return { status: response.status(), value };
  }
  async function ok(method, endpoint, data) { const result = await api(method, endpoint, data); assert.equal(result.status, 200, method + endpoint + JSON.stringify(result.value)); return result.value; }
  try {
    browser = await chromium.launch({ headless: true, channel: 'msedge' });
    context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
    page = await context.newPage(); page.setDefaultTimeout(15000);
    page.on('pageerror', error => { state.browserErrors.push(error.message); save(); });
    await page.goto(base + '/account/login');
    await page.locator('[name="UserName"]').fill(credentials.userName); await page.locator('[name="Password"]').fill(credentials.password);
    await page.locator('button[type="submit"]').click(); await page.waitForURL(base + '/');
    await page.waitForFunction(() => window.KINHMAT_BOOTSTRAP && document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false');
    user = await page.evaluate(() => window.KINHMAT_BOOTSTRAP);
    const catalogs = await ok('GET', '/api/catalogs');
    const template = { name: state.tag, categoryId: catalogs.categories[0].id, brandId: catalogs.brands[0]?.id || null, price: 110000, cost: 100000, stock: 20, active: true };
    const initialCount = (await ok('GET', '/api/products')).length;
    for (const [name, change] of [['empty product name', { name: '' }], ['whitespace product name', { name: '   ' }], ['overlong product name', { name: 'a'.repeat(151) }], ['negative sale price', { price: -1 }], ['negative stock', { stock: -1 }], ['nonexistent category', { categoryId: 2147483000 }], ['fractional stock', { stock: 1.5 }], ['more than two money decimal places', { price: 100.001 }]]) {
      const result = await api('POST', '/api/products', { ...template, ...change });
      check('Reject ' + name, [400, 409].includes(result.status), String(result.status));
    }
    check('Invalid product requests do not insert records', (await ok('GET', '/api/products')).length === initialCount);
    for (const [name, input] of [['whitespace customer', { name: '  ' }], ['invalid customer email', { name: state.tag, email: 'wrong-address' }], ['invalid phone digits', { name: state.tag, phone: '--------' }]]) {
      check('Reject ' + name, (await api('POST', '/api/customers', input)).status === 400);
    }
    const supplier = track('suppliers', await ok('POST', '/api/suppliers', { name: state.tag + ' Nhà cung cấp' }));
    const products = [];
    for (let i = 0; i < 2; i++) products.push(track('products', await ok('POST', '/api/products', { ...template, name: state.tag + ' Kính ' + (i + 1), stock: i === 0 ? 20 : 30 })));
    const invalidInvoices = [
      ['zero quantity', { items: [{ productId: products[0].id, quantity: 0, unitPrice: 100000, discount: 0 }] }],
      ['negative quantity', { items: [{ productId: products[0].id, quantity: -1, unitPrice: 100000, discount: 0 }] }],
      ['quantity 10001', { items: [{ productId: products[0].id, quantity: 10001, unitPrice: 100000, discount: 0 }] }],
      ['empty lines', { items: [] }],
      ['null line', { items: [null] }],
      ['duplicate product', { items: [{ productId: products[0].id, quantity: 1, unitPrice: 100000, discount: 0 }, { productId: products[0].id, quantity: 1, unitPrice: 100000, discount: 0 }] }],
      ['unknown supplier', { supplierId: 2147483000, items: [{ productId: products[0].id, quantity: 1, unitPrice: 100000, discount: 0 }] }],
      ['discount over 100', { items: [{ productId: products[0].id, quantity: 1, unitPrice: 100000, discount: 100.01 }] }]
    ];
    const beforePurchases = (await ok('GET', '/api/purchases')).length;
    for (const [name, change] of invalidInvoices) {
      const result = await api('POST', '/api/purchases', { token: randomUUID(), supplierId: supplier.id, ...change });
      check('Reject purchase ' + name, [400, 404, 409].includes(result.status), String(result.status));
    }
    check('Invalid purchases are atomic', (await ok('GET', '/api/purchases')).length === beforePurchases && (await ok('GET', '/api/products/' + products[0].id)).stock === 20);
    await page.reload();
    await page.waitForFunction(() => document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false');
    await page.evaluate(() => { location.hash = 'import'; });
    await page.locator('#invoice-party').selectOption(String(supplier.id));
    await page.locator('#sale-search').fill(state.tag);
    for (const product of products) await page.locator(`[data-action="add-cart"][data-id="${product.id}"]`).click();
    for (const [index, quantity] of [[0, 2], [1, 3]]) {
      const input = page.locator(`[data-quantity="${products[index].id}"]`); await input.fill(String(quantity)); await input.press('Tab');
    }
    await page.locator(`[data-unit-price="${products[0].id}"]`).fill('123456.78'); await page.locator(`[data-unit-price="${products[0].id}"]`).press('Tab');
    await page.locator(`[data-discount="${products[0].id}"]`).fill('12.34'); await page.locator(`[data-discount="${products[0].id}"]`).press('Tab');
    await page.locator(`[data-unit-price="${products[1].id}"]`).fill('230000.12'); await page.locator(`[data-unit-price="${products[1].id}"]`).press('Tab');
    await page.locator('[data-action="confirm-invoice"]').click(); await page.locator('#invoice-form').waitFor();
    const responsePromise = page.waitForResponse(response => response.request().method() === 'POST' && new URL(response.url()).pathname === '/api/purchases');
    await page.locator('#invoice-form button[type="submit"]').click();
    const response = await responsePromise; assert.equal(response.status(), 200, 'Purchase form save');
    const payload = response.request().postDataJSON(); const purchase = track('purchases', { ...await response.json(), token: payload.token });
    await page.locator('#modal').waitFor({ state: 'hidden' });
    check('Purchase form saves two lines and current employee', purchase.items.length === 2 && purchase.employeeId === user.employeeId && purchase.supplierId === supplier.id);
    check('Purchase decimal total matches rounding rules', purchase.total === 906444.79, String(purchase.total));
    check('Purchase form updates each stock', (await ok('GET', '/api/products/' + products[0].id)).stock === 22 && (await ok('GET', '/api/products/' + products[1].id)).stock === 33);
    await page.locator(`#invoice-history [data-action="invoice-detail"][data-id="${purchase.id}"]`).first().click();
    await page.locator(`[data-action="cancel-invoice"][data-id="${purchase.id}"]`).click();
    const cancelResponse = page.waitForResponse(response => new URL(response.url()).pathname === '/api/purchases/' + purchase.id + '/cancel' && response.request().method() === 'POST');
    await page.locator('#cancel-invoice-form button[type="submit"]').click(); assert.equal((await cancelResponse).status(), 200);
    await page.locator('#modal').waitFor({ state: 'hidden' });
    check('Multi-line cancellation restores every stock and cost', (await ok('GET', '/api/products/' + products[0].id)).stock === 20 && (await ok('GET', '/api/products/' + products[1].id)).stock === 30 && (await ok('GET', '/api/products/' + products[0].id)).cost === 100000);
    await ok('POST', '/api/purchases/' + purchase.id + '/cancel', {});
    check('Repeated multi-line cancellation has no second stock effect', (await ok('GET', '/api/products/' + products[0].id)).stock === 20);
    const inactive = await ok('PUT', '/api/products/' + products[0].id, { ...template, name: products[0].name, active: false });
    check('Cannot sell inactive product', (await api('POST', '/api/sales', { token: randomUUID(), items: [{ productId: inactive.id, quantity: 1, unitPrice: inactive.price, discount: 0 }] })).status === 409);
    await ok('PUT', '/api/products/' + products[0].id, { ...template, name: products[0].name, active: true });
    check('No browser errors in purchase workflows', state.browserErrors.length === 0, state.browserErrors.join('; '));
    state.completed = true; save();
  } catch (error) { state.error = error.stack; save(); if (page) { try { await page.screenshot({ path: path.join(directory, state.tag + '-inventory-failure.png'), fullPage: true }); } catch {} } process.stderr.write(error.stack + '\n'); process.exitCode = 1; }
  finally {
    if (context && user) for (const invoice of state.fixtures.purchases) {
      try { await ok('POST', '/api/purchases/' + invoice.id + '/cancel', {}); } catch (error) { state.recoveryError = error.message; save(); process.exitCode = 1; }
    }
    if (browser) await browser.close();
    process.stdout.write(JSON.stringify({ output, tests: state.tests.length, passed: state.tests.filter(test => test.pass).length, completed: !!state.completed }) + '\n');
  }
})();
