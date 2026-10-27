// Isolated browser test. Save requests are intercepted; no shared layout writes.
const {chromium}=require('C:/Users/palle/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),out=path.join(root,'ada_run/editor-webgl');fs.mkdirSync(out,{recursive:true});
const file=path.join(root,'commons/void/rooms.json'),hash=()=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
async function main(){
 const before=hash(),browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 try{
  const context=await browser.newContext({viewport:{width:1600,height:1000}}),page=await context.newPage(),errors=[],saves=[];
  let releaseLayout;const layoutGate=new Promise(resolve=>{releaseLayout=resolve;});
  page.setDefaultTimeout(90000);page.on('pageerror',e=>errors.push(e.message));
  await context.route('**/api/void-layout*',async route=>{
   if(route.request().method()!=='POST'){await layoutGate;return route.continue();}
   const body=route.request().postDataJSON();saves.push(body);
   await route.fulfill({json:body.validateOnly?{valid:true,warnings:[]}:{saved:true,revision:'isolated-proof',warnings:[],live:[]}});
  });
  await context.addInitScript(()=>{
   window.__blockEditorGL=true;window.__contextReleases=0;
   const original=HTMLCanvasElement.prototype.getContext;
   HTMLCanvasElement.prototype.getContext=function(type,...args){
    if(window.__blockEditorGL&&String(type).includes('webgl'))return null;
    const result=original.call(this,type,...args);
    if(result&&type==='webgl2'&&!result.__proof){
     result.__proof=true;const get=result.getExtension.bind(result);
     result.getExtension=function(name){const extension=get(name);if(extension&&name==='WEBGL_lose_context'&&!extension.__proof){extension.__proof=true;const lose=extension.loseContext.bind(extension);extension.loseContext=()=>{window.__contextReleases++;lose();};}return extension;};
    }
    return result;
   };
  });
  await page.goto('http://localhost:3003/lab-editor?mode=void&floor=16',{waitUntil:'domcontentloaded',timeout:120000});
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor();
  await page.getByRole('button',{name:'Continue without 3D',exact:true}).click();
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  await page.getByRole('status',{name:'Graphics status'}).waitFor();
  await page.getByRole('button',{name:'Graphics details',exact:true}).click();
  await page.getByRole('button',{name:'Dismiss graphics notice',exact:true}).click();
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  await page.getByRole('button',{name:'Graphics details',exact:true}).click();await page.keyboard.press('Escape');
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  await page.getByRole('button',{name:'Graphics details',exact:true}).click();
  await page.getByRole('button',{name:'Show floor objects',exact:true}).click();
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  releaseLayout();
  await page.getByRole('textbox',{name:'Find floor object'}).waitFor();
  const object=page.locator('[class*="objects"] button').nth(1);await object.waitFor();await object.click();
  const x=page.getByRole('spinbutton',{name:'Position X'}),initial=Number(await x.inputValue()),changed=initial+.25;
  await x.fill(String(changed));await x.blur();
  await page.waitForFunction(()=>document.querySelector('footer[role="status"]')?.textContent?.includes('Saved to desktop'));
  assert.equal(Number(await x.inputValue()),changed);assert.ok(saves.some(s=>!s.validateOnly));
  await page.screenshot({path:path.join(out,'unavailable.png')});
  await page.evaluate(()=>{window.__blockEditorGL=false;});await page.getByRole('button',{name:'Retry 3D preview',exact:true}).click();
  await page.getByLabel('Void floor 3D viewport').waitFor();
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  assert.equal(Number(await x.inputValue()),changed);
  const gpu=await page.evaluate(()=>{const canvas=document.querySelector('canvas[aria-label="Void floor 3D viewport"]'),gl=canvas.getContext('webgl2');return {renderer:gl.getParameter(gl.RENDERER),version:gl.getParameter(gl.VERSION),preservedBuffer:gl.getContextAttributes().preserveDrawingBuffer};});
  assert.equal(gpu.preservedBuffer,false);
  await page.waitForTimeout(2000);await page.screenshot({path:path.join(out,'recovered.png')});
  await page.evaluate(()=>{const gl=document.querySelector('canvas[aria-label="Void floor 3D viewport"]').getContext('webgl2');window.__restoreEditorGL=gl.getExtension('WEBGL_lose_context');window.__restoreEditorGL.loseContext();});
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor();
  assert.equal(Number(await x.inputValue()),changed);
  await page.evaluate(()=>window.__restoreEditorGL.restoreContext());
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  assert.equal(Number(await x.inputValue()),changed);
  // A synthetic notification leaves a live GL slot to measure cleanup of an
  // old renderer. A genuinely lost slot is already released by the browser.
  await page.evaluate(()=>document.querySelector('canvas[aria-label="Void floor 3D viewport"]').dispatchEvent(new Event('webglcontextlost',{cancelable:true})));await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor();
  const releases=await page.evaluate(()=>window.__contextReleases);
  await page.getByRole('button',{name:'Retry 3D preview',exact:true}).click();
  await page.getByRole('alert',{name:'3D preview unavailable'}).waitFor({state:'hidden'});
  assert.equal(await page.getByLabel('Void floor 3D viewport').count(),1);assert.equal(Number(await x.inputValue()),changed);
  assert.ok(await page.evaluate(()=>window.__contextReleases)>releases);
  // The body archive is a separate trial and can be tested explicitly. Popup
  // dismissal on the user's main floor does not depend on that trial's state.
  const verifyBody=process.argv.includes('--body');
  if(verifyBody){
  const body=await context.newPage();body.setDefaultTimeout(90000);body.on('pageerror',e=>errors.push(e.message));
  await body.goto('http://localhost:3003/lab-editor?mode=void&trial=chains_studies&floor=2',{waitUntil:'domcontentloaded',timeout:120000});
  await body.getByRole('alert').filter({hasText:'Body 3D preview unavailable'}).waitFor();
  assert.ok(await body.getByRole('button',{name:'Replay parent',exact:true}).isVisible());
  await body.evaluate(()=>{window.__blockEditorGL=false;});await body.getByRole('button',{name:'Retry body preview',exact:true}).click();
  await body.getByLabel('Modular body 3D preview').waitFor();await body.getByRole('alert').filter({hasText:'Body 3D preview unavailable'}).waitFor({state:'hidden'});
  }
  assert.deepEqual(errors,[]);assert.equal(hash(),before);
  const report={passed:true,floor:16,secondaryBodyChecked:verifyBody,gpu,saveRequestsIntercepted:saves.length,sharedLayoutUnchanged:true,checks:['Disabled WebGL does not crash React','Graphics notice dismisses by Continue, close, Escape and Show floor objects while layout is still loading','Dismissed notice remains a small status bar while data loads independently','Object list and numeric editing remain usable','Retry restores 3D with the selected object and edited draft','Lost and restored contexts preserve draft and controls','Retry releases the old context and leaves one canvas',...(verifyBody?['Secondary body preview also fails safely and retries without losing its archive']:[]),'No uncaught page errors','No shared layout writes']};
  fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
 }finally{await browser.close();}
}main().catch(e=>{console.error(e);process.exitCode=1});
