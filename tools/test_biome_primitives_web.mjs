import fs from 'node:fs';
import assert from 'node:assert/strict';
import {Encounter,stages} from '../commons/artifacts/biome_primitives/web/model.mjs';
const data=JSON.parse(fs.readFileSync(new URL('../commons/artifacts/biome_primitives/pilot.json',import.meta.url)));
const oracle=JSON.parse(fs.readFileSync(new URL('../ada_run/biome_primitives/oracle.json',import.meta.url)));
let comparisons=0;
function same(a,b,path=''){
  comparisons++;
  if(typeof a==='number'){assert.ok(Math.abs(a-b)<.00002,`${path}: ${a} != ${b}`);return;}
  if(a&&typeof a==='object'){assert.deepEqual(Object.keys(a).sort(),Object.keys(b).sort(),path);for(const k of Object.keys(a))same(a[k],b[k],path+'.'+k);return;}
  assert.equal(a,b,path);
}
for(let i=0;i<stages.length;i++){
  const m=new Encounter(data.form_dna);m.setStage(i);
  for(const a of (i>=6?data.hinge_demo:(i>=4?data.form_demo:data.demo))){m.move(a.p);m.advance(a.dt);}
  same(m.snapshot(),oracle[stages[i]],stages[i]);
}
const m=new Encounter();m.setStage(2);m.advance(.12);m.move([1,.3,1]);m.advance(.12);
const archive=structuredClone(m.samples);m.toggle();m.move([-4,.3,3]);m.advance(10);
assert.deepEqual(m.samples,archive);assert.equal(m.snapshot().visible_samples,0);
m.toggle();m.advance(.12);assert.equal(m.samples.at(-1).start,true);
const h=new Encounter(data.form_dna);h.setStage(6);
for(const pose of oracle.hinge_schedule){h.hinge_angle=Encounter.angleAt(pose.time);same(h.hinge_angle,pose.angle,'hinge.angle');same(h.forms(),pose.forms,'hinge.forms');}
h.hinge_time=6;h.hinge_angle=Encounter.angleAt(6);h.move([-4.1,.05,-.3]);h.advanceHinge(.1,true);
assert.equal(h.hinge_time,6);assert.equal(h.hinge_held,true);h.move([0,.05,4.5]);h.advanceHinge(.1,true);assert.equal(h.hinge_held,false);assert.ok(h.hinge_time>6);
const frozen=structuredClone(h.forms());h.toggle();h.advanceHinge(.1);assert.deepEqual(h.forms(),frozen);h.toggle();h.advanceHinge(.1);assert.notDeepEqual(h.forms(),frozen);
const s=new Encounter(data.form_dna);s.setStage(7);
for(const entry of oracle.scale_schedule){
  const pose=Encounter.scalePoseAt(entry.time);same(pose,entry.pose,'scale.pose');
  s.width_factor=pose.factor;s.hinge_angle=pose.angle;same(s.forms(),entry.forms,'scale.forms');
}
s.scale_time=22;Object.assign(s,{width_factor:Encounter.scalePoseAt(22).factor,hinge_angle:0});
s.move([5.2,.05,.4]);s.advanceHinge(.1,true);assert.equal(s.hinge_held,true);assert.equal(s.scale_time,22);
s.move([0,.05,4.5]);s.advanceHinge(.1,true);assert.equal(s.hinge_held,false);assert.ok(s.scale_time>22);
const scaled=structuredClone(s.forms());s.toggle();s.advanceHinge(.1);assert.deepEqual(s.forms(),scaled);s.toggle();s.advanceHinge(.1);assert.notDeepEqual(s.forms(),scaled);
fs.writeFileSync(new URL('../ada_run/biome_primitives/web-test.json',import.meta.url),JSON.stringify({comparisons,passed:true},null,2));
console.log(`Browser / Godot parity: ${comparisons} field comparisons passed; withdrawal, scale, hinge and stroke gap passed.`);
