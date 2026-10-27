const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const cache=new Map();function load(file){file=path.resolve(file);if(cache.has(file))return cache.get(file);const box={exports:{},structuredClone,process,require(name){return name.startsWith('.')?load(path.resolve(path.dirname(file),name+'.ts')):require(name);}};cache.set(file,box.exports);vm.runInNewContext(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText,box);return box.exports;}
const store=load(path.join(web,'src/lib/prefab-workbench-store.ts')),model=load(path.join(web,'src/components/lab-editor/void-model.ts'));
const out=path.join(root,'ada_run/prefab-workbench');fs.mkdirSync(out,{recursive:true});const checks=[];
async function run(){
 const fixture=fs.mkdtempSync(path.join(out,'store-fixture-'));const dir=path.join(fixture,'commons/void');fs.mkdirSync(dir,{recursive:true});
 for(const name of ['capacity-artifacts.json','primitive-prefabs.json','catalog.json','rooms.json'])fs.copyFileSync(path.join(root,'commons/void',name),path.join(dir,name));
 for(const relative of ['commons/modular/terms.json','commons/maps/sequences/logic.json',...['Logic_Event','Logic_AND','Logic_Alternatives','Logic_Assemblage'].map(id=>'commons/maps/'+id+'/map_data.json')]){
  const target=path.join(fixture,relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(root,relative),target);
 }
 const beforeNodes=JSON.parse(fs.readFileSync(path.join(dir,'capacity-artifacts.json'))).nodes;
 let data=store.loadWorkbench(fixture,web);assert.equal(data.maps.length,22);for(const id of ['matter_and','melencolia_court','sine_yoke'])assert.ok(data.nodes.some(n=>n.id===id&&n.placement),id);assert.deepEqual(Array.from(data.maps.filter(m=>m.id.startsWith('Logic_')),m=>m.floor),[20,21,22,23]);checks.push('The existing construction slice now includes the four canonical Logic maps in the shared catalogue');
 const court=data.nodes.find(n=>n.id==='melencolia_court');assert.equal(court.preview.length,60);assert.deepEqual(Array.from(new Set(court.preview.map(p=>p.stage))),['Foundation','Deck','Rim','Access']);assert.equal(court.preview.filter(p=>p.ingredient==='construction_cube').length,25);assert.equal(court.preview.filter(p=>p.ingredient==='timber_panel_1x1').length,25);assert.equal(court.preview.filter(p=>p.ingredient==='wp').length,2);checks.push('Melencolia build-up has 25 original cube meshes, 25 sheets, eight rim planks and two access wedges');
 const changed=structuredClone(data.edges),edge=changed.find(e=>e.source==='wp'&&e.target==='matter_and');edge.label='A wedge introduces a slope into the AND track.';
 const saved=store.saveWorkbenchRelations(fixture,web,data.revision,changed);assert.ok(saved.saved);
 assert.equal(store.loadWorkbench(fixture,web).edges.find(e=>e.source==='wp'&&e.target==='matter_and').label,edge.label);
 assert.deepEqual(JSON.parse(fs.readFileSync(path.join(dir,'capacity-artifacts.json'))).nodes,beforeNodes);checks.push('Relationship edit persists to the main graph format while preserving all object definitions');
 assert.throws(()=>store.saveWorkbenchRelations(fixture,web,data.revision,changed),/changed elsewhere/);checks.push('Concurrent revision conflict refuses to overwrite newer tree edits');
 data=store.loadWorkbench(fixture,web);
 const graphBefore=fs.readFileSync(path.join(dir,'capacity-artifacts.json'));
 for(const bad of [[...data.edges,{source:'no-such-id',target:'matter_and',kind:'combine',label:'bad'}],[...data.edges,{source:'matter_and',target:'matter_and',kind:'associate',label:'bad'}],[...data.edges,data.edges[0]],[...data.edges,{source:'matter_and',target:'construction_cube',kind:'combine',label:'A circular build recipe'}]])assert.throws(()=>store.saveWorkbenchRelations(fixture,web,data.revision,bad));
 assert.equal(Buffer.compare(fs.readFileSync(path.join(dir,'capacity-artifacts.json')),graphBefore),0);checks.push('Unknown objects, self-links, duplicate relations and circular construction recipes leave saved data untouched');
 const noWedge=data.edges.filter(e=>!(e.source==='wp'&&e.target==='matter_and'&&e.kind==='combine'));
 store.saveWorkbenchRelations(fixture,web,data.revision,noWedge);
 const prefabs=JSON.parse(fs.readFileSync(path.join(dir,'primitive-prefabs.json'))),and=prefabs.prefabs.find(p=>p.id==='matter_and');assert.ok(!and.recipe.includes('wp'));assert.equal(and.completion.objective,'matter_and_truth_table');assert.equal(and.scene,'res://commons/artifacts/matter_gates/matter_and.tscn');checks.push('Changed built-from relations update catalogue recipe metadata; source scenes and unlock objectives stay intact');
 assert.ok(fs.readdirSync(path.join(fixture,'ada_run/prefab-workbench/history')).length>=4);checks.push('Each save retains both graph and catalogue backups');
 const actualRooms=fs.readFileSync(path.join(root,'commons/void/rooms.json')),actualGraph=fs.readFileSync(path.join(root,'commons/void/capacity-artifacts.json'));
 const response=await fetch('http://localhost:3003/api/prefab-workbench'),live=await response.json();assert.ok(response.ok);
 let r=await fetch('http://localhost:3003/api/prefab-workbench',{method:'POST',headers:{'Content-Type':'application/json',Origin:'http://localhost:3003'},body:JSON.stringify({revision:'stale',edges:live.edges})});assert.equal(r.status,409);
 r=await fetch('http://localhost:3003/api/prefab-workbench',{method:'POST',headers:{'Content-Type':'application/json',Origin:'https://unrelated.invalid'},body:JSON.stringify({revision:live.revision,edges:live.edges})});assert.equal(r.status,403);checks.push('Live API rejects stale saves and cross-origin mutation');
 let serverValidated=0;
 async function validateDraft(draft){const validation=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json',Origin:'http://localhost:3003'},body:JSON.stringify({rooms:draft,validateOnly:true})}),report=await validation.json();assert.ok(validation.ok,JSON.stringify(report));}
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),draft=structuredClone(payload.rooms);
 for(const [i,piece] of live.nodes.filter(n=>n.placement).entries()){
  const floor=i%5+8; // Separate validation-only drafts avoid per-floor authoring limits.
  draft.floors[floor]=structuredClone(payload.rooms.floors[floor]);
  assert.ok(fs.existsSync(path.join(root,piece.prefab.scene.replace('res://',''))),piece.id);
  for(const part of piece.preview)if(part.model.url){const bytes=fs.readFileSync(path.join(web,'public',part.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());assert.ok(gltf.meshes?.length);}
  const key=model.placeWorkbenchPrefab(draft.floors[floor],piece,[0,0],'test-workbench-'+piece.id);const entries=model.listEntries(draft.floors[floor],payload,models,floor),entry=entries.find(e=>e.key===key);assert.ok(entry,piece.id);if(piece.placement.kind==='construction'){const keys=entries.filter(e=>e.kind==='construction'&&e.id.startsWith('test-workbench-'+piece.id+'-')).map(e=>e.key);model.moveSelection(draft.floors[floor],entries,keys,[.25,0,.25],payload);}else model.place(draft.floors[floor],entry,[0,entry.position[1],1],payload);model.turn(draft.floors[floor],entry);
  if(piece.placement.kind==='construction'){const added=draft.floors[floor].construction.filter(c=>c.id.startsWith('test-workbench-'+piece.id+'-'));assert.equal(added.length,piece.placement.items.length);assert.equal(new Set(added.map(c=>c.id)).size,added.length);assert.notEqual(added[0],piece.placement.items[0]);}
  if(i%5===4){await validateDraft(draft);serverValidated+=5;}
 }
 await validateDraft(draft);serverValidated+=live.nodes.filter(n=>n.placement).length%5;assert.equal(serverValidated,live.nodes.filter(n=>n.placement).length);
 assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));checks.push('All placeable pieces parse real GLBs and support editor place/move/turn, server validation and JSON save parity');
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),actualRooms),0);assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/capacity-artifacts.json')),actualGraph),0);checks.push('Tests use isolated graph fixtures and validation-only layout drafts; visitor arrangements are unchanged');
 fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({passed:true,checks,scope:'Store save/reload/backup/conflict/cycle validation in isolated copies; actual source model parsing and editor/server validation. No game interaction changes or native simulation claimed.'},null,2)+'\n');console.log(checks.length+' prefab workbench checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
