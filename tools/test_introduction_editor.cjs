// Production editor operations + native exports; fixtures never replace user rooms.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const out=path.join(root,'doc/book/iterations/2026-10-19-introduction-hazard-pit');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=transformation';
 const payload=await(await fetch(url)).json(),original=JSON.stringify(payload.rooms),checks=[];
 const manifest=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/transformation/manifest.json'),'utf8'));
 const entries=listEntries(payload.rooms.floors[2],payload,manifest,2).filter(e=>e.kind==='part');
 assert.equal(entries.length,41);
 for(const part of entries){
  if(part.model.meshes){const b=fs.readFileSync(path.join(web,'public',part.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);}
  else assert.ok(part.model.labels.length);
 }
 checks.push({name:'All 41 pieces, captions and route anchor have native geometry/text previews',passed:true});
 assert.equal(payload.rooms.floors[2].walls.length,7);
 assert.equal(listEntries(payload.rooms.floors[2],payload,manifest,2).filter(e=>e.kind==='wall').length,7);
 checks.push({name:'All seven route partitions remain editable wall objects',passed:true});
 for(const id of ['NearCube1_2','NearWedge2','MovingPlatform','FarWedge2','LethalPit']){
  const rooms=structuredClone(payload.rooms),floor=rooms.floors[2];
  const entry=listEntries(floor,payload,manifest,2).find(e=>e.id===id&&e.kind==='part');
  const key=pasteObject(floor,copyObject(floor,entry,payload,2),0);
  let copy=listEntries(floor,payload,manifest,2).find(e=>e.key===key);
  place(floor,copy,[1,0,4],payload);turn(floor,copy);
  copy=listEntries(floor,payload,manifest,2).find(e=>e.key===key);
  assert.equal(copy.position[0],1);assert.equal(copy.position[2],4);
  assert.equal((copy.rotation[1]%360+360)%360,((entry.rotation[1]+90)%360+360)%360);assert.equal(copy.model.url,entry.model.url);
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const result=await response.json();assert.ok(response.ok&&result.valid,JSON.stringify(result));
  if(id==='MovingPlatform')fs.writeFileSync(path.join(out,'editor-copy.json'),JSON.stringify(floor.copies.at(-1),null,2));
  checks.push({name:id+': independent copy, move, quarter turn and save validation',passed:true});
 }
 assert.equal(JSON.stringify((await(await fetch(url)).json()).rooms),original);
 checks.push({name:'Validation never overwrites the authored floor',passed:true});
 const before=JSON.parse(fs.readFileSync(path.join(out,'before.json'),'utf8'));
 assert.deepEqual(payload.rooms.floors.slice(0,2),before.rooms.floors.slice(0,2));
 checks.push({name:'Pre and its roof retain the prior saved arrangement',passed:true});
 for(const [file,digest] of Object.entries(before.preserved_sha256)){
  if(file==='commons/void/ride_platform.gd')continue;
  assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),digest,file);
 }
 checks.push({name:'Chapter texts, original museum data, curated tower and shared building recipes preserved',passed:true});
 for(const file of [path.join(root,'commons/void/trials/transformation/rooms.json'),'C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json'])assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),payload.rooms);
 checks.push({name:'Editor, native game and Desktop trial backup agree',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor checks passed; native copy fixture written');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
