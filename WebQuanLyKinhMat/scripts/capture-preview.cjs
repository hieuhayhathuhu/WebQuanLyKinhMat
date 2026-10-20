const fs = require('node:fs');
const path = require('node:path');
const loginOnly = process.argv.includes('--login-only');
const credentials = loginOnly ? null : require('./qa-credentials.cjs').getQaCredentials();
const { chromium } = require('./qa-browser.cjs');
const base = process.env.KINHMAT_TEST_URL || 'http://127.0.0.1:5088';
const directory = path.resolve(__dirname, '../artifacts/previews');
fs.mkdirSync(directory, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
    const errors = []; page.on('pageerror', error => errors.push(error.message));
    await page.goto(base + '/account/login');
    await page.screenshot({ path: path.join(directory, 'login.png') });
    if (loginOnly) { process.stdout.write('Login preview updated.\n'); return; }
    await page.locator('input[name="UserName"]').fill(credentials.userName);
    await page.locator('input[name="Password"]').fill(credentials.password);
    await page.locator('button[type="submit"]').click(); await page.waitForURL(base + '/');
    await page.waitForFunction(() => document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false');
    for (const route of ['overview','products']) {
      await page.evaluate(hash => { location.hash = hash; }, route); await page.waitForTimeout(200);
      await page.screenshot({ path: path.join(directory, route + '-desktop.png'), fullPage: true });
    }
    const widths = [];
    for (const width of [320, 390, 768, 1440]) {
      await page.setViewportSize({ width, height: 844 });
      await page.waitForTimeout(200);
      widths.push(await page.evaluate(() => ({ viewport: innerWidth, content: document.documentElement.scrollWidth })));
    }
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(200);
    await page.screenshot({ path: path.join(directory, 'products-mobile.png'), fullPage: true });
    const layouts = [];
    for (const width of [320, 390, 768, 1440]) {
      await page.setViewportSize({ width, height: 844 });
      for (const route of ['overview', 'sale', 'import', 'products', 'customers', 'suppliers', 'catalogs', 'search', 'reports', 'users']) {
        await page.evaluate(hash => { location.hash = hash; }, route);
        await page.waitForFunction(hash => document.querySelector('.nav-link.active')?.getAttribute('href') === '#' + hash && document.querySelector('#main h1') && document.querySelector('#main').getAttribute('aria-busy') === 'false', route);
        await page.waitForTimeout(75);
        const layout = await page.evaluate(() => ({ viewport: innerWidth, content: document.documentElement.scrollWidth, heading: document.querySelector('#main h1').textContent }));
        layouts.push({ route, ...layout, pass: layout.content <= layout.viewport + 3 });
      }
    }
    const csrfToken = await page.evaluate(() => window.KINHMAT_BOOTSTRAP.csrfToken);
    const invalid = await page.context().request.post(base + '/api/customers', { headers: { 'X-CSRF-TOKEN': csrfToken }, data: { name: 'Kiểm tra thông báo', phone: '--------' } });
    const invalidBody = await invalid.json();
    const localizedValidation = invalid.status() === 400 && Object.values(invalidBody.errors || {}).flat().join(' ').includes('chữ số');
    const logout = await page.context().request.post(base + '/account/logout', { headers: { 'X-CSRF-TOKEN': csrfToken } });
    const afterLogout = await page.context().request.get(base + '/api/products');
    const anonymousHome = await page.context().request.get(base + '/');
    const logoutVerified = logout.status() === 200 && afterLogout.status() === 401 && new URL(anonymousHome.url()).pathname === '/account/login';
    fs.writeFileSync(path.join(directory, 'preview-check.json'), JSON.stringify({ createdAt: new Date().toISOString(), errors, widths, layouts, logoutVerified, localizedValidation }, null, 2));
    if (errors.length || !logoutVerified || !localizedValidation || layouts.some(row => !row.pass) || widths.some(row => row.content > row.viewport + 3)) throw new Error('Preview verification failed');
    process.stdout.write(JSON.stringify({ screenshots: directory, widths, layoutsPassed: layouts.filter(row => row.pass).length, errors }) + '\n');
  } finally { await browser.close(); }
})().catch(error => { process.stderr.write(error.stack + '\n'); process.exitCode = 1; });
