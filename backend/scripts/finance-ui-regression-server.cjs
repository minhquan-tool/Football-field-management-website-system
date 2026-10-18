// Browser regression server: serves only synthetic fixtures and the actual finance.js.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const routes = {
    '/': [path.join(__dirname, 'fixtures/finance-ui.html'), 'text/html'],
    '/finance.js': [path.join(__dirname, '../../frontend/js/finance.js'), 'text/javascript']
};
http.createServer((req, res) => {
    if(new URL(req.url,'http://localhost').pathname==='/qr-fixture.svg'){res.setHeader('Content-Type','image/svg+xml');res.end('<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300"><rect width="300" height="300" fill="white"/><text x="10" y="40">TEST ONLY - NOT A PAYMENT QR</text></svg>');return;}
    if(new URL(req.url,'http://localhost').pathname==='/qr'){res.setHeader('Content-Type','text/html; charset=utf-8');fs.createReadStream(path.join(__dirname,'fixtures/payment-qr-ui.html')).pipe(res);return;}
    const route = routes[new URL(req.url, 'http://localhost').pathname];
    if (!route) { res.writeHead(404).end(); return; }
    res.setHeader('Content-Type', route[1] + '; charset=utf-8');
    fs.createReadStream(route[0]).pipe(res);
}).listen(8093, '127.0.0.1', () => console.log('Finance UI regression: http://127.0.0.1:8093 ; synthetic data only'));
