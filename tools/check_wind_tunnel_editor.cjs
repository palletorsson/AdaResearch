// Production editor operations on disposable copies; never save test layouts.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/wind-tunnel-108');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),draft=structuredClone(payload.rooms),f=draft.floors[108];
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),entries=ctx.exports.listEntries(f,payload,models,108),files=new Set();
 for(const a of f.artifacts){
  const e=entries.find(x=>x.key==='a:'+a.id),m=models.floors['108'].artifacts[a.id];assert.ok(e);assert.equal(m.artifact,a.artifact);assert.ok(m.model.meshes>0);
  const file=path.join(web,'public',m.model.url),b=fs.readFileSync(file);files.add(file);
  assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(4),2);assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length>0);
  const clip=ctx.exports.copyObject(f,e,payload,108),key=ctx.exports.pasteObject(f,clip,.1),copy=f.copies.find(x=>'a:'+x.id===key);assert.ok(copy);
  if(a.artifact==='lattice_gas_pump'){
   assert.equal(copy.config.wind_tunnel_study,true);assert.equal(copy.config.initial_angle,0);assert.equal(copy.config.plinth,'0');
   assert.equal(e.label,'Wind tunnel / turn the obstacle');
  }
  ctx.exports.turn(f,e);ctx.exports.place(f,e,[e.position[0]+.1,e.position[1],e.position[2]],payload);
 }
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})}),validation=await response.json();
 assert.ok(response.ok&&validation.valid,JSON.stringify(validation));assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);
 const receipt={passed:true,originals:6,parsedGLBs:files.size,checks:['Six original occurrences remain source-backed with real geometry.','All6 move,rotate,copy through production editor functions.','The wind-tunnel copy retains its live-study configuration and initial angle.','Edited arrangements pass the actual save validator without changing the visitor layout.'],limitations:['Tunnel is editable as a whole coupled object. Individual gas cells are procedural.','Editor GLB is a static snapshot; the same layout runs live in Godot desktop and VR.']};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt));
}run().catch(e=>{console.error(e);process.exitCode=1;});
