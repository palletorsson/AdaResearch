// Standalone candidate-gem probe. These are new samples, not a captured Godot bench run.
// Run: node doc/book/experiments/randomness-gem-boundary/probe.mjs
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';

const seed=42, count=48, halfWidth=1;
let state=seed;
const samples=Array.from({length:count},()=>{
  state^=state<<13; state^=state>>>17; state^=state<<5; state>>>=0;
  return state/4294967296;
});
const increments=samples.map(u=>2*u-1);
let sum=0;
const cumulative=increments.map(d=>sum+=d);
const firstContactGain=halfWidth/Math.max(...cumulative.map(Math.abs));
// Fold an arbitrarily overshooting coordinate into [-halfWidth, halfWidth].
function reflect(x){const period=4*halfWidth;const t=((x+halfWidth)%period+period)%period;return t<=2*halfWidth?t-halfWidth:3*halfWidth-t;}
function run(gain,policy,draws=increments){
  let x=0,discardedDistance=0;const path=[0],events=[];
  draws.forEach((d,i)=>{
    const attempted=x+gain*d;
    if(Math.abs(attempted)>halfWidth)events.push({step:i+1,attempted});
    x=policy==='clamp'?Math.max(-halfWidth,Math.min(halfWidth,attempted)):reflect(attempted);
    if(policy==='clamp')discardedDistance+=Math.abs(attempted-x);
    path.push(x);
  });
  return {gain,policy,path,events,discardedDistance};
}
const tolerance=1e-12;
const maxDifference=(a,b)=>Math.max(...a.map((x,i)=>Math.abs(x-b[i])));
const trials=[.8,1.2].map(ratio=>{
  const gain=ratio*firstContactGain,clamp=run(gain,'clamp'),reflection=run(gain,'reflect');
  return {ratio,gain,clamp,reflection,maxPathDifference:maxDifference(clamp.path,reflection.path)};
});
assert.equal(trials[0].clamp.events.length,0);
assert.equal(trials[0].reflection.events.length,0);
assert.ok(trials[0].maxPathDifference<tolerance);
assert.ok(trials[1].clamp.events.length>0);
assert.ok(trials[1].maxPathDifference>tolerance);
for(const trial of trials)for(const policy of ['clamp','reflection'])assert.ok(trial[policy].path.every(x=>Math.abs(x)<=halfWidth+tolerance));
assert.deepEqual(run(trials[1].gain,'clamp'),trials[1].clamp);
assert.deepEqual(run(trials[0].gain,'clamp'),trials[0].clamp);
// Attempt to defeat a stronger claim: the effect need not be unique to randomness.
const constantInput=Array(count).fill(.5);
const constantControl={input:constantInput,clamp:run(trials[1].gain,'clamp',constantInput),reflection:run(trials[1].gain,'reflect',constantInput)};
const constantDifference=maxDifference(constantControl.clamp.path,constantControl.reflection.path);
assert.ok(constantDifference>tolerance);

const receipt={schema:'ada-gem-probe/1',candidate:'At a boundary, the same random displacements acquire different consequences through the receiving rule.',
  scope:'Standalone numerical displacement model; not a Godot/VR run or visitor observation.',
  generator:'xorshift32, unsigned state; u = state / 2^32',seed,samples,increments,
  baseline:{start:0,halfWidth,stepCount:count,operation:'x_attempt = x_previous + gain * (2*u - 1)',note:'Discrete displacement, not a physical force model; no claim about fresh physical entropy.'},
  threshold:{firstContactGain,meaning:'For this finite sample, the smallest nonnegative gain at which the unconstrained cumulative path touches either edge. Policy effects begin on overshoot.'},
  trials,constantControl:{...constantControl,maxPathDifference:constantDifference,interpretation:'The boundary effect also occurs with constant input. This probe does not establish a property unique to randomness.'},checks:{belowThresholdSame:true,aboveThresholdDifferent:true,replayExact:true,returnToBaselineExact:true,bounded:true,nonrandomCounterexample:true},
  unresolved:['Does a visitor notice the different edge behaviour without being told what to conclude?','Does controlling the edge suggest a new use or a different question?','Can someone reconstruct the difference from the tutorial?','Does the candidate support a literary passage beyond restating the code?']};
fs.writeFileSync(fileURLToPath(new URL('./receipt.json',import.meta.url)),JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify({firstContactGain,trials:trials.map(t=>({gain:t.gain,ratio:t.ratio,clampContacts:t.clamp.events.length,reflectionContacts:t.reflection.events.length,maxPathDifference:t.maxPathDifference,discardedDistance:t.clamp.discardedDistance})),constantDifference,checks:receipt.checks},null,2));
