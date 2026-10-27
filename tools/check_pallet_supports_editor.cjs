const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/pallet-supports'),ts=require(path.join(web,'node_modules/typescript'));
const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function get(url){const r=await fetch('http://localhost:3003'+url),d=await r.json();assert.ok(r.ok,JSON.stringify(d));return d;}
async function run(){
 const before=fs.readFileSync(path.join(root,'commons/void/rooms.json')),payload=await get('/api/void-layout'),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),saved=JSON.parse(fs.readFileSync(path.join(out,'saved.json'))),wb=await get('/api/prefab-workbench');
 const p=wb.nodes.find(n=>n.id===saved.id);assert.equal(p.preview.length,45);assert.equal(p.placement.config.study,'pallet_and');assert.equal(p.placement.config.track_height,.6);assert.equal(p.placement.config.board_count,2);assert.equal(p.placement.config.logic_grammar,'supports');assert.ok(p.preview.some(x=>x.name==='TrueCone'));
 for(const part of p.preview){const b=fs.readFileSync(path.join(web,'public',part.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length);}
 const draft=structuredClone(payload.rooms),floor=draft.floors[12];ctx.exports.placeWorkbenchPrefab(floor,p,[-1,5.9],'temporary-pallet-and-check');
 const entries=ctx.exports.listEntries(floor,payload,models,12).filter(e=>e.artifactId==='temporary-pallet-and-check');assert.equal(entries.length,45);
 for(const name of ['bearer_1','block_1_1','Board','Board2','CinderBlock8','TrueCone','BaseCrate8','LogicControls','Runway1']){
  const e=entries.find(x=>x.id===name);assert.ok(e);ctx.exports.place(floor,e,[e.position[0],e.position[1]+.01,e.position[2]],payload);ctx.exports.turn(floor,e);
 }
 const r=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(r.ok,await r.text());assert.equal(Buffer.compare(before,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);
 const baseline=JSON.parse(fs.readFileSync(path.join(root,'ada_run/pallet-supports/before-rooms.json')));baseline.floors[12].artifacts.find(a=>a.id==='pallet-hand-workshop').config.board_count=2;baseline.floors[12].artifacts.find(a=>a.id==='pallet-hand-workshop').config.logic_grammar='supports';assert.deepEqual(JSON.parse(before),baseline);
 const inventory=await get('/api/void-inventory');assert.ok(inventory.prefabs.find(p=>p.id===saved.id&&p.unlocked));
 const library=await get('/api/void-spawnlists?q='+encodeURIComponent('temporary AND'));assert.ok(library.items['kit:'+saved.id]);
 const term=JSON.parse(fs.readFileSync(path.join(root,'commons/modular/terms.json'))).terms[saved.id];assert.equal(term.handmade.logic_grammar,'supports');assert.equal(term.build.parts.length,45);assert.ok(Math.abs(term.handmade.parts.find(p=>p.id==='block_1_1').position[0]+.46)<1e-6);assert.ok(Math.abs(term.handmade.parts.find(p=>p.id==='block_3_1').position[0]-.46)<1e-6);assert.equal(Object.keys(term.handmade.environment).length,25);
 const report={passed:true,prefab:saved.id,parts:45,checks:['Two standard sheets, extra runway boards, crate bases, cinder blocks, ball and TRUE cone have real exported meshes.','All45 groups place through the shared workbench; both sheets, runway boards, controls and cone edits validate and serialize.','Saved recipe carries the two-board profile into the shared catalogue and live-editor inventory/library.','Only the active pallet support-grammar configuration changed in the tower; all other saved records remain intact.']};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report.checks.join('\n'));
}
run().catch(e=>{console.error(e);process.exitCode=1;});
