# Joined faces â€” TriangleTable and Square Assembly

Both artifacts use `face_assembly.gd`. The existing `triangle_assembly_table.tscn`
remains the source for TriangleTable in Point Triangle Context. The square sibling
is placed in Point Animatedcube (main floor7). There are twelve independently
pickable and editor-placeable starting panels per assembly, each with 0.32m edges.

When all available faces have been joined into forms, six more appear on the
right-hand stock area, following its editable Support pose. MORE FACES can request another six earlier. Real collision
queries find clear spaces and small stacks without moving existing work. If the
stock area is completely blocked, clear it and press MORE FACES. There is a
96-panel live limit per table. START OVER removes runtime stock and restores the
twelve editor-authored panels. Isolated editor-part copies do not replenish.
Extra live stock is session construction material; the browser shows the saved
starting layout, rather than persisting a play session's generated panels.

Bring parallel free edges within14cm, then release. The selected signed fold
rotates the new face around the shared edge; both endpoints coincide. Zero is a
flat outward extension,90 is a right-angle corner.70.529 degrees closes an eight-triangle diamond (regular octahedron).
The DIAMOND button selects that exact angle. CUBE selects 90 degrees.
109.471 degrees from flat is
included for closing an equilateral tetrahedron. Select the angle on the physical
minus/plus buttons; OTHER SIDE reverses it. The choice affects the next join,
not the existing form. A gold line shows the candidate edge while holding.

Lift one face to detach it. Other panels stay where placed. START OVER restores
the editor-authored poses. Nearby occupied edges and distant edges are refused. Broad-interior collisions
are refused, with a narrow seam tolerance for finite panel thickness. The final panel can close several coincident
edges at once. Broad faces have real thin convex colliders, not centre-point
markers. The desktop pointer preserves these panels' explicit Q/E and R/F
orientation while carrying; ordinary objects keep their previous behaviour.

These are frozen kinematic construction pieces. Joins are geometric relations,
not physics hinges/glue or load-bearing force simulation. Closed shells and flat
patches are supported; no claim that an arbitrary assembly tiles3D space without
gaps. Each table searches its own panels. Isolated editor copies are independent
pieces; they do not join another table's collection.

Native and editor share rooms.json. Each panel, Controls and Support is a direct
editable part. Saved position/rotation reconstruct coincident edge links. Main
floor5 promotes the previously nested TriangleTable at its exact saved world
pose to one standalone artifact; its previous wrapper keeps the other panels and
caption. Existing main floor7 content remains, with the square table on the west
slab. Browser GLBs show an initial static arrangement; interaction runs in Godot.
No chapter/final.md changes.

Targeted validation and captures: `python tools/run_face_assembly.py`.
Publish staged layouts: `python tools/stage_face_assembly.py --publish` (requires
passing native receipt and unchanged target floors). Export actual native models:
`python tools/export_void_floors.py 5,7 <absolute-output-folder>`.
The rendered probe uses production desktop carry/drop and XRTools pickup with
supplied controller poses. It does not stand for a physical-headset playtest.

## Near-edge edition (26 October)

Stock is stacked along the front of the table; the control buttons are on the near rail. Replacement stock stays below 1.25m. The saved square-table face and control overrides were reset to these new positions; the table itself and other floor artifacts retain their saved poses. Each member remains separately editable.

Void now uses a two-metre, unobstructed empty-hand pull. Grip in VR or RMB on desktop attracts a pickable with a brief trail of pink sparks. Release grip / press RMB again to cancel or drop. This reuses XRTools linear grab interpolation, not simulated gravitational force. Desktop Q/E and R/F rotate a face through the actual grab driver. Museum rigs outside the Void retain their existing pickup settings.

Updated tests: `python tools/run_face_assembly.py --reach` and `python tools/test_force_pull.py`; receipts and native captures in `ada_run/face-reach/`. Diamond construction verifies eight faces, twelve joined edges and six unique vertices. The cube verifies six faces and twelve joined edges. Synthetic XR and automated mouse checks do not replace a physical-headset comfort assessment.
