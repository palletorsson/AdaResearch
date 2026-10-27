const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=process.argv[2]?path.resolve(process.argv[2]):path.join(root,'ada_run/intro-logic');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
 const draft=structuredClone(payload.rooms),floor=draft.floors[14],checks=[],counts={};
 const entries=ctx.exports.listEntries(floor,payload,models,14);
 for(const op of ['and','or','not']){
  const parts=entries.filter(e=>e.kind==='part'&&e.artifactId==='logic-spring-'+op);assert.ok(parts.length>=7);counts[op]=parts.length;
  for(const e of parts){
   if(!e.model.url){assert.equal(e.model.meshes,0);assert.ok(e.model.labels.length);continue;}
   const b=fs.readFileSync(path.join(web,'public',e.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.ok(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length);
  }
  const e=parts[0];ctx.exports.turn(floor,e);ctx.exports.place(floor,e,[e.position[0]+.1,e.position[1],e.position[2]],payload);
  ctx.exports.pasteObject(floor,ctx.exports.copyObject(floor,e,payload,14),.1);
 }
 checks.push('All three gates expose actual exported groups; copied parts move and rotate through production editor functions.');
 const workbench=await(await fetch('http://localhost:3003/api/prefab-workbench')).json();
 for(const op of ['and','or','not']){const p=workbench.nodes.find(n=>n.id==='matter_spring_'+op);assert.equal(p.preview.length,counts[op]);ctx.exports.placeWorkbenchPrefab(draft.floors[13],p,[0,0],op+'-editor-check');}
 checks.push('AND, OR and NOT use the shared tree/catalogue and can be placed from the workbench.');
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);
 checks.push('Editor changes serialize and validate without mutating the saved visitor layout.');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,counts,checks},null,2)+'\n');console.log(checks.join('\n'));
}
run().catch(e=>{console.error(e);process.exitCode=1;});
