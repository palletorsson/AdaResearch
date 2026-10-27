// Actual exported parts and editor mutations, in validation-only layout drafts.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=process.argv[2]?path.resolve(process.argv[2]):path.join(root,'ada_run/scale-zoetrope-playback');
const expectedParts=Number(process.argv[3]||4);
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const original=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),draft=structuredClone(payload.rooms),checks=[];
 const entries=ctx.exports.listEntries(draft.floors[59],payload,models,59);
 const parts=entries.filter(e=>e.kind==='part'&&e.artifactId==='hand-scale-zoetrope');assert.equal(parts.length,expectedParts);
 for(const entry of parts){
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
  const json=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));assert.ok(json.meshes.length>0);
  ctx.exports.place(draft.floors[59],entry,[entry.position[0]+.25,entry.position[1],entry.position[2]+.25],payload);
  ctx.exports.turn(draft.floors[59],entry);
 }
 checks.push(`${expectedParts} active groups resolve real native GLBs and edit independently`);
 const current=ctx.exports.listEntries(draft.floors[59],payload,models,59).find(e=>e.artifactId==='hand-scale-zoetrope'&&e.id==='DiskAndCrank');
 const clip=ctx.exports.copyObject(draft.floors[59],current,payload,59),copy=ctx.exports.pasteObject(draft.floors[59],clip,.25);
 assert.ok(ctx.exports.listEntries(draft.floors[59],payload,models,59).find(e=>e.key===copy));
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());checks.push('Actual editor move, rotate and copy validate through the save API');
 assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));checks.push('Part poses and copies survive layout serialization');
 const workbench=await(await fetch('http://localhost:3003/api/prefab-workbench')).json();
 const piece=workbench.nodes.find(n=>n.id==='scale_zoetrope');assert.ok(piece?.placement);assert.equal(piece.preview.length,expectedParts);
 assert.ok(workbench.edges.filter(e=>e.target==='scale_zoetrope').some(e=>e.kind==='develop'));
 const placed=ctx.exports.placeWorkbenchPrefab(draft.floors[58],piece,[0,0],'zoetrope-editor-check');
 assert.ok(ctx.exports.listEntries(draft.floors[58],payload,models,58).find(e=>e.key===placed));
 checks.push(`Shared catalogue exposes ${expectedParts} real preview parts and live-editor placement`);
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),original),0);checks.push('Checks preserve the saved visitor layout');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Native GLB parsing, actual editor model move/rotate/copy and server validation, shared catalogue placement. Validation-only drafts.'},null,2)+'\n');
 console.log(checks.length+' focused editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
