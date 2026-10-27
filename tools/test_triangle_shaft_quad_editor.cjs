const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
async function main(){
  const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const {listEntries,place,turn,copyObject,pasteObject}=context.exports;
  const draft=structuredClone(payload.rooms),floor=draft.floors[5],checks=[];
  function check(name,fn){fn();checks.push({name,passed:true});}
  let entries=listEntries(floor,payload,models,5);
  const quad=entries.find(e=>e.kind==='part'&&e.artifactId==='surfaces'&&e.id==='ShaftQuad');
  check('quad is an independent editor part over shaft A',()=>{
    assert.ok(quad);assert.ok(Math.abs(quad.position[0]+10)<.01);
    assert.ok(Math.abs(quad.position[1]+1.65)<.01);assert.equal(Math.round(quad.rotation[0]),-25);
    assert.ok(fs.statSync(path.join(web,'public',quad.model.url)).size>10000);
  });
  check('native part metadata permits saved quad placement',()=>{
    const parts=JSON.parse(fs.readFileSync(path.join(root,'commons/void/line_parts.json'),'utf8'));
    assert.ok(parts.void_triangle_surfaces.ShaftQuad);
  });
  check('real GLB embeds the construction wood texture',()=>{
    const bytes=fs.readFileSync(path.join(web,'public',quad.model.url));
    const glb=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString('utf8').trim());
    assert.ok(glb.images?.some(image=>image.bufferView!==undefined));
    assert.ok(glb.materials.some(material=>material.pbrMetallicRoughness?.baseColorTexture));
    assert.ok(glb.meshes.length>=10);
  });
  place(floor,quad,[quad.position[0]+.25,quad.position[1],quad.position[2]],payload);
  entries=listEntries(floor,payload,models,5);
  turn(floor,entries.find(e=>e.key===quad.key));
  const moved=listEntries(floor,payload,models,5).find(e=>e.key===quad.key);
  check('move and turn retain the tilt',()=>{assert.equal(moved.rotation[0],quad.rotation[0]);assert.equal(moved.rotation[1],quad.rotation[1]+90);});
  const key=pasteObject(floor,copyObject(floor,moved,payload,5),3);
  check('copy isolates one complete quad',()=>{
    const copy=listEntries(floor,payload,models,5).find(e=>e.key===key);
    assert.equal(copy.id,'ShaftQuad');assert.notEqual(copy.artifactId,'surfaces');
  });
  const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});
  const validation=await response.json();
  check('production save validation accepts moved/rotated copy',()=>assert.equal(validation.valid,true,JSON.stringify(validation)));
  check('test draft never replaces shared layout; Desktop mirror matches',()=>{
    assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'),'utf8')),payload.rooms);
    assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8')),payload.rooms);
  });
  fs.writeFileSync(path.join(root,'ada_run/triangle-shaft-quad/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
  console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
