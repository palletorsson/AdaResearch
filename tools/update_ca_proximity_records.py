"""Update one lesson's plan and evidence without changing any other decision."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-the-surface-includes-you'
M=R/'commons/maps/CA_ExpandingSpace'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text())
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(r['samples'] for r in room['observations']['routes'].values())
p=R/'doc/book/course/execution-plan/plan.json';data=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(data)
row=next(r for r in data['lessons'] if r['id']=='CA_ExpandingSpace')
row.update(
 object='The carried PointBody supplies position to a fractional cell field; floor and wall share its state.',
 change='Connect a held point centre as external input. Decay nearby cells, recover through healthy neighbours, and separate recovery from support thresholds. Compare update schedules with three cells.',
 dependsOn=['CA_BeyondBinary','Point_Coordinates','Point_Lines'],
 reuses='Same PointBody and action signal; local/world coordinates and distance; address, loops, old-to-next buffers; a state and its chosen output.',
 given='Existing Day Zero museum host, player, camera, lighting and XR Tools. Full presence.gd and unchanged point_body.gd printed. All learner geometry, materials, labels and colliders are constructed in code.',
 later='Compact model uses manual steps and held point centre. Installed VISITOR resolves the physical body; PROBE, RUN and richer desk remain comparisons. Secondary chair/tree/crossway works are museum encounters, not required lesson code.',
 checks=[f'{n} exact-printed-code native checks: 3D distance, four axial neighbours, strict thresholds, clamping, separate buffers, schedule comparison and 160 updates matching the installed solver.', 'Independent height and .49 threshold exercises; flat-distance and accidental-scan faults rejected; native material, collision, actual XRTools pickup/action/release with supplied poses; keyboard and limit.',f'{q} native museum checks including cameras: four sources, held-point parity, release/recovery, shared materials, schedules, falling body, climbed ramp, four routes/{samples} capsule-and-floor samples and portal approaches.'],
 transfer='Move the held point above the radius and predict recovery. Change CHAIN W from .495 to .49; in forward SCAN it reaches .5, still cannot contribute to the next cell because healthy means strictly greater than .5.',
 carry='External input can alter future state; visual presence, physical support and recovery participation are distinct permissions. Timing of reads belongs to the rule.',
 next='CA_SoftRules: inspect the installed primary and what its neighbourhood reads beyond a thresholded count; keep one carried object and one tested reconstruction.',
 notes='One-fifth-scale learner model reverses its visual mapping to retain simulation units. It samples PointBody centre only while held; the installed VISITOR samples tracked body origin, not pressure. Bridge solver unchanged. No physical headset, full portal transfer or independent student acceptance.',
 summary='Carry the same PointBody from STEP-only to spatial input. In a 5x16 fractional field, a held point within a 3D radius removes health; otherwise four healthy axial neighbours permit recovery. Keep every address and show each value twice, on floor and wall. Below .2 floor support ends; only values above .5 aid recovery. Predict withdrawal and height changes. Revisit old-to-next with a three-cell SYNC/SCAN comparison, then edit .495 to .49 and explain the threshold. Carry explicit input/state/output separation toward soft neighbourhood rules.'
)
assert all(a==b for a,b in zip(old['lessons'],data['lessons']) if a['id']!='CA_ExpandingSpace')
assert all(old[k]==data[k] for k in data if k!='lessons')
p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(O/'after/lesson-plan.json').write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
p=M/'technical.md';s=p.read_text(encoding='utf-8')
s=s.replace('The study can use VISITOR, a nominated PROBE position, or NONE.', 'The study can use VISITOR, a nominated PROBE position, NONE, or HAND. The fourth source samples the held PointBody centre; when released it has no proximity input. The point trigger selects HAND and steps once. The point parks on release, and release itself does not step.')
s=s.replace('with the other six shifted together into the rear gallery.', 'with the other six staged individually in a level rear gallery. The chair is scaled to 0.12, crossway to 0.25 and tree to 0.35. Crossway is lifted 0.8 m as a small relief; it no longer crosses the exit wall.')
s+='''

## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints `presence.gd` and the unchanged PointBody, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_ExpandingSpace`. The full 5 × 16 float dictionary keeps the installed primary's pitch, radius, rates, axial bounded neighbourhood and thresholds. A one-fifth-scale view maps the held point back into simulation units. The model has manual steps, a lower receiving tray, corresponding wall panels and a complete collision construction. Unlike the installed VISITOR mode, its input is deliberately the held point centre. It is a tabletop reconstruction, not a miniature walking platform.

The lesson introduces external input first; SYNC/SCAN is a later return to the existing buffer agreement. Independent exercises raise the point above the radius and change CHAIN W from .495 to .49. Two deliberately faulty variants discard height or read newly written answers in SYNC; the tests reject their predicted outcomes.

The installed proximity study adds `proximity_hand.gd` only through its opt-in study mounting. VISITOR, PROBE and NONE remain in the same order; HAND is fourth. The original bridge solver is unchanged in this pass. The rear chair receives optional `host_lighting:1`, like the tree, to disable its standalone sun/environment. Its cellular algorithm is unchanged.

All seven authored works remain. Rear floor/partition cells are levelled, incidental sculpture is reserved out of circulation, and portals move to the entry/exit thresholds with no additional generic gate. The basin and recovery wedges retain their geometry. Only this hall's generated plan row is rederived.
'''
s+=f'\n{n} exact-printed-code checks and {q} installed-museum checks pass in Godot 4.6. There are {samples} samples on four routes for layer-1 capsule clearance (0.56 m wide / 1.7 m high) and level floor. A supplied physical body loses support at W, lands at approximately -0.63 m and climbs the exit wedge to the museum floor. Both source types at the same coordinate produce the same field. Final runs have no SCRIPT ERROR or Parse Error; existing unrelated engine warnings remain.\n'
s+='''

Earlier diagnostic runs are retained: the learner parity fixture initially omitted the production study-coordinate flag; the first museum pass exposed a duplicate configuration hook added to the chair and a route intersecting the desk foot. The hook is merged into the existing function; the final route goes around the furniture. These are corrected integration/harness defects, not grounds for claiming the first runs passed.

Evidence: `doc/book/iterations/2026-10-08-ca-the-surface-includes-you/index.html`, exact printed code, receipts, logs, before/after overhead/raised/visitor views and review ZIP. No physical headset, Quest performance, independent student, complete secondary-artifact interaction audit or full portal transfer is claimed.
'''
p.write_bytes(s.encode('utf-8'))
p=M/'encounter-notes.md'
with p.open('a',encoding='utf-8') as f:f.write(f'''

---

# The surface includes you — 8 October 2026

The carried point moves from controlling the clock to supplying a location. HAND + STEP is an additional installed input; release withdraws it, while recovery still requires further updates. The complete two-file learner model reconstructs that same rule at table scale. The reflection keeps its encounter and distinction between appearance, support and recovery; three implementation blocks become prose. Its point passage records the new connection without turning the final text into a tutorial.

Rear gallery levelled and six secondary works spaced; all seven authored works retained. Chair/crossway/tree fit at .12/.25/.35, crossway lifted .8 m. Threshold portals and no duplicate gate. Existing basin/ramps and bridge transition law preserved. Optional host lighting on the embedded chair avoids a second sun.

{n} learner + {q} native museum checks pass; four routes / {samples} samples. Native XRTools supplied poses, physical-body basin/ramp test, comparison faults and threshold transfer are covered. Initial failed diagnostics retained. No headset or independent student claim. Final photos reviewed from above, raised oblique and eye height. The printed model is temporarily mounted only for its picture. Blank wall frames and secondary encounters still need their own review.

Full review: `doc/book/iterations/2026-10-08-ca-the-surface-includes-you/index.html`. Next: CA_SoftRules.
''')
print('One lesson plan and its supporting records updated; decision remains draft.')
