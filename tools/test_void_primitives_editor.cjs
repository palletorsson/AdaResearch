// Verify real model exports and editor transforms on an unsaved copy of the tower.
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
  assert.equal(payload.rooms.floors.length,14);assert.equal(Object.keys(models.floors).length,14);
  assert.equal(models.failures.length,0);
  for(let index=7;index<14;index++){
    const floor=payload.rooms.floors[index];
    const entries=listEntries(floor,payload,models,index).filter(e=>e.kind==='part');
    assert.ok(entries.length>=8);
    for(const entry of entries){
      if(entry.model.meshes){
        const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));
        assert.equal(bytes.readUInt32LE(0),0x46546c67);
        const document=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());
        assert.ok(document.meshes.length>0);
      }else assert.ok(entry.model.labels.length>0,entry.id+' must contain a model or label');
    }
    checks.push({name:`floor ${index}: ${entries.length} independently selectable parts use real exported models or labels`,passed:true});
    const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
    Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
    const original=entries.find(e=>e.model.meshes>0&&e.id!=='TimberDescent');
    const key=pasteObject(destination,copyObject(floor,original,payload,index),0);
    let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
    assert.equal(copy.model.url,original.model.url);
    place(destination,copy,[0,original.position[1],4],payload);turn(destination,copy);
    copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
    assert.equal(copy.position[0],0);assert.equal(copy.position[2],4);
    assert.equal(copy.rotation[1],(original.rotation[1]+90)%360);
    assert.equal(destination.copies[0].config.only_parts[0],original.id);
    const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
    const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
    checks.push({name:`floor ${index}: ${original.id} copies across floors, moves, rotates and passes the native save validator`,passed:true});
  }
  assert.equal(JSON.stringify(payload.rooms),before);
  const after=await (await fetch('http://localhost:3003/api/void-layout')).json();
  assert.equal(after.revision,payload.revision,'Checks never modify the shared layout');
  checks.push({name:'Original shared layout remains unchanged by editor tests',passed:true});
  fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-void-primitives-complete/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
  console.log(`${checks.length} Primitives editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
