const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const sandbox={exports:{},require,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,sandbox);
const {listEntries,copyObject,pasteObject,place,turn,withSharedPalette}=sandbox.exports;
const checks=[];const url='http://localhost:3003/api/void-layout';
async function validate(rooms){const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json',Origin:'http://localhost:3003'},body:JSON.stringify({rooms,validateOnly:true})});const report=await response.json();assert.ok(response.ok,JSON.stringify(report));}
async function run(){
 const original=fs.readFileSync(path.join(root,'commons/void/rooms.json'));
 const response=await fetch(url),payload=await response.json();assert.ok(response.ok,JSON.stringify(payload));
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'))),defs=JSON.parse(fs.readFileSync(path.join(root,'commons/void/primitive-prefabs.json'))).prefabs;
 for(const p of defs){assert.ok(fs.existsSync(path.join(root,p.scene.replace('res://',''))));}
 checks.push('All 19 definitions resolve to real source scenes');
 const rooms=structuredClone(payload.rooms);
 for(const [kind,prop] of Object.entries(payload.catalog.props).filter(([k,v])=>v.group==='Primitives kit')){
  const model=models.props[kind];assert.ok(model&&model.meshes>0,kind);
  const bytes=fs.readFileSync(path.join(web,'public',model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
  const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());assert.ok(gltf.meshes.length>0);
  if(kind.startsWith('timber_')||kind==='traffic_pyramid_5')assert.ok(gltf.images?.length,kind+' keeps its actual texture');
  rooms.floors[12].props.push({id:'kit-validation-'+kind,kind,position:[16,5],facing:90,scale:1});
  checks.push(kind+': real parsed GLB and placeable palette kind');
 }
 await validate(rooms);checks.push('All ten new palette members validate in a shared desktop/VR layout draft');
 const trialPayload=await(await fetch(url+'?trial=matter_gates')).json(),trialModels=JSON.parse(fs.readFileSync(path.join(web,'public/void-trials/matter_gates/manifest.json')));
 const merged=withSharedPalette(trialModels,trialPayload);
 assert.equal(merged.props.timber_plank_2m.url,models.props.timber_plank_2m.url);assert.equal(merged.props.container,trialModels.props.container);
 checks.push('Existing trials receive new shared kit previews while retaining their own exported models');
 for(const [floor,id] of [[3,'Hand_plank'],[4,'BallRamp'],[5,'SheetOneMetre'],[5,'SheetTwoByOne'],[5,'SheetWallInfill'],[6,'TrafficPyramidFive'],[6,'SevenVertexCrystal'],[12,'CourtDeck']]){
  const draft=structuredClone(payload.rooms),entry=listEntries(draft.floors[floor],payload,models,floor).find(e=>e.kind==='part'&&e.id===id);assert.ok(entry,id);
  const key=pasteObject(draft.floors[floor],copyObject(draft.floors[floor],entry,payload,floor),0);
  const copy=listEntries(draft.floors[floor],payload,models,floor).find(e=>e.key===key);assert.ok(copy,id);
  place(draft.floors[floor],copy,[16,entry.position[1],4],payload);turn(draft.floors[floor],copy);await validate(draft);
  assert.equal(JSON.stringify(JSON.parse(JSON.stringify(draft)).floors[floor]),JSON.stringify(draft.floors[floor]));checks.push(id+': independent copy/move/turn and JSON roundtrip validate');
 }
 assert.equal(Buffer.compare(fs.readFileSync(path.join(root,'commons/void/rooms.json')),original),0,'User arrangements must remain byte-identical');
 checks.push('Saved main-tower rooms remain byte-identical; validation-only, no transient user-layout writes');
 fs.writeFileSync(path.join(root,'ada_run/primitives-kit/editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Real GLB parsing and server validateOnly drafts. No new full-tower playthrough or physical-headset review.'},null,2)+'\n');
 console.log(checks.length+' Primitives kit editor checks passed');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
