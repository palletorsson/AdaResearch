const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await(await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const metadata=JSON.parse(fs.readFileSync(path.join(root,'commons/void/line_parts.json'),'utf8'));
 const {listEntries,place,turn,copyObject,pasteObject}=context.exports;
 const draft=structuredClone(payload.rooms),floor=draft.floors[11],checks=[];
 const entries=listEntries(floor,payload,models,11).filter(e=>e.artifactId==='sky-walk');
 function check(name,fn){fn();checks.push({name,passed:true});}
 function glb(model){const b=fs.readFileSync(path.join(web,'public',model.url));assert.equal(b.readUInt32LE(0),0x46546c67);return JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString().trim());}
 check('static span has 14 editable parts and no transport or docking boxes',()=>{
  assert.equal(entries.length,14);assert.ok(entries.some(e=>e.id==='ShaftBridge1'));
  for(const id of ['MovingPlatform','WestDock1','WestDock2','EastDock1','EastDock2']){
   assert.ok(!entries.some(e=>e.id===id));assert.ok(!metadata.void_portal_span[id]);
  }
 });
 check('actual GLB has twenty translucent pink rings at unit scale and 3 m intervals',()=>{
  const rings=entries.find(e=>e.id==='RefinementPassage'),g=glb(rings.model);
  const pink=new Set(g.materials.map((m,i)=>({m,i})).filter(({m})=>{
   const c=m.pbrMetallicRoughness?.baseColorFactor||[1,1,1,1];
   return c[0]>.9&&c[1]<.4&&c[2]>.1&&c[2]<.8&&m.alphaMode==='BLEND'&&c[3]>.7&&c[3]<.85;
  }).map(({i})=>i));
  const meshes=new Set(g.meshes.map((m,i)=>({m,i})).filter(({m})=>m.primitives.some(p=>pink.has(p.material))).map(({i})=>i));
  const nodes=g.nodes.filter(n=>meshes.has(n.mesh));assert.equal(nodes.length,20);
  for(const n of nodes)assert.ok((n.scale||[1,1,1]).every(s=>Math.abs(s-1)<1e-4));
  const z=nodes.map(n=>n.translation?.[2]||0).sort((a,b)=>a-b);
  for(let i=1;i<z.length;i++)assert.ok(Math.abs(z[i]-z[i-1]-3)<1e-3);
  assert.ok(metadata.void_portal_span.RefinementPassage.bounds[4]>3.9&&metadata.void_portal_span.RefinementPassage.bounds[4]<4.1);
 });
 check('lookout, arrivals and static bridge have actual exported models',()=>{
  for(const id of ['ShaftBridge1','ShaftBridge2','EastSpan1','SkyLookout','StrangeArrivals'])assert.ok(glb(entries.find(e=>e.id===id).model).meshes.length>0);
  assert.equal(entries.find(e=>e.id==='SkyLookout').position[0],40.5);
  assert.equal(entries.find(e=>e.id==='StrangeArrivals').position[0],38.5);
 });
 for(const id of ['ShaftBridge1','RefinementPassage','SkyLookout']){
  let entry=listEntries(floor,payload,models,11).find(e=>e.artifactId==='sky-walk'&&e.id===id);
  const key=pasteObject(floor,copyObject(floor,entry,payload,11),3);
  let copy=listEntries(floor,payload,models,11).find(e=>e.key===key);
  place(floor,copy,[0,copy.position[1],4],payload);
  copy=listEntries(floor,payload,models,11).find(e=>e.key===key);const yaw=copy.rotation[1];turn(floor,copy);
  copy=listEntries(floor,payload,models,11).find(e=>e.key===key);
  check(id+': independent copy/move/turn',()=>{assert.equal(copy.id,id);assert.equal(copy.position[0],0);assert.equal(copy.rotation[1],(yaw+90)%360);});
 }
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});
 const result=await response.json();
 check('production save validation accepts edited bridge/ring copies',()=>assert.ok(response.ok&&result.valid,JSON.stringify(result)));
 check('palette span uses refreshed real geometry and thumbnail',()=>{assert.ok(glb(models.props.portal_span).meshes.length>100);assert.ok(fs.existsSync(path.join(web,'public',models.props.portal_span.thumbnail)));});
 check('test edits never replace the shared native and Desktop layout',()=>{
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'),'utf8')),payload.rooms);
  assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8')),payload.rooms);
 });
 fs.writeFileSync(path.join(root,'ada_run/portals-static-pink/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
