const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict'),vm=require('node:vm');
const {chromium}=require('C:/Users/palle/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/spatial-comparison/full-native');
const base=process.env.SPATIAL_URL||'http://localhost:3003';fs.mkdirSync(out,{recursive:true});
const files=['commons/void/rooms.json','commons/void/layout.json','commons/maps/Trans_Rotation/map_data.json','commons/data/museum/em_overrides.json','ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json'];
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
async function main(){
 const before=Object.fromEntries(files.map(f=>[f,hash(f)])),r=await fetch(base+'/api/map-comparison?floor=16&grid=current');assert.equal(r.status,200);const doc=await r.json();
 const grid=doc.layers.find(l=>l.id==='grid'),museum=doc.layers.find(l=>l.id==='museum'),tower=doc.layers.find(l=>l.id==='void');
 assert.equal(doc.map,'Trans_Rotation');assert.equal(grid.native,true);assert.equal(grid.objects.length,12);assert.deepEqual([grid.width,grid.depth],[39,73]);assert.deepEqual([tower.width,tower.depth],[42,18]);assert.equal(museum.native,true);assert.ok(museum.objects.length>=12);assert.equal(museum.boxes.length,0);assert.equal(museum.status,'Current Museum builder · native snapshot');assert.ok(museum.structure.url);assert.ok(museum.roof.url);assert.ok(museum.builtAt.startsWith('2026-10-26'));
 for(const name of new Set(grid.objects.map(o=>o.artifact)))assert.equal(museum.objects.filter(o=>o.artifact===name).length,grid.objects.filter(o=>o.artifact===name).length,'Museum retains original '+name+' occurrences');
 assert.ok(grid.objects.find(o=>o.artifact==='rotation_array_compare').token.includes('#columns:2'));assert.equal(tower.objects.find(o=>o.artifact==='rotation_array_compare'&&!o.parent).configuration.columns,1);
 for(const object of [...grid.objects,...museum.objects]){const b=fs.readFileSync(path.join(web,'public',object.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.ok(object.cell.length===2||object.cell.length===0);}
 assert.equal((await fetch(base+'/api/map-comparison',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'})).status,405);
 assert.equal((await fetch(base+'/api/map-comparison?floor=-1')).status,400);
 assert.equal((await fetch(base+'/api/map-comparison/prepare?floor=-1',{method:'POST'})).status,400);
 assert.equal((await (await fetch(base+'/api/map-comparison/prepare?floor=16&grid=current',{method:'POST'})).json()).state,'ready');
 // Unit-check the actual rigid display transform, including yaw and anchors.
 const ts=require(path.join(web,'node_modules/typescript')),exports={};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/comparison-transform.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,{exports});
 const settings={layout:'overlay',alignment:'anchor',mode:'top',focus:'all',colours:'sources',roof:false,layers:Object.fromEntries(doc.layers.map(l=>[l.id,{visible:true,structure:true,objects:true,route:true,opacity:1,x:0,z:0,yaw:90,anchor:l.objects[0]?.id??''}]))};
 for(const layer of [grid,tower]){const pose=exports.displayTransform(layer,settings),p=layer.objects[0].position,c=Math.cos(pose.yaw),s=Math.sin(pose.yaw);assert.ok(Math.hypot(c*p[0]+s*p[2]+pose.position[0],p[1]-layer.groundY+pose.position[1],-s*p[0]+c*p[2]+pose.position[2])<1e-8);}
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1680,height:1050}}),errors=[],writes=[];page.setDefaultTimeout(90000);page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(r.method()==='POST'&&/api\/(void-layout|museum-editor|maps\/cell-edit|map-comparison)/.test(r.url()))writes.push(r.url());});
 try{
  await page.goto(base+'/lab-editor?mode=void&floor=16&compare=1&grid=current',{waitUntil:'domcontentloaded',timeout:120000});
  await page.getByLabel('Grid Museum Void comparison viewport').waitFor();await page.locator('footer[role="status"]').filter({hasText:'Native snapshots loaded'}).waitFor();
  assert.equal(await page.getByRole('button',{name:/save/i}).count(),0);assert.equal(await page.locator('canvas').count(),1);
  await page.screenshot({path:path.join(out,'side-by-side.png')});
  await page.getByRole('button',{name:'Full window',exact:true}).click();
  await page.getByRole('group',{name:'Focus source'}).getByRole('button',{name:'Museum',exact:true}).click();await page.waitForTimeout(500);
  const original=await page.locator('canvas').screenshot();await page.screenshot({path:path.join(out,'museum-full.png')});
  await page.getByLabel('Museum section cut',{exact:true}).uncheck();await page.waitForTimeout(200);assert.notEqual(crypto.createHash('sha256').update(await page.locator('canvas').screenshot()).digest('hex'),crypto.createHash('sha256').update(original).digest('hex'),'Museum section reveals interior architecture');await page.getByLabel('Museum section cut',{exact:true}).check();await page.getByLabel('Show overhead geometry').check();assert.equal(await page.getByLabel('Show overhead geometry').isChecked(),true);await page.getByLabel('Show overhead geometry').uncheck();
  await page.getByLabel('Comparison materials').selectOption('sources');await page.waitForTimeout(250);assert.notEqual(crypto.createHash('sha256').update(await page.locator('canvas').screenshot()).digest('hex'),crypto.createHash('sha256').update(original).digest('hex'),'Original and source-colour displays differ');
  await page.getByLabel('Comparison materials').selectOption('original');
  await page.getByRole('button',{name:'Explore',exact:true}).click();await page.locator('canvas').focus();const entry=await page.locator('canvas').screenshot();await page.keyboard.down('w');await page.waitForTimeout(1000);await page.keyboard.up('w');assert.notEqual(crypto.createHash('sha256').update(await page.locator('canvas').screenshot()).digest('hex'),crypto.createHash('sha256').update(entry).digest('hex'),'Eye-level camera moves');await page.screenshot({path:path.join(out,'museum-explore.png')});
  await page.getByRole('button',{name:'3D orbit',exact:true}).click();
  await page.getByRole('group',{name:'Focus source'}).getByRole('button',{name:'Grid',exact:true}).click();await page.waitForTimeout(300);await page.screenshot({path:path.join(out,'grid-full.png')});
  await page.getByRole('button',{name:'Show panels',exact:true}).click();
  await page.getByRole('button',{name:'Overlay',exact:true}).click();await page.getByRole('button',{name:'Fit all',exact:true}).click();
  assert.equal(await page.getByLabel('Grid opacity').inputValue(),'0.28');await page.waitForTimeout(500);await page.screenshot({path:path.join(out,'overlay.png')});
  await page.locator('[class*="objectList"] button').filter({hasText:'rotation_array_compare'}).first().click();
  await page.getByText('Matching by artifact type.',{exact:false}).waitFor();
  await page.getByLabel('Grid anchor').selectOption('19,25');await page.getByLabel('Void anchor').selectOption('a:angle-bands');
  assert.equal(await page.getByLabel('Alignment',{exact:true}).inputValue(),'anchor');
  await page.getByLabel('Grid x',{exact:true}).fill('2');await page.getByLabel('Grid yaw',{exact:true}).fill('90');
  await page.locator('[aria-label="Museum source"] input[type="checkbox"]').first().uncheck();
  await page.getByRole('button',{name:'3D orbit',exact:true}).click();await page.getByRole('button',{name:'Fit all',exact:true}).click();await page.waitForTimeout(500);await page.screenshot({path:path.join(out,'aligned-artifact.png')});
  await page.getByRole('button',{name:'Reset comparison',exact:true}).click();assert.equal(await page.getByLabel('Grid x',{exact:true}).inputValue(),'0');assert.equal(await page.getByLabel('Grid yaw',{exact:true}).inputValue(),'0');
  await page.getByRole('button',{name:'Look closely',exact:true}).click();assert.equal(await page.getByRole('group',{name:'Focus source'}).getByRole('button',{name:'Grid',exact:true}).getAttribute('aria-pressed'),'true');
  const other=await (await fetch(base+'/api/map-comparison?floor=5&grid=current')).json();assert.equal(other.layers.every(l=>l.native),true);assert.equal((await (await fetch(base+'/api/map-comparison/prepare?floor=5&grid=current')).json()).state,'ready');
  await page.getByLabel('Compare floor').selectOption('5');await page.getByRole('heading',{name:other.title,exact:true}).waitFor();await page.locator('footer[role="status"]').filter({hasText:'Native snapshots loaded'}).waitFor();assert.equal(await page.locator('canvas').count(),1);
  await page.getByRole('group',{name:'Focus source'}).getByRole('button',{name:'Museum',exact:true}).click();await page.getByRole('button',{name:'Full window',exact:true}).click();await page.waitForTimeout(300);await page.screenshot({path:path.join(out,'triangle-museum-full.png')});
  assert.deepEqual(errors,[]);assert.deepEqual(writes,[]);
 }finally{await browser.close();}
 for(const f of files)assert.equal(hash(f),before[f],f+' changed');
 const report={passed:true,map:doc.map,nativeGridObjects:12,nativeMuseumObjects:museum.objects.length,museum:'Actual current Museum build, including all original Grid occurrences and Museum staging/furniture',voidObjects:tower.objects.length,sourceFilesUnchanged:files,checks:['Actual configured Grid GLBs and exact source cells','Full native Museum geometry; original occurrence counts match Grid','Real Void placements/models through the production adapter','Solo full-window views, original/source materials, section/overhead controls, eye-level camera movement','Different Grid/Void configurations remain visible','Rigid anchor alignment preserves metres under 90-degree rotation','Authoring API rejects writes; export API rejects invalid floors and reuses fresh snapshots','Prepared floor 5 has both native sources; switching maps disposes the old renderer','Side-by-side, overlay, visibility, opacity, anchor, look-closely and camera controls','One renderer; no uncaught page errors','No authoring POST requests or source file changes']};
 fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}main().catch(e=>{console.error(e);process.exitCode=1});
