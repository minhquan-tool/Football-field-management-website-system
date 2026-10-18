# Mô hình phụ thuộc hàm và dữ liệu snapshot

Phạm vi: chuẩn hóa các thuộc tính cơ sở theo tập phụ thuộc hàm công bố; tách giá trị dẫn xuất thành computed column. Không suy 3NF từ một bộ dữ liệu mẫu hoặc chỉ từ số bảng.

## Các bất thường đã xử lý

- DatSan: thời lượng và tiền sân GIA_GIO tính từ phút thực và đơn giá snapshot; tổng tính từ các thành phần. Các field này không còn được INSERT/UPDATE độc lập.
- HoaDon: tổng, còn lại và hoàn tất tài chính là kết quả tính từ snapshot thành phần và trạng thái/tiền thu; giữ snapshot sau chốt.
- ChiTietDichVu: số đơn vị theo quy cách, giá lốc và thành tiền được SQL tính. Runtime chỉ ghi giá đơn vị snapshot, quy cách và số lượng.
- GIA_KHUNG/LEGACY: giữ chính xác thời lượng, tiền sân và giá dịch vụ gốc trong cột snapshot riêng; không tra giá danh mục mới hoặc nhân lại 1,5h.

## Phân tích theo quan hệ

| Quan hệ | Khóa ứng viên công bố | Thuộc tính dẫn xuất không ghi độc lập | 3NF theo tập FD đã nêu |
|---|---|---|---|
| BangGia | (MaBangGia) | Không | Đạt |
| BaoCao | (MaBaoCao) | Không | Đạt |
| ChiTietDanhGia | (MaDanhGia, MaTieuChi) | Không | Đạt |
| ChiTietDichVu | (MaChiTiet) | SoDonViMoiQuyCach, DonGia, ThanhTien | Đạt |
| ChucNang | (MaChucNang) | Không | Đạt |
| DanhGia | (MaDanhGia); (MaDatSan) | Không | Đạt |
| DatSan | (MaDatSan) | ThoiLuong, TienSan, TongTien | Đạt |
| DichVu | (MaDV) | Không | Đạt |
| GiaTheoCa | (MaCa); (GioBatDau); (GioKetThuc) | Không | Đạt |
| HoaDon | (MaHoaDon); (MaDatSan) | TongTien, ConLai, HoanTatTaiChinh | Đạt |
| HoanTien | (MaHT); (MaHuy, MaTT) | Không | Đạt |
| HuyDatSan | (MaHuy); (MaDatSan) | Không | Đạt |
| KhachHang | (MaKH); (SoDienThoai) | Không | Đạt |
| KhungGio | (MaKhungGio) | Không | Đạt |
| KhuyenMai | (MaKM) | Không | Đạt |
| LoaiSan | (MaLoaiSan) | Không | Đạt |
| NhanVien | (MaNV) | Không | Đạt |
| NhatKyHeThong | (MaNhatKy) | Không | Đạt |
| PhanHoi | (MaPhanHoi) | Không | Đạt |
| PhanQuyen | (MaChucNang, MaVaiTro) | Không | Đạt |
| San | (MaSan) | Không | Đạt |
| SaoLuu | (MaSaoLuu) | Không | Đạt |
| TaiKhoan | (MaTK); (TenDangNhap) | Không | Đạt |
| ThanhToan | (MaTT) | Không | Đạt |
| TieuChiDanhGia | (MaTieuChi) | Không | Đạt |
| VaiTro | (MaVaiTro) | Không | Đạt |
| XacNhanSan | (MaXacNhan); (MaDatSan) | Không | Đạt |

Bằng chứng chi tiết X+ (bao đóng) và phụ thuộc hàm từng bảng nằm trong exports/normalization-fd-verification.json. Với mỗi X → A, kiểm tra X là siêu khóa hoặc A là thuộc tính nguyên tố. Chỉ công bố kết quả theo mô hình FD này, không khẳng định không thể tồn tại thêm quy tắc nghiệp vụ chưa khai báo.

## Snapshot và giới hạn mô hình

MaDV không quyết định giá đã bán trong mọi thời điểm; giá đã bán thuộc sự kiện dòng dịch vụ. MaKhungGio không được dùng để tính lại tiền legacy khi danh mục đổi. Giữ các giá trị sự kiện khác với lặp lại giá hiện tại của danh mục.

KhungGio.ThoiLuong giữ ý nghĩa đơn vị tính giá của khung legacy; dữ liệu/test kế thừa có thể dùng số giờ tính phí khác phép đo từng giây. Với GIA_GIO mới, giá và thời lượng dùng phút thực và không dựa vào trường này.

TienDichVu và DaThanhToan còn là tổng lưu có kiểm soát giữa các bảng. Trigger dịch vụ và transaction tài chính tiếp tục là nguồn cập nhật tương ứng; số thu phải đối chiếu sổ thu/hoàn. Không lấy chứng minh 3NF của một quan hệ để thay cho kiểm chứng nhất quán nhiều bảng.

Các snapshot mới có NULL ở nhánh không sử dụng, được CHECK theo chế độ giá/nguồn; phải phân tích từng chế độ khi giảng viên yêu cầu mô hình quan hệ không dùng NULL. Không tuyên bố chứng minh BCNF hoặc loại hoàn toàn mọi cache/denormalization vật lý của ứng dụng.

Migration tài chính và JAR tương ứng phải triển khai cùng nhau sau phê duyệt. Script có so SHA256 các trường gốc và rollback riêng; không DROP bảng/database hoặc reset lịch sử.
