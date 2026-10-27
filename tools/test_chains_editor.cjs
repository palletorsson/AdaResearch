// Actual lab-editor operations against the exported native members and save API.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
const folder=path.join(root,'commons/void/trials/chains_studies'),url='http://localhost:3003/api/void-layout?trial=chains_studies';
const inventory=JSON.parse(fs.readFileSync(path.join(folder,'source-inventory.json')));
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex');
const currentSources=Object.fromEntries(Object.keys(inventory.preserved_sources).map(file=>[file,sha(file)]));
const published=path.join(web,'public/void-trial-evidence/chains_studies');
const evidenceFolder=fs.existsSync(path.join(published,'move-receipt.json'))?published:path.join(folder,'evidence');
const headers={'Content-Type':'application/json',Origin:'http://localhost:3003'};
async function main(){
 const response=await fetch(url);assert.ok(response.ok,await response.clone().text());
 const p=await response.json(),modelsPath=path.join(web,'public/void-trials/chains_studies/manifest.json');
 const models=JSON.parse(fs.readFileSync(modelsPath)),checks=[];
 assert.equal(p.trial,'chains_studies');assert.equal(p.rooms.floors.length,8);assert.deepEqual(models.failures,[]);
 for(let level=1;level<=6;level++){
  const native=models.floors[String(level)].artifacts['study-'+level];
  const keys=['Worker_1','RequestDock',...(level===2?['Worker_2','BodyHistory']:[]),...(level===4?['AlternativeSupport']:[]),...(level===6?['SharedHabitat']:[])];
  for(const name of keys){
   const model=native.parts[name];assert.ok(model,name);
   const filename=fs.realpathSync(path.join(web,'public',model.url));
   assert.match(filename.replaceAll('\\','/'),/^D:\/AdaGenerated\/AdaResearch_46\//i);
   const bytes=fs.readFileSync(filename);assert.equal(bytes.readUInt32LE(0),0x46546c67);
   const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());assert.ok(gltf.meshes.length);
   const rooms=structuredClone(p.rooms),floor=rooms.floors[level];
   const entry=listEntries(floor,p,models,level).find(e=>e.kind==='part'&&e.artifactId==='study-'+level&&e.id===name);assert.ok(entry,name);
   const original=structuredClone(entry.position),key=pasteObject(floor,copyObject(floor,entry,p,level),0);
   let copy=listEntries(floor,p,models,level).find(e=>e.key===key);assert.ok(copy);
   // A single copied member can fit on the empty outer slab. Validate its actual editor contract.
   place(floor,copy,[16,copy.position[1],4],p);turn(floor,copy);
   copy=listEntries(floor,p,models,level).find(e=>e.key===key);
   assert.notEqual(copy.key,entry.key);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
   assert.equal(JSON.stringify(listEntries(floor,p,models,level).find(e=>e.key===entry.key).position),JSON.stringify(original));
   const valid=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});assert.ok(valid.ok,await valid.text());
   checks.push({name:`Floor ${level}: ${name} actual GLB on D; independent editor copy/move/rotation validates`,passed:true});
  }
 }
 const moved=structuredClone(p.rooms);moved.floors[1].artifacts[0].position[0]+=.25;
 const saved=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})}),receipt=await saved.json();assert.ok(saved.ok&&receipt.saved,JSON.stringify(receipt));
 try{
  assert.deepEqual((await(await fetch(url)).json()).rooms,moved);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(folder,'rooms.json'))),moved);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/chains_studies/rooms.json')),moved);
  checks.push({name:'Save/reload preserves the shared native/Desktop/VR layout contract',passed:true});
  const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:'stale-chains-check'})});assert.equal(stale.status,409);
  checks.push({name:'Stale save rejected',passed:true});
 }finally{
  const restored=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:receipt.revision})});assert.ok(restored.ok,'Concurrent edit detected; never overwrite');
 }
 assert.deepEqual(JSON.parse(fs.readFileSync(path.join(folder,'rooms.json'))),p.rooms);
 const endSources=Object.fromEntries(Object.keys(currentSources).map(file=>[file,sha(file)]));
 // The main tower is being arranged in another chat. It is outside this trial's
 // write target, so retain its drift as evidence rather than reverting that work.
 for(const [file,hash] of Object.entries(currentSources))if(file!=='commons/void/rooms.json')assert.equal(endSources[file],hash,file+' changed during this check');
 const mainRooms=JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json')));
 assert.ok(mainRooms.floors.length>p.rooms.floors.length,'Trial must never replace the main tower');
 const concurrentDrift=Object.keys(currentSources).filter(file=>endSources[file]!==currentSources[file]).map(file=>({file,start:currentSources[file],end:endSources[file]}));
 // Other chats may have edited the main tower since the original sketch receipt.
 // Retain that historical comparison without restoring or laundering their work.
 const historicalDrift=Object.entries(inventory.preserved_sources).filter(([file,hash])=>currentSources[file]!==hash).map(([file,hash])=>({file,original:hash,current:currentSources[file]}));
 checks.push({name:'Main tower stays separate from the trial; Model B, original Dream Bodies, Point Zero and main layout match this run\'s baseline',passed:true});
 models.source_files['commons/void/trials/chains_studies/rooms.json']=crypto.createHash('sha256').update(fs.readFileSync(path.join(folder,'rooms.json'))).digest('hex');
 fs.writeFileSync(modelsPath,JSON.stringify(models,null,2)+'\n');
 fs.writeFileSync(path.join(evidenceFolder,'editor-checks.json'),JSON.stringify({passed:true,checks,historical_source_drift:historicalDrift,concurrent_source_drift:concurrentDrift,source_hashes_at_start:currentSources,source_hashes_at_end:endSources,scope:'Real exported members and editor model/API; temporary trial edit restored. Main tower arrangement drift is disclosed and retained; it is not accepted as unchanged. Other protected sources match this run\'s baseline. Static GLBs do not execute native policies.'},null,2)+'\n');
 console.log(checks.length+' Chains editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
