const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const report=path.join(root,'doc/book/iterations/2026-10-20-rotation-full-floor');
function moduleAt(file){
 const context={exports:{},require,structuredClone};
 vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),
   {compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
 return context.exports;
}
async function main(){
 const model=moduleAt('src/components/lab-editor/void-model.ts');
 const url='http://localhost:3003/api/void-layout';
 const state=await(await fetch(url)).json(),draft=structuredClone(state.rooms);
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const checks=[],check=(name,fn)=>{fn();checks.push({name,passed:true});};
 const entries=()=>model.listEntries(draft.floors[16],state,models,16);
 check('Main tower exposes Rotation and the lower Scale arrival',()=>{
  assert.equal(state.rooms.floors[16].map,'Trans_Rotation');assert.equal(state.rooms.floors[17].map,'Trans_Scale');
 });
 check('Every Rotation artifact has a native exported model',()=>{
  assert.deepEqual(models.failures,[]);
  for(const item of state.rooms.floors[16].artifacts)assert.ok(models.floors[16].artifacts[item.id],item.id);
  assert.ok(models.floors[17].artifacts['rotation-landing']);
 });
 check('Every cube and wedge remains individually editable',()=>{
  assert.equal(entries().filter(e=>e.kind==='construction').length,draft.floors[16].construction.length);
 });
 for(const id of ['axis-x','axis-z','angle-bands','twisting-tunnel','hinge','turn-order-film']){
  check('Copy, move and turn '+id+' preserves its configuration',()=>{
   const original=draft.floors[16].artifacts.find(p=>p.id===id);
   const source=entries().find(e=>e.id===id);assert.ok(source);
   const key=model.pasteObject(draft.floors[16],model.copyObject(draft.floors[16],source,state,16),0);
   const entry=entries().find(e=>e.key===key);
   model.place(draft.floors[16],entry,[0,0,0],state);model.turn(draft.floors[16],entry);
   const copy=draft.floors[16].copies.find(v=>v.id===entry.id);
   for(const [k,v] of Object.entries(original.config)){
    if(k==='editor_label')assert.ok(copy.config[k].startsWith(v+' (copy'));
    else assert.deepEqual(copy.config[k],v);
   }
   assert.deepEqual(Array.from(copy.position),[0,0]);assert.equal(copy.height,0);
  });
 }
 const validation=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},
  body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(validation.ok,await validation.text());
 checks.push({name:'Shared save validator accepts edited native copies',passed:true});
 check('Desktop backup matches both changed floors',()=>{
  const backup=JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json'));
  assert.deepEqual(backup.floors.slice(16),state.rooms.floors.slice(16));
 });
 assert.deepEqual((await(await fetch(url)).json()).rooms.floors.slice(16),state.rooms.floors.slice(16));
 checks.push({name:'Editor verification does not alter the saved layout',passed:true});
 fs.writeFileSync(path.join(report,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor/model/API checks passed.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
