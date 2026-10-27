// Verify the bridge between two builders, actual exported members and editor saves.
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/s-descent-boolean-2026-10-27');
const ts=require(path.join(web,'node_modules/typescript'));
require.extensions['.ts']=(module,file)=>module._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,esModuleInterop:true,target:ts.ScriptTarget.ES2022}}).outputText,file);
const model=require(path.join(web,'src/components/lab-editor/void-model.ts'));
const {saveLayout,layoutRevision,LayoutConflict}=require(path.join(web,'src/lib/void-layout-store.ts'));
const THREE=require(path.join(web,'node_modules/three'));
// No renderer or source geometry is replaced here: the tiny canvas stub only
// lets the expression builder create its labels while checking transform data.
global.document={createElement:()=>({getContext:()=>({measureText:t=>({width:t.length*16}),scale(){},fillRect(){},fillText(){}})})};
const {Builder}=require(path.join(web,'src/lib/modular-terms.ts'));
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const hash=file=>require('crypto').createHash('sha256').update(fs.readFileSync(file)).digest('hex');
async function main(){
 const checks=[],before=hash(path.join(root,'commons/void/rooms.json')),terms=read(path.join(root,'commons/modular/terms.json')).terms;
 const trial='s_descent_boolean',url='http://localhost:3003/api/void-layout?trial='+trial;
 const p=await(await fetch(url,{signal:AbortSignal.timeout(60000)})).json();assert(p.rooms,JSON.stringify(p));
 const manifest=read(path.join(web,'public',p.models)),draft=structuredClone(p.rooms),saved=JSON.stringify(p.rooms);
 const native=read(path.join(out,'checks.json'));assert(native.passed);
 const object=new Builder(terms).build({t:'boolean_s_descent_model',with:{model_scale:.1,yaw:18,passage_width:1.6,headroom:2.8,wall:.35,xray:true}});object.updateMatrixWorld(true);
 for(const [id,part] of Object.entries(native.metrics.parts)){
  const child=object.getObjectByName(id);assert(child,id);
  const position=new THREE.Vector3(),rotation=new THREE.Quaternion(),scale=new THREE.Vector3();child.matrixWorld.decompose(position,rotation,scale);
  assert(position.distanceTo(new THREE.Vector3(...part.position))<1e-5,id+' translation parity');
  const q=new THREE.Quaternion().setFromEuler(new THREE.Euler(...part.rotation.map(v=>v*Math.PI/180)));
  assert(Math.abs(rotation.dot(q))>1-1e-6,id+' rotation parity');
  if(/RouteTrace|ContinuousPassage/.test(id)){
   const frame=new THREE.Matrix4().compose(position,q,new THREE.Vector3(1,1,1)).invert();const box=new THREE.Box3();
   child.traverse(mesh=>{if(!mesh.isMesh)return;const attr=mesh.geometry.getAttribute('position');for(let i=0;i<attr.count;i++)box.expandByPoint(new THREE.Vector3().fromBufferAttribute(attr,i).applyMatrix4(mesh.matrixWorld).applyMatrix4(frame));});
   const expected=new THREE.Box3(new THREE.Vector3(...part.bounds.slice(0,3)),new THREE.Vector3(...part.bounds.slice(0,3)).add(new THREE.Vector3(...part.bounds.slice(3))));
   assert(box.min.distanceTo(expected.min)<1e-4&&box.max.distanceTo(expected.max)<1e-4,id+' swept geometry bounds parity');
  }
 }
 checks.push('Three.js and Godot agree on all 8 member poses and passage/trace geometry bounds');
  let lastPart,lastFloor;
  for(const [floorIndex,record] of Object.entries(manifest.floors)){
   const i=Number(floorIndex),floor=draft.floors[i];const entries=model.listEntries(floor,p,manifest,i);
   for(const [id,artifact] of Object.entries(record.artifacts))for(const name of Object.keys(artifact.parts)){
    const entry=entries.find(e=>e.kind==='part'&&e.id===name&&e.artifactId===id);assert(entry,id+'/'+name+' editable');assert(entry.model.url);
    const b=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);assert(readGltf(b).meshes.length>0);
    if(name==='ContinuousPassage'){lastPart=entry;lastFloor=i;}
   }
  }
  checks.push(trial+': every exported member has real GLB geometry and an independent editor entry');
  assert(lastPart);const floor=draft.floors[lastFloor];model.place(floor,lastPart,[lastPart.position[0]+.2,lastPart.position[1],lastPart.position[2]],p);model.turn(floor,lastPart);
  model.pasteObject(floor,model.copyObject(floor,lastPart,p,lastFloor),.4);assert.deepEqual(floor.copies.at(-1).config.only_parts,[lastPart.id]);
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:p.revision,validateOnly:true}),signal:AbortSignal.timeout(60000)});const report=await response.json();assert.equal(response.status,200,JSON.stringify(report));assert(report.valid);
  checks.push(trial+': independent move, rotate and copy pass the real save API validator');
  const fixture=fs.mkdtempSync(path.join(out,'editor-fixture-')),dir=path.join(fixture,'commons/void');fs.mkdirSync(path.join(dir,'trials',trial),{recursive:true});fs.copyFileSync(path.join(root,'commons/void/trials/playable.json'),path.join(dir,'trials/playable.json'));
  const file=path.join(dir,'trials',trial,'rooms.json'),raw=JSON.stringify(p.rooms)+'\n';fs.writeFileSync(file,raw);
  saveLayout(fixture,draft,layoutRevision(raw),path.join(fixture,'Desktop'),trial);assert.deepEqual(read(file),draft);assert.deepEqual(read(path.join(fixture,'Desktop/trials',trial,'rooms.json')),draft);assert.throws(()=>saveLayout(fixture,p.rooms,'stale',path.join(fixture,'Desktop'),trial),LayoutConflict);
  checks.push(trial+': save/reload, Desktop mirror and stale-save conflict pass in an isolated fixture');
  assert.equal(JSON.stringify((await(await fetch(url)).json()).rooms),saved);
 assert.equal(hash(path.join(root,'commons/void/rooms.json')),before);checks.push('Main tower and actual saved user arrangements were untouched');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));console.log(checks.join('\n'));
}
function readGltf(b){return JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString().trim());}
main().catch(e=>{console.error(e);process.exitCode=1;});
