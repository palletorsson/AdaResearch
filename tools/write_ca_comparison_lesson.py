"""Align the tutorial with the installed comparison, preserving its reflection."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/CA_AgentsCircuits';S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_AgentsCircuits';O=R/'doc/book/iterations/2026-10-08-ca-two-ways-to-make'
intro='''# Two ways to make

## Learning elements

- Rule 90: a next cell is occupied when its two neighbours differ.
- Independent rows store successive states; a picture can show time along one axis.
- A supplied copying recipe places cubes without reading a cellular state.
- Change one input, then identify which construction responds.
- A finite boundary limits a pattern that appears to keep growing.

## Return to the row

The previous hall separated what happens at an address from what it receives from neighbours. Here we return to the Boolean row from the CA opening and the saved history from the third hall. We change its rule, then compare its way of making with the pyramid already in the room.

At the explorer, select 90 and replay the single central seed. The stored rows appear both on the desk and on the floor. Take the same black point at the desk's front rail. Moving it sideways selects a current-row address; its trigger advances one generation. Read the neighbours before pressing. The point is an inspector and a STEP control here, not a seed brush.

Follow one triangular gap across the floor toward the pyramid. Both constructions suggest repeated shapes. Find out what each procedure reads before treating that resemblance as an explanation.

## Reconstruct this comparison

Save your earlier study. Put `procedures.gd`, `comparison.gd` and the unchanged `point_body.gd` together. Attach `comparison.gd` to the existing `PointStudy` Node3D in the Day Zero museum, at unit scale. Leave about 4 × 2.5 metres clear and approach its positive Z side. The museum continues to supply the player, camera, lighting and XR Tools. All required study children are built below.

The compact model shows one history table and one fixed cube construction. The museum also enlarges its history onto the floor and supplies richer rule controls. This reconstruction stays with Rule 90. Enter or the held point's trigger steps; R replays the selected seed; C switches between one cell and two adjacent cells and replays. C and R are keyboard controls here; use the installed desk's SEED and RST buttons in the full VR encounter. Walking keys remain available.

## What does a cell read?

For Rule 90 the centre does not affect the answer. Read the old left and right values. If exactly one is true, the next value is true. If they agree, it is false. For Booleans, `left != right` expresses exclusive OR, often called XOR.

| Left | Right | Next |
| --- | --- | --- |
| false | false | false |
| false | true | true |
| true | false | true |
| true | true | false |

The existing explorer evaluates a numbered eight-case rule including the centre. Its Rule 90 gives this same answer for all eight cases. The shorter expression below exposes that particular rule; it does not replace the general evaluator in the museum.

`next_row` reads the complete old row and returns a new one. The last address neighbours the first. `history` keeps those rows in chronological order. Each row's horizontal positions are space; advancing along the table shows time. New rows change neither the earlier arrays nor the pyramid's positions.

## What does the copying recipe read?

`copy_positions` is supplied from the installed pyramid's placement logic. It reads a position, spacing and remaining depth. At depth zero it returns one position. Otherwise it calls itself at six offsets with half the spacing and one less depth. A function that calls itself is recursive; we will study that process through the Fractals sequence. Here follow just one call and notice its inputs.

The six placements are four lower corners and two upper positions. This particular recipe has an extra upper branch. It does not inspect neighbouring cubes, read the cellular row, or wait for a clock. The returned list contains one entry per leaf call, including entries that may coincide. Every displayed cube keeps the same size; spacing changes during the construction. The result is a finite collection with overlaps, not a demonstration of an ideal fractal's dimension.

At depth 3 the procedure returns 6 × 6 × 6 = 216 entries. The large museum pyramid uses depth 4: 1,296 entries. The compact model scales all final positions and cube sizes together, so its smaller version retains the recipe's proportions. We supply that recipe to make the comparison inspectable; deriving it is not a prerequisite for the neighbour-rule lesson.

## Complete procedures — procedures.gd

'''
middle='''
## Keep the two constructions independent

`make_display` asks for the cube positions once. `step` asks only for a next cellular row. `reset` restores that history from `seed_sites`. None of those cellular operations rebuilds or edits the cubes.

The same PointBody from the previous room supplies its held world position. Converting to study-local X selects an address along the rail. This changes `selected`, not the cells. The readout predicts that address's next value. Release parks the point at the selected address.

`redraw` places every recorded cell, including zeros. Dark tiles show false; they are not holes. Unrecorded rows have zero-size transforms. The table's collider remains solid beneath both states. The miniature cubes are visual instances on a solid plinth; the installed pyramid uses the museum's cube prefab and its colliders. The compact model does not rebuild that larger climbing geometry.

## Complete study — comparison.gd

Read `reset`, `step` and `readout` first. `draw_instances` and `make_display` include the staging so the example can run without prepared child nodes. There is one `_ready`.

'''
point='''
## Unchanged carried object — point_body.gd

Keep your existing copy from the previous hall. It is repeated here only to make the three-file example complete.

'''
end='''
## One beginning, two kinds of change

Replay the single cell at address 16. Before STEP, predict addresses 15, 16 and 17. After one update, 15 and 17 are occupied; 16 is empty. Both new cells read the old 16. No cube in the pyramid moves.

Advance to generation 15 and compare a gap with the fixed sculpture. Then predict generation 16 before pressing. On this 32-cell ring, both expanding edges reach the same opposite address. That address reads two true neighbours, so XOR returns false. The entire next row is empty and remains empty. The pattern did not reach an infinite limit: the finite periodic boundary changed the situation.

Press C to try two adjacent cells. It restarts the cellular history while keeping the same copying construction. Step and compare. Which resemblance survives? You can test the changed row; a visual match with the sculpture remains a judgment about selected features, not a proof that the procedures agree.

Make one independent edit: set `seed_sites` to **[14, 16, 18]**, then restart the script. Predict the first row before pressing Enter. Only addresses **13 and 19** should be occupied. Addresses 15 and 17 each receive two true neighbours and cancel. Check the readout at either cancelled address, and confirm that the 216 cube transforms stayed the same. R replays your edited seed; C returns to the built-in single/pair choices.

The compact table stops after 24 stored rows, generations 0–23, so the comparison stays inspectable. The installed explorer can continue and scrolls its last 24 rows; it labels that retained range. These are different display budgets for the same row update.

You can now distinguish repeating an update from repeating a placement. The next hall keeps the procedure fixed and changes one starting value, asking how far that difference travels.
'''
def block(name):return '```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
(M/'tutorial.md').write_bytes((intro+block('procedures.gd')+middle+block('comparison.gd')+point+block('point_body.gd')+end).encode('utf-8'))
s=(O/'before/final.md').read_text(encoding='utf-8')
s=s.replace('Each new cell is still calculated', 'The small black point is back at the desk. Take it along the rail: the numbers follow an address, while the row stays still. Use its trigger and the next row arrives. In the previous room it placed a seed. Here we have given the same held object another relation to the work: it lets us inspect a place and advance a process.\n\nEach new cell is still calculated')
s=s.replace('images/ca-pattern-correspondence.png','images/two-procedures.png')
(M/'final.md').write_bytes(s.encode('utf-8'))
print('Actual comparison replaces obsolete Wireworld tutorial; reflection gains carried point.')
