// Validate individual arrangement in the real editor model and save API.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const trial=process.argv[2]||'shaders',folder=path.join(root,'commons/void/trials',trial);
const ts=require(path.join(web,'node_modules/typescript')),ctx={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const {listEntries,copyObject,pasteObject,place,turn}=ctx.exports;
async function main(){
 const url='http://localhost:3003/api/void-layout?trial='+trial,headers={'Content-Type':'application/json',Origin:'http://localhost:3003'},checks=[];
 const p=await(await fetch(url)).json(),file=path.join(folder,'rooms.json');
 assert.equal(p.trial,trial);assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 const inventory=JSON.parse(fs.readFileSync(path.join(folder,'source-inventory.json')));
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials',trial,'manifest.json')));
 assert.deepEqual(models.failures,[]);
 for(let level=1;level<=inventory.maps.length;level++){
  assert.equal(p.rooms.floors[level].map,inventory.maps[level-1]);
  const entries=listEntries(p.rooms.floors[level],p,models,level).filter(e=>e.kind==='artifact');
  assert.equal(entries.length,inventory.placements.filter(e=>e.floor===level).length);
  for(const entry of entries){
   const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
   const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());assert.ok(gltf.meshes.length>0);
   const rooms=structuredClone(p.rooms),f=rooms.floors[level],key=pasteObject(f,copyObject(f,entry,p,level),0);
   let copy=listEntries(f,p,models,level).find(e=>e.key===key);place(f,copy,[16,0,4],p);turn(f,copy);
   copy=listEntries(f,p,models,level).find(e=>e.key===key);assert.notEqual(copy.key,entry.key);
   assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
   const response=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms,validateOnly:true})});assert.ok(response.ok,JSON.stringify(await response.json()));
   const dependencyMarker=(trial==='randomness_03'&&['f2_remove_random_1_2','f2_pickup_cube_placer_1_3'].includes(entry.id))||(trial==='randomness_04'&&entry.id==='f2_Random_Rotate_Random_XYZ_3_10')||models.floors[String(level)]?.artifacts?.[entry.id]?.preview_kind==='missing_dependency_arrangement_marker';
   const emptySampleMarker=models.floors[String(level)]?.artifacts?.[entry.id]?.preview_kind==='empty_sample_arrangement_marker';
   const nonvisualMarker=models.floors[String(level)]?.artifacts?.[entry.id]?.preview_kind==='nonvisual_source_setup_marker';
   const geometryLabel=nonvisualMarker?'declared nonvisual source setup marker':dependencyMarker?'declared dependency marker':(emptySampleMarker?'empty source display arrangement marker':(['wavefunctions_02','wavefunctions_03','wavefunctions_04'].includes(trial)&&entry.id.includes('BigPipeSystem')?'unbuilt-source editor marker':'real geometry'));
   checks.push({name:entry.id+': '+geometryLabel+'; independent move, copy and rotation',passed:true});
  }
 }
 const moved=structuredClone(p.rooms);moved.floors[1].artifacts[0].position[0]+=.25;
 const save=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:p.revision})}),receipt=await save.json();assert.ok(save.ok&&receipt.saved,JSON.stringify(receipt));
 try{
  assert.deepEqual((await(await fetch(url)).json()).rooms,moved);assert.deepEqual(JSON.parse(fs.readFileSync(file)),moved);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join('C:/Users/palle/Desktop/Ada Void/trials',trial,'rooms.json'))),moved);
  checks.push({name:'Save/reload reaches native layout and Desktop mirror',passed:true});
  const stale=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:moved,revision:'stale-transfer-check'})});assert.equal(stale.status,409);
  checks.push({name:'Stale save rejected',passed:true});
 }finally{
  const restore=await fetch(url,{method:'POST',headers,body:JSON.stringify({rooms:p.rooms,revision:receipt.revision})});assert.ok(restore.ok,'New user edit: do not overwrite');
 }
 for(const [file,digest] of Object.entries(inventory.preserved_sources))assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),digest,file);
 checks.push({name:'All source map and chapter hashes unchanged',passed:true});
 // API serializes JSON. Verify semantic restoration before refreshing the manifest hash.
 assert.deepEqual(JSON.parse(fs.readFileSync(file)),p.rooms);
 const manifestFile=path.join(web,'public/void-trials',trial,'manifest.json');
 models.source_files['commons/void/trials/'+trial+'/rooms.json']=crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
 fs.writeFileSync(manifestFile,JSON.stringify(models,null,2)+'\n');
 fs.mkdirSync(path.join(folder,'evidence'),{recursive:true});fs.writeFileSync(path.join(folder,'evidence/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
 console.log(checks.length+' '+trial+' editor checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
