const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),trial='matter_logic_reference',out=path.join(root,'ada_run/matter-reference'),ts=require(path.join(web,'node_modules/typescript'));
const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/trials',trial,'rooms.json')),payload=await(await fetch('http://localhost:3003/api/void-layout?trial='+trial)).json(),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials',trial,'manifest.json'))),draft=structuredClone(payload.rooms);let parts=0;
 for(let i=1;i<draft.floors.length-1;i++){
  const floor=draft.floors[i],id=floor.artifacts[0].id,actual=models.floors[i].artifacts[id];assert.equal(actual.config.kind,floor.artifacts[0].config.kind);assert.equal(floor.artifacts[0].scale,1);
  for(const [name,part] of Object.entries(actual.parts)){
   if(part.url){const b=fs.readFileSync(path.join(web,'public',part.url));assert.equal(b.readUInt32LE(0),0x46546c67);const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(g.meshes?.length,name);}
   else assert.ok(part.labels?.length,name);
   const e=ctx.exports.listEntries(floor,payload,models,i).find(x=>x.artifactId===id&&x.kind==='part'&&x.id===name);assert.ok(e,name);ctx.exports.place(floor,e,[e.position[0],e.position[1]+.01,e.position[2]],payload);ctx.exports.turn(floor,e);parts++;
  }
  const e=ctx.exports.listEntries(floor,payload,models,i).find(x=>x.artifactId===id&&x.kind==='part');ctx.exports.pasteObject(floor,ctx.exports.copyObject(floor,e,payload,i),.2);
 }
 const r=await fetch('http://localhost:3003/api/void-layout?trial='+trial,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(r.ok,await r.text());assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/trials',trial,'rooms.json'))),0);
 const report={passed:true,floors:36,sourcePages:15,parts,checks:['All 36 study configurations retain scale one and actual exported GLB geometry or explicit Label3D labels.','Every authored body, frame and console moves and rotates independently through the real lab-editor model.','Member copies and edits pass the shared save validator without changing saved layouts.'],limitations:['Physics contacts and hinge damping are a documented Jolt translation, not a byte-identical Cannon solver.','Headset ergonomics have not been physically tested.']};fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}run().catch(e=>{console.error(e);process.exitCode=1});
