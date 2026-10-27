const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/barrier-play-2026-10-27');
const ts=require(path.join(web,'node_modules/typescript'));
require.extensions['.ts']=(module,file)=>module._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,esModuleInterop:true,target:ts.ScriptTarget.ES2022}}).outputText,file);
const model=require(path.join(web,'src/components/lab-editor/void-model.ts'));
const {saveLayout,layoutRevision,LayoutConflict}=require(path.join(web,'src/lib/void-layout-store.ts'));
async function main(){
 const url='http://localhost:3003/api/void-layout',p=await(await fetch(url,{signal:AbortSignal.timeout(60000)})).json(),checks=[];
 assert(p.rooms,JSON.stringify(p));
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const original=JSON.stringify(p.rooms),draft=structuredClone(p.rooms),floor=draft.floors[15],entries=model.listEntries(floor,p,models,15);
 for(const [id,names] of [['barrier-packed',['TemporaryTable','Copy01','Copy10']],['sun-feather',['Controls','Copy01','Copy10']],['barrier-scale-line',['ScaleTable','LowerSupport01','GrowingBarrier01','GrowingBarrier09']]]){
  for(const name of names){
   const entry=entries.find(e=>e.kind==='part'&&e.id===name&&e.artifactId===id);assert(entry,id+'/'+name+' editable');assert(entry.model.url,id+'/'+name+' geometry');
   const b=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString().trim());assert(g.meshes.length>0);
  }
 }
 checks.push('Packed row, circular feather and growing line use real native models and independent parts');
 const part=entries.find(e=>e.kind==='part'&&e.id==='GrowingBarrier09'&&e.artifactId==='barrier-scale-line');
 model.place(floor,part,[part.position[0]+.25,part.position[1],part.position[2]+.25],p);model.turn(floor,part);
 const clipboard=model.copyObject(floor,part,p,15);model.pasteObject(floor,clipboard,.5);
 const copy=floor.copies.at(-1);assert.deepEqual(copy.config.only_parts,['GrowingBarrier09']);assert.equal(copy.config.editor_source.floor,15);assert.equal(copy.config.editor_source.id,'barrier-scale-line');
 checks.push('The oversized barrier can be moved, rotated and copied independently');
 const response=await fetch(url,{method:'POST',signal:AbortSignal.timeout(60000),headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:p.revision,validateOnly:true})});const report=await response.json();assert.equal(response.status,200,JSON.stringify(report));assert(report.valid);
 checks.push('Edited native part poses pass real lab API validation');
 const fixture=fs.mkdtempSync(path.join(out,'editor-fixture-')),dir=path.join(fixture,'commons/void');fs.mkdirSync(dir,{recursive:true});const file=path.join(dir,'rooms.json'),raw=JSON.stringify(p.rooms)+'\n';fs.writeFileSync(file,raw);
 saveLayout(fixture,draft,layoutRevision(raw),path.join(fixture,'Desktop'));assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),draft);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(fixture,'Desktop/rooms.json'),'utf8')),draft);assert.throws(()=>saveLayout(fixture,p.rooms,'stale',path.join(fixture,'Desktop')),LayoutConflict);
 checks.push('Layout save/reload, Desktop mirror and stale-save protection pass in a disposable fixture');
 const workbench=await(await fetch('http://localhost:3003/api/prefab-workbench',{signal:AbortSignal.timeout(60000)})).json();
 const node=workbench.nodes.find(n=>n.id==='barrier_scale_line');assert(node,'Shared workbench node');assert(node.placement,'Reusable placement');assert(workbench.edges.some(e=>e.source==='do_not_cross_barrier'&&e.target==='barrier_scale_line'));
 checks.push('Shared workbench and tree link the scale study to the original blue barrier');
 const latest=await(await fetch(url,{signal:AbortSignal.timeout(60000)})).json();assert.equal(JSON.stringify(latest.rooms),original);
 checks.push('Actual user arrangements were untouched by the editor tests');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,fixture},null,2));console.log(checks.join('\n'));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
