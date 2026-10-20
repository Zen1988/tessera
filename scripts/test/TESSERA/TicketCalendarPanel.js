const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
let options, events = [], labels = [];
function element() { return { length: 1, empty() { labels = []; return this; },
    appendTo() { return this; }, addClass() { return this; }, prop() { return this; },
    attr() { return this; }, css() { return this; }, text(value) { labels.push(value); return this; },
    fullCalendar(value) { if (value === 'clientEvents') return events; options = value; return this; } }; }
let errorText, errorHidden;
const error = element();
error.text = value => { errorText = value; return error; };
error.prop = (name, value) => { errorHidden = value; return error; };
const calendar = element();
function $(value) { if (typeof value === 'function') { value(); return; }
    if (value === '#ZTSMCustomerTicketCalendarError') return error;
    return value === '#ZTSMCustomerTicketCalendar' ? calendar : element(); }
$.fn = { fullCalendar() {} };
$.each = (items, callback) => Object.keys(items).forEach(key => callback(key, items[key]));
$.grep = (items, predicate) => items.filter(predicate);
const moment = value => ({ valueOf: () => Date.parse(value), format: () => value });
const ticket = (title, start, end) => ({title, start: moment(start), end: moment(end), url: '/ticket'});
let initializer, configLoaded = false;
const core = {Config: {Get: () => { assert(configLoaded, 'config ready before first request'); return '/customer.pl?'; }},
    Init: {RegisterNamespace(namespace, stage) { assert.equal(stage, 'APP_MODULE'); initializer = namespace.Init; }}};
vm.runInNewContext(fs.readFileSync('var/httpd/htdocs/js/TESSERA.Customer.TicketCalendar.js', 'utf8'), {$, Core: core});
assert.equal(options, undefined, 'calendar does not start during module loading');
configLoaded = true;
initializer();

events = [ticket('October ticket', '2026-10-05T03:15:08Z', '2026-10-06T03:15:08Z'),
    ticket('Spanning ticket', '2026-09-16T08:50:00Z', '2026-10-14T00:00:00Z'),
    ticket('Ends at September boundary', '2026-08-30T00:00:00Z', '2026-09-01T00:00:00Z')];
options.eventAfterAllRender({intervalStart: moment('2026-09-01T00:00:00Z'), intervalEnd: moment('2026-10-01T00:00:00Z')});
assert(!labels.includes('October ticket'), 'October-only ticket excluded from September panel');
assert(labels.includes('Spanning ticket'), 'ticket spanning September remains visible');
assert(!labels.includes('Ends at September boundary'), 'exclusive interval boundary respected');
assert(labels.some(label => String(label).includes('2026-09-16T08:50:00Z > 2026-10-14')), 'range shown');
options.eventAfterAllRender({intervalStart: moment('2026-10-01T00:00:00Z'), intervalEnd: moment('2026-11-01T00:00:00Z')});
assert(labels.includes('October ticket'), 'cached navigation rebuilds October panel');
console.log('Calendar panel: 5 assertions passed');
$.isArray = Array.isArray;
let pending = [];
$.getJSON = (url, range) => {
    const request = {url, range, done(fn) { this.success = fn; return this; }, fail(fn) { this.failure = fn; return this; }};
    pending.push(request); return request;
};
let replies = [];
const rangeStart = moment('2026-10-01T00:00:00Z'), rangeEnd = moment('2026-11-01T00:00:00Z');
options.events(rangeStart, rangeEnd, 'local', data => replies.push(data));
pending[0].failure();
assert.equal(pending.length, 2, 'first HTTP failure automatically retries once');
pending[1].success([{id: 32}]);
assert.equal(replies[0][0].id, 32, 'retry fills initial month without navigation');
pending = []; replies = [];
options.events(rangeStart, rangeEnd, 'local', data => replies.push(data));
pending[0].success({Error: 'backend failure'});
pending[1].failure();
assert.equal(pending.length, 2, 'persistent failure is bounded to two attempts');
assert.equal(replies.length, 1, 'persistent failure completes callback once');
assert(errorText === 'Calendar events could not be loaded.' && errorHidden === false, 'final failure is visible');
pending = []; replies = [];
options.events(rangeStart, rangeEnd, 'local', data => replies.push(data));
options.events(rangeStart, rangeEnd, 'local', data => replies.push(data));
pending[1].success([{id: 33}]);
pending[0].failure();
assert.equal(pending.length, 2, 'stale failure does not retry after navigation');
assert.equal(replies[0][0].id, 33, 'current view result wins');
console.log('Calendar loading: 7 assertions passed');
