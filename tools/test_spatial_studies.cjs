// Compare native receipts against Three.js and exercise the real editor save contract.
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),out=path.join(root,'ada_run/spatial-studies-2026-11-13');
const ts=require(path.join(web,'node_modules/typescript')),Module=require('module'),resolve=Module._resolveFilename;
Module._resolveFilename=function(request,parent,...rest){return resolve.call(this,request.startsWith('@/')?path.join(web,'src',request.slice(2)):request,parent,...rest);};
require.extensions['.ts']=(m,f)=>m._compile(ts.transpileModule(fs.readFileSync(f,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,esModuleInterop:true,target:ts.ScriptTarget.ES2022}}).outputText,f);
const THREE=require(path.join(web,'node_modules/three'));
global.document={createElement:()=>({getContext:()=>({measureText:t=>({width:t.length*16}),scale(){},fillRect(){},fillText(){}})})};
const {Builder}=require(path.join(web,'src/lib/modular-terms.ts')),{spatialStudy}=require(path.join(web,'src/lib/spatial-studies.ts'));
const model=require(path.join(web,'src/components/lab-editor/void-model.ts'));
const {saveLayout,layoutRevision,LayoutConflict}=require(path.join(web,'src/lib/void-layout-store.ts'));
const read=f=>JSON.parse(fs.readFileSync(f,'utf8'));
async function main(){
 const checks=[],refs=read(path.join(out,'references.json')),terms=read(path.join(root,'commons/modular/terms.json')).terms,spec=read(path.join(root,'commons/modular/lab.json'));
 for(const r of spec.recipes.filter(r=>r.kind)){
  for(const [key,range] of Object.entries(r.limits))for(const value of range){
   const e=spatialStudy({kind:r.kind,...r.defaults,[key]:value});assert(e.parts.length>0&&e.parts.length<=(r.id==='lab_sphere_fractal'?156:r.id==='lab_fractal_assembly'?147:81));assert.equal(new Set(e.parts.map(p=>p.id)).size,e.parts.length);
   for(const p of e.parts){assert(p.at.every(Number.isFinite));assert(p.rot.every(Number.isFinite));assert(p.of.fit_box.every(v=>Number.isFinite(v)&&v>0));}
  }
 }
 checks.push('Every control boundary creates bounded, uniquely named finite parts with positive dimensions');
 const random=spec.recipes.find(r=>r.id==='lab_seeded_field');const a=spatialStudy({kind:'random',...random.defaults});assert.deepEqual(a,spatialStudy({kind:'random',...random.defaults}));assert.notDeepEqual(a,spatialStudy({kind:'random',...random.defaults,seed:53}));
 const sparse=spatialStudy({kind:'random',...random.defaults,missing:.6});for(const p of sparse.parts)assert.deepEqual(p,a.parts.find(q=>q.id===p.id));
 checks.push('Seeds reproduce exactly; omissions retain surviving positions; another seed changes the field');
 const tree=spec.recipes.find(r=>r.id==='lab_branching');for(let depth=0;depth<=5;depth++)assert.equal(spatialStudy({kind:'tree',...tree.defaults,depth}).parts.length,2**(depth+1)-1);
 checks.push('The binary branching rule produces 1, 3, 7, 15, 31 and 63 editable beams');
 for(const [recipe,ref] of Object.entries(refs).filter(([id])=>process.argv.length<3||id.startsWith(process.argv[2]))){
  const dir=path.join(root,'ada_run/spatial-lab-2026-10-27',ref.trial),receipt=read(path.join(dir,'checks.json'));assert(receipt.passed);
  for(const pose of receipt.poses){const object=new Builder(terms).build({t:pose.recipe,with:pose.bindings});object.updateMatrixWorld(true);
   for(const p of pose.parts){if(['lab_fractal_assembly','lab_sphere_fractal'].includes(pose.recipe)){const expr=spatialStudy({kind:spec.recipes.find(r=>r.id===pose.recipe).kind,...pose.bindings});assert.equal(p.source,expr.parts.find(q=>q.id===p.id).of.token);}const child=object.getObjectByName(p.id);assert(child,p.id);const pos=new THREE.Vector3(),q=new THREE.Quaternion(),s=new THREE.Vector3();child.matrixWorld.decompose(pos,q,s);assert(pos.distanceTo(new THREE.Vector3(...p.position))<.00003,recipe+'/'+p.id+' position');const expected=new THREE.Quaternion().setFromEuler(new THREE.Euler(...p.rotation.map(v=>v*Math.PI/180),'YXZ'));assert(q.angleTo(expected)<.00003,recipe+'/'+p.id+' rotation');}
  }
  const url='http://localhost:3003/api/void-layout?trial='+ref.trial,payload=await(await fetch(url)).json();assert(payload.rooms,JSON.stringify(payload));const manifest=read(path.join(web,'public',payload.models));
  const entries=model.listEntries(payload.rooms.floors[1],payload,manifest,1).filter(e=>e.kind==='part'&&e.artifactId==='variation');assert.equal(entries.length,receipt.poses[0].parts.length);
  for(const e of entries){const b=fs.readFileSync(path.join(web,'public',e.model.url));assert.equal(b.readUInt32LE(0),0x46546c67);assert(JSON.parse(b.subarray(20,20+b.readUInt32LE(12))).meshes.length);}
  const draft=structuredClone(payload.rooms),floor=draft.floors[1],part=entries[0];model.place(floor,part,[part.position[0]+.2,part.position[1],part.position[2]],payload);model.turn(floor,part);model.pasteObject(floor,model.copyObject(floor,part,payload,1),.4);
  assert.deepEqual(floor.copies.at(-1).config.only_parts,[part.id]);
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});assert.equal(response.status,200,await response.text());
  const fixture=fs.mkdtempSync(path.join(out,'save-fixture-')),td=path.join(fixture,'commons/void/trials',ref.trial);fs.mkdirSync(td,{recursive:true});fs.copyFileSync(path.join(root,'commons/void/trials/playable.json'),path.join(fixture,'commons/void/trials/playable.json'));const raw=JSON.stringify(payload.rooms)+'\n';fs.writeFileSync(path.join(td,'rooms.json'),raw);saveLayout(fixture,draft,layoutRevision(raw),path.join(fixture,'Desktop'),ref.trial);assert.deepEqual(read(path.join(td,'rooms.json')),draft);assert.deepEqual(read(path.join(fixture,'Desktop/trials',ref.trial,'rooms.json')),draft);assert.throws(()=>saveLayout(fixture,draft,'stale',path.join(fixture,'Desktop'),ref.trial),LayoutConflict);
  checks.push(recipe+': native/Web poses, all exported member GLBs, independent move/rotate/copy and save/reload pass');
 }
 const mixed=spec.recipes.find(r=>r.id==='lab_fractal_assembly');
 for(let depth=0;depth<=3;depth++)for(let branches=1;branches<=3;branches++){const e=spatialStudy({kind:mixed.kind,...mixed.defaults,depth,branches});let nodes=0;for(let i=0;i<=depth;i++)nodes+=branches**i;assert.equal(e.parts.length,nodes*3+branches**depth);assert.equal(new Set(e.parts.map(p=>p.of.token)).size,4);}
 const original=spatialStudy({kind:mixed.kind,...mixed.defaults}),swap=spatialStudy({kind:mixed.kind,...mixed.defaults,tip_source:'trace_point_ball'});for(let i=0;i<original.parts.length;i++){assert.deepEqual(original.parts[i].at,swap.parts[i].at);assert.equal(swap.parts[i].of.token,original.parts[i].id.endsWith('_Tip')?'trace_point_ball':original.parts[i].of.token);}
 checks.push('Mixed recursion counts, four distinct roles and isolated prefab replacement preserve the grammar');
 const sphere=spec.recipes.find(r=>r.id==='lab_sphere_fractal');
 for(let depth=1;depth<=4;depth++)assert.equal(spatialStudy({kind:sphere.kind,...sphere.defaults,depth}).parts.length,(5**depth-1)/4);
 const spherePose=spatialStudy({kind:sphere.kind,...sphere.defaults,phase:7.13}),sphereSwap=spatialStudy({kind:sphere.kind,...sphere.defaults,phase:7.13,inner_source:'traffic_pyramid_5',tip_source:'pentagonal_bipyramid_7'});
 assert.deepEqual(spherePose,spatialStudy({kind:sphere.kind,...sphere.defaults,phase:7.13}));assert.notDeepEqual(spherePose,spatialStudy({kind:sphere.kind,...sphere.defaults,phase:0}));
 for(let i=0;i<spherePose.parts.length;i++){assert.deepEqual(spherePose.parts[i].at,sphereSwap.parts[i].at);assert.deepEqual(spherePose.parts[i].rot,sphereSwap.parts[i].rot);}
 const crystal=spatialStudy({kind:sphere.kind,...sphere.defaults,sag:0,speed:0,depth:2,size:1});assert.deepEqual(crystal.parts[0].at,[0,1,0]);const first=[[0,1.75,0],[-.75,1,0],[.75,1,0],[0,1,.75],[0,1,-.75]];for(let i=0;i<5;i++)assert(new THREE.Vector3(...crystal.parts[i+1].at).distanceTo(new THREE.Vector3(...first[i]))<1e-10);
 checks.push('Sphere recursion: 1/6/31/156 parts, source-axis directions, deterministic motion and interchangeable role geometry');
 const api=await(await fetch('http://localhost:3003/api/spatial-lab')).json();assert.deepEqual(api.spec.sequences.map(s=>s.id),['transformation','array','fractals','randomness']);
 for(const [recipe,bindings] of [['lab_sphere_fractal',{depth:4.5}],['lab_sphere_fractal',{phase:61}],['lab_sphere_fractal',{inner_source:'not_a_prefab'}],['lab_fractal_assembly',{branches:2.5}],['lab_fractal_assembly',{tip_source:'not_a_prefab'}],['lab_fractal_assembly',{joint_source:'crate'}],['lab_branching',{depth:1.5}],['lab_seeded_field',{seed:1.4}],['lab_thresholds',{source:'trace_point_ball'}]]){const r=await fetch('http://localhost:3003/api/spatial-lab',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({recipe,bindings,recipe_hash:api.hashes[recipe]})});assert.equal(r.status,400);}
 checks.push('Four lab sequence areas are served; invalid generations, seeds and incompatible sources reject');
 fs.writeFileSync(path.join(out,'editor-checks.json'),JSON.stringify({passed:true,checks},null,2));console.log(checks.join('\n'));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
