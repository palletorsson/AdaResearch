const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const report=path.join(root,'doc/book/iterations/2026-10-20-rotation-in-tower');
function moduleAt(file){const ctx={exports:{},require:(name)=>name==='three'?require(path.join(web,'node_modules/three')):require(name),structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
async function main(){
 const model=moduleAt('src/components/lab-editor/void-model.ts');
 const {paintConstruction}=moduleAt('src/components/voxel-editor/void-construction.ts');
 const {constructionView}=moduleAt('src/components/voxel-editor/void-construction-view.ts');
 const url='http://localhost:3003/api/void-layout';
 const p=await(await fetch(url)).json(),draft=structuredClone(p.rooms),floor=draft.floors[16],checks=[];
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const check=(name,fn)=>{fn();checks.push({name,passed:true});};
 const entries=()=>model.listEntries(floor,p,models,16);
 check('Rotation follows Translation in the main tower',()=>{assert.equal(p.rooms.floors.length,17);assert.equal(p.rooms.floors[15].map,'Trans_Translation');assert.equal(models.floors[16].map,'Trans_Rotation');});
 check('Every cube wedge and platform is individually editable',()=>assert.equal(entries().filter(e=>e.kind==='construction').length,9));
 const source=entries().find(e=>e.id==='rotating_platform-9');
 const key=model.pasteObject(floor,model.copyObject(floor,source,p,16),0);
 const copy=entries().find(e=>e.key===key);
 model.place(floor,copy,[-10,2,0],p);model.turn(floor,copy);
 const item=floor.construction.find(p=>p.id===copy.id);
 Object.assign(item,{angle:45,turn_speed:12,pause:6,length:6});
 check('Copy move turn and settings preserve the source platform',()=>{assert.deepEqual(Array.from(item.position),[-10,2,0]);assert.equal(item.facing,90);assert.equal(floor.construction.find(p=>p.id===source.id).angle,-90);});
 fs.writeFileSync(path.join(report,'edited-platform.json'),JSON.stringify(item,null,2));
 check('New brush creates a working quarter-turn by default',()=>{
  const id=paintConstruction(floor,'rotating_platform',[-17,1,0],0);
  const added=floor.construction.find(p=>p.id===id);
  assert.equal(added.angle,-90);assert.equal(added.length,8);assert.equal(added.pause,6);assert.equal(added.turn_speed,9);
  paintConstruction(floor,'erase',[-17,1,0],0);
 });
 check('Editor preview shows deck, fixed support and destination arc',()=>{
  const view=constructionView(item,5.64);
  assert.equal(view.children.length,6);
  assert.equal(view.children[0].geometry.parameters.width,6);
  assert.equal(view.children[3].rotation.y,Math.PI/4);
  assert.equal(view.children[4].geometry.attributes.position.count,49);
 });
 const validation=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(validation.ok,await validation.text());checks.push({name:'Shared desktop/VR save validator accepts the edited copy',passed:true});
 item.turn_speed=100;
 const invalid=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.equal(invalid.status,422);checks.push({name:'Validator rejects turn speed outside the supported range',passed:true});
 check('Rotation in Desktop backup matches the live API',()=>assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json')).floors[16],p.rooms.floors[16]));
 assert.deepEqual((await(await fetch(url)).json()).rooms.floors[16],p.rooms.floors[16]);
 checks.push({name:'Editor tests leave Rotation unchanged; concurrent curation of other floors is allowed',passed:true});
 fs.writeFileSync(path.join(report,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor/API checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
