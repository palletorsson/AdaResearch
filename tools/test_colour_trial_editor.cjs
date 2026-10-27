// Use production editor operations and the real revision-checked save endpoint.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'doc/book/iterations/2026-10-20-colour-celebration');
const ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const towerHash=()=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'commons/void/rooms.json'))).digest('hex');
 const towerBefore=towerHash();
 const url='http://localhost:3003/api/void-layout?trial=color',headers={'Content-Type':'application/json',Origin:'http://localhost:3003'},checks=[];
 const p=await(await fetch(url)).json(),file=path.join(root,'commons/void/trials/color/rooms.json');
 assert.equal(p.trial,'color');assert.equal(p.rooms.floors[1].map,'Color_Context_Placed');
 assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 checks.push({name:'Lab editor serves the same Colour layout as desktop and VR',passed:true});
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/color/manifest.json')));
 assert.deepEqual(models.failures,[]);
 assert.equal(models.lighting.ambient_color,'ffffff');
 assert.ok(Math.abs(models.lighting.ambient_energy-.45)<1e-6);
 assert.equal(p.rooms.floors[1].artifacts.length,23);
 for(const item of p.rooms.floors[1].artifacts){
  const e=listEntries(p.rooms.floors[1],p,models,1).find(e=>e.kind==='artifact'&&e.id===item.id);
  assert.ok(e?.model?.url,item.id+' has its own native model');
  assert.ok(fs.existsSync(path.join(web,'public',e.model.url)));
 }
 checks.push({name:'All 23 full-size original compositions have separate editable native models',passed:true});
 for(const id of ['one','by-shape','by-height','by-neighbour']){
  const rooms=structuredClone(p.rooms),f=rooms.floors[1],source=listEntries(f,p,models,1).find(e=>e.kind==='artifact'&&e.id===id);
  assert.ok(source?.model?.url,id+' real model');
  const bytes=fs.readFileSync(path.join(web,'public',source.model.url));
  assert.equal(bytes.readUInt32LE(0),0x46546c67);
  assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString()).meshes.length>=5);
  assert.equal(source.model.lights.filter(l=>l.name.startsWith('WhiteStudyLight')).length,2);
  const key=pasteObject(f,copyObject(f,source,p,1),0);
  let copy=listEntries(f,p,models,1).find(e=>e.key===key);
  place(f,copy,[16,0,5],p);turn(f,copy);
  copy=listEntries(f,p,models,1).find(e=>e.key===key);
  assert.equal(copy.rotation[1],90);
  assert.notEqual(copy.key,source.key);
  const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});
  assert.ok(response.ok,JSON.stringify(await response.json()));
  checks.push({name:id+': native geometry and lamps; copy, move and turn validate independently',passed:true});
 }
 const moved=structuredClone(p.rooms);moved.floors[1].artifacts[0].position[0]+=.5;
 const save=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})});
 const receipt=await save.json();assert.ok(save.ok&&receipt.saved,JSON.stringify(receipt));
 try{
  assert.deepEqual((await(await fetch(url)).json()).rooms,moved);
  assert.deepEqual(JSON.parse(fs.readFileSync(file)),moved);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/color/rooms.json')),moved);
  checks.push({name:'Real save and reload agree with native file and Desktop mirror',passed:true});
  const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})});
  assert.equal(stale.status,409);
  checks.push({name:'Stale saves cannot overwrite newer edits',passed:true});
 } finally {
  const restore=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:receipt.revision})});
  assert.ok(restore.ok,'Restore declined: a newer user edit must be preserved');
 }
 assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);
 for(const [file,digest] of Object.entries(JSON.parse(fs.readFileSync(path.join(out,'before.json'))))){
  if(file==='commons/void/rooms.json')continue;
  assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),digest,file);
 }
 assert.equal(towerHash(),towerBefore,'Trial save must not write to the curated tower');
 checks.push({name:'Test edit restored; original museum, chapter texts and curated tower unchanged',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' Colour editor checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
