"""Authoring snapshot: do not rerun over later editorial changes without review."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/cellular-automata-through-the-hands/CA_GameOfLife'
M=R/'commons/maps/CA_GameOfLife'
text='''# Keep a generation

## Learning elements

- A history made from independent array snapshots.
- Generation and site as different indices.
- One record mapped to two arrangements.
- Visible geometry and collision as separate responsibilities.
- Reading an earlier state without reversing the calculation.
- A fixed record budget and an explicit restart.

## Walk beside the record

We are in Endless Museum. The desk, the tiles in the basin and the upright lattice show the same Rule 30 history. Twelve rows greet you. Walk along the margin: gold follows your position through the record. Turn back. The later rows remain.

Return to the desk and press REPLAY, then STEP. A single occupied site becomes three. This is the row rule from the opening hall. The previous room expanded the neighbourhood into a three-state volume; here we return to the simpler row to investigate **what happens when its past is kept**. The map's historical name, CA_GameOfLife, does not name this rule. Conway's Life is the next hall's main lesson.

## Continue with the point

We carry arrays, loops, an old-to-next update and the small PointBody. Save the previous lesson's script, then attach `history.gd` to the existing `PointStudy` Node3D in the museum. Keep unit scale, place it on level floor with about 2 × 2 metres clear, and face its positive Z side. Put the unchanged `point_body.gd` beside it. The museum supplies the camera, lighting, player and XR Tools; these files create the study itself.

This is a small comparison you can walk around. One saved row becomes a horizontal band and a vertical strip. Move the held point along Z to select an existing generation. Trigger, or Enter, appends a new row. R restarts. Release parks the point at the selected row. In the installed basin your body selects the row; in this reconstruction your familiar point is the reader. The small tiles are not a replacement floor course.

## Save an independent row

`current` is the latest state. `history[g]` is a saved generation; `history[g][x]` reads one site in it. We append in time order: generation zero stays at index zero. This differs from a display that keeps only its newest rows and discards old ones.

`current.duplicate()` gives the record its own row. These entries are Boolean values, so a shallow copy is sufficient. Appending `current` alone would share that array: a later in-place edit could alter the supposed snapshot. A history of nested objects would need a more specific copying agreement.

`next_row` still reads only the old row while writing a fresh one. Left, centre and right make an index from 0 to 7. `ANSWERS` stores Rule 30 in that ascending order, 000 to 111. Left and right wrap at the row's ends. We have not added a new automaton.

The record holds 24 generations, including the seed. At capacity STEP returns without changing it. REPLAY clears the record and begins again from `seeds`. There is no claim of unlimited memory.

## Give the record two uses

In `deck_position`, site X stays horizontal. In `screen_position`, the same site rises vertically. Generation G becomes depth Z in both. A gold marker shows the selected generation, but it contributes no support.

`redraw` reads the record. It does not evolve it. A recorded true cell shows a cube in each view. The horizontal cube also enables its matching collision shape; the upright cube has no collision. Each cell has a reserved instance, indexed by `g * WIDTH + x`. A zero-sized basis hides inactive instances. `set_deferred` changes collision after the current physics work finishes.

An unoccupied recorded cell and an unrecorded future slot both show no cube. The label distinguishes them: it reports the recorded range and refuses a selection outside it. The installed desk makes this distinction with different dark tones as well.

## Complete study — history.gd

The two mapping functions are the part to change in your own arrangement. `make_display` builds the repeated geometry and collision pool once. `redraw` updates those existing receivers. There are no required scene children hidden behind references.

'''
text+='```gdscript\n'+(S/'history.gd').read_text(encoding='utf-8').rstrip()+'\n```\n\n'
text+='''## Carried file — point_body.gd

This is the same point as in the previous two halls. Its construction is printed here so the pair of files is complete; you do not need to rebuild or redesign it. The inherited pickable action supplies the trigger signal.

'''
text+='```gdscript\n'+(S/'point_body.gd').read_text(encoding='utf-8').rstrip()+'\n```\n\n'
text+='''## Read without rewriting

Make six rows. Hold the point and move it back toward generation one. Both gold marks return there. STEP still calculates from the latest `current`, not from the selected row. Selection changes the reading; it does not fork the history. While held, your point's position continues to select the row under your hand after a step.

In the large installation, walking back also leaves the update clock alone. Its manual ROW button pauses RUN; walking does not. That distinction belongs to the controls, not to Rule 30.

## Make another beginning

Change `seeds` from `[7]` to `[5, 9]`, then run the study. Predict the first new row: sites 4, 5, 6, 8, 9 and 10 should appear. Confirm it in both views. Keep that history and change the screen's mapping to `1.05 + (WIDTH - 1 - x) * 0.055`. The wall reading flips vertically; the horizontal tiles, saved rows and future calculation should stay the same. Explain why.

## What travels onward

We can keep a state without confusing it with the current calculation, and change its display without changing the record. Next, a two-dimensional grid holds one present. A glider will seem to move through it while the addressed cells remain in place. A pattern's apparent movement and our stored history are different constructions.
'''
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
f=(M/'final.md').read_text(encoding='utf-8')
start=f.index('The rule reads left');end=f.index('Leave the desk',start)
f=f[:start]+'''The rule reads left, centre and right, as the board in the first hall did. Their ordered states select one of Rule 30's eight answers. Each answer enters a new row while the old row remains available to its other neighbours. The study keeps the new row and adds it to the record.

There are fifteen sites across and room for twenty-four rows. At the edges, left and right wrap. At the end of the record, this instrument stops adding rows. The first boundary belongs to the neighbourhood; the second belongs to our viewing budget.

'''+f[end:]
f=f.replace('None of the four choices has changed in this hall: it is Rule 30 again, three cells in a row, one row at a time. What has changed is where the past is kept.','We have returned to Rule 30 from the opening hall: three cells in a row, one row at a time. We keep its answers and change where the past is held.')
f=f.replace('Press ROW. The line moves','Press ROW. The clock pauses and the line moves')
f=f.replace('Beyond the basin the hall continues: columns, the orb again, a lab, a mirrored automaton.','Beyond the basin, a level passage leads around the lab. The orb and columns stand clear of its back wall; the mirrored automaton waits farther on.')
(M/'final.md').write_bytes(f.encode('utf-8'))
print('Full history tutorial and separate reflection written.')
