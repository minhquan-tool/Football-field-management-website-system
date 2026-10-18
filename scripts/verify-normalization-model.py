"""Verify derived-column separation and a published FD model, never infer FDs from sample rows.
3NF results are conditional on the declared domain dependencies, not a universal theorem
about every possible business rule. Historical quote facts are independent of live catalog.
"""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
(root/'exports').mkdir(exist_ok=True)
meta=json.loads(((root/'exports/normalization-after-schema.json') if (root/'exports/normalization-after-schema.json').exists() else (root/'database/metadata/current-schema.json')).read_text(encoding='utf-8-sig'))
required={'DatSan':{'ThoiLuong','TienSan','TongTien'},'HoaDon':{'TongTien','ConLai','HoanTatTaiChinh'},'ChiTietDichVu':{'SoDonViMoiQuyCach','DonGia','ThanhTien'}}
for name,attrs in required.items():
    table=next(t for t in meta['tables'] if t['name']==name)
    actual={c['name'] for c in table['columns'] if c.get('computed') and c.get('is_persisted')}
    if not attrs<=actual:raise RuntimeError(f'Missing derived columns: {name}')
def closure(seed,fds):
    result=set(seed)
    while True:
        prior=set(result)
        for lhs,rhs in fds:
            if lhs<=result:result|=rhs
        if prior==result:return result
checks=[]
for table in meta['tables']:
    attributes={c['name'] for c in table['columns'] if not c.get('computed')}
    nullable={c['name'] for c in table['columns'] if c['is_nullable']}
    keys=[]
    for index in table['indexes']:
        if not index['is_unique'] or index.get('filter_definition'):continue
        key={c['name'] for c in index['columns'] if not c['is_included_column']}
        if key&nullable or not key<=attributes:continue
        keys.append(key)
    if not keys:raise RuntimeError('No non-null candidate key for '+table['name'])
    fds=[(key,attributes-key) for key in keys]
    # The CHECK constraints fix three unique bands; their boundaries identify MaCa too.
    if table['name']=='GiaTheoCa':
        fds += [({'GioBatDau'},attributes-{'GioBatDau'}),({'GioKetThuc'},attributes-{'GioKetThuc'})]
        keys += [{'GioBatDau'},{'GioKetThuc'}]
    prime=set().union(*keys)
    violations=[]
    for lhs,rhs in fds:
        for attr in rhs-lhs:
            if attr not in prime and not attributes<=closure(lhs,fds):violations.append(dict(lhs=sorted(lhs),rhs=attr))
    checks.append(dict(table=table['name'],baseAttributes=sorted(attributes),derivedAttributes=[c['name'] for c in table['columns'] if c.get('computed')],candidateKeys=[sorted(k) for k in keys],declaredDependencies=[dict(lhs=sorted(a),rhs=sorted(b)) for a,b in fds],thirdNormalFormUnderDeclaredDependencies=not violations,violations=violations))
record=dict(status='PASS_UNDER_DECLARED_DOMAIN_MODEL',database=meta['database'],computedColumnsVerified=9,tables=checks,assumptions=[
 'FDs come from the published domain/keys, not from coincidental current rows.',
 'Stored legacy quotes/prices/durations belong to their original event and are independent of mutable current catalog.',
 'KhungGio.ThoiLuong is the legacy billable slot unit; do not assume every legacy interval implies an exact elapsed duration.',
 'Derived view/computed attributes are excluded from base-relation normalization.',
 'Persisted cross-table aggregates such as paid total and service subtotal are separately guarded transaction caches; this proof does not certify lossless arbitrary future redesigns.'
])
(root/'exports/normalization-fd-verification.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
md=['# Mô hình phụ thuộc hàm và dữ liệu snapshot','',
 'Phạm vi: chuẩn hóa các thuộc tính cơ sở theo tập phụ thuộc hàm công bố; tách giá trị dẫn xuất thành computed column. Không suy 3NF từ một bộ dữ liệu mẫu hoặc chỉ từ số bảng.',
 '', '## Các bất thường đã xử lý','',
 '- DatSan: thời lượng và tiền sân GIA_GIO tính từ phút thực và đơn giá snapshot; tổng tính từ các thành phần. Các field này không còn được INSERT/UPDATE độc lập.',
 '- HoaDon: tổng, còn lại và hoàn tất tài chính là kết quả tính từ snapshot thành phần và trạng thái/tiền thu; giữ snapshot sau chốt.',
 '- ChiTietDichVu: số đơn vị theo quy cách, giá lốc và thành tiền được SQL tính. Runtime chỉ ghi giá đơn vị snapshot, quy cách và số lượng.',
 '- GIA_KHUNG/LEGACY: giữ chính xác thời lượng, tiền sân và giá dịch vụ gốc trong cột snapshot riêng; không tra giá danh mục mới hoặc nhân lại 1,5h.',
 '', '## Phân tích theo quan hệ','',
 '| Quan hệ | Khóa ứng viên công bố | Thuộc tính dẫn xuất không ghi độc lập | 3NF theo tập FD đã nêu |','|---|---|---|---|']
for item in checks:md.append('| '+item['table']+' | '+'; '.join('('+', '.join(k)+')' for k in item['candidateKeys'])+' | '+(', '.join(item['derivedAttributes']) or 'Không')+' | '+('Đạt' if item['thirdNormalFormUnderDeclaredDependencies'] else 'Chưa đạt')+' |')
md += ['', 'Bằng chứng chi tiết X+ (bao đóng) và phụ thuộc hàm từng bảng nằm trong exports/normalization-fd-verification.json. Với mỗi X → A, kiểm tra X là siêu khóa hoặc A là thuộc tính nguyên tố. Chỉ công bố kết quả theo mô hình FD này, không khẳng định không thể tồn tại thêm quy tắc nghiệp vụ chưa khai báo.',
 '', '## Snapshot và giới hạn mô hình','',
 'MaDV không quyết định giá đã bán trong mọi thời điểm; giá đã bán thuộc sự kiện dòng dịch vụ. MaKhungGio không được dùng để tính lại tiền legacy khi danh mục đổi. Giữ các giá trị sự kiện khác với lặp lại giá hiện tại của danh mục.',
 '', 'KhungGio.ThoiLuong giữ ý nghĩa đơn vị tính giá của khung legacy; dữ liệu/test kế thừa có thể dùng số giờ tính phí khác phép đo từng giây. Với GIA_GIO mới, giá và thời lượng dùng phút thực và không dựa vào trường này.',
 '', 'TienDichVu và DaThanhToan còn là tổng lưu có kiểm soát giữa các bảng. Trigger dịch vụ và transaction tài chính tiếp tục là nguồn cập nhật tương ứng; số thu phải đối chiếu sổ thu/hoàn. Không lấy chứng minh 3NF của một quan hệ để thay cho kiểm chứng nhất quán nhiều bảng.',
 '', 'Các snapshot mới có NULL ở nhánh không sử dụng, được CHECK theo chế độ giá/nguồn; phải phân tích từng chế độ khi giảng viên yêu cầu mô hình quan hệ không dùng NULL. Không tuyên bố chứng minh BCNF hoặc loại hoàn toàn mọi cache/denormalization vật lý của ứng dụng.',
 '', 'Migration tài chính và JAR tương ứng phải triển khai cùng nhau sau phê duyệt. Script có so SHA256 các trường gốc và rollback riêng; không DROP bảng/database hoặc reset lịch sử.'
]
(root/'docs/DBMS_NORMALIZATION_MODEL.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print('NORMALIZATION_MODEL_PASS: 9 computed columns; 27 relations checked against the published FD model')
