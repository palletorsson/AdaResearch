"""Align sequence descriptions with the twelve retained encounters."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PATH=ROOT/'commons/maps/sequences/wavefunctions.json'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
d=read(PATH); s=d['sequences']['wavefunctions']
old=read(HERE/'before/commons/maps/sequences/wavefunctions.json')['sequences']['wavefunctions']
changes={
 'name':'Wavefunctions: What Returns',
 'truth':'Returning to one value need not mean returning to the same state. Follow what a repeated movement carries into a record, a space, a sound and a sum.',
 'qfep_connection':'The sequence asks which differences a returning pattern carries or hides, and which authored boundaries and receivers make that return possible. Periodicity, coupling and chance are distinct operations to investigate.',
 'formula':'x(t) = A sin(ωt + φ); y(t) = Σₙ₌₁⁵ aₙ sin(nωt)',
 'demonstration':'Release a pendulum, compare sampling clocks, walk beside sine-shaped space, then discover the coordinate projection of a turning point. Compare coupling, modulation, chance, struck voices, sampled steps, beats and finite harmonic sums.',
 'description':'What returns changes with the state we retain and the body that receives it. Motion becomes a record, periodic coordinates become space, and simple sources meet as sound or a visible sum. The sequence preserves the difference between a mathematical rule and what a visitor can do with its implementation.',
 'learning_objectives':[
  'Distinguish a returning position from a returning state using velocity and release conditions',
  'Compare sampling intervals, retained duration and stroboscopic records on a finite clock',
  'Compare sine-shaped collision terrain with moving visual boundaries',
  'Predict sine and cosine as coordinate projections of angular progression',
  'Compare driven local motion with motion transmitted through neighbour coupling',
  'Hear phase modulation while holding a reference and separating envelope, index and frequency ratio',
  'Distinguish periodic form through height, whole-object rotation and sampled walking affordances',
  'Distinguish chance event ordering from the prepared vocabulary it selects',
  'Compare a struck voice, a restrike and the sampled sum of independent voices',
  'Read a beat envelope without confusing the sum with either input',
  'Build finite sums of five nonnegative, phase-locked harmonics and inspect the limits of their recipe labels'
 ],
 'content':[
  'WaveFunctions_Intro: A returning position is not a whole state',
  'WaveFunctions_Pendulum: A movement acquires a sampled history',
  'WaveFunctions_Sine_Space: A periodic rule becomes terrain and visible passage',
  'WaveFunctions_Unit_Circle: Discover the coordinate that draws the graph',
  'WaveFunctions_3D_Wave_Propagation: A disturbance travels between local receivers',
  'WaveFunctions_Effect_Sound: Hear one oscillator alter another’s phase',
  'Wavefunctions_Bernini: Periodic form through height, rotation through time',
  'WaveFunctions_John_Cage: Chance selects within a prepared vocabulary',
  'WaveFunctions_AirMusic: Contact ends while its sound continues',
  'Wavefunctions_Sky_Stairs: A sampled curve needs provisions for a body',
  'WaveFunctions_TrigWalkingPath: Two fast motions make a slow envelope',
  'WaveFunctions_Synthesis_Lab: Read a finite sum and its recipe classifier'
 ]}
for k,v in changes.items():s[k]=v
history=s.setdefault('local_review_history',[])
if not any(v.get('date')=='2026-09-19' for v in history):
 history.append(dict(date='2026-09-19',reason='Twelve-hall restoration and source-grounded objectives; map order preserved.',previous={k:old[k] for k in changes}))
assert s['maps']==old['maps']
PATH.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Sequence narrative aligned; twelve-map order unchanged.')
