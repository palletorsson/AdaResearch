// Production editor transforms + real scene exports. Test edits are never saved.
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
  const original=JSON.stringify(payload.rooms),floor=payload.rooms.floors[12],checks=[];
  const parts=listEntries(floor,payload,models,12).filter(e=>e.artifactId==='sky-walk');
  assert.equal(parts.length,15);
  for(const entry of parts){
    if(entry.model.meshes){
      const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
    }else assert.ok(entry.model.labels.length);
  }
  checks.push({name:'All 15 named parts have real Godot geometry or text exports',passed:true});
  for(const id of ['EntryRamp1','MovingPlatform','SkyLookout','RefinementPassage']){
    const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
    Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
    const entry=parts.find(e=>e.id===id);assert.ok(entry);
    const key=pasteObject(destination,copyObject(floor,entry,payload,12),0);
    let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
    assert.equal(copy.model.url,entry.model.url);
    place(destination,copy,[0,0,4],payload);turn(destination,copy);
    copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
    assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
    const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
    const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
    checks.push({name:`Copy, move, turn and validate ${id} on another floor`,passed:true});
  }
  for(const id of ['portal_span','portal_ferry']){
    assert.ok(payload.catalog.props[id]&&models.props[id].meshes>0);
    checks.push({name:`Reusable prefab ${id} is in the palette with actual exported geometry`,passed:true});
  }
  assert.equal(JSON.stringify(payload.rooms),original);
  fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-portals-sky-walk/editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Production editor functions, actual geometry, validation only; no saved test edits.'},null,2));
  console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
