"""Record each Tiling map as a reviewable proposal; never accept on publication."""
import json, subprocess, sys
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def call(command,payload):
    run=subprocess.run([sys.executable,str(ROOT/'tools/project_memory.py'),'--root',str(ROOT),command],input=json.dumps(payload),encoding='utf-8',capture_output=True,check=True)
    return json.loads(run.stdout)

plans=next(s for s in load(ROOT/'doc/book/course/storyboards/early.json') if s['sequence']=='tiling')
changes={h['id']:h for h in load(HERE/'changes.json')}
model=call('model',{})
out=[]
for hall in plans['halls']:
    c=changes[hall['id']]
    snapshot=HERE/'proposals'/f'{hall["id"]}.json'
    snapshot.parent.mkdir(exist_ok=True)
    if not snapshot.exists():snapshot.write_text(json.dumps(hall,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    path=snapshot.relative_to(ROOT).as_posix()
    existing=next((f for f in model['findings'] if any(s['path']==path for s in f['sources'])),None)
    if existing:
        out.append(existing);continue
    finding=dict(scope='map:'+hall['id'],kind='proposal',text='Tiling revision — '+hall['id']+': '+c['after'],reason=c['reason'],sequence_effect=hall['carries'],project_effect='One-map teaching selection; summaries only. Preserve the existing museum, critical text and room order. Full lesson/binding remains a separate pass.',related_scopes=['sequence:tiling'],source_paths=[path,'doc/book/course/storyboards/TILING.md','commons/maps/'+hall['id']+'/final.md']+hall['source_refs'],method='Static source and editorial review; compact before/after summary with dated museum image. No new runtime or learner test.',created_by='Codex')
    model=call('mutate',dict(action='finding',expected_revision=model['revision'],finding=finding))
    new=next(f for f in model['findings'] if any(s['path']==path for s in f['sources']))
    assert new['status']=='proposed'
    out.append(new)
(HERE/'memory-proposals.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
packet=call('packet',{'scope':'sequence:tiling'})
(HERE/'tiling-handoff.md').write_text(packet['text'],encoding='utf-8')
print(f'{len(out)} map proposals recorded separately; memory revision {model["revision"]}. No proposal accepted.')
