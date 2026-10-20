"""Align the Rotation teaching choice using the revision-checked history API."""
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
    choice=dict(subjects=['Axis, angle and pivot','Degrees and radians','Local offsets under a rotating parent','Reparenting while keeping local coordinates','An attached face mark'],
        focus='Continue the tested Translation files. Keep BoxBody, box(), _process(), travel and the body dimensions. Add a pivot; reparent the body with its local transform retained. Convert a timed turn to radians and set the parent orientation. Attach a dark mark using the inherited constructor. Offset the child to make an orbit, then change the axis and duration. Compare fixed local coordinates, changing world positions and return of the face mark. Multiple-axis composition and rider counter-rotation remain later encounters.')
    cards=get('/api/tutorial-cards')
    post('/api/tutorial-cards',dict(revision=cards['revision'],map=HALL,**choice))
    path=ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    document=json.loads(path.read_text(encoding='utf-8'))
    row=next(r for r in document['halls'] if r['map']==HALL)
    row.update(**choice,status='aligned',tutorial_sha256_after=sha(CANONICAL),revision_report='doc/book/iterations/2026-10-16-rotation-carried-body/index.html',
        builds_on=[{'map':'Trans_Translation','why':'Exact tested scripts; unchanged BoxBody, box(), _process(), travel and dimensions.'},{'map':'Point_Coordinates','why':'A child position is local to a parent; the parent transform determines its world position.'}],
        adds='A pivot and axis-angle orientation; explicit local-preserving reparenting; a face mark inherited through the hierarchy.',
        carries='BoxBody, placement function and clock; pivot/body/mark hierarchy with fixed internal distances.',
        review=f'Four printed edits reconstruct two runnable checkpoints. {receipt["native_assertions"]} native assertions; three exercises, one axis-length case; five behavioural faults detected. Physical riders, headsets and learner understanding remain outside this evidence.')
    put(path,json.dumps(document,ensure_ascii=False,indent=2)+'\n')
    current=get('/api/tutorial-plan')
    plan=next(r for r in current['plan']['lessons'] if r['id']==HALL)
    plan.update(summary=choice['focus'],object='Translation’s same BoxBody visual beneath a pivot, with a second BoxBody as face mark',
        change='Four edits: pivot values, parent-body setup, axis-angle pose function, face-mark insertion.',
        reuses='Exact Translation lesson.gd and byte-identical box_body.gd; unchanged box(size, at), _process(delta), travel reference and visual dimensions.',
        given='Prepared Endless Museum room, light and viewer. Empty floor-level TransformStudy, zero rotation and unit scale. New pivot, body and mark are made by the lesson; installed riding remains supplied.',
        checks=['Apply only four printed edits to Translation and match both runnable checkpoints and full files exactly.', 'Run assembled scenes in Godot; check spin/orbit at 30 and 120 updates per second, fixed local offset, changed world position, attached mark, rigid shape and continued turning.', 'Run the three exercises and a non-unit axis; reject five deliberate behavioural faults and eight missing/ambiguous edit anchors.'],
        transfer='Predict the quarter-turn centre with a two-metre offset, then with negative Z as axis; double the duration and explain which value controls plane, radius and timing.',
        carry='Unchanged BoxBody, box() and clock; a hierarchy that carries the body and face mark through one parent transform.',
        next='Repair Trans_Scale from the complete Rotation files: preserve BoxBody and make the changing parent and fixed size witness explicit.',
        notes=f'16 October continuation edition. {receipt["native_assertions"]} native assertions; four exact edits, three exercise variants and five behavioural faults detected. Receipt: doc/book/iterations/2026-10-16-rotation-carried-body/verification.json. Reflection and museum runtime unchanged; Scale handoff still needs this continuation pass.')
    saved=post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=plan))
    evidence=next(e for e in saved['evidence'] if e['id']==HALL)
    assert not evidence['choiceChanged'] and not evidence['sourceChanged'] and evidence['written']=='aligned'
    # The previous row's next-step sentence should point to the continuation now delivered.
    current=get('/api/tutorial-plan')
    previous=next(r for r in current['plan']['lessons'] if r['id']=='Trans_Translation')
    previous['next']='Trans_Rotation now continues these exact files: keep BoxBody, box() and _process(), add a pivot and preserve the child’s local transform when reparenting.'
    previous['notes']=previous['notes'].replace('Rotation remains the next handoff to repair.','Rotation continuation completed in doc/book/iterations/2026-10-16-rotation-carried-body/.')
    post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=previous))
    put(HERE/'plan-sync.json',json.dumps(dict(passed=True,evidence=evidence,scope='Rotation card, lineage and plan; Translation next-step text. API retains earlier choices in history.'),indent=2)+'\n')
    print('Rotation subjects and lineage match the tested continuation.')

if __name__=='__main__': main()

