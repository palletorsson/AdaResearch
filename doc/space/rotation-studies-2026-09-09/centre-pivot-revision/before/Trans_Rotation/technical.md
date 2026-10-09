# Two rotation studies

The active map instantiates `rotation_wall_crossings` and `rotation_array_compare` in a fixed 25 by 44 grid. Both scenes build visible meshes and matching physical boxes. They turn their own scene nodes; neither changes GridMultiMesh transforms.

## Panel, axis and pivot

`commons/artifacts/rotation_studies/wall_crossings.gd` creates three station parents. A pivot node supplies the axis location. The panel's position under that pivot supplies its offset from the hinge.

| Station | Initial mount | Axis and signed turn | Route at ninety degrees |
| --- | --- | --- | --- |
| Y | Flat, centre pivot | +y, +90 degrees | Along z |
| X | Upright, bottom hinge at near bank | +x, +90 degrees | Along z |
| Z | Upright, bottom hinge on the negative-x bank | +z, -90 degrees | Along x |

All panels measure 3.6 by 1.2 by 0.2 metres. Their long dimension occupies a different initial coordinate direction. Banks leave a 3.4 metre gap; the horizontal panel overlaps each bank by 0.1 metre. Panel tops and bank tops meet at the ground deck at ninety degrees.

The actual assignment is:

```gdscript
station.pivot.basis = Basis(station.axis,deg_to_rad(angle*float(station.sign)))
```

The basis sets an absolute angle relative to the station rather than accumulating an extra turn each frame. The axes are unit vectors. The collision body and mesh share the same parent pivot. The experiment changes mounting as well as axis, so its three outcomes cannot isolate an axis-only effect.

## Each cube or the array

`commons/artifacts/rotation_studies/array_compare.gd` builds two identical rows. Each has five blocks, 1.04 metres wide, spaced 1.02 metres between centres. Their combined length is 5.12 metres; their front-to-back bank gap is 4.9 metres. The slight overlap prevents seams between blocks.

```gdscript
var turn := Basis(Vector3.UP,deg_to_rad(angle))
for cube: Node3D in bays[0].cubes:
    cube.basis = turn
bays[1].group.basis = turn
```

In EACH CUBE, the cubes' local origins retain their positions under an unturned parent, so their world centres stay fixed. In WHOLE ARRAY, the cubes retain their local positions but inherit their parent's turn. Four centres orbit the shared origin; the middle centre stays. Only that whole row bridges the gap at ninety degrees. Top numbers and yellow edges expose the cubes' orientation even when a square outline repeats.

## Timing and verification

`parts.gd` supplies a sixteen-second cycle: hold at zero for four seconds, turn over three, hold at ninety for six, return over three. The two studies run automatically. The visitor crosses during the hold; no visitor-operated pause control is currently implemented.

`commons/testing/probe_rotation_studies.gd` builds the real grid and uses a CharacterBody3D capsule (radius 0.22 m, height 1.6 m) walking at 2 m/s. It tests all three wall routes and both array routes at zero and ninety degrees, verifies centre positions, placement and unchanged grid instance transforms. The current run reports 25 checks with zero failures in `ada_run/rotation_studies_checks.json`.

The probe fixes the study at each tested endpoint. It verifies geometry and collision there, not a complete human crossing during an animated turn. The museum capture verifies installation visually; timing, signage and comfort still need a VR walk.
