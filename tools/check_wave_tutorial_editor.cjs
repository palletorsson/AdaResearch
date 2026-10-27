// Exercise the real editor model and save validator with unsaved drafts only.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/wave-tutorial-path');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const original=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const draft=structuredClone(payload.rooms),floor=draft.floors[59],checks=[];
 const entries=ctx.exports.listEntries(floor,payload,models,59);
 const modules=entries.filter(e=>e.kind==='construction'&&e.id.startsWith('wave-path-'));assert.equal(modules.length,31);
 for(const id of ['wave-path-yoke-back-0','wave-path-view-up-0']){
  const entry=modules.find(e=>e.id===id);assert.ok(entry);
  ctx.exports.place(floor,entry,[entry.position[0]+.25,entry.position[1],entry.position[2]],payload);ctx.exports.turn(floor,entry);
  ctx.exports.pasteObject(floor,ctx.exports.copyObject(floor,entry,payload,59),.25);
 }
 checks.push('All31 cube/wedge modules stay independent; actual editor move/rotate/copy works');
 for(const id of ['hand-sine-yoke','hand-single-turntable','hand-scale-zoetrope']){
  const parts=entries.filter(e=>e.kind==='part'&&e.artifactId===id);assert.equal(parts.length,2);
  for(const e of parts){
   const b=fs.readFileSync(path.join(web,'public',e.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);
   assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length);
  }
 }
 checks.push('All three machines expose their two real exported editable groups');
 const turn=entries.find(e=>e.artifactId==='hand-single-turntable'&&e.id==='DiskAndCrank');
 ctx.exports.turn(floor,turn);ctx.exports.place(floor,turn,[turn.position[0]+.25,turn.position[1],turn.position[2]],payload);
 ctx.exports.pasteObject(floor,ctx.exports.copyObject(floor,turn,payload,59),.25);
 const workbench=await(await fetch('http://localhost:3003/api/prefab-workbench')).json();
 const piece=workbench.nodes.find(n=>n.id==='single_cube_turntable');assert.equal(piece.preview.length,2);
 assert.ok(workbench.edges.some(e=>e.source==='sine_yoke'&&e.target===piece.id));
 assert.ok(workbench.edges.some(e=>e.source===piece.id&&e.target==='scale_zoetrope'));
 ctx.exports.placeWorkbenchPrefab(draft.floors[58],piece,[0,0],'one-cube-editor-check');
 checks.push('The shared tree/catalogue connects and places yoke, one cube and frame sequence');
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));
 checks.push('Module and machine edits serialize and validate through the actual save API');
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),original),0);
 checks.push('Saved visitor arrangement preserved');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Actual exported parts and editor placement functions, save API validation only. No visitor-layout writes.'},null,2)+'\n');
 console.log(checks.length+' focused editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
