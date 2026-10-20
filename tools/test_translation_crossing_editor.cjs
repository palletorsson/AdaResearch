// Production copy/move/turn operations; validation does not save fixtures.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const out=path.join(root,'doc/book/iterations/2026-10-19-translation-single-crossing');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=transformation';
 const payload=await(await fetch(url)).json(),original=JSON.stringify(payload.rooms),checks=[];
 const manifest=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/transformation/manifest.json'),'utf8'));
 const entries=listEntries(payload.rooms.floors[3],payload,manifest,3).filter(e=>e.kind==='part');
 assert.equal(entries.length,9);
 for(const part of entries){assert.ok(part.model.meshes>0);const b=fs.readFileSync(path.join(web,'public',part.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);}
 checks.push({name:'All nine independently editable parts have real native geometry',passed:true});
 const floor=payload.rooms.floors[3];assert.equal(floor.artifacts.length,1);assert.equal(floor.props.length,0);assert.equal(floor.walls.length,0);assert.ok(!floor.basin);
 checks.push({name:'One crossing; no course partitions, extra pits or decorative props',passed:true});
 for(const id of ['NearCube1','NearWedge1','SuspendedPlatform']){
  const rooms=structuredClone(payload.rooms),floor=rooms.floors[3];
  const entry=listEntries(floor,payload,manifest,3).find(e=>e.id===id&&e.kind==='part');
  const key=pasteObject(floor,copyObject(floor,entry,payload,3),0);
  let copy=listEntries(floor,payload,manifest,3).find(e=>e.key===key);
  place(floor,copy,[4,2,5],payload);turn(floor,copy);
  copy=listEntries(floor,payload,manifest,3).find(e=>e.key===key);
  assert.equal(copy.position[0],4);assert.equal(copy.position[1],2);assert.equal(copy.position[2],5);assert.equal(copy.model.url,entry.model.url);
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const result=await response.json();assert.ok(response.ok&&result.valid,JSON.stringify(result));
  fs.writeFileSync(path.join(out,'editor-copy-'+id+'.json'),JSON.stringify(floor.copies.at(-1),null,2));
  checks.push({name:id+': copy, move, quarter-turn and save validation',passed:true});
 }
 assert.equal(JSON.stringify((await(await fetch(url)).json()).rooms),original);
 const before=JSON.parse(fs.readFileSync(path.join(out,'before-rooms.json'),'utf8'));
 for(const index of [0,1,2,4])assert.deepEqual(payload.rooms.floors[index],before.floors[index]);
 checks.push({name:'Fixtures never replace the saved layout; other floors unchanged',passed:true});
 for(const file of [path.join(root,'commons/void/trials/transformation/rooms.json'),'C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json'])assert.deepEqual(JSON.parse(fs.readFileSync(file,'utf8')),payload.rooms);
 checks.push({name:'Editor, native game and Desktop backup agree',passed:true});
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor checks passed.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
