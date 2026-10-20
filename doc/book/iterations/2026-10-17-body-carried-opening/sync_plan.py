"""Align this hall's teaching choice; retain earlier decisions in API history."""
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
    for path,digest in receipt['inputs'].items(): assert sha(ROOT/path)==digest,path
    choice=dict(subjects=['The existing viewpoint as input','World positions and horizontal separation','Metres mapped to a bounded fraction','A fraction choosing scale','Reversible response without a stored path'],
        focus='Continue the exact Scale files. Retain BoxBody, box(), apply_pose(), the doorway parent and three parts, and the fixed sphere. Three insertions read the existing active walking/XR camera, project world separation onto the floor, map near/far distance to a bounded fraction and interpolate an enlargement factor. Predict near, midpoint and far opening sizes. Test extended reach, width-only response and reversed output. The viewpoint is explicit input, not a collision body; installed multi-body collision, smoothing and retained cuts remain outside this visual study.')
    cards=get('/api/tutorial-cards')
    post('/api/tutorial-cards',dict(revision=cards['revision'],map=HALL,**choice))
    path=ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    document=json.loads(path.read_text(encoding='utf-8'))
    row=next(r for r in document['halls'] if r['map']==HALL)
    row.update(**choice,status='aligned',tutorial_sha256_after=sha(CANONICAL),revision_report='doc/book/iterations/2026-10-17-body-carried-opening/index.html',
        builds_on=[{'map':'Trans_Scale','why':'Exact tested frame, fixed sphere, BoxBody, box() and apply_pose(Vector3) continue.'},{'map':'Point_Coordinates','why':'World versus local positions; declared reference to existing museum support.'},{'map':'Trans_Translation','why':'Interpolation now chooses size rather than a route position.'}],
        adds='Active viewpoint supplies horizontal distance; a clamped fraction chooses the inherited parent scale.',
        carries='Unchanged doorway and constructor; independent reference; tested distance-to-factor response.',
        review=f'Three insertions, 16 nonblank code lines, reconstruct from Scale. {receipt["native_assertions"]} native assertions; three exercise variants, five faults and six bad anchors rejected. Camera classes tested with deterministic positions; physical XR and learner understanding untested.')
    put(path,json.dumps(document,ensure_ascii=False,indent=2)+'\n')
    current=get('/api/tutorial-plan')
    plan=next(r for r in current['plan']['lessons'] if r['id']==HALL)
    plan.update(summary=choice['focus'],object='Scale’s three-BoxBody doorway and fixed sphere, driven by the existing active viewpoint',
        change='Three insertions: reach declarations; range assertions in _ready; _process and respond. All incoming Scale code retained.',
        reuses='Exact Scale files; unchanged box_body.gd, box(), apply_pose(), parent membership, doorway construction and sphere. World positions and scalar interpolation return.',
        given='Existing Endless Museum room, light and active walking/XR camera in the study viewport; floor-level host with unit scale and no tilt. Camera reference is reacquired each frame. Lesson remains visual; no collision or body-tracking reconstruction.',
        later='Collision and timed combined passage; multiple visitors; smoothing; permanent cell removal.',
        checks=['Mechanically insert the three printed fragments into exact Scale files and compare with full online output; retain previous source and reflection.', 'Execute incoming Scale and Body scenes; measure near/middle/far and outside-range opening sizes, local geometry, fixed witness and threshold; verify horizontal world separation under different parents, no accumulation and retreat.', 'Run extended reach, width-only and reversed response files; actual Camera3D/XRCamera3D test positions, missing/late/freed/replacement cameras and live frames; reject five faults and six bad anchors.'],
        transfer='Choose another far limit and predict its midpoint. Explain separately the input reach, maximum scale and parent membership; compare width-only and reversed response.',
        carry='Same BoxBody frame and fixed witness; bounded distance-to-factor function feeding apply_pose(Vector3).',
        next='Repair Trans_Body → Trans_Pit from this edition: add timed, combined and solid passage without silently replacing the inherited construction.',
        notes=f'17 October continuation edition: {receipt["native_assertions"]} native assertions; three exercise variants, five faults and six bad anchors rejected. Receipt doc/book/iterations/2026-10-17-body-carried-opening/verification.json. This replaces the old standalone cube tutorial; older sequence receipts remain historical. Physical XR, collision and learner understanding are not certified.')
    saved=post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=plan))
    evidence=next(e for e in saved['evidence'] if e['id']==HALL)
    assert not evidence['choiceChanged'] and not evidence['sourceChanged'] and evidence['written']=='aligned'
    current=get('/api/tutorial-plan')
    previous=next(r for r in current['plan']['lessons'] if r['id']=='Trans_Scale')
    previous['next']='Trans_Body now continues these exact files: retain the frame, fixed sphere, BoxBody and apply_pose(); add active-viewpoint distance as the input.'
    previous['notes']=previous['notes'].replace('Trans_Body remains the next handoff to repair.','Trans_Body continuation completed in doc/book/iterations/2026-10-17-body-carried-opening/.')
    post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=previous))
    put(HERE/'plan-sync.json',json.dumps(dict(passed=True,evidence=evidence,scope='Body card, lineage and plan; Scale next-step text. API retains earlier choices in history.'),indent=2)+'\n')
    print('Body card, lineage and plan aligned with the tested continuation.')

if __name__=='__main__': main()
