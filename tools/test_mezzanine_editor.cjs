const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'doc/book/iterations/2026-10-20-translation-steel-mezzanine');
function moduleAt(file){const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
const {paintConstruction}=moduleAt('src/components/voxel-editor/void-construction.ts');
const {listEntries,place,turn,copyObject,pasteObject}=moduleAt('src/components/lab-editor/void-model.ts');
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=transformation',p=await(await fetch(url)).json(),checks=[];
 const check=(name,fn)=>{fn();checks.push({name,passed:true});};
 const f=p.rooms.floors[3],before=JSON.parse(fs.readFileSync(path.join(out,'before-rooms.json'),'utf8'));
 check('Other trial floors preserved',()=>{for(const i of [0,1,2,4])assert.deepEqual(p.rooms.floors[i],before.floors[i]);});
 check('Editor receives the native steel geometry recipe',()=>assert.deepEqual(p.steelModules,JSON.parse(fs.readFileSync(path.join(root,'commons/void/steel_modules.json'),'utf8'))));
 check('One-metre modules and two open deck banks',()=>{
  assert.equal(f.construction.filter(c=>c.kind==='deck').length,36);
  for(const c of f.construction.filter(c=>c.kind==='deck')){assert.ok(Math.abs(c.position[2])>=5.5);assert.equal(c.position[1],2.88);}
  assert.deepEqual(p.steelModules.deck.size,[1,.12,1]);assert.deepEqual(p.steelModules.truss.size,[1,.5,.2]);
 });
 const draft=structuredClone(p.rooms),floor=draft.floors[3],count=floor.construction.length;
 check('Paint and erase all three steel types without deleting another height',()=>{
  paintConstruction(floor,'support',[0,0,0],0);paintConstruction(floor,'truss',[0,2.38,0],90);paintConstruction(floor,'deck',[0,2.88,0],0);
  paintConstruction(floor,'truss',[0,2.38,0],90);assert.equal(floor.construction.length,count+3);
  paintConstruction(floor,'erase',[0,2.38,0],0);assert.equal(floor.construction.length,count+2);
  assert.ok(floor.construction.some(c=>c.id==='deck-1'));
 });
 check('Steel modules retain copy, move and quarter-turn controls',()=>{
  const models={floors:{},props:{}},entry=listEntries(floor,p,models,3).find(e=>e.id==='NearTruss0-0');
  const key=pasteObject(floor,copyObject(floor,entry,p,3),1),copy=listEntries(floor,p,models,3).find(e=>e.key===key);
  place(floor,copy,[2,1,2],p);turn(floor,copy);
  assert.deepEqual(Array.from(floor.construction.at(-1).position),[2,1,2]);assert.equal(floor.construction.at(-1).facing,90);
 });
 const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());checks.push({name:'Shared save validator accepts steel modules and edited copies',passed:true});
 check('Project and Desktop backup match the API save',()=>{
  for(const file of [path.join(root,'commons/void/trials/transformation/rooms.json'),'C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json'])
   assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),p.rooms);
 });
 assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);checks.push({name:'Validation does not save temporary test modules',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor/API checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
