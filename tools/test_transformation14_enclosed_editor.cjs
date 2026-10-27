const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/transformation14-enclosed-route-2026-10-26');
const ts=require(path.join(web,'node_modules/typescript'));
require.extensions['.ts']=(module,file)=>module._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,esModuleInterop:true,target:ts.ScriptTarget.ES2022}}).outputText,file);
const model=require(path.join(web,'src/components/lab-editor/void-model.ts'));
const {saveLayout,layoutRevision,LayoutConflict}=require(path.join(web,'src/lib/void-layout-store.ts'));
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json(),checks=[];
 const before=JSON.stringify(payload.rooms.floors[14]),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const draft=structuredClone(payload.rooms),floor=draft.floors[14],entries=model.listEntries(floor,payload,models,14);
 const walls=entries.filter(e=>e.kind==='wall'&&e.id.startsWith('trans14-route-'));
 assert.equal(walls.length,8);checks.push('All 8 wall segments appear as independent editor objects');
 const entry=walls.find(e=>e.id==='trans14-route-A-west');assert(entry);
 model.place(floor,entry,[entry.position[0]+.25,entry.position[1],entry.position[2]],payload);
 model.turn(floor,entry);const clipboard=model.copyObject(floor,entry,payload,14);model.pasteObject(floor,clipboard,.5);
 assert.equal(floor.walls.length,9);checks.push('Real editor move, rotate and copy work with the final low walls');
 fs.writeFileSync(path.join(out,'editor-draft.json'),JSON.stringify(draft));
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});const validated=await response.json();assert.equal(response.status,200,JSON.stringify(validated));assert(validated.valid);checks.push('Edited draft passes real save API validation without changing the live arrangement');
 const fixture=fs.mkdtempSync(path.join(out,'editor-fixture-')),dir=path.join(fixture,'commons/void');fs.mkdirSync(dir,{recursive:true});
 const file=path.join(dir,'rooms.json'),original=JSON.stringify(payload.rooms)+'\n';fs.writeFileSync(file,original);
 const result=saveLayout(fixture,draft,layoutRevision(original),path.join(fixture,'Desktop'));
 assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),draft);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(fixture,'Desktop/rooms.json'),'utf8')),draft);
 assert.throws(()=>saveLayout(fixture,payload.rooms,'stale',path.join(fixture,'Desktop')),LayoutConflict);checks.push('Exact saved transforms survive reload and Desktop mirror; stale writes are rejected (disposable fixture)');
 const latest=await(await fetch(endpoint)).json();assert.equal(JSON.stringify(latest.rooms.floors[14]),before);checks.push('Live floor 14 stayed unchanged during editor tests');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,fixture,revision:result.revision},null,2));console.log(checks.join('\n'));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
