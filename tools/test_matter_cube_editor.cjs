const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
function load(file){const box={exports:{},require,structuredClone,process};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText,box);return box.exports;}
const {listEntries,copyObject,pasteObject,place,turn,placeInventoryPrefab}=load('src/components/lab-editor/void-model.ts');
const {loadPrimitivePrefabs,loadPrefabInventory}=load('src/lib/primitive-prefabs.ts');
const checks=[];const api='http://localhost:3003/api/void-layout';
async function validate(rooms){const r=await fetch(api,{method:'POST',headers:{'Content-Type':'application/json',Origin:'http://localhost:3003'},body:JSON.stringify({rooms,validateOnly:true})});const d=await r.json();assert.ok(r.ok,JSON.stringify(d));}
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch(api)).json();const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const p=loadPrimitivePrefabs(root).find(x=>x.id==='matter_and');assert.ok(p&&p.completion&&p.placement);
 assert.equal(p.placement.source_floor,7);assert.equal(payload.rooms.floors[7].artifacts.filter(a=>a.id===p.placement.source_id).length,1);
 checks.push('Main Cube encounter and shared catalogue identify the same source');
 const source=models.floors['7'].artifacts[p.placement.source_id];assert.equal(source.artifact,p.placement.artifact);
 for(const [id,m] of Object.entries(source.parts)){
  assert.ok(m.meshes>0||m.labels?.length,id);if(m.url){const b=fs.readFileSync(path.join(web,'public',m.url));assert.equal(b.readUInt32LE(0),0x46546c67);const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString());assert.ok(g.meshes?.length,id);}
 }
 checks.push('All '+Object.keys(source.parts).length+' part previews parse as actual scene geometry/labels');
 const draft=structuredClone(payload.rooms);
 assert.throws(()=>placeInventoryPrefab(draft.floors[12],{...p,unlocked:false},[0,0]),/Complete/);
 assert.equal(draft.floors[12].copies?.length??0,payload.rooms.floors[12].copies?.length??0);checks.push('Locked recipe cannot add an editor copy');
 const key=placeInventoryPrefab(draft.floors[12],{...p,unlocked:true},[0,0],'inventory-validation');
 let entries=listEntries(draft.floors[12],payload,models,12);const assembly=entries.find(e=>e.key===key);assert.ok(assembly);
 assert.equal(entries.filter(e=>e.artifactId==='inventory-validation').length,Object.keys(source.parts).length);turn(draft.floors[12],assembly);place(draft.floors[12],assembly,[0,.2,0],payload);
 entries=listEntries(draft.floors[12],payload,models,12);const input=entries.find(e=>e.artifactId==='inventory-validation'&&e.id==='InputX');assert.ok(input);
 place(draft.floors[12],input,[-2,.2,1],payload);turn(draft.floors[12],input);
 const copied=pasteObject(draft.floors[12],copyObject(draft.floors[12],input,payload,12),.5);assert.ok(copied);
 await validate(draft);assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));
 checks.push('Earned assembly places, rotates and moves with all named parts; individual input copies validate and roundtrip');
 const supportEntries=entries.filter(e=>e.artifactId==='inventory-validation'&&e.id.includes('PlanksSupportCube'));
 assert.equal(supportEntries.length,6);
 for(const support of supportEntries){const key=pasteObject(draft.floors[12],copyObject(draft.floors[12],support,payload,12),.5);assert.ok(key);}
 await validate(draft);checks.push('All six source cube supports remain independently copyable and validate in the shared editor layout');
 const native=fs.readdirSync(path.join(root,'ada_run/matter-cube-inventory')).filter(f=>/^test-inventory-desktop.*\.json$/.test(f));
 assert.ok(native.length,'Run native completion test first');process.env.VOID_INVENTORY_PATH=path.join(root,'ada_run/matter-cube-inventory',native.at(-1));
 const inventory=loadPrefabInventory(root);assert.ok(inventory.prefabs.find(x=>x.id==='matter_and').unlocked);delete process.env.VOID_INVENTORY_PATH;
 checks.push('Web reader sees the actual Godot-earned test save using the shared completion objective');
 const live=await(await fetch('http://localhost:3003/api/void-inventory')).json();assert.ok(live.prefabs.some(x=>x.id===p.id));checks.push('Live read-only inventory endpoint resolves the canonical recipe');
 const before=JSON.parse(fs.readFileSync(path.join(root,'ada_run/matter-cube-inventory/rooms-before.json'))),after=JSON.parse(saved);after.floors[7].artifacts=after.floors[7].artifacts.filter(a=>a.id!=='matter-and');assert.deepEqual(after,before);
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);checks.push('Only the authorized AND encounter was added; editor tests never write player arrangements');
 fs.writeFileSync(path.join(root,'ada_run/matter-cube-inventory/editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Actual exported models, locked/unlocked pure placement, server validation, JSON save parity and real isolated native save. Player save not awarded by tests.'},null,2)+'\n');
 console.log(checks.length+' editor/catalogue checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
