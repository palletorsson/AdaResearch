const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/full-void-spine');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const read=f=>JSON.parse(fs.readFileSync(f,'utf8'));
const stable=x=>JSON.stringify(x);
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json();
 const models=read(path.join(web,'public/void-models/manifest.json')),spine=read(path.join(root,'commons/void/spine.json'));
 const checks=[],files=new Set();function check(name,fn){fn();checks.push({name,passed:true});}
 check('205 unique map floors and 24 sequences in canonical order',()=>{
  assert.equal(payload.rooms.floors.length,205);assert.equal(new Set(payload.rooms.floors.map(f=>f.map)).size,205);
  assert.equal(payload.frame.spine.length,24);assert.deepEqual(payload.rooms.floors.map(f=>f.map),spine.floors.map(f=>f.map));
  assert.equal(payload.rooms.floors[204].map,'PostCrisis_Synthesis');
 });
 check('all 18 arranged floors preserved exactly',()=>{
  const before=read(path.join(out,'void-rooms.json.before'));assert.deepEqual(payload.rooms.floors.slice(0,18),before.floors);
  const frame=read(path.join(out,'void-layout.json.before'));
  assert.deepEqual(payload.frame.levels.slice(0,18),frame.levels);assert.equal(payload.frame.width,42);assert.equal(payload.frame.depth,18);
 });
 const trialCache=new Map();
 check('all 187 imported floor records match their saved trial arrangements',()=>{
  for(const [index,source] of Object.entries(payload.frame.floor_sources)){
   if(!trialCache.has(source.trial))trialCache.set(source.trial,read(path.join(root,'commons/void/trials',source.trial,'rooms.json')));
   assert.deepEqual(payload.rooms.floors[+index],trialCache.get(source.trial).floors[source.floor]);
  }
 });
 check('every saved artifact resolves to the existing exported model or editable assembly',()=>{
  for(const [i,floor] of payload.rooms.floors.entries()){
   const exported=models.floors[String(i)];assert.equal(exported.map,floor.map);
   const entries=context.exports.listEntries(floor,payload,models,i);
   for(const a of [...floor.artifacts,...floor.copies??[]]){
    const source=a.config?.editor_source;
    const actual=models.floors[String(source?.floor??i)]?.artifacts[source?.id??a.id];
    assert.equal(actual?.artifact,a.artifact,`${i}/${a.id} preview source`);
    assert.ok(entries.some(e=>e.id===a.id||e.artifactId===a.id),`${i}/${a.id} editable object`);
   }
   assert.ok(exported.structure.url.startsWith('/void-models/spine/'));
  }
 });
 function visit(x){if(!x||typeof x!=='object')return;for(const [k,v]of Object.entries(x)){if(k==='url'&&typeof v==='string'&&v.endsWith('.glb'))files.add(v);else visit(v);}}
 visit(models);
 let meshCount=0;
 check('all referenced actual GLBs have valid headers, meshes and buffer lengths',()=>{
  for(const url of files){
   const file=path.join(web,'public',url),b=fs.readFileSync(file);assert.equal(b.readUInt32LE(0),0x46546c67,url);assert.equal(b.readUInt32LE(8),b.length,url);
   const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString().trim());assert.ok(g.meshes?.length>0,url);
   meshCount+=g.meshes.length;
   for(const view of g.bufferViews??[])assert.ok((view.byteOffset??0)+view.byteLength<=g.buffers[view.buffer].byteLength,url);
  }
 });
 const draft=structuredClone(payload.rooms),i=204,entries=context.exports.listEntries(draft.floors[i],payload,models,i);
 const entry=entries.find(e=>e.kind==='artifact'&&e.model?.url);assert.ok(entry);
 context.exports.place(draft.floors[i],entry,[entry.position[0]+.25,entry.position[1],entry.position[2]],payload);
 context.exports.turn(draft.floors[i],entry);
 const copy=context.exports.copyObject(draft.floors[i],entry,payload,i);context.exports.pasteObject(draft.floors[i],copy,.5);
 const validated=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});
 const report=await validated.json();check('last-floor copy, move, rotation and complete-document validation work',()=>{assert.equal(validated.status,200,stable(report));assert.equal(report.valid,true);});
 // Unchanged canonical save mirrors the newly expanded tower to Desktop; the
 // edited draft above is intentionally never saved over the user's arrangement.
 const saved=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:payload.rooms,revision:payload.revision})});
 const receipt=await saved.json();check('production save and Desktop/VR mirror retain all 205 floors',()=>{
  assert.equal(saved.status,200,stable(receipt));assert.equal(receipt.saved,true);
  assert.deepEqual(read(path.join(root,'commons/void/rooms.json')),payload.rooms);
  assert.deepEqual(read('C:/Users/palle/Desktop/Ada Void/rooms.json'),payload.rooms);
 });
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,model_files:files.size,meshes:meshCount,scope:'Map access, existing GLB integrity, editing transforms and production save parity. No claim of full artifact occurrence closure or gameplay/shaft clearance.'},null,2));
 console.log(`${checks.length} editor checks passed; ${files.size} GLBs, ${meshCount} meshes`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
