// Real lab-editor operations on the noise trial through the production model code and
// the live save API: copy, move, turn, save, reload, restore; isolation from the curated
// tower and the Transformation trial. Needs the encyclopedia dev server on port 3003.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const report=path.join(root,'doc/book/iterations/2026-10-20-void-noise-types-trial');
const trialFile=path.join(root,'commons/void/trials/noise/rooms.json');
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=noise';
 const headers={'Content-Type':'application/json',Origin:'http://localhost:3003'};
 const checks=[];
 const curated={rooms:sha(path.join(root,'commons/void/rooms.json')),transformation:sha(path.join(root,'commons/void/trials/transformation/rooms.json')),parts:sha(path.join(root,'commons/void/line_parts.json'))};
 const payload=await(await fetch(url)).json();
 assert.equal(payload.title,'Noise / Random Noise Types');assert.equal(payload.trial,'noise');
 const original=JSON.stringify(payload.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync(trialFile,'utf8')),payload.rooms);
 checks.push({name:'API serves the noise trial from its own rooms.json with its own frame and title',passed:true});
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/noise/manifest.json'),'utf8'));
 assert.equal(models.floors['1'].map,'Random_Noise_Types');
 for(const id of ['point','bench','surface','field','spectrum','weather']){
  const rooms=structuredClone(payload.rooms),floor=rooms.floors[1];
  const entry=listEntries(floor,payload,models,1).find(e=>e.kind==='artifact'&&e.id===id);
  assert.ok(entry?.model?.url,id+' has a real exported model');
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));
  assert.equal(bytes.readUInt32LE(0),0x46546c67,id+' model is a GLB');
  assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString()).meshes.length,id+' GLB carries meshes');
  const key=pasteObject(floor,copyObject(floor,entry,payload,1),0);
  let copy=listEntries(floor,payload,models,1).find(e=>e.key===key);
  assert.ok(copy&&copy.key!==entry.key,id+' paste makes an independent record');
  place(floor,copy,[-16,copy.position[1],-3],payload);turn(floor,copy);
  copy=listEntries(floor,payload,models,1).find(e=>e.key===key);
  assert.equal(copy.position[0],-16);assert.equal(copy.position[2],-3);
  assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  assert.equal(copy.model.url,entry.model.url);
  const source=floor.artifacts.find(a=>a.id===id);
  assert.deepEqual(source.config,payload.rooms.floors[1].artifacts.find(a=>a.id===id).config,id+' original record untouched by the copy');
  const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});
  const result=await response.json();assert.ok(response.ok&&result.valid,id+': '+JSON.stringify(result));
  checks.push({name:id+': native GLB, independent copy, move, turn and save validation',passed:true});
 }
 // A real save: move the bench by half a metre, reload it, then put it back.
 const moved=structuredClone(payload.rooms);const bench=moved.floors[1].artifacts.find(a=>a.id==='bench');bench.position=[bench.position[0]+0.5,bench.position[1]];
 let saved=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:payload.revision})});
 let receipt=await saved.json();assert.ok(saved.ok&&receipt.saved,'save: '+JSON.stringify(receipt));
 let reloaded=await(await fetch(url)).json();
 assert.equal(reloaded.rooms.floors[1].artifacts.find(a=>a.id==='bench').position[0],bench.position[0]);
 assert.deepEqual(JSON.parse(fs.readFileSync(trialFile,'utf8')),reloaded.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/noise/rooms.json','utf8')),reloaded.rooms);
 checks.push({name:'A real save moves the bench, the reload agrees, and the Desktop trial backup mirrors it',passed:true});
 const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:payload.revision})});
 assert.equal(stale.status,409);
 checks.push({name:'A stale revision is refused instead of overwriting',passed:true});
 saved=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:payload.rooms,revision:reloaded.revision})});
 receipt=await saved.json();assert.ok(saved.ok&&receipt.saved,'restore: '+JSON.stringify(receipt));
 reloaded=await(await fetch(url)).json();
 assert.equal(JSON.stringify(reloaded.rooms),original);
 checks.push({name:'Restoring the arrangement returns the file to its authored content',passed:true});
 fs.writeFileSync(path.join(report,'layout-change.json'),JSON.stringify({moved_then_restored:'bench +0.5 m on x',revision_before:payload.revision,revision_after:reloaded.revision},null,2));
 assert.equal(sha(path.join(root,'commons/void/rooms.json')),curated.rooms);
 assert.equal(sha(path.join(root,'commons/void/trials/transformation/rooms.json')),curated.transformation);
 assert.equal(sha(path.join(root,'commons/void/line_parts.json')),curated.parts);
 const history=JSON.parse(fs.readFileSync(path.join(report,'before.json'),'utf8'));
 for(const [file,hash] of Object.entries(history.preserved_sha256))assert.equal(sha(path.join(root,file)),hash,file);
 checks.push({name:'Curated tower, Transformation trial, shared part manifest, original map/tutorial/final and artifact scripts stay unchanged',passed:true});
 for(const a of history.rooms.floors[1].artifacts){const current=reloaded.rooms.floors[1].artifacts.find(x=>x.id===a.id);assert.equal(current.artifact,a.artifact);assert.deepEqual(current.config,a.config);}
 checks.push({name:'All six original artifacts keep their source and museum configuration',passed:true});
 fs.writeFileSync(path.join(report,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
