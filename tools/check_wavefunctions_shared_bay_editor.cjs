// Targeted editor proof in a validation-only draft; never adds test items to the live floor.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/wavefunctions-shared-bay');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const checks=[],file=path.join(root,'commons/void/rooms.json'),original=fs.readFileSync(file);
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
 assert.deepEqual(payload.rooms,JSON.parse(original));
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const floor=payload.rooms.floors[59],entries=ctx.exports.listEntries(floor,payload,models,59);
 const ids=['clock','turn',...['backdrop','side','low-edge','store','stock','lamp'].map(x=>'return-bay-'+x)];
 for(const id of ids){
  const entry=entries.find(e=>e.id===id);assert.ok(entry?.model?.url,id+' has actual model');
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
  assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12))).meshes.length,id+' GLB contains real meshes');
 }
 checks.push('Both original cubes and six independent props resolve actual exported mesh models');
 const draft=structuredClone(payload.rooms);
 for(const id of ids){
  const entry=ctx.exports.listEntries(draft.floors[59],payload,models,59).find(e=>e.id===id);
  ctx.exports.place(draft.floors[59],entry,[entry.position[0]+.25,entry.position[1],entry.position[2]+.25],payload);
  ctx.exports.turn(draft.floors[59],entry);
 }
 const modelEntry=ctx.exports.listEntries(draft.floors[59],payload,models,59).find(e=>e.id==='return-bay-store');
 const clip=ctx.exports.copyObject(draft.floors[59],modelEntry,payload,59);
 const copied=ctx.exports.pasteObject(draft.floors[59],clip,.25);
 assert.ok(ctx.exports.listEntries(draft.floors[59],payload,models,59).find(e=>e.key===copied));
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());
 checks.push('Move, turn and copy remain valid through the actual editor model and server validator');
 assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));
 checks.push('Editor arrangement survives JSON serialization');
 assert.equal(Buffer.compare(fs.readFileSync(file),original),0);
 checks.push('Validation leaves the saved desktop/VR layout untouched');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Real exported source models, editor move/turn/copy and validation-only drafts; no interactive VR simulation.'},null,2)+'\n');
 console.log(checks.length+' focused editor checks passed');
}
run().catch(error=>{console.error(error);process.exitCode=1;});
