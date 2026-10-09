"""Keep the single hall's plan, technical account and encounter record aligned."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
p=R/'doc/book/course/execution-plan/plan.json'
d=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(d)
row=next(r for r in d['lessons'] if r['id']=='CA_BeyondBinary')
row.update(
 object='PointBody carries STEP through a two-dimensional present; one fixed cell controls one lamp.',
 change='Count eight surrounding sites, apply B3/S23 into a fresh buffer, and bind a fixed address to an independently switchable output.',
 dependsOn=['CA_Introduction','CA_ElementaryRules','CA_GameOfLife'],
 reuses='PointBody and pickable action; arrays, loops and local coordinates; synchronous old-to-next updates; a value and its receiver.',
 given='Existing Day Zero museum camera, lights, player and XR Tools. Both complete learner files printed, including unchanged PointBody. No supplied dish or lamp children.',
 later='Secondary mould/growth/hexagonal works remain museum encounters. RUN, TRACE, three installed lamps and MEET are wider comparisons, not extra required code in the compact lesson.',
 checks=['29 exact-printed-code checks: all 18 rule cases, eight offsets, wrapping, independent buffer and reverse iteration, installed-solver parity through 48 glider steps and eight random seeds.', 'Blinker and alternate-address transfer tasks; rejected centre-count and in-place mutations; native colour, collision, XRTools pickup/action/release and keyboard.', '38 installed museum checks including cameras: carried STEP, one-way LINK, TRACE restoration, patterns, stable floor support, 48-step limit, five routes / 306 capsule-and-floor samples and portal approaches.'],
 transfer='Make the three-cell blinker; predict both phases and the continuously occupied centre. Change SITE from (10,10) to (9,10); predict an alternating lamp without altering the cells.',
 carry='Two-dimensional present versus retained history; fixed address versus travelling pattern; a separately chosen output binding.',
 next='CA_ExpandingSpace: proximity becomes input; the observing body enters the update conditions.',
 notes='Actual Life rule remains binary despite historical map ID. Compact study has one lamp and manual steps; installed hall has three lamps and richer controls. Exact code, native renderer/physics and supplied XRTools poses tested; no tracked headset or independent student acceptance. Solver/receiver unchanged; carryable STEP is opt-in for walk-floor placements.',
 summary='Carry PointBody and old-to-next into a 24x24 present. Count eight surrounding neighbours, exclude centre, apply B3/S23 synchronously. Four glider steps shift the pattern while every address stays fixed. Bind A to a lamp; disconnect output without stopping cells. Build a blinker, predict its two phases, then move only the output address to make the lamp alternate. Walk the installed floor with the held STEP point. Carry explicit one-way coupling toward next hall’s proximity input.'
)
assert all(a==b for a,b in zip(old['lessons'],d['lessons']) if a['id']!='CA_BeyondBinary')
assert all(old[k]==d[k] for k in d if k!='lessons')
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
M=R/'commons/maps/CA_BeyondBinary'
p=M/'map_data.json';data=json.loads(p.read_text(encoding='utf-8'));p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=M/'technical.md';s=p.read_text(encoding='utf-8')
s=s.replace('The 15 × 27 map adds a front study and an eastern aisle around the retained rear configuration.', 'The 15 × 27 map has a front study and, since 8 October, a level open rear gallery. Raised strips, pits and its short internal partition have been removed. The secondary works are spaced around the onward route.')
s+='''

## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints `life.gd` and the unchanged `point_body.gd`, maintained in `doc/book/studies/cellular-automata-through-the-hands/CA_BeyondBinary`. The 24 × 24 Boolean present uses a flat array and the same seed, periodic neighbourhood and B3/S23 rule as the installed primary. It supplies a complete small table, fixed tile instances, one address frame, one lamp and PointBody STEP. It omits the installed RUN, TRACE and preset UI. The student changes seeds to a blinker, then moves the output binding while keeping cell evolution unchanged.

29 native checks of the exact printed blocks pass: eighteen rule cases; all offsets/wrapping; separate buffer and order independence; solver parity through 48 glider generations and eight random beginnings; two meaningful fault variants; both transfer tasks; rendered colours and fixed transforms; collision support for empty/occupied sites; actual XRTools pickup/action/release with supplied controller poses. The first probe used an incorrect production property name (`initial_culture`); corrected to `culture` before the successful run. This was a test-harness defect, not a learner-code failure.

Walk-floor address-study placements now add `life_hand.gd`: the established pickable point carries the existing `step_once` action and parks beside the console on release. Moving the point never edits a cell. The Life solver and `life_address_receiver.gd` are byte-identical to this turn's baseline. Other address-study placements do not add the hand control.

Rear staging: mould at source (2,20), scale 0.4; growth network at (3,24), height 1.3 and scale 0.35; dark sphere at (6,21); screen at (1,19), facing inward. The hex table keeps (9,23). All six authored artifacts remain; no secondary algorithm was changed. Incidental sculpture is reserved out of circulation. Entry/exit use (6,0)/(6,26), with no extra gate. Only this generated museum-plan row is rederived.

38 museum checks pass, including eight capture checks: installed point action, LINK and onset preservation, TRACE restoration, blinker/meeting, support at A through generations 0/8/12, RUN/limit, stable floor transforms, portal approaches, and five routes with 306 samples of 0.56 m wide/1.7 m high capsule clearance and level floor on collision layer 1. Initial route samples touched the console and readout stem: the final route stops at a reachable console approach and goes around its furniture. This does not establish all-layer walking, full portal transfer, physical headset comfort or secondary-work interaction acceptance.

Current full texts, before/after overhead and visitor captures, native receipts and ZIP: `doc/book/iterations/2026-10-08-ca-a-pattern-visits/index.html`.
'''
p.write_bytes(s.encode('utf-8'))
p=M/'encounter-notes.md'
with p.open('a',encoding='utf-8') as f:f.write('''

---

# A pattern visits an address — 8 October 2026

Full runnable two-file tutorial now owns implementation; the reflection's two code blocks become prose. Clarify eight surrounding neighbours and distinguish Conway's reported design ambition from a theorem excluding unbounded growth. Preserve the argument about pattern recognition, withdrawal, support and one-way coupling. The carryable point lets the visitor step while beside an address. The next hall introduces proximity as input.

29 learner checks and 38 museum checks pass. Five capsule/floor routes total 306 samples. The six authored works remain in a levelled rear gallery; mould and growth studies are scaled to fit, the dark sphere and screen repositioned, incidental sculpture reserved out, portals put on thresholds. The Life solver and lamp receiver are unchanged. Before snapshots, an initial test-harness property error, initial route collisions and the corrected evidence are retained in the review directory.

The native screenshots show the installed room from above, obliquely and at eye height. The complete learner study is mounted only temporarily for its own photograph. Existing bright overhead lighting and some blank wall frames remain; this pass does not claim a full art-loading repair, secondary-interaction audit, headset test or independent student review.
''')
print('One lesson plan updated; other lessons and draft decision preserved.')
