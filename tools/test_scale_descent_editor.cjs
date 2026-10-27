const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/transformation14-scale-descent-2026-10-26');
const ts=require(path.join(web,'node_modules/typescript'));
require.extensions['.ts']=(module,file)=>module._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,esModuleInterop:true,target:ts.ScriptTarget.ES2022}}).outputText,file);
const model=require(path.join(web,'src/components/lab-editor/void-model.ts'));
const {saveLayout,layoutRevision,LayoutConflict}=require(path.join(web,'src/lib/void-layout-store.ts'));
async function main(){
 const url='http://localhost:3003/api/void-layout',p=await(await fetch(url,{signal:AbortSignal.timeout(20000)})).json(),checks=[];
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const original=JSON.stringify(p.rooms.floors[14]),draft=structuredClone(p.rooms),floor=draft.floors[14],entries=model.listEntries(floor,p,models,14);
 for(const name of ['ShaftFieldA','ShaftFieldB','GrowingCube']){
  const entry=entries.find(e=>e.kind==='part'&&e.id===name&&e.artifactId==='sequence');assert(entry,name+' editable');assert(entry.model.url,name+' native geometry');
  const b=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString().trim());assert(g.meshes.length>0);
 }
 checks.push('Both fields and the growing cube use real native geometry and independent editor entries');
 const field=entries.find(e=>e.kind==='part'&&e.id==='ShaftFieldA'&&e.artifactId==='sequence');
 model.place(floor,field,[field.position[0]+.25,field.position[1],field.position[2]+.25],p);model.turn(floor,field);
 const clipboard=model.copyObject(floor,field,p,14);model.pasteObject(floor,clipboard,.5);
 const copy=floor.copies.at(-1);assert.deepEqual(copy.config.only_parts,['ShaftFieldA']);assert.equal(copy.config.editor_source.floor,14);assert.equal(copy.config.editor_source.id,'sequence');
 checks.push('Move, rotate and copy isolate just the selected field through the existing prefab contract');
 const response=await fetch(url,{method:'POST',signal:AbortSignal.timeout(20000),headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:p.revision,validateOnly:true})});const report=await response.json();assert.equal(response.status,200,JSON.stringify(report));assert(report.valid);checks.push('Native-derived field part transforms and copies pass real API validation');
 const fixture=fs.mkdtempSync(path.join(out,'editor-fixture-')),dir=path.join(fixture,'commons/void');fs.mkdirSync(dir,{recursive:true});const file=path.join(dir,'rooms.json'),raw=JSON.stringify(p.rooms)+'\n';fs.writeFileSync(file,raw);
 saveLayout(fixture,draft,layoutRevision(raw),path.join(fixture,'Desktop'));assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),draft);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(fixture,'Desktop/rooms.json'),'utf8')),draft);assert.throws(()=>saveLayout(fixture,p.rooms,'stale',path.join(fixture,'Desktop')),LayoutConflict);checks.push('Saved poses survive reload and Desktop mirror; stale saves rejected in disposable fixture');
 const latest=await(await fetch(url,{signal:AbortSignal.timeout(20000)})).json();assert.equal(JSON.stringify(latest.rooms.floors[14]),original);checks.push('Actual floor arrangement stayed untouched during tests');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,fixture},null,2));console.log(checks.join('\n'));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
