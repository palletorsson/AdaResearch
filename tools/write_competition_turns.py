from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-competition-the-next-turn'
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Competition'
def code(name):
    return '\n<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
text='''# Competition — the next turn

## Learning elements

- A shared resource grid
- Sequential updates and execution order
- Consumption before a conditional rewrite
- Independent before/after records

Architecture gave a sentence width and boundaries. Here two copies of a sentence meet the same changing field. You bring the rewrite function, saved turtle state, indexed records, and the point you can hold. The new question is **what has already happened when the next instruction runs?**

## Look at the existing pair

At the front of Competition, both stems start with F and use the same rule. Hold the black point beside the console. A trigger press gives one tree a turn; the next press gives the other its turn. STEP does the same. Take two turns: A receives 2.250 and B receives 1.980. ORDER restores the starting field and makes B first. Repeat: the allocation reverses. These are model values, not measured quantities of food.

SEASON restores the comparison in winter. Consumption still happens, but the sentence stays F. Look at the soil as well as the stem. The unchanged shape does not mean that nothing happened.

## Rebuild the relation

Continue in the prepared museum project. Put the five files below in one folder and attach `competition.gd` to an empty, unit-scale Node3D in a clear working bay. The existing museum supplies the floor, camera, player and XRTools. Run the project as before. Do not attach this script to the running ForestCompetition object: it makes a separate small study. For comparison, place its host at the front study's transform in a working copy with the existing primary hidden; leave the visitor route clear. Its visual field spans x −3.5…3.5 and z −6.5…0.5; the control is at z 2.3.

The point, cylinder renderer and grammar reader are unchanged from Curves. The branches return to that reader's vertical plane, 25° turns and 0.32-metre steps. Each copy starts at a separate display position; its soil address is recorded elsewhere. Moving a display is not moving a root.

We isolate the opening resource experiment. Each root keeps a fixed five-by-five sampling square. Health, diameter growth, diffusion and automatic seasons are left to the installed forest. Consequently, the first pair of resource requests agrees with the museum; later resource histories and branch dimensions need not. The installed forest enlarges its sampling area as its estimated crown grows. This small study keeps the area fixed so that order stays visible.

### 1. Keep one soil field

`soil.gd` gives each row its own array. `patch()` turns a root address into valid cell addresses. `consume()` reads each current value, takes fifteen percent and writes the remainder back to **the shared grid**.
'''+code('soil.gd')+'''
Both initial squares contain 25 cells. Their roots are one cell apart, so they share 20 cells. The first request receives 25 × 0.6 × 0.15 = 2.25. For the second, those 20 shared cells contain 0.51; five untouched cells still contain 0.6. Its uptake is (20 × 0.51 + 5 × 0.6) × 0.15 = 1.98.

The second request does not read a saved copy of the opening grid. This differs from the cellular automata update that computed an entire next generation from one old state. Both are valid schedules; they compute different relations.

### 2. Give one tree a turn

`competition.gd` creates two sentence records, the field, the drawings and the held point. ENTER or its held trigger calls `attempt()`. O resets with the opposite first tree; W resets with the opposite season; R returns to spring with A first. ORDER keeps the selected season, and SEASON keeps the selected first tree.

Read `attempt()` first. `trees[next]` selects a record; editing that dictionary updates the stored tree. Consumption precedes the winter test. A successful test permits the inherited rewrite; it does not invent a new branching algorithm. `next = 1 - next` alternates 0 and 1.

The two `duplicate(true)` calls preserve complete field snapshots. A reference to the same mutable array would keep changing, erasing the evidence of the earlier state. The retained history is bounded to 80 attempts; it lives in this running scene, not across halls or restarts.
'''+code('competition.gd')+'''
The generation cap is checked before consumption. At three generations, a capped tree takes nothing. Winter instead consumes and then refuses rewriting. These two still stems have different histories. The symbol budget in `rewrite()` remains an additional limit; this three-generation example stays below it.

`redraw()` reads the resulting state; it does not take another turn. The tile height and colour expose resource values. Each outline identifies a sampling square, and the small vertical mark identifies its centre cell. The two branching displays use the same reader and stride. Their separate positions help inspection, without separating their resource patches. The drawing has no terrain collision; the supplied museum floor supports the visitor.

### 3. Keep the known tools

These are the exact Curves files. Keep your existing copies if unchanged. They are printed here so the complete program can be reconstructed without hidden helpers. No scene-child references or prepared meshes are required.

`grammar.gd` retains whole-generation rewriting, bracket validation and copied turtle state. This study calls its ordinary reader with sideways set to false.
'''+code('grammar.gd')+'''
`point_body.gd` retains the frozen pickable sphere and desktop grab hooks. The new behaviour is the action connection in `competition.gd`.
'''+code('point_body.gd')+'''
`line_skin.gd` gives each segment a finite cylindrical surface, as before.
'''+code('line_skin.gd')+'''
## Predict, change, check

1. Reset, then take two turns. Both generations become one; the last uptake values are 2.250 and 1.980. Reverse the first tree from a reset state and repeat. The allocation reverses. For this fixed-area, fixed-fraction model, the field after the completed pair is the same in either order.
2. Select winter and take two turns. Both sentences remain F while the resource total falls by 4.23. Read the saved `before` and `after` grids. Taking another turn must not change the older event's snapshots.
3. In `soil.gd`, change only the second root from `Vector2i(10, 10)` to `Vector2i(14, 10)`. Predict whether the two sampling squares still overlap. Run the complete edited program: each first request now receives 2.250, whichever acts first. Explain why order stopped changing this allocation without changing the grammar.
4. Restore the original roots. Six spring attempts give both trees three generations. The next two leave the soil unchanged. Contrast this with the winter result.

## Return to the forest

The installed SOIL button advances diffusion and replenishment for one second without giving a tree a turn. Our small program deliberately omits that extra process. Behind the pair, the original five-strategy forest combines soil time, seasons, crown size and crowding. The coral nearby follows a separate recipe; it does not consume this field.

You carry forward an unchanged instruction whose execution depends on a changing situation, and records that let you inspect the difference. In Living, we ask which changes an authored set of controls lets us request from a body.
'''
(R/'commons/maps/LSystems_Competition/tutorial.md').write_bytes(text.encode())
final=(O/'before/commons/maps/LSystems_Competition/final.md').read_text(encoding='utf-8')
final=final.replace('Press STEP: A takes a turn.', 'Hold the black point beside the console and press its trigger, or press STEP: A takes a turn.')
start=final.index("The forest does something before applying it.")
end=final.index('Each initial sampling square',start)
final=final[:start]+"The forest does something before applying it. It reads the soil around the selected root, subtracts fifteen percent from each cell, and adds those portions to the tree’s uptake. Both trees begin with the same appetite.\n\n"+final[end:]
start=final.index('The consumption happened before this test:')
end=final.index('Winter refuses the rewrite.',start)
final=final[:start]+"Only after consuming does the forest ask whether enough was taken and whether the season permits a rewrite.\n\n"+final[end:]
(R/'commons/maps/LSystems_Competition/final.md').write_bytes(final.encode())
print('Wrote complete Competition tutorial and targeted reflection edits.')
