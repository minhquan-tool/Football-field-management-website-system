// Bounded, read-only local baseline. Not a booking/payment stress test or remote-client certification.
import assert from 'node:assert/strict';
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
assert.equal(process.env.SAN_BONG_READ_LOAD_OPT_IN,'yes','Explicit read-load opt-in required');
const base=(process.env.AUTH_TEST_BASE_URL||'http://127.0.0.1:8082/api').replace(/\/$/,'');
const count=Number(process.env.LOAD_REQUESTS||300),concurrency=Number(process.env.LOAD_CONCURRENCY||10);
assert.ok(Number.isInteger(count)&&count>=10&&count<=500);assert.ok(Number.isInteger(concurrency)&&concurrency>=1&&concurrency<=20);
const paths=['/health','/public/options','/public/pitches'];
const initial=await(await fetch(base+'/health',{signal:AbortSignal.timeout(10000)})).json();assert.equal(initial.status,'UP');
for(let i=0;i<10;i++)await(await fetch(base+paths[i%paths.length],{signal:AbortSignal.timeout(10000)})).arrayBuffer();
let cursor=0;const durations=[],errors=[],statuses={};const started=performance.now();
await Promise.all(Array.from({length:concurrency},async()=>{
 while(cursor<count){const n=cursor++,path=paths[n%paths.length],begin=performance.now();
  try{const response=await fetch(base+path,{method:'GET',signal:AbortSignal.timeout(10000)});const data=await response.json();statuses[response.status]=(statuses[response.status]||0)+1;
   if(!response.ok||(path==='/health'?data.status!=='UP':data.success!==true))throw Error('Unexpected response '+response.status);
  }catch(error){errors.push({request:n,path,error:error.message});}finally{durations.push(performance.now()-begin);}
 }
}));
const elapsed=performance.now()-started;durations.sort((a,b)=>a-b);
const percentile=p=>Number(durations[Math.min(durations.length-1,Math.ceil(durations.length*p)-1)].toFixed(2));
const result={checkedAt:new Date().toISOString(),scope:'Local read-only HTTP baseline; not remote/load acceptance',method:'GET',paths,requests:count,concurrency,warmupRequests:10,statuses,errors,p50Ms:percentile(.5),p95Ms:percentile(.95),maxMs:percentile(1),elapsedMs:Number(elapsed.toFixed(2)),requestsPerSecond:Number((count*1000/elapsed).toFixed(2))};
writeFileSync(resolve(import.meta.dirname,'../../exports/medium-read-load-results.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result));assert.equal(errors.length,0,'Read-load requests failed; inspect saved result');
