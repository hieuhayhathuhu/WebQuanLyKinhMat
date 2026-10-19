'use strict';

window.KinhMatData = (() => {
  const config = window.KINHMAT_CONFIG;
  const user = window.KINHMAT_BOOTSTRAP || {};
  const day = offset => {
    const date = new Date();
    date.setDate(date.getDate() + offset);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  };
  async function request(path, options = {}) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), config.requestTimeoutMs);
    const mutation = options.method && options.method !== 'GET';
    try {
      const response = await fetch(config.apiBaseUrl + path, {
        ...options, credentials: 'same-origin', signal: controller.signal,
        headers: { Accept: 'application/json', ...(mutation ? { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': user.csrfToken } : {}), ...options.headers }
      });
      if (response.status === 401) {
        location.assign('/account/login?returnUrl=' + encodeURIComponent(location.pathname + location.search));
        throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      const text = await response.text();
      let result = null;
      if (text) { try { result = JSON.parse(text); } catch { if (response.ok) throw new Error('Dữ liệu phản hồi không hợp lệ. Vui lòng tải lại trang.'); } }
      if (!response.ok) {
        const errors = result?.errors ? Object.values(result.errors).flat().filter(Boolean).join(' ') : '';
        const error = new Error(errors || result?.message || (response.status === 403 ? 'Tài khoản chưa có quyền thực hiện thao tác này.' : 'Chưa thực hiện được thao tác. Vui lòng thử lại.'));
        error.status = response.status; throw error;
      }
      return result;
    } catch (error) {
      if (error.name === 'AbortError') throw new Error('Máy chủ phản hồi quá lâu. Vui lòng thử lại; chứng từ sẽ được kiểm tra để tránh lưu trùng.');
      if (error instanceof TypeError) throw new Error('Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.');
      throw error;
    } finally { clearTimeout(timeout); }
  }
  const write = (path, input, method = 'POST') => request(path, { method, body: JSON.stringify(input) });
  const resource = (name, input) => write('/' + name + (input.id ? '/' + input.id : ''), input, input.id ? 'PUT' : 'POST');
  return Object.freeze({
    day, request,
    async load() {
      const names = ['products', 'customers', 'suppliers', 'sales', 'catalogs'];
      if (user.role === 'Admin') names.push('purchases');
      const values = await Promise.all(names.map(name => request('/' + name)));
      const result = Object.fromEntries(names.map((name, index) => [name, values[index]]));
      if (!['products', 'customers', 'suppliers', 'sales'].every(name => Array.isArray(result[name])) || !result.catalogs || typeof result.catalogs !== 'object') throw new Error('Chưa đọc được dữ liệu cửa hàng. Vui lòng tải lại.');
      result.purchases ||= [];
      return result;
    },
    saveProduct: input => resource('products', input),
    saveCustomer: input => resource('customers', input),
    saveSupplier: input => resource('suppliers', input),
    remove: (resourceName, id) => request('/' + resourceName + '/' + id, { method: 'DELETE' }),
    saveCatalog: (type, input) => resource('catalogs/' + type, input),
    createInvoice: (kind, input) => write(kind === 'sale' ? '/sales' : '/purchases', input),
    cancelInvoice: (kind, id) => write((kind === 'sale' ? '/sales/' : '/purchases/') + id + '/cancel', {}),
    users: () => request('/users'),
    saveUser: input => resource('users', input),
    changePassword: input => write('/account/password', input)
  });
})();
