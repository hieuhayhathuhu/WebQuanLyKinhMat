using System.Security.Claims;
using KinhMat.Web.Data;
using KinhMat.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KinhMat.Web.Controllers;

[ApiController, Authorize, Route("api/products")]
public sealed class ProductsController(StoreRepository store) : ControllerBase
{
    [HttpGet] public Task<List<ProductDto>> List() => store.GetProductsAsync();
    [HttpGet("{id:int}")] public async Task<IActionResult> Get(int id) => (await store.GetProductsAsync()).FirstOrDefault(p => p.Id == id) is { } row ? Ok(row) : NotFound(new { message = "Không tìm thấy sản phẩm." });
    [HttpPost, Authorize(Roles = "Admin")] public async Task<IActionResult> Create(ProductInput input) => Ok(await store.SaveProductAsync(null, input));
    [HttpPut("{id:int}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Update(int id, ProductInput input) => Ok(await store.SaveProductAsync(id, input));
    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Delete(int id) { await store.DeleteProductAsync(id); return NoContent(); }
}

[ApiController, Authorize, Route("api/customers")]
public sealed class CustomersController(StoreRepository store) : ControllerBase
{
    [HttpGet] public Task<List<CustomerDto>> List() => store.GetCustomersAsync();
    [HttpGet("{id:int}")] public async Task<IActionResult> Get(int id) => (await store.GetCustomersAsync()).FirstOrDefault(p => p.Id == id) is { } row ? Ok(row) : NotFound(new { message = "Không tìm thấy khách hàng." });
    [HttpPost] public async Task<IActionResult> Create(CustomerInput input) => Ok(await store.SaveCustomerAsync(null, input));
    [HttpPut("{id:int}")] public async Task<IActionResult> Update(int id, CustomerInput input) => Ok(await store.SaveCustomerAsync(id, input));
    [HttpDelete("{id:int}")] public async Task<IActionResult> Delete(int id) { await store.DeleteCustomerAsync(id); return NoContent(); }
}

[ApiController, Authorize, Route("api/suppliers")]
public sealed class SuppliersController(StoreRepository store) : ControllerBase
{
    [HttpGet] public Task<List<SupplierDto>> List() => store.GetSuppliersAsync();
    [HttpPost, Authorize(Roles = "Admin")] public async Task<IActionResult> Create(SupplierInput input) => Ok(await store.SaveSupplierAsync(null, input));
    [HttpPut("{id:int}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Update(int id, SupplierInput input) => Ok(await store.SaveSupplierAsync(id, input));
    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Delete(int id) { await store.DeleteSupplierAsync(id); return NoContent(); }
}

[ApiController, Authorize, Route("api/catalogs")]
public sealed class CatalogsController(StoreRepository store) : ControllerBase
{
    [HttpGet] public Task<Dictionary<string, List<LookupDto>>> List() => store.GetCatalogsAsync();
    [HttpPost("{type}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Create(string type, LookupInput input) => Ok(await store.SaveCatalogAsync(type, null, input));
    [HttpPut("{type}/{id:int}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Update(string type, int id, LookupInput input) => Ok(await store.SaveCatalogAsync(type, id, input));
    [HttpDelete("{type}/{id:int}"), Authorize(Roles = "Admin")] public async Task<IActionResult> Delete(string type, int id) { await store.DeleteCatalogAsync(type, id); return NoContent(); }
}

[ApiController, Authorize, Route("api/sales")]
public sealed class SalesController(StoreRepository store) : ControllerBase
{
    [HttpGet] public Task<List<InvoiceDto>> List() => store.GetInvoicesAsync(false);
    [HttpGet("{id:int}")] public async Task<IActionResult> Get(int id) => (await store.GetInvoicesAsync(false)).FirstOrDefault(p => p.Id == id) is { } row ? Ok(row) : NotFound(new { message = "Không tìm thấy hóa đơn." });
    [HttpPost] public async Task<IActionResult> Create(InvoiceInput input) => Ok(await store.CreateInvoiceAsync(false, input, int.Parse(User.FindFirstValue("employeeId")!)));
    [HttpPost("{id:int}/cancel"), Authorize(Roles = "Admin")] public async Task<IActionResult> Cancel(int id) { await store.CancelInvoiceAsync(false, id, int.Parse(User.FindFirstValue("employeeId")!)); return Ok(new { message = "Đã hủy hóa đơn và hoàn tồn kho." }); }
}

[ApiController, Authorize(Roles = "Admin"), Route("api/purchases")]
public sealed class PurchasesController(StoreRepository store) : ControllerBase
{
    [HttpGet] public Task<List<InvoiceDto>> List() => store.GetInvoicesAsync(true);
    [HttpGet("{id:int}")] public async Task<IActionResult> Get(int id) => (await store.GetInvoicesAsync(true)).FirstOrDefault(p => p.Id == id) is { } row ? Ok(row) : NotFound(new { message = "Không tìm thấy phiếu nhập." });
    [HttpPost] public async Task<IActionResult> Create(InvoiceInput input) => Ok(await store.CreateInvoiceAsync(true, input, int.Parse(User.FindFirstValue("employeeId")!)));
    [HttpPost("{id:int}/cancel")] public async Task<IActionResult> Cancel(int id) { await store.CancelInvoiceAsync(true, id, int.Parse(User.FindFirstValue("employeeId")!)); return Ok(new { message = "Đã hủy phiếu nhập và cập nhật tồn kho." }); }
}
