"""Author the opening CA lesson from its complete, separately testable scripts."""
from pathlib import Path
import json
import re

R = Path(__file__).resolve().parents[1]
M = R / 'commons/maps/CA_Introduction'
S = R / 'doc/book/studies/cellular-automata-through-the-hands/CA_Introduction'
B = R / 'doc/book/iterations/2026-10-08-ca-a-row-with-neighbours/before'

tutorial = '''# A row with neighbours

## Learning elements

- Binary cell state: `bool`.
- An ordered neighbourhood: left, self, right.
- A rule as eight stored answers.
- A synchronous update: read the old row, then replace it.
- A wrapped boundary.
- Current state and retained history.

## At the board

We are in Endless Museum. The explorer already works. Hold its small black point and move your hand sideways: three marks follow the selected address. The point reads the row; it does not turn a cell on. Press the trigger to advance one generation. The overhead ring receives the same stored rows.

Choose Rule 90 and a single seed. Pause before stepping. Pick a cell, read its left neighbour, itself and its right neighbour, and predict its next state from the table below. The museum's side plate can check your answer. Our smaller reconstruction leaves that prediction to you.

## What we carry

Trace gave us an array of positions; Grid gave those positions addresses. Arrays let us read and replace stored entries. Here each address holds a Boolean: `false` or `true`. The address stays; its state changes. We reuse the pickable sphere from the point lessons as a reader. Its hand position selects an address in the study's local frame.

Continue on your existing `PointStudy` node inside the museum, keeping its earlier script as a previous working version. Save both files below in one folder and attach `row.gd` to that node. Use unit scale. This builds a separate small experiment inside the museum. The camera, lighting, player and XR Tools are already present from Day Zero. No authored mesh, label or scene-child reference is required. Face the node's positive Z side; the board is 0.95 metres above its origin. Keep this experiment separate from the installed explorer while comparing them.

## Three inputs, eight answers

| Left / self / right | Address in the answer list | Next state, Rule 90 |
|---|---:|---:|
| 000 | 0 | 0 |
| 001 | 1 | 1 |
| 010 | 2 | 0 |
| 011 | 3 | 1 |
| 100 | 4 | 1 |
| 101 | 5 | 0 |
| 110 | 6 | 1 |
| 111 | 7 | 0 |

`4 * int(left) + 2 * int(self_cell) + int(right)` turns the ordered inputs into an address. `int(false)` is zero; `int(true)` is one. Compare `100` with `010`: both contain one active cell, but use different entries. A count alone would lose information.

The installed explorer packs these eight answers into the number 90. We keep them as a readable list. They give the same answers; bit operations can wait.

## Give every cell the same present

`evolve` allocates a separate `next` array. Its loop reads only `old`. The result replaces `current` after all addresses have received an answer. Writing directly into `old` would allow a freshly changed neighbour to affect a later calculation.

`posmod` supplies our boundary choice. With 32 cells, the left neighbour of cell 0 is cell 31; the right neighbour of 31 is 0. The calculation joins the ends even when we draw a straight row.

`remember` puts a copy of the current row at the front of `history`. This copy is an observation, not another neighbourhood. Twenty-four observations fit on the board. Older ones leave the display while the generation count continues. The newest row is at the far edge; earlier rows extend towards you. History's second dimension describes time, not a second spatial direction in the rule.

## Complete `row.gd`

The first half defines the state and its update. `make_display` supplies the repeated boxes, marks and label; `redraw` gives those boxes the stored states. Both are included so the experiment can be reconstructed. MultiMesh is display plumbing here, not another lesson to master before understanding the rule.

```gdscript
{row}
```

## Carried `point_body.gd`

This is the earlier pickable sphere construction, reduced to an 8.5 cm radius for this desk. The finish and desktop hooks are supplied adapters. `held()` accepts an XR pickup or the museum's desktop grab; release leaves the reader parked at its selected cell. The point does not collide with or edit the automaton. The complete helper is here so no prior file is silently missing.

```gdscript
{point}
```

## Try a change and account for it

1. Keep the table unchanged. Set `seeds` to `[15, 16]`. Before running, write the addresses you predict will be active after one step. Run and compare. Explain one address where the two seeds meet.
2. Return to `[16]`. Reverse the traversal by replacing `for i in range(old.size()):` with `for i in range(old.size() - 1, -1, -1):`. Predict whether the next row will change. Test both versions from the same seed, keeping the original file.
3. Use `[0]` as the seed. Follow both sides of its first generation and explain where the boundary appears in the drawing.

Hold the point to inspect. Trigger or Enter advances the reconstruction once. Re-running or calling `reset()` restores the selected seed and clears its history. Unlike the installed explorer, this small study has no automatic RUN, rule slider or overhead receiver. The same eight-answer list can later receive a different interface.

Carry the row engine, its explicit boundary and its independent history. In the next hall we will change what a cell can hold and who counts as its neighbour. The rug and growing network remain encounters in the wider museum; we do not need to rebuild them to understand this step.
'''
tutorial = tutorial.replace('{row}', (S/'row.gd').read_text(encoding='utf-8').rstrip()).replace('{point}', (S/'point_body.gd').read_text(encoding='utf-8').rstrip())
(M/'tutorial.md').write_text(tutorial, encoding='utf-8')

# Targeted edits to the existing reflective text; preserve its wider encounters.
p=M/'final.md'; text=(B/'final.md').read_text(encoding='utf-8')
text=text.replace('Three small marks pick out a cell and its two neighbours.', 'The black point has become a reader. Hold it and move your hand sideways: three small marks pick out a cell and its two neighbours. You change which address we inspect; the row keeps its state until you ask it to step.')
text=re.sub(r'The explorer consults its rule through these actual lines:\s*```gdscript.*?```\s*Three on/off states make eight possible arrangements\. The shifts place them into an index from zero to seven\.', 'Three on/off states make eight possible arrangements.', text, flags=re.S)
text=re.sub(r'The update writes a separate row\. Here is the loop inside `_advance`, followed by the moment the new row becomes current:\s*```gdscript.*?```', 'The update writes a separate row before making it current.', text, flags=re.S)
text=re.sub(r' In `_enforce_quadrant`, one value is written into three reflected positions \(comments between these assignments are omitted\):\s*```gdscript.*?```', ' One value is copied into three reflected positions.', text, flags=re.S)
text=text.replace('The modulo operations in the loop join the two ends.', 'The boundary rule joins the two ends.')
p.write_text(text,encoding='utf-8')

note='''## 8 October 2026 — one row, one reader

The opening tutorial now prints two complete scripts: `row.gd` and the carried `point_body.gd`. They reconstruct a 32-cell binary automaton with an explicit eight-answer Rule 90 table, separate old/next rows, wrapped neighbours and 24 retained snapshots. The installed explorer retains its existing rule calculation, controls and history. Only `room:ring` adds `hand_point.gd`: lateral hand movement selects `sample_cell`; trigger calls the existing `step()`. Release parks at the selected address. Other explorer configurations do not receive this reader.

The compact study and installed artwork remain distinct: the study has manual steps and no overhead receiver; the installed ring reads the explorer's existing history. No second museum clock or CA engine was added. Synthetic XR and desktop checks are not headset usability evidence. See `doc/book/iterations/2026-10-08-ca-a-row-with-neighbours/` for source snapshots, assertions and native captures.

'''
for name in ['technical.md','encounter-notes.md']:
 p=M/name; s=(B/name).read_text(encoding='utf-8'); temporary=p.with_suffix('.new.md'); temporary.write_bytes((note+s).encode('utf-8')); temporary.replace(p)

p=R/'doc/book/course/execution-plan/plan.json'
data=json.loads(p.read_text(encoding='utf-8-sig'))
x=next(x for x in data['lessons'] if x['id']=='CA_Introduction')
x.update(object='The carried PointBody reads a 32-cell row; a separate history display retains its generations.', change='Reconstruct the installed Rule 90 behaviour with an explicit eight-answer table, wrapped neighbours and an old-to-next update.', reuses='Pickable PointBody and local position; arrays, indexed entries, loops and conditionals.', given='Existing museum player, camera, lighting and XR Tools. Full point adapter and display construction are printed.', later='Rule byte encoding; automatic clocks; 2D rug symmetry; network growth. These are not required to build the row.', transfer='Predict two adjacent seeds; independently reverse traversal and compare from the same seed; test a seed at address zero.', carry='A synchronous binary row engine, explicit wrapped boundary and copied history, with the familiar point as reader.', next='CA_ElementaryRules: expand neighbourhood into a volume and state into empty, active and fading.', notes='Complete reconstruction now available in tutorial.md. Installed hand reader delegates to existing explorer state and step; no second automaton.', summary='Carry the pickable point into a row of 32 cells. Move it to inspect left, self and right, then trigger one generation. Reconstruct Rule 90 as eight readable answers; calculate every next cell from the same old row, wrap the boundary and keep copied history separately. Predict two adjacent seeds and test reversed traversal from the same beginning. Carry the row engine and the distinction between state and its record into the next three-state volume.')
x['dependsOn']=['Point_Coordinates','Point_Line_Grid','Array']
x['checks']=[
 'Exact two printed scripts construct the row, reader and label with no authored scene children.',
 'Eight answers and forty complete generations match the installed explorer for Rules 90 and 30.',
 'Adjacent seeds and a boundary seed match predictions; reversed traversal preserves thirty generations.',
 'A deliberately in-place update is rejected; history copies remain independent and bounded at 24.',
 'Actual XRTools pickup in a rotated frame selects an address; trigger steps once; release parks.',
 'Installed hall reader advances the existing explorer and its shared ring history. No headset claim.'
]
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('CA opening text and its plan row written; final retains wider encounters.')
