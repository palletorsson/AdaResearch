# Three new friction studies

Completed on main floor 46 / Kinetic Forces. This is new native content beyond the original 15 ZIP examples. All five existing floor-46 artifacts and all other floors were retained.

## What the player can do

- Let Go: adjust the angle/contact surface, release a cube and measure stick versus slide.
- Keep Going: compare actual stopping distances after identical 2.4 Ns impulses on two 2 kg cubes, with plywood versus rough grit.
- Almost Enough: adjust hanging mass/contact friction, then release a real suspended weight over shaft A.
- Pick up and place the cubes; reset releases an actual held body and restores the authored member positions. Three recent takes persist only while this encounter is loaded.

## Evidence

- 17 physical checks: actual low/high contact contrasts at negative height and a rotated assembly, native weight descent, reset and edited part preservation.
- 90 actual main-floor player checks: desktop mouse, synthetic XR trigger/grip, pickup/reset, route walking and measured contact/cable readings.
- 26 independently editable members; 212 actual exported meshes. Every member moves/rotates; copied witnesses pass the production save validator without saving test edits.
- Production revision-guarded layout save and desktop/VR mirror agree. Export refreshed floor 46 only, preserving other model floors.
- Native screenshots inspected separately from test assertions. Overview/detail inspection views hide neighbouring floors; player views use the actual game.

## Physical model and limits

Jolt integrates rigid bodies and contact friction. There are no success pose animations or output velocity nudges after release (Keep Going's one initial impulse is explicit). Planar guides keep cubes within each demonstration plane. Almost Enough uses a unilateral spring/damper cable: stiffness 400 N/m, damping 8 Ns/m, no compressive force while slack, ideal massless roller. It is not a native pulley joint or a simulation of rope material/inertia. The weight guide permits vertical movement and prevents lateral drift.

Let Go has a physical downhill catch; its reading stops if a hand-placed cube leaves the plank rather than projecting a later fall into a false slide distance. Reset uses static freeze mode so restoring a carried cube does not sweep it into another collision. Parameter-dependent rebuilds are deferred until after button signal dispatch and retain explicit editor member overrides.

Original physics warnings about solver bias and Compatibility-renderer headset blur remain; no artifact script/runtime errors were accepted. Synthetic XR is not physical-headset acceptance. Arbitrary editor rearrangements can break the calibrated contact/cable geometry. This is an additive installation, not a full curation of the five older exhibits. No chapter/final.md rewrites.

Gallery: http://localhost:3003/book-review/doc/book/iterations/2026-10-25-friction-studies/index.html
Editor: http://localhost:3003/lab-editor?mode=void&floor=46
