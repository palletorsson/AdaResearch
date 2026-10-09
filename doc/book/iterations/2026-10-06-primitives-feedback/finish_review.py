from pathlib import Path
import sys,json,hashlib,re,urllib.request
from datetime import datetime,timezone
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PREVIOUS=HERE.parent/'2026-10-06-primitives-tutorial-lineage'
sys.path.insert(0,str(PREVIOUS))
from write_lessons import LESSONS

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

assert read(HERE/'verification.json')['passed']
changed=read(HERE/'summaries.json')
card_path=ROOT/'doc/book/course/hall-cards/state.json';state=read(card_path)
lineage_path=ROOT/'doc/book/course/hall-cards/lineage-opening.json';lineage=read(lineage_path)
story_path=ROOT/'doc/book/course/storyboards/opening.json';stories=read(story_path)
for hall in changed:
    subjects=LESSONS[hall][1];assert subjects
    state['cards'][hall]['subjects']=subjects
    next(r for r in lineage['halls'] if r['map']==hall)['subjects']=subjects
    for seq in stories:
        for row in seq['halls']:
            if row['id']==hall:
                row['learns']=subjects
                row['storyboard_short']='TEACH '+ '; '.join(subjects)+'. '+changed[hall]
state['updatedAt']=datetime.now(timezone.utc).isoformat()
save(card_path,state);save(lineage_path,lineage);save(story_path,stories)

note='''
## Primitives feedback refinement — 6 October

The author approved relevant feedback in both text tracks. Grid names representation change while retaining a sampled source; Triangle names indexed connectivity after Lines; Ignorance locates the decision in a generating rule and its input. Godot concentrates on resolution with supplied held-time mechanics. Profiles returns to Columns' section/route relation. Portals declares its sampler supplied so finite tolerance and budget remain the lesson. Melencolia adds an independent arrangement using already learned constructions; no new collision requirement or hidden worked answer.

Seven tutorial texts and four reflective texts changed. All printed executable blocks and museum maps are unchanged. Native evidence was refreshed (Trace 134, Grid 53 including 10 shared producer checks; later Primitives 122; 14 deliberate faults rejected). These are behavioural checks, not evidence that a learner understands the text. Current facing pages, lesson summaries, labels and Ghost Student states are synchronized. The independent closing task has no new tested solution. [Review](../../iterations/2026-10-06-primitives-feedback/index.html).
'''
for rel in ['doc/book/course/functional_text/RECONSTRUCTION.md','doc/book/course/storyboards/CONTEXT.md']:
    p=ROOT/rel;text=p.read_text(encoding='utf-8')
    if '## Primitives feedback refinement — 6 October' not in text:p.write_text(text.rstrip()+'\n'+note,encoding='utf-8',newline='\n')

manifest=read(ROOT.parent/'ada_encyclopedia/ghost-student/manifest.json')
entries={f['id']:f for f in manifest['files']}
ghost=ROOT.parent/'ada_encyclopedia/ghost-student'
states=[]
for state in manifest['states']:
    errors=[]
    for fid in state['files']:
        entry=entries[fid]
        if sha(ghost/entry['path'])!=entry['sha256']:errors.append('file '+fid)
    report=read(ghost/entries[state['evidence']['report']]['path'])
    for path,expected in {**report.get('inputs',{}),**report.get('dependencies',{})}.items():
        if sha(ROOT/path)!=expected:errors.append('source '+path)
    states.append({'state':state['id'],'current':not errors,'errors':errors})
save(HERE/'current-states.json',states)
assert all(s['current'] for s in states),[s for s in states if not s['current']]
print('Correct subject labels; fourteen current source-bound states; durable review notes updated.')
