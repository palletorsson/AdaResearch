// Actual editor transforms and save validation on disposable in-memory copies.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/belt-drive');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const draft=structuredClone(payload.rooms),floor=draft.floors[59],checks=[];
 const entries=ctx.exports.listEntries(floor,payload,models,59);
 for(const id of ['two-wheel-belt-drive']){
  const parts=entries.filter(e=>e.kind==='part'&&e.artifactId===id);assert.equal(parts.length,2);
  for(const e of parts){
   const b=fs.readFileSync(path.join(web,'public',e.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);
   assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length);
  }
  const e=parts[0];ctx.exports.turn(floor,e);ctx.exports.place(floor,e,[e.position[0]+.25,e.position[1],e.position[2]],payload);
  ctx.exports.pasteObject(floor,ctx.exports.copyObject(floor,e,payload,59),.25);
 }
 checks.push('Both real exported groups load, move, rotate and copy through the editor model.');
 const workbench=await(await fetch('http://localhost:3003/api/prefab-workbench')).json();
 for(const id of ['belt_drive']){
  const p=workbench.nodes.find(n=>n.id===id);assert.equal(p.preview.length,2);
  ctx.exports.placeWorkbenchPrefab(draft.floors[58],p,[0,0],id+'-editor-check');
 }
 checks.push('The belt-drive prefab uses the shared tree/catalogue and can be placed from the workbench.');
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);
 checks.push('Copied/moved parts serialize and pass save validation without changing the visitor layout.');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2)+'\n');console.log(checks.join('\n'));
}
run().catch(e=>{console.error(e);process.exitCode=1;});
