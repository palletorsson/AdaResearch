// Update only the final writing seeds for the authorized middle revision.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath,pathToFileURL} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
const {load}=await import(pathToFileURL(path.resolve(root,'../ada_encyclopedia/tests/writing-wall/load.mjs')).href);
const {loadWall}=load('lib/writing-wall-store');
const {roomLayoutIssues,walkingRoute}=load('lib/writing-room');
const m=loadWall(root,'Random_Definition');
const before=JSON.parse(fs.readFileSync(path.join(here,'before/writing_wall.json'),'utf8'));
assert.deepEqual(m.wall,before,'A saved wall changed since this revision began; reconcile before saving.');
assert.equal(fs.readFileSync(path.join(root,'commons/maps/Random_Definition/map_data.json'),'utf8'),fs.readFileSync(path.join(here,'before/map_data.json'),'utf8'));
assert.deepEqual(m.passages.final.map(p=>p.lookup),m.wall.order);
const seeds={
  'seed_replay_demo/source_console':'A kept atmospheric arrival can start a generator. Move from this single kept value to the historical need for a supply; retain the difference between acquiring and replaying.',
  random_number_book_page_1955:'A table can faithfully keep an unwanted pattern. Let the tested historical source complicate the promise of the falling page: keeping a digit does not establish its origin or quality.',
  'seed_replay_demo/frame_timing':'Try the tempting shortcut left by the book: does looking irregular tell us what we have kept? The uneven frame trace cannot establish source unpredictability. Carry that missing account to the comparison.',
  trng_vs_prng:'Supply only the distinction now needed: calculation from state versus physical-source measurement. Following the latter requires seeing how an event becomes a record. The simulations investigate this passage without claiming physical entropy.',
  lava_entropy_wall:'Give that passage a visible intervention: the retained lamp state can remain while a covered sensor loses part of its view. Recovering the view raises the next question: what distinctions can time measurement lose?',
  geiger_counter:'Use the same recorded simulated events. Coarser interval quantization can turn an unequal pair into a tie that emits no bit. Return to the held digit: retaining an event still leaves a choice of how to read it.',
  'seed_replay_demo/movement_sampler':'Bring the recording question into a hand. A gesture becomes usable as a seed while exceeding that encoding; turn from what is retained to what the five-tray receiver can make of values.',
};
const wall=structuredClone(m.wall);for(const magnet of wall.magnets)if(seeds[magnet.id])magnet.final=seeds[magnet.id];
const response=await fetch('http://localhost:3003/api/writing-wall',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({map:wall.map,version:m.version,wall})});
const result=await response.json();if(!response.ok)throw new Error(JSON.stringify(result));
const current=loadWall(root,'Random_Definition');assert.deepEqual(current.wall,wall);
assert.deepEqual(current.wall.order,current.passages.final.map(p=>p.lookup));
assert.deepEqual(roomLayoutIssues(current),[]);const route=walkingRoute(current);assert.equal(route.legs.length,12);assert.deepEqual(route.unreachable,[]);
const body=current.passages.final.map(p=>p.text).join('\n\n');
const receipt={at:new Date().toISOString(),bodyWords:body.split(/\s+/).filter(Boolean).length,changedFinalSeeds:Object.keys(seeds),roomAndFinalOrderMatch:true,physicalLayoutUnchanged:true,otherWallFieldsPreserved:true,routeLegs:12,roomIssues:[],visitorJudgement:'Not yet observed; do not infer from technical checks.'};
fs.writeFileSync(path.join(here,'verification.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt,null,2));
