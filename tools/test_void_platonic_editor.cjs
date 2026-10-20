// Real exported models and production editor copy/move/turn. Validation only.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await (await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const floor=payload.rooms.floors[8],original=JSON.stringify(payload.rooms),checks=[];
 const names=['Tetrahedron','Cube','Octahedron','Dodecahedron','Icosahedron'];
 const entries=listEntries(floor,payload,models,8).filter(e=>e.artifactId==='hall'&&names.includes(e.id));
 assert.equal(entries.length,5);
 for(const entry of entries){
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
  const jsonLength=bytes.readUInt32LE(12),model=JSON.parse(bytes.subarray(20,20+jsonLength).toString().trim());
  // The exporter flattens node names. Inspect the actual mesh data instead.
  const faceMaterial=model.materials.findIndex(m=>Math.abs(m.pbrMetallicRoughness.metallicFactor-.05)<1e-5);
  const face=model.meshes.flatMap(m=>m.primitives).find(p=>p.material===faceMaterial);
  assert.ok(face);assert.equal(model.accessors[face.indices].count/3,{Tetrahedron:4,Cube:12,Octahedron:8,Dodecahedron:36,Icosahedron:20}[entry.id]);
  const edgeMaterial=model.materials.findIndex(m=>Math.abs((m.extensions?.KHR_materials_emissive_strength?.emissiveStrength??0)-.16)<1e-5);
  assert.ok(edgeMaterial>=0&&model.meshes.some(m=>m.primitives.some(p=>p.material===edgeMaterial&&model.accessors[p.indices].count>100)));
  assert.ok(entry.model.labels.some(l=>l.text===entry.id.toUpperCase()));
  assert.ok(entry.model.lights.some(l=>l.name==='CarriedLight'&&!l.visible&&Math.abs(l.range-2.6)<1e-5));
  const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
  Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
  const key=pasteObject(destination,copyObject(floor,entry,payload,8),0);
  let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
  assert.equal(copy.model.url,entry.model.url);
  place(destination,copy,[0,entry.position[1],4],payload);turn(destination,copy);
  copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
  assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
  checks.push({name:`${entry.id}: actual faces/edges, copy/move/turn, schema-valid draft`,passed:true});
 }
 assert.equal(JSON.stringify(payload.rooms),original);
 const out=path.join(root,'doc/book/iterations/2026-10-19-platonic-solids');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Production editor and Godot GLB geometry; no test copies saved.'},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
