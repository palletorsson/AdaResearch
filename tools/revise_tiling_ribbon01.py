"""Carry the cube grid into indexed layers; preserve the installed reflection."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Ribbon_Patterns_01'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_01';S=R/'doc/book/studies/tiling-lineage'
O.mkdir(parents=True,exist_ok=True);(O/'before').mkdir(exist_ok=True)
for n in ['final.md','map_data.json','technical.md']:
 if not (O/'before'/n).exists():shutil.copy2(M/n,O/'before'/n)
if not (O/'before/state.json').exists():(O/'before/state.json').write_text(json.dumps({'tutorial.md':(M/'tutorial.md').exists(),'final.md':True}))
if not (O/'before/plan-entry.json').exists():
 plan=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
 (O/'before/plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Ribbon_Patterns_01'),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Temple/learner/printed/'+n for n in ['palette.gd','grid_surface.gd','point_body.gd']}
for n,p in carried.items():assert (S/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
(O/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
def block(n):return f'<!-- student-code:{n} -->\n```gdscript\n{(S/n).read_text(encoding="utf8").rstrip()}\n```\n'
t='''# Ribbon Patterns 01 — an address gains depth

## Learning elements

- Storing a volume as layers of rows: `[y][z][x]`.
- Letting height change a source lookup.
- Wrapping a shifted address.
- Separating stored values, visible cells and absent data.

## Start with the installed pair

The low source array and the volume near the entrance belong together. The console names their storage order: SOURCE `[z][x]`, VOLUME `[y][z][x]`. Use X + and Z +, then LAYER +. A frame moves up through the volume while another names the source entry it reads. REPEAT / SHIFT makes height enter that reading. SLICE / ALL hides the other layers; UNDO returns to an earlier state.

There are sixteen source entries and sixty-four volume entries. A slice shows sixteen of the sixty-four. Zero selects a pale cube here. It is a value with a visible body, not an empty address.

## Carry the source and the point

In Pattern Temple we kept a separate record for each receiver. Here, make a related arrangement: layers of receivers filled by one rule. Keep our two-row, three-column source, three colours, black point and five-by-five `GridSurface`. Put one grid on the left as a reference; stack four on the right. There are **six source values, twenty-five reference cubes and one hundred stored volume values**. The counts differ from the installed pair because we are developing our smaller construction.

Begin with translation, the P1 reading we already know. Hold reflection and glide aside while asking what height adds. In REPEAT, all four layers read the same source. In SHIFT, layer `y` adds `y` to the source column before wrapping. Cube positions stay fixed.

Replace the previous entry with **07_layer_reader.gd** on the same learner Node3D in the museum. Keep its root at unit scale. The three unchanged helper files follow below. The existing museum still supplies the player, camera, light and XR Tools.

The point now inspects the selected layer. Grip it, hold it above LAYER, SLICE or SHIFT, and trigger. Over the grid, hovering shows the volume and source addresses; triggering there does not paint. We keep the source fixed for this comparison. The left marker identifies the source entry in the first two rows and three columns of the reference grid; the remaining reference cells repeat those values.

### 07_layer_reader.gd

'''+block('07_layer_reader.gd')+'''
## One more index

`values[y]` selects a layer. `values[y][z]` selects a row in that layer. `values[y][z][x]` reads one stored palette index. When placed in space, the directions are still x, y and z. Storage order is a convention we declare, not a change in those directions.

The outer loop in `fill_values()` creates a fresh `sheet` for each height. Its inner loop creates a fresh `row`. Reusing one row or sheet would make several entries refer to the same mutable list—the ownership problem from Temple would return inside the volume.

`source_address()` gives the original source address. `sample()` reads its value. `fill_values()` stores those readings and colours the existing cubes. The loop that positions the grids runs only when the construction starts. SHIFT fills new values; it does not move the layers.

Our volume is a derived record. Changing the source in code requires running `fill_values()` again to update it. No automatic live connection is implied by having sampled a source once.

## Predict a cell before selecting it

Set LAYER to 1 and inspect column 4, row 3: volume `[1][3][4]`. In REPEAT, column 4 wraps to source column 1; row 3 wraps to source row 1. That entry contains 0, navy.

In SHIFT, the column reads `(4 + 1)` wrapped across three columns: source column 2. Source `[1][2]` contains 1, pink. The marker on the reference moves one column. The selected volume address and the cube position stay still.

Now follow volume column 0, row 1 through layers 0, 1, 2 and 3 with SHIFT on. Its values are **0, 0, 1, 0**. The reading returns after three height steps because the source is three columns wide. Four stored layers do not imply a four-layer pattern period.

## A view is not a deletion

SLICE calls `update_view()`. It changes each layer's `visible` property; it does not clear `values`, remove children or regenerate cubes. The display shows twenty-five volume cells and keeps one hundred stored. The twenty-five reference cubes are separate from that counter.

Use LAYER while sliced. Inspect the same row and column at another height. Then restore ALL. Hidden values return with their bodies because neither was deleted. A cube obscured behind another cube is different again: its node may be visible even though your view is blocked.

In our carried palette, zero is navy; in the installed pair it is pale. In both cases, the program draws a cube for it. A previous occupancy lesson could use zero to mean vacancy. These meanings come from what the program does with a value, not from the number alone.

## Change the direction of the reading

Make an independent edit: set `LAYER_COUNT` to 3 and `SHIFT_STEP` to -1. Keep the same source and rendering helper. Predict before running:

- The volume stores 75 values. SLICE shows 25; the reference still has 25 cubes.
- With SHIFT on, volume `[1][1][0]` reads source `[1][2]`: value 1, pink. The negative offset wraps back into the source.
- At column 0, row 1, the three layers read **0, 1, 0**.
- Three presses of LAYER return to the starting layer. SHIFT changes no receiver positions.

`posmod()` is useful here: a negative input still produces an address between zero and width minus one. Do not replace it with a remainder that can stay negative. The readout should name column 2, not -1, even if a language allows a negative list index to reach the same value.

## Return to the larger array

Find the same distinction at the installed console: a selected layer, a source lookup, a stored value, and a body you may or may not see. Its fixed four-by-four source shifts with a four-column wrap. Our smaller source repeats with a three-column wrap. Neither example imports edits from the other automatically.

The bars, shelves and sorting examples elsewhere in the hall can remain other encounters. This tutorial follows the layered reader. In Ribbon Patterns 02, keep the value fixed and ask what its surroundings and receiving surface add to what you see.

## Complete carried files

The grid, palette and pickable point are unchanged from Pattern Temple. Their construction is supplied here; the new work is how layers are filled and inspected.

'''
for n in carried:t+='### '+n+'\n\n'+block(n)+'\n'
(M/'tutorial.md').write_text(t,encoding='utf8')
final=(O/'before/final.md').read_text(encoding='utf8')
final=final.replace('In the previous room, one source could repeat, reverse and slip across a plane. The corridor wrapped a pattern around several faces. Here, look between the faces. There are addresses behind the ones you can see.','In Pattern Temple, a copied recipe reached the floor, walls, columns and dome. The surfaces could agree and then become different again. Here, look between the faces. There are addresses behind the ones you can see.')
start=final.index('The changed rule is small. This is the lookup')
end=final.index('Each result is stored',start)
final=final[:start]+'The changed rule is small: height advances the column read from the source. When that reading reaches the edge, it returns to the beginning.\n\n'+final[end:]
(M/'final.md').write_text(final,encoding='utf8')
(O/'spec-student.json').write_text(json.dumps({'lesson':'res://'+O.relative_to(R).as_posix()+'/learner/printed/07_layer_reader.gd'},indent=2))
print('Ribbon 01 tutorial written; reflection transition and code passage tightened.')
