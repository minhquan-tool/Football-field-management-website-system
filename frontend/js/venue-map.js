/* Coordinates supplied by the group. No location is sent to the application server. */
window.SanBongVenueMap = (() => {
    const destination = '10.8505572,106.7729939';
    function mapUrl() {
        const url = new URL('https://www.google.com/maps/search/');
        url.search = new URLSearchParams({ api: '1', query: destination });
        return url.href;
    }
    function directionsUrl(origin = '') {
        const url = new URL('https://www.google.com/maps/dir/');
        const params = new URLSearchParams({ api: '1', destination, travelmode: 'driving' });
        if (origin.trim()) params.set('origin', origin.trim());
        url.search = params; return url.href;
    }
    function init() {
        const $ = id => document.getElementById(id);
        $('openMap').href = mapUrl();
        $('currentDirections').href = directionsUrl();
        $('venueMap').src = `https://www.google.com/maps?q=${encodeURIComponent(destination)}&z=17&output=embed`;
        $('directionsForm').addEventListener('submit', event => {
            event.preventDefault();
            const origin = $('directionsOrigin').value.trim();
            if (!origin) { $('directionsOrigin').setCustomValidity('Nhập địa chỉ xuất phát.'); $('directionsOrigin').reportValidity(); return; }
            $('locatedDirections').href = directionsUrl(origin); $('locatedDirections').hidden = false;
            $('locatedDirections').textContent = 'Mở đường đi từ địa chỉ đã nhập ↗';
            $('mapStatus').textContent = 'Đã chuẩn bị đường đi. Bấm liên kết bên dưới để xem quãng đường và thời gian trên Google Maps.';
        });
        $('directionsOrigin').addEventListener('input', () => $('directionsOrigin').setCustomValidity(''));
        $('locateCustomer').addEventListener('click', () => {
            $('locatedDirections').hidden = true;
            if (!navigator.geolocation) { $('mapStatus').textContent = 'Trình duyệt không hỗ trợ vị trí. Hãy nhập điểm xuất phát hoặc mở Google Maps.'; return; }
            $('locateCustomer').disabled = true; $('mapStatus').textContent = 'Đang yêu cầu vị trí từ trình duyệt…';
            navigator.geolocation.getCurrentPosition(position => {
                const { latitude, longitude } = position.coords;
                if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || Math.abs(latitude) > 90 || Math.abs(longitude) > 180) {
                    $('mapStatus').textContent = 'Không nhận được vị trí hợp lệ. Hãy nhập địa chỉ xuất phát.';
                } else {
                    $('locatedDirections').href = directionsUrl(`${latitude},${longitude}`);
                    $('locatedDirections').textContent = 'Mở đường đi từ vị trí hiện tại ↗'; $('locatedDirections').hidden = false;
                    $('mapStatus').textContent = 'Đã nhận vị trí. Bấm liên kết để xem đường đi trên Google Maps; vị trí không được lưu vào hệ thống sân bóng.';
                }
                $('locateCustomer').disabled = false;
            }, () => {
                $('locateCustomer').disabled = false;
                $('mapStatus').textContent = 'Không lấy được vị trí hoặc bạn chưa cho phép. Bạn vẫn có thể nhập điểm xuất phát hoặc mở Google Maps.';
            }, { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 });
        });
    }
    return { mapUrl, directionsUrl, init };
})();
