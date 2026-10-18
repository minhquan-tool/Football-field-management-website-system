import assert from 'node:assert/strict';
import {readFileSync,readdirSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
const root=resolve(import.meta.dirname,'../../frontend');
const html=readdirSync(root).filter(n=>n.endsWith('.html'));
for(const name of html){
 const source=readFileSync(resolve(root,name),'utf8');
 assert.ok(!/cdn\.tailwindcss\.com|tailwind\.config|fonts\.googleapis\.com|fonts\.gstatic\.com|upload\.wikimedia\.org|cdnjs\.cloudflare\.com|hcmute\.edu\.vn\/Resources/.test(source),'External UI resource in '+name);
 for(const match of source.matchAll(/<(?:script|img|link)\b[^>]*?(?:src|href)="([^"]+)"/g)){
  const path=match[1];assert.ok(!/^https?:\/\//.test(path),'Nonlocal resource '+name+' '+path);
  if(!path.startsWith('/'))assert.ok(existsSync(resolve(root,path.split(/[?#]/)[0])),'Missing asset '+path);
 }
}
for(const path of ['vendor/fontawesome/css/all.min.css','vendor/montserrat/montserrat.css']){
 const absolute=resolve(root,path),source=readFileSync(absolute,'utf8');
 for(const match of source.matchAll(/url\(['"]?([^)'"\s]+)['"]?\)/g))assert.ok(existsSync(resolve(dirname(absolute),match[1])),'Missing font '+match[1]);
}
const css=readFileSync(resolve(root,'css/tailwind.css'),'utf8');
for(const selector of ['.bg-brand-600','.text-brand-700','.md\\:grid-cols-2','.hidden'])assert.ok(css.includes(selector),'Missing generated utility '+selector);
assert.equal(readFileSync(resolve(root,'assets/hcmute-logo.png')).subarray(0,8).toString('hex'),'89504e470d0a1a0a');
console.log('LOCAL_ASSETS_PASS: '+html.length+' pages, generated CSS, local logo/font/icon references; map network remains optional.');
