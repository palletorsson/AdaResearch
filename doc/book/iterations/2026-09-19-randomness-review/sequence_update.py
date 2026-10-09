"""Describe the actual learning arc, with explicit museum-only interludes."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
path=ROOT/'commons/maps/sequences/randomness.json'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
d=read(path);s=d['sequences']['randomness']
old=read(HERE/'before/commons/maps/sequences/randomness.json')['sequences']['randomness']
changes={
 'name':'Randomness: What Can Chance Change?',
 'description':'A draw enters a world that has already made choices: its possible values, their distribution, the eligible bodies, the clock, the memory and the consequences. Begin by recovering a picture, then discover how the same draw can become a colour, an absence, a step, a garment or a lost foothold. Learning those rules also makes it possible to ask which other bodies and relations they could admit.',
 'qfep_connection':'The sequence investigates the project’s connection between uncertainty, possibility and freedom through specific encounters. Empirical categorical Shannon entropy measures symbol shares in a retained sample; it is not a direct measure of spatial disorder, thermodynamic entropy or freedom. The critical question remains open: which differences may occur within a rule, and what changes when we alter the rule itself?',
 'learning_objectives':[
  'Separate a generator seed from the procedure that consumes and assigns its draws',
  'Compare sample order, symbol shares and categorical Shannon entropy without equating them',
  'Inspect eligibility before selection, then distinguish hiding geometry from withdrawing collision support',
  'Relate local binary marks to larger contours and a separately implemented navigation graph',
  'Compare a physical-looking die outcome with a retained record and the conditions of its throws',
  'Separate accumulated changes in position, orientation and appearance',
  'Distinguish direction sets, bounded step-length laws, boundary handling and retained history',
  'Compare sampling procedures, clipping and rebinning of the same stored values',
  'Distinguish variation within a wardrobe from changing the construction that makes forms possible',
  'Compare independent spatial variation with correlated neighbours and finite layered fields',
  'Identify the different jobs of chance in mark generation, numerical estimation, path growth and particle updates',
  'Compare a recorded trail with a signal that influences later choices',
  'Distinguish an already sampled deadline from an undrawn wait, and a cue from the event it reveals'
 ],
 'content':[
  'Random_Definition: A seed needs a procedure before it becomes a picture',
  'Random_Entropy: Sorting changes order while symbol shares and their gauge stay',
  'Random_Remove: Filter, draw, delete — and decide what support disappears',
  'Randomness_10_PRINT_Algorithm: Local choices become marks, contours and separately computed passages',
  'Random_Cubes: A single throw becomes an empirical record',
  'Random_Rotate_Random_XYZ: Decompose the impression of disorder into changing variables',
  'Random_Walk: Steps accumulate; a retained trail need not guide the next step',
  'Random_Gaussian: Sampling, clipping and binning give a record its shape',
  'Random_Mushrooms: Visit a specimen bed, an arrival wardrobe and a different garment construction',
  'Random_Space_Geometry: Compare independent heights with correlated neighbours',
  'Randomness_Examples_of_Randomness: Give chance different jobs in a gallery of procedures',
  'Random_Pheromone: A mark enters the next decision',
  'Random_Space: Combine finite contributions at different scales',
  'Random_Game: What is already decided, and what must your body still discover?'
 ],
 'museum_interludes':[
  dict(map='Biome_Cage',after='Random_Mushrooms',purpose='Retained museum application: an authored repertoire is staged as a seeded composition. No additional final.md chapter is implied.'),
  dict(map='Biome_Ladder_Randomness',after='Random_Game',purpose='Retained closing application: the sequence’s vocabulary accumulates in successive seeded biome compositions.')
 ]}
for k,v in changes.items():s[k]=v
history=s.setdefault('local_review_history',[])
if not any(x.get('date')=='2026-09-19' for x in history):
 history.append(dict(date='2026-09-19',reason='Restore fourteen chapters and retain two authored biome interludes; distinguish different jobs of chance.',previous={k:old.get(k) for k in changes}))
assert s['maps']==old['maps'] and s['deferred_maps']==old['deferred_maps']
path.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Randomness metadata aligned; fourteen book chapters and two explicit museum interludes.')
