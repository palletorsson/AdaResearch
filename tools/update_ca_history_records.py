"""Record this hall's verified learner contract without changing other lessons."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
p=R/'doc/book/course/execution-plan/plan.json'
d=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(d)
row=next(r for r in d['lessons'] if r['id']=='CA_GameOfLife')
row.update(
 object='PointBody reads a retained Rule 30 history across two receivers.',
 change='Copy each new row into chronological history. Build horizontal collision tiles and a visual vertical screen from the same saved addresses; held point selects a recorded generation.',
 dependsOn=['CA_Introduction','CA_ElementaryRules'],
 reuses='Old-to-next row update; arrays and nested indices; PointBody pickup/action; local coordinates; pooled repeated geometry.',
 given='Existing museum Day Zero host: camera, lights, player, XR Tools. Both learner files printed in full, including unchanged PointBody.',
 later='Actual Conway Life follows in CA_BeyondBinary. Rear columns, orb, mirrored automaton and Turing lab are wider encounters, not extra tutorial assignments.',
 checks=['Exact printed files: all eight Rule30 cases; eight seeds through 24 rows versus installed solver; snapshot independence; faulty alias rejected.', 'Both mappings, all 360 visibility/support slots, native collision rays; old-row reading preserves current/history; capacity and replay.', 'Independent two-site beginning and flipped wall receiver; actual XRTools pickup/action/release with supplied poses; installed walking reader and room routes.'],
 transfer='Begin with sites 5 and 9; predict six occupied sites in generation one. Reverse only the vertical site mapping; explain why saved rows, deck and next state stay the same.',
 carry='Independent chronological snapshots; separate site and generation indices; display and support consume the same data with different consequences.',
 next='CA_BeyondBinary: one two-dimensional present, B3/S23 and a glider whose apparent motion differs from this retained spatial history.',
 notes='30 exact-code checks + 35 museum checks including capture checks. 451 route samples. Small learner has two views/hand reader; installed work has desk, basin, lattice/body reader. No physical headset, human learner, or full portal transfer test. Production rule/study unchanged.',
 summary='Return to opening Rule30 after the three-state volume. Carry PointBody and old-to-next; copy completed rows into 24 chronological snapshots. Build horizontal support and upright ornament from the same generation/site addresses. Move the held point to read an earlier row without changing state. Predict the two-site seed, then flip only one view. In the installed hall walk beside the basin and watch three witnesses agree. Carry saved state and explicit receiver responsibilities into the next hall’s two-dimensional present.'
)
assert all(a==b for a,b in zip(old['lessons'],d['lessons']) if a['id']!='CA_GameOfLife')
assert old.keys()==d.keys() and all(old[k]==d[k] for k in d if k!='lessons')
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
M=R/'commons/maps/CA_GameOfLife'
p=M/'technical.md';s=p.read_text(encoding='utf-8').replace('ROW selects an earlier recorded row without changing history.','ROW pauses RUN and selects an earlier recorded row without changing history.')
s+='''

## Complete learner reconstruction — 8 October 2026

`tutorial.md` now prints the entire `history.gd` and unchanged `point_body.gd`, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_GameOfLife`. The smaller study reserves 360 slots in each of two views, copies Boolean rows, uses a held point's local Z to read history and its action to append. Its 24-row limit includes the seed. It does not reproduce the basin, desk controls or RUN timer. The installed Rule30 solver and history study are unchanged.

Native test tools: `tools/test_ca_history_lesson.py`, `tools/probes/ca_history_lesson.gd`. The exact printed files pass 30 checks, including eight deterministic seeds through all 24 rows versus the installed solver, rejected aliasing mutation, independent seed/mapping exercises, renderer/collision agreement and actual XRTools with supplied poses.

The rear gallery is levelled; the east passage opens around the lab. The orb moves to source cell (4,28), columns to (8,28). All six authored works remain. Incidental generated sculptures are reserved out of this narrow circulation. Entry (6,0) and exit (6,36) use the thresholds; no extra gate. Only this generated museum plan row is rederived. The front basin and its ramps stay intact.

35 native museum checks include cameras, walking selection, preserved state/support, replay/seed/capacity, surface and lower-floor rays, portal approaches and five routes with 451 samples. The capsule is 0.56 m wide and 1.7 m tall, tested on layer 1; this is not dynamic all-layer walking, a portal transfer, physical headset or Quest acceptance. The rear lab apparatus remains a secondary encounter rather than a tested lesson.

Current report, before/after native views and receipts: `doc/book/iterations/2026-10-08-ca-history-three-bodies/index.html`.
'''
p.write_bytes(s.encode('utf-8'))
p=M/'encounter-notes.md'
with p.open('a',encoding='utf-8') as f:f.write('''

---

# Keep a generation — 8 October 2026

This pass supersedes the earlier decision to keep code excerpts in the reflection: full runnable code now belongs in tutorial.md; final.md keeps the encounter and argument. It also corrects the transition from the previous three-state volume: we return to the opening Rule30 row to study retained history, rather than imply the 3D rule continued unchanged.

One small learner construction carries PointBody as a reader and STEP. Two complete files, 30 native checks. Native installed walking reader and space: 35 checks, including 451 floor/capsule samples. All six current authored works retained; rear circulation levelled, side divider opened, orb and columns moved clear of laboratory, threshold portals. The installed solver and history-study sources are byte-identical to the turn's baseline. Room snapshots, earlier diagnostic failures, full texts, diff and review ZIP are in `doc/book/iterations/2026-10-08-ca-history-three-bodies`.

The first route endpoint intersected the inclined desk; it now stops at its reachable approach. The first lower-floor ray hit an end ramp; the corrected ray tests the basin's interior. The first learner capture visually merged its pattern with the large basin. The final temporary mounting uses a plain wall in the rear gallery. No permanent duplicate study is added. Existing bright museum lighting and the interior-facing lab sign are retained. No headset, independent student, complete lab interaction or portal-transfer claim.
''')
print('One lesson record updated; draft decision and all other lessons preserved.')
