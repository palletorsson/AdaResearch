// Production editor operations and real API; live play keeps its authored layout.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'doc/book/iterations/2026-10-20-colour-flashlight');
const ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=color_flashlight',headers={'Content-Type':'application/json',Origin:'http://localhost:3003'},checks=[];
 const p=await(await fetch(url)).json(),file=path.join(root,'commons/void/trials/color_flashlight/rooms.json');
 assert.equal(p.trial,'color_flashlight');assert.equal(p.rooms.floors[1].map,'Color_Flashlight');
 assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 checks.push({name:'Editor and native player resolve the same separate Flashlight layout',passed:true});
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/color_flashlight/manifest.json')));
 assert.deepEqual(models.failures,[]);
 assert.ok(Math.abs(models.lighting.ambient_energy-.08)<1e-6);
 const entries=listEntries(p.rooms.floors[1],p,models,1).filter(e=>e.model?.url);
 assert.equal(entries.length,5);
 assert.deepEqual(Array.from(entries.find(e=>e.id==='WhiteRoom').position),[-10,0,0]);
 assert.deepEqual(Array.from(entries.find(e=>e.id==='LightWell').position),[10,0,0]);
 checks.push({name:'Editor places the white room over shaft A and lightwell over shaft B',passed:true});
 for(const entry of entries){
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));
  assert.equal(bytes.readUInt32LE(0),0x46546c67);
  assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString()).meshes.length>0);
  assert.ok(entry.model.lights.length>0);
  const rooms=structuredClone(p.rooms),f=rooms.floors[1];
  const key=pasteObject(f,copyObject(f,entry,p,1),0);
  let copy=listEntries(f,p,models,1).find(e=>e.key===key);
  place(f,copy,[16,0,3],p);turn(f,copy);
  copy=listEntries(f,p,models,1).find(e=>e.key===key);
  assert.notEqual(copy.key,entry.key);
  assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});
  const validation=await response.json();
  assert.ok(response.ok,JSON.stringify(validation));
  checks.push({name:entry.label+': real geometry and lights; copy, move and turn validate',passed:true});
 }
 assert.equal(models.floors['1'].artifacts.lamps.model.lights.length,4);
 assert.equal(models.floors['1'].artifacts.pink.model.lights.length,5);
 assert.equal(models.floors['1'].artifacts.rooms.parts.WhiteRoom.lights.length,7);
 assert.equal(models.floors['1'].artifacts.rooms.parts.LightWell.lights.length,10);
 const wallLights=models.floors['1'].artifacts['cube-wall'].model.lights;
 assert.equal(wallLights.length,80);
 assert.equal(wallLights.filter(l=>l.visible).length,30);
 assert.ok(wallLights.every(l=>l.color==='ff0000')); 
 checks.push({name:'Original lamps and rooms plus sixteen cubicles and red lighting presets exported',passed:true});
 // Save the current document unchanged while the user is playing; this still
 // exercises validation, atomic native save and the Desktop mirror.
 const save=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:p.revision})});
 const receipt=await save.json();assert.ok(save.ok&&receipt.saved,JSON.stringify(receipt));
 assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/color_flashlight/rooms.json')),p.rooms);
 checks.push({name:'Real save and reload match the Godot file and Desktop mirror',passed:true});
 const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:'outdated-test-revision'})});
 assert.equal(stale.status,409);
 checks.push({name:'Stale saves are rejected',passed:true});
 for(const [file,digest] of Object.entries(JSON.parse(fs.readFileSync(path.join(out,'before.json'))))){
  if(file==='commons/void/rooms.json')continue;
  assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),digest,file);
 }
 checks.push({name:'Original museum geometry and chapter texts preserved',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' Flashlight editor checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});

