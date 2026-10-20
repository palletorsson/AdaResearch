// Real editor copy/place/turn operations and save validation; no fixture saved.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript'));
const ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const url='http://localhost:3003/api/void-layout?trial=transformation';
 const payload=await(await fetch(url)).json(),before=JSON.stringify(payload.rooms),checks=[];
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/transformation/manifest.json'),'utf8'));
 for(const name of ['EntryWedge2','DeckCube1_2','ExitWedge2']){
  const rooms=structuredClone(payload.rooms),floor=rooms.floors[1];
  const original=listEntries(floor,payload,models,1).find(e=>e.kind==='part'&&e.id===name);
  assert.ok(original?.model?.url,name+' real model');
  const bytes=fs.readFileSync(path.join(web,'public',original.model.url));
  assert.equal(bytes.readUInt32LE(0),0x46546c67);
  assert.ok(JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString()).meshes.length);
  const key=pasteObject(floor,copyObject(floor,original,payload,1),0);
  let copy=listEntries(floor,payload,models,1).find(e=>e.key===key);
  place(floor,copy,[-16,0,3],payload);turn(floor,copy);
  copy=listEntries(floor,payload,models,1).find(e=>e.key===key);
  assert.equal(copy.position[0],-16);assert.equal(copy.position[2],3);
  assert.equal(copy.rotation[1],(original.rotation[1]+90)%360);
  assert.equal(copy.model.url,original.model.url);
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const result=await response.json();assert.ok(response.ok&&result.valid,JSON.stringify(result));
  checks.push({name:name+': native model, independent copy, move, turn and save validation',passed:true});
 }
 assert.equal(JSON.stringify((await(await fetch(url)).json()).rooms),before);
 checks.push({name:'Validation leaves the saved trial unchanged',passed:true});
 const report=path.join(root,'doc/book/iterations/2026-10-19-transformation-two-shafts');
 const history=JSON.parse(fs.readFileSync(path.join(report,'before.json'),'utf8'));
 for(const [file,hash] of Object.entries(history.preserved_sha256))assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),hash,file);
 checks.push({name:'Curated Primitives layout and Trans_Pre final/tutorial/map stay unchanged',passed:true});
 const originals=history.rooms.floors[1].artifacts.filter(a=>a.config?.museum_origin==='Trans_Pre'&&a.artifact!=='void_trial_raised_route');
 assert.equal(originals.length,13);
 for(const source of originals){const current=payload.rooms.floors[1].artifacts.find(a=>a.id===source.id);assert.equal(current.artifact,source.artifact);assert.deepEqual(current.config,source.config);}
 checks.push({name:'All thirteen original artifacts keep their source and interaction configuration',passed:true});
 assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/trials/transformation/rooms.json'),'utf8')),payload.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/trials/transformation/rooms.json','utf8')),payload.rooms);
 checks.push({name:'Editor, native trial and Desktop trial backup agree',passed:true});
 fs.writeFileSync(path.join(report,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
