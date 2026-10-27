const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
const url='http://localhost:3003/api/void-layout?trial=matter_gates',headers={'Content-Type':'application/json',Origin:'http://localhost:3003'};
const checks=[];
async function validate(rooms){const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});const report=await response.json();assert.ok(response.ok,JSON.stringify(report));}
async function main(){
 const response=await fetch(url),payload=await response.json();assert.ok(response.ok,JSON.stringify(payload));
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/matter_gates/manifest.json')));
 assert.deepEqual(models.failures,[]);
 const entries=listEntries(payload.rooms.floors[1],payload,models,1),parts=entries.filter(e=>e.kind==='part');
 assert.ok(parts.length>=15);
 for(const entry of parts){
  assert.ok(entry.model.meshes>0||entry.model.labels.length>0,entry.id+' has actual geometry or source text');
  if(entry.model.url){const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());assert.ok(gltf.meshes.length>0);}
  const rooms=structuredClone(payload.rooms),floor=rooms.floors[1];
  const key=pasteObject(floor,copyObject(floor,entry,payload,1),0);
  let copy=listEntries(floor,payload,models,1).find(e=>e.key===key);
  place(floor,copy,[16,entry.position[1],4],payload);turn(floor,copy);
  await validate(rooms);checks.push({name:entry.id+': real source preview and independent copy/move/rotation accepted',passed:true});
 }
 const rooms=structuredClone(payload.rooms);
 rooms.floors[1].artifacts[0].config.parts={InputX:{position:[-1.45,0,-.5],rotation:[0,0,0]}};
 await validate(rooms);
 const saved=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,revision:payload.revision})});
 const receipt=await saved.json();assert.ok(saved.ok&&receipt.saved,JSON.stringify(receipt));
 try {
  assert.deepEqual((await(await fetch(url)).json()).rooms,rooms);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/trials/matter_gates/rooms.json'))),rooms);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/matter_gates/rooms.json')),rooms);
  checks.push({name:'Part edit saves to native project and shared Desktop/VR mirror and reloads unchanged',passed:true});
  const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,revision:'stale-matter-layout'})});assert.equal(stale.status,409);
  checks.push({name:'Stale save rejected',passed:true});
 } finally {
  const restore=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:payload.rooms,revision:receipt.revision})});assert.ok(restore.ok,'Concurrent edit: preserve it instead of restoring');
 }
 assert.deepEqual((await(await fetch(url)).json()).rooms,payload.rooms);
 checks.push({name:'Authored study restored after reversible save test',passed:true});
 fs.writeFileSync(path.join(root,'ada_run/matter-gates/editor-checks.json'),JSON.stringify({passed:true,checks},null,2)+'\n');
 console.log(checks.length+' Matter Gates editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
