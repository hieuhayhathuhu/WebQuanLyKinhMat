using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Globalization;
using KinhMat.Web.Models;
using Microsoft.Data.SqlClient;

namespace KinhMat.Web.Data;

public sealed class StoreRepository(SqlDatabase database)
{
    private sealed record Catalog(string Table, string Key, string Name, int MaximumLength, string? ProductText = null);
    private static readonly IReadOnlyDictionary<string, Catalog> Catalogs = new Dictionary<string, Catalog>(StringComparer.Ordinal)
    {
        ["categories"] = new("LoaiSanPham", "MaLoai", "TenLoai", 100),
        ["brands"] = new("ThuongHieu", "MaThuongHieu", "TenThuongHieu", 100),
        ["materials"] = new("ChatLieu", "MaChatLieu", "TenChatLieu", 100, "ChatLieu"),
        ["colors"] = new("MauSac", "MaMauSac", "TenMauSac", 50, "MauSac"),
        ["shapes"] = new("HinhDang", "MaHinhDang", "TenHinhDang", 100, "HinhDang")
    };

    private const string ProductSelect = """
        SELECT p.MaSanPham Id,p.TenSanPham Name,COALESCE(b.TenThuongHieu,N'') Brand,l.TenLoai Category,
            p.MaThuongHieu BrandId,p.MaLoai CategoryId,p.GiaBan Price,p.GiaNhap Cost,p.SoLuongTon Stock,p.TrangThai Active,
            COALESCE(m.TenChatLieu,p.ChatLieu,N'') Material,COALESCE(c.TenMauSac,p.MauSac,N'') Color,
            COALESCE(s.TenHinhDang,p.HinhDang,N'') Shape,COALESCE(p.MoTa,N'') Description,COALESCE(p.HinhAnh,N'') ImageUrl,
            p.MaChatLieu MaterialId,p.MaMauSac ColorId,p.MaHinhDang ShapeId
        FROM dbo.SanPham p JOIN dbo.LoaiSanPham l ON l.MaLoai=p.MaLoai
        LEFT JOIN dbo.ThuongHieu b ON b.MaThuongHieu=p.MaThuongHieu
        LEFT JOIN dbo.ChatLieu m ON m.MaChatLieu=p.MaChatLieu
        LEFT JOIN dbo.MauSac c ON c.MaMauSac=p.MaMauSac
        LEFT JOIN dbo.HinhDang s ON s.MaHinhDang=p.MaHinhDang
        """;

    public async Task<List<ProductDto>> GetProductsAsync()
    {
        await using var connection = await database.OpenAsync();
        return await ReadProductsAsync(connection, null, null);
    }

    public async Task<ProductDto> SaveProductAsync(int? id, ProductInput input)
    {
        Validate(input);
        Money(input.Price); Money(input.Cost);
        var name = input.Name.Trim();
        var image = Trim(input.ImageUrl);
        if (image is not null && !(image.StartsWith('/') && !image.StartsWith("//", StringComparison.Ordinal))
            && !(Uri.TryCreate(image, UriKind.Absolute, out var imageUri) && imageUri.Scheme is "http" or "https"))
            throw new BusinessException("Ảnh sản phẩm phải là đường dẫn trên website hoặc URL http/https.");
        return await WriteAsync(async (connection, transaction) =>
        {
            if (id.HasValue)
            {
                var stock = await ScalarAsync(connection, transaction,
                    "SELECT SoLuongTon FROM dbo.SanPham WITH(UPDLOCK,HOLDLOCK) WHERE MaSanPham=@id", ("@id", id));
                if (stock is null) throw Missing("Sản phẩm");
                if (Convert.ToInt32(stock) != input.Stock && await ProductReferencedAsync(connection, transaction, id.Value))
                    throw new BusinessException("Sản phẩm đã có chứng từ. Hãy thay đổi tồn kho bằng nhập/bán hàng.", 409);
            }
            if (await ScalarAsync(connection, transaction,
                "SELECT TOP(1) MaSanPham FROM dbo.SanPham WITH(UPDLOCK,HOLDLOCK) WHERE LTRIM(RTRIM(TenSanPham))=@name AND (@id IS NULL OR MaSanPham<>@id)",
                ("@name", name), ("@id", id)) is not null)
                throw new BusinessException("Tên sản phẩm đã tồn tại.", 409);
            await ProductLookupAsync(connection, transaction, "categories", input.CategoryId);
            await ProductLookupAsync(connection, transaction, "brands", input.BrandId);
            var material = await ProductLookupAsync(connection, transaction, "materials", input.MaterialId);
            var color = await ProductLookupAsync(connection, transaction, "colors", input.ColorId);
            var shape = await ProductLookupAsync(connection, transaction, "shapes", input.ShapeId);
            var parameters = new (string, object?)[]
            {
                ("@id", id), ("@name", name), ("@category", input.CategoryId), ("@brand", input.BrandId),
                ("@materialId", input.MaterialId), ("@colorId", input.ColorId), ("@shapeId", input.ShapeId),
                ("@material", material), ("@color", color), ("@shape", shape), ("@price", input.Price),
                ("@cost", input.Cost), ("@stock", input.Stock), ("@active", input.Active),
                ("@description", Trim(input.Description)), ("@image", image)
            };
            int savedId;
            if (id.HasValue)
            {
                await ExecuteAsync(connection, transaction, """
                    UPDATE dbo.SanPham SET TenSanPham=@name,MaLoai=@category,MaThuongHieu=@brand,
                        MaChatLieu=@materialId,MaMauSac=@colorId,MaHinhDang=@shapeId,
                        ChatLieu=@material,MauSac=@color,HinhDang=@shape,GiaNhap=@cost,GiaBan=@price,
                        SoLuongTon=@stock,TrangThai=@active,MoTa=@description,HinhAnh=@image
                    WHERE MaSanPham=@id;
                    IF NOT EXISTS(SELECT 1 FROM dbo.ChiTietPhieuNhap d JOIN dbo.PhieuNhap h ON h.MaPhieuNhap=d.MaPhieuNhap WHERE d.MaSanPham=@id AND h.DaHuy=0)
                        UPDATE dbo.SanPham SET GiaNhapGoc=@cost,GiaBanGoc=@price WHERE MaSanPham=@id;
                    """, parameters);
                savedId = id.Value;
            }
            else
                savedId = Convert.ToInt32(await ScalarAsync(connection, transaction, """
                    INSERT dbo.SanPham(TenSanPham,MaLoai,MaThuongHieu,MaChatLieu,MaMauSac,MaHinhDang,
                        ChatLieu,MauSac,HinhDang,GiaNhap,GiaBan,SoLuongTon,TrangThai,MoTa,HinhAnh,GiaNhapGoc,GiaBanGoc)
                    VALUES(@name,@category,@brand,@materialId,@colorId,@shapeId,@material,@color,@shape,
                        @cost,@price,@stock,@active,@description,@image,@cost,@price);
                    SELECT CAST(SCOPE_IDENTITY() AS int);
                    """, parameters));
            return (await ReadProductsAsync(connection, transaction, savedId)).Single();
        });
    }

    public async Task DeleteProductAsync(int id)
    {
        await WriteAsync(async (connection, transaction) =>
        {
            await RequireRowAsync(connection, transaction, "SanPham", "MaSanPham", id, "Sản phẩm");
            if (await ProductReferencedAsync(connection, transaction, id))
                throw new BusinessException("Sản phẩm đã có chứng từ; hãy chuyển trạng thái sang ngừng kinh doanh.", 409);
            await ExecuteAsync(connection, transaction, "DELETE dbo.SanPham WHERE MaSanPham=@id", ("@id", id));
            return true;
        });
    }

    public async Task<List<CustomerDto>> GetCustomersAsync()
    {
        await using var connection = await database.OpenAsync();
        return await ReadCustomersAsync(connection, null, null);
    }

    public async Task<CustomerDto> SaveCustomerAsync(int? id, CustomerInput input)
    {
        input.Phone = Trim(input.Phone); input.Email = Trim(input.Email);
        Validate(input);
        return await WriteAsync(async (connection, transaction) =>
        {
            if (id.HasValue) await RequireRowAsync(connection, transaction, "KhachHang", "MaKhachHang", id.Value, "Khách hàng");
            if (input.Phone is not null && await ScalarAsync(connection, transaction,
                "SELECT TOP(1) MaKhachHang FROM dbo.KhachHang WITH(UPDLOCK,HOLDLOCK) WHERE SoDienThoai=@phone AND (@id IS NULL OR MaKhachHang<>@id)",
                ("@phone", input.Phone), ("@id", id)) is not null)
                throw new BusinessException("Số điện thoại đã được dùng cho khách hàng khác.", 409);
            var parameters = new (string, object?)[] { ("@id", id), ("@name", input.Name.Trim()), ("@phone", input.Phone),
                ("@email", input.Email), ("@address", Trim(input.Address)), ("@note", Trim(input.Note)) };
            int savedId;
            if (id.HasValue)
            {
                await ExecuteAsync(connection, transaction, "UPDATE dbo.KhachHang SET HoTen=@name,SoDienThoai=@phone,Email=@email,DiaChi=@address,GhiChu=@note WHERE MaKhachHang=@id", parameters);
                savedId = id.Value;
            }
            else savedId = Convert.ToInt32(await ScalarAsync(connection, transaction,
                "INSERT dbo.KhachHang(HoTen,SoDienThoai,Email,DiaChi,GhiChu) VALUES(@name,@phone,@email,@address,@note); SELECT CAST(SCOPE_IDENTITY() AS int)", parameters));
            return (await ReadCustomersAsync(connection, transaction, savedId)).Single();
        });
    }

    public async Task DeleteCustomerAsync(int id)
    {
        await WriteAsync(async (connection, transaction) =>
        {
            await RequireRowAsync(connection, transaction, "KhachHang", "MaKhachHang", id, "Khách hàng");
            if (await ScalarAsync(connection, transaction, "SELECT TOP(1) MaHoaDon FROM dbo.HoaDonBan WITH(UPDLOCK,HOLDLOCK) WHERE MaKhachHang=@id", ("@id", id)) is not null)
                throw new BusinessException("Khách hàng đã có hóa đơn, không thể xóa để giữ lịch sử.", 409);
            await ExecuteAsync(connection, transaction, "DELETE dbo.KhachHang WHERE MaKhachHang=@id", ("@id", id));
            return true;
        });
    }

    public async Task<List<SupplierDto>> GetSuppliersAsync()
    {
        await using var connection = await database.OpenAsync();
        return await ReadSuppliersAsync(connection, null, null);
    }

    public async Task<SupplierDto> SaveSupplierAsync(int? id, SupplierInput input)
    {
        input.Phone = Trim(input.Phone); input.Email = Trim(input.Email);
        Validate(input);
        return await WriteAsync(async (connection, transaction) =>
        {
            if (id.HasValue) await RequireRowAsync(connection, transaction, "NhaCungCap", "MaNhaCungCap", id.Value, "Nhà cung cấp");
            var parameters = new (string, object?)[] { ("@id", id), ("@name", input.Name.Trim()), ("@phone", input.Phone),
                ("@email", input.Email), ("@address", Trim(input.Address)) };
            int savedId;
            if (id.HasValue)
            {
                await ExecuteAsync(connection, transaction, "UPDATE dbo.NhaCungCap SET TenNhaCungCap=@name,SoDienThoai=@phone,Email=@email,DiaChi=@address WHERE MaNhaCungCap=@id", parameters);
                savedId = id.Value;
            }
            else savedId = Convert.ToInt32(await ScalarAsync(connection, transaction,
                "INSERT dbo.NhaCungCap(TenNhaCungCap,SoDienThoai,Email,DiaChi) VALUES(@name,@phone,@email,@address); SELECT CAST(SCOPE_IDENTITY() AS int)", parameters));
            return (await ReadSuppliersAsync(connection, transaction, savedId)).Single();
        });
    }

    public async Task DeleteSupplierAsync(int id)
    {
        await WriteAsync(async (connection, transaction) =>
        {
            await RequireRowAsync(connection, transaction, "NhaCungCap", "MaNhaCungCap", id, "Nhà cung cấp");
            if (await ScalarAsync(connection, transaction, "SELECT TOP(1) MaPhieuNhap FROM dbo.PhieuNhap WITH(UPDLOCK,HOLDLOCK) WHERE MaNhaCungCap=@id", ("@id", id)) is not null)
                throw new BusinessException("Nhà cung cấp đã có phiếu nhập, không thể xóa để giữ lịch sử.", 409);
            await ExecuteAsync(connection, transaction, "DELETE dbo.NhaCungCap WHERE MaNhaCungCap=@id", ("@id", id));
            return true;
        });
    }

    public async Task<Dictionary<string, List<LookupDto>>> GetCatalogsAsync()
    {
        await using var connection = await database.OpenAsync();
        var result = new Dictionary<string, List<LookupDto>>();
        foreach (var (type, catalog) in Catalogs)
            result[type] = await ReadCatalogAsync(connection, null, catalog);
        return result;
    }

    public async Task<LookupDto> SaveCatalogAsync(string type, int? id, LookupInput input)
    {
        var catalog = GetCatalog(type);
        Validate(input);
        var name = input.Name.Trim();
        if (name.Length > catalog.MaximumLength)
            throw new BusinessException($"Tên danh mục không được vượt quá {catalog.MaximumLength} ký tự.");
        return await WriteAsync(async (connection, transaction) =>
        {
            if (id.HasValue) await RequireRowAsync(connection, transaction, catalog.Table, catalog.Key, id.Value, "Danh mục");
            if (await ScalarAsync(connection, transaction,
                $"SELECT TOP(1) [{catalog.Key}] FROM dbo.[{catalog.Table}] WITH(UPDLOCK,HOLDLOCK) WHERE LTRIM(RTRIM([{catalog.Name}]))=@name AND (@id IS NULL OR [{catalog.Key}]<>@id)",
                ("@name", name), ("@id", id)) is not null)
                throw new BusinessException("Tên danh mục đã tồn tại.", 409);
            bool brand = type == "brands";
            int savedId;
            if (id.HasValue)
            {
                await ExecuteAsync(connection, transaction,
                    $"UPDATE dbo.[{catalog.Table}] SET [{catalog.Name}]=@name{(brand ? ",QuocGia=@country" : "")} WHERE [{catalog.Key}]=@id",
                    ("@id", id), ("@name", name), ("@country", Trim(input.Country)));
                if (catalog.ProductText is not null)
                    await ExecuteAsync(connection, transaction,
                        $"UPDATE dbo.SanPham SET [{catalog.ProductText}]=@name WHERE [{catalog.Key}]=@id", ("@id", id), ("@name", name));
                savedId = id.Value;
            }
            else savedId = Convert.ToInt32(await ScalarAsync(connection, transaction,
                $"INSERT dbo.[{catalog.Table}]([{catalog.Name}]{(brand ? ",QuocGia" : "")}) VALUES(@name{(brand ? ",@country" : "")}); SELECT CAST(SCOPE_IDENTITY() AS int)",
                ("@name", name), ("@country", Trim(input.Country))));
            return new LookupDto(savedId, name, brand ? Trim(input.Country) : null);
        });
    }

    public async Task DeleteCatalogAsync(string type, int id)
    {
        var catalog = GetCatalog(type);
        await WriteAsync(async (connection, transaction) =>
        {
            await RequireRowAsync(connection, transaction, catalog.Table, catalog.Key, id, "Danh mục");
            if (await ScalarAsync(connection, transaction,
                $"SELECT TOP(1) MaSanPham FROM dbo.SanPham WITH(UPDLOCK,HOLDLOCK) WHERE [{catalog.Key}]=@id", ("@id", id)) is not null)
                throw new BusinessException("Danh mục đang được sản phẩm sử dụng, không thể xóa.", 409);
            await ExecuteAsync(connection, transaction, $"DELETE dbo.[{catalog.Table}] WHERE [{catalog.Key}]=@id", ("@id", id));
            return true;
        });
    }

    public async Task<List<InvoiceDto>> GetInvoicesAsync(bool inbound)
    {
        await using var connection = await database.OpenAsync();
        return await ReadInvoicesAsync(connection, null, inbound, null);
    }

    public async Task<InvoiceDto> CreateInvoiceAsync(bool inbound, InvoiceInput input, int employeeId)
    {
        Validate(input);
        if (input.Token == Guid.Empty) throw new BusinessException("Thiếu mã chống lưu trùng hóa đơn.");
        if (input.Items.Any(item => item is null)) throw new BusinessException("Dòng sản phẩm không hợp lệ.");
        foreach (var line in input.Items) { Validate(line); Money(line.UnitPrice); Money(line.Discount); }
        if (input.Items.Select(x => x.ProductId).Distinct().Count() != input.Items.Count)
            throw new BusinessException("Mỗi sản phẩm chỉ được xuất hiện một lần trong chứng từ.");
        if (inbound && !input.SupplierId.HasValue) throw new BusinessException("Chọn nhà cung cấp cho phiếu nhập.");
        if (inbound && input.CustomerId.HasValue || !inbound && input.SupplierId.HasValue)
            throw new BusinessException("Thông tin đối tác không phù hợp loại chứng từ.");
        if (inbound && input.Items.Any(x => x.UnitPrice > 1_000_000_000m))
            throw new BusinessException("Đơn giá nhập không được vượt quá 1 tỷ đồng.");
        string header = inbound ? "PhieuNhap" : "HoaDonBan", detail = inbound ? "ChiTietPhieuNhap" : "ChiTietHoaDonBan";
        string key = inbound ? "MaPhieuNhap" : "MaHoaDon", priceColumn = inbound ? "DonGiaNhap" : "DonGiaBan";
        return await WriteAsync(async (connection, transaction) =>
        {
            await RequireEmployeeAsync(connection, transaction, employeeId);
            // The SQL transaction lock also covers the idempotency check and code allocation across application instances.
            var lockResult = Convert.ToInt32(await ScalarAsync(connection, transaction,
                "DECLARE @result int; EXEC @result=sys.sp_getapplock @Resource=@resource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000; SELECT @result",
                ("@resource", "KinhMat.Web:Invoice:" + header)));
            if (lockResult < 0) throw new BusinessException("Đang có chứng từ khác được lưu. Vui lòng thử lại.", 409);
            var existing = await ScalarAsync(connection, transaction,
                $"SELECT [{key}] FROM dbo.[{header}] WITH(UPDLOCK,HOLDLOCK) WHERE TokenLuu=@token", ("@token", input.Token));
            if (existing is not null)
            {
                var saved = (await ReadInvoicesAsync(connection, transaction, inbound, Convert.ToInt32(existing))).Single();
                if (!SameInvoice(saved, input, inbound, employeeId))
                    throw new BusinessException("Mã lưu đã được dùng cho một chứng từ khác. Hãy tạo chứng từ mới.", 409);
                return saved;
            }
            if (inbound) await RequireRowAsync(connection, transaction, "NhaCungCap", "MaNhaCungCap", input.SupplierId!.Value, "Nhà cung cấp");
            else if (input.CustomerId.HasValue) await RequireRowAsync(connection, transaction, "KhachHang", "MaKhachHang", input.CustomerId.Value, "Khách hàng");
            var products = new Dictionary<int, (string Name, int Stock, decimal Cost, decimal Price)>();
            foreach (var line in input.Items.OrderBy(x => x.ProductId))
            {
                await using var command = Command(connection, transaction,
                    "SELECT TenSanPham,SoLuongTon,GiaNhap,GiaBan,TrangThai FROM dbo.SanPham WITH(UPDLOCK,HOLDLOCK) WHERE MaSanPham=@id", ("@id", line.ProductId));
                await using var reader = await command.ExecuteReaderAsync();
                if (!await reader.ReadAsync()) throw new BusinessException("Sản phẩm không còn tồn tại. Hãy tải lại danh sách.", 409);
                var product = (Name: reader.GetString(0), Stock: reader.GetInt32(1), Cost: reader.GetDecimal(2), Price: reader.GetDecimal(3));
                if (!reader.GetBoolean(4)) throw new BusinessException($"{product.Name} đã ngừng kinh doanh.", 409);
                if (!inbound && product.Stock < line.Quantity) throw new BusinessException($"{product.Name}: chỉ còn {product.Stock} sản phẩm.", 409);
                if (inbound && product.Stock > 1_000_000 - line.Quantity) throw new BusinessException($"{product.Name}: tồn kho vượt giới hạn 1.000.000.");
                if (!inbound && product.Price != line.UnitPrice)
                    throw new BusinessException($"{product.Name}: giá bán đã thay đổi. Hãy tải lại và kiểm tra hóa đơn.", 409);
                products[line.ProductId] = product;
            }
            var date = DateTime.Now;
            string prefix = (inbound ? "HĐN_" : "HĐB_") + date.ToString("ddMMyyyy", CultureInfo.InvariantCulture);
            int sequence = Convert.ToInt32(await ScalarAsync(connection, transaction,
                $"SELECT COALESCE(MAX(TRY_CONVERT(int,SUBSTRING(SoHoaDon,LEN(@prefix)+1,20))),0)+1 FROM dbo.[{header}] WHERE LEFT(SoHoaDon,LEN(@prefix))=@prefix", ("@prefix", prefix)));
            string code = prefix + sequence.ToString("0000", CultureInfo.InvariantCulture);
            decimal total = input.Items.Sum(LineTotal);
            int id = Convert.ToInt32(await ScalarAsync(connection, transaction,
                $"INSERT dbo.[{header}]({(inbound ? "MaNhaCungCap" : "MaKhachHang")},MaNhanVien,{(inbound ? "NgayNhap" : "NgayBan")},TongTien,SoHoaDon,TokenLuu) VALUES(@partner,@employee,@date,@total,@code,@token); SELECT CAST(SCOPE_IDENTITY() AS int)",
                ("@partner", inbound ? input.SupplierId : input.CustomerId), ("@employee", employeeId), ("@date", date), ("@total", total), ("@code", code), ("@token", input.Token)));
            foreach (var line in input.Items.OrderBy(x => x.ProductId))
            {
                var product = products[line.ProductId];
                await ExecuteAsync(connection, transaction,
                    $"INSERT dbo.[{detail}]([{key}],MaSanPham,SoLuong,[{priceColumn}],GiamGia,ThanhTienChot{(inbound ? ",GiaNhapTruoc,GiaBanTruoc" : "")}) VALUES(@id,@product,@quantity,@price,@discount,@amount{(inbound ? ",@oldCost,@oldPrice" : "")})",
                    ("@id", id), ("@product", line.ProductId), ("@quantity", line.Quantity), ("@price", line.UnitPrice),
                    ("@discount", line.Discount), ("@amount", LineTotal(line)), ("@oldCost", product.Cost), ("@oldPrice", product.Price));
                await ExecuteAsync(connection, transaction,
                    "UPDATE dbo.SanPham SET SoLuongTon=SoLuongTon" + (inbound ? "+" : "-") + "@quantity" +
                    (inbound ? ",GiaNhapGoc=COALESCE(GiaNhapGoc,GiaNhap),GiaBanGoc=COALESCE(GiaBanGoc,GiaBan),GiaNhap=@cost,GiaBan=@price" : "") + " WHERE MaSanPham=@product",
                    ("@quantity", line.Quantity), ("@cost", line.UnitPrice), ("@price", SalePrice(line.UnitPrice)), ("@product", line.ProductId));
            }
            return (await ReadInvoicesAsync(connection, transaction, inbound, id)).Single();
        });
    }

    public async Task CancelInvoiceAsync(bool inbound, int id, int employeeId)
    {
        string header = inbound ? "PhieuNhap" : "HoaDonBan", detail = inbound ? "ChiTietPhieuNhap" : "ChiTietHoaDonBan";
        string key = inbound ? "MaPhieuNhap" : "MaHoaDon";
        await WriteAsync(async (connection, transaction) =>
        {
            await RequireEmployeeAsync(connection, transaction, employeeId);
            var cancelled = await ScalarAsync(connection, transaction,
                $"SELECT DaHuy FROM dbo.[{header}] WITH(UPDLOCK,HOLDLOCK) WHERE [{key}]=@id", ("@id", id));
            if (cancelled is null) throw Missing("Chứng từ");
            if (Convert.ToBoolean(cancelled)) return true;
            var lines = new List<(int ProductId, int Quantity)>();
            await using (var command = Command(connection, transaction,
                $"SELECT MaSanPham,SoLuong FROM dbo.[{detail}] WHERE [{key}]=@id ORDER BY MaSanPham", ("@id", id)))
            await using (var reader = await command.ExecuteReaderAsync())
                while (await reader.ReadAsync()) lines.Add((reader.GetInt32(0), reader.GetInt32(1)));
            foreach (var line in lines)
            {
                int stock = Convert.ToInt32(await ScalarAsync(connection, transaction,
                    "SELECT SoLuongTon FROM dbo.SanPham WITH(UPDLOCK,HOLDLOCK) WHERE MaSanPham=@product", ("@product", line.ProductId)));
                if (inbound && stock < line.Quantity)
                    throw new BusinessException("Hàng nhập đã được bán hoặc xuất bớt; không đủ tồn kho để hủy phiếu nhập.", 409);
                if (!inbound && stock > 1_000_000 - line.Quantity)
                    throw new BusinessException("Hoàn hàng sẽ vượt giới hạn tồn kho 1.000.000.", 409);
                await ExecuteAsync(connection, transaction,
                    "UPDATE dbo.SanPham SET SoLuongTon=SoLuongTon" + (inbound ? "-" : "+") + "@quantity WHERE MaSanPham=@product",
                    ("@quantity", line.Quantity), ("@product", line.ProductId));
            }
            await ExecuteAsync(connection, transaction, $"UPDATE dbo.[{header}] SET DaHuy=1 WHERE [{key}]=@id", ("@id", id));
            if (inbound)
                foreach (var line in lines)
                    await ExecuteAsync(connection, transaction, """
                        UPDATE p SET GiaNhap=COALESCE(x.DonGiaNhap,p.GiaNhapGoc,p.GiaNhap),
                            GiaBan=CASE WHEN x.DonGiaNhap IS NULL THEN COALESCE(p.GiaBanGoc,p.GiaBan) ELSE ROUND(x.DonGiaNhap*1.1,2) END
                        FROM dbo.SanPham p OUTER APPLY(
                            SELECT TOP(1) d.DonGiaNhap FROM dbo.ChiTietPhieuNhap d JOIN dbo.PhieuNhap h ON h.MaPhieuNhap=d.MaPhieuNhap
                            WHERE d.MaSanPham=p.MaSanPham AND h.DaHuy=0 ORDER BY h.NgayNhap DESC,h.MaPhieuNhap DESC
                        ) x WHERE p.MaSanPham=@product;
                        """, ("@product", line.ProductId));
            return true;
        });
    }

    private static async Task<List<ProductDto>> ReadProductsAsync(SqlConnection connection, SqlTransaction? transaction, int? id)
    {
        await using var command = Command(connection, transaction,
            ProductSelect + (id.HasValue ? " WHERE p.MaSanPham=@id" : "") + " ORDER BY p.MaSanPham DESC", ("@id", id));
        await using var reader = await command.ExecuteReaderAsync();
        var result = new List<ProductDto>();
        while (await reader.ReadAsync())
            result.Add(new ProductDto(I(reader, "Id"), S(reader, "Name"), S(reader, "Brand"), S(reader, "Category"),
                N(reader, "BrandId"), I(reader, "CategoryId"), D(reader, "Price"), D(reader, "Cost"), I(reader, "Stock"),
                reader.GetBoolean(reader.GetOrdinal("Active")), S(reader, "Material"), S(reader, "Color"), S(reader, "Shape"),
                S(reader, "Description"), S(reader, "ImageUrl"), N(reader, "MaterialId"), N(reader, "ColorId"), N(reader, "ShapeId")));
        return result;
    }

    private static async Task<List<CustomerDto>> ReadCustomersAsync(SqlConnection connection, SqlTransaction? transaction, int? id)
    {
        await using var command = Command(connection, transaction,
            "SELECT MaKhachHang,HoTen,SoDienThoai,Email,DiaChi,GhiChu FROM dbo.KhachHang" + (id.HasValue ? " WHERE MaKhachHang=@id" : "") + " ORDER BY MaKhachHang DESC", ("@id", id));
        await using var reader = await command.ExecuteReaderAsync();
        var result = new List<CustomerDto>();
        while (await reader.ReadAsync()) result.Add(new CustomerDto(reader.GetInt32(0), S(reader, "HoTen"), S(reader, "SoDienThoai"), S(reader, "Email"), S(reader, "DiaChi"), S(reader, "GhiChu")));
        return result;
    }

    private static async Task<List<SupplierDto>> ReadSuppliersAsync(SqlConnection connection, SqlTransaction? transaction, int? id)
    {
        await using var command = Command(connection, transaction,
            "SELECT MaNhaCungCap,TenNhaCungCap,SoDienThoai,Email,DiaChi FROM dbo.NhaCungCap" + (id.HasValue ? " WHERE MaNhaCungCap=@id" : "") + " ORDER BY MaNhaCungCap DESC", ("@id", id));
        await using var reader = await command.ExecuteReaderAsync();
        var result = new List<SupplierDto>();
        while (await reader.ReadAsync()) result.Add(new SupplierDto(reader.GetInt32(0), S(reader, "TenNhaCungCap"), S(reader, "SoDienThoai"), S(reader, "Email"), S(reader, "DiaChi")));
        return result;
    }

    private static async Task<List<LookupDto>> ReadCatalogAsync(SqlConnection connection, SqlTransaction? transaction, Catalog catalog)
    {
        await using var command = Command(connection, transaction,
            $"SELECT [{catalog.Key}],[{catalog.Name}]{(catalog.Table == "ThuongHieu" ? ",QuocGia" : "")} FROM dbo.[{catalog.Table}] ORDER BY [{catalog.Name}],[{catalog.Key}]");
        await using var reader = await command.ExecuteReaderAsync();
        var result = new List<LookupDto>();
        while (await reader.ReadAsync()) result.Add(new LookupDto(reader.GetInt32(0), reader.GetString(1), catalog.Table == "ThuongHieu" && !reader.IsDBNull(2) ? reader.GetString(2) : null));
        return result;
    }

    private static async Task<List<InvoiceDto>> ReadInvoicesAsync(SqlConnection connection, SqlTransaction? transaction, bool inbound, int? id)
    {
        string header = inbound ? "PhieuNhap" : "HoaDonBan", detail = inbound ? "ChiTietPhieuNhap" : "ChiTietHoaDonBan";
        string key = inbound ? "MaPhieuNhap" : "MaHoaDon", price = inbound ? "DonGiaNhap" : "DonGiaBan";
        string party = inbound ? "n.TenNhaCungCap" : "CAST(N'' AS nvarchar(150))";
        string partnerId = inbound ? "MaNhaCungCap" : "MaKhachHang";
        await using var command = Command(connection, transaction, $"""
            SELECT h.[{key}] Id,COALESCE(h.SoHoaDon,CONVERT(nvarchar(40),h.[{key}])) Code,
                h.[{(inbound ? "NgayNhap" : "NgayBan")}] Date,h.[{partnerId}] PartnerId,
                {party} Supplier,h.DaHuy,h.TongTien,h.MaNhanVien EmployeeId,COALESCE(e.HoTen,N'') EmployeeName
            FROM dbo.[{header}] h LEFT JOIN dbo.NhanVien e ON e.MaNhanVien=h.MaNhanVien
            {(inbound ? "LEFT JOIN dbo.NhaCungCap n ON n.MaNhaCungCap=h.MaNhaCungCap" : "")}
            {(id.HasValue ? $"WHERE h.[{key}]=@id" : "")}
            ORDER BY h.[{(inbound ? "NgayNhap" : "NgayBan")}] DESC,h.[{key}] DESC;
            SELECT d.[{key}] InvoiceId,d.MaSanPham,p.TenSanPham,d.SoLuong,d.[{price}] UnitPrice,d.GiamGia,
                COALESCE(d.ThanhTienChot,ROUND(d.SoLuong*d.[{price}]*(100-d.GiamGia)/100,2)) Total
            FROM dbo.[{detail}] d JOIN dbo.SanPham p ON p.MaSanPham=d.MaSanPham
            {(id.HasValue ? $"WHERE d.[{key}]=@id" : "")}
            ORDER BY d.[{key}],d.MaSanPham;
            """, ("@id", id));
        await using var reader = await command.ExecuteReaderAsync();
        var result = new List<InvoiceDto>();
        var index = new Dictionary<int, InvoiceDto>();
        while (await reader.ReadAsync())
        {
            int invoiceId = I(reader, "Id");
            var invoice = new InvoiceDto(invoiceId, S(reader, "Code"), reader.GetDateTime(reader.GetOrdinal("Date")).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                inbound ? null : N(reader, "PartnerId"), inbound ? N(reader, "PartnerId") : null,
                S(reader, "Supplier"), reader.GetBoolean(reader.GetOrdinal("DaHuy")) ? "cancelled" : "completed",
                D(reader, "TongTien"), [], S(reader, "EmployeeName"), I(reader, "EmployeeId"));
            result.Add(invoice); index[invoiceId] = invoice;
        }
        await reader.NextResultAsync();
        while (await reader.ReadAsync())
            if (index.TryGetValue(I(reader, "InvoiceId"), out var invoice))
                invoice.Items.Add(new InvoiceItemDto(I(reader, "MaSanPham"), S(reader, "TenSanPham"), I(reader, "SoLuong"), D(reader, "UnitPrice"), D(reader, "GiamGia"), D(reader, "Total")));
        return result;
    }

    private static bool SameInvoice(InvoiceDto saved, InvoiceInput input, bool inbound, int employeeId)
    {
        if (saved.EmployeeId != employeeId || (inbound ? saved.SupplierId != input.SupplierId : saved.CustomerId != input.CustomerId)
            || saved.Items.Count != input.Items.Count) return false;
        var expected = input.Items.OrderBy(x => x.ProductId).ToArray();
        var actual = saved.Items.OrderBy(x => x.ProductId).ToArray();
        return expected.Select((line, i) => line.ProductId == actual[i].ProductId && line.Quantity == actual[i].Quantity
            && line.UnitPrice == actual[i].UnitPrice && line.Discount == actual[i].Discount).All(x => x);
    }

    private static async Task<string?> ProductLookupAsync(SqlConnection connection, SqlTransaction transaction, string type, int? id)
    {
        if (!id.HasValue) return null;
        var catalog = GetCatalog(type);
        var value = await ScalarAsync(connection, transaction,
            $"SELECT [{catalog.Name}] FROM dbo.[{catalog.Table}] WITH(UPDLOCK,HOLDLOCK) WHERE [{catalog.Key}]=@id", ("@id", id));
        if (value is null) throw new BusinessException("Danh mục đã thay đổi hoặc không còn tồn tại. Hãy tải lại danh sách.", 409);
        var name = Convert.ToString(value)!;
        if (name.Length > catalog.MaximumLength) throw new BusinessException($"Tên danh mục quá dài (tối đa {catalog.MaximumLength} ký tự).");
        return name;
    }

    private static async Task<bool> ProductReferencedAsync(SqlConnection connection, SqlTransaction transaction, int id) =>
        Convert.ToInt32(await ScalarAsync(connection, transaction, """
            SELECT CASE WHEN EXISTS(SELECT 1 FROM dbo.ChiTietHoaDonBan WITH(UPDLOCK,HOLDLOCK) WHERE MaSanPham=@id)
                OR EXISTS(SELECT 1 FROM dbo.ChiTietPhieuNhap WITH(UPDLOCK,HOLDLOCK) WHERE MaSanPham=@id) THEN 1 ELSE 0 END
            """, ("@id", id))) == 1;

    private static async Task RequireEmployeeAsync(SqlConnection connection, SqlTransaction transaction, int employeeId)
    {
        if (employeeId <= 0 || await ScalarAsync(connection, transaction,
            "SELECT MaNhanVien FROM dbo.NhanVien WITH(HOLDLOCK) WHERE MaNhanVien=@id AND TrangThai=1", ("@id", employeeId)) is null)
            throw new BusinessException("Tài khoản nhân viên không còn hoạt động. Vui lòng đăng nhập lại.", 401);
    }

    private static async Task RequireRowAsync(SqlConnection connection, SqlTransaction transaction, string table, string key, int id, string label)
    {
        if (id <= 0 || await ScalarAsync(connection, transaction,
            $"SELECT [{key}] FROM dbo.[{table}] WITH(UPDLOCK,HOLDLOCK) WHERE [{key}]=@id", ("@id", id)) is null) throw Missing(label);
    }

    private async Task<T> WriteAsync<T>(Func<SqlConnection, SqlTransaction, Task<T>> action)
    {
        await using var connection = await database.OpenAsync();
        await ExecuteAsync(connection, null, "SET XACT_ABORT ON");
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable);
        try
        {
            var result = await action(connection, transaction);
            await transaction.CommitAsync();
            return result;
        }
        catch (SqlException error) when (error.Number is 547 or 2601 or 2627 or 1205 or 1222)
        {
            await RollbackAsync(transaction);
            throw new BusinessException(error.Number is 1205 or 1222
                ? "Dữ liệu đang được cập nhật bởi người khác. Hãy tải lại và thử lại."
                : "Dữ liệu đang được sử dụng hoặc bị trùng. Hãy tải lại danh sách trước khi tiếp tục.", 409);
        }
        catch
        {
            await RollbackAsync(transaction);
            throw;
        }
    }

    private static async Task RollbackAsync(SqlTransaction transaction)
    {
        try { await transaction.RollbackAsync(); }
        catch (InvalidOperationException) { }
        catch (SqlException) { }
    }

    private static SqlCommand Command(SqlConnection connection, SqlTransaction? transaction, string sql, params (string Name, object? Value)[] parameters)
    {
        var command = new SqlCommand(sql, connection, transaction) { CommandTimeout = 30 };
        foreach (var (name, value) in parameters)
        {
            var parameter = new SqlParameter(name, value ?? DBNull.Value);
            if (value is decimal) { parameter.SqlDbType = SqlDbType.Decimal; parameter.Precision = 18; parameter.Scale = 2; }
            else if (value is string) { parameter.SqlDbType = SqlDbType.NVarChar; parameter.Size = -1; }
            command.Parameters.Add(parameter);
        }
        return command;
    }

    private static async Task<object?> ScalarAsync(SqlConnection connection, SqlTransaction? transaction, string sql, params (string Name, object? Value)[] parameters)
    {
        await using var command = Command(connection, transaction, sql, parameters);
        var value = await command.ExecuteScalarAsync();
        return value is DBNull ? null : value;
    }

    private static async Task<int> ExecuteAsync(SqlConnection connection, SqlTransaction? transaction, string sql, params (string Name, object? Value)[] parameters)
    {
        await using var command = Command(connection, transaction, sql, parameters);
        return await command.ExecuteNonQueryAsync();
    }

    private static Catalog GetCatalog(string type) => Catalogs.TryGetValue(type, out var value)
        ? value : throw new BusinessException("Loại danh mục không được hỗ trợ.", 404);
    private static BusinessException Missing(string label) => new($"{label} không còn tồn tại.", 404);
    private static string? Trim(string? text) => string.IsNullOrWhiteSpace(text) ? null : text.Trim();
    private static void Validate(object input)
    {
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(input, new ValidationContext(input), results, true))
            throw new BusinessException("Dữ liệu không hợp lệ: " + string.Join(" ", results.Select(x => x.ErrorMessage)));
    }
    private static void Money(decimal value)
    {
        if (decimal.Round(value, 2, MidpointRounding.AwayFromZero) != value)
            throw new BusinessException("Số tiền và tỷ lệ giảm giá chỉ được có tối đa 2 chữ số thập phân.");
    }
    private static decimal LineTotal(InvoiceLineInput item) => decimal.Round(item.Quantity * item.UnitPrice * (100m - item.Discount) / 100m, 2, MidpointRounding.AwayFromZero);
    private static decimal SalePrice(decimal cost) => decimal.Round(cost * 1.1m, 2, MidpointRounding.AwayFromZero);
    private static string S(SqlDataReader reader, string name) { var index = reader.GetOrdinal(name); return reader.IsDBNull(index) ? "" : reader.GetString(index); }
    private static int I(SqlDataReader reader, string name) => reader.GetInt32(reader.GetOrdinal(name));
    private static int? N(SqlDataReader reader, string name) { var index = reader.GetOrdinal(name); return reader.IsDBNull(index) ? null : reader.GetInt32(index); }
    private static decimal D(SqlDataReader reader, string name) => reader.GetDecimal(reader.GetOrdinal(name));
}
