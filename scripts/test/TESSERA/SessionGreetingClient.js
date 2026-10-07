const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerDashboard.tt', 'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];
(async () => {
    const handlers = {}, styles = {}, timers = [], status = {};
    const form = {dataset: {}, action: '/otobo/customer.pl?Action=CustomerDashboard', addEventListener: (name, fn) => handlers[name] = fn};
    const card = {style: {setProperty: (k, v) => styles[k] = v}, parentElement: {getBoundingClientRect: () => ({left: 75, right: 1915})}, querySelector: s => s === 'form' ? form : status};
    const main = {getBoundingClientRect: () => ({left: 75, right: 1915})};
    let ready, resized, observed, body;
    const context = {
        document: {readyState: 'loading', addEventListener: (name, fn) => ready = fn, getElementById: id => id === 'oooMainBox' ? main : card},
        window: {getComputedStyle: () => ({paddingLeft: '102px', paddingRight: '58px'}), addEventListener: (name, fn) => resized = fn, setTimeout: (fn, delay) => timers.push({fn, delay}), ResizeObserver: true},
        ResizeObserver: class {constructor(fn) {observed = fn;} observe(value) {assert.equal(value, main);}},
        FormData: class {set(k, v) {body = [k, v];}},
        fetch: async (url, options) => {assert.equal(options.credentials, 'same-origin'); return {ok: true, json: async () => ({Success: 1, Message: 'Good to see you today.'})};}
    };
    vm.runInNewContext(source, context);
    assert.equal(handlers.submit, undefined);
    ready();
    assert.equal(styles['--greeting-left'], '102px');
    assert.equal(styles['--greeting-right'], '58px');
    assert.ok(resized && observed);
    handlers.submit({preventDefault() {}, submitter: {value: '4'}});
    await new Promise(resolve => setImmediate(resolve));
    assert.deepEqual(body, ['Mood', '4']);
    assert.equal(form.hidden, true);
    assert.equal(status.textContent, 'Good to see you today.');
    assert.equal(timers[0].delay, 4000);
    timers[0].fn();
    assert.equal(card.hidden, true);
    console.log('Greeting client: DOM readiness, alignment, selection and four-second dismissal pass.');
})().catch(error => {console.error(error); process.exitCode = 1;});
