const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/friction-studies'),read=f=>JSON.parse(fs.readFileSync(f,'utf8'));
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json(),models=read(path.join(web,'public/void-models/manifest.json')),saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),before=read(path.join(out,'rooms.before.json')),draft=structuredClone(payload.rooms),checks=[];let parts=0,meshes=0;
 for(let i=0;i<205;i++)if(i!==46)assert.deepEqual(draft.floors[i],before.floors[i]);assert.deepEqual(draft.floors[46].artifacts.slice(0,5),before.floors[46].artifacts);checks.push('All other floors and five original floor-46 artifacts retained.');
 for(const kind of ['ramp','coast','pull']){
  const id='matter-friction-'+kind,actual=models.floors['46'].artifacts[id],entry=draft.floors[46].artifacts.find(a=>a.id===id);assert.equal(actual.artifact,'matter_friction_'+kind);assert.equal(entry.scale,1);assert.ok(actual.parts.Controls);assert.ok(actual.parts.Witness);
  const entries=ctx.exports.listEntries(draft.floors[46],payload,models,46);
  for(const [name,part]of Object.entries(actual.parts)){
   if(part.url){const b=fs.readFileSync(path.join(web,'public',part.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);const g=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));assert.ok(g.meshes?.length);meshes+=g.meshes.length;}else assert.ok(part.labels?.length);
   const e=entries.find(e=>e.artifactId===id&&e.kind==='part'&&e.id===name);assert.ok(e,name);ctx.exports.place(draft.floors[46],e,[e.position[0]+.01,e.position[1],e.position[2]],payload);ctx.exports.turn(draft.floors[46],e);parts++;
  }
  const e=entries.find(e=>e.artifactId===id&&e.id==='Witness');ctx.exports.pasteObject(draft.floors[46],ctx.exports.copyObject(draft.floors[46],e,payload,46),.25);
 }
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});assert.ok(response.ok,await response.text());assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);assert.deepEqual(read('C:/Users/palle/Desktop/Ada Void/rooms.json'),payload.rooms);
 checks.push('Every authored member has actual native GLB geometry or explicit labels.','All members move/rotate and copied witnesses pass the production validator without saving test edits.','Desktop and VR share the same saved arrangement.');
 const receipt={passed:true,parts,meshes,checks,scope:'Actual exported models and production editor transforms/save validation. Arbitrary rearrangements can break calibrated contact/cable behaviour; no physical headset claim.'};fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify(receipt,null,2)+'\n');console.log(receipt);
}run().catch(e=>{console.error(e);process.exitCode=1});
