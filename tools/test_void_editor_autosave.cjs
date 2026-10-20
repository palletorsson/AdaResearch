// Exercise the actual placement model, save queue, filesystem store and API validator.
const fs=require('node:fs'),path=require('node:path'),os=require('node:os'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
function moduleAt(file){const ctx={exports:{},require,structuredClone,setTimeout,clearTimeout,process};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020,esModuleInterop:true}}).outputText,ctx);return ctx.exports;}
const {listEntries,selectionRoots,moveSelection}=moduleAt('src/components/lab-editor/void-model.ts');
const {LayoutSaveQueue}=moduleAt('src/components/lab-editor/void-save.ts');
const {saveLayout,layoutRevision,LayoutConflict}=moduleAt('src/lib/void-layout-store.ts');
const checks=[];function check(name,fn){fn();checks.push({name,passed:true});}
async function main(){
  const payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const floor=structuredClone(payload.rooms.floors[3]),before=listEntries(floor,payload,models,3);
  const a=before.find(e=>e.kind==='part'&&e.id==='FloorPlanTable'),b=before.find(e=>e.kind==='part'&&e.id==='FullSizeRuler');
  check('Group translation keeps offsets and other objects unchanged',()=>{
    moveSelection(floor,before,[a.key,b.key],[.5,.2,-.75],payload);
    const after=listEntries(floor,payload,models,3);
    for(const old of before){const next=after.find(e=>e.key===old.key);const delta=[a.key,b.key].includes(old.key)?[.5,.2,-.75]:[0,0,0];old.position.forEach((v,i)=>assert.ok(Math.abs(next.position[i]-v-delta[i])<1e-8));}
  });
  check('Parent plus child moves once; another work area stays still',()=>{
    const original=structuredClone(payload.rooms.floors[3]),entries=listEntries(original,payload,models,3),parent=entries.find(e=>e.key==='a:setting_out');
    const keys=[parent.key,a.key];assert.equal(selectionRoots(entries,keys).length,1);
    moveSelection(original,entries,keys,[1,0,0],payload);
    for(const e of listEntries(original,payload,models,3)){const old=entries.find(o=>o.key===e.key);assert.ok(Math.abs(e.position[0]-old.position[0]-(e.key===parent.key||e.artifactId===parent.id?1:0))<1e-8);}
  });
  let resolveFirst;const calls=[];const q=new LayoutSaveQueue('A','r0',async(doc,rev)=>{calls.push([doc,rev]);if(calls.length===1)await new Promise(r=>resolveFirst=r);return {revision:'r'+calls.length,warnings:[]};},()=>{},10000);
  const saving=q.flush('B');q.schedule('C');resolveFirst();await saving;
  check('A newer edit is saved after the in-flight edit with the new revision',()=>{assert.equal(JSON.stringify(calls),JSON.stringify([['B','r0'],['C','r1']]));assert.equal(q.state.saved,'C');});q.dispose();
  let release;const undoCalls=[];const undoQ=new LayoutSaveQueue('A','0',async(doc)=>{undoCalls.push(doc);if(undoCalls.length===1)await new Promise(r=>release=r);return {revision:String(undoCalls.length)};},()=>{},10000);
  const pending=undoQ.flush('B');undoQ.schedule('A');release();await pending;
  check('Undo during a save restores the server too',()=>assert.equal(JSON.stringify(undoCalls),'["B","A"]'));undoQ.dispose();
  let attempts=0;const fail=new LayoutSaveQueue('A','0',async()=>{attempts++;throw Error('Conflict');},()=>{},10000);await fail.flush('B');fail.schedule('C');
  check('Failed save is visible and does not silently retry or mark saved',()=>{assert.equal(fail.state.phase,'error');assert.equal(fail.state.saved,'A');assert.equal(attempts,1);});fail.dispose();
  const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'void-save-test-'));const shared=path.join(tmp,'commons/void/rooms.json');fs.mkdirSync(path.dirname(shared),{recursive:true});fs.writeFileSync(shared,'{"old":true}\n');
  const desktop=path.join(tmp,'Desktop/Ada Void');const receipt=saveLayout(tmp,{new:true},layoutRevision(fs.readFileSync(shared,'utf8')),desktop);
  check('Atomic store writes the shared layout and Desktop backup, retaining previous version',()=>{assert.equal(fs.readFileSync(shared,'utf8'),fs.readFileSync(path.join(desktop,'rooms.json'),'utf8'));assert.ok(receipt.saved);const history=path.join(tmp,'ada_run/void-editor-backups');assert.equal(fs.readFileSync(path.join(history,fs.readdirSync(history)[0]),'utf8'),'{"old":true}\n');});
  check('Stale revision cannot overwrite another editor',()=>assert.throws(()=>saveLayout(tmp,{wrong:true},'stale',desktop),LayoutConflict));
  const blocked=path.join(tmp,'not-a-directory');fs.writeFileSync(blocked,'x');const partial=saveLayout(tmp,{new:2},receipt.revision,blocked);
  check('Desktop backup failure does not misreport a successful project save',()=>{assert.equal(partial.warnings.length,1);assert.equal(JSON.parse(fs.readFileSync(shared,'utf8')).new,2);});
  const valid=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:payload.rooms,validateOnly:true})});const validation=await valid.json();
  check('Existing spatial warnings do not prevent saving valid data',()=>{assert.equal(valid.status,200);assert.ok(validation.valid);assert.ok(validation.warnings.length>=1);});
  const malformed=structuredClone(payload.rooms);malformed.floors[3].artifacts[0].artifact='missing-scene';
  const invalid=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:malformed,validateOnly:true})});
  check('Missing artifact resources still block save',()=>assert.equal(invalid.status,422));
  const after=await(await fetch('http://localhost:3003/api/void-layout')).json();
  check('Tests never mutate the user layout',()=>assert.equal(after.revision,payload.revision));
  const config=ts.readConfigFile(path.join(web,'tsconfig.json'),ts.sys.readFile).config;
  const parsed=ts.parseJsonConfigFileContent(config,ts.sys,web);
  const files=['src/components/lab-editor/VoidEditor.tsx','src/components/lab-editor/void-scene.ts','src/components/lab-editor/void-model.ts','src/components/lab-editor/void-save.ts','src/lib/void-layout-store.ts','src/app/api/void-layout/route.ts','next-env.d.ts'].map(f=>path.join(web,f));
  const program=ts.createProgram(files,{...parsed.options,incremental:false});
  const diagnostics=ts.getPreEmitDiagnostics(program);if(diagnostics.length)throw Error(ts.formatDiagnosticsWithColorAndContext(diagnostics,{getCanonicalFileName:f=>f,getCurrentDirectory:()=>web,getNewLine:()=> '\n'}));
  checks.push({name:'Changed editor and API pass TypeScript checking',passed:true});
  const out=path.join(root,'doc/book/iterations/2026-10-19-live-rulers-and-editor');fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));console.log(checks.length+' editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
