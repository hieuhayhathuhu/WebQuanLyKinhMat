const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const credentials = require('./qa-credentials.cjs').getQaCredentials();
const { chromium } = require('./qa-browser.cjs');

// The caller starts the application. Every real mutation is tracked immediately.
// No real invoice is submitted: POST /api/sales is aborted, and the CSV invoice
// fixture is a GET response mock only. Cleanup-TestData.ps1 can use this JSON.
const base = (process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5080').replace(/\/$/, '');
const directory = path.resolve(__dirname, '../artifacts');
fs.mkdirSync(directory, { recursive: true });
const tag = 'QA' + Date.now();
const state = {
  tag, createdAt: new Date().toISOString(), suite: 'ui-extended',
  fixtures: { products: [], customers: [], suppliers: [], catalogs: [], users: [], sales: [], purchases: [] },
  tests: [], browserErrors: [], downloads: [], mockedResponses: []
};
const output = path.join(directory, tag + '-ui-extended.json');
function save() { fs.writeFileSync(output, JSON.stringify(state, null, 2)); }
function check(name, condition, details = '') {
  state.tests.push({ name, pass: !!condition, details }); save();
  assert.ok(condition, name + (details ? ': ' + details : ''));
}
function fixture(type, row) { state.fixtures[type].push(row); save(); return row; }
async function get(context, endpoint) {
  const response = await context.request.get(base + endpoint);
  assert.equal(response.status(), 200, 'GET ' + endpoint);
  return response.json();
}
async function write(context, csrfToken, endpoint, input, type) {
  const response = await context.request.post(base + endpoint, { headers: { 'X-CSRF-TOKEN': csrfToken }, data: input });
  assert.equal(response.status(), 200, 'POST ' + endpoint + ': ' + await response.text());
  return fixture(type, await response.json());
}
async function route(page, name) {
  await page.evaluate(hash => { location.hash = hash; }, name);
  await page.waitForFunction(hash => document.querySelector('.nav-link.active')?.getAttribute('href') === '#' + hash && document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false', name);
}
async function reload(page) {
  const response = page.waitForResponse(row => new URL(row.url()).pathname === '/api/products' && row.request().method() === 'GET');
  await page.locator('#refresh-data').click();
  await response;
  await page.waitForFunction(() => document.querySelector('#main').getAttribute('aria-busy') === 'false');
}
async function names(page) { return page.locator('#product-results tbody .table-product strong').allTextContents(); }
async function searchProducts(page, value, stock = '', category = '') {
  await page.locator('#product-search').fill(value);
  await page.locator('#product-category').selectOption(String(category));
  await page.locator('#product-stock').selectOption(stock);
}
function sameNames(actual, expected) { return actual.length === expected.length && [...actual].sort().every((row, index) => row === [...expected].sort()[index]); }
function parseCsv(value) {
  const rows = []; let row = [], cell = '', quoted = false;
  const text = value.replace(/^\ufeff/, '');
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (char === '"') {
      if (quoted && text[index + 1] === '"') { cell += '"'; index++; }
      else quoted = !quoted;
    } else if (char === ',' && !quoted) { row.push(cell); cell = ''; }
    else if ((char === '\r' || char === '\n') && !quoted) {
      if (char === '\r' && text[index + 1] === '\n') index++;
      row.push(cell); rows.push(row); row = []; cell = '';
    } else cell += char;
  }
  if (cell.length || row.length) { row.push(cell); rows.push(row); }
  return rows;
}
async function downloadCsv(page, action) {
  const pending = page.waitForEvent('download'); await action(); const download = await pending;
  const destination = path.join(directory, tag + '-' + download.suggestedFilename());
  await download.saveAs(destination);
  const bytes = fs.readFileSync(destination);
  state.downloads.push({ filename: download.suggestedFilename(), path: destination, bytes: bytes.length }); save();
  return { filename: download.suggestedFilename(), bytes, rows: parseCsv(bytes.toString('utf8')) };
}

(async () => {
  let browser, context, page, abortHandler, salesMock;
  try {
    browser = await chromium.launch({ headless: true, channel: 'msedge' });
    context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce', acceptDownloads: true });
    await context.addInitScript(() => { window.__qaExecuted = false; });
    page = await context.newPage(); page.setDefaultTimeout(15000);
    page.on('pageerror', error => { state.browserErrors.push(error.message); save(); });
    await page.goto(base + '/account/login');
    await page.locator('[name="UserName"]').fill(credentials.userName);
    await page.locator('[name="Password"]').fill(credentials.password);
    await page.locator('button[type="submit"]').click(); await page.waitForURL(base + '/');
    await page.waitForFunction(() => window.KINHMAT_BOOTSTRAP && document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false');
    const user = await page.evaluate(() => window.KINHMAT_BOOTSTRAP);
    check('Admin signs in once for the extended UI suite', user.role === 'Admin');
    const catalogs = await get(context, '/api/catalogs');
    assert.ok(catalogs.categories.length, 'Need an existing category; this suite creates no catalogs');
    const products = [];
    const htmlName = tag + ' Kính Đổi Ánh HTML <img src=x onerror="window.__qaExecuted=true">';
    const sqlName = tag + ' Kính Đổi Ánh SQL O\'Brien, "Đẹp"; SELECT N\'Tiếng Việt\'; --';
    for (let index = 0; index < 12; index++) {
      const input = {
        name: index === 10 ? htmlName : index === 11 ? sqlName : `${tag} Kính Đổi Ánh ${String(index + 1).padStart(2, '0')}`,
        categoryId: catalogs.categories[index % Math.min(2, catalogs.categories.length)].id,
        brandId: null, materialId: null, colorId: null, shapeId: null,
        price: 123456.78, cost: 112233.45, stock: index < 3 ? [0, 3, 5][index] : 12,
        active: index !== 9, description: 'Dữ liệu kiểm thử UI riêng: Việt Nam, Đỗ Ánh.', imageUrl: null
      };
      products.push(await write(context, user.csrfToken, '/api/products', input, 'products'));
    }
    check('PR04 creates twelve owned Unicode products with no invoices', products.length === 12 && products.every(row => row.name.startsWith(tag)));
    await reload(page); await route(page, 'products');
    await searchProducts(page, tag + ' kinh doi anh');
    check('PR04 unaccented lowercase search matches Vietnamese Đ/đ and accents', (await page.locator('#product-results .filter-count').innerText()).startsWith('12 sản phẩm'));
    const firstNames = await names(page);
    check('PR04 first page shows eight results and disables previous page', firstNames.length === 8 && await page.getByRole('button', { name: 'Trang sản phẩm trước', exact: true }).isDisabled());
    await page.getByRole('button', { name: 'Trang sản phẩm sau', exact: true }).click();
    const secondNames = await names(page);
    check('PR04 last page has four disjoint results and disables next page', secondNames.length === 4 && !secondNames.some(row => firstNames.includes(row)) && await page.getByRole('button', { name: 'Trang sản phẩm sau', exact: true }).isDisabled());
    await page.locator('#product-search').fill(tag + ' Kính Đổi Ánh 01');
    check('PR04 changing search resets pagination to page one', sameNames(await names(page), [products[0].name]) && (await page.locator('.pagination').innerText()).includes('Trang 1 / 1'));
    const category = catalogs.categories[0].id;
    await searchProducts(page, tag, '', category);
    const categoryExpected = products.filter(row => row.categoryId === category);
    check('PR04 category filter composes with search', (await page.locator('#product-results .filter-count').innerText()).startsWith(categoryExpected.length + ' sản phẩm') && (await names(page)).every(row => categoryExpected.some(product => product.name === row)), `Existing categories: ${catalogs.categories.length}`);
    for (const [status, expected] of [
      ['low', products.filter(row => row.active && row.stock <= 5)],
      ['available', products.filter(row => row.active && row.stock > 5)],
      ['inactive', products.filter(row => !row.active)]
    ]) {
      await searchProducts(page, tag, status);
      check('PR04 ' + status + ' filter returns exact fixture set', sameNames(await names(page), expected.map(row => row.name)));
    }
    await searchProducts(page, tag + ' NO_SUCH_PRODUCT');
    check('PR04 no-result search has an empty state and safe pagination', await page.locator('#product-results .empty-state').isVisible() && (await page.locator('#product-results .table-footer').innerText()).includes('0–0 / 0') && await page.getByRole('button', { name: 'Trang sản phẩm sau', exact: true }).isDisabled());

    const savedHtml = await get(context, '/api/products/' + products[10].id);
    await searchProducts(page, tag + ' kinh doi anh html');
    check('SC02 HTML-like product name is stored and rendered as literal text', savedHtml.name === htmlName && sameNames(await names(page), [htmlName]) && await page.locator('#product-results img[src="x"]').count() === 0 && await page.evaluate(() => window.__qaExecuted) === false);
    await page.locator(`[data-action="edit-product"][data-id="${products[10].id}"]`).click();
    check('SC02 quotes and markup remain literal inside edit fields', await page.locator('#product-form [name="name"]').inputValue() === htmlName && await page.locator('#modal-body img[src="x"]').count() === 0 && await page.evaluate(() => window.__qaExecuted) === false);
    await page.keyboard.press('Escape'); await page.locator('#modal').waitFor({ state: 'hidden' });
    const savedSql = await get(context, '/api/products/' + products[11].id);
    await searchProducts(page, tag + ' kinh doi anh sql');
    check('SC02 apostrophes, double quotes and SQL source remain ordinary data', savedSql.name === sqlName && sameNames(await names(page), [sqlName]) && (await get(context, '/api/products')).filter(row => row.name.startsWith(tag)).length === 12);

    const previousHash = await page.evaluate(() => location.hash);
    await page.locator('#skip-link').focus(); await page.keyboard.press('Enter');
    check('UI02 keyboard skip link focuses content and preserves current route', await page.locator('#main').evaluate(element => element === document.activeElement) && await page.evaluate(() => location.hash) === previousHash && await page.locator('#product-search').isVisible());
    const newProduct = page.locator('[data-action="new-product"]');
    await newProduct.focus(); await page.keyboard.press('Enter'); await page.locator('#modal[open]').waitFor();
    assert.equal(await page.locator('#product-form [name="name"]').evaluate(element => element === document.activeElement), true, 'Dialog initially focuses name');
    await page.keyboard.press('Escape'); await page.locator('#modal').waitFor({ state: 'hidden' });
    check('UI02 keyboard opens modal, Escape closes it and restores opener focus', await newProduct.evaluate(element => element === document.activeElement));
    await route(page, 'customers');
    await page.locator('[data-action="new-party"][data-resource="customers"]').focus(); await page.keyboard.press('Enter');
    const customerName = tag + ' Khách Đỗ "Ánh", O\'Brien';
    await page.locator('#party-form [name="name"]').fill(customerName);
    await page.locator('#party-form [name="phone"]').fill('09' + tag.slice(-8));
    await page.locator('#party-form [name="address"]').fill('Hà Nội, Việt Nam');
    const customerResponse = page.waitForResponse(row => new URL(row.url()).pathname === '/api/customers' && row.request().method() === 'POST');
    await page.locator('#party-form [name="name"]').press('Enter');
    const createdResponse = await customerResponse;
    assert.equal(createdResponse.status(), 200, 'Keyboard customer submission');
    const customer = fixture('customers', await createdResponse.json());
    await page.locator('#modal').waitFor({ state: 'hidden' });
    await page.waitForFunction(() => document.querySelector('#main').getAttribute('aria-busy') === 'false');
    check('UI02 Enter submits a valid form and persists Vietnamese customer data', customer.name === customerName && (await get(context, '/api/customers')).some(row => row.id === customer.id && row.name === customerName));

    await route(page, 'products'); await searchProducts(page, tag);
    const csv = await downloadCsv(page, () => page.locator('[data-action="export"]').click());
    check('I1801 product CSV starts with a UTF-8 BOM', csv.bytes.subarray(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf])));
    const csvProduct = csv.rows.find(row => row[0] === String(products[11].id));
    check('I1801 CSV preserves Unicode, commas, quotes and fractional prices', csv.rows.length === 13 && csvProduct?.[1] === sqlName && csvProduct?.[4] === '123456.78' && csv.rows.some(row => row[1] === htmlName));
    const browserToday = await page.evaluate(() => window.KinhMatData.day(0));
    check('I1801 CSV download filename uses local YYYY-MM-DD date', csv.filename === 'san-pham-' + browserToday + '.csv');

    // Guarantee a known date/decimal CSV case without writing any database invoice.
    const mockedInvoice = { id: -1, code: tag + '-CSV-RESPONSE-ONLY', date: '2026-02-03', customerId: customer.id, supplierId: null, supplier: '', status: 'completed', total: 123456.78, items: [], employeeName: tag + ' Nhân viên thử CSV', employeeId: user.employeeId };
    state.mockedResponses.push({ endpoint: 'GET /api/sales', onlyInBrowser: true, invoice: mockedInvoice }); save();
    salesMock = async intercepted => {
      if (intercepted.request().method() !== 'GET') return intercepted.continue();
      const response = await intercepted.fetch(); const real = await response.json();
      await intercepted.fulfill({ response, json: [...real, mockedInvoice] });
    };
    await page.route('**/api/sales', salesMock);
    await reload(page); await route(page, 'sale');
    const invoiceCsv = await downloadCsv(page, () => page.locator('#invoice-history [data-action="export"]').click());
    const csvInvoice = invoiceCsv.rows.find(row => row[0] === mockedInvoice.code);
    check('I1801 invoice CSV preserves date, Vietnamese customer and decimal amount', invoiceCsv.bytes.subarray(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf])) && csvInvoice?.[1] === '2026-02-03' && csvInvoice?.[2] === customerName && csvInvoice?.[4] === '123456.78' && csvInvoice?.[5] === 'Hoàn tất', 'Invoice exists only in a mocked GET response, never in SQL Server.');
    await page.unroute('**/api/sales', salesMock); salesMock = null; await reload(page);

    const saleProduct = products[3];
    const beforeSales = (await get(context, '/api/sales')).map(row => row.id).sort((left, right) => left - right);
    const stockBefore = (await get(context, '/api/products/' + saleProduct.id)).stock;
    await page.locator('#sale-search').fill(saleProduct.name);
    await page.locator('#invoice-party').selectOption(String(customer.id));
    await page.locator(`[data-action="add-cart"][data-id="${saleProduct.id}"]`).click();
    await page.locator(`[data-quantity="${saleProduct.id}"]`).fill('2'); await page.locator(`[data-quantity="${saleProduct.id}"]`).press('Tab');
    check('UI03 cart is prepared before simulated network failure', (await page.locator('#cart [data-cart-quantity]').innerText()).includes('2 sản phẩm'));
    let aborted = 0;
    abortHandler = async intercepted => {
      if (intercepted.request().method() === 'POST') { aborted++; return intercepted.abort('failed'); }
      return intercepted.continue();
    };
    await page.route('**/api/sales', abortHandler);
    await page.locator('[data-action="confirm-invoice"]').click(); await page.locator('#invoice-form').waitFor();
    await page.locator('#invoice-form button[type="submit"]').click();
    await page.locator('#invoice-form .form-error:not([hidden])').waitFor();
    const error = page.locator('#invoice-form .form-error');
    check('UI03 aborted invoice request displays an actionable focused error', aborted === 1 && (await error.innerText()).includes('Không kết nối được máy chủ') && await error.evaluate(element => element === document.activeElement) && await page.locator('#invoice-form button[type="submit"]').isEnabled(), 'The application presents this error in the modal alert.');
    await page.locator('#close-modal').click(); await page.locator('#modal').waitFor({ state: 'hidden' });
    check('UI03 failed invoice leaves cart quantity, party and amount intact', await page.locator(`[data-quantity="${saleProduct.id}"]`).inputValue() === '2' && await page.locator('#invoice-party').inputValue() === String(customer.id) && (await page.locator('#cart [data-cart-total]').innerText()).includes('246.913,56'));
    const afterSales = (await get(context, '/api/sales')).map(row => row.id).sort((left, right) => left - right);
    check('UI03 network failure creates no SQL invoice and changes no stock', JSON.stringify(beforeSales) === JSON.stringify(afterSales) && (await get(context, '/api/products/' + saleProduct.id)).stock === stockBefore);
    await page.unroute('**/api/sales', abortHandler); abortHandler = null;
    await page.locator('[data-action="confirm-invoice"]').click(); await page.locator('#invoice-form').waitFor();
    check('UI03 removing network simulation restores confirmation without losing draft', (await page.locator('#invoice-form').innerText()).includes(saleProduct.name) && await page.locator('#invoice-form button[type="submit"]').isEnabled(), 'The recovered confirmation is closed without submitting an invoice.');
    await page.keyboard.press('Escape'); await page.locator('#modal').waitFor({ state: 'hidden' });
    await page.locator(`[data-action="remove-cart"][data-id="${saleProduct.id}"]`).click();
    check('Extended UI workflows complete with no uncaught browser errors', state.browserErrors.length === 0, state.browserErrors.join('; '));
    state.completed = true; save();
  } catch (error) {
    state.error = error.stack; save();
    if (page) { try { state.failureScreenshot = path.join(directory, tag + '-ui-extended-failure.png'); await page.screenshot({ path: state.failureScreenshot, fullPage: true }); save(); } catch {} }
    process.stderr.write(error.stack + '\n'); process.exitCode = 1;
  } finally {
    if (page && abortHandler) { try { await page.unroute('**/api/sales', abortHandler); } catch {} }
    if (page && salesMock) { try { await page.unroute('**/api/sales', salesMock); } catch {} }
    if (browser) await browser.close();
    process.stdout.write(JSON.stringify({ output, tests: state.tests.length, passed: state.tests.filter(row => row.pass).length, completed: !!state.completed, realInvoicesCreated: state.fixtures.sales.length }) + '\n');
  }
})();
