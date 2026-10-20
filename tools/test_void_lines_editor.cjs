// Real editor operations and save validation, without persisting test copies.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
  const payload=await (await fetch('http://localhost:3003/api/void-layout')).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const before=JSON.stringify(payload.rooms),checks=[];
  for(const name of ['MeasurementRoom','FloorPlanTable','FullSizeRuler','LightTunnel','CollectionHangers','SevenPlanks4','Hand_light']){
    const rooms=structuredClone(payload.rooms),floor=rooms.floors[3],target=rooms.floors[7];
    const original=listEntries(floor,payload,models,3).find(e=>e.kind==='part'&&e.id===name);
    assert.ok(original?.model?.url,name+' has a real model');
    const bytes=fs.readFileSync(path.join(web,'public',original.model.url));
    assert.equal(bytes.readUInt32LE(0),0x46546c67);
    assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString()).meshes.length>0);
    const key=pasteObject(target,copyObject(floor,original,payload,3),0);
    let copy=listEntries(target,payload,models,7).find(e=>e.key===key);
    place(target,copy,[0,original.position[1],4.5],payload);turn(target,copy);
    copy=listEntries(target,payload,models,7).find(e=>e.key===key);
    assert.equal(copy.model.url,original.model.url);
    assert.equal(copy.position[0],0);assert.equal(copy.position[2],4.5);
    assert.equal(copy.rotation[1],(original.rotation[1]+90)%360);
    const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
    const result=await response.json();assert.ok(response.ok&&result.valid,name+': '+JSON.stringify(result));
    checks.push({name:name+': real GLB, independent copy, placement, rotation and save validation',passed:true});
  }
  assert.equal(JSON.stringify(payload.rooms),before);
  const after=await (await fetch('http://localhost:3003/api/void-layout')).json();
  assert.equal(JSON.stringify(after.rooms),before);
  checks.push({name:'Tests leave the saved shared layout unchanged',passed:true});
  fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-lines-that-open-and-light/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
  console.log(checks.length+' editor checks passed');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
