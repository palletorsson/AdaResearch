"""Print and freshly reconstruct the closing QFEP soft-body lesson."""
import argparse
import hashlib
import json
from build_qfep_introduction import ROOT, STUDY, CARRIED, extract, code

OUT = ROOT/'doc/book/iterations/2026-10-12-qfep-a-body-keeps-moving'
HALL = ROOT/'commons/maps/QFEP_Synthesis'
NEW = ['morphology_map.gd','synthesis_study.gd','morphology_checks.gd']

def tutorial():
    return '''# A body keeps moving

**Learning elements**

- Mapping two controls to requested mechanical properties
- Live pressure and damping; the limits of stiffness and drag controls
- A pressure baseline and a timed modulation
- Changing coefficients without resetting a simulated body
- Separating a setting, an observation and an interpretation

We are in Endless Museum's QFEP Synthesis. Find the specimen in its jar and use its own controls. Choose PAIR B. Watch **pressure base** and **pressure now**, then press PULSE / STEADY. The pressure becomes steady. Does the body immediately stop? The distinction is our last experiment in this laboratory.

Sandbox separated a value offered by a hand from the value received by an object. Here the route is direct and local: two values reach one deformable body. Keep the PointBody sphere as the hand control. Return to the SphereMesh we have made since Primitives, but give this receiver to `SoftBody3D` so its constituent positions can move. The control sphere stays a pickable rigid body; it does not secretly become the specimen. We retain both objects throughout the experiment.

## Carry the working bench

Work in `res://doc/book/studies/qfep-lineage/` inside the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged. Their full sources remain in [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Bench initializes our labels, sphere and five buttons. XRTools, the player and `res://commons/interactables/push_button.tscn` are supplied by the museum.

Godot supplies the soft-body solver; this project selects Jolt. We write the mapping that reaches it. Unlike the familiar rigid PointBody, a SoftBody3D uses its mesh for deformable contact. Do not give the specimen a rigid SphereShape3D. Its surrounding fixed boundaries do use ordinary BoxShape3D colliders.

The working copy uses a larger violet sphere in an outlined box, making the body and the limits of its movement readable on the bench. It copies the installed specimen's four requested coefficient mappings with base pressure 1.0, mass 0.5 and simulation precision 8. It does not copy the jar's dimensions, glass, fluid shader or colour changes. Those differences affect appearance and contact: matching coefficients is not a claim of identical trajectories. The outlined walls are solid even though their faces are not drawn.

## State the mapping

Create `morphology_map.gd`:

''' + code('morphology_map.gd') + '''
`values[0]` is lambda, from zero to one. `values[1]` is signed phi, from minus one to one. We continue the last halls' signed range rather than silently substituting Introduction's unsigned control.

Lambda requests **two properties together**. `lerpf(0.9, 0.1, l)` lowers requested stiffness as lambda increases. The baseline pressure peaks at lambda 0.5: it is 1.0 at either end and 1.5 in the middle. This triangular peak is an authored rule. It is not measured entropy or a discovered physical transition.

Phi also requests two properties together. The expression `(phi + 1) / 2` maps its signed range to the zero-to-one interpolation range. Requested damping changes from 0.2 to 0.001; requested drag changes from 0.3 to zero. But requests are not enough: the current engine ignores drag, and the stiffness readback can change without updating the running body's constraints. We keep those requests visible so the mismatch can be inspected. In this build, pressure and damping are the live mechanical controls.

**Check the engine as well as the script.** On Godot 4.6-stable with Jolt, our tests found drag readback fixed at zero. Matching bodies with different runtime stiffness settings followed the same motion; bodies built with different stiffnesses responded differently. The [Godot 4.6 source](https://github.com/godotengine/godot/blob/4.6-stable/modules/jolt_physics/objects/jolt_soft_body_3d.cpp) confirms the missing drag implementation and that stiffness is used when constraints are built. This is a version-specific limit. Our bench sets stiffness before entering the tree and retains that body; it labels both the request and its built value. It does not secretly rebuild the mesh to make a slider appear effective.

Bring back Wavefunctions: a sine multiplies the baseline, rather than replacing it. At lambda 0.5, speed is 1.25 radians per second and amplitude is 0.06. Pressure therefore ranges from 1.41 to 1.59. Pulsing operates only inside the open interval 0.3 < lambda < 0.7. At the endpoints, even an enabled pulse produces steady pressure. `active()` is what the readout reports.

`toggle` resets the modulation's phase clock, not the physical body. `apply_to` requests four properties on the specific receiver passed to it. Two affect the running mechanics here; drag is unused, and stiffness is retained for a future constraint construction. It neither makes a replacement mesh nor sets any vertex back to a starting position. KEEP copies the settings and the modulation clock for this run. It does not save vertex positions, velocities or a restartable physics checkpoint.

## Let those values reach a real body

Create `synthesis_study.gd`:

''' + code('synthesis_study.gd') + '''
The familiar sphere recipe now belongs to SoftBody3D. Rings and segments supply the surface the solver can deform. The six `boundary` calls make a fixed box with an inside floor at height 1.0; the frame shows where its faces stand. The museum bench's tabletop is a visual mesh, so we explicitly construct the floor collider instead of assuming a visible surface will support the specimen.

The collision mask is deliberate: the specimen sees layer 1, which includes its box and museum architecture. The carried control sphere lives on layer 3 and does not shove the specimen accidentally while editing a value. NUDGE gives the body a small impulse in the bench's local direction, converted to world space. The values are a repeatable input, but the resulting motion depends on the body's current state and contacts.

Lift the same PointBody to edit lambda or phi. `to_local` keeps the height control meaningful when the bench is translated or rotated in the museum. Release before selecting a term or pressing an action. Only the selected value changes. The model sends its properties straight to this body; it broadcasts nothing to the original specimen, ceiling or term spheres.

The new `_physics_process` first calls the inherited method so the released PointBody still returns to its rail. Then it advances the pressure clock and applies the mapping once per physics update. `_process` handles the hand and refreshes the plate. Drawing a label does not advance simulation time. The plate reads properties back from the actual SoftBody3D, alongside the computed pressure baseline. It distinguishes the requested stiffness from the value used when this body was built, and requested drag from the engine's zero. Even a nonzero readback is not sufficient evidence of a physical effect.

PULSE / STEADY changes the forcing. NUDGE adds an impulse. Neither operation resets the mesh, its current deformation or its motion. The engine keeps integrating after the pressure becomes steady. We also keep the material colour fixed: here a change in silhouette must come from moving geometry, not from the shader changing colour.

## Run inside the museum

Open the supplied `synthesis.tscn` and press F6. Its `synthesis_museum.gd` adapter mounts this bench in the real Synthesis hall alongside the existing works and player. The adapter and room are supplied infrastructure; all new lesson behavior is printed above. Desktop grab or the VR grip moves the control sphere; the five nearby buttons select and apply the actions.

1. At the opening pair, lambda 0.5 and phi 0, predict built stiffness 0.5, damping 0.1005 and pressure base 1.5. Requested drag is 0.15; the engine still reports zero. Watch the changing pressure.
2. Press PULSE / STEADY, then NUDGE. Track a part of the surface. Steady pressure and continuing motion can occur together. KEEP records this setting, not that moving surface's full state.
3. Hold lambda at 0.5; change phi to +1. Pressure base and stiffness should stay the same. Damping becomes 0.001. The drag request becomes zero, matching its already-unused engine value. Give another nudge. The starting physical state was not reset, so identical impulses are not identical experiments.
4. Change lambda while keeping phi fixed. Check the requested stiffness and pressure base. Built stiffness remains 0.5. Move beyond the pulsing band and notice that the effective mode reads STEADY even when pulsing remains enabled.

**Make a new comparison.** Without a preset, form lambda 0.2 / phi +0.8 and KEEP it. Predict requested stiffness 0.74, baseline 1.2, damping 0.0209 and requested drag 0.03. Then form lambda 0.8 / phi -0.8: requested stiffness 0.26, the same baseline 1.2, damping 0.1801 and requested drag 0.27. In both, built stiffness stays 0.5 and engine drag stays zero. Both pairs have steady pressure. Nudge each and describe what you see without pretending that equal pressure supplies equal histories. Which quantities are controlled, and which are still changing?

## Check the claims

Create `morphology_checks.gd`:

''' + code('morphology_checks.gd') + '''
Run `python tools/test_qfep_synthesis.py` from the repository root. The supplied harness reconstructs these three files from this tutorial and the three declared inherited files from their earlier chapters. It runs the printed assertions, operates the sphere under a transformed parent, checks the independent comparison, and tests real Jolt vertex movement with pulsing disabled. It also checks that toggling pressure does not immediately rewrite vertex positions or replace the body.

The arithmetic assertions establish what coefficients are requested. A separate engine comparison checks live stiffness edits against construction-time stiffness and verifies the ignored drag setting. The physics checks establish that an actual simulated mesh can keep moving under steady pressure. Neither test proves a physical model of life or queerness, predicts identical trajectories at different time steps, or establishes what a human learner understood. Headset reach and comfort still need a person in the room.

## What leaves this laboratory

We can now distinguish an input, its route, its mapping, the evolving body and a retained observation. Each has a different job. The QFEP expression does not calculate this specimen's motion; an authored mapping feeds an existing mechanics solver. Post-Crisis asks what our resulting descriptions preserve and what they leave out. Carry the habit of keeping a setting separate from the body it helped produce.

**Short instruction:** Continue PointBody + Bench. Reuse sphere geometry as one SoftBody3D receiver; explicit fixed boundaries. L requests stiffness + pressure baseline. Signed P requests damping + drag. On tested Jolt: pressure/damping live, stiffness built at creation, drag unused. Show request versus effective value. Physics clock modulates pressure only for .3<L<.7. STEADY is not pause/reset. Keep material fixed. NUDGE current body; KEEP settings only. Assert ranges, pulse extrema, same-body continuity, moving vertices under steady pressure, local hand control and independent comparison. No measured QFEP/life/queerness claim.
'''

def prepare(write=False):
    OUT.mkdir(parents=True,exist_ok=True)
    for name,hall in CARRIED.items():
        content=extract((ROOT/'commons/maps'/hall/'tutorial.md').read_text(encoding='utf8'),name)
        assert (STUDY/name).read_text(encoding='utf8')==content,name
    if write:
        before=OUT/'before';before.mkdir(exist_ok=True)
        for name in ['tutorial.md','final.md']:
            if not (before/name).exists():(before/name).write_bytes((HALL/name).read_bytes())
        (HALL/'tutorial.md').write_text(tutorial(),encoding='utf8')
        baseline=OUT/'preserved-sources.json'
        if not baseline.exists():
            paths=[HALL/'map_data.json',ROOT/'commons/maps/sequences/qfeplaboratory.json',
                ROOT/'commons/artifacts/queer_morphology_specimen/queer_morphology_specimen.gd']
            baseline.write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    manifest={'scope':'Fresh printed Synthesis lesson and three inherited files. Hashes use UTF-8 with LF newlines.','files':{}}
    for name in list(CARRIED)+NEW:
        source=ROOT/'commons/maps'/CARRIED[name]/'tutorial.md' if name in CARRIED else HALL/'tutorial.md'
        text=extract(source.read_text(encoding='utf8'),name)
        assert text==(STUDY/name).read_text(encoding='utf8'),name
        (learner/name).write_text(text,encoding='utf8')
        manifest['files'][name]={'source':source.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(text.encode()).hexdigest(),'carried':name in CARRIED}
    (OUT/'extraction.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    return learner

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-tutorial',action='store_true')
    print(prepare(parser.parse_args().write_tutorial))
