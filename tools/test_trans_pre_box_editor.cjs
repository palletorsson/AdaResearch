const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const report=path.join(root,'doc/book/iterations/2026-10-20-trans-pre-box-path');
function moduleAt(file){const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
async function main(){
 const model=moduleAt('src/components/lab-editor/void-model.ts');
 const {paintConstruction}=moduleAt('src/components/voxel-editor/void-construction.ts');
 const url='http://localhost:3003/api/void-layout?trial=transformation';
 const p=await(await fetch(url)).json(),draft=structuredClone(p.rooms),floor=draft.floors[1],checks=[];
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/transformation/manifest.json')));
 const check=(name,fn)=>{fn();checks.push({name,passed:true});};
 const entries=()=>model.listEntries(floor,p,models,1);
 check('Actual reward box models are exported',()=>{for(const id of ['first-health','found-solid','last-health'])assert.ok(models.floors[1].artifacts[id].model.url);});
 check('Every metre cell remains an editable construction object',()=>assert.equal(entries().filter(e=>e.kind==='construction').length,175));
 check('Rewards copy, move and rotate independently',()=>{
  const entry=entries().find(e=>e.id==='found-solid');
  const key=model.pasteObject(floor,model.copyObject(floor,entry,p,1),1);
  const copy=entries().find(e=>e.key===key);
  model.place(floor,copy,[18,0,-5],p);model.turn(floor,copy);
  assert.equal(floor.copies.at(-1).artifact,'void_step_prefab_box');
  assert.deepEqual(Array.from(floor.copies.at(-1).position),[18,-5]);
 });
 check('Paint and erase do not remove another height layer',()=>{
  const count=floor.construction.length;
  paintConstruction(floor,'cube',[-18,0,3],0);paintConstruction(floor,'slab',[-18,1,3],0);
  paintConstruction(floor,'erase',[-18,1,3],0);
  assert.equal(floor.construction.length,count+1);
 });
 check('Raised lesson labels retain their height when moved and copied',()=>{
  const entry=entries().find(e=>e.kind==='route'&&e.label==='01 / STILL');
  assert.equal(entry.position[1],1.035);
  model.place(floor,entry,[-5,1.035,.7],p);
  const key=model.pasteObject(floor,model.copyObject(floor,entry,p,1),1);
  assert.equal(entries().find(e=>e.key===key).position[1],1.035);
 });
 const validation=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(validation.ok,await validation.text());checks.push({name:'Shared save validator accepts edited cells and reward copies',passed:true});
 check('Desktop backup and live project match the editor API',()=>{for(const file of [path.join(root,'commons/void/trials/transformation/rooms.json'),'C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json'])assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);});
 assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);
 checks.push({name:'Editor tests leave the saved arrangement unchanged',passed:true});
 fs.writeFileSync(path.join(report,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor/API checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
