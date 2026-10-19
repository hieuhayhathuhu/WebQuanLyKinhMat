using System.ComponentModel.DataAnnotations;

namespace KinhMat.Web.Models;

public sealed record ProductDto(int Id, string Name, string Brand, string Category,
    int? BrandId, int CategoryId, decimal Price, decimal Cost, int Stock, bool Active,
    string Material, string Color, string Shape, string Description, string ImageUrl,
    int? MaterialId, int? ColorId, int? ShapeId);

public sealed class ProductInput
{
    [Required(ErrorMessage = "Nhập tên sản phẩm."), StringLength(150, ErrorMessage = "Tên sản phẩm tối đa 150 ký tự.")] public string Name { get; set; } = "";
    [Range(1, int.MaxValue, ErrorMessage = "Chọn loại kính hợp lệ.")] public int CategoryId { get; set; }
    [Range(1, int.MaxValue)] public int? BrandId { get; set; }
    [Range(1, int.MaxValue)] public int? MaterialId { get; set; }
    [Range(1, int.MaxValue)] public int? ColorId { get; set; }
    [Range(1, int.MaxValue)] public int? ShapeId { get; set; }
    [Range(typeof(decimal), "0", "1100000000", ErrorMessage = "Giá bán phải từ 0 đến 1.100.000.000đ.")] public decimal Price { get; set; }
    [Range(typeof(decimal), "0", "1000000000", ErrorMessage = "Giá nhập phải từ 0 đến 1.000.000.000đ.")] public decimal Cost { get; set; }
    [Range(0, 1000000, ErrorMessage = "Tồn kho phải từ 0 đến 1.000.000 sản phẩm.")] public int Stock { get; set; }
    public bool Active { get; set; } = true;
    [StringLength(500)] public string? Description { get; set; }
    [StringLength(260)] public string? ImageUrl { get; set; }
}

public sealed record CustomerDto(int Id, string Name, string Phone, string Email, string Address, string Note);
public sealed class CustomerInput
{
    [Required(ErrorMessage = "Nhập tên khách hàng."), StringLength(100, ErrorMessage = "Tên khách hàng tối đa 100 ký tự.")] public string Name { get; set; } = "";
    [StringLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự."), RegularExpression(@"^(?=(?:\D*\d){8,15}\D*$)\+?[\d ()-]+$", ErrorMessage = "Số điện thoại cần từ 8 đến 15 chữ số.")]
    public string? Phone { get; set; }
    [StringLength(100, ErrorMessage = "Email tối đa 100 ký tự."), EmailAddress(ErrorMessage = "Email không hợp lệ.")] public string? Email { get; set; }
    [StringLength(255)] public string? Address { get; set; }
    [StringLength(500)] public string? Note { get; set; }
}

public sealed record SupplierDto(int Id, string Name, string Phone, string Email, string Address);
public sealed class SupplierInput
{
    [Required(ErrorMessage = "Nhập tên nhà cung cấp."), StringLength(150, ErrorMessage = "Tên nhà cung cấp tối đa 150 ký tự.")] public string Name { get; set; } = "";
    [StringLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự."), RegularExpression(@"^(?=(?:\D*\d){8,15}\D*$)\+?[\d ()-]+$", ErrorMessage = "Số điện thoại cần từ 8 đến 15 chữ số.")]
    public string? Phone { get; set; }
    [StringLength(100, ErrorMessage = "Email tối đa 100 ký tự."), EmailAddress(ErrorMessage = "Email không hợp lệ.")] public string? Email { get; set; }
    [StringLength(255)] public string? Address { get; set; }
}

public sealed record LookupDto(int Id, string Name, string? Country = null);
public sealed class LookupInput
{
    [Required(ErrorMessage = "Nhập tên danh mục."), StringLength(100, ErrorMessage = "Tên danh mục tối đa 100 ký tự.")] public string Name { get; set; } = "";
    [StringLength(100)] public string? Country { get; set; }
}

public sealed class InvoiceInput
{
    public Guid Token { get; set; }
    [Range(1, int.MaxValue)] public int? CustomerId { get; set; }
    [Range(1, int.MaxValue)] public int? SupplierId { get; set; }
    [Required(ErrorMessage = "Chọn sản phẩm cho chứng từ."), MinLength(1, ErrorMessage = "Chọn ít nhất một sản phẩm."), MaxLength(500, ErrorMessage = "Một chứng từ tối đa 500 dòng.")] public List<InvoiceLineInput> Items { get; set; } = [];
}

public sealed class InvoiceLineInput
{
    [Range(1, int.MaxValue)] public int ProductId { get; set; }
    [Range(1, 10000, ErrorMessage = "Số lượng phải từ 1 đến 10.000.")] public int Quantity { get; set; }
    [Range(typeof(decimal), "0", "1100000000")] public decimal UnitPrice { get; set; }
    [Range(typeof(decimal), "0", "100", ErrorMessage = "Giảm giá phải từ 0 đến 100%.")] public decimal Discount { get; set; }
}

public sealed record InvoiceItemDto(int ProductId, string Name, int Quantity,
    decimal UnitPrice, decimal Discount, decimal Total);

public sealed record InvoiceDto(int Id, string Code, string Date, int? CustomerId,
    int? SupplierId, string Supplier, string Status, decimal Total,
    List<InvoiceItemDto> Items, string EmployeeName, int EmployeeId);
