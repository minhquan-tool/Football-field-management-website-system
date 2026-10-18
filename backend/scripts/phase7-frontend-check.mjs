import assert from 'node:assert/strict';
import {readFileSync, readdirSync, existsSync, writeFileSync} from 'node:fs';
import {resolve, dirname} from 'node:path';
import {runInNewContext} from 'node:vm';
import {webcrypto} from 'node:crypto';
const root=resolve(import.meta.dirname,'../../frontend');
const sandbox={window:{location:{href:'http://server.example:8080/api/Man_hinh_chinh_KH.html'}},document:{addEventListener(){}},URL,Headers,Uint8Array,crypto:{getRandomValues:a=>webcrypto.getRandomValues(a)}};
runInNewContext(readFileSync(resolve(root,'js/auth.js'),'utf8'),sandbox);
const ids=new Set();for(let i=0;i<100;i++){const id=sandbox.window.SanBong.randomId();assert.match(id,/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/);ids.add(id);}assert.equal(ids.size,100);
const cdn=new Set(),html=[];
for(const file of readdirSync(root).filter(f=>f.endsWith('.html'))){
 const source=readFileSync(resolve(root,file),'utf8');html.push(file);
 assert.ok(!/href\s*=\s*["']#["']/.test(source),file+' contains placeholder navigation');
 for(const match of source.matchAll(/(?:src|href)\s*=\s*["']([^"']+)["']/g)){
  const url=match[1].replaceAll('&amp;','&');if(/^https?:\/\//.test(url)){cdn.add(new URL(url).hostname);continue;}
  if(!url||url.startsWith('#')||url.startsWith('/')||url.startsWith('?'))continue;
  assert.ok(existsSync(resolve(dirname(resolve(root,file)),decodeURIComponent(url.split(/[?#]/)[0]))),file+' broken link '+url);
 }
}
for(const file of readdirSync(resolve(root,'js')).filter(f=>f.endsWith('.js'))){
 const source=readFileSync(resolve(root,'js',file),'utf8');
 assert.ok(!/https?:\/\/(?:localhost|127\.0\.0\.1|192\.168\.)/.test(source),file+' pins development API host');
 assert.ok(!/APP_DB_PASSWORD|jdbc:sqlserver/.test(source),file+' exposes database configuration');
}
writeFileSync(resolve(import.meta.dirname,'../phase7-frontend-results.json'),JSON.stringify({status:'PASS',uuidWithoutSecureContextRandomUUID:100,htmlFiles:html,cdn:[...cdn].sort(),browserManualRequired:true},null,2));
console.log('FRONTEND_STATIC_PASS: UUID fallback, same-origin API, links, CDN inventory; browser/render verification pending.');
