const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'doc/book/iterations/2026-10-20-introduction-edited-gaps');
function moduleAt(file){const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
const {paintConstruction}=moduleAt('src/components/voxel-editor/void-construction.ts');
const {listEntries,place,turn,copyObject,pasteObject}=moduleAt('src/components/lab-editor/void-model.ts');
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=transformation',p=await(await fetch(url)).json(),checks=[];
 const check=(name,fn)=>{fn();checks.push({name,passed:true});};
 const before=JSON.parse(fs.readFileSync(path.join(out,'before-rooms.json'),'utf8'));
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/transformation/manifest.json'),'utf8'));
 check('Pre, Translation and other trial floors preserved',()=>{for(const i of [0,1,3,4])assert.deepEqual(p.rooms.floors[i],before.floors[i]);});
 check('Original geometry recipe reaches the editor',()=>assert.deepEqual(p.steelModules,JSON.parse(fs.readFileSync(path.join(root,'commons/void/steel_modules.json'),'utf8'))));
 const draft=structuredClone(p.rooms),floor=draft.floors[2],count=floor.construction.length;
 check('Static construction is unchanged from the user edit',()=>assert.deepEqual(floor.construction.filter(c=>c.id!=='SuspendedPlatform'),before.floors[2].construction.filter(c=>c.id!=='SuspendedPlatform')));
 check('Eight pillar collars and three-metre decks retain metre modules',()=>{
  assert.equal(floor.construction.filter(c=>c.kind==='collar').length,8);
  for(const c of floor.construction.filter(c=>c.kind==='deck'))assert.equal(c.position[1],2.88);
 });
 check('Native models expose resized original instruments as individual parts',()=>{
  const entries=listEntries(floor,p,models,2);
  for(const name of ['GrowingCube','TurningPlank'])assert.ok(entries.find(e=>e.id===name));
  assert.ok(entries.find(e=>e.id==='SuspendedPlatform'&&e.kind==='construction'));
  assert.ok(!entries.find(e=>e.id==='AdjustableLanding'));
  const growth=entries.find(e=>e.id==='GrowingCube'),turner=entries.find(e=>e.id==='TurningPlank');
  assert.ok(growth && turner);
 });
 check('Steel paint and erase respects height layers',()=>{
  paintConstruction(floor,'deck',[18,3,6],0);paintConstruction(floor,'truss',[18,2.5,6],90);
  paintConstruction(floor,'erase',[18,3,6],0);assert.equal(floor.construction.length,count+1);
  assert.ok(floor.construction.some(c=>c.kind==='truss'&&c.position[0]===18&&c.position[1]===2.5));
 });
 check('Pillar collars can be copied, moved and rotated',()=>{
  const entry=listEntries(floor,p,models,2).find(e=>e.id==='StartCollarm7');
  const key=pasteObject(floor,copyObject(floor,entry,p,2),1);
  const copy=listEntries(floor,p,models,2).find(e=>e.key===key);
  place(floor,copy,[19,2.38,7],p);turn(floor,copy);
  assert.deepEqual(Array.from(floor.construction.at(-1).position),[19,2.38,7]);
 });
 check('Each dynamic instrument can be copied without its surrounding architecture',()=>{
  for(const name of ['GrowingCube','TurningPlank']){
   const entry=listEntries(floor,p,models,2).find(e=>e.id===name);
   const key=pasteObject(floor,copyObject(floor,entry,p,2),1);
   const copy=listEntries(floor,p,models,2).find(e=>e.key===key);
   place(floor,copy,[18,0,5],p);turn(floor,copy);
   assert.deepEqual(Array.from(floor.copies.at(-1).config.only_parts),[name]);
  }
 });
 const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());checks.push({name:'Shared validator accepts edited construction and instrument copies',passed:true});
 check('API, game project and Desktop backup match',()=>{
  for(const file of [path.join(root,'commons/void/trials/transformation/rooms.json'),'C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json'])assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),p.rooms);
 });
 assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);checks.push({name:'Validation did not change saved layout',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor/API checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
