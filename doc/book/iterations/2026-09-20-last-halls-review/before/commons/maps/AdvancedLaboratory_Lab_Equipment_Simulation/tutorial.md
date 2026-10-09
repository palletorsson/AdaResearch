# Where was this body's destination decided?

We carry primitives, arrays, transformations and restoring forces into a catalogue of possible assemblies.

<!-- @MolecularDesigner -->

Choose a visible part during the floating phase. Follow it as an assembly forms. Watch another floating phase and a different assembly; notice both its destination and any change of shape or colour.

The controller reuses part instances, but can replace their mesh, type and colour when assigning a new assembly. The same instance need not keep the same visual identity. Target positions are authored before the parts move.

The source makes the operation inspectable:

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

[Implementation](../../../algorithms/computationalbiology/molecular_framework/Part.gd). This is an excerpt from the artifact, not a standalone program.

The name MolecularDesigner suggests chemistry, but the current controller arranges catalogue parts and draws declared bonds. It does not establish chemical validity. Its constructive question is still substantial: can a new body be made by changing positions and relations, or does it demand a part the inventory cannot supply? Reusing an instance while replacing its visible form offers another question about identity. Neither physical emergence nor freedom is established by a persuasive animation.

<!-- @ -->

A useful catalogue is a choice with consequences. The last hall asks us to keep one consequence available for revision.

## Next experiment — not yet a visitor control

Expose one editable target with a visible link to its source assembly. Compare the same docking motion at two fixed update rates before changing damping. Let a visitor alter one relation and keep the resulting body beside the original.
