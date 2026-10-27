// Real editor model operations and revision-checked save/reload, scoped to the Array trial.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'doc/book/iterations/2026-10-20-array-hand-index');
function moduleAt(file){const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
const {listEntries,copyObject,pasteObject,place,turn}=moduleAt('src/components/lab-editor/void-model.ts');
const {paintConstruction}=moduleAt('src/components/voxel-editor/void-construction.ts');
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex');
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=array_tutorial',headers={'Content-Type':'application/json',Origin:'http://localhost:3003'};
 const protectedFiles=['commons/void/rooms.json','commons/void/trials/transformation/rooms.json','commons/void/trials/noise/rooms.json','commons/maps/Array/final.md','commons/maps/Array/tutorial.md'];
 const before=Object.fromEntries(protectedFiles.map(p=>[p,sha(p)])),checks=[];
 const p=await(await fetch(url)).json();
 assert.equal(p.trial,'array_tutorial');assert.equal(p.rooms.floors[1].map,'Array');
 const file=path.join(root,'commons/void/trials/array_tutorial/rooms.json');
 assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 checks.push({name:'Editor serves the same trial layout as native desktop and VR',passed:true});
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/array_tutorial/manifest.json')));
 for(const id of ['row','grid','worksite']){
  const rooms=structuredClone(p.rooms),f=rooms.floors[1],source=listEntries(f,p,models,1).find(e=>e.kind==='artifact'&&e.id===id);
  assert.ok(source?.model?.url,id+' model exported');
  const bytes=fs.readFileSync(path.join(web,'public',source.model.url));
  assert.equal(bytes.readUInt32LE(0),0x46546c67);
  assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString()).meshes.length);
  const key=pasteObject(f,copyObject(f,source,p,1),0);
  let copy=listEntries(f,p,models,1).find(e=>e.key===key);
  place(f,copy,[0,0,0],p);turn(f,copy);
  copy=listEntries(f,p,models,1).find(e=>e.key===key);
  assert.equal(copy.rotation[1],90);assert.notEqual(copy.key,source.key);
  const result=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});
  assert.ok(result.ok,JSON.stringify(await result.json()));
  checks.push({name:id+': real exported meshes, independent copy, move, turn and validated placement',passed:true});
 }
 const painted=structuredClone(p.rooms),f=painted.floors[1],count=f.construction.length;
 for(const [kind,pos] of [['cube',[-3,0,7]],['slab',[-4,1,7]],['wedge',[3,0,6]]])paintConstruction(f,kind,pos,180);
 assert.equal(f.construction.length,count+3);
 paintConstruction(f,'wedge',[3,0,6],180);assert.equal(f.construction.length,count+3);
 paintConstruction(f,'erase',[-3,0,7],0);assert.equal(f.construction.length,count+2);
 const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:painted,validateOnly:true})});
 assert.ok(response.ok,JSON.stringify(await response.json()));
 checks.push({name:'Voxel cubes, slabs and wedges paint and erase on the same floor; repeated strokes are idempotent',passed:true});
 // Save a concrete edit, verify project and Desktop mirror, then restore that exact edit.
 const moved=structuredClone(p.rooms);moved.floors[1].artifacts.find(a=>a.id==='row').position[0]+=.5;
 const save=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})});
 const receipt=await save.json();assert.ok(save.ok&&receipt.saved,JSON.stringify(receipt));
 let restored=false;
 try{
  const reloaded=await(await fetch(url)).json();
  assert.deepEqual(reloaded.rooms,moved);assert.deepEqual(JSON.parse(fs.readFileSync(file)),moved);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/array_tutorial/rooms.json')),moved);
  checks.push({name:'Real save, reload, native project and Desktop trial backup agree',passed:true});
  const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})});
  assert.equal(stale.status,409);checks.push({name:'Stale save cannot overwrite newer edits',passed:true});
 } finally {
  // Use our receipt, not a freshly fetched revision: concurrent user edits must win.
  const restore=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:receipt.revision})});
  assert.ok(restore.ok,'Arrangement changed during test: restore rejected to preserve the newer edit');
  restored=true;
 }
 assert.ok(restored);assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);
 checks.push({name:'Temporary test edit restored to authored arrangement',passed:true});
 for(const [file,hash] of Object.entries(before))assert.equal(sha(file),hash,file+' preserved');
 checks.push({name:'Curated tower, other trials and original Array texts unchanged',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
