// Focused native export and existing editor placement/copy/save contract.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/single-cube');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
async function run(){
 const before=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const payload=await(await fetch('http://localhost:3003/api/void-layout')).json(),models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),draft=structuredClone(payload.rooms),checks=[];
 const part=models.floors['7'].artifacts.hall.parts.PairedCubeDiagonals;
 assert.match(part.default.label,/eight movable vertices/);assert.ok(part.default.bounds[3]<1.8&&part.default.bounds[4]<1.8);
 const bytes=fs.readFileSync(path.join(web,'public',part.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
 const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));
 const skins=gltf.materials.filter(m=>m.alphaMode==='BLEND'&&m.doubleSided&&Math.abs(m.pbrMetallicRoughness?.baseColorFactor?.[3]-.6)<.001);
 assert.ok(new Set(skins.map(m=>m.pbrMetallicRoughness.baseColorFactor.join(','))).size>=3);
 checks.push('Actual exported single-cube geometry has compact bounds and three double-sided translucent skin colours');
 const entry=ctx.exports.listEntries(draft.floors[7],payload,models,7).find(e=>e.kind==='part'&&e.artifactId==='hall'&&e.id==='PairedCubeDiagonals');assert.ok(entry);
 ctx.exports.place(draft.floors[7],entry,[entry.position[0]+.25,entry.position[1],entry.position[2]+.25],payload);ctx.exports.turn(draft.floors[7],entry);
 const fresh=ctx.exports.listEntries(draft.floors[7],payload,models,7).find(e=>e.key===entry.key);
 const clip=ctx.exports.copyObject(draft.floors[7],fresh,payload,7),key=ctx.exports.pasteObject(draft.floors[7],clip,.25);
 assert.ok(ctx.exports.listEntries(draft.floors[7],payload,models,7).some(e=>e.key===key));
 checks.push('Same saved part key supports actual editor movement, rotation and isolated copying');
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,await response.text());
 checks.push('Shared desktop/VR save API validates the copied cube and edited poses');
 assert.equal(Buffer.compare(before,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);checks.push('Visitor arrangements are unchanged by this validation-only check');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Parse actual exported GLB and materials, actual editor model operations, shared layout API validation. Static preview; vertex interaction is native.'},null,2)+'\n');console.log(checks.length+' focused editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
