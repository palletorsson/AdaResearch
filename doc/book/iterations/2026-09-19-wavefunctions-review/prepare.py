"""Prepare reviewable, exact manuscript changes. Does not edit production text."""
from pathlib import Path
import json, difflib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
proposals=read(HERE/'opening/manuscript-proposals.json')
proposals+=read(HERE/'ending/root-proposals.json')['final_md']
proposals.append(dict(path='commons/maps/WaveFunctions_Effect_Sound/final.md',
 old='In AirMusic, a strike starts a response that continues after contact. Carry this habit to the bar: give a sound time to change before deciding what sort of body has answered.',
 new='In AirMusic, a strike will start a response that continues after contact. First, Bernini gives periodic change another direction: along the height of a column. Walk around it. What changes as you move, and what keeps moving when you stand still?',
 reason='Reconnect the next hall while retaining the later auditory return.'))
middle=HERE/'middle/manuscript-proposals.json'
if middle.exists():proposals+=read(middle)
by_path={}
for p in proposals:by_path.setdefault(p['path'],[]).append(p)
(HERE/'proposed').mkdir(exist_ok=True);(HERE/'diffs').mkdir(exist_ok=True)
for path,items in by_path.items():
 old=(HERE/'before'/path).read_text(encoding='utf-8');new=old
 for item in items:
  assert new.count(item['old'])==1,(path,item['old'][:100])
  new=new.replace(item['old'],item['new'],1)
 name=Path(path).parent.name
 (HERE/'proposed'/f'{name}.md').write_text(new,encoding='utf-8')
 (HERE/'diffs'/f'{name}.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+path,tofile=path)),encoding='utf-8')
 print(name,len(items),'bounded changes')
(HERE/'text-changes.json').write_text(json.dumps(proposals,ensure_ascii=False,indent=2),encoding='utf-8')
