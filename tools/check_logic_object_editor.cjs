const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=process.argv[2]?path.resolve(process.argv[2]):path.join(root,'ada_run/logic-object-controls-2026-10-26');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const before=JSON.parse(fs.readFileSync(path.join(out,'before-models.json'),'utf8'));
 for(const [id,model] of Object.entries(before.floors))if(!['14','21','22'].includes(id))assert.deepEqual(models.floors[id],model,'unrelated models preserved '+id);
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),draft=structuredClone(payload.rooms);
 let parts=0,glbs=0;
 for(const floor of [14,21,22]){
  const f=draft.floors[floor],entries=ctx.exports.listEntries(f,payload,models,floor);
  for(const a of f.artifacts.filter(a=>a.artifact.startsWith('matter_spring_'))){
   const members=entries.filter(e=>e.kind==='part'&&e.artifactId===a.id);assert.ok(members.some(e=>e.part==='Controls'||e.id?.endsWith('/Controls'))||members.length>=7);
   for(const e of members){
    if(e.model.url){const b=fs.readFileSync(path.join(web,'public',e.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);const j=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(j.meshes?.length);glbs++;}
    ctx.exports.place(f,e,[e.position[0]+.01,e.position[1],e.position[2]+.01],payload);ctx.exports.turn(f,e);parts++;
   }
   const e=members.find(e=>e.model.url);ctx.exports.pasteObject(f,ctx.exports.copyObject(f,e,payload,floor),.05);
  }
 }
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,await response.text());
 assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);
 const report={passed:true,parts,parsedGLBs:glbs,floors:[14,21,22],unrelatedModelFloorsPreserved:Object.keys(before.floors).length-3,scope:'Production editor API + actual regenerated member models. Move/rotate/copy validated in an unsaved draft; user arrangements unchanged.'};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}
run().catch(e=>{console.error(e);process.exitCode=1});
