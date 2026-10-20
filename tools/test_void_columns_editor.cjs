// Inspect real exported geometry and exercise the production editor without saving test copies.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const {listEntries,copyObject,pasteObject,place,turn}=context.exports;
async function main(){
 const endpoint='http://localhost:3003/api/void-layout',payload=await (await fetch(endpoint)).json();
 const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
 const index=payload.rooms.floors.findIndex(f=>f.map==='Primitives_Columns'),floor=payload.rooms.floors[index],checks=[];
 assert.equal(models.floors[index].map,floor.map);
 const allEntries=listEntries(floor,payload,models,index);
 if(process.argv.includes('--ceiling')){
  const ceilingColumns=allEntries.filter(e=>e.artifactId==='hall'&&/^(Sides_|Grove_|InteriorColumn_)/.test(e.id));
  assert.equal(ceilingColumns.length,45);
  for(const entry of ceilingColumns){
   const bounds=entry.model.default.bounds;
   assert.ok(Math.abs(bounds[1]+bounds[4]-5.64)<.001,entry.id+': exported bounds must reach the upper slab');
  }
  checks.push({name:'All 45 editor column meshes reach 5.64 m including their bases',passed:true});
 }
 const entries=allEntries.filter(e=>e.artifactId==='hall'&&/^(Sides|Grove)_/.test(e.id));
 assert.equal(entries.length,25);
 for(const entry of entries){
  assert.ok(/\/ (sides|divisions|outline|height|composition)$/.test(entry.label),entry.label);
  const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
  const model=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString().trim());
  const column=model.meshes.find(m=>m.primitives.length===9);assert.ok(column,'Nine original profile sections');
  const card=entry.model.labels.find(l=>l.text.includes('SIDES /'));assert.ok(card);
  const [,sides,rings]=card.text.match(/(\d+) SIDES \/ (\d+) DIVISIONS/);
  const triangles=column.primitives.reduce((sum,p)=>sum+model.accessors[p.indices].count/3,0);
  assert.equal(triangles,Number(sides)*(10*Number(rings)+26));
  checks.push({name:entry.label+': actual mesh matches displayed resolution',passed:true});
 }
 const copyCases=['sides','divisions','outline','height','composition'].map(family=>[family,entries.find(e=>e.label.endsWith('/ '+family))]);
 if(process.argv.includes('--grove')){
  const grove=allEntries.filter(e=>e.artifactId==='hall'&&e.id.startsWith('InteriorColumn_'));
  assert.equal(grove.length,20);
  for(const entry of grove){
   assert.match(entry.label,/^Grove \d+ \/ (Vessel|Reed|Bell|Spindle|Cairn) \/ [\d.]+ m \/ \d+ sides$/);
   const bytes=fs.readFileSync(path.join(web,'public',entry.model.url));assert.equal(bytes.readUInt32LE(0),0x46546c67);
   const model=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString().trim());
   assert.ok(model.meshes.some(m=>m.primitives.length===9));
   assert.equal(entry.model.labels.length,0);
   checks.push({name:entry.label+': exported original column geometry and movable part',passed:true});
  }
  for(const id of ['InteriorColumn_01','InteriorColumn_13','InteriorColumn_20'])copyCases.push([id,grove.find(e=>e.id===id)]);
  assert.equal(allEntries.filter(e=>e.id.startsWith('GroveLight')).length,2);
 }
 for(const [family,entry] of copyCases){
  const rooms=structuredClone(payload.rooms),destination=rooms.floors[0];
  Object.assign(destination,{artifacts:[],copies:[],props:[],walls:[],route:[]});
  const key=pasteObject(destination,copyObject(floor,entry,payload,index),0);
  let copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
  assert.equal(copy.model.url,entry.model.url);assert.ok(copy.label.startsWith(entry.label));
  place(destination,copy,[0,entry.position[1],4],payload);turn(destination,copy);
  copy=listEntries(destination,payload,models,0).find(e=>e.key===key);
  assert.equal(copy.position[2],4);assert.equal(copy.rotation[1],(entry.rotation[1]+90)%360);
  const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms,validateOnly:true})});
  const receipt=await response.json();assert.ok(response.ok&&receipt.valid,JSON.stringify(receipt));
  checks.push({name:family+': copy/move/turn and schema-valid draft',passed:true});
 }
 const guideEntries=listEntries(floor,payload,models,index).filter(e=>e.artifactId==='hall'&&e.id.endsWith('Guide'));
 assert.equal(guideEntries.length,5);
 const lightEntries=listEntries(floor,payload,models,index).filter(e=>e.artifactId==='hall'&&e.id.endsWith('Light'));
 assert.equal(lightEntries.length,4);assert.ok(lightEntries.every(e=>e.model.lights.length===1));
 checks.push({name:'Five movable guides and four exported spotlights',passed:true});
 // Legacy parts without labels retain their previous naming. Explicit copy names still win.
 const oldEntries=listEntries(payload.rooms.floors[8],payload,models,8);
 assert.ok(oldEntries.some(e=>e.id==='Dodecahedron'&&e.label==='Dodecahedron'));
 const beforeReport=process.argv.includes('--ceiling')?'2026-10-19-columns-to-the-ceiling':'2026-10-19-columns-comparisons';
 const before=JSON.parse(fs.readFileSync(path.join(root,'doc/book/iterations',beforeReport,'rooms-before.json')));
 for(let i=0;i<payload.rooms.floors.length;i++)if(i!==index)assert.deepEqual(payload.rooms.floors[i],before.floors[i]);
 assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json')),payload.rooms);
 checks.push({name:'Other floors preserved; Desktop layout equals the editor layout',passed:true});
 const report=process.argv.includes('--ceiling')?'2026-10-19-columns-to-the-ceiling':process.argv.includes('--grove')?'2026-10-19-column-grove':'2026-10-19-columns-comparisons';
 fs.writeFileSync(path.join(root,'doc/book/iterations',report,'editor-checks.json'),JSON.stringify({passed:true,checks,scope:'Real GLBs and production editor operations; test copies not saved.'},null,2));
 console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
