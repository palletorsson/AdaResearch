# Assemble a body — implementation and encounter

The primary artifact is `MolecularDesigner`. Its [scene](../../../algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn) and [implementation](../../../algorithms/computationalbiology/molecular_framework/Part.gd) supply the behaviour described here.

The scene starts with forty reusable part instances. This hall configures eight seconds of floating, eighteen seconds of assembly, scale 2 and body_study=true. An amber ring stays attached to the first instance as its catalogue type changes. The source scene's default phases remain ten seconds elsewhere. _assemble() reads node specifications, reapplies each part's catalogue mesh and calls set_target(target_pos); the call does not supply a target basis. Bonds are read from the assembly data. Part._dock_to_target() integrates a damped spring in _process(), while idle translation accumulates a sine-derived offset weighted by elapsed time. Inventory positions are local to the exhibit; target positions use to_global(), so museum position, rotation and scale apply to the assembly. Changing assembly releases surplus instances from their previous targets. In body_study mode the controller moves unused instances into two visible side racks; their own floating process resumes on release. This display arrangement is authored too. Keyboard shortcuts exist in the script, but the book does not rely on them in VR. No in-room catalogue editor or chemistry solver is implemented by this primary.

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

## Limits and next test

Expose one editable target with a visible link to its source assembly. Compare the same docking motion at two fixed update rates before changing damping. Let a visitor alter one relation and keep the resulting body beside the original.

The private museum probe checks instantiated behaviour and selected walking routes. See the [current evidence](../../../doc/book/iterations/2026-09-20-last-halls-review/SUMMARY.md). Headset readability, comfort, Quest performance and learner understanding remain unverified. The assembly parts are visual objects without supporting collision: walking among them does not establish a chair you can sit on or a body you can wear.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
