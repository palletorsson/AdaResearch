"""Update only Transformation's editable plans after the canonical-source tests pass."""
from pathlib import Path
import copy
import json
import re
import shutil
from prepare import HERE, ROOT, HALLS, put, sha

def main():
    assert not (HERE/'plan-receipt.json').exists(), 'Already reconciled; use the live editor for later decisions.'
    evidence=json.loads((HERE/'verification.json').read_text())
    assert evidence['passed']
    lineage=json.loads((HERE/'lineage.json').read_text())
    base=ROOT/'doc/book/course/execution-plan'
    original=(base/'plan.json').read_bytes()
    plan=json.loads(original)
    before=copy.deepcopy(plan)
    for name in ['plan.json','authorized-revisions.json','TRANSFORMATION_SUMMARIES.md','lesson-summaries.txt']:
        shutil.copyfile(base/name,HERE/('before-'+name))
    by_id={entry['id']:entry for entry in plan['lessons']}
    contracts=json.loads((ROOT/'doc/book/iterations/2026-10-06-transformation-tutorial-drafts/contracts.json').read_text())
    contract={c['map']:c for c in contracts}
    report='doc/book/iterations/2026-10-12-transformation-in-the-book/index.html'
    prior={
        'Trans_Pre':['Point_Zero','Point_One','Point_Trace','Point_Animatedcube'],
        'Trans_Introduction':['Trans_Pre'],
        'Trans_Translation':['Trans_Introduction','Point_Lines'],
        'Trans_Rotation':['Trans_Translation','Point_Coordinates'],
        'Trans_Scale':['Trans_Rotation'],
        'Trans_Body':['Trans_Scale','Point_Coordinates'],
        'Trans_Pit':['Trans_Pre','Trans_Body','Point_Trace']}
    export=(base/'lesson-summaries.txt').read_text(encoding='utf-8')
    for entry in lineage:
        hall=entry['id']; lesson=by_id[hall]; c=contract[hall]
        lesson.update(decision='accepted', object=entry['object'], change=c['build'],
            dependsOn=prior[hall], reuses=c['bring'],
            given='Existing Endless Museum room, light, camera and player. A floor-level, unrotated, unit-scale TransformStudy hosts the complete printed lesson.gd. New lesson geometry is created in code. Player lookup is declared; installed riding is supplied. The final door creates its own solid boundaries.',
            later=c['later'], checks=[c['check'], 'Exact printed canonical program and its named source variations execute in Godot; the deliberate behavioural fault must fail the intended assertion.'],
            transfer=c['check'], carry=entry['carry'], next=entry['next'], summary=entry['summary'],
            notes='12 October author requested using the existing Transformation drafts, keeping the lineage into Arrays, one sequence at a time. Seven canonical tutorials now contain the reviewed programs. Fresh sequence evidence: 204 native assertions, 19 variants, 12 detected behavioural faults. Programs unchanged from review; current reflections and runtime preserved. Acceptance selects this execution scope; manuscript and teaching choices remain revisable. '+report)
        lesson['baseline']['tutorial']=sha(ROOT/'commons/maps'/hall/'tutorial.md')
        pattern=rf'(### {re.escape(hall)}\n\n).*?(?=\n### |\n## |\Z)'
        replacement=rf'\g<1>{entry["summary"]}\n\nPlan: accepted execution scope; tutorial: canonical reconstruction; native evidence: fresh 12 October sequence run.\n\nEvidence: {report}\n'
        export,count=re.subn(pattern,lambda m: m.group(1)+entry['summary']+'\n\nPlan: accepted execution scope; tutorial: canonical reconstruction; native evidence: fresh 12 October sequence run.\n\nEvidence: '+report+'\n',export,flags=re.S)
        assert count==1,hall
    sequence=next(s for s in plan['sequences'] if s['id']=='transformation')
    sequence['carry']='Whole BoxMesh construction, deliberate transform properties, parent-child scope, overlap detection and a solid composed opening. Arrays returns to still collectible cubes with addresses; no live-node transport is assumed.'
    sequence['note']='Seven canonical tutorial constructions reconciled from reviewed drafts and freshly tested 12 October. Current final texts preserved. Pre → crossings → journey → pivot → scale → approach → solid opening. Read TRANSFORMATION_SUMMARIES.md. Arrays is the next separate pass.'
    assert [x for x in before['lessons'] if x['id'] not in HALLS]==[x for x in plan['lessons'] if x['id'] not in HALLS]
    assert [x for x in before['sequences'] if x['id']!='transformation']==[x for x in plan['sequences'] if x['id']!='transformation']
    assert before['topics']==plan['topics']
    revisions=json.loads((base/'authorized-revisions.json').read_text())
    protected=json.loads((base/'protected-sources.json').read_text())
    for hall in HALLS:
        relative=f'commons/maps/{hall}/tutorial.md'
        assert relative in protected
        revisions[relative]={'date':'2026-10-12','before':protected[relative],'after':sha(ROOT/relative),
            'reason':'Author requested the existing Transformation drafts as the current tutorial sequence with lineage into Arrays. Seven complete printed programs; fresh 204 native assertions, 19 variants, 12 rejected faults. Current final texts, museum runtime and other sequences preserved.'}
    assert (base/'plan.json').read_bytes()==original,'Concurrent plan edit; reconcile before writing.'
    put(base/'history/2026-10-12-transformation-incorporation.json',json.dumps(before,ensure_ascii=False,indent=2)+'\n')
    put(base/'plan.json',json.dumps(plan,ensure_ascii=False,indent=2)+'\n')
    put(base/'authorized-revisions.json',json.dumps(revisions,ensure_ascii=False,indent=2)+'\n')
    put(base/'lesson-summaries.txt',export)
    summary=(HERE/'SUMMARIES.md').read_text(encoding='utf-8')
    summary+='\n## Reading and verification\n\nOne complete script per hall, one _ready function, geometry built in code, named existing museum support. The learner programs are byte-identical to the reviewed drafts. Fresh Godot execution checks the exact canonical text, 19 source variations and 12 deliberate faults. No headset or human-learning claim. Current final.md texts and map/runtime sources are preserved.\n\n[Seven paired readings](../../iterations/2026-10-12-transformation-in-the-book/index.html) · [Fresh evidence](../../iterations/2026-10-12-transformation-in-the-book/verification.json) · [Edit the plan](http://localhost:3003/tutorial-plan?view=summaries&map=Trans_Pre)\n'
    put(base/'TRANSFORMATION_SUMMARIES.md',summary)
    put(HERE/'plan-receipt.json',json.dumps({'updated_lessons':HALLS,'other_lessons_unchanged':True,'other_sequences_unchanged':True,'topics_unchanged':True,'decision':'accepted execution scope; revisable text','plan_sha256':sha(base/'plan.json')},indent=2)+'\n')
    print('Updated seven plans, Transformation summary and export. Other lesson and sequence records unchanged.')

if __name__=='__main__':main()
