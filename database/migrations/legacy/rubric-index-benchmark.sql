/* SYNTHETIC laboratory only. Mirrors five real index access patterns.
   Never modifies dbo tables/indexes. Retains synthetic tables for reproducibility. */
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'$(ReviewedDatabase)' OR DB_NAME() NOT LIKE 'QuanLySanBong_Fixtures[_]%'
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'SanBongFixtureDatabase' AND TRY_CONVERT(int,value)=1)
 THROW 51040,'Disposable fixture database required',1;
IF SCHEMA_ID('rubric_bench') IS NOT NULL THROW 51041,'Benchmark already exists; use a fresh fixture, no overwrite',1;
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC('CREATE SCHEMA rubric_bench');
 SELECT TOP(0) MaDatSan,MaSan,NgayChoi,GioBatDau,MaKH,TrangThai INTO rubric_bench.Booking FROM dbo.DatSan;
 SELECT TOP(0) MaTT,MaDatSan,TrangThai,SoTien INTO rubric_bench.Payment FROM dbo.ThanhToan;
 SELECT TOP(0) MaDatSan,MaDV,SoLuong,DonGia INTO rubric_bench.Service FROM dbo.ChiTietDichVu;
 SELECT TOP(0) MaTK,TenDangNhap INTO rubric_bench.Account FROM dbo.TaiKhoan;
 SELECT TOP(0) MaKH,SoDienThoai INTO rubric_bench.Customer FROM dbo.KhachHang;
 CREATE TABLE #Numbers(n int NOT NULL PRIMARY KEY);
 ;WITH d(n) AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))a(n))
 INSERT #Numbers SELECT a.n+10*b.n+100*c.n+1000*e.n+10000*f.n+1 FROM d a CROSS JOIN d b CROSS JOIN d c CROSS JOIN d e CROSS JOIN d f WHERE a.n+10*b.n+100*c.n+1000*e.n+10000*f.n<50000;
 INSERT rubric_bench.Booking SELECT 'B'+RIGHT('000000000'+CONVERT(varchar(9),n),9),'S'+CONVERT(varchar(9),n%100),DATEADD(day,n%365,CONVERT(date,'20260101')),CONVERT(time,'08:00'),'K'+CONVERT(varchar(9),n%10000),N'Đã xác nhận' FROM #Numbers;
 INSERT rubric_bench.Payment SELECT 'T'+RIGHT('000000000'+CONVERT(varchar(9),n),9),'B'+RIGHT('000000000'+CONVERT(varchar(9),n%25000+1),9),CASE WHEN n%4=0 THEN N'Chờ xử lý' ELSE N'Thành công' END,100000 FROM #Numbers;
 INSERT rubric_bench.Service SELECT 'B'+RIGHT('000000000'+CONVERT(varchar(9),n%10000+1),9),'SV03',1,10000 FROM #Numbers;
 INSERT rubric_bench.Account SELECT 'A'+RIGHT('000000000'+CONVERT(varchar(9),n),9),'rubric_user_'+CONVERT(varchar(9),n) FROM #Numbers;
 INSERT rubric_bench.Customer SELECT 'K'+RIGHT('000000000'+CONVERT(varchar(9),n),9),'09'+RIGHT('00000000'+CONVERT(varchar(8),n),8) FROM #Numbers;
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
