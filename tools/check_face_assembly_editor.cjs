// Real GLBs plus actual live-editor operations, in validation-only drafts.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/face-assembly');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const original=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),draft=structuredClone(payload.rooms),checks=[];
 for(const [floor,id,prefix] of [[5,'triangle-edge-assembly','Triangle'],[7,'square-edge-assembly','Square']]){
  let entries=ctx.exports.listEntries(draft.floors[floor],payload,models,floor);
  const parts=entries.filter(e=>e.kind==='part'&&e.artifactId===id);assert.equal(parts.length,14);
  assert.ok(parts.find(e=>e.id==='Controls').model.labels.some(label=>label.text==='MORE FACES'));
  const faces=parts.filter(e=>e.id.startsWith(prefix));assert.equal(faces.length,12);
  for(const entry of parts){
   const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
   const json=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));assert.ok(json.meshes.length>0);
  }
  checks.push(id+': all12 faces, support and MORE FACES controls resolve actual exported geometry');
  const face=faces[1];
  ctx.exports.place(draft.floors[floor],face,[face.position[0]+.25,face.position[1]+.25,face.position[2]+.25],payload);
  ctx.exports.turn(draft.floors[floor],face);
  entries=ctx.exports.listEntries(draft.floors[floor],payload,models,floor);
  const moved=entries.find(e=>e.key===face.key);assert.ok(moved);
  const clip=ctx.exports.copyObject(draft.floors[floor],moved,payload,floor),copy=ctx.exports.pasteObject(draft.floors[floor],clip,.25);
  assert.ok(ctx.exports.listEntries(draft.floors[floor],payload,models,floor).find(e=>e.key===copy));
  checks.push(id+': real editor moves, turns and copies an individual face');
 }
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());checks.push('Both floors and isolated copies validate through the shared desktop/VR save API');
 const workbench=await(await fetch('http://localhost:3003/api/prefab-workbench')).json();
 for(const id of ['triangle_assembly_table','square_assembly_table']){
  const node=workbench.nodes.find(n=>n.id===id);assert.ok(node?.placement);assert.equal(node.preview.length,14);
  const placed=ctx.exports.placeWorkbenchPrefab(draft.floors[6],node,[0,0],'face-check-'+id);
  assert.ok(ctx.exports.listEntries(draft.floors[6],payload,models,6).find(e=>e.key===placed));
 }
 checks.push('Same catalogue provides both14-part prefabs to the tree/workbench and live editor');
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),original),0);checks.push('All checks preserve saved visitor arrangements');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Native GLB parsing, actual editor move/rotate/copy, API validation and shared catalogue placement. Validation-only drafts.'},null,2)+'\n');
 console.log(checks.length+' focused editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
