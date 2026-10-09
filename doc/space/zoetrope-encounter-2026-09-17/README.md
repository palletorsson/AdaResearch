# Walk up to the moving edge

17 September 2026. Revision prompted by the question: can the transformation be felt from where the visitor stands?

[Open the experiment](http://localhost:3003/research/possible-bodies/transformation-zoetrope.html).

## A carrier turns

The four `transformation_sampling` stations now have actual rotating pose carriers. Each platform top is 1.7 m above the artifact's floor. Its twelve stored poses stay fixed relative to the carrier; their world positions move. The disc has radius 1.10 m and turns once per six seconds. Poses are placed radially and oriented so each arrives facing the same way at the front viewing position.

The earlier large tables were replaced with narrow stationary supports. A visitor can approach the disc edge without a table blocking their feet. Small captions sit in cases on the supports. Equally drawn cube and tetrahedron edges make the passing geometry readable at eye height; the sphere has no added edge grid. The optional witness mark still distinguishes a particular material point.

Live and held-sample comparisons remain available behind the drums, hidden initially. In the desktop fixture, **Show / hide sampled comparisons** reveals them. Their sampling interval does not control the drum's rotation speed.

## One body turns on its own axis

The new `axial_sweep` artifact turns a cube or a flat triangular profile about Y at 18 degrees per second. Its platform is also 1.7 m high. The visitor can pause, change shape and reveal the outer boundary swept by the full turn.

- The centred cube has edge length 0.60 m. Its full rotational union has a cylindrical outer boundary with radius `sqrt(2) * 0.30` and height 0.60 m.
- The triangle has vertices `(0,-0.35,0)`, `(0.45,-0.35,0)` and `(0,0.35,0)`. Rotating this filled region produces a conical union with base radius 0.45 m and height 0.70 m.

The boundary begins hidden. It is a computed contour added for inspection, not a claim that the headset produces motion blur or that the newly outlined space has become solid. Optional history retains at most 24 observed edge poses; it is disabled initially.

The distinction is the encounter: the body keeps its instantaneous shape, while the places it occupies over a turn describe another form. Movement can claim more space than a single pose shows.

## Run and inspect

- Desktop scene: `commons/testing/transformation_sampling_lab.tscn`.
- **Walk up** enables WASD movement; hold the right mouse button to look around. The camera stands 1.7 m above the walking body's floor. Escape releases the mouse.
- The four operation buttons provide fixed eye-height views. **Axial body** focuses the companion; its toolbar controls change shape, playback and boundary visibility.
- Reusable artifacts: `commons/artifacts/transformation_sampling/transformation_sampling.tscn` and `commons/artifacts/axial_sweep/axial_sweep.tscn`. Both are registered in `commons/artifacts/registry/transforms.json`.
- Capture script: `commons/testing/shoot_zoetrope_encounter.gd`.

These are working research fixtures. This revision does not place them into the spine, change the existing `grand_zoetrope` elsewhere, or revise the book.

## Checks

`test-results.json`: **32/32 drum checks pass**. All 48 frame and mount transforms remain locally fixed while their world transforms move. Quarter-turn and full-return timings, actual play/pause/reset buttons and exact platform heights pass. A real 0.44 m wide, 1.75 m tall CharacterBody capsule reaches each rim, both at the origin and beneath a translated parent rotated 180 degrees. This verifies the approach on the supplied flat floor, not the route through an installed hall.

`axial-test-results.json`: **38/38 axial checks pass**. Geometry remains unchanged during rotation; quarter and full-turn timings, controls and contour dimensions pass. Independent sampling of 76,560 surface positions verifies containment by the specified swept boundaries. The pedestal is solid; the rotating shape and boundary have no collider. History remains capped. Both suites report stable production hashes and no script errors.

Reusable probes: `commons/testing/probe_zoetrope_encounter.gd` and `commons/testing/probe_axial_sweep.gd`. Runtime logs retain unrelated project startup warnings. Images were captured in Godot and reviewed after reducing captions, hiding the larger comparisons and adding equal edge outlines.

The updated browser page was inspected at its starting and closest permitted views. Orbit, approach, pose arrangement, witness mark, axial shape, boundary, pause/play and reset work. The original sampling comparisons expand and render, and their paused sampling rule still holds. `browser-state-checks.json` records **34/34 state and geometry checks**; rerun with `node doc/space/zoetrope-encounter-2026-09-17/check-browser-state.cjs`. These mocked-DOM checks complement the actual browser review. The published local copy matches the source.

Headset viewing, perceptual fusion of successive poses, tracked-hand reach and comfort remain to be tested. Continuous rendering of a rotating carrier alone does not establish a convincing zoetrope illusion.

## What the engine contributes

We retain Godot's metre scale, Y-up coordinates, finite frames, discrete geometry and camera projection. The first experiment separates parent motion from child pose. The second separates instantaneous geometry from accumulated occupancy. These are the seams being made visible; neither changes the world's collision law automatically.

![The rotating carrier from approach height](approach-turning.png)

![The triangle and its computed swept boundary](axial-triangle.png)
