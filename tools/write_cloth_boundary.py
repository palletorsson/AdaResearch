from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Cloth_Physics'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics'
O=R/'doc/book/iterations/2026-10-09-cloth-which-points-stay'
raise SystemExit('Initial draft generator retained for provenance; canonical tutorial has since been corrected by native tests. Use the current tutorial and test_cloth_boundary.py.')
old=(O/'before/commons/maps/SoftBodies_Cloth_Physics/tutorial.md').read_text(encoding='utf8')
optional=old[old.index('<!-- study-spine:tension_membrane -->'):]
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```'
t='''# Cloth Physics — which points must stay?

## Learning elements

- An open sheet as a subdivided mesh
- Select a set of vertices from reference coordinates
- Combine conditions: top row, upper corners, no pins
- Separate the visible support from the simulated attachment
- Distinguish re-pinning a running body from rebuilding it

The cube in the previous hall gave way around one fixed point. Keep its SoftBody3D setup and the black PointBody. Change the closed BoxMesh into an open sheet, then change the set of points that must stay. The new operation is a selection rule, not another solver.

## Begin with the hanging strips

The museum already contains eight strips. PINS changes each upper row from eight pinned points to two corners. RELEASE lets them all go. SUPPORT changes the surrounding frame without changing the pin indices. REBUILD makes fresh strips. Try those separately before touching STIFFNESS.

We reconstruct one wider, shorter sheet so that the upper edge is easy to inspect. Its mesh has the same subdivision counts as a museum strip; its dimensions are 1.2 by 1.4 metres. This is a small study of the same operation, not a duplicate of the whole curtain.

Save the three files together. Attach `study.gd` to a unit-scale Node3D in an open part of this existing hall. The prepared museum supplies its camera, floor, player, Jolt and XRTools. The review tests a temporary learner bay beside the strips; the scene does not replace the installed curtain.

## From one selected point to a selected edge

`hanging_sheet.gd` keeps the previous lesson's construction order: the mesh exists in `_init()` before the host adds the body to the world. `PlaneMesh.FACE_Z` puts this sheet in its local x–y plane. Its open surface has no enclosed volume, so pressure stays zero. Stiffness, damping and solver precision match the museum strips and remain fixed during the boundary comparison.

Keep `rest_points` before the solver starts. These local coordinates describe which vertices belong to the original top row, even after the sheet sags or the host moves. `set_pins()` applies one Boolean decision to every array entry:

- Mode 0: the point is on the top row.
- Mode 1: it is on that row **and** at either outer x edge.
- Mode 2: neither condition admits a pin.

The second `absf()` lets one test include both left and right edges. The small tolerance avoids requiring exact floating-point equality. Each call also unpins entries that no longer qualify; merely adding the two corners would leave the original row held.

{sheet}

Six width subdivisions produce eight vertex columns. Twelve depth subdivisions produce fourteen rows: 112 entries. The first policy selects eight; the second selects two. The word `COLUMNS` is the subdivision setting here, not the final vertex count.

## Continue with the same point

The host builds a small bar, the sheet, a readout and the unchanged point. Gold dots show the currently pinned positions. The bar is a visual mesh with no collider. Hiding it cannot remove pins. The museum's larger supports can have colliders, so changing their architecture can still change contact or passage while leaving the pin rule alone.

Grab the black point and press slowly into the sheet. Its existing collider is included in the sheet's mask, just as in the previous lesson. Press the held trigger to switch between row and corner pins. On desktop, **1** does the same; **2** shows or hides the bar, **X** releases all pins and **R** rebuilds the sheet. The installed museum desk provides its own XR-accessible controls; this reduced host's extra comparisons use those keyboard keys.

{host}

`PINS` changes the current body. It does not create a new sheet or restore the old surface positions. If you pin a previously free point, it stays where it has reached. The gold dots read those positions from the physics body. They do not assume that re-pinning has pulled the edge back to the bar.

`REBUILD` has a different job. It removes the old sheet and constructs a fresh one from the reference mesh, with the top row fixed. The same black point and visible bar survive. This is the distinction we met at the cube: changing a condition and starting a new run are different operations.

<details>
<summary>Carried file: point_body.gd — unchanged from Soft Body Deformation</summary>

Keep your existing file, or use this identical copy. Sphere construction and grab behaviour are already learned work.

{point}

</details>

## Predict a release

Begin with the upper row pinned. Hide the bar. Predict that the eight attachments stay where they are, then check the gold dots. Bring the bar back and switch to two corners. Watch the six released upper points before pressing the sheet.

Switch back to the row. Does its edge straighten, or become fixed in its current shape? Rebuild to recover the original straight edge. Then release every pin and watch gravity act. Rebuild again before the next comparison. Keep stiffness and damping unchanged throughout.

Now change `COLUMNS` from 6 to 10 and restart. Predict twelve top-row pins, two corner pins and 168 total entries. The same selection rule should work without a new list of vertex numbers. Explain why the middle points may move in corner mode even though every coefficient is unchanged.

Carry the reference coordinates and the selected boundary into the next hall. There the attachment itself will move. We first need to know what is being carried by it.

Sources: `algorithms/softbodies/cloth_straps/cloth_straps.gd`, `_setup_lesson_straps()`; `commons/artifacts/timing_machines/soft_workshop.gd`, `_cloth_pins()`. API: [PlaneMesh](https://docs.godotengine.org/en/4.6/classes/class_planemesh.html) and [SoftBody3D](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html). The engine solver is supplied; the boundary selection and complete learner host are printed above.

The following installed membrane is an optional return. It changes load while preserving four anchors and uses its own supplied constraint solver. It is not another implementation of the sheet above.

'''.format(sheet=code('hanging_sheet.gd'),host=code('study.gd'),point=code('point_body.gd'))
(M/'tutorial.md').write_bytes((t+optional).encode('utf8'))
f=(O/'before/commons/maps/SoftBodies_Cloth_Physics/final.md').read_text(encoding='utf8')
f=re.sub(r'The rule that holds that edge never looks at the frame:\n\n```gdscript\n.*?\n```\n\n`verts` is the strip\'s own rest geometry, in its own coordinates. `ymax` is the highest value in it.', "The rule that holds that edge never looks at the frame. It reads the strip's original geometry in its own coordinates and finds the highest row.",f,flags=re.S)
f=f.replace('The strips are on the floor now. **REBUILD** makes a fresh hanging rank.', 'The strips can fall now. **REBUILD** makes a fresh hanging rank.')
f=f.replace('The solver ran the same way on the same mesh.', 'The solver and its coefficients remained the same; the boundary changed.')
f=f.replace('On the way out the floor runs empty for a long time, and then a few cells stand higher than the rest and one is missing altogether — the fixed points of the room this hall used to be, left where they were when everything around them was moved.', 'Beyond these encounters, the earlier room remains inside the enlarged hall. Its raised cells ask your feet to negotiate another kind of boundary. The curtain\'s pins and the floor\'s supports belong to different constructions; you meet their consequences in the same body.')
(M/'final.md').write_bytes(f.encode('utf8'))
p=M/'technical.md';s=p.read_text(encoding='utf8').replace('Godot Physics adds bending links as well as triangle-edge links.', 'The current project uses Jolt Physics. Earlier GodotPhysics3D constraint descriptions are historical and are not a description of this solver.')
s+='\n## Runnable boundary reconstruction · 9 October 2026\n\nThe tutorial prints a complete 1.2 × 1.4 m PlaneMesh study, with the installed subdivision counts (6/12), stiffness .34, damping .05 and precision 5. Reference coordinates choose a top row, upper corners or no pins. Mesh construction precedes world entry. The black PointBody is copied unchanged from the preceding lesson; the contact mask includes its layer. The visual bar has no collision, unlike some installed support variants. Re-pinning retains current positions; REBUILD creates a new body. The optional tension membrane application and its supplied solver remain separate. See the dated review for executable tests, actual museum images and remaining limits.\n'
p.write_bytes(s.encode('utf8'))
