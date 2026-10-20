"""Save the two reviewed teaching choices through the existing revision/history API."""
import json
import urllib.request
from prepare import HERE, ROOT, HALLS, put, sha

BASE='http://localhost:3003'
def get(endpoint):
    return json.load(urllib.request.urlopen(BASE+endpoint,timeout=60))
def post(endpoint, payload):
    request=urllib.request.Request(BASE+endpoint,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json','Origin':BASE},method='POST')
    return json.load(urllib.request.urlopen(request,timeout=60))

def main():
    assert json.loads((HERE/'verification.json').read_text())['passed']
    choices={
      'Trans_Pre':dict(subjects=['Reusable visual class','Translation','Rotation','Uniform scale','Elapsed time and a return cycle','Overlap detection','Signals and player filtering'],
        focus='Branch from the saved Melencolia arrangement. Name the deliberate change from bottom-origin CubeBody to centred BoxMesh. Create BoxBody once; place one instance and give it timed position, rotation and uniform scale. Then add an Area3D and player-filtered collection signal. The museum supplies the environment and player. Keep the complete collectible copy for Arrays and carry box_body.gd unchanged into Introduction.'),
      'Trans_Introduction':dict(subjects=['Reusing a visual class','Independent instances','Returning placement function','Bounded pose fraction','Interpolation','Pose versus clock'],
        focus='Start with the exact completed Pre files. Carry box_body.gd unchanged; remove collection. Use a returning placement function to make three visual crossing models and their banks. Separate apply_pose from the clock, hold poses at 0, 0.5 and 1, then move the far bank without changing the end pose. Period remains one full return cycle. The models have no blocking collision; installed crossings supply riding.')}
    for hall,fields in choices.items():
        current=get('/api/tutorial-cards')
        post('/api/tutorial-cards',dict(revision=current['revision'],map=hall,**fields))
    lineage=ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    saved=lineage.read_text(encoding='utf-8')
    put(HERE/'before/lineage-opening.json',saved)
    document=json.loads(saved)
    for row in document['halls']:
        if row['map'] not in HALLS: continue
        hall=row['map']
        row.update(**choices[hall],status='aligned',tutorial_sha256_after=sha(ROOT/'commons/maps'/hall/'tutorial.md'),revision_report='doc/book/iterations/2026-10-16-transformation-handoff/index.html')
        row['review']='Canonical printed edits reconstruct the complete runnable files. Combined native evidence: 68 assertions, eight variants, four behavioural faults detected. Museum and reflective texts preserved. This is code verification, not a human-learning or headset result.'
        row['builds_on']=[{'map':'Primitives_Melencolia','why':'The actual saved arrangement script is the incoming file; the representation change is explicit.'},{'map':'Point_Zero','why':'Initialization and elapsed-time updates return.'}] if hall=='Trans_Pre' else [{'map':'Trans_Pre','why':'Exact completed pickup script plus the unchanged BoxBody file.'}]
        row['adds']='Timed transforms and an overlap-driven response; an explicit centred visual class.' if hall=='Trans_Pre' else 'Independent instances, returning placement, a held pose separate from time.'
        row['carries']='BoxBody, seconds, three transforms, and a saved collectible branch for Arrays.' if hall=='Trans_Pre' else 'Unchanged BoxBody, box placement function, bounded pose and interpolation.'
    put(lineage,json.dumps(document,ensure_ascii=False,indent=2)+'\n')
    for hall in HALLS:
        current=get('/api/tutorial-plan')
        row=next(r for r in current['plan']['lessons'] if r['id']==hall)
        row['summary']=choices[hall]['focus']
        row['given']='Existing Endless Museum environment and player; empty floor-level TransformStudy with zero rotation and unit scale. All example geometry and interaction code is in the printed edits and complete linked files.'
        row['notes']='16 October handoff edition: exact predecessor + printed edits = complete linked files. Native receipt: doc/book/iterations/2026-10-16-transformation-handoff/verification.json. Combined 68 assertions, eight variants, four behaviour faults and sixteen rejected bad anchors. No museum runtime or final.md changes. Introduction to Translation remains the next repair.'
        if hall=='Trans_Pre':
            row.update(object='One BoxBody using its own centred BoxMesh, with a child detection area',change='Explicit representation branch; new visual class; timed transforms; then collection.',dependsOn=['Point_Zero','Point_Trace','Point_Animatedcube','Primitives_Melencolia'],reuses='The actual Melencolia host script, local placement, class construction and Point Zero callbacks.',carry='Unchanged box_body.gd; elapsed-time transform logic; saved pickup version for Arrays.',next='Introduction edits this completed copy, removes collection and reuses BoxBody unchanged.')
        else:
            row.update(object='Three independent BoxBody crossing models and six banks',change='Reuse the exact class; replace the arrangement and collection; separate pose from clock.',reuses='Pre lesson.gd and byte-identical box_body.gd; period continues to mean a full return cycle.',carry='box_body.gd, returning box(size, at), bounded apply_pose(value) and a separate clock.',next='Repair Translation to reuse this edition’s BoxBody and placement function, adding its route only.')
        row['checks']=['Reconstruct from the pinned predecessor using only canonical printed edits; exact equality with full downloadable files.','Run the assembled programs and stated variants in Godot; deliberate faults must fail their intended behaviour assertion.',row['transfer']]
        post('/api/tutorial-plan',dict(kind='lesson',revision=current['revision'],record=row))
    result=get('/api/tutorial-plan')
    selected=[e for e in result['evidence'] if e['id'] in HALLS]
    assert all(not e['sourceChanged'] and not e['choiceChanged'] and e['written']=='aligned' for e in selected),selected
    put(HERE/'plan-sync.json',json.dumps({'passed':True,'evidence':selected,'scope':'Two teaching cards, two lineage records and two plan rows; API saves retain history. Native receipt lives with this edition; older ghost records are not relabelled.'},indent=2)+'\n')
    print('Two teaching choices and plan rows now match the canonical handoff.')

if __name__=='__main__':main()
