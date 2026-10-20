// Exercise the actual editor placement/copy functions without saving a test layout.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const source=fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8');
const context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
const coordinates=process.argv.includes('--coordinates'),lines=process.argv.includes('--lines'),trace=process.argv.includes('--trace'),triangle=process.argv.includes('--triangle'),polyhedra=process.argv.includes('--polyhedra'),index=polyhedra?6:triangle?5:trace?4:lines?3:coordinates?2:1;
async function main(){
  const payload=await (await fetch('http://localhost:3003/api/void-layout')).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const before=JSON.stringify(payload.rooms),checks=[];
  const rooms=structuredClone(payload.rooms),floor=rooms.floors[index];
  // The complete tower no longer has a spare floor. Clear only our in-memory
  // destination; this fixture is submitted with validateOnly and never saved.
  const destinationIndex=index===0?1:0;
  const destination=rooms.floors[destinationIndex];
  Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
  const prefix=polyhedra?'polyhedra':triangle?'triangle':trace?'trace':lines?'lines':coordinates?'coordinates':'point';
  const expected={'work_light':prefix+'-work-light','scaffold_tarp':prefix+'-scaffold','unfinished_wall':prefix+'-unfinished-wall'};
  let i=0;
  for(const [kind,id] of Object.entries(expected)){
    const original=listEntries(floor,payload,models,index).find(e=>e.id===id);
    assert.ok(original?.model?.url);
    const clipboard=copyObject(floor,original,payload,index);
    const key=pasteObject(destination,clipboard,.5);
    let copy=listEntries(destination,payload,models,destinationIndex).find(e=>e.key===key);
    assert.equal(copy.model.url,original.model.url);
    place(destination,copy,[-4+i*4,0,5],payload);
    turn(destination,copy);
    copy=listEntries(destination,payload,models,destinationIndex).find(e=>e.key===key);
    assert.equal(copy.rotation[1],(original.rotation[1]+90)%360);
    assert.equal(copy.position[0],-4+i*4);
    const buffer=fs.readFileSync(path.join(web,'public',original.model.url));
    assert.equal(buffer.readUInt32LE(0),0x46546c67);
    const gltf=JSON.parse(buffer.subarray(20,20+buffer.readUInt32LE(12)).toString());
    assert.ok(gltf.meshes.length>0);
    if(kind==='scaffold_tarp')assert.ok(gltf.materials.some(m=>m.doubleSided),'Tarp must be visible from either side in the editor');
    checks.push({name:`${kind}: real GLB, independent cross-floor copy, movement and rotation`,passed:true});
    i++;
  }
  assert.equal(JSON.stringify(payload.rooms),before,'Source layout must remain unchanged');
  const validation=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const result=await validation.json();assert.ok(validation.ok&&result.valid,JSON.stringify(result));
  checks.push({name:'The save endpoint accepts all three copied props without changing the source layout',passed:true});
  if(polyhedra){
    for(const name of ['AlignTetrahedron','AlignWedge','CornerTetrahedron','OpenTrihedron','ClosedTetrahedron','EditablePyramid','VisibleAndPhysicalBoundary','UnfoldingMonitor','StandingWedge0','WedgePlatform','WedgeColumn','WedgeMouseModel']){
      const isolated=structuredClone(payload.rooms),target=isolated.floors[destinationIndex];
      const original=listEntries(floor,payload,models,index).find(e=>e.kind==='part'&&e.id===name);
      assert.ok(original?.model?.url,`${name} has its real model`);
      const key=pasteObject(target,copyObject(floor,original,payload,index),0);
      let copy=listEntries(target,payload,models,destinationIndex).find(e=>e.key===key);
      place(target,copy,[0,original.position[1],4.5],payload);turn(target,copy);
      copy=listEntries(target,payload,models,destinationIndex).find(e=>e.key===key);
      assert.equal(copy.model.url,original.model.url);
      assert.equal(copy.position[0],0);assert.equal(copy.position[2],4.5);
      assert.equal(copy.rotation[1],(original.rotation[1]+90)%360);
      assert.equal(target.copies.length,1);assert.equal(target.copies[0].config.only_parts[0],name);
      assert.equal(JSON.stringify(payload.rooms),before);
      const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:isolated,validateOnly:true})});
      const receipt=await response.json();assert.ok(response.ok&&receipt.valid,`${name}: ${JSON.stringify(receipt)}`);
      checks.push({name:`${name}: independent part copy, real preview, movement, rotation and accepted native layout`,passed:true});
    }
  }
  const out=path.join(root,'doc/book/iterations',polyhedra?'2026-10-19-void-polyhedra':triangle?'2026-10-18-triangle-worksite':trace?'2026-10-18-trace-worksite':lines?'2026-10-18-lines-worksite':coordinates?'2026-10-18-coordinates-worksite':'2026-10-18-point-one-worksite','editor-checks.json');
  fs.writeFileSync(out,JSON.stringify({passed:true,checks},null,2));
  console.log(`${checks.length} editor contracts passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
