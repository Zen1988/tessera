const fs = require('fs');
const vm = require('vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerTicketZTSMRiskAssessment.tt', 'utf8');
const code = source.slice(source.indexOf('        var assessmentForm ='), source.indexOf('        bindRemove(root);', source.indexOf('        var assessmentForm =')));
function element(attrs={}) {
    return {attrs, value:'', name:'', type:'text', tagName:'INPUT',
        getAttribute(k){return this.attrs[k] || null;}, setAttribute(k,v){this.attrs[k]=v;},
        focus(){this.focused=true;},scrollIntoView(){},remove(){this.removed=true;},
        matches(){return this.assess;},closest(){return this.assess ? this : null;}};
}
function group(name,type='text') {
    const g=element({'data-field-name':name,'aria-labelledby':name+'_Caption'});
    const control=element(); control.name=name; control.type=type;
    if(type==='select') {control.tagName='SELECT';control.selectedOptions=[];}
    g.controls=[control];
    if(type==='hidden') {const display=element();display.name='Autocomplete_'+name;g.controls.push(display);}
    g.querySelectorAll=()=>g.controls;
    g.querySelector=(sel)=>sel.includes('FieldError') ? (g.error && !g.error.removed ? g.error : null) : g.controls.find(c=>c.type!=='hidden');
    g.appendChild=e=>{g.error=e;};
    return g;
}
const groups=[group('RA_0_ZRM-RiskAction','select'),group('RA_0_ZRM-RiskPlan'),group('RA_0_ZRM-RiskStatement','hidden')];
const outcome=element(); outcome.name='RiskAssessmentOutcome';
const listeners={}; let summary;
const form={querySelector:s=>s.includes('Outcome')?outcome:summary,prepend:e=>{summary=e;},addEventListener:(type,fn,capture)=>{listeners[type]={fn,capture};}};
const root={querySelector:()=>form,querySelectorAll:s=>s.includes('.ZTSMRiskAssessmentRow')?[]:groups};
const context={root,document:{createElement:()=>element()}};
vm.createContext(context);vm.runInContext(code,context);
function click() {const button=element();button.assess=true;const event={target:button,preventDefault(){this.prevented=true;},stopImmediatePropagation(){this.stopped=true;}};listeners.click.fn(event);return event;}
assert.equal(listeners.click.capture,true); assert.equal(listeners.submit.capture,true);
let event=click(); assert.equal(event.prevented,true); assert.equal(event.stopped,true);
assert.ok(groups.every(g=>g.attrs['aria-invalid']==='true')); assert.equal(summary.attrs.role,'alert');
assert.ok(groups[0].controls[0].focused);
outcome.value='Risk Accepted'; groups[0].controls[0].selectedOptions=[{value:'Mitigate'}];groups[1].controls[0].value='   ';groups[2].controls[1].value='typed display text';
event=click();assert.equal(event.prevented,true);assert.equal(groups[2].attrs['aria-invalid'],'true','display text without selected ID fails');
groups[1].controls[0].value='Plan';groups[2].controls[0].value='630';event=click();assert.equal(event.prevented,undefined);assert.equal(summary.hidden,true);
assert.ok(groups.every(g=>g.attrs['aria-invalid']==='false')); assert.ok(groups.every(g=>g.error.removed));
groups.push(group('RA_1_ZRM-RiskPlan'));event=click();assert.equal(event.prevented,true,'new row is checked');
groups[3].controls[0].value='Second plan';listeners.change.fn();assert.equal(groups[3].attrs['aria-invalid'],'false');
const submit={submitter:{matches:()=>true},preventDefault(){this.prevented=true;},stopImmediatePropagation(){}};
outcome.value='';listeners.submit.fn(submit);assert.equal(submit.prevented,true,'keyboard submission is blocked');
console.log('Passed client guard checks: capture prevents submission, all errors, whitespace, reference IDs, correction, new rows, keyboard submit.');
