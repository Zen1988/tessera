const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const { pathToFileURL } = require('node:url');
(async () => {
 const browser = await chromium.launch({channel:'msedge',headless:true,timeout:20000});const results=[];
 try {
  for (const kind of ['detail','list','decision']) for (const width of [1280,390]) {
   const page=await browser.newPage({viewport:{width,height:900}});
   await page.goto(pathToFileURL(path.resolve(`outputs/change012-preview/${kind}.html`)).href);
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,`${kind} overflow ${width}`);
   assert.equal(await page.locator('a[href*="Action=CustomerTicketZoom"],a[href*="Action=CustomerITSMConfigItem"]').count(),0,'no private object links');
   const duplicates=await page.evaluate(()=>{const a=[...document.querySelectorAll('[id]')].map(n=>n.id);return a.length-new Set(a).size});assert.equal(duplicates,0,'no duplicate control IDs');
   await page.keyboard.press('Tab');assert.equal(await page.evaluate(()=>document.activeElement!==document.body),true,'keyboard entry');
   if (kind==='detail') {
    assert.equal(await page.locator('details').count(),4,'four submitted phases');
    assert.equal(await page.locator('form').count(),0,'announcement cannot mutate');
    await page.locator('details').first().locator('summary').focus();await page.keyboard.press('Enter');assert.equal(await page.locator('details').first().evaluate(e=>e.open),false,'keyboard can collapse phase');
   }
   await page.screenshot({path:`outputs/change012-preview/${kind}-${width}.png`,fullPage:true});results.push({kind,width,passed:true});await page.close();
  }
  fs.writeFileSync('outputs/change012-preview/browser-validation.json',JSON.stringify(results,null,2));console.log('6 layouts passed overflow, private-link, IDs and keyboard checks; detail has four read-only runbook phases.');
 } finally {await browser.close()}
})().catch(e=>{console.error(e.message);process.exitCode=1});
