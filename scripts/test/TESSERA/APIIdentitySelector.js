const fs = require('fs');
const vm = require('vm');
const assert = require('assert/strict');
const code = fs.readFileSync('Kernel/Package/GovernanceDB/var/httpd/htdocs/js/TESSERA.Agent.APIIdentity.js', 'utf8');
function setup(readOnly = false) {
    const form = { events: {}, on(name, fn) { this.events[name] = fn; return this; } };
    function element(value = '') {
        return { value, events: {}, length: 1, readOnly, validity: '',
            0: { setCustomValidity(msg) { search.validity = msg; }, reportValidity() { search.reported = true; } },
            prop(name) { return this[name]; },
            val(value) { if (arguments.length) { this.value = value; return this; } return this.value; },
            text(value) { this.value = value; return this; },
            on(name, fn) { this.events[name] = fn; return this; },
            data() { return this; }, removeData() { return this; }, closest() { return form; }
        };
    }
    const search = element(), login = element(), status = element();
    const $ = selector => ({'#PermissionSubjectSearch': search, '#CustomerUserID': login, '#PermissionSubjectStatus': status}[selector]);
    $.map = (data, fn) => data.map(fn);
    const state = { search, login, status, form };
    const context = {$, Core: {
        Init: { RegisterNamespace(ns) { state.init = ns.Init; } },
        Config: { Get() { return '/index.pl'; } },
        AJAX: { FunctionCall(url, params, callback) { state.params = params; callback([{Label: 'Test User (test)', Value: 'test'}]); return {}; } },
        UI: { Autocomplete: { Init(el, source, select, type, options) { Object.assign(state, {source, select, type, options}); } } }
    }};
    vm.runInNewContext(code, context);
    state.init();
    return state;
}
let s = setup();
assert.equal(s.options.MinQueryLength, 2);
s.login.val('previous');s.search.events.input();assert.equal(s.login.val(), '');
assert.ok(s.search.validity);
let suggestions;s.source({term: 'te'}, data => { suggestions = data; });
assert.equal(s.params.Subaction, 'SearchSubjects');assert.equal(suggestions[0].value, 'test');
let prevented = false;s.select({preventDefault() { prevented = true; }}, {item: suggestions[0]});
assert.ok(prevented);assert.equal(s.login.val(), 'test');assert.equal(s.search.val(), 'Test User (test)');assert.equal(s.search.validity, '');
s.search.events.input();assert.equal(s.login.val(), '');
prevented = false;s.form.events.submit({preventDefault() { prevented = true; }});assert.ok(prevented);assert.ok(s.search.reported);
s = setup(true);assert.equal(s.source, undefined);
console.log('Customer selector: selection, stale-login clearing, required choice and immutable display passed.');
