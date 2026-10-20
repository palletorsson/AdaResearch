// Exercise real editor operations on clones; never save the test arrangement.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const out=path.join(root,'doc/book/iterations/2026-10-19-lines-museum-return');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
  const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const checks=[],floor=payload.rooms.floors[3],entries=listEntries(floor,payload,models,3);
  const assembly=models.floors['3'].artifacts.assembly;
  assert.ok(!Object.keys(assembly.parts).some(name=>name.includes('ArtifactReaction')),'Runtime reactions must not become editable props');
  for(const direction of ['Horizontal','Vertical'])for(let i=0;i<3;i++){
    const name=`DepthGrid${direction}${i}`,part=assembly.parts[name];
    assert.ok(part,`Export missing ${name}`);
    assert.equal(fs.readFileSync(path.join(web,'public',part.url)).readUInt32LE(0),0x46546c67);
    assert.ok(entries.some(e=>e.kind==='part'&&e.id===name),`Editor missing ${name}`);
  }
  checks.push({name:'All six grid lines have actual GLBs and independently selectable entries',passed:true});
  const entry=entries.find(e=>e.kind==='part'&&e.id==='DepthGridHorizontal1');
  const rooms=structuredClone(payload.rooms),destination=rooms.floors[3];
  const key=pasteObject(destination,copyObject(floor,entry,payload,3),3);
  let copy=listEntries(destination,payload,models,3).find(e=>e.key===key);
  assert.equal(copy.model.url,entry.model.url);
  place(destination,copy,[18,1.5,3],payload);turn(destination,copy);
  copy=listEntries(destination,payload,models,3).find(e=>e.key===key);
  assert.equal(copy.position[0],18);assert.equal(copy.position[2],3);
  assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  const receipt=await(await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})})).json();
  assert.ok(receipt.valid,JSON.stringify(receipt));
  checks.push({name:'A grid line can be copied, moved, turned and validated through the production editor',passed:true});
  const history=JSON.parse(fs.readFileSync(path.join(out,'layout-change.json'),'utf8'));
  assert.deepEqual(payload.rooms,history.before);
  checks.push({name:'All curated positions, settings and other floors preserved',passed:true});
  for(const [file,hash] of Object.entries(history.preserved_text_sha256)){
    assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'commons/maps/Point_Lines',file))).digest('hex'),hash);
  }
  checks.push({name:'Original museum map, final text and tutorial unchanged',passed:true});
  const project=JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'),'utf8'));
  const desktop=JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8'));
  assert.deepEqual(payload.rooms,project);assert.deepEqual(project,desktop);
  checks.push({name:'Editor, desktop, VR and Desktop backup share the same saved layout',passed:true});
  fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Production editor operations and exported models. Test copies validated only, never saved.'},null,2)+'\n');
  console.log(`${checks.length} editor checks passed`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
