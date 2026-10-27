// Geometry/identity tests use the real Three.js builder. Canvas is only a material
// texture sink here; rendered appearance is inspected separately in the browser.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),THREE=require(path.join(web,'node_modules/three'));
const cache=new Map();
function load(file){
 if(cache.has(file))return cache.get(file);const exports={};cache.set(file,exports);
 const localRequire=name=>name.startsWith('.')?load(path.resolve(path.dirname(file),name+'.ts')):require(require.resolve(name,{paths:[web]}));
 const context={exports,require:localRequire,structuredClone,Date,console,document:{createElement:()=>({width:1,height:1,getContext:()=>({fillRect(){}})})}};
 vm.runInNewContext(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,context,{filename:file});return exports;
}
const {compileRecipe,applyCommand}=load(path.join(web,'src/lib/chains-futures.ts')),{Builder}=load(path.join(web,'src/lib/modular-terms.ts'));
const source=JSON.parse(fs.readFileSync(path.join(root,'commons/artifacts/chains_studies/futures.json'))),checks=[];
const studies=JSON.parse(fs.readFileSync(path.join(root,'commons/artifacts/chains_studies/beauty_studies.json'))).studies;
const check=(name,fn)=>{fn();checks.push({name,passed:true});};
for(const version of source.versions){
 check(version.id+': actual Three.js geometry and stable connection endpoints',()=>{
  const expr=compileRecipe(version.recipe),body=new Builder({}).build(expr);body.updateMatrixWorld(true);
  const kids=body.children.filter(c=>!c.userData.tie),ties=expr.ties;
  assert.equal(kids.length,version.recipe.of.parts.length);
  ties.forEach(([a,b],i)=>{assert.equal(kids[a].userData.partId,version.recipe.links[i].a);assert.equal(kids[b].userData.partId,version.recipe.links[i].b);});
  let meshes=0;body.traverse(n=>{if(n instanceof THREE.Mesh)meshes++;});assert.ok(meshes>=10);
  assert.ok(!new THREE.Box3().setFromObject(body).isEmpty());
 });
}
check('An inserted or reordered part cannot silently reconnect a tie',()=>{
 const r=structuredClone(source.versions[2].recipe),original=structuredClone(r.links);r.of.parts.reverse();
 const built=new Builder({}).build(compileRecipe(r));const kids=built.children.filter(c=>!c.userData.tie);
 compileRecipe(r).ties.forEach(([a,b],i)=>{assert.equal(kids[a].userData.partId,original[i].a);assert.equal(kids[b].userData.partId,original[i].b);});
 const duplicate=structuredClone(r);duplicate.of.parts[1].id=duplicate.of.parts[0].id;assert.throws(()=>compileRecipe(duplicate));
 r.links[0].a='absent';assert.throws(()=>compileRecipe(r));
});
check('The rendered body has an open entrance and an empty interior at eye height',()=>{
 const r=source.versions.find(v=>v.id==='room-within').recipe,body=new Builder({}).build(compileRecipe(r));body.updateMatrixWorld(true);
 const meshes=[];body.traverse(n=>{if(n instanceof THREE.Mesh)meshes.push(n);});
 const ray=new THREE.Raycaster(new THREE.Vector3(0,1.17,2),new THREE.Vector3(0,0,-1),0,2.35);
 assert.equal(ray.intersectObjects(meshes,false).length,0);
 const shell=r.of.parts.find(p=>p.id==='torso').of.parts;assert.ok(shell.length>200);
 assert.ok(shell.every(p=>p.of.parts.some(p=>p.p==='body')&&p.of.parts.some(p=>p.p==='collider')));
});
check('A declined offer preserves recipe and identities while recording refusal',()=>{
 const d=structuredClone(source),before=JSON.stringify(d.versions),relations=JSON.stringify(d.residents.lumen.relationships),cursor=d.cursor;
 applyCommand(d,{action:'offer'});assert.equal(d.cursor,cursor);assert.equal(JSON.stringify(d.versions),before);
 applyCommand(d,{action:'decline'});assert.equal(d.events.at(-1).outcome,'rejected');assert.equal(JSON.stringify(d.versions),before);assert.equal(JSON.stringify(d.residents.lumen.relationships),relations);
});
check('An accepted offer remains attached to the offered parent, even after replay',()=>{
 const d=structuredClone(source);applyCommand(d,{action:'offer'});applyCommand(d,{action:'select',version:'v-000'});applyCommand(d,{action:'accept'});
 assert.equal(d.versions.at(-1).parent,'room-within');assert.equal(d.events.at(-1).seed,d.versions.at(-1).seed);assert.ok(d.versions.at(-1).inhabitable);
});
check('Placement edit creates a branch; invalid placements preserve prior history',()=>{
 const d=structuredClone(source),r=JSON.stringify(d.versions[5]);applyCommand(d,{action:'edit',part:'head',at:[.15,3.02,0]});assert.equal(JSON.stringify(d.versions[5]),r);assert.equal(d.versions.at(-1).operation,'edit');
 const n=d.versions.length;assert.throws(()=>applyCommand(d,{action:'edit',part:'head',at:[99,0,0]}));assert.equal(d.versions.length,n);
});
check('History remains replayable at its growth limit',()=>{
 const d=structuredClone(source);while(d.versions.length<256)d.versions.push({...d.versions[0],id:'full-'+d.versions.length});
 applyCommand(d,{action:'select',version:'v-000'});assert.equal(d.cursor,'v-000');assert.throws(()=>applyCommand(d,{action:'branch'}));
});
const published=path.join(web,'public/void-trial-evidence/chains_studies'),nativeFolder=path.join(root,'commons/void/trials/chains_studies/evidence');
const evidenceFolder=fs.existsSync(path.join(published,'move-receipt.json'))?published:nativeFolder;
for(const study of studies)check(study.id+': real geometry, clear entrance, immutable branch and reload',()=>{
 const d=structuredClone(source),before=JSON.stringify(d.versions);
 applyCommand(d,{action:'study',study:study.id},studies);
 assert.equal(JSON.stringify(d.versions.slice(0,source.versions.length)),before);
 const v=d.versions.at(-1);assert.equal(v.parent,'room-within');assert.equal(v.label,study.label);assert.equal(d.events.at(-1).study,study.id);
 assert.ok(v.inhabitable);assert.equal(JSON.stringify(JSON.parse(JSON.stringify(d)).versions.at(-1).recipe),JSON.stringify(study.recipe));
 const body=new Builder({}).build(compileRecipe(v.recipe));body.updateMatrixWorld(true);
 const meshes=[];body.traverse(n=>{if(n instanceof THREE.Mesh&&!n.userData.collider)meshes.push(n);});
 assert.ok(meshes.length>100);assert.ok(new THREE.Box3().setFromObject(body).max.y<4.1);
 const ray=new THREE.Raycaster(new THREE.Vector3(0,1.17,2),new THREE.Vector3(0,0,-1),0,2.35);assert.equal(ray.intersectObjects(meshes,false).length,0);
});
check('Unknown study cannot mutate versions or decisions',()=>{
 const d=structuredClone(source),before=JSON.stringify(d);assert.throws(()=>applyCommand(d,{action:'study',study:'missing'},studies));assert.equal(JSON.stringify(d),before);
});
if(process.argv.includes('--beauty-native'))check('All three new branches have identical Godot and web history',()=>{
 const d=structuredClone(source);for(const study of studies)for(const command of [{action:'select',version:'room-within'},{action:'study',study:study.id}]){applyCommand(d,command,studies);d.revision++;}
 const saved=JSON.parse(fs.readFileSync(path.join(nativeFolder,'debug/beauty-studies-both/beauty-history-false.json')));
 const clean=x=>{x=structuredClone(x);x.events.forEach(e=>delete e.time);return JSON.parse(JSON.stringify(x));};assert.deepEqual(clean(d),clean(saved));
});
const native=fs.existsSync(path.join(nativeFolder,'futures-test-false.json'))?path.join(nativeFolder,'futures-test-false.json'):path.join(evidenceFolder,'futures-test-false.json');
if(process.argv.includes('--native'))check('Godot and web produce the same saved branching history',()=>{
 const d=structuredClone(source);for(const command of [{action:'select',version:'v-000'},{action:'branch'},{action:'parent'},{action:'branch'},{action:'select',version:'v-002'},{action:'offer'},{action:'decline'},{action:'offer'},{action:'accept'},{action:'select',version:'room-within'}]){applyCommand(d,command);d.revision++;}
 const clean=x=>{x=structuredClone(x);x.events.forEach(e=>delete e.time);return JSON.parse(JSON.stringify(x));};assert.deepEqual(clean(d),clean(JSON.parse(fs.readFileSync(native))));
});
fs.writeFileSync(path.join(evidenceFolder,process.argv.includes('--beauty-native')?'beauty-web-checks.json':'futures-web-checks.json'),JSON.stringify({passed:true,checks,scope:'Actual Three.js geometry and bounded graph operations; optional comparison with native saved graph. No rendered appearance or physical-headset claim.'},null,2)+'\n');
console.log(checks.length+' body-future checks passed');
