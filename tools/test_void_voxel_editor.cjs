const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const out=path.join(root,'doc/book/iterations/2026-10-20-void-voxel-editor');
function moduleAt(file){const ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,file),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
const {paintConstruction}=moduleAt('src/components/voxel-editor/void-construction.ts');
const {listEntries,place,turn,copyObject,pasteObject}=moduleAt('src/components/lab-editor/void-model.ts');
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=transformation';const p=await(await fetch(url)).json(),rooms=structuredClone(p.rooms),f=rooms.floors[3],checks=[];
 const check=(name,fn)=>{fn();checks.push({name,passed:true});};
 const initial=f.construction.length;
 check('Brush paints sparse elevated slabs without filling below',()=>{paintConstruction(f,'slab',[0,2,3],0);assert.equal(f.construction.length,initial+1);});
 check('Repeated brush stroke is idempotent',()=>{paintConstruction(f,'slab',[0,2,3],0);assert.equal(f.construction.length,initial+1);});
 check('Erase affects the selected layer only',()=>{paintConstruction(f,'cube',[0,0,5],0);paintConstruction(f,'erase',[0,0,5],0);assert.equal(f.construction.length,initial+1);});
 const fixture=[f.construction.at(-1)];
 paintConstruction(f,'platform',[4,2,5],90);f.construction.at(-1).id='edited-platform';fixture.push(f.construction.at(-1));
 paintConstruction(f,'platform',[4,1,-5],0);Object.assign(f.construction.at(-1),{id:'lift',travel:[0,2,0]});fixture.push(f.construction.at(-1));
 const models={floors:{},props:{}};let entry=listEntries(f,p,models,3).find(e=>e.id==='NearWedge1');
 check('Lab editor and voxel editor share move, turn and copy',()=>{const key=pasteObject(f,copyObject(f,entry,p,3),0);entry=listEntries(f,p,models,3).find(e=>e.key===key);place(f,entry,[6,1,4],p);turn(f,entry);assert.equal(f.construction.at(-1).position[1],1);assert.equal(f.construction.at(-1).facing,270);});
 async function validate(r){const res=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:r,validateOnly:true})});return {ok:res.ok,data:await res.json()};}
 assert.ok((await validate(rooms)).ok);checks.push({name:'Shared API accepts painted cells, rotated platform and lift',passed:true});
 const bad=structuredClone(rooms);bad.floors[3].construction.find(v=>v.id==='lift').travel=[0,0,0];assert.ok(!(await validate(bad)).ok);checks.push({name:'Zero-length platform journey rejected',passed:true});
 bad.floors[3].construction=Array.from({length:4097},()=>({id:'x',kind:'cube',position:[0,0,0],facing:0}));assert.ok(!(await validate(bad)).ok);checks.push({name:'Construction capacity limit enforced',passed:true});
 for(const file of ['commons/void/trials/transformation/rooms.json','C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json'])assert.deepEqual(JSON.parse(fs.readFileSync(path.isAbsolute(file)?file:path.join(root,file),'utf8')),p.rooms);
 assert.deepEqual((await(await fetch(url)).json()).rooms,p.rooms);checks.push({name:'Validation leaves save unchanged; native and Desktop backup agree',passed:true});
 const before=JSON.parse(fs.readFileSync(path.join(out,'before-rooms.json'),'utf8'));for(const i of [0,1,2,4])assert.deepEqual(p.rooms.floors[i],before.floors[i]);checks.push({name:'Other floors preserved',passed:true});
 fs.writeFileSync(path.join(out,'fixture.json'),JSON.stringify(fixture,null,2));fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));console.log(checks.length+' checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
