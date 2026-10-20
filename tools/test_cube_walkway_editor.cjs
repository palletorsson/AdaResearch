// Exercise production editor transforms on an unsaved copy, using the real Godot exports.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
  const checks=[];
  for(const trial of [false,true]){
    const endpoint='http://localhost:3003/api/void-layout'+(trial?'?trial=transformation':'');
    const payload=await (await fetch(endpoint)).json();
    const models=JSON.parse(fs.readFileSync(path.join(web,'public',trial?'void-trials/transformation/manifest.json':'void-models/manifest.json'),'utf8'));
    const index=trial?1:7,floor=payload.rooms.floors[index],before=JSON.stringify(payload.rooms);
    const parts=listEntries(floor,payload,models,index).filter(e=>e.artifactId==='carried-walkway');
    assert.equal(parts.length,39,'36 construction pieces and three labels');
    for(const entry of parts){
      if(entry.model.meshes){
        const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));
        assert.equal(bytes.readUInt32LE(0),0x46546c67);
        const doc=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());
        assert.ok(doc.meshes.length>0);
      }else assert.ok(entry.model.labels.length>0);
    }
    checks.push({name:`${trial?'Transformation':'Cube'}: all 36 pieces and three labels have real editor exports`,passed:true});
    for(const id of ['LandingCube1_1_1','EntryWedge1']){
      const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
      Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
      const original=parts.find(e=>e.id===id);assert.ok(original);
      const key=pasteObject(destination,copyObject(floor,original,payload,index),0);
      let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
      assert.equal(copy.model.url,original.model.url);
      place(destination,copy,[0,0,4],payload);turn(destination,copy);
      copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
      assert.equal(copy.position[0],0);assert.equal(copy.position[2],4);
      assert.equal(copy.rotation[1],(original.rotation[1]+90)%360);
      assert.equal(destination.copies[0].config.only_parts[0],id);
      const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
      const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
      checks.push({name:`${trial?'Transformation':'Cube'}: copy ${id} to another floor, move, turn and validate without saving`,passed:true});
    }
    assert.ok(payload.catalog.props.cube_walkway);
    assert.ok(models.props.cube_walkway.meshes>0);
    checks.push({name:`${trial?'Transformation':'Cube'}: complete construction is a reusable prefab`,passed:true});
    assert.equal(JSON.stringify(payload.rooms),before);
  }
  fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-cube-carried-structure/editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Production editor functions; real exports; validation-only requests; no saved test edits.'},null,2));
  console.log(`${checks.length} Cube editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
