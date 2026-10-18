// One-off source migration, deterministic and idempotent; never downloads anything.
import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {resolve} from 'node:path';
const root=resolve(import.meta.dirname,'../frontend');let changed=0;
for(const name of readdirSync(root).filter(n=>n.endsWith('.html'))){
 const path=resolve(root,name),original=readFileSync(path,'utf8');
 const source=original
  .replace(/<script\s+src="https:\/\/cdn\.tailwindcss\.com"><\/script>/g,'<link rel="stylesheet" href="css/tailwind.css">')
  .replace(/<script>\s*tailwind\.config\s*=[\s\S]*?<\/script>/g,'')
  .replaceAll('https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css','vendor/fontawesome/css/all.min.css')
  .replace(/<link\s+rel="preconnect"\s+href="https:\/\/fonts\.(?:googleapis|gstatic)\.com"[^>]*>\s*/g,'')
  .replace(/https:\/\/fonts\.googleapis\.com\/css2\?family=Montserrat:[^"]+/g,'vendor/montserrat/montserrat.css')
  .replace(/https:\/\/upload\.wikimedia\.org\/[^"\s]+\.png/g,'assets/hcmute-logo.png')
  .replaceAll('https://hcmute.edu.vn/Resources/Images/SubDomain/HomePage/tin%20tuc/Nam%202023/Ky%20luc/PVH-7.jpg','assets/football-field.svg');
 if(source!==original){writeFileSync(path,source,'utf8');changed++;}
}
console.log(`LOCAL_ASSETS: ${changed} HTML pages updated; no runtime API/business changes.`);
