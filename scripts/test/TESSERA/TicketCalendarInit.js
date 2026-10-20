const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
for (const frontend of ['Customer', 'Agent']) {
    let ready = false, requests = [];
    const start = {format: () => '2026-09-27'}, end = {format: () => '2026-11-08'};
    const node = {length: 1, prop() {return this;},
        fullCalendar(options) {options.events(start, end, 'local', () => {});}};
    function $(value) {if (typeof value === 'function') {value();return;} return node;}
    $.fn = {fullCalendar() {}}; $.isFunction = value => typeof value === 'function';
    $.each = (items, callback) => items.forEach((item, i) => callback.call(item, i, item));
    $.getJSON = (url, range) => {requests.push({url,range});return {done() {return this;},fail() {return this;}};};
    const context = {$, Core: {Config: {Get() {assert(ready, 'configuration must be loaded');return '/otobo/customer.pl?';}}, Debug: {}}};
    vm.createContext(context);
    vm.runInContext(fs.readFileSync('otobo-11.1.0-beta2/var/httpd/htdocs/js/Core.Init.js','utf8'),context);
    vm.runInContext(fs.readFileSync(`var/httpd/htdocs/js/TESSERA.${frontend}.TicketCalendar.js`,'utf8'),context);
    assert.equal(requests.length,0, 'no premature first-load request');
    context.Core.Init.ExecuteInit('DOCUMENT_READY');
    assert.equal(requests.length,0, 'document readiness alone does not trigger request');
    ready = true;
    context.Core.Init.ExecuteInit('CONFIG_LOADED');
    context.Core.Init.ExecuteInit('APP_MODULE');
    assert.equal(requests.length,1, 'native module stage triggers initial fetch');
    assert(requests[0].url.startsWith('/otobo/customer.pl?Action='), 'valid first-load URL');
    assert.equal(requests[0].range.Start,'2026-09-27');
    assert.equal(requests[0].range.End,'2026-11-08');
}
console.log('Native initialization: 12 assertions passed across customer and agent calendars');
