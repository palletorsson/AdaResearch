// Exercise the real editor operations on a cloned draft; never save test objects.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await (await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const index=payload.rooms.floors.findIndex(f=>f.map==='Primitives_Portals'),floor=payload.rooms.floors[index],checks=[];
 const entry=listEntries(floor,payload,models,index).find(e=>e.artifactId==='sky-walk'&&e.id==='StrangeArrivals');
 assert.ok(entry);assert.match(entry.label,/Portal arrivals.*skull/);
 checks.push({name:'Named arrival part appears on the Portals floor',passed:true});
 const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
 const model=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString().trim());
 assert.ok(model.meshes.length>=17,'Baked skull and its separate teeth');assert.equal(entry.model.lights.length,1);
 checks.push({name:'Actual skull geometry and pink light exported',passed:true});
 const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
 Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
 const key=pasteObject(destination,copyObject(floor,entry,payload,index),0);
 let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
 assert.equal(copy.model.url,entry.model.url);
 place(destination,copy,[0,1,4],payload);turn(destination,copy);
 copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
 assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],90);
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
 const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
 checks.push({name:'Copy, move and quarter-turn produce a schema-valid draft',passed:true});
 assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'))),payload.rooms);
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json')),payload.rooms);
 checks.push({name:'Editor, desktop backup and Godot use the same unchanged layout',passed:true});
 fs.writeFileSync(path.join(root,'doc/book/iterations/2026-10-19-portal-arrivals/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
