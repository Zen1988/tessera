const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');
const s=fs.readFileSync('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerTicketZTSMRiskAssessment.tt','utf8');
function option(value,text){return {value,text,cloneNode(){return option(value,text);}};}
function field(){return {options:[option('',''),...Array.from({length:10},(_,i)=>option(String(100+i+1),String(i+1)))],value:'105',replaceChildren(){this.options=[];},appendChild(o){this.options.push(o);},get value(){return this._value||'';},set value(v){this._value=this.options.some(o=>o.value===v)?v:'';}};}
let framework='1',requests=[],recalculations=0;
const fields=Array.from({length:4},field);fields.forEach(f=>f.value='105');let message;
const row={getAttribute(){return '0';},querySelector(sel){if(sel.includes('ScaleError'))return message;return fields[sel.includes('Residual')? (sel.includes('Likelihood')?2:3):(sel.includes('Likelihood')?0:1)];},appendChild(m){message=m;}};
const ctx={fieldValue(){return framework;},encodeURIComponent,document:{createElement(){return {setAttribute(){}};}},recalculateRow(){recalculations++;},jQuery:{ajax(p){requests.push(p);return {abort(){}};}}};ctx.window=ctx;
vm.createContext(ctx);vm.runInContext(s.slice(s.indexOf('        function updateFrameworkScales('),s.indexOf('        function updateFrameworkLevels(')),ctx);
ctx.updateFrameworkScales(row);assert(fields.every(f=>f.disabled));assert.equal(row.ztsmScaleReady,false);
requests[0].success({Success:1,Scales:{Likelihood:3,Impact:5}});
assert.deepEqual(fields[0].options.map(o=>o.text),['','1','2','3']);assert.equal(fields[0].value,'');assert.equal(fields[1].value,'105');assert.equal(fields[2].options.length,4);assert.equal(fields[3].options.length,6);assert.equal(row.ztsmScaleReady,true);assert.equal(message.hidden,false);
framework='2';ctx.updateFrameworkScales(row);requests[0].success({Success:1,Scales:{Likelihood:10,Impact:10}});assert.equal(row.ztsmScaleReady,false,'stale response ignored');
requests[1].success({Success:1,Scales:{Likelihood:10,Impact:10}});assert.equal(fields[0].options.length,11,'full catalog restored for larger Framework');assert.equal(fields[0].value,'','cleared selection not silently restored');
framework='3';ctx.updateFrameworkScales(row);requests[2].success({Success:1,Scales:{}});assert.equal(row.ztsmScaleReady,false);assert(fields.every(f=>f.disabled));
framework='';ctx.updateFrameworkScales(row);assert.equal(requests.length,3);assert.equal(row.ztsmScaleReady,false);
vm.runInContext(s.slice(s.indexOf('        function scoreValue('),s.indexOf('        function setField(')),ctx);assert.equal(ctx.scoreValue('10'),10);assert.equal(ctx.scoreValue('3abc'),0);
console.log('Passed Framework scale client checks: filtering, both phases, reselection, expansion, races, invalid configuration and score10.');
