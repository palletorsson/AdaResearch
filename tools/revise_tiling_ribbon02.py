"""A small controlled comparison; preserve the existing carrier encounter."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Ribbon_Patterns_02'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_02';S=R/'doc/book/studies/tiling-lineage'
O.mkdir(parents=True,exist_ok=True);(O/'before').mkdir(exist_ok=True)
for n in ['final.md','technical.md','map_data.json']:
 if not (O/'before'/n).exists():shutil.copy2(M/n,O/'before'/n)
if not (O/'before/state.json').exists():(O/'before/state.json').write_text(json.dumps({'tutorial.md':(M/'tutorial.md').exists()}))
if not (O/'before/plan-entry.json').exists():
 data=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
 (O/'before/plan-entry.json').write_text(json.dumps(next(x for x in data['lessons'] if x['id']=='Ribbon_Patterns_02'),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_01/learner/printed/'+n for n in ['palette.gd','grid_surface.gd','point_body.gd']}
for n,p in carried.items():assert (S/n).read_text()==(R/p).read_text()
(O/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
def block(n):return f'<!-- student-code:{n} -->\n```gdscript\n{(S/n).read_text(encoding="utf8").rstrip()}\n```\n'
t='''# Ribbon Patterns 02 — keep the value

## Learning elements

- Holding a target value fixed while changing its surroundings.
- Sharing one material across several bodies.
- Distinguishing stored colour, surface spacing and viewed appearance.
- Predicting what a control changes and what it preserves.

## Look before changing

At the installed **SimultaneousContrast** display, compare the two grey targets. Press SWAP, then SURROUNDS, then CONNECT. Return with UNDO or RESET. These controls leave both target colours at RGB (0.5, 0.5, 0.5). A test can establish that equality. Your visual comparison is a separate observation; it need not match another visitor's.

The previous hall separated stored values from visible layers. Here, a visible value meets its surroundings. Keep our point, palette and two-row, three-column source. Use the familiar five-by-five grid as a selector. A trigger above a cell reads its source value and gives the corresponding colour to **both targets together**. It does not paint the source. We begin with navy, as before; the installed study begins with grey.

## One material, two targets

Replace the previous entry with **08_equal_targets.gd** on the same learner Node3D in the museum, at unit scale. The three unchanged helper files follow below. The museum supplies the player, camera, lights and XR Tools. We set the layered construction aside for this comparison; saved source edits are not imported automatically.

The two targets and their connector use one `StandardMaterial3D`. This is intentional sharing: changing its colour should change all three. Each surround has its own material, so one can remain dark while the other becomes light. Both kinds are unshaded; this exercise removes lighting-dependent shading from the comparison, not the display's colour processing or the viewer.

Grip the black point. Trigger above SWAP to exchange the surrounds, above EQUAL to match them to the target, or above CONNECT to join the targets. Each action toggles back. Unlike the installed console, this small version has no UNDO history. Trigger over the grid to select another colour. Hovering alone changes nothing.

### 08_equal_targets.gd

'''+block('08_equal_targets.gd')+'''
## Follow what stays

`value_at()` is the wrapped lookup we already know. The selector has twenty-five cubes, but the source still has six entries. Grid column 4, row 3 reads source `[1][1]`, value 0. Column 2, row 1 reads source `[1][2]`, value 1. The readout names the **source** address, in `[z][x]` order.

`refresh()` first gives the selected colour to the shared target material. It then sets two independently owned surround materials. SWAP changes which surround is dark; EQUAL makes both match the target. CONNECT changes the bridge's visibility. None of those actions edits a source entry, moves a target or changes its size.

This revisits Temple's ownership question. We copied recipes there when later changes needed to stay local. Here, one material is deliberately shared because equality is the condition we want to preserve. Sharing and copying answer different purposes.

## Predict, then compare

Select column 1, row 0. Both targets become pink. Before pressing SWAP, predict what should happen to each material. The left surround changes from 0.1 grey to 0.9 grey; the right makes the reverse change. Both targets remain pink.

Turn EQUAL on. Both surrounds now use that same pink. The faces may become difficult to distinguish; edges can still disclose the raised targets. Turn CONNECT on, then EQUAL off. The bar shares the targets' colour in either arrangement. Decide what the connector helps you compare. The program cannot decide that for you.

Keep this record in words: **changed condition / values held fixed / what I observed**. Do not replace the last part with what you think you were supposed to see.

## Make another comparison

Make two small edits in the entry file: change the first palette colour from `Color("172051")` to `Color(0.5, 0.5, 0.5)`, and change the source to `[[0, 1, 0], [0, 0, 2]]`. The source still has six entries; the last one now selects the existing mint colour.

Predict before running:

- The first selection gives grey to both targets and the hidden connector. The reference grid's zero-valued cells are grey too.
- Selecting column 2, row 1 gives mint to both targets and the connector; the source remains unchanged by the selection.
- EQUAL makes both surrounds mint. SWAP while EQUAL is on leaves them equal; turning EQUAL off reveals the exchanged dark/light order.
- All twenty-five selector cubes and both target meshes keep their positions.

That is a new comparison made with the same object and controls. It tests whether you can choose the condition being held fixed, not whether you can reproduce a prescribed illusion.

## Carry the method to the curved display

At the installed **MetamerismLab** station, find the blue corner of the same bent mark on the plane and half-cylinder. The name is a registry label; this placement does not demonstrate spectral metamerism. Its code supplies one RGB texture and a small directional shading model.

Both carriers measure four metres horizontally **along their surfaces**. Four repeats therefore occupy one metre each. REPEAT SIZE changes to eight repeats: fifty centimetres each. The two vertical repeats stay one metre high. GRID marks repeat boundaries, not individual source pixels. The half-cylinder has open ends; it is not a seam test.

Walk sideways. Equal surface distances do not guarantee equal widths in the image reaching you. Then try FLAT / SHADED and LIGHT SIDE. The surface directions differ along the curve; the plane keeps one direction. LIGHT SIDE changes a direction used inside the supplied shader, not the museum's sun. Keep the source and geometry fixed while comparing these settings.

We are using those controls to investigate, not rebuilding the curve or introducing dot-product code here. Record one prediction and observation about spacing, then one about shading. Those are different operations, even when both change the appearance. The next hall, Ribbon Patterns 03, follows the sampled value into the shader and fabric studio.

## Complete carried files

These are unchanged from Ribbon Patterns 01. The grid and pickable point retain their construction; the entry changes what their controls do.

'''
for n in carried:t+='### '+n+'\n\n'+block(n)+'\n'
(M/'tutorial.md').write_text(t,encoding='utf8')
f=(O/'before/final.md').read_text(encoding='utf8')
start=f.index('This small shader multiplies');end=f.index('Try **REPEAT SIZE**',start)
f=f[:start]+'''The supplied shader compares each surface direction with a chosen light direction, then uses that comparison to darken the sampled colour. A small constant keeps its darker side from becoming completely black.

These are choices in the experiment. **LIGHT SIDE** changes a direction inside this shader; it does not move the museum's sun. The calculation does not model cloth fibres, gloss or wavelengths. Keeping the model small lets us follow where the difference enters.

'''+f[end:]
(M/'final.md').write_text(f,encoding='utf8')
(O/'spec-student.json').write_text(json.dumps({'lesson':'res://'+O.relative_to(R).as_posix()+'/learner/printed/08_equal_targets.gd'},indent=2))
print('Ribbon02 comparison written; reflective shader excerpt replaced with prose.')
