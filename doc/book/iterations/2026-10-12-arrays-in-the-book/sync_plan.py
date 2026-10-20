"""Update the five Arrays plans only, retaining all unrelated user decisions."""
from pathlib import Path
import copy
import json
import re
import os
import tempfile
import time
from prepare_texts import HERE, ROOT, HALLS
from publish import put, sha

def atomic_put(path, text):
    handle,name=tempfile.mkstemp(prefix=path.name+'.',suffix='.tmp',dir=path.parent)
    with os.fdopen(handle,'w',encoding='utf-8',newline='') as stream: stream.write(text)
    for attempt in range(10):
        try:
            os.replace(name,path)
            return
        except OSError:
            if attempt==9: raise
            time.sleep(0.1)

def main():
    assert not (HERE/'plan-receipt.json').exists(), 'Already synchronized; use current records for later edits.'
    evidence=json.loads((HERE/'verification.json').read_text())
    assert evidence['passed']
    base=ROOT/'doc/book/course/execution-plan'
    before=json.loads((HERE/'before-sources.json').read_text())
    for name in ['authorized-revisions.json','lesson-summaries.txt']:
        assert sha(base/name)==before[f'doc/book/course/execution-plan/{name}'],'Concurrent edit: '+name
    plan=json.loads((HERE/'before/doc/book/course/execution-plan/plan.json').read_text(encoding='utf-8'))
    original=copy.deepcopy(plan)
    lookup={l['id']:l for l in plan['lessons']}
    lineage=json.loads((HERE/'lineage.json').read_text())
    export=(base/'lesson-summaries.txt').read_text(encoding='utf-8')
    report='doc/book/iterations/2026-10-12-arrays-in-the-book/index.html'
    for item in lineage:
        lesson=lookup[item['id']]
        lesson.update(decision='accepted',mode='reuse' if item['id']=='Tutorial_Tiling_Walls' else 'build',
            object=item['object'],change=item['change_note'],dependsOn=item['dependsOn'],given=item['given'],
            checks=[item['check'],'Exact printed files run in native Godot; deliberate behavioural faults fail their intended assertion.'],
            transfer=item['transfer'],carry=item['carry'],next=item['next'],summary=item['summary'],
            notes='12 October: author continued from Transformation, one sequence at a time. Existing Array draft incorporated; four outlines expanded to full construction. 451 native assertions, 22 configurations including baselines, 15 rejected faults. Current final texts and live museum runtime preserved. Accepted execution scope; text remains revisable. '+report)
        lesson['baseline']['tutorial']=sha(ROOT/f'commons/maps/{item["id"]}/tutorial.md')
        if item['id']=='Array': lesson['reuses']='Trans_Pre whole BoxMesh and overlap collection; Trace lists/indices; Transformation references and per-body transforms.'
        if item['id']=='Tutorial_Tiling_Walls': lesson['later']='The guarded moving museum wall and landing remain supplied. The printed freestanding panel uses a fixed pose at startup; no new hinge controller or live hall synchronization.'
        if item['id']=='Tutorial_Disco': lesson['later']='Four-track synthesis, audio-accurate scheduling and the museum sound-to-floor flash bridge remain later or supplied encounters. No footstep recording.'
        pattern=rf'(### {re.escape(item["id"])}\n\n).*?(?=\n### |\n## |\Z)'
        export,count=re.subn(pattern,lambda m:m.group(1)+item['summary']+'\n\nPlan: accepted execution scope; canonical complete code; fresh 12 October teacher-authored native evidence.\n\nEvidence: '+report+'\n',export,flags=re.S)
        assert count==1,item['id']
    sequence=next(s for s in plan['sequences'] if s['id']=='array_tutorial')
    sequence.update(carry='Whole cube construction → independent copies and retained slots → declared YZX volume → address-to-turn rule → saved image on another receiver → score with separate clock. Values, references, orientation and events stay distinct; Colour continues with familiar geometry and per-instance materials.',
        note='Five canonical tutorials complete for this pass, using the reviewed Array draft and four new minimal constructions. Seven printed files; fresh 451 native checks and 15 rejected faults. Walls loads Floor output in a separate engine process. Current final.md and runtime unchanged. Read ARRAYS_SUMMARIES.md. Colour is next.')
    assert [l for l in plan['lessons'] if l['id'] not in HALLS]==[l for l in original['lessons'] if l['id'] not in HALLS]
    assert [s for s in plan['sequences'] if s['id']!='array_tutorial']==[s for s in original['sequences'] if s['id']!='array_tutorial']
    assert plan['topics']==original['topics']
    revisions=json.loads((base/'authorized-revisions.json').read_text())
    protected=json.loads((base/'protected-sources.json').read_text())
    for hall in HALLS:
        path=f'commons/maps/{hall}/tutorial.md'
        revisions[path]={'date':'2026-10-12','before':protected.get(path),'after':sha(ROOT/path),'reason':'Author requested continuing one sequence at a time from Transformation. Complete Arrays lineage and printed programs, native tested; current final.md and museum runtime preserved.'}
    put(base/'history/2026-10-12-arrays-incorporation.json',json.dumps(original,ensure_ascii=False,indent=2)+'\n')
    current=json.loads((base/'plan.json').read_text(encoding='utf-8'))
    assert current==original or current==plan, 'Concurrent plan edit; reconcile before publication.'
    atomic_put(base/'plan.json',json.dumps(plan,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'authorized-revisions.json',json.dumps(revisions,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'lesson-summaries.txt',export)
    put(base/'ARRAYS_SUMMARIES.md',(HERE/'SUMMARIES.md').read_text(encoding='utf-8')+'\n[Paired reading report](../../iterations/2026-10-12-arrays-in-the-book/index.html) · [Edit the plan](http://localhost:3003/tutorial-plan?view=summaries&map=Array)\n')
    put(HERE/'plan-receipt.json',json.dumps({'updated_lessons':HALLS,'other_lessons_unchanged':True,'other_sequences_unchanged':True,'topics_unchanged':True,'decision':'accepted execution scope; revisable text','plan_sha256':sha(base/'plan.json')},indent=2)+'\n')
    print('Five Arrays plans and short summaries updated; other sequence plans unchanged.')

if __name__=='__main__':main()
