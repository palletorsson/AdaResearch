const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'doc/book/iterations/2026-10-21-void-noise');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=noise',headers={'Content-Type':'application/json',Origin:'http://localhost:3003'},checks=[];
 const p=await(await fetch(url)).json(),file=path.join(root,'commons/void/trials/noise/rooms.json');
 assert.equal(p.trial,'noise');assert.equal(p.rooms.floors[1].map,'Random_Noise_Types');
 assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 checks.push({name:'Editor and both player modes read the same separate Noise layout',passed:true});
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/noise/manifest.json')));
 assert.deepEqual(models.failures,[]);
 assert.equal(p.rooms.floors[2].map,'Noise_Columns');
 for(const level of [1,2]){
 const entries=listEntries(p.rooms.floors[level],p,models,level).filter(e=>e.kind==='artifact');
 assert.equal(entries.length,level===1?6:3);
 for(const entry of entries){
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));
  assert.equal(bytes.readUInt32LE(0),0x46546c67);
  const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());
  assert.ok(gltf.meshes.length>0);
  const rooms=structuredClone(p.rooms),f=rooms.floors[level];
  const key=pasteObject(f,copyObject(f,entry,p,level),0);
  let copy=listEntries(f,p,models,level).find(e=>e.key===key);
  place(f,copy,[16,0,4],p);turn(f,copy);
  copy=listEntries(f,p,models,level).find(e=>e.key===key);
  assert.notEqual(copy.key,entry.key);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});
  assert.ok(response.ok,JSON.stringify(await response.json()));
  checks.push({name:entry.id+': exported geometry, independent move, turn and copy validate',passed:true});
 }
 }
 const moved=structuredClone(p.rooms);moved.floors[2].artifacts.find(a=>a.id==='columns').position[0]+=.25;
 const save=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})});
 const receipt=await save.json();assert.ok(save.ok&&receipt.saved,JSON.stringify(receipt));
 try{
  assert.deepEqual((await(await fetch(url)).json()).rooms,moved);
  assert.deepEqual(JSON.parse(fs.readFileSync(file)),moved);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/noise/rooms.json')),moved);
  checks.push({name:'Moved station survives save and reload in the native layout and Desktop backup',passed:true});
  const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:'stale-test-revision'})});
  assert.equal(stale.status,409);checks.push({name:'Stale saves cannot overwrite a newer edit',passed:true});
 }finally{
  const restore=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:receipt.revision})});
  assert.ok(restore.ok,'A newer user edit exists; leave it intact');
 }
 for(const [file,digest] of Object.entries(JSON.parse(fs.readFileSync(path.join(out,'before.json')))))assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),digest,file);
 checks.push({name:'Original museum artifacts and chapter texts preserved',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' Noise editor checks passed.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
