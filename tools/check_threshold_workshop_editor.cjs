const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/threshold-workshop'),read=f=>JSON.parse(fs.readFileSync(f,'utf8'));
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json(),models=read(path.join(web,'public/void-models/manifest.json')),saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),before=read(path.join(out,'main-rooms.before.json')),draft=structuredClone(payload.rooms),checks=[];let parts=0,meshes=0;
 function check(name,f){f();checks.push({name,passed:true});}
 check('standard 205-floor tutorial and every other saved floor are preserved',()=>{
  assert.equal(draft.floors.length,205);assert.equal(payload.frame.width,42);assert.equal(payload.frame.depth,18);
  for(let i=0;i<205;i++)if(i!==14)assert.deepEqual(draft.floors[i],before.floors[i]);
  for(const key of Object.keys(before.floors[14]))if(!['artifacts','route'].includes(key))assert.deepEqual(draft.floors[14][key],before.floors[14][key]);
  assert.deepEqual(draft.floors[14].artifacts.slice(0,4),before.floors[14].artifacts);
 });
 for(const kind of ['again','almost','just','barely','still','descent']){
  const id='threshold-workshop-'+kind,entry=draft.floors[14].artifacts.find(a=>a.id===id),actual=models.floors['14'].artifacts[id];assert.ok(entry);assert.equal(entry.scale,1);assert.equal(entry.height,0);assert.equal(actual.artifact,'threshold_'+kind);assert.ok(actual.parts.TakeLedger);if(kind==='almost')assert.ok(actual.parts.HeightWitness);
  const entries=ctx.exports.listEntries(draft.floors[14],payload,models,14);
  for(const [name,part] of Object.entries(actual.parts)){
   if(part.url){const b=fs.readFileSync(path.join(web,'public',part.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(g.meshes?.length);meshes+=g.meshes.length;}else assert.ok(part.labels?.length);
   const e=entries.find(e=>e.artifactId===id&&e.kind==='part'&&e.id===name);assert.ok(e,name);ctx.exports.place(draft.floors[14],e,[e.position[0]+.01,e.position[1],e.position[2]],payload);ctx.exports.turn(draft.floors[14],e);parts++;
  }
  const ledger=entries.find(e=>e.artifactId===id&&e.id==='TakeLedger');ctx.exports.pasteObject(draft.floors[14],ctx.exports.copyObject(draft.floors[14],ledger,payload,14),.25);
 }
 check('six native assemblies and every witness/member have actual editable geometry',()=>assert.ok(parts>200&&meshes>200));
 const result=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});assert.ok(result.ok,await result.text());
 check('all members move/rotate and copied ledgers pass the production save validator',()=>assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0));
 check('desktop and VR use the same saved tutorial arrangement',()=>assert.deepEqual(read('C:/Users/palle/Desktop/Ada Void/rooms.json'),payload.rooms));
 const receipt={passed:true,parts,meshes,checks,scope:'Actual main-floor GLBs, production editor move/rotate/copy and validate-only save path; existing main floors and original floor-14 objects retained. No test copies saved.'};fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(receipt,null,2)+'\n');console.log(receipt);
}run().catch(e=>{console.error(e);process.exitCode=1});
