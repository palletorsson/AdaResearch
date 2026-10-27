// Exercise actual editor part operations and save validation after the move.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/generated-storage-migration');
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,ctx);
async function run(){
 const saved=fs.readFileSync(path.join(root,'commons/void/rooms.json')),payload=await(await fetch('http://localhost:3003/api/void-layout')).json();
 const models=await(await fetch('http://localhost:3003/void-models/manifest.json',{cache:'no-store'})).json(),draft=structuredClone(payload.rooms),checks=[];
 const source=models.floors['7'].artifacts['matter-and'];assert.ok(source.parts.Tabletop&&source.parts.InputX);checks.push('Lab editor loads the actual native part manifest through the unchanged HTTP URL');
 const resolved=fs.realpathSync(path.join(web,'public',source.parts.Tabletop.url));assert.match(resolved.replaceAll('\\','/'),/^D:\/AdaGenerated\/AdaResearch_46\//i);
 assert.equal(fs.readFileSync(resolved).readUInt32LE(0),0x46546c67);checks.push('The real tabletop preview is physically on D:');
 for(const name of ['Tabletop','InputX','BallRelease']){
  const entry=ctx.exports.listEntries(draft.floors[7],payload,models,7).find(e=>e.kind==='part'&&e.artifactId==='matter-and'&&e.id===name);assert.ok(entry,name);
  ctx.exports.place(draft.floors[7],entry,[entry.position[0]+.01,entry.position[1],entry.position[2]],payload);ctx.exports.turn(draft.floors[7],entry);
  const fresh=ctx.exports.listEntries(draft.floors[7],payload,models,7).find(e=>e.key===entry.key);
  assert.ok(ctx.exports.pasteObject(draft.floors[7],ctx.exports.copyObject(draft.floors[7],fresh,payload,7),.1));
 }
 checks.push('Actual editor move/rotate/copy operations retain independent parts after relocation');
 const response=await fetch('http://localhost:3003/api/void-layout',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,validateOnly:true})});assert.ok(response.ok,(await response.text()).slice(0,500));
 assert.equal(Buffer.compare(saved,fs.readFileSync(path.join(root,'commons/void/rooms.json'))),0);checks.push('Shared desktop/VR save contract validates the edits without altering the user layout');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2)+'\n');console.log(checks.length+' editor storage checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
