"""Collect tested code, native museum views and an editable encounter report."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-crowd-a-direction-in-common'
HALL='SwarmIntelligence_FlowFields'
RUN=ROOT/f'ada_run/encounter_pilot/{HALL}/flow-crowd-third'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

code=read(ROOT/'ada_run/flow_crowd_checks.json');native=read(RUN/'report.json')
assert code['passed'] and native['passed']
assert all(c['passed'] for result in [code,native] for c in result['checks'])
for log in [ROOT/'ada_run/flow-crowd-checks.log',RUN/'stdout.log']:
    content=log.read_text(encoding='utf-8')
    assert all(error not in content for error in ['SCRIPT ERROR','SHADER ERROR','Invalid metadata identifier']),log
preserved=read(OUT/'before/preserved-hashes.json')
assert all(sha(ROOT/p)==digest for p,digest in preserved.items())
before=read(OUT/'before/commons/data/museum/em_plan.json');after=read(ROOT/'commons/data/museum/em_plan.json')
assert [p for p in before['plans'] if p['map']!=HALL]==[p for p in after['plans'] if p['map']!=HALL]
assert {k:v for k,v in before.items() if k!='plans'}=={k:v for k,v in after.items() if k!='plans'}
old=read(OUT/f'before/commons/maps/{HALL}/map_data.json');new=read(ROOT/f'commons/maps/{HALL}/map_data.json')
for layer in ['utilities','interactables']:
    assert all(cell==new['layers'][layer][z][x] for z,row in enumerate(old['layers'][layer]) for x,cell in enumerate(row))
assert all(len(rows)==15 and all(len(row)==33 for row in rows) for rows in new['layers'].values())
for folder in ['assets','evidence']:(OUT/folder).mkdir(exist_ok=True)
figures=[
 ('toward-a','A crowd follows the field around the island. Arrows show the supplied directions; no figure reads its neighbours.'),
 ('without-arrows','The same positions with the arrows hidden. Integration was paused only for this two-image comparison.'),
 ('ready','At visitor height: twenty-four point-headed figures wait at RETURN. Their sphere heads continue the chapter’s visual lineage.'),
 ('arrival','The same bodies reach A and stop in assigned places. Parking is an authored arrangement, separate from following the shared route.'),
 ('point-control','Carry the familiar black PointBody toward A or B. Trigger shows or hides arrows. Drop sends the group home.'),
 ('hall-above','The existing Flow Fields hall and its new east court, photographed from above. Original exhibit placements remain.')]
for name,_ in figures:shutil.copy2(RUN/f'{name}.png',OUT/'assets'/f'{name}.png')
for p,name in [(ROOT/'ada_run/flow_crowd_checks.json','code-checks.json'),(ROOT/'ada_run/flow-crowd-checks.log','code.log'),(RUN/'report.json','museum-checks.json'),(RUN/'stdout.log','museum.log'),(RUN/'source_manifest.json','museum-sources.json')]:shutil.copy2(p,OUT/'evidence'/name)
sources=[f'commons/artifacts/flow_crowd/{p}' for p in ['model.gd','flow_crowd.gd','flow_crowd.tscn','README.md']]+['commons/artifacts/registry/flow_crowd.json',f'commons/maps/{HALL}/map_data.json','commons/data/museum/em_plan.json','tools/probes/flow_crowd_checks.gd','tools/probes/flow_crowd_museum.gd']
(OUT/'evidence/source-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in sources},indent=2)+'\n',encoding='utf-8')
(OUT/'evidence/preserved-hashes.json').write_text(json.dumps(preserved,indent=2)+'\n',encoding='utf-8')
total=len(code['checks'])+len(native['checks'])
report=f'''# A direction in common

Endless Museum · Flow Fields · 11 October 2026

Twenty-four figures turn toward the same destination. At their feet, arrows lead around a low island. Carry the black point toward A or B and the field changes. Drop it and the same bodies return.

## Try the encounter

Reload **Swarm Intelligence → Flow Fields**. Walk through the opening on the east side into the new court. The point stands beside the waiting group, at hand height.

- **Carry the point toward A or B** to choose a destination. A movement of more than 20 cm toward either side selects it. The neutral middle band keeps your selection.
- **Trigger**, or desktop left-click while carrying, shows or hides the arrows. Desktop right-click carries or drops the point.
- **Drop the point** to bring the group back. All twenty-four bodies remain; none are replaced. The point returns to its stand after 1.5 seconds.

Walk around the island and watch a body meet a turn. Then hide the arrows. The guidance remains active even when its marks disappear.

## What this adds

The fish and drone comparisons used neighbours as moving references. This crowd shows another source of collective movement: **a shared field prepared for everyone**. The same group can appear coordinated while each body consults only its own position and the directions supplied there.

The point keeps its existing pickup and action class. Its new role is to choose the destination that reorganises the field. The figures keep their identities, positions and velocities across changes. Their sphere heads retain the point’s visual role while their larger bodies make the room inhabitable.

This is an optional full-size encounter beside the existing Flow Fields lesson. The fourteen canonical tutorial/final files and seven-hall order remain unchanged. The original table, ant colony and ecosystem placements remain. The hall extends from 13 × 10 to 33 × 15 cells, with a three-cell opening to the east court and a low central island that visitors can walk around. The automatic entry partition is disabled so it does not span the new court; authored walls remain apart from that opening.

## Exact mechanism

The new model reuses the existing **FlowGrid cost propagation** from the table. All traversable cells here have equal cost. A local adapter selects cardinal neighbours with lower costs, keeping a margin around the island. Movers steer toward successive cell centres with bounded acceleration and speed. Near their destination, they move into assigned parking places. Those places are supplied staging; the parking pattern is not evidence of emergent agreement.

No mover reads another mover. A test changes all the other bodies while retaining the witness’s inputs; its trajectory remains identical. The figures are kinematic visual bodies and can overlap. This demonstrates shared route guidance, not pedestrian collision avoidance or crowd pressure.

The arrows come from the same field used to choose the next cell. Thin cylinders and cone tips give their direction a physical shape. The island and point stand have real collision for the visitor. Moving figures and floor arrows do not block the player.

## A short reflection to consider

The bodies turn together. You hide the arrows and the turn looks like something they decided among themselves. Yet none has asked where its neighbour is going. You move the point; the ground is rewritten. What looked like agreement was also an arrangement of the room.

This paragraph is an encounter note for review, not an automatic insertion into final.md.

## Evidence and limits

**{total}/{total} checks passed:** {len(code['checks'])} code checks and {len(native['checks'])} native museum checks.

The code run covers 150 simulated seconds across A, B and RETURN, plus a 105-second mid-route reversal and return. All bodies arrive, stay outside the island, remain finite and obey the speed cap. Additional checks cover unchanged-target caching, neighbour independence, transformed coordinates, actual pickup/action/drop hooks, identity retention and agreement between displayed arrows and field vectors.

The museum run checks continuous floor and standing-capsule clearance through the entrance and around both sides, hand-height reach, live destination selection, arrival at A, redirection, and return of all original bodies. Six images come from native Godot rendering. The with/without-arrow photographs hold positions fixed; movement resumes afterward. This is a capture technique, not a player pause control.

The first native run exposed repeated physics writes returning an already-resting point to its stand, which could overwrite the first pickup movement. The artifact now returns it only when displaced. The final run rechecks the actual transition. A malformed placement parameter was also corrected before the final run. Earlier failed run folders remain available.

No script or shader errors occur in the final receipts. Existing project warnings remain in the logs. Physical headset use, portal crossing, Quest performance and an independent learner review remain open. These checks validate this encounter, not a new full-sequence ghost-student run.
'''
(OUT/'REPORT.md').write_text(report,encoding='utf-8')
gallery=''.join(f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" loading="lazy" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in figures)
css='*{box-sizing:border-box}body{margin:0;background:#132131;color:#eeeae3;font:18px/1.65 system-ui}main{max-width:1180px;margin:auto;padding:36px 24px 70px}h1{font-size:clamp(40px,6vw,68px);line-height:1.1;color:#88dbe6}h2{margin-top:40px}article{max-width:870px}nav{display:flex;gap:24px;flex-wrap:wrap;padding:16px 24px;background:#233348}a{color:#f0a9ce}figure{margin:26px 0;padding:10px;background:#233348}img{width:100%;display:block}figcaption{font-size:15px;padding:10px 6px;color:#cdd5df}li{margin:8px 0}'
hero='<figure><img src="assets/toward-a.png" alt="Full-size crowd following the shared field in the actual museum"><figcaption>A direction in common — native museum capture.</figcaption></figure>'
body=markdown.markdown(report,extensions=['extra'])
(OUT/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A direction in common — Endless Museum</title><style>'+css+'</style></head><body><nav><a href="#pictures">Museum pictures</a><a href="REPORT.md">Editable report</a><a href="evidence/code-checks.json">Code checks</a><a href="evidence/museum-checks.json">Museum checks</a><a href="../2026-10-11-swarm-three-appearances/index.html">Previous encounter</a></nav><main>'+hero+'<article>'+body+'</article><section id="pictures"><h2>Inside the museum</h2>'+gallery+'</section></main></body></html>',encoding='utf-8')
print(f'Published {total} passing checks, six native images; preserved texts, order, original exhibits and other plan rows.')
