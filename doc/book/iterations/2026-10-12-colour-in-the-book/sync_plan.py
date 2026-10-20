"""Update only the eight Colour lesson plans and their sequence note."""
from prepare import HERE, ROOT, HALLS, put, sha
import copy, json, os, re, tempfile, time

def atomic_put(path,text):
    handle,name=tempfile.mkstemp(prefix=path.name+'.',suffix='.tmp',dir=path.parent)
    with os.fdopen(handle,'w',encoding='utf-8',newline='') as f:f.write(text)
    for attempt in range(10):
        try:os.replace(name,path);return
        except OSError:
            if attempt==9:raise
            time.sleep(0.1)

def main():
    assert not (HERE/'plan-receipt.json').exists(),'Already synchronized.'
    evidence=json.loads((HERE/'sequence-verification.json').read_text());assert evidence['passed']
    base=ROOT/'doc/book/course/execution-plan'; before=json.loads((HERE/'before-sources.json').read_text())
    for name in ['plan.json','authorized-revisions.json','lesson-summaries.txt']:assert sha(base/name)==before[f'doc/book/course/execution-plan/{name}'],name
    plan=json.loads((base/'plan.json').read_text(encoding='utf-8')); original=copy.deepcopy(plan)
    lookup={x['id']:x for x in plan['lessons']};lineage=json.loads((HERE/'lineage.json').read_text())
    export=(base/'lesson-summaries.txt').read_text(encoding='utf-8');report='doc/book/iterations/2026-10-12-colour-in-the-book/index.html'
    for item in lineage:
        lesson=lookup[item['id']]
        assert all(d in lookup for d in item['dependsOn'])
        lesson.update(decision='accepted',mode='compose' if item['id'] in ['Color_Rainbow','Color_Walls'] else 'build',
            object=item['object'],change=item['change_note'],dependsOn=item['dependsOn'],given=item['given'],
            checks=[item['check'],'Exact printed files execute under native Godot; deliberate faults fail their intended behavioural checks.'],
            transfer=item['transfer'],carry=item['carry'],next=item['next'],summary=item['summary'],
            notes='12 October: author continued from Arrays, one sequence at a time. Reviewed Colour drafts incorporated; supplied Grid/Walls pointer controls added. 811 native assertions, 39 render checks, 36 configurations, 27 rejected faults. Teacher-authored synthetic evidence; current final texts and museum runtime preserved. Accepted execution scope, revisable text. '+report)
        lesson['baseline']['tutorial']=sha(ROOT/f'commons/maps/{item["id"]}/tutorial.md')
        if item['id']=='Color_Context_Placed':lesson['later']='Full stacks, automatic category inference and art/design DNA remain larger museum encounters; the five-part program gives a complete minimal assignment.'
        if item['id']=='Color_Rainbow':lesson['later']='The making lesson is optional. Celebration, pickups and banner are installed encounters; no wavelength simulation is implied.'
        if item['id']=='Color_Paint':lesson['later']='Automatic caller is optional after the manual mark works. Mist, wetness, runs and GPU accumulation are outside the reduced circular-stamp model.'
        if item['id']=='Color_Walls':lesson['later']='Larger office, RGB/HSV models and interpolation bench remain separate encounters. This two-pane study reuses the exact taught Palette class.'
        pattern=rf'(### {re.escape(item["id"])}\n\n).*?(?=\n### |\n## |\Z)'
        export,n=re.subn(pattern,lambda m:m.group(1)+item['summary']+'\n\nPlan: accepted execution scope; canonical full code; fresh 12 October teacher-authored evidence.\n\nEvidence: '+report+'\n',export,flags=re.S)
        assert n==1,item['id']
    sequence=next(s for s in plan['sequences'] if s['id']=='color')
    sequence.update(carry='Arrays addresses → material assignments → illumination → position-to-colour → ordered bands → sampled HSV field → Palette state → retained surface marks → independent panes. Familiar PointBody and Palette return unchanged; numerical handoffs are explicit records. Pattern_Disco next separates pattern from palette.',
        note='Eight canonical tutorials now incorporate the reviewed drafts. 21 printed files; 811 native assertions, 39 render checks and 27 rejected faults. Grid/Walls have supplied museum pointer controls; Paint manual-first and Rainbow optional. Current reflections and live museum preserved. See COLOUR_SUMMARIES.md. Text remains revisable.')
    assert [x for x in plan['lessons'] if x['id'] not in HALLS]==[x for x in original['lessons'] if x['id'] not in HALLS]
    assert [x for x in plan['sequences'] if x['id']!='color']==[x for x in original['sequences'] if x['id']!='color']
    assert plan['topics']==original['topics']
    revisions=json.loads((base/'authorized-revisions.json').read_text());protected=json.loads((base/'protected-sources.json').read_text())
    for h in HALLS:
        p=f'commons/maps/{h}/tutorial.md'
        revisions[p]={'date':'2026-10-12','before':protected.get(p),'after':sha(ROOT/p),'reason':'Author requested continuing one sequence at a time. Reviewed Colour drafts incorporated with complete printed code and fresh native evidence; current final texts and museum runtime preserved.'}
    put(base/'history/2026-10-12-colour-incorporation.json',json.dumps(original,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'plan.json',json.dumps(plan,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'authorized-revisions.json',json.dumps(revisions,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'lesson-summaries.txt',export)
    put(base/'COLOUR_SUMMARIES.md',(HERE/'SUMMARIES.md').read_text(encoding='utf-8')+'\n[Paired reading report](../../iterations/2026-10-12-colour-in-the-book/index.html) · [Editable plan](http://localhost:3003/tutorial-plan?view=summaries&map=Color_Context_Placed)\n')
    put(HERE/'plan-receipt.json',json.dumps({'updated_lessons':HALLS,'other_lessons_unchanged':True,'other_sequences_unchanged':True,'topics_unchanged':True,'decision':'accepted execution scope; revisable writing','plan_sha256':sha(base/'plan.json')},indent=2)+'\n')
    print('Eight Colour plans and sequence summary synchronized; other plans preserved.')

if __name__=='__main__':main()
