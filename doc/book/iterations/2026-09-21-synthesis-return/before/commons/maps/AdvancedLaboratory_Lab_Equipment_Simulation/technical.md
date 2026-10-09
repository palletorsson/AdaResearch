# Assemble a body — implementation and encounter

The primary artifact is `MolecularDesigner`. Its [scene](../../../algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn) and [implementation](../../../algorithms/computationalbiology/molecular_framework/Part.gd) supply the behaviour described here.

The scene starts with forty reusable part instances. This hall configures eight seconds of floating, eighteen seconds of assembly, scale 2 and body_study=true. An amber ring stays attached to the first instance as its catalogue type changes. The source scene's default phases remain ten seconds elsewhere. _assemble() reads node specifications, reapplies each part's catalogue mesh and calls set_target(target_pos); the call does not supply a target basis. Bonds are read from the assembly data. Part._dock_to_target() integrates a damped spring in _process(), while idle translation accumulates a sine-derived offset weighted by elapsed time. Inventory positions are local to the exhibit; target positions use to_global(), so museum position, rotation and scale apply to the assembly. Changing assembly releases surplus instances from their previous targets. In body_study mode the controller moves unused instances into two visible side racks; their own floating process resumes on release. This display arrangement is authored too. Keyboard shortcuts exist in the script, but the book does not rely on them in VR. The automatic display remains a catalogue showcase, not a chemistry solver. This hall also enables `body_workshop=true`; other placements retain the earlier default.

## Operation to read after the encounter

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

## What to compare

Walk around the floating inventory and follow the part carrying the amber ring. Keep that instance in view as the body gives way to a chair or another assembly. Its position and visible form can change while the ring remains with it.

The controller reuses part instances, but can replace their mesh, type and colour when assigning a new assembly. The same instance need not keep the same visual identity. Target positions are authored before the parts move.

## A body whose positions the visitor can change

[AssemblyBodyStudy.gd](../../../algorithms/computationalbiology/molecular_framework/AssemblyBodyStudy.gd) reads the same `VRBody` assembly: thirteen named joints and twelve declared connections. It builds a separate body at 1.12 times the assembly coordinates, with real XRTools pickable joints. The top-level study has a unit global basis, avoiding scaled rigid bodies beneath the two-times-scale automatic display. Its position is derived from the configured exhibit transform. The automatic display is placed at cell (3,5); its workshop stands 5.2 metres to the right and 1.2 metres along its local Z direction.

Grip and move a joint in VR. On desktop, point at a joint, right-click to carry it, and right-click again to release it; the standard mouse wheel changes carrying distance. Both paths retain the new position. Connections redraw between endpoints. They do not transmit forces, preserve limb lengths or alter adjacency. The independent catalogue cycle cannot overwrite this pose. Spare carriers in the automatic study now gather along the left wall, leaving the comparison aisle clear.

```gdscript
targets[index] = to_local(handle.global_position)
```

Joint centres are bounded to local X/Z ±1.9 metres and Y 0.12–2.35 metres. A thin square floor inlay marks the horizontal bounds. There is no anatomical validation. The bounds concern joint centres; the visible sphere can extend beyond them. Joints have pickup collision on layer 3, while connections are visual. Neither body is a wearable avatar or a load-bearing chair.

The pose lasts for the loaded hall visit. `export_pose()` supplies named coordinates for probes and future research logging; it does not automatically save to disk. `reset_pose()` is an authoring/probe API and refuses to reset during a held edit; no reset panel is added.

## Limits and next test

The current intervention changes geometry while keeping the original graph. A useful next extension would let the visitor add a joint or revise a connection, then retain both versions for comparison. The spring damping in the automatic study is still applied per frame; compare fixed update rates before changing that separate behaviour.

The private museum probe checks instantiated behaviour and selected walking routes. See the [current evidence](../../../doc/book/iterations/2026-09-21-assembly-immersion/SUMMARY.md). Headset readability, comfort, Quest performance and learner understanding remain unverified. The assembly parts are visual objects without supporting collision: walking among them does not establish a chair you can sit on or a body you can wear.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
