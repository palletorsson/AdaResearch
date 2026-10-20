"""Update Tiling alone; preserve the wider plan and its freedom to change."""
from prepare import HERE, ROOT, HALLS, put, sha
import copy, json, os, re, tempfile

def atomic_put(path,text):
    handle,name=tempfile.mkstemp(prefix=path.name+'.',suffix='.tmp',dir=path.parent)
    with os.fdopen(handle,'w',encoding='utf-8',newline='') as f:f.write(text)
    os.replace(name,path)

def main():
    assert not (HERE/'plan-receipt.json').exists(),'Already synchronized.'
    evidence=json.loads((HERE/'sequence-verification.json').read_text());assert evidence['passed']
    before=json.loads((HERE/'before-sources.json').read_text());base=ROOT/'doc/book/course/execution-plan'
    for n in ['plan.json','authorized-revisions.json','lesson-summaries.txt']:
        assert sha(base/n)==before[f'doc/book/course/execution-plan/{n}'],n
    plan=json.loads((base/'plan.json').read_text(encoding='utf-8')); original=copy.deepcopy(plan)
    rows=json.loads((HERE/'lineage.json').read_text());lookup={x['id']:x for x in plan['lessons']}
    summaries=(base/'lesson-summaries.txt').read_text(encoding='utf-8')
    report=HERE.relative_to(ROOT).as_posix()+'/index.html'
    note='12 October: continue from Colour using current complete Tiling drafts, including later loom/garment refinements. 36 printed file occurrences; 647 native assertions and 12 explicit transfer assertions passed. Entry programs and current reflections retained; inherited GridSurface hint aligned with Colour. Teacher-authored evidence, not a blind student or headset trial. Accepted execution scope; writing remains revisable. '+report
    for item in rows:
        h=item['id'];entry=lookup[h]
        assert all(d in lookup for d in item['dependsOn'])
        entry.update(decision='accepted',mode=item['mode'],dependsOn=item['dependsOn'],summary=item['summary'],carry=item['carry'],next=item['next'])
        entry['notes']=entry.get('notes','').rstrip()+'\n\n'+note
        entry['checks']=entry.get('checks',[])+['Fresh 12 October reconstruction of the exact printed files passes native Godot assertions; evidence is teacher-authored.']
        entry['baseline']['tutorial']=sha(ROOT/f'commons/maps/{h}/tutorial.md')
        if h=='Ribbon_Patterns_01':entry['later']='Optional volume branch. The later surface comparison and sampling shader do not depend on completing it.'
        if h=='Ribbon_Patterns_03':
            entry['transfer']='After the guided repeat edit, choose another positive vertical count and predict a texel and physical spacing before running. Explain why SAVE transfers the supported recipe but not the edited shader.'
    # The older export omitted Temple. Replace only this sequence section so all
    # nine current halls appear in spine order, rather than retaining that gap.
    section='## Patterns: Dress the Architecture\n\nSeparate a source from its repeated interpretations.\n\nSequence demonstration: Predict a source address and its visible occurrences; compare changing the reader with editing or copying its data.\n\n'
    section+='\n\n'.join('### '+item['id']+'\n\n'+item['summary']+'\n\nPlan: accepted execution scope; current complete code; fresh 12 October teacher-authored evidence.\n\nEvidence: '+report for item in rows)+'\n'
    summaries,n=re.subn(r'## Patterns: Dress the Architecture\n.*?(?=\n## |\Z)',lambda m:section,summaries,flags=re.S)
    assert n==1,'Tiling summary section'
    sequence=next(s for s in plan['sequences'] if s['id']=='tiling')
    sequence.update(carry='Colour PointBody, Palette and GridSurface → independent palette/phase → source entries → reflected reads → physical frames → glide → copied recipes → optional volume → controlled comparison → UV sampling and a saved garment recipe.',
        check='Predict a source address and all its visible occurrences. Keep source values fixed while changing one reader operation; distinguish this from editing or copying the source.',
        note='All nine full tutorials and Ribbon companions exist. Current 9–10 October loom and garment revisions preserved. Most entry scripts initialize declared state; reuse is not automatic saved-state transfer. Optional loom cloth is explicitly saved for the cutting table. The five-column preview cuts a six-column reflected period short; a wider view remains a proposed spatial improvement. See TILING_SUMMARIES.md. Accepted execution scope; revisable text.')
    assert [x for x in plan['lessons'] if x['id'] not in HALLS]==[x for x in original['lessons'] if x['id'] not in HALLS]
    assert [x for x in plan['sequences'] if x['id']!='tiling']==[x for x in original['sequences'] if x['id']!='tiling']
    assert plan['topics']==original['topics']
    revisions=json.loads((base/'authorized-revisions.json').read_text());protected=json.loads((base/'protected-sources.json').read_text())
    for h in HALLS:
        path=f'commons/maps/{h}/tutorial.md'
        revisions[path]={'date':'2026-10-12','before':protected.get(path),'after':sha(ROOT/path),'reason':'Author requested continuing Tiling from the existing drafts with Colour lineage. Bounded handoff/readout and exercise wording edits; complete current entry programs and reflections preserved; fresh native evidence.'}
    put(base/'history/2026-10-12-tiling-continuity.json',json.dumps(original,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'plan.json',json.dumps(plan,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'authorized-revisions.json',json.dumps(revisions,ensure_ascii=False,indent=2)+'\n')
    atomic_put(base/'lesson-summaries.txt',summaries)
    put(base/'TILING_SUMMARIES.md',(HERE/'SUMMARIES.md').read_text(encoding='utf-8')+'\n[Paired reading](../../iterations/2026-10-12-tiling-in-the-book/index.html) · [Editable plan](http://localhost:3003/tutorial-plan?view=summaries&map=Pattern_Disco)\n')
    put(HERE/'plan-receipt.json',json.dumps({'updated_lessons':HALLS,'other_lessons_unchanged':True,'other_sequences_unchanged':True,'topics_unchanged':True,'decision':'accepted execution scope; revisable text','plan_sha256':sha(base/'plan.json')},indent=2)+'\n')
    print('Nine Tiling plans synchronized. Other lesson and sequence decisions preserved.')

if __name__=='__main__':main()
