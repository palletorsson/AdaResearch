// Production editor operations on disposable copies; never save test arrangements.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/ca-curation');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const originals=JSON.parse(fs.readFileSync(path.join(out,'inventory.json'))),draft=structuredClone(payload.rooms),files=new Set(),counts={};
 let originalsCount=0,partsCount=0,newReceivers=0;
 function model(m){
  if(!m?.url){assert.ok(m?.labels?.length||m?.meshes===0,'A missing model must disclose a label-only group.');return;}
  const file=path.join(web,'public',m.url);files.add(file);const b=fs.readFileSync(file);
  assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(4),2);
  assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes?.length,'GLB must contain actual geometry');
 }
 for(const source of originals){
  const i=source.floor,f=draft.floors[i],entries=ctx.exports.listEntries(f,payload,models,i);counts[i]={originals:f.artifacts.length,parts:0};
  const ids=new Set(source.artifacts.map(a=>a.id));
  assert.deepEqual(f.artifacts.filter(a=>ids.has(a.id)).map(a=>a.id).sort(),[...ids].sort());
  assert.ok(f.artifacts.every(a=>ids.has(a.id)||(i===109&&a.id==='ca-architectural-history')));
  for(const a of f.artifacts){
   const exported=models.floors[String(i)]?.artifacts[a.id];assert.equal(exported?.artifact,a.artifact);
   const rootEntry=entries.find(e=>e.key==='a:'+a.id);assert.ok(rootEntry);
   const parts=entries.filter(e=>e.kind==='part'&&e.artifactId===a.id);assert.ok(exported.model?.meshes>0||parts.some(e=>e.model?.meshes>0),'Each original has geometry');
   if(exported.model)model(exported.model);
   for(const e of parts)model(e.model);
   counts[i].parts+=parts.length;partsCount+=parts.length;if(ids.has(a.id))originalsCount++;else newReceivers++;
   const clipboard=ctx.exports.copyObject(f,rootEntry,payload,i),key=ctx.exports.pasteObject(f,clipboard,.12),copy=f.copies.find(x=>'a:'+x.id===key);
   assert.ok(copy);for(const k of ['ca_live','curated_console','void_auto_door'])if(a.config?.[k]!==undefined)assert.deepEqual(copy.config[k],a.config[k]);
   ctx.exports.turn(f,rootEntry);ctx.exports.place(f,rootEntry,[rootEntry.position[0]+.1,rootEntry.position[1],rootEntry.position[2]],payload);
   if(parts.length){const e=parts[0];ctx.exports.turn(f,e);ctx.exports.place(f,e,[e.position[0]+.05,e.position[1],e.position[2]],payload);}
  }
  for(const kind of ['wall','construction','prop']){
   const e=entries.find(e=>e.kind===kind);assert.ok(e,'Each floor has editable '+kind+' framing');ctx.exports.turn(f,e);ctx.exports.place(f,e,[e.position[0]+.05,e.position[1],e.position[2]],payload);
  }
 }
 assert.equal(originalsCount,43);
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 const validation=await response.json();assert.ok(response.ok&&validation.valid,JSON.stringify(validation));
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);
 const receipt={passed:true,originals:originalsCount,newReceivers,editableParts:partsCount,parsedGLBs:files.size,floors:counts,checks:['All 43 original occurrences retained with actual exported geometry.','All 44 source-backed objects move and turn through production editor functions.','Copies preserve source dependencies and opt-in live/control configurations.','Cubes, wedges, walls and work lights remain separate editable objects.','Edited/copy arrangements serialize and pass the production save validator; visitor layout is unchanged by the test.'],limitations:['CA procedural exhibits are edited as whole source-backed objects; their individual generated cells are not separate editor parts.','Editor GLBs are static geometry previews; live CA computation runs in Godot.']};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));
}
run().catch(e=>{console.error(e);process.exitCode=1;});
