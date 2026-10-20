"""Align the Translation teaching choice using the revision-checked history API."""
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
    choice=dict(subjects=['Displacement in a coordinate frame','Vector interpolation','One-way duration and arrival','Conditions selecting route segments','Reusing the visual and placement function'],
        focus='Continue the exact Introduction files. Keep BoxBody and box(size, at) unchanged; retain travel and the bounded apply_pose interface. Replace three comparison models with one level travelling surface. Use elapsed/duration for a one-way journey; compare direct interpolation with a route through one corner. Predict halfway and final positions, then add Z and change duration. The museum supplies installed riding; this study is visual. Waypoint indexing and constant-speed routes remain later topics.')
    cards=get('/api/tutorial-cards')
    post('/api/tutorial-cards',dict(revision=cards['revision'],map=HALL,**choice))
    path=ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    document=json.loads(path.read_text(encoding='utf-8'))
    row=next(r for r in document['halls'] if r['map']==HALL)
    row.update(**choice,status='aligned',tutorial_sha256_after=sha(CANONICAL),revision_report='doc/book/iterations/2026-10-16-translation-carried-body/index.html',
        builds_on=[{'map':'Trans_Introduction','why':'Exact tested incoming files, unchanged visual class and box function; bounded pose and elapsed seconds.'},{'map':'Point_Lines','why':'Displacement components describe a combined change in a named frame.'}],
        adds='A clamped one-way journey, vector interpolation and a condition selecting two route segments.',
        carries='Same BoxBody and placement function; prescribed positions, clock and a separate pose function.',
        review=f'Five printed edits reconstruct both runnable checkpoints. {receipt["native_assertions"]} native assertions; three exercise variants and one edge case; four behavioural faults detected. No museum-runtime, rider, headset or human-learning claim.')
    put(path,json.dumps(document,ensure_ascii=False,indent=2)+'\n')
    current=get('/api/tutorial-plan')
    plan=next(r for r in current['plan']['lessons'] if r['id']==HALL)
    plan.update(summary=choice['focus'],object='The same travel reference and BoxBody visual from Introduction',
        change='Five located edits: route values, one-body setup, one-way clock, direct vector interpolation, optional corner.',
        reuses='Introduction’s exact lesson.gd and byte-identical box_body.gd; unchanged box(size, at), travel reference, elapsed seconds and bounded apply_pose interface.',
        given='Prepared Endless Museum environment and viewer; empty floor-level TransformStudy with zero rotation and unit scale. Visual models have no rider physics; use installed carriers for riding.',
        checks=['Reconstruct from Introduction using only the five canonical printed edits; compare both checkpoints and full files exactly.', 'Assert quarter, halfway and endpoint positions at 30 and 120 updates per second, clamped arrival, fixed mesh/basis, local/world placement and no corner jump.', 'Test the three stated exercise variants and a zero-length edge case; reject four deliberate behavioural faults and ten bad edit anchors.'],
        carry='Unchanged BoxBody and box function; one level visual, endpoint values, clock and separate route pose.',
        next='Repair Rotation from this completed state, adding a pivot and making the placement parent explicit.',
        notes=f'16 October continuation edition. {receipt["native_assertions"]} native assertions on assembled scenes; exact predecessor and unchanged constructors verified. Receipt: doc/book/iterations/2026-10-16-translation-carried-body/verification.json. final.md and museum runtime unchanged. Rotation remains the next handoff to repair.')
    saved=post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=plan))
    evidence=next(e for e in saved['evidence'] if e['id']==HALL)
    assert not evidence['choiceChanged'] and not evidence['sourceChanged'] and evidence['written']=='aligned'
    put(HERE/'plan-sync.json',json.dumps(dict(passed=True,evidence=evidence,scope='Translation teaching card, lineage record and plan row; API retains prior choices in history.'),indent=2)+'\n')
    print('Translation subjects and lineage now match the reconstructed tutorial.')

if __name__=='__main__': main()
