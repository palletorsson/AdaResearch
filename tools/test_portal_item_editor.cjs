// Verify shared compiler, native member poses and the actual editor save contract.
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),trial=process.argv[2];assert(/^portal_item_[a-f0-9]{10}$/.test(trial));
const out=path.join(root,'ada_run/portal-lab',trial),ts=require(path.join(web,'node_modules/typescript'));
require.extensions['.ts']=(m,f)=>m._compile(ts.transpileModule(fs.readFileSync(f,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,esModuleInterop:true,target:ts.ScriptTarget.ES2022}}).outputText,f);
const model=require(path.join(web,'src/components/lab-editor/void-model.ts')),store=require(path.join(web,'src/lib/void-layout-store.ts')),THREE=require(path.join(web,'node_modules/three'));
global.document={createElement:()=>({getContext:()=>({measureText:t=>({width:t.length*16}),scale(){},fillRect(){},fillText(){}})})};
const {Builder}=require(path.join(web,'src/lib/modular-terms.ts'));
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
async function main(){
 const native=read(path.join(out,'checks.json')),compiled=read(path.join(root,'commons/void/trials',trial,'recipe.json')),terms=read(path.join(root,'commons/modular/terms.json')).terms,checks=[];assert(native.passed);
 const built=new Builder({...terms,portal_lab_item:compiled.term}).build({t:'portal_lab_item'});built.updateMatrixWorld(true);
 for(const [id,part] of Object.entries(native.metrics.parts)){
  const child=built.getObjectByName(id);assert(child,id);const position=new THREE.Vector3(),rotation=new THREE.Quaternion(),scale=new THREE.Vector3();child.matrixWorld.decompose(position,rotation,scale);assert(position.distanceTo(new THREE.Vector3(...part.position))<1e-4,id+' translation');const q=new THREE.Quaternion().setFromEuler(new THREE.Euler(...part.rotation.map(v=>v*Math.PI/180),'YXZ'));assert(Math.abs(q.dot(rotation))>1-1e-6,id+' rotation');
 }
 checks.push('Shared Three.js/native compiler agrees on every independent member pose');
 const url='http://localhost:3003/api/void-layout?trial='+trial,p=await(await fetch(url,{signal:AbortSignal.timeout(60000)})).json();assert(p.rooms,JSON.stringify(p));
 const manifest=read(path.join(web,'public',p.models)),draft=structuredClone(p.rooms),entries=model.listEntries(draft.floors[1],p,manifest,1);let selected;
 for(const [id,part] of Object.entries(manifest.floors['1'].artifacts['portal-item'].parts)){
  const entry=entries.find(e=>e.kind==='part'&&e.artifactId==='portal-item'&&e.id===id);assert(entry,id+' editor entry');const b=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert.equal(b.readUInt32LE(8),b.length);const gltf=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString().trim());assert(gltf.meshes.length>0,id+' real geometry');if(id==='Portal12')selected=entry;
 }
 checks.push('Every saved native piece has a real parsed GLB and independent editor entry');assert(selected);
 model.place(draft.floors[1],selected,[selected.position[0]+.2,selected.position[1],selected.position[2]],p);model.turn(draft.floors[1],selected);model.pasteObject(draft.floors[1],model.copyObject(draft.floors[1],selected,p,1),.4);assert.deepEqual(draft.floors[1].copies.at(-1).config.only_parts,['Portal12']);
 const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:p.revision,validateOnly:true}),signal:AbortSignal.timeout(60000)}),validation=await response.json();assert.equal(response.status,200,JSON.stringify(validation));assert(validation.valid);checks.push('Independent move, rotation and copy pass the live editor save validator');
 const fixture=fs.mkdtempSync(path.join(out,'editor-fixture-')),dir=path.join(fixture,'commons/void');fs.mkdirSync(path.join(dir,'trials',trial),{recursive:true});fs.copyFileSync(path.join(root,'commons/void/trials/playable.json'),path.join(dir,'trials/playable.json'));const file=path.join(dir,'trials',trial,'rooms.json'),raw=JSON.stringify(p.rooms)+'\n';fs.writeFileSync(file,raw);store.saveLayout(fixture,draft,store.layoutRevision(raw),path.join(fixture,'Desktop'),trial);assert.deepEqual(read(file),draft);assert.deepEqual(read(path.join(fixture,'Desktop/trials',trial,'rooms.json')),draft);assert.throws(()=>store.saveLayout(fixture,p.rooms,'stale',path.join(fixture,'Desktop'),trial),store.LayoutConflict);checks.push('Save/reload and desktop mirror retain the edited members; stale saves reject');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));console.log(checks.join('\n'));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
