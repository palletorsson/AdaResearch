# Assemble a body — implementation and encounter

The primary artifact is `MolecularDesigner`. Its [scene](../../../algorithms/computationalbiology/molecular_framework/MolecularDesigner.tscn) and [implementation](../../../algorithms/computationalbiology/molecular_framework/Part.gd) supply the behaviour described here.

MolecularDesigner.tscn enables automatic ten-second floating and assembling phases and starts with forty part instances. _assemble() reads node specifications, reapplies each part's catalogue mesh and calls set_target(target_pos); the call does not supply a target basis. Bonds are read from the assembly data. Part._dock_to_target() integrates a damped spring in _process(), while idle translation accumulates a sine-derived offset each frame. Keyboard shortcuts exist in the script, but the book does not rely on them in VR. No in-room catalogue editor or chemistry solver is implemented by this primary.

## Operation to read after the encounter

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

## What to compare

Choose a visible part during the floating phase. Follow it as an assembly forms. Watch another floating phase and a different assembly; notice both its destination and any change of shape or colour.

The controller reuses part instances, but can replace their mesh, type and colour when assigning a new assembly. The same instance need not keep the same visual identity. Target positions are authored before the parts move.

## Limits and next test

Expose one editable target with a visible link to its source assembly. Compare the same docking motion at two fixed update rates before changing damping. Let a visitor alter one relation and keep the resulting body beside the original.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
