# Point_Animatedcube interface pass — 22 September 2026

Published review:
http://localhost:3003/book-review/doc/book/iterations/2026-09-22-interface-spine-cube-review/index.html

## Outcome

Continued the spine interface pass after Primitives_Polythedra and the Room
Memory audio detour. Both existing discovery builders retain their independent
experiments. Each now has a supported, inclined console in front of it, with
four physical buttons on a backplate and flat 2D text in 3D.

- Readout: 76 × 32 cm, previously 110 × 96 cm. Shared data surface redraws only
  when its text changes. Static control captions use baked textures.
- Buttons: 19 cm spacing, 0.825 m above the floor; horizontal distance from the
  supplied operating pose is 0.376–0.462 m. Native button geometry is unscaled.
- Two 55 cm plinths replace the previous default one-metre plinths. Cube size
  stays one metre; corner centres are 0.608–1.608 m above the floor.
- Visible grip radius grows to 2.8 cm inside the unchanged grab collider.
- Console height follows the museum floor independently of specimen seating;
  its top-level transform excludes it from the specimen's measured bounds.
- Pause becomes a lit RESUME. Diagonals become available after assembly.
  Replay and restore dim while a corner is held; existing builder guards still
  enforce release first. Replay retains deformation; restore resets positions.
- Map tokens and the two corresponding museum-plan entries agree. No artifacts
  or curatorial roles were removed. Book, intent, technical and critical text
  only change “side” instrument/panel to “front”; field notes record the staging.

## Verification

**152 passing desktop checks:**

- `after/cube/report.json`: 112 actual-hall checks, including two real console
  approaches by the museum walker, capsule fit, floor support, control rays,
  all 16 corner heights and separate near-grab poses, native XRTools grab and
  pointer events, held-state guards, comparison independence, text fit, and
  the readout's sightline below the intact cube from a 1.65 m operating eye.
- `after/functional-checks.json`: 40 original experiment regression checks,
  covering assembly, paused reveal, local coordinates under a rotated parent,
  mesh and diagonal updates, scaffold/strata comparisons, replay, restore,
  unconfigured instances and both authored map placements.
- Baseline: 46 checks, with four failures for replay/pause height (1.435 m).
  The expanded final probe adds grip and interaction checks beyond the baseline.

The native grab tests wait for the builder's deferred mesh update; calling its
process method does not synchronously update vertex data. The original
`probe_cube_primary.gd` now measures 2D label bounds and accepts `--report=` so
this pass writes privately rather than overwriting another review's evidence.

Only one Godot instance was run at a time, with XR disabled, dummy audio and
hidden windows. Hall captures use the production museum builder with private
control, plan, bake and output paths. They do not change the user's resume pose.
Baseline and final hall logs both contain the existing unrecognised
`uid://rwex60pqapc`; the final hall and experiment runs contain no script errors.

## Reproduce

From the repository root, with no other Godot process running:

```powershell
python doc/reports/interfaces-2026-09-22/spine-cube/run.py cube after
python doc/reports/interfaces-2026-09-22/spine-cube/publish.py
```

The functional probe is
`res://commons/testing/probe_cube_primary.gd`; run headless with XR off and
`--report=res://doc/reports/interfaces-2026-09-22/spine-cube/after/functional-checks.json`.
The publisher requires both functional and actual-hall results to pass.

## Remaining scope / next work

Headset comfort, seated reach, controller tracking and Quest performance remain
untested. Separate valid corner standing poses do not establish a complete
walkthrough route around every specimen. The console position is not a promise
that every corner can be reached without moving around the cube.

**Next active spine hall: Primitives_Ignorance.** Continue the interface pass
there, preserving the uneven five-segment capsule and its book argument about
what polygons cannot hold. The broader manuscript revision is not this task.

The working tree contains extensive earlier and concurrent work. Nothing was
committed or reverted in this pass.
