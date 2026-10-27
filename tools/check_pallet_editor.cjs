const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/pallet-assemblage');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function get(url){const r=await fetch('http://localhost:3003'+url);const d=await r.json();assert.ok(r.ok,JSON.stringify(d));return d;}
async function run(){
 const original=fs.readFileSync(path.join(root,'commons/void/rooms.json')),terms=JSON.parse(fs.readFileSync(path.join(root,'commons/modular/terms.json'))),receipt=JSON.parse(fs.readFileSync(path.join(out,'saved.json'))),id=receipt.id,checks=[];
 const payload=await get('/api/void-layout'),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),wb=await get('/api/prefab-workbench');
 const node=wb.nodes.find(n=>n.id===id),kit=wb.nodes.find(n=>n.id==='pallet_hand_kit');assert.equal(node.preview.length,20);assert.equal(kit.preview.length,20);assert.ok(node.placement);assert.ok(wb.edges.some(e=>e.source==='pallet_hand_kit'&&e.target===id));
 for(const p of node.preview){const b=fs.readFileSync(path.join(web,'public',p.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);const gltf=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(gltf.meshes.length);const actual=terms.terms[id].handmade.parts.find(x=>x.id===p.name);assert.deepEqual(p.position,actual.position);assert.deepEqual(p.rotation,actual.rotation);}
 checks.push('Twenty real native timber models and exact saved local poses in the shared workbench.');
 const draft=structuredClone(payload.rooms),floor=draft.floors[12];ctx.exports.placeWorkbenchPrefab(floor,node,[-2,5.9],'pallet-roundtrip-check');
 const entries=ctx.exports.listEntries(floor,payload,models,12).filter(e=>e.kind==='part'&&e.artifactId==='pallet-roundtrip-check');assert.equal(entries.length,20);
 for(const e of entries){ctx.exports.place(floor,e,[e.position[0]+.11,e.position[1]+.05,e.position[2]],payload);ctx.exports.turn(floor,e);}
 const copied=ctx.exports.copyObject(floor,entries[0],payload,12);ctx.exports.pasteObject(floor,copied,.2);
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,await response.text());
 assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));fs.writeFileSync(path.join(out,'editor-roundtrip.json'),JSON.stringify(draft,null,2));
 checks.push('Production live-editor placement, twenty independent move/rotate edits, part copy, serialization and server validation.');
 const inventory=await get('/api/void-inventory');assert.ok(inventory.prefabs.find(p=>p.id===id&&p.unlocked));
 const library=await get('/api/void-spawnlists?q='+encodeURIComponent('hand-built open frame'));assert.ok(library.items['kit:'+id]?.placement.config.term===id);
 require.extensions['.ts']=(module,file)=>module._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText,file);
 const graph=require(path.join(web,'src/lib/capacity-artifacts.ts')).loadArtifactGraph(root,web);
 assert.equal(graph.nodes.find(n=>n.id==='pallet_hand_kit').placements.filter(p=>p.site.kind==='tower').length,1);
 assert.equal(graph.nodes.find(n=>n.id===id).placements.length,0);
 assert.ok(graph.edges.some(e=>e.source==='pallet_hand_kit'&&e.target===id));
 checks.push('Main capacity tree uses the same recipe and distinguishes a saved asset from a placed instance.');
 const before=fs.readFileSync(path.join(root,'commons/modular/terms.json'));
 const invalid={...receipt.snapshot,key:'invalid-pallet-check',parts:receipt.snapshot.parts.slice(1)};
 const rejection=await fetch('http://localhost:3003/api/handmade-prefabs',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(invalid)});assert.equal(rejection.status,422);
 const retry=await fetch('http://localhost:3003/api/handmade-prefabs',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...receipt.snapshot,key:'pallet-assembly-demonstration-2026-10-24-v2'})});const repeated=await retry.json();assert.equal(repeated.id,id);assert.equal(repeated.reused,true);
 assert.equal(Buffer.compare(before,fs.readFileSync(path.join(root,'commons/modular/terms.json'))),0);assert.equal(Buffer.compare(original,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);
 const baseline=JSON.parse(fs.readFileSync(path.join(out,'before-rooms.json'))),current=JSON.parse(original);current.floors[12].artifacts=current.floors[12].artifacts.filter(a=>a.id!=='pallet-hand-workshop');assert.deepEqual(current,baseline);
 checks.push('Saved recipe is unlocked; incomplete saves reject, retry is idempotent, visitor layout remains unchanged.');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,prefab:id,checks},null,2)+'\n');console.log(checks.join('\n'));
}
run().catch(e=>{console.error(e);process.exitCode=1;});
