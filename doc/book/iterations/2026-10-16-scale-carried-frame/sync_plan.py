"""Align the Scale teaching choice using the revision-checked history API."""
import json
import urllib.request
from prepare import HERE, ROOT, HALL, CANONICAL, put, sha

BASE='http://localhost:3003'
def get(endpoint):
    return json.load(urllib.request.urlopen(BASE+endpoint,timeout=90))
def post(endpoint,payload):
    req=urllib.request.Request(BASE+endpoint,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json','Origin':BASE},method='POST')
    return json.load(urllib.request.urlopen(req,timeout=90))

def main():
    receipt=json.loads((HERE/'verification.json').read_text(encoding='utf-8'))
    assert receipt['passed']
    choice=dict(subjects=['Uniform and unequal scale factors','Child dimensions and child spacing','A threshold origin at floor level','A fixed reference outside the parent'],
        focus='Continue Rotation’s exact tested files. Retain BoxBody, box(), the pivot declaration and local-preserving reparenting. Replace the moving body and clock with three doorway parts under the fixed parent and a sphere beside it. apply_pose explicitly changes from a float time fraction to Vector3 scale factors. Compare uniform, width-only and XY enlargement using predicted clear dimensions; keep stored local data and the reference sphere unchanged. Installed collision and room relocation remain supplied.')
    cards=get('/api/tutorial-cards')
    post('/api/tutorial-cards',dict(revision=cards['revision'],map=HALL,**choice))
    path=ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    document=json.loads(path.read_text(encoding='utf-8'))
    row=next(r for r in document['halls'] if r['map']==HALL)
    row.update(**choice,status='aligned',tutorial_sha256_after=sha(CANONICAL),revision_report='doc/book/iterations/2026-10-16-scale-carried-frame/index.html',
        builds_on=[{'map':'Trans_Rotation','why':'Exact tested scripts; unchanged BoxBody and box(); parent declaration and explicit local-preserving reparenting.'},{'map':'Point_One','why':'A familiar visible sphere; this new witness is constructed explicitly and has no collider or pickup.'}],
        adds='Scale the parent’s child sizes and spacing around a threshold origin; keep a reference outside the group.',
        carries='BoxBody and placement function; Vector3 scale input, parent scope and an independent reference.',
        review=f'Five printed instructions reconstruct the completed state, including two deletions. {receipt["native_assertions"]} native assertions; three exercises and one depth-only case; four behavioural faults detected. Physical passage and learner understanding remain separate observations.')
    put(path,json.dumps(document,ensure_ascii=False,indent=2)+'\n')
    current=get('/api/tutorial-plan')
    plan=next(r for r in current['plan']['lessons'] if r['id']==HALL)
    plan.update(summary=choice['focus'],object='A three-BoxBody doorway under Rotation’s retained parent, with a fixed sphere sibling',
        change='Five edits: remove travel, replace angle/clock declarations, remove _process, construct the doorway and sphere, change apply_pose to Vector3 scale.',
        reuses='Exact Rotation scripts; unchanged box_body.gd and box(size, at), retained pivot declaration and local-preserving reparenting.',
        given='Prepared Endless Museum room, light and viewer; empty floor-level TransformStudy with zero rotation and unit scale. Lesson creates its own visuals; installed room supplies collision and bodily passage.',
        checks=['Apply all five printed instructions, including removals, to the exact Rotation output and compare complete files.', 'Measure actual transformed opening, post spacing, world dimensions and floor contact; assert unchanged local data and sphere, repeated scale assignment and static real-frame behaviour.', 'Run uniform, width-only and XY exercises plus a depth case; reject four behavioural faults and ten missing/ambiguous anchors.'],
        transfer='Predict width, height and depth under (2,2,1); explain why the sphere stays fixed and why scaling parts alone differs from scaling their parent.',
        carry='Unchanged BoxBody and box(); a fixed parent grouping child positions and dimensions; Vector3 scale input and independent reference.',
        next='Repair Trans_Body from these completed Scale files: reuse BoxBody and replace a chosen factor with input from the existing visitor.',
        notes=f'16 October continuation edition. {receipt["native_assertions"]} native assertions; three exercises plus depth case, four behavioural faults rejected. Receipt: doc/book/iterations/2026-10-16-scale-carried-frame/verification.json. Reflection and museum runtime unchanged; Trans_Body remains the next handoff to repair.')
    saved=post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=plan))
    evidence=next(e for e in saved['evidence'] if e['id']==HALL)
    assert not evidence['choiceChanged'] and not evidence['sourceChanged'] and evidence['written']=='aligned'
    current=get('/api/tutorial-plan')
    previous=next(r for r in current['plan']['lessons'] if r['id']=='Trans_Rotation')
    previous['next']='Trans_Scale now continues these exact files: retain BoxBody, box() and the parent; place a doorway beneath it and keep a sphere outside the changing group.'
    previous['notes']=previous['notes'].replace('Scale handoff still needs this continuation pass.','Scale continuation completed in doc/book/iterations/2026-10-16-scale-carried-frame/.')
    post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=previous))
    put(HERE/'plan-sync.json',json.dumps(dict(passed=True,evidence=evidence,scope='Scale card, lineage and plan; Rotation next-step text. API retains earlier choices in history.'),indent=2)+'\n')
    print('Scale learning elements and lineage now match the tested continuation.')

if __name__=='__main__': main()

