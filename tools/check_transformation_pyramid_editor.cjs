const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/transformation-required-route-2026-10-26');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const before=JSON.parse(fs.readFileSync(path.join(out,'before-models.json'),'utf8'));
 for(const [id,model] of Object.entries(before.floors))if(!['14','15'].includes(id))assert.deepEqual(models.floors[id],model,'unrelated models preserved '+id);
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),draft=structuredClone(payload.rooms);
 let prefabs=0,glbs=0;
 for(const index of [14,15]){
  const f=draft.floors[index],entries=ctx.exports.listEntries(f,payload,models,index);
  assert.equal(f.walls.length,0);assert.equal(f.construction.filter(c=>c.id.startsWith('ShaftRim-Plinth-')).length,34);
  for(const a of f.artifacts.filter(a=>a.id.startsWith('shaft-rim-pyramid-'))){
   assert.equal(a.artifact,'pyramid_blocker');assert.equal(a.scale,1);assert.equal(a.height,1);
   const e=entries.find(e=>e.kind==='artifact'&&e.id===a.id);assert.ok(e?.model?.url,'real independently editable pyramid model '+a.id);
   const b=fs.readFileSync(path.join(web,'public',e.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);
   const j=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(j.meshes?.length);glbs++;
   ctx.exports.place(f,e,[e.position[0]+.05,e.position[1],e.position[2]+.05],payload);ctx.exports.turn(f,e);
   ctx.exports.pasteObject(f,ctx.exports.copyObject(f,e,payload,index),.05);prefabs++;
  }
 }
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,await response.text());
 assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0,'draft validation must not change the live layout');
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8')),payload.rooms,'desktop/VR shared layout');
 const report={passed:true,prefabs,parsedGLBs:glbs,floors:[14,15],unrelatedModelFloorsPreserved:Object.keys(before.floors).length-2,
  scope:'Production editor: actual source GLBs, independent move/rotate/copy, validated unsaved draft and unchanged live save; desktop/VR layout mirror parity.'};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}
run().catch(e=>{console.error(e);process.exitCode=1});
