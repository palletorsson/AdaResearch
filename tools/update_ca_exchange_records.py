"""Update only this hall's lesson contract and evidence."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers'
M=R/'commons/maps/CA_SoftRules'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text());assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
p=R/'doc/book/course/execution-plan/plan.json';data=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(data)
row=next(r for r in data['lessons'] if r['id']=='CA_SoftRules')
row.update(
 object='Same PointBody plants a matched seed in two independent concentration fields, each shown twice.',
 change='Move from thresholded neighbour counts to a four-neighbour difference sum. Compare exchange on/off while keeping the supplied reaction and beginnings equal.',
 dependsOn=['CA_ExpandingSpace','Point_Coordinates'],
 reuses='Carried PointBody and action; world/local position to grid address; fractional state, arrays, loops, classes, old-to-next updates and field-to-colour mapping.',
 given='Day Zero Endless Museum host, player, camera, lighting and XR Tools. Gray–Scott reaction terms and constants supplied and named. Three complete printed files create the compact field model, staging and point.',
 later='Derivation and numerical analysis of the reaction model. Compact model uses keyboard clock/view/exchange; installed study keeps eight VR desk controls and body crossing. Clockmaker and four rear works remain encounters, not extra coding requirements.',
 checks=[f'{n} exact-printed-file native checks; 2400 steps per exchange mode exactly match production arrays (maximum difference 0). Uniform sum, periodic boundary, independent old/new buffers, clamps, textures, support and supplied XRTools poses.', 'Transfer adds one corner seed in both fields. Predicted nine wrapped addresses and first outward V pass. Missing-centre-subtraction and in-place-read mutations fail the expected results.',f'{q} native museum checks including cameras: selected hand seed, fixed body seed, withdrawal/reentry, replay while occupied, view/coating, clock and cap, four routes/{samples} clearance and floor samples, supported portal approaches.'],
 transfer='Add left.seed_at(Vector2i(0,0)) and right.seed_at(Vector2i(0,0)) after right.reset in the study. Predict nine wrapped sites and which field can give adjacent unseeded sites their first V.',
 carry='Two values at one address; the neighbourhood offers differences. State, intervention, update and display have distinct jobs; same intervention can meet different field histories.',
 next='CA_AgentsCircuits: audit the actual row-history / Sierpinski comparison. Its current encounter compares procedures behind resemblance; historical map title is not the lesson contract.',
 notes='Field model separated as RefCounted. Same reaction as installed solver, fresh buffers instead of reused buffers. Point input explicitly replaces a 3x3 patch without stepping. Primary solver and walk receiver unchanged. No headset, Quest, full portal transfer or independent student acceptance.',
 summary='Bring the same held PointBody to two tables and place an identical seed. Each 32x32 site stores U,V. Sum four neighbour-minus-centre differences, combine with the named supplied reaction, and write both next arrays before replacing the present. Predict W=(12,15): exchange gives (.92,.02), no exchange (1,0). Enable both to recover agreement. Change the palette without changing state. Add a corner seed, predict its nine wrapped sites, then watch exchange carry V beyond it. Carry input/state/update/display separation into a comparison of different procedures behind similar forms.'
)
assert all(a==b for a,b in zip(old['lessons'],data['lessons']) if a['id']!='CA_SoftRules')
assert all(old[k]==data[k] for k in data if k!='lessons')
p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(O/'after/lesson-plan.json').write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
s=(O/'before/technical.md').read_text(encoding='utf-8')
s=s.replace('with an added front bay and eastern aisle.', 'with a front comparison bay and a level rear gallery. The primary tables, curved displays and clockmaker retain their positions.')
s+='''

## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints three complete files maintained in `doc/book/studies/cellular-automata-through-the-hands/CA_SoftRules`: `field.gd`, `exchange.gd`, and the unchanged previous `point_body.gd`. The RefCounted field keeps two 32² fractional arrays, fixed Gray–Scott terms, a four-axial difference sum, periodic boundary and synchronous next buffers. The compact model has two 1.28 m table images and upright panels, with one texture shared per pair. These are fixed display surfaces, not growing geometry. Clock/view/exchange controls are keyboard-based in this reconstruction; the installed desk remains VR-operable.

The installed `exchange_hand.gd` mounts the same small PointBody beside the existing desk. World position converts to study local space; a held centre within .35 m vertically and .8 m of either tabletop centre selects an address at .05 m pitch. Trigger replaces U=.5,V=.25 in a wrapped 3×3 patch in both fields. No clock advances. Outside, above, or released inputs do nothing; release parks the sphere. The compact example uses the same mapping with .04 m pitch and .64 m half-width. Its point centre is not a pressure measure.

The fixed `walk_seed.gd` receiver and `live_field.gd` solver remain byte-identical to this pass's baseline. Only selected injection and its hand adapter are added to the installed study. REPLAY restores original values and clears injection count without changing exchange, view or coating choices. The installed +100 advances in bounded batches; the compact Space action executes 100 steps directly.

Spatial changes preserve six authored works. Rows16–24 are levelled, with incidental sculpture reserved out of circulation. Rear staging: lattice_gas_pump source(12,18); ca_sphere(3,22),height1.1; crack_propagation_ca(3,18),height1.2,scale.35; rule_30_110_gravity(12,22),height2.6,scale.3. The latter uses optional host_lighting to disable its standalone sun/camera; its transition and falling-body logic are unchanged. The generic gate is disabled and portals sit at source(8,0)/(8,25). Only this hall's generated plan row is rederived.
'''
s+=f'\nValidation: {n} learner and {q} museum checks pass in native Godot 4.6. Both exchange settings match installed U,V arrays exactly for 2400 updates each. Corner transfer and two deliberate defects are tested. Native supplied XRTools poses and CharacterBody overlap test pickup, planting, release, arrival, occupancy and reentry. Four routes contain {samples} layer-1 capsule and level-floor samples. Portal approaches pass; no full transition, physical headset, Quest benchmark or independent student assessment is claimed.\n'
s+='\nReview: `doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers/index.html`, full texts, before/after above and inside captures, printed files, receipts and ZIP. Secondary interactions remain unaudited, some secondary labels draw through the primary wall surfaces, and existing blank wall frames remain.\n'
(M/'technical.md').write_bytes(s.encode('utf-8'))
s=(O/'before/encounter-notes.md').read_text(encoding='utf-8')
s+=f'''

---

# What a neighbour offers — 8 October 2026

The carried point now chooses where to plant, rather than supplying a continuously sampled proximity. Trigger replaces one patch in both fields without advancing time. A's and B's histories remain independent. The complete three-file lesson reconstructs this comparison with the supplied reaction explicitly named. It teaches differences from four neighbours, two fields and a periodic edge. The corner-seed exercise tests transfer. The final reflection keeps the encounter and replaces three implementation blocks with prose; the sphere's changed role is added.

Retain the front tables, curved walls and clockmaker. Clear rear partitions and floor holes, fit four secondary works and keep the path through to the threshold portal. All six authored works remain. Native before/after overhead, raised, entry and rear views, selected seed, body seed and exact learner model are in the report. The learner model is mounted temporarily for its photograph.

{n} printed-code + {q} installed museum checks pass, four routes/{samples} samples. 4800 updates match the installed solver exactly. Both deliberate faults are detected. No physical headset, independent student, complete portal transfer or secondary-interaction acceptance. The secondary lattice labels can show through the field walls; existing blank frames and deeper secondary curation remain visible limitations.

Next: CA_AgentsCircuits. Inspect its actual procedure-comparison encounter; do not infer Wireworld or an ant lesson from the historical name or old tutorial fragment. Current final compares Rule90 history with the recursively copied pyramid.
'''
(M/'encounter-notes.md').write_bytes(s.encode('utf-8'))
print(f'One lesson contract updated; {n}/{q} checks; {samples} route samples; decision remains draft.')
