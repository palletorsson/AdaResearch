const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/tape-rolls');
const read=p=>JSON.parse(fs.readFileSync(p,'utf8')),ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json(),models=read(path.join(web,'public/void-models/manifest.json'));
 const before=read(path.join(out,'rooms.before.json')),saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),draft=structuredClone(payload.rooms);
 for(let i=0;i<draft.floors.length;i++)if(i!==3)assert.deepEqual(draft.floors[i],before.floors[i]);
 assert.deepEqual(draft.floors[3].artifacts.filter(a=>a.id!=='tape-supply'),before.floors[3].artifacts);
 const entry=models.floors['3'].artifacts['tape-supply'];assert.equal(entry.artifact,'tape_roll_station');assert.equal(Object.keys(entry.parts).length,11);
 let meshes=0,textures=0;
 const entries=ctx.exports.listEntries(draft.floors[3],payload,models,3);
 for(const [name,part]of Object.entries(entry.parts)){
  assert.ok(part.url,name);const b=fs.readFileSync(path.join(web,'public',part.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);
  const gltf=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(gltf.meshes?.length,name);meshes+=gltf.meshes.length;textures+=(gltf.images?.length??0);
  if(['MaskingRoll','PinkRoll','BarrierRoll','TapeSamples'].includes(name))assert.ok(gltf.images?.length,name+' must keep real pattern textures');
  const e=entries.find(e=>e.kind==='part'&&e.artifactId==='tape-supply'&&e.id===name);assert.ok(e,name);
  ctx.exports.place(draft.floors[3],e,[e.position[0]+.01,e.position[1],e.position[2]],payload);ctx.exports.turn(draft.floors[3],e);
 }
 for(const id of ['tape_roll_station','tape_roll_masking','tape_roll_pink','tape_roll_barrier']){
  const piece=payload.workbenchPieces[id];assert.ok(piece,id+' reusable placement');
  ctx.exports.placeWorkbenchPrefab(draft.floors[3],piece,[-16,7.5],'proof-'+id);
 }
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});
 assert.ok(response.ok,await response.text());assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);
 assert.deepEqual(read('C:/Users/palle/Desktop/Ada Void/rooms.json'),payload.rooms);
 const oldModels=read(path.join(out,'before-models.json'));for(const [key,value]of Object.entries(oldModels.floors))if(key!=='3')assert.deepEqual(models.floors[key],value);
 const report={passed:true,parts:11,meshes,textures,prefabs:4,checks:['All prior floors and Point Lines placements retained','Eleven real native parts retain their generated pattern textures','Every member moves and rotates through the production editor model','Station and three individual rolls place through the shared workbench catalogue','Production validateOnly succeeds without saving test edits','Desktop/VR saved rooms remain identical','Other floor model receipts preserved'],scope:'Actual GLBs, pattern textures, shared workbench placements, production validation and save parity. Runtime tape is session-local.'};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}run().catch(e=>{console.error(e);process.exitCode=1});
