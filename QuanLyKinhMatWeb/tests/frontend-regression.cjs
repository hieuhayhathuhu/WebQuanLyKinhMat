'use strict';
// Browser-independent regression checks for the cart and API boundary.
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const jsRoot = path.join(__dirname, '..', 'wwwroot', 'js');
const sample = () => ({
  products: [{ id: 1, name: 'Cùng tên', price: 550000, cost: 300000, stock: 20000, active: true, categoryId: 1, brandId: 1, brand: 'Kính Mắt', category: 'Gọng kính' }, { id: 2, name: 'Cùng tên', price: 100, cost: 90, stock: 2, active: true, categoryId: 1, brand: 'Kính Mắt', category: 'Gọng kính' }],
  customers: [{ id: 1, name: 'Khách kiểm tra', phone: '0900000000' }], suppliers: [{ id: 1, name: 'Nhà cung cấp kiểm tra' }],
  sales: [], purchases: [], users: [], catalogs: { categories: [{ id: 1, name: 'Gọng kính' }], brands: [{ id: 1, name: 'Kính Mắt' }], materials: [], colors: [], shapes: [] }
});
function setup(role = 'Admin') {
  const elements = new Map(), events = {};
  function element(selector) {
    if (!elements.has(selector)) elements.set(selector, {
      innerHTML: '', textContent: '', open: false, hidden: true, dataset: {}, classList: { add() {}, remove() {}, toggle() {}, contains() { return false; } },
      setAttribute() {}, removeAttribute() {}, addEventListener() {}, querySelector() { return null; }, querySelectorAll() { return []; }, focus() {}, scrollIntoView() {},
      showModal() { this.open = true; }, close() { this.open = false; }
    });
    return elements.get(selector);
  }
  let fresh = sample();
  const context = {
    window: { KINHMAT_BOOTSTRAP: { role, displayName: 'Kiểm tra', userId: 1, employeeId: 1 }, KinhMatData: { day(offset) { const date = new Date(Date.UTC(2026, 9, 19 + offset)); return date.toISOString().slice(0, 10); }, async load() { return structuredClone(fresh); } } },
    document: { querySelector: element, querySelectorAll() { return []; }, addEventListener(type, callback) { events[type] = callback; } },
    location: { origin: 'http://localhost', hash: '', pathname: '/' }, crypto: { randomUUID }, URL, Intl, Date, setTimeout() {}, clearTimeout() {}, console
  };
  vm.createContext(context);
  let source = fs.readFileSync(path.join(jsRoot, 'app.js'), 'utf8');
  source = source.slice(0, source.indexOf("  $('#navigation').innerHTML")) + `
    window.audit={
      setStore(value){store=value;loaded=true}, setRoute(value){route=value}, getCarts(){return carts}, getConfirmation(){return confirmation},
      routes:navItems.map(row=>row[0]), render, reports, productForm, partyForm, catalogForm, userForm, confirmInvoice, lineAmount, cartTotal
    };
  })();`;
  vm.runInContext(source, context);
  return { audit: context.window.audit, element, events, setFresh(value) { fresh = value; } };
}
async function checkApp() {
  const { audit, element, events, setFresh } = setup(); let store = sample(); audit.setStore(store);
  for (const route of audit.routes) { audit.setRoute(route); audit.render(); assert.ok(element('#main').innerHTML, 'Route renders: ' + route); }
  for (const [method, args] of [['productForm', [1]], ['partyForm', [1, 'customers']], ['partyForm', [1, 'suppliers']], ['catalogForm', [1, 'categories']], ['userForm', [null]]]) { audit[method](...args); assert.match(element('#modal-body').innerHTML, /<form/); }
  audit.setRoute('import'); audit.getCarts().purchase.push({ productId: 1, quantity: 10000, unitPrice: 300000, discount: 0 });
  events.click({ target: { closest() { return { dataset: { action: 'add-cart', id: '1' } }; } } });
  assert.equal(audit.getCarts().purchase[0].quantity, 10000, 'Product tile enforces 10000 limit');
  assert.equal(audit.lineAmount({ quantity: 3, unitPrice: 125000.50, discount: 10 }), 337501.35, 'Decimal discount rounds to two places');
  assert.equal(audit.lineAmount({ quantity: 1, unitPrice: 150000, discount: 100 }), 0, '100% discount is allowed');
  store.sales = [{ id: 1, date: '2026-10-19', total: 100, status: 'completed', items: [{ productId: 1, name: 'Tên cũ', quantity: 1 }] }, { id: 2, date: '2026-10-19', total: 200, status: 'completed', items: [{ productId: 2, name: 'Cùng tên', quantity: 2 }] }];
  audit.setStore(store); assert.equal((audit.reports().match(/class="metric-row"/g) || []).length, 2, 'Different product IDs stay separate');
  store.sales[1].items[0].productId = 1; audit.setStore(store); assert.equal((audit.reports().match(/class="metric-row"/g) || []).length, 1, 'Renaming a product does not split ranking');
  audit.setRoute('sale'); audit.getCarts().sale.push({ productId: 1, quantity: 1, unitPrice: 550000, discount: 0 });
  const fresh = sample(); fresh.products[0].price = 600000; setFresh(fresh); element('#modal').open = false;
  await audit.confirmInvoice(); assert.equal(element('#modal').open, false, 'Changed prices require a second confirmation'); assert.equal(audit.cartTotal('sale'), 600000); assert.match(element('#toast').textContent, /Giá bán vừa thay đổi/);
  await audit.confirmInvoice(); assert.equal(element('#modal').open, true); const token = audit.getConfirmation().payload.token; assert.equal(audit.getConfirmation().payload.items[0].unitPrice, 600000);
  audit.getCarts().sale[0].quantity = 2; assert.equal(audit.getConfirmation().payload.items[0].quantity, 1, 'Confirmation keeps its own payload snapshot');
  await audit.confirmInvoice(); assert.equal(audit.getConfirmation().payload.token, token, 'Reopening a draft keeps its idempotency token');
  const staff = setup('Staff'); staff.audit.setStore(sample()); assert.ok(!staff.audit.routes.includes('import')); assert.ok(!staff.audit.routes.includes('users')); assert.ok(!staff.audit.routes.includes('suppliers'));
  staff.audit.productForm(1); assert.ok(!staff.element('#modal-body').innerHTML.includes('product-form'), 'Staff product details are read only');
  staff.audit.setRoute('catalogs'); staff.audit.render(); assert.ok(!staff.element('#main').innerHTML.includes('new-catalog'), 'Staff cannot edit catalogs');
  console.log('PASS: page/forms render, role UI, quantity cap, discount totals, ranking by ID, changed-price confirmation, immutable payload, stable token.');
}
async function checkDataService() {
  const requests = []; let status = 200, result = {};
  const context = { window: { KINHMAT_CONFIG: { apiBaseUrl: '/api', requestTimeoutMs: 1000 }, KINHMAT_BOOTSTRAP: { role: 'Staff', csrfToken: 'test-token' } }, AbortController, setTimeout, clearTimeout, location: { pathname: '/', search: '', assign() {} },
    async fetch(url, options) { requests.push({ url, options }); return { status, ok: status >= 200 && status < 300, async text() { if (status !== 200) return JSON.stringify(result); return url === '/api/catalogs' ? '{}' : url.includes('/api/products') && options.method ? '{}' : '[]'; } }; } };
  vm.createContext(context); vm.runInContext(fs.readFileSync(path.join(jsRoot, 'data-service.js'), 'utf8'), context);
  const service = context.window.KinhMatData;
  await service.load(); assert.ok(!requests.some(row => row.url === '/api/purchases'), 'Staff does not request admin data');
  await service.saveProduct({ name: 'Kính' }); const write = requests.at(-1); assert.equal(write.options.headers['X-CSRF-TOKEN'], 'test-token'); assert.equal(write.options.credentials, 'same-origin');
  status = 400; result = { message: 'Dữ liệu chưa đúng', errors: { Name: ['Tên bắt buộc.'] } }; await assert.rejects(service.saveCustomer({}), /Tên bắt buộc/);
  console.log('PASS: API role loading, same-origin credentials, CSRF mutation header, validation error display.');
}
(async () => { await checkApp(); await checkDataService(); })().catch(error => { console.error(error); process.exitCode = 1; });
