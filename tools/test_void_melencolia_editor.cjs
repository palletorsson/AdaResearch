// Exercise real editor code; validate copies without saving any test edits.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
  const endpoint='http://localhost:3003/api/void-layout';
  const payload=await (await fetch(endpoint)).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const original=JSON.stringify(payload.rooms),floor=payload.rooms.floors[13],checks=[];
  const entries=listEntries(floor,payload,models,13);
  for(const id of ['CourtDeck','CourtRampLeft','CourtRampRight','MelencoliaEngraving','CompositionTable']){
    const entry=entries.find(e=>e.artifactId==='hall'&&e.id===id);assert.ok(entry,id);
    const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
    const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
    Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
    const key=pasteObject(destination,copyObject(floor,entry,payload,13),0);
    let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
    assert.equal(copy.model.url,entry.model.url);
    place(destination,copy,[0,0,4],payload);turn(destination,copy);
    copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
    assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
    const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
    const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
    checks.push({name:`Actual exported geometry; copy, move, turn and validate ${id}`,passed:true});
  }
  const solids=floor.artifacts.filter(a=>['pyramid','pyramidlong','cube_scene'].includes(a.artifact));
  assert.equal(solids.length,9);
  for(const solid of solids) assert.ok(entries.some(e=>e.id===solid.id||e.artifactId===solid.id),solid.id);
  checks.push({name:'Nine original court solids remain individually editable',passed:true});
  const receipt=JSON.parse(fs.readFileSync(path.join(root,'doc/book/iterations/2026-10-19-primitives-restored-relations/layout-change.json'),'utf8'));
  const crypto=require('node:crypto');
  for(const [name,hash] of Object.entries(receipt.preserved_text_sha256)){
    assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'commons/maps/Primitives_Melencolia',name))).digest('hex'),hash);
  }
  checks.push({name:'Existing final.md and tutorial.md preserved',passed:true});
  assert.equal(JSON.stringify(payload.rooms),original);
  fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-primitives-restored-relations/editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Production editor code and actual Godot exports. Validation only; no test edits saved.'},null,2));
  console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
