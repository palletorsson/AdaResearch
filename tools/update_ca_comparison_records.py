"""Record this hall's tested lesson without changing other lesson decisions."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-two-ways-to-make'
M=R/'commons/maps/CA_AgentsCircuits'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text())
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
p=R/'doc/book/course/execution-plan/plan.json';data=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(data)
row=next(r for r in data['lessons'] if r['id']=='CA_AgentsCircuits')
row.update(
 object='Same PointBody inspects and steps a Rule 90 history beside a fixed recursive cube construction.',
 change='Compare a next-state calculation with a supplied placement recipe. Change the beginning of one and identify which output responds.',
 dependsOn=['CA_Introduction','CA_GameOfLife','Point_Coordinates'],
 reuses='Carried point/action, world-to-local address, Boolean state, old-to-next update, independent saved rows, arrays and loops, supplied classes and mesh instances.',
 given='Existing Day Zero Endless Museum host, player, camera, lighting and XR Tools. Three full files create the learner comparison. Recursive six-offset placement recipe is supplied and explained one level at a time; derivation belongs to Fractals.',
 later='Compact example fixes Rule 90, caps history at 24 rows and uses keyboard C/R for seed/replay; installed desk has wider VR rule controls and a scrolling floor receiver. Wireworld is archived proposal material, not an installed lesson. No universality or fractal-dimension proof.',
 checks=[f'{n} exact printed-file native checks. All eight Rule 90 cases and 240 mixed-start updates match the installed evaluator. Ordered recursive positions match production at depths 0–4. Test independent rows, finite wrap, geometry/support, supplied XRTools poses and keyboard controls.', 'Transfer changes seed_sites to [14,16,18]: first next row contains only 13 and 19, while all 216 cube transforms remain fixed. XOR-to-OR and in-place-read defects are detected.', f'{q} installed museum checks including cameras: actual pickup/step/release, floor history/colour/transforms, seed/reset/scrolling, all 1296 cube transforms, body walking, four routes/{samples} clearance and floor samples, supported portal approaches.'],
 transfer='Change seed_sites to [14,16,18]. Predict shared-neighbour cancellation, then show that only addresses 13 and 19 survive the first update and that no cube placement changes.',
 carry='Ask what repeats, what it reads and what input can change it. Similar outlines do not establish the same procedure.',
 next='CA_EdgeOfChaos: keep the procedure fixed and follow one changed starting value through two nearly matching volumes. Audit actual implementation before expanding the lesson.',
 notes='Rule 90 and pyramid algorithms unchanged. Existing HandPoint adapter added to comparison branch. All three authored placements and floor retained; incidental sculpture cleared and portals moved to thresholds. Hall blurb and two catalogue captions corrected to the actual six-call/seed comparison. No headset, Quest, full portal transfer or independent student acceptance.',
 summary='Return with the same point and Boolean row. Move the held point to inspect one address; trigger advances one generation. Rule 90 reads old left/right values and writes their inequality into a new row; saved rows make time visible on the table and floor. Compare this with the supplied six-offset recursive cube recipe, which reads positions, spacing and depth. Change seed_sites to [14,16,18], predict the next occupied addresses 13 and 19, and confirm the fixed pyramid has not moved. Carry the distinction between changing state and repeating placement into a comparison of almost identical beginnings.'
)
assert all(a==b for a,b in zip(old['lessons'],data['lessons']) if a['id']!='CA_AgentsCircuits')
assert all(old[k]==data[k] for k in data if k!='lessons')
p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(O/'after/lesson-plan.json').write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
s=(O/'before/technical.md').read_text(encoding='utf-8')
s+=f'''

## Complete learner reconstruction — 8 October 2026

`tutorial.md` now prints `procedures.gd`, `comparison.gd` and unchanged `point_body.gd`, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_AgentsCircuits`. They run on the existing Day Zero `PointStudy`. The first file owns the two procedures; the second builds the table, plinth, instances, labels, support and input. The third is byte-identical to CA_SoftRules. No prepared study children are required.

The 32-cell rule reads old left/right and writes their Boolean inequality. Centre does not affect Rule 90. The learner stores chronological independent snapshots, stops at 24 rows and renders unused rows at zero scale. The museum retains its existing newest-first storage and scrolling receiver. The supplied recursive function preserves all six installed offsets, including the extra crown; depth three yields 216 leaf entries versus the installed depth four's 1296. Entries may overlap. Every leaf cube keeps a fixed size. Learner cube instances are visual, on a solid plinth; they do not recreate the large prefab's individual colliders.

The comparison branch of `neighbour_study.gd` now mounts the existing `hand_point.gd` adapter, already used by the opening. Moving the held point selects the current row address. Its trigger calls the existing STEP operation and pauses. Release parks it at the selected address. Moving it does not edit state. The compact model uses Enter for STEP, R to replay, C to switch the seed. The installed SEED/RST controls remain VR-operable.

Room changes preserve all three authored artifact tokens, their placements and the level floor. A sculpture reservation clears incidental objects from the approach. The generic gate is disabled; entry and exit move to source(6,0)/(6,17), with supported approaches. Only this hall's generated plan row is rederived.

Validation: {n} learner and {q} museum assertions pass in native Godot 4.6. All eight truth cases and 240 mixed-start updates match the general evaluator. Actual ordered recursive placements at depths 0–4 match the learner recipe. The three-seed transfer predicts [13,19] and unchanged copies. Two deliberate faults are detected. Native supplied XRTools poses test pickup, inspection, trigger and release in both models. A CharacterBody walks over dark floor cells without changing the record. Four routes provide {samples} layer-1 capsule and level-floor samples.

The initial learner run found a typed-array ternary assignment; `seed_sites.assign(...)` fixes the printed script. The initial museum colour equality was too strict for native MultiMesh storage. The final measured maximum RGB difference is {room['observations']['maximum_colour_channel_error']:.8f}, below one 8-bit channel step; transforms and Boolean records remain checked independently. First-pass logs are retained in the report's diagnostics.

The main explorer, comparison floor and pyramid scripts remain byte-identical to this pass's baseline. Final runs have no SCRIPT ERROR or Parse Error. No physical headset, Quest performance, independent student, full portal transfer or full secondary-interaction audit is claimed. Existing blank wall frames remain. Image inspection caught an inherited five-copy caption, inconsistent with this configuration's extra crown. Only this hall's two captions and obsolete Wireworld blurb are corrected in the book/source/shipped catalogue records. Native assertions verify both new wall captions. No other hall's catalogue text is changed.

Review: `doc/book/iterations/2026-10-08-ca-two-ways-to-make/index.html`, before/after above and inside images, full texts, exact scripts, native receipts and review ZIP. Next: CA_EdgeOfChaos.
'''
(M/'technical.md').write_bytes(s.encode('utf-8'))
s=(O/'before/encounter-notes.md').read_text(encoding='utf-8')
s+=f'''

---

# Two ways to make — 8 October 2026

The source audit confirms the room's existing comparison: Rule 90 history and the six-call recursive pyramid. The stale Wireworld tutorial is replaced with a complete reconstruction of that encounter. Bring the point back as an address inspector and STEP control. Keep the copy recipe supplied, so deriving recursion is not a hidden prerequisite. The independent three-seed edit must change the row without changing the sculpture. The final reflection adds the point's new role and a current museum image; the rest of its inquiry is retained.

Keep the desk, floor history, film and pyramid placements. Clear incidental obstruction and extra gate, put the passages at their thresholds. Native before/after overhead, raised and visitor images record this modest spatial change. The learner miniature is mounted temporarily for its photograph, not added as a duplicate artifact.

{n} printed-code + {q} museum checks pass; four routes/{samples} samples. Exact evaluator and recursive-placement parity, transfer, two fault variants, pickup/step/release and physical support are tested. No headset, independent student or complete portal transition. Blank frames remain. The inherited five-copy wall caption is corrected to six placements at half spacing, and the explorer caption now names the seed comparison. This hall's blurb no longer describes uninstalled Wireworld. Native assertions check the displayed captions; other halls' catalogue records are preserved.

Next CA_EdgeOfChaos: compare two nearly matching beginnings under one procedure, after auditing the installed volumes and controls.
'''
(M/'encounter-notes.md').write_bytes(s.encode('utf-8'))
print(f'Updated one lesson contract; {n}/{q} checks; {samples} route samples; decision preserved.')
