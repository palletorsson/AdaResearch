// Copy real imported artifacts and authored furniture with production editor code.
// Requests only validate drafts; none of these test copies are saved.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await (await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const floor=payload.rooms.floors[8],original=JSON.stringify(payload.rooms),entries=listEntries(floor,payload,models,8),checks=[];
 const selected=entries.filter(e=>['18-13','18-16','21-13','21-16','24-13','24-16'].some(id=>e.id==='museum-primitives_ignorance-'+id)||e.artifactId==='hall'&&['ComparisonStand_1_Edges','BudgetOfSmoothness','SphereResolutionAtlas'].includes(e.id));
 assert.equal(selected.length,9);
 for(const entry of selected){
   const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
   const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
   Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
   const key=pasteObject(destination,copyObject(floor,entry,payload,8),0);
   let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
   assert.equal(copy.model.url,entry.model.url);
   place(destination,copy,[0,entry.position[1],4],payload);turn(destination,copy);
   copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
   assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
   if(entry.kind==='artifact'){
     const source=floor.artifacts.find(a=>a.id===entry.id),item=[...destination.artifacts,...destination.copies??[]][0];
     assert.equal(item.config.inspection,source.config.inspection);
     assert.equal(item.config.inspection_edges,source.config.inspection_edges);
   }
   const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
   const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
   checks.push({name:`Real geometry, copy/move/turn and schema validation: ${entry.id}`,passed:true});
 }
 const out=path.join(root,'doc/book/iterations/2026-10-19-ignorance-comparison-path');
 const before=JSON.parse(fs.readFileSync(path.join(out,'layout-change.json'),'utf8'));
 assert.deepEqual(floor.artifacts.map(a=>a.id),before.artifact_ids);
 checks.push({name:'All original imported artifact IDs retained',passed:true});
 for(const [name,hash] of Object.entries(before.preserved_text_sha256)){
   assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'commons/maps/Primitives_Ignorance',name))).digest('hex'),hash);
 }
 checks.push({name:'Existing tutorial.md and final.md unchanged',passed:true});
 assert.equal(JSON.stringify(payload.rooms),original);
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Production editor transformations and actual Godot models; validation only.'},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
