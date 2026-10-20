// Explicit trial installation requested by Palle. Dry run by default; --apply writes the room and wall.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath,pathToFileURL} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'../../../..');
const web=path.resolve(root,'../ada_encyclopedia');
const {load}=await import(pathToFileURL(path.join(web,'tests/writing-wall/load.mjs')).href);
const {loadWall}=load('lib/writing-wall-store');
const {planRoomLayout}=load('lib/writing-room-store');
const {roomLayoutIssues,walkingRoute}=load('lib/writing-room');
const moves=[
  ['seed_replay_demo',1,1],['prng_crank_machine',4,1],['film_prng_register',8,1],
  ['seed_replay_demo/source_console',8,4],['random_number_book_page_1955',1,4],
  ['seed_replay_demo/frame_timing',1,7],['trng_vs_prng',8,7],
  ['lava_entropy_wall',8,11],['geiger_counter',1,11],
  ['seed_replay_demo/movement_sampler',1,14],['seed_study',8,14],
  ['random_return',8,17],['slot_machine',1,17],
].map(([id,x,z])=>({id,x,z}));
const order=moves.map(m=>m.id);
const original=loadWall(root,'Random_Definition');
assert.deepEqual([...order].sort(),[...original.wall.order].sort());
const draftText=fs.readFileSync(path.join(here,'final-draft.md'),'utf8');
const {passagesOf}=load('lib/encounter-route');
const passages=passagesOf(draftText);assert.deepEqual(passages.map(p=>p.lookup),order);
const plan=planRoomLayout(root,'Random_Definition',original.version,moves);
const candidate={...original,wall:{...original.wall,order},artifacts:original.artifacts.map(a=>{const m=moves.find(m=>m.id===a.id);return {...a,x:m.x+.5,z:m.z+.5};})};
assert.deepEqual(roomLayoutIssues(candidate),[]);assert.deepEqual(walkingRoute(candidate).unreachable,[]);
console.log(JSON.stringify({mode:process.argv.includes('--apply')?'apply':'dry run',order,cellOperations:plan.operations.length,routeLegs:walkingRoute(candidate).legs.length}));
if(!process.argv.includes('--apply'))process.exit(0);
async function post(route,payload){const response=await fetch('http://localhost:3003'+route,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});const data=await response.json();if(!response.ok||data.error)throw new Error(JSON.stringify(data));return data;}
const moved=await post('/api/maps/cell-edit',plan);
fs.writeFileSync(path.join(here,'placement-save.json'),JSON.stringify(moved,null,2)+'\n');
// The source text and plan are kept separate from the generated planning notes.
fs.copyFileSync(path.join(here,'final-draft.md'),path.join(root,'commons/maps/Random_Definition/final.md'));
const afterMove=loadWall(root,'Random_Definition'),wall=structuredClone(afterMove.wall);
wall.order=order;
const briefSeeds=[
  'Begin with a returning picture. One discarded draw changes the right window without changing its seed. Let that discrepancy ask for a procedure.',
  'Answer the replay question through visible arithmetic. Define pseudorandom procedure, state and seed only now; repeatability gives us an experiment we can revisit.',
  'A short supporting encounter: the number has a predecessor. Give the dependency a visible form without starting a second lecture.',
  'Ask where the initial value arrived from. The saved atmospheric 435 and its chosen range separate acquiring a value from replaying its use.',
  'Follow preservation into the historical number table, then let the installed falling page trouble that promise. Keeping becomes an event.',
  'An irregular trace challenges the eye: appearance alone does not establish a source of uncertainty.',
  'Distinguish calculation from physical-source measurement, and distinguish both from a persuasive simulation. Carry the measurement question through the doorway.',
  'The virtual lamps meet a selective sensor. Changing its view changes the record; the receiving apparatus participates in the number.',
  'Change the clock on retained simulated detections. The sound can stay while its numerical interpretation changes.',
  'Bring the visitor into acquisition: a recorded gesture becomes a seed while exceeding what the integer retains.',
  'Return to the opening assignment question with five trays. RGB triples and their means give the same sample different forms. Keep this as our first research pilot.',
  'Let assignment carry a body. Direction and distance vary while returning remains prescribed; changing that relation requires another rule.',
  'Give anticipation time. The reels and their counts hand the question of what a record retains to Random Entropy.',
];
for(const [i,id] of order.entries()){const m=wall.magnets.find(m=>m.id===id);m.tags=[...new Set([...(m.tags??[]),'final'])];m.final=briefSeeds[i];}
// Preserve all existing subject memberships, research records, conceptual edges and tutorial tags/seeds.
await post('/api/writing-wall',{map:wall.map,version:afterMove.version,wall});
const installed=loadWall(root,'Random_Definition');
assert.deepEqual(installed.wall.order,installed.passages.final.map(p=>p.lookup));
assert.deepEqual(roomLayoutIssues(installed),[]);
const route=walkingRoute(installed);assert.equal(route.legs.length,12);assert.deepEqual(route.unreachable,[]);
assert.deepEqual(installed.wall.subjects,original.wall.subjects);
assert.deepEqual(installed.wall.edges,original.wall.edges);
assert.deepEqual(installed.wall.experiments,original.wall.experiments);
for(const m of original.wall.magnets){const n=installed.wall.magnets.find(n=>n.id===m.id);assert.equal(n.tutorial,m.tutorial);assert.equal(n.tags.includes('tutorial'),m.tags?.includes('tutorial')??false);}
for(const move of moves){const a=installed.artifacts.find(a=>a.id===move.id);assert.equal(a.x,move.x+.5);assert.equal(a.z,move.z+.5);}
const crossings=route.legs.flatMap((l,i)=>l.cells.filter(c=>c.z===9).map(c=>({...c,afterStop:i+1})));
assert.deepEqual(crossings,[{x:11,z:9,afterStop:7}]);
const receipt={at:new Date().toISOString(),order,moves,bodyWords:passages.map(p=>p.text).join(' ').split(/\s+/).filter(Boolean).length,roomIssues:[],walkingLegs:route.legs.length,crossings,finalMarkersMatch:true,existingSubjectAndConceptLinksPreserved:true,tutorialSeedsPreserved:true,version:installed.version};
fs.writeFileSync(path.join(here,'verification.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt,null,2));
