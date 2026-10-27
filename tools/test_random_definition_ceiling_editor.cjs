// Exercise the real Void web-editor model against the exported Random Definition floor.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'ada_run/random-definition-ceiling');
function moduleAt(file){const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
const {listEntries,copyObject,pasteObject,place,turn}=moduleAt('src/components/lab-editor/void-model.ts');
function glb(file){
 const bytes=fs.readFileSync(file);assert.equal(bytes.readUInt32LE(0),0x46546c67,file+' is GLB');
 const json=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString('utf8').replace(/\0+$/,'').trim());
 assert.ok((json.meshes?.length??0)>0,file+' contains meshes');return json;
}
async function main(){
 const url='http://localhost:3003/api/void-layout',headers={'Content-Type':'application/json',Origin:'http://localhost:3003'};
 const payload=await(await fetch(url)).json();assert.ok(payload.rooms&&payload.revision,payload.error??'layout unavailable');
 const floor=payload.rooms.floors[71];assert.equal(floor.map,'Random_Definition');
 const ids=['seed','touch','crank','page','shelf','geiger','slots-1','slots-2','slots-3','lava','film','ride','frames'];
 assert.deepEqual(floor.artifacts.map(a=>a.id).sort(),ids.slice().sort());
 for(const artifact of floor.artifacts){
  assert.equal(artifact.interface?.style,'ceiling_instrument',artifact.id+' uses ceiling instrument interface');
  assert.ok(artifact.interface.title&&artifact.interface.action,artifact.id+' has clear interface copy');
 }
 const project=JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'),'utf8'));
 assert.deepEqual(payload.rooms,project,'web editor and Godot use the same layout');
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const entries=listEntries(floor,payload,models,71).filter(e=>e.kind==='artifact'&&ids.includes(e.id));
 assert.equal(entries.length,ids.length);
 const edited=structuredClone(payload.rooms),editableFloor=edited.floors[71];
 for(const id of ids){
  const entry=entries.find(e=>e.id===id);assert.ok(entry?.model?.url,id+' has exported editor model');
  const modelFile=path.join(web,'public',entry.model.url);const json=glb(modelFile);
  assert.equal(json.meshes.length,entry.model.meshes,id+' manifest mesh count matches GLB');
  const key=pasteObject(editableFloor,copyObject(editableFloor,entry,payload,71),.25);
  let copy=listEntries(editableFloor,payload,models,71).find(e=>e.key===key);assert.ok(copy,id+' copy exists');
  place(editableFloor,copy,[copy.position[0]+.25,copy.position[1],copy.position[2]],payload);turn(editableFloor,copy);
  copy=listEntries(editableFloor,payload,models,71).find(e=>e.key===key);
  assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360,id+' copy turns independently');
 }
 const valid=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:edited,validateOnly:true})});
 const validation=await valid.json();assert.ok(valid.ok,JSON.stringify(validation));
 // Save the unchanged fetched document once. This checks revision locking and refreshes the Desktop mirror
 // without moving any authored object or risking overwrite of a concurrent edit.
 const saved=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:payload.rooms,revision:payload.revision})});
 const receipt=await saved.json();assert.ok(saved.ok&&receipt.saved,JSON.stringify(receipt));
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8')),payload.rooms);
 const checks=[
  {name:'All 13 Random Definition artifacts use a ceiling instrument interface',passed:true},
  {name:'Godot and the web editor load the same floor 71 layout',passed:true},
  {name:'All 13 current GLB exports contain real mesh geometry',passed:true},
  {name:'All 13 artifacts copy, move and turn independently in the editor model',passed:true},
  {name:'The edited test arrangement passes the real server validator',passed:true},
  {name:'Revision-checked save mirrors the unchanged layout to Desktop',passed:true}
 ];
 fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2)+'\n');
 console.log(checks.length+' Random Definition editor checks passed');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
