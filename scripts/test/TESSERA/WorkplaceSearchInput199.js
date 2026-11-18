/* Execute the actual paging module with a minimal event/AJAX fixture.
 * This is a unit check, not a browser or visual acceptance claim. */
'use strict';
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const packageRoot = process.env.TESSERA_TEST_PACKAGE_ROOT || 'Kernel/Package/GovernanceDB';
const source = fs.readFileSync(path.join(packageRoot, 'var/httpd/htdocs/js/TESSERA.Customer.SearchPaging.js'), 'utf8');
let checks = 0;
function check(name, actual, expected) { assert.deepEqual(actual, expected, name); checks++; console.log('ok ' + checks + ' - ' + name); }

function fixture() {
    const handlers = {}, requests = [], input = {id: 'oooSearch', value: 'needle', exists: true, focus: false}, header = {id: 'FulltextES', value: '', exists: false, focus: false};
    const doc = {activeElement: null, body: {}}, nativeRoot = {}, nativeOuter = {}, button = {};
    const collection = {empty() {return this;}, prop() {return this;}, toArray() {return [];}};
    const root = {
        0: nativeRoot, length: 1,
        attrs: {'data-search-query': 'needle', 'data-search-scope': 'All'},
        attr(key, value) {if (value === undefined) return this.attrs[key]; this.attrs[key] = value; return this;},
        find() {return collection;}, closest() {return outer;}, removeAttr(key) {delete this.attrs[key]; return this;}
    };
    const outer = {0: nativeOuter, length: 1, closest() {return {is() {return true;}};}};
    const control = {
        0: button, hasClass() {return true;}, closest() {return root;}, prop() {return false;},
        attr(key) {return key === 'data-search-scope' ? 'People' : undefined;}
    };
    function wrap(field) {return {length: field.exists ? 1 : 0, val() {return field.value;}, is() {return field.focus;}};}
    function $(item) {
        if (typeof item === 'function') {item(); return;}
        if (item === doc) {return {off() {return this;}, on(event, selector, handler) {handlers[event] = {selector, handler}; return this;}};}
        if (item === '#oooSearch') return wrap(input);
        if (item === '#FulltextES') return wrap(header);
        if (item === button) return control;
        if (Array.isArray(item)) return collection;
        return item;
    }
    $.contains = () => true;
    const Core = {Config: {Get() {return 'customer.pl?';}}, AJAX: {FunctionCall(url, data, callback) {
        const request = {url, data, callback, fail() {return this;}, always() {return this;}};
        requests.push(request); return request;
    }}};
    vm.runInNewContext(source, {$, Core, document: doc, window: {location: {href: 'customer.pl?Action=CustomerDashboard'}}});
    function click() {handlers['click.TESSERASearchPaging'].handler.call(button, {preventDefault() {}});}
    return {handlers, requests, input, header, root, click};
}

let f = fixture(); f.click();
check('native #oooSearch issues scope request without #FulltextES', f.requests.length, 1);
check('scope request preserves Workplace text', f.requests[0].data.FulltextES, 'needle');
check('scope request targets People', f.requests[0].data.SearchScope, 'People');
f = fixture(); f.input.value = ''; f.click();
check('native blur clearing preserves open dialog query', f.requests.length, 1);
f = fixture(); f.input.value = 'different'; f.click();
check('changed typed query cannot page stale results', f.requests.length, 0);
f = fixture(); f.input.value = ''; f.input.focus = true; f.click();
check('explicitly cleared focused input does not restore old query', f.requests.length, 0);
f = fixture(); f.input.exists = false; f.header.exists = true; f.header.value = 'needle';
f.handlers['input.TESSERASearchPaging'].handler.call({id: 'FulltextES'}); f.click();
check('header #FulltextES remains supported', f.requests.length, 1);
check('edit invalidation listens to native Workplace input', f.handlers['input.TESSERASearchPaging'].selector.includes('#oooSearch'), true);
let prevented = false, triggered = false;
f.handlers['submit.TESSERASearchPaging'].handler.call({find(selector) {
    assert.equal(selector, '#oooSearch'); return {trigger(event) {assert.equal(event, 'input'); triggered = true;}};
}}, {preventDefault() {prevented = true;}});
check('Workplace Enter prevents ticket-only form submission', prevented, true);
check('Workplace Enter invokes existing search input handler', triggered, true);
check('Enter interception is confined to marked Workplace forms', f.handlers['submit.TESSERASearchPaging'].selector, 'form[data-workplace-search="1"]');
console.log('PASS ' + checks + ' input/AJAX unit assertions');
