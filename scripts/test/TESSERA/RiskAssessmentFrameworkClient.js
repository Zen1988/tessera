const fs = require('fs');
const vm = require('vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerTicketZTSMRiskAssessment.tt','utf8');
const editable = source.slice(source.indexOf('        function setEditableField('), source.indexOf('        function recalculateRow('));
const start = source.indexOf('        function bindRiskStatementDefaults(');
const defaults = source.slice(start, source.indexOf('\n        if (',source.indexOf('                scheduleDefaults();\n            });\n        }',start)));
assert(defaults.includes('scheduleDefaults();'));
let scheduled, request;
function control(value='') {
    return {value,tagName:'INPUT',listeners:{},addEventListener(type,fn){this.listeners[type]=fn;},dispatchEvent(){}};
}
const statement=control('4'), visible=control('Statement'), framework=control('3'), display=control('Override Framework');
const row={dataset:{},getAttribute(){return '0';},addEventListener(){},
    querySelector(s){if(s.includes('Field_ZRM-Framework')) return {querySelector(){return display;}};
        return s.includes('Autocomplete') ? visible : s.includes('RiskStatement') ? statement : null;},
    querySelectorAll(s){return s.includes('ZRM-Framework') ? [framework] : [];}};
const scope={querySelectorAll(){return [row];}};
const context={root:scope,document:scope,Event:function(){},debugLog(){},recalculateRow(){},
    fieldValue(_row,name){return name.includes('RiskStatement') ? statement.value : framework.value;},
    clearTimeout(){},setTimeout(fn){scheduled=fn;return 1;},jQuery:{ajax(options){request=options;return {abort(){}};}}};
vm.createContext(context);
context.window = context;
vm.runInContext(editable+defaults,context);
context.bindRiskStatementDefaults(scope); scheduled();
request.success({Success:1,RiskStatementID:'4',Fields:{'ZRM-Framework':'2'},FrameworkLabel:'Statement Framework'});
assert.equal(framework.value,'3','reopening preserves saved override');
statement.value='5'; statement.listeners.change(); scheduled();
request.success({Success:1,RiskStatementID:'5',Fields:{'ZRM-Framework':'1'},FrameworkLabel:'Asset Risk Management'});
assert.equal(framework.value,'1','statement change updates stored ID');
assert.equal(display.value,'Asset Risk Management','statement change updates visible Framework name');
framework.value='3'; display.value='Override Framework'; visible.listeners.blur(); scheduled();
request.success({Success:1,RiskStatementID:'5',Fields:{'ZRM-Framework':'1'},FrameworkLabel:'Asset Risk Management'});
assert.equal(framework.value,'3','unchanged statement blur preserves manual override');
statement.value=''; visible.value=''; statement.listeners.change(); scheduled();
assert(request.url.includes('RiskStatementID=;'),'cleared statement still requests organization default');
request.success({Success:1,Fields:{'ZRM-Framework':'1'},FrameworkLabel:'Asset Risk Management'});
assert.equal(framework.value,'1','clear restores default');
console.log('Passed 6 Framework client checks: saved override, changed ID/name, manual override, empty request, clear fallback.');
