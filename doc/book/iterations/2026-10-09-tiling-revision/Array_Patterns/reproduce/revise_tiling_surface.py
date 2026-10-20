from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/Array_Patterns'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Array_Patterns'
S=R/'doc/book/studies/tiling-lineage'
def block(n):return f'<!-- student-code:{n} -->\n```gdscript\n{(S/n).read_text(encoding="utf-8").rstrip()}\n```\n'
O.mkdir(parents=True,exist_ok=True);(O/'before').mkdir(exist_ok=True)
for n in ['tutorial.md','final.md','map_data.json']:
 if not (O/'before'/n).exists():shutil.copy2(M/n,O/'before'/n)
plan=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf-8'))
if not (O/'before/plan-entry.json').exists():(O/'before/plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Array_Patterns'),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Tutorial_Pattern/learner/printed/'+n for n in ['palette.gd','grid_surface.gd','point_body.gd']}
for n,p in carried.items():assert (S/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
(O/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
text='''# Array Patterns — give the address a surface

## Learning elements

- Receiver origin and local axes.
- Cell spacing in metres.
- World position back to a surface address.
- Source width, repeat period and display extent.

## Walk the larger example

Enter the tunnel's side bay. Its console stands beside the lower end of the ramp. Press COL + four times: the surface column advances while the source column returns. Press FACE and follow the indicator onto the right wall. The same row and column now point in different directions through the room.

The installed tunnel has a fixed four-by-four source. CELL SIZE changes a cell from 40 to 60 centimetres; the motif's width changes from 1.6 to 2.4 metres. The tunnel keeps its dimensions. GRID hides the drawn divisions while the supports still hold you. UNDO restores a setting.

Keep our smaller two-by-three source, five-by-five cube grid and black point. Tutorial Pattern changed the address that reads a source. Here we hold that reading still and change the receiver's position, orientation and scale. These are the operations from Transformation, returning with a purpose.

## Turn the carried grid

Replace the preceding entry script with `04_surface_frame.gd`. Keep the three carried files beside it, on the same empty Node3D in your museum learner space. The root stands on the floor at unit scale; it may be moved and turned. The museum supplies the player, camera, lighting and XR Tools. This small display has no floor or wall collision of its own.

Grip the point and move it above the cubes. Its centre selects an addressed interval; the ring follows that interval. The source remains fixed in this comparison. The point now inspects instead of painting.

At the front, hold the point over FACE, then press the trigger. The grid becomes a right-wall panel: columns go along the room and rows go down. Hold it over CELL WIDTH and trigger to enlarge the intervals from 32 to 48 centimetres. The labels stand 60 centimetres to either side, 2.5 metres from the root; select with the point centre between 95 and 150 centimetres above the floor. The readout names the action before you press. Hovering alone changes no setting.

### 04_surface_frame.gd

'''+block('04_surface_frame.gd')+'''
`place_receiver()` changes the existing grid node. It neither recreates the cubes nor reads a different source. In the table pose, local X runs across and local Z follows the rows along the floor. The first cube centre is at the grid's origin. On the right wall, the two quarter-turns put local X along the room's Z direction, local Z downward, and local Y outward toward you.

The helper still places neighbouring cube centres 0.32 local units apart. Dividing the desired width by that spacing gives the scale: 0.48 / 0.32 = 1.5. The cubes, their gaps and the selection ring all grow together. Here **cell width means centre-to-centre spacing**, not the coloured cube's width; each cube leaves a small gap around it.

The address calculation has a return journey. `to_local()` takes the point's world position through the inverse of the grid's translation, rotation and scale. We can then use the same local X/Z calculation on either face. Adding half a pitch places the first interval's boundary half a cell before its centre. `floori()` chooses the interval; the dictionary rejects addresses outside the five-by-five display.

Local Y measures distance out from the receiver. Multiplying by the grid's uniform scale returns that distance to metres. The allowed point-centre distance stays 12–65 centimetres on both faces and at both sizes. Testing world Y would work above the table and fail beside the wall. This conversion assumes the lesson root remains at unit scale.

### The carried files

Palette, GridSurface and PointBody are unchanged from Tutorial Pattern. Their complete code is kept here for reconstruction; the new work is the receiver frame and its inverse selection. The point's pickup and release behaviour remain supplied by the earlier class.

### palette.gd

'''+block('palette.gd')+'\n### grid_surface.gd\n\n'+block('grid_surface.gd')+'\n### point_body.gd\n\n'+block('point_body.gd')+'''
## Predict, then inspect

Select surface **row 1, column 3**. With the printed translation reader, it consults source **row 1, column 0**: navy. Turn the receiver into the right-wall pose and find that address again. Its position has changed; its value has not. Moving the whole learner root elsewhere in the museum should preserve this relation too.

At 32 centimetres per cell, the three-column source spans 96 centimetres. At 48 centimetres it spans 1.44 metres. The five addressed intervals span 1.6 and 2.4 metres respectively; the outermost cube edges sit slightly inside those bounds. Neither display contains two complete horizontal copies of the source.

Change the width list to `[0.24, 0.36]`. Before running, predict the new source widths: **0.72 and 1.08 metres**. Keep the source and the twenty-five colours unchanged. After turning and enlarging the receiver, the point should still find surface row 1, column 3. It should stop selecting when its centre is more than 65 centimetres from the surface.

The previous reflected reader is retained in `source_address()`. If you deliberately start with `reflected = true`, the same surface address reads source row 1, column 2: pink. For this asymmetric source, the horizontal translation period is then six cells, twice the source width. Turning or resizing the receiver does not switch that rule.

## Return to the passage

The little grid changes size as a whole. The installed tunnel holds its dimensions and changes how many intervals fit across each face. Both keep their source, but they answer different spatial constraints. Look for the cut interval at the tunnel's boundary and the place where its wall starts counting again.

Carry three things separately: the source entry, the address that reads it, and the frame that gives the address a place. Symmetry Seventeen will compare operations on the repeating field. The room's finite edges remain available to test what that comparison leaves out.
'''
(M/'tutorial.md').write_text(text,encoding='utf-8')
final=(O/'before/final.md').read_text(encoding='utf-8')
final=final.replace('```gdscript\ncolumn % 4\nrow % 4\n```\n\nThese are the wrapping expressions used by the inspector.','The inspector wraps each surface coordinate back into the four-cell source.')
(M/'final.md').write_text(final,encoding='utf-8')
print('Array Patterns: complete four-file tutorial; reflection retains its encounter and replaces code with prose.')
