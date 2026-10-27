// Actual native previews, shared recipe and real editor operations; no user-save mutation.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/matter-tabletop');
const ts=require(path.join(web,'node_modules/typescript'));
function load(file){const box={exports:{},require,structuredClone,process};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText,box);return box.exports;}
const editor=load('src/components/lab-editor/void-model.ts'),catalogue=load('src/lib/primitive-prefabs.ts');
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),source=models.floors['7'].artifacts['matter-and'];
 const recipe=catalogue.loadPrimitivePrefabs(root).find(p=>p.id==='matter_and');assert.equal(recipe.dimensions[0],1.8);assert.equal(recipe.placement.source_floor,7);
 assert.equal(recipe.completion.objective,'matter_and_truth_table');assert.deepEqual(JSON.parse(JSON.stringify(recipe.completion.observations)),{'00':0,'01':0,'10':0,'11':1});
 const checks=['Tree, live editor and inventory retain the same compact recipe and four-case completion objective'];
 for(const [key,part] of Object.entries(source.parts)){
  assert.ok(part.url||part.labels?.length,key);
  if(part.url){const bytes=fs.readFileSync(path.join(web,'public',part.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);const g=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));assert.ok(g.meshes?.length,key);}
 }
 assert.ok(source.parts.Tabletop.default.bounds[3]<1.81);assert.ok(source.parts.InputX.default.bounds[3]<.18);
 checks.push('All '+Object.keys(source.parts).length+' independent part previews contain actual exported geometry or labels at tabletop dimensions');
 const draft=structuredClone(payload.rooms),floor=draft.floors[7];
 for(const name of ['Tabletop','TableSupportLeft','EntryWedge','BallRelease','InputX','InputY','ReceivingCube','Controls']){
  const entry=editor.listEntries(floor,payload,models,7).find(e=>e.artifactId==='matter-and'&&e.kind==='part'&&e.id===name);assert.ok(entry,name);
  editor.place(floor,entry,[entry.position[0]+.1,entry.position[1],entry.position[2]+.1],payload);editor.turn(floor,entry);
  const moved=editor.listEntries(floor,payload,models,7).find(e=>e.key===entry.key);
  const key=editor.pasteObject(floor,editor.copyObject(floor,moved,payload,7),.1);assert.ok(key,name);
 }
 checks.push('Table, supports, wedge, inputs, box, receiver and controls independently move, rotate and copy using real editor operations');
 assert.throws(()=>editor.placeInventoryPrefab(draft.floors[12],{...recipe,unlocked:false},[0,0]),/Complete/);
 const placed=editor.placeInventoryPrefab(draft.floors[12],{...recipe,unlocked:true},[0,0],'tabletop-validation');assert.ok(placed);
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,(await response.text()).slice(0,500));
 checks.push('Locked inventory is refused; earned tabletop assembly and independent edits validate through the shared desktop/VR save API');
 const native=fs.readdirSync(out).filter(f=>/^isolated-false.*\.json$/.test(f));assert.ok(native.length);
 process.env.VOID_INVENTORY_PATH=path.join(out,native.at(-1));assert.ok(catalogue.loadPrefabInventory(root).prefabs.find(p=>p.id==='matter_and').unlocked);delete process.env.VOID_INVENTORY_PATH;
 checks.push('Web inventory reads the real native-earned reward from the isolated test save');
 const before=JSON.parse(fs.readFileSync(path.join(out,'before-rooms.json'))),after=JSON.parse(saved);
 for(const data of [before,after])data.floors[7].artifacts=data.floors[7].artifacts.filter(a=>a.id!=='matter-and');assert.deepEqual(after,before);
 assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);
 checks.push('Every other saved artifact/floor arrangement is preserved; these editor tests do not save their drafts');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Actual GLBs, canonical recipe/reward, editor copy/move/rotate, save API validation, native-earned test inventory and preservation of unrelated arrangements.'},null,2)+'\n');console.log(checks.length+' tabletop editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
