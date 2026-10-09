"""Prepare exact, guarded manuscript edits; do not overwrite the live chapters."""
from pathlib import Path
import difflib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
proposals=[
 dict(path='commons/maps/Random_Remove/final.md',
 old='Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. Carry the changing set into the next room, where a walker takes its steps from draws like these and the set of places it can reach is decided one step at a time.',
 new='Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. In the next room, the available choice narrows to two diagonal marks. Follow what their neighbours make of them: when does a choice become a contour, and when can that contour become a passage?',
 reason='Keep the eligibility argument; hand off to the actual next hall, 10 PRINT.'),
 dict(path='commons/maps/Randomness_Examples_of_Randomness/final.md',
 old='Carry that question through the rear exit to Random Game. When a platform moves or a wait changes, distinguish the rule you can learn from the event you still have to discover.',
 new='Carry that question into the pheromone terrain. The pipe did not remember which places it had passed; the next walkers will leave a signal that can enter a later decision. What changes when a visit helps recruit another visit? Random Game still waits ahead, where such distinctions will become questions of support and timing.',
 reason='Restore the transition from retained paths to feedback without losing the later bodily capstone.')
]
for part in ['opening','middle','ending']:
 p=HERE/part/'manuscript-proposals.json'
 if part=='middle' and not p.exists():p=HERE/'middle/proposed/root-text.json'
 if p.exists():proposals+=read(p)
for p in proposals:
 if p['path']=='commons/maps/Random_Pheromone/final.md' and p['new'].startswith('At the console'):
  p['new']=p['new'].replace('Use +20 STEPS to watch a longer interval accumulate','Use +20 STEPS to advance a batch')
 if p['path']=='commons/maps/Random_Pheromone/final.md' and p['old'].startswith('A walker that avoided'):
  p['new']='Could the same act of leaving marks help make a different world? '+p['new']
  p['reason']='Keep the chapter’s question about possible worlds while making its proposed avoidance comparison available to the visitor.'
by_path={}
for p in proposals:by_path.setdefault(p['path'],[]).append(p)
(HERE/'proposed').mkdir(exist_ok=True);(HERE/'diffs').mkdir(exist_ok=True)
for path,items in by_path.items():
 old=(HERE/'before'/path).read_text(encoding='utf-8');new=old
 for p in items:
  assert new.count(p['old'])==1,(path,p['old'][:90])
  new=new.replace(p['old'],p['new'],1)
 name=Path(path).parent.name
 (HERE/'proposed'/f'{name}.md').write_text(new,encoding='utf-8')
 (HERE/'diffs'/f'{name}.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+path,tofile=path)),encoding='utf-8')
 print(name,len(items),'bounded changes')
(HERE/'text-changes.json').write_text(json.dumps(proposals,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
