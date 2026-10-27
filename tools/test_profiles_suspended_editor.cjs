const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const metadata=JSON.parse(fs.readFileSync(path.join(root,'commons/void/line_parts.json'),'utf8'));
 const {listEntries,place,turn,copyObject,pasteObject}=context.exports;
 const draft=structuredClone(payload.rooms),floor=draft.floors[10],checks=[];
 const ids=['SuspendedShaft_O','SuspendedShaft_B','HangingChannel_C','HangingSpool_I','RollingTyre_O'];
 function check(name,fn){fn();checks.push({name,passed:true});}
 for(const id of ids){
  let entry=listEntries(floor,payload,models,10).find(e=>e.kind==='part'&&e.artifactId==='hall'&&e.id===id);
  check(id+': independent actual glyph model and registered default',()=>{
   assert.ok(entry);assert.ok(metadata.void_primitive_profiles[id]);
   const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));
   assert.equal(bytes.readUInt32LE(0),0x46546c67);
   const glb=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString().trim());
   assert.ok(glb.meshes.length>=(id==='RollingTyre_O'?1:3));
   assert.ok(glb.accessors.some(a=>a.type==='VEC3'&&a.count>100));
  });
  const moved=[entry.position[0]+.25,entry.position[1],entry.position[2]];
  place(floor,entry,moved,payload);
  entry=listEntries(floor,payload,models,10).find(e=>e.key===entry.key);
  const oldYaw=entry.rotation[1];turn(floor,entry);
  entry=listEntries(floor,payload,models,10).find(e=>e.key===entry.key);
  const key=pasteObject(floor,copyObject(floor,entry,payload,10),3);
  check(id+': move/turn and isolated editable copy',()=>{
   assert.equal(entry.position[0],moved[0]);assert.equal(entry.rotation[1],oldYaw+90);
   const copy=listEntries(floor,payload,models,10).find(e=>e.key===key);
   assert.equal(copy.id,id);assert.notEqual(copy.artifactId,'hall');assert.equal(copy.model.url,entry.model.url);
  });
 }
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});
 const result=await response.json();
 check('production editor accepts all five moved and copied parts',()=>assert.ok(response.ok&&result.valid,JSON.stringify(result)));
 const before=JSON.parse(fs.readFileSync(path.join(root,'ada_run/profiles-suspended/rooms-before.json'),'utf8'));
 check('all other floors and existing Profiles placements preserved',()=>{
  for(let i=0;i<before.floors.length;i++)if(i!==10)assert.deepEqual(payload.rooms.floors[i],before.floors[i]);
  for(const item of before.floors[10].artifacts){
   const current=payload.rooms.floors[10].artifacts.find(a=>a.id===item.id);
   if(item.id!=='hall')assert.deepEqual(current,item);
   else for(const key of Object.keys(item).filter(k=>k!=='config'))assert.deepEqual(current[key],item[key]);
  }
 });
 check('native and Desktop/VR shared layout match; test draft was not saved',()=>{
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'),'utf8')),payload.rooms);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8')),payload.rooms);
  assert.equal(payload.rooms.floors[10].artifacts.find(a=>a.id==='hall').config.connects_next_floor,true);
 });
 fs.writeFileSync(path.join(root,'ada_run/profiles-suspended/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
