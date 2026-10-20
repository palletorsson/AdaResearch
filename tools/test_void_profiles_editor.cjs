// Real exported meshes and production editor operations; never save test copies.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await (await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const index=payload.rooms.floors.findIndex(f=>f.map==='Primitives_Profiles'),floor=payload.rooms.floors[index],checks=[];
 assert.equal(models.floors[index].map,floor.map);
 const entries=listEntries(floor,payload,models,index).filter(e=>e.artifactId==='hall');
 const profiles=entries.filter(e=>e.id.startsWith('Profile_'));
 assert.equal(profiles.length,6);
 for(const entry of profiles){
  assert.ok(entry.label.includes(' / '));
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
  const model=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString().trim());
  assert.ok(model.meshes.length>=5,'Sculpture, source outline, reading card and posts');
  assert.equal(entry.model.lights.length,1);
  assert.ok(entry.model.labels.some(l=>l.text.includes(' / ')));
  checks.push({name:entry.label+': actual meshes, outline, card and light exported',passed:true});
 }
 const sections=entries.filter(e=>e.id.startsWith('WellSection'));
 assert.equal(sections.length,2);
 checks.push({name:'Both B section tables are separate editable parts',passed:true});
 for(const id of ['Profile_1_O','Profile_2_O','Profile_3_B','WellSectionTop']){
  const entry=entries.find(e=>e.id===id),rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
  Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
  const key=pasteObject(destination,copyObject(floor,entry,payload,index),0);
  let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
  assert.equal(copy.model.url,entry.model.url);
  place(destination,copy,[0,0,4],payload);turn(destination,copy);
  copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
  assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
  checks.push({name:id+': copy/move/turn and schema-valid draft',passed:true});
 }
 const before=JSON.parse(fs.readFileSync(path.join(root,'doc/book/iterations/2026-10-19-profiles-in-the-tower/rooms-before.json')));
 for(let i=0;i<payload.rooms.floors.length;i++)if(i!==index)assert.deepEqual(payload.rooms.floors[i],before.floors[i]);
 assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'))),payload.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json')),payload.rooms);
 checks.push({name:'Other floors preserved; editor, Godot and Desktop backup share the layout',passed:true});
 fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-profiles-in-the-tower/editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Real GLBs and production editor operations; test copies not saved.'},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
