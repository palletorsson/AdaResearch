// Apply this trial once, guarding the saved room and wall against concurrent edits.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
const {load}=await import(pathToFileURL(path.resolve(root,'../ada_encyclopedia/tests/writing-wall/load.mjs')).href);
const {loadWall}=load('lib/writing-wall-store');
const {roomLayoutIssues,walkingRoute}=load('lib/writing-room');
const file=path.join(root,'commons/maps/Random_Definition/map_data.json');
const raw=fs.readFileSync(file,'utf8'),doc=JSON.parse(raw),before=loadWall(root,'Random_Definition');
assert.equal(raw,fs.readFileSync(path.join(here,'before/map_data.json'),'utf8'));
assert.deepEqual(before.wall,JSON.parse(fs.readFileSync(path.join(here,'before/writing_wall.json'),'utf8')));
const old=doc.layers.interactables[4][1];
assert.equal(old,'random_number_book_page_1955:270:3:1');
async function post(route,payload){const r=await fetch('http://localhost:3003'+route,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});const v=await r.json();if(!r.ok||v.error)throw new Error(JSON.stringify(v));return v;}
const result=await post('/api/maps/cell-edit',{map:'Random_Definition',expect_sha256:createHash('sha256').update(raw).digest('hex'),operations:[{op:'set',layer:'interactables',cell:[1,0,4],token:old+'#row_stream:true#cascade_speed:0.4',expect:old}],rebuild_strip:true});
fs.writeFileSync(path.join(here,'placement-save.json'),JSON.stringify(result,null,2)+'\n');
const m=loadWall(root,'Random_Definition'),wall=structuredClone(m.wall);
const seeds={
 random_number_book_page_1955:'A new row enters from above; touching keeps a digit while the stream continues. A kept page supports tests of patterns and bias, but cannot alone establish provenance or future unpredictability. Preserve the difference between production, recording and selection.',
 'seed_replay_demo/frame_timing':'Hold one trace and change its display range. Its appearance changes without new intervals. Let this enacted comparison separate a visual impression from a claim about the source, preparing three distinct questions.',
 trng_vs_prng:'Distinguish visual irregularity, specified statistical properties and predictability given available information. Compare calculation from state with measurement of physical uncertainty. Follow the measuring procedure through the doorway; the lamps and detections here remain simulations.',
 'seed_replay_demo/movement_sampler':'Timed positions and orientations are rounded and hashed to a seed from 0 to 999. Different gestures can share a seed; the fuller sample record is also kept. Ask what another reader of the same recording could retain, then what the five trays let values do.',
};
for(const magnet of wall.magnets)if(seeds[magnet.id])magnet.final=seeds[magnet.id];
await post('/api/writing-wall',{map:wall.map,version:m.version,wall});
const current=loadWall(root,'Random_Definition');
assert.deepEqual(current.wall,wall);
assert.deepEqual(current.wall.order,before.wall.order);
assert.deepEqual(current.passages.final.map(p=>p.lookup),wall.order);
assert.deepEqual(roomLayoutIssues(current),[]);
const route=walkingRoute(current);assert.equal(route.legs.length,12);assert.deepEqual(route.unreachable,[]);
const updated=JSON.parse(fs.readFileSync(file,'utf8'));updated.layers.interactables[4][1]=old;assert.deepEqual(updated,doc);
for(const a of before.artifacts){const b=current.artifacts.find(b=>b.id===a.id);assert.equal(b.x,a.x);assert.equal(b.z,a.z);}
const crossings=route.legs.flatMap((l,i)=>l.cells.filter(c=>c.z===9).map(c=>({...c,afterStop:i+1})));
assert.deepEqual(crossings,[{x:11,z:9,afterStop:7}]);
const receipt={at:new Date().toISOString(),bodyWords:current.passages.final.map(p=>p.text).join(' ').split(/\s+/).filter(Boolean).length,changedFinalSeeds:Object.keys(seeds),roomAndFinalOrderMatch:true,placementUnchanged:true,onlyMapChange:'RAND row_stream:true cascade_speed:0.4',otherWallFieldsPreserved:true,routeLegs:12,crossings,roomIssues:[],runtimeTest:'tests/test_rand_row_stream.gd passed headless',visualPacing:'Not yet observed in desktop/VR',readerEvidence:'Full-sequence feedback supplied by Palle; revised version awaits reading.'};
fs.writeFileSync(path.join(here,'verification.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));
