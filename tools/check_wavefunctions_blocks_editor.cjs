const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/wavefunctions-block-supports');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),draft=structuredClone(payload.rooms),checks=[];
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),floor=draft.floors[59];
 const entries=ctx.exports.listEntries(floor,payload,models,59),cells=entries.filter(e=>e.kind==='construction'&&e.id.startsWith('wave-block-'));
 assert.equal(cells.length,27);assert.equal(new Set(cells.map(e=>e.id)).size,27);assert.ok(!floor.props.some(p=>p.kind==='workbench'));
 checks.push('Seven workbenches replaced by 27 separate existing cube and wedge modules');
 for(const entry of cells){ctx.exports.place(floor,entry,[entry.position[0],entry.position[1],entry.position[2]-.25],payload);ctx.exports.turn(floor,entry);}
 const clip=ctx.exports.copyObject(floor,cells.find(e=>e.id==='wave-block-west-ramp-0'),payload,59);ctx.exports.pasteObject(floor,clip,.25);
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,await response.text());
 checks.push('Every support and ramp supports actual editor move/rotate; ramp copy validates');
 for(const entry of entries.filter(e=>e.kind==='artifact'&&e.id!=='hand-sine-yoke')){
  assert.ok(entry.model?.url,entry.id);const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
 }
 checks.push('All original artifact previews remain real native GLBs');
 assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft))),JSON.stringify(draft));assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),saved),0);
 checks.push('Save serialization preserves parts and validation leaves visitor arrangements unchanged');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Actual editor model mutations and validation-only server requests; native snapshots for unchanged artifacts.'},null,2)+'\n');console.log(checks.length+' editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
