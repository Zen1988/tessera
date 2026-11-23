const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const { pathToFileURL } = require('node:url');
(async () => {
    const browser = await chromium.launch({
        ...(process.env.UTILITIES_BROWSER ? { executablePath: process.env.UTILITIES_BROWSER } : { channel: 'msedge' }),
        headless: true, timeout: 20000,
    });
    const results = [];
    try {
        for (const [name, width] of [['CustomerUtilities',1280],['CustomerUtilities',390],['AgentUtilities',1280],['AgentUtilities',390],['TESSERAUtilitiesShortcuts',390]]) {
            const page = await browser.newPage({ viewport: { width, height: 900 } });
            await page.goto(pathToFileURL(path.resolve(`outputs/utilities011-preview/${name}.html`)).href);
            assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false, `${name} horizontal overflow at ${width}`);
            const duplicateIDs = await page.evaluate(() => { const ids=[...document.querySelectorAll('[id]')].map(n=>n.id);return ids.length-new Set(ids).size; });
            assert.equal(duplicateIDs, 0, 'unique control IDs');
            assert.equal(await page.locator('a[target="_blank"]:not([rel~="noopener"]),a[target="_blank"]:not([rel~="noreferrer"])').count(), 0, 'external link isolation');
            await page.keyboard.press('Tab');
            assert.equal(await page.evaluate(() => document.activeElement !== document.body), true, 'keyboard can reach a control');
            await page.screenshot({ path: `outputs/utilities011-preview/${name}-${width}.png`, fullPage: true });
            results.push({ name, width, passed: true });
            await page.close();
        }
        fs.writeFileSync('outputs/utilities011-preview/browser-validation.json', JSON.stringify(results,null,2));
        console.log(`${results.length} layouts passed overflow, IDs, external-link and keyboard checks.`);
    } finally { await browser.close(); }
})().catch(error => { console.error(error.message);process.exitCode=1; });
