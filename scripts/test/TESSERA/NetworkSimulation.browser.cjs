const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});const checks=[];
 fs.mkdirSync('outputs/network015-preview',{recursive:true});
 try {
  for(const kind of ['permitted','restricted','gap'])for(const width of [1280,390]){
   const page=await browser.newPage({viewport:{width,height:900}});
   const name=kind==='permitted'?'customer-network-simulation-preview':`network-${kind}-preview`;
   await page.goto(pathToFileURL(path.resolve(`.artifacts/${name}.html`)).href);
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'no page overflow');
   assert.equal(await page.locator('[name="EnvironmentID"]').count(),0,'no environment selector');
   const ids=await page.locator('[id]').evaluateAll(rows=>rows.map(n=>n.id));assert.equal(ids.length,new Set(ids).size,'unique IDs');
   if(kind==='restricted'){
    const node=page.locator('.NetworkSimulation__node--restricted');assert.equal(await node.count(),1);
    assert.match(await node.textContent(),/Payments/,'application system remains visible');
    assert.equal(await node.locator('rect').evaluate(n=>getComputedStyle(n).fill),'rgb(229, 231, 235)');
    await node.focus();await page.keyboard.press('Enter');
    assert.equal(await page.locator('#SimulationInspector a').count(),0,'restricted node has no CI link');
    assert.doesNotMatch(await page.locator('#SimulationInspector').textContent(),/Firewall|203\.0\.113|201/,'no hidden CI identity');
   }
   if(kind==='gap'){
    assert.equal(await page.locator('.NetworkSimulation__node--gap').count(),1);
    assert.equal(await page.locator('.NetworkSimulation__edge--unknown').count(),2);
   }
   await page.screenshot({path:`outputs/network015-preview/${kind}-${width}.png`,fullPage:true});
   checks.push({kind,width,passed:true});await page.close();
  }
  fs.writeFileSync('outputs/network015-preview/browser-validation.json',JSON.stringify(checks,null,2));
  console.log('Six layouts passed: scope-safe grey nodes, Application labels, gaps, IDs and overflow.');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
