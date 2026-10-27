// Actual production editor functions, disposable copies, no visitor save.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/ca-spatial-02');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),draft=structuredClone(payload.rooms);
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),files=new Set();
 const base=JSON.parse(fs.readFileSync(path.join(out,'before.json'))).rooms;
 let originals=0,receivers=0;
 for(const n of [104,107]){
  const f=draft.floors[n],entries=ctx.exports.listEntries(f,payload,models,n);
  for(const a of f.artifacts){
   const e=entries.find(x=>x.key==='a:'+a.id);assert.ok(e);
   const m=models.floors[String(n)].artifacts[a.id];assert.equal(m.artifact,a.artifact);assert.ok(m.model.meshes>0);
   const file=path.join(web,'public',m.model.url);files.add(file);const b=fs.readFileSync(file);
   assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(4),2);
   assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length>0);
   const clip=ctx.exports.copyObject(f,e,payload,n),key=ctx.exports.pasteObject(f,clip,.12),copy=f.copies.find(x=>'a:'+x.id===key);
   assert.ok(copy);if(a.config?.source_id){assert.equal(copy.config.source_id,a.config.source_id);receivers++;}else originals++;
   ctx.exports.turn(f,e);ctx.exports.place(f,e,[e.position[0]+.1,e.position[1],e.position[2]],payload);
  }
  assert.equal(base.floors[n].artifacts.filter(a=>f.artifacts.some(x=>x.id===a.id)).length,base.floors[n].artifacts.length);
 }
 assert.equal(originals,9);assert.equal(receivers,4);
 const res=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 const validation=await res.json();assert.ok(res.ok&&validation.valid,JSON.stringify(validation));
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);
 const receipt={passed:true,originals,receivers,realGLBs:files.size,checks:['Every original retained;4 new source-linked objects independently exported.','All13 objects copy,move,rotate using production editor functions.','Copies preserve source association; edited arrangements pass actual save validation.','No visitor arrangement was saved by this check.'],limits:['Procedural CA cells/louvers are whole-source editable objects, not individual editor parts.','Editor geometry is a snapshot; the same original algorithms drive Godot desktop/VR.']};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt));
}run().catch(e=>{console.error(e);process.exitCode=1;});
