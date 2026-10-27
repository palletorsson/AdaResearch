const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/logic-sequence-2026-10-26');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
const read=p=>JSON.parse(fs.readFileSync(p,'utf8')),url='http://localhost:3003';
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch(url+'/api/void-layout')).json(),workbench=await(await fetch(url+'/api/prefab-workbench')).json();
 const models=read(path.join(web,'public/void-models/manifest.json')),before=read(path.join(out,'rooms.before.json'));
 const maps=['Logic_Event','Logic_AND','Logic_Alternatives','Logic_Assemblage'];
 assert.equal(payload.rooms.floors.length,209);assert.deepEqual(payload.rooms.floors.slice(20,24).map(f=>f.map),maps);
 for(let i=0;i<205;i++){
  const expected=structuredClone(before.floors[i]);
  for(const a of [...expected.artifacts,...expected.copies??[]]){const s=a.config?.editor_source;if(s&&s.floor>=20)s.floor+=4;}
  assert.deepEqual(payload.rooms.floors[i<20?i:i+4],expected,'preserved earlier arrangement '+i);
 }
 const backupIndex=read(path.join(out,'backup-index.json')),at=backupIndex.findIndex(p=>p.replaceAll('\\','/').endsWith('public/void-models/manifest.json'));
 const oldModels=read(path.join(out,`before-${at}-manifest.json`));
 for(const [floor,model] of Object.entries(oldModels.floors))assert.deepEqual(models.floors[Number(floor)<20?floor:String(Number(floor)+4)],model,'preserved original local GLB records '+floor);
 const expectedIds=['logic_event_chain','matter_spring_and','matter_spring_or','matter_spring_not','logic_assemblage_workshop'];
 for(const id of expectedIds){const n=workbench.nodes.find(n=>n.id===id);assert.ok(n?.preview.length&&n.placement,id+' actual model and placement');}
 const draft=structuredClone(payload.rooms);let members=0,glbs=new Set();
 for(let floor=20;floor<=23;floor++){
  const f=draft.floors[floor],entries=ctx.exports.listEntries(f,payload,models,floor);
  for(const a of f.artifacts){
   const parts=entries.filter(e=>e.kind==='part'&&e.artifactId===a.id);assert.ok(parts.length>=7,a.id+' independent parts');
   for(const e of parts){
    if(e.model.url){const p=path.join(web,'public',e.model.url),b=fs.readFileSync(p);assert.equal(b.readUInt32LE(0),0x46546c67);const j=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(j.meshes?.length);glbs.add(p);}
    else assert.ok(e.model.labels?.length,'explicit native text');
    ctx.exports.place(f,e,[e.position[0]+.01,e.position[1],e.position[2]+.01],payload);ctx.exports.turn(f,e);members++;
   }
   const e=parts.find(e=>e.model.url);ctx.exports.pasteObject(f,ctx.exports.copyObject(f,e,payload,floor),.05);
  }
 }
 for(const id of expectedIds){const n=workbench.nodes.find(n=>n.id===id);ctx.exports.placeWorkbenchPrefab(draft.floors[23],n,[0,6],'logic-check-'+id);}
 const response=await fetch(url+'/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});
 assert.ok(response.ok,await response.text());
 assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);
 assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(process.env.USERPROFILE,'Desktop/Ada Void/rooms.json'))),0);
 const thread=await(await fetch(url+'/api/capacity-thread')).json(),sequence=thread.maps.map(m=>m.sequence);
 assert.ok(sequence.indexOf('transformation')<sequence.indexOf('logic')&&sequence.lastIndexOf('logic')<sequence.indexOf('array_tutorial'));
 for(const id of expectedIds)assert.ok(thread.objects.some(n=>n.id===id&&maps.includes(n.entry.map)),id+' explicit tree insertion');
 const report={passed:true,existingArrangementsPreserved:205,existingModelRecordsPreserved:205,newFloors:[20,21,22,23],workbenchExamples:expectedIds.length,editableMembers:members,parsedGLBs:glbs.size,saveParity:true,scope:'Current production APIs and real local GLBs: every new member move/rotate/copy, all five catalogue examples placed in validation-only drafts, tree order and desktop mirror. No saved user layout or relationship changed by these checks.'};
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}
run().catch(e=>{console.error(e);process.exitCode=1});
