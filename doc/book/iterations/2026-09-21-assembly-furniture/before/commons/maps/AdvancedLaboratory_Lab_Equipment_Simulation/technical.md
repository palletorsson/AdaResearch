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

Grip and move a joint in VR. On desktop, point at a joint, right-click to carry it, and right-click again to release it; the standard mouse wheel changes carrying distance. Both paths retain the new position. Connections redraw between endpoints. They do not transmit forces or preserve limb lengths. Moving a gold joint alone does not alter adjacency. The independent catalogue cycle cannot overwrite this pose. Spare carriers in the automatic study now gather along the left wall, leaving the comparison aisle clear.

```gdscript
targets[index] = to_local(handle.global_position)
```

Joint centres are bounded to local X/Z ±1.9 metres and Y 0.12–2.35 metres. A thin square floor inlay marks the horizontal bounds. There is no anatomical validation. The bounds concern joint centres; the visible sphere can extend beyond them. Joints have pickup collision on layer 3, while connections are visual. Neither body is a wearable avatar or a load-bearing chair.

A changed release now keeps one latest pose through [AssemblyPoseRecord.gd](../../../algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd), normally at `user://ada_research/assembly_pose.json`. Starting and released positions, joint identities, radii, original and current connections, and the source hash travel together. Schema 2 retains both graphs; existing schema-1 pose records remain readable with their original graph. A changed connection counts as a released edit even when no point moves. Another held joint is saved at its previous released position. Re-entering this workshop restores a valid matching pose and continues its edit count. The final hall reconstructs both versions at standing scale. Failed disk writes retain an explicitly labelled session-only record. `export_pose()` reports released coordinates; it is not a hand trajectory. `reset_pose()` remains an authoring/probe API, restores both positions and connections, refuses to reset during a held joint or collar edit, and does not save automatically; no reset panel is added. See the [persistence and final-hall checks](../../../doc/book/iterations/2026-09-21-synthesis-return/SUMMARY.md).

## Limits and next test

The gold joints change geometry. Two turquoise collars now open both ends of the original left forearm connection: pick up either collar, carry it to a different gold joint and release within 0.28 m to change its neighbour. A green ring previews a valid target. Both ends of this one connection are editable; the other eleven connections and all thirteen joints remain. Taking the hand end to the head isolates the hand; taking the elbow end to that hand reconnects all thirteen joints without restoring their original adjacency. When both collars are held, each release commits only its own endpoint. The second release is validated against the first released change; an attempted self-connection or duplicate is rejected. Self-connections, duplicates and empty-space drops return to the previous attachment. They create no saved edit. The finite workspace applies to the held collar too. Both desktop carry and XRTools pickup use the same begin/release actions. A new joint remains a possible later operation. The spring damping in the automatic study is still applied per frame; compare fixed update rates before changing that separate behaviour.

The private museum probe checks instantiated behaviour and selected walking routes. See the [two-end encounter evidence](../../../doc/book/iterations/2026-09-21-assembly-belonging/SUMMARY.md). Headset readability, comfort, Quest performance and learner understanding remain unverified. The automatic catalogue and gold workshop are visual objects without supporting collision: walking among them does not establish a chair you can sit on or a body you can wear.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.

[Reconnection encounter and latest checks](../../../doc/book/iterations/2026-09-21-assembly-reconnection/index.html): same points and same edge count can have different connectivity. The record retains both graphs, so the final gallery can show the original and altered connections honestly.

## A body whose connections carry force

This hall also opts into `body_ragdoll=true`. `AssemblyRagdoll.gd` makes a separate, unsaved physics comparison from the existing VRBody points. The same thirteen names remain available as coral grab rings. Ten rigid parts supply a torso, head and two segments per arm and leg; nine PinJoint3D constraints join them. The hip attachments are separated by 0.24 m so the hanging legs remain distinct. These are freely rotating pin joints, without anatomical angle limits. Non-adjacent parts collide with one another and the museum floor; directly joined pairs exclude mutual collision.

The study stands at map coordinates (3.5, 0, 9.2), facing the central lane, with a 2.8 m square, 0.024 m high mat and a hanging support. Its global basis has unit scale despite the catalogue's two-times placement. The head is initially supported. Taking any ring releases that support. The target follows desktop carry or the XRTools grab driver, while a capped damped spring applies force at the corresponding attachment point of the unfrozen physical limb. A thin coral tether makes the gap between held target and physical attachment visible. This separates hand tracking from rigid-body motion; grabbing does not teleport the limb or impose a pose. Two controllers can pull different limbs at once. A finite target region and 90 N force cap bound the interaction.

Releasing a ring stops its pulling force, leaving gravity, inertia and constraints to act. The HANG AGAIN button on the stand resets velocities and authored part transforms, then recreates the head support. It refuses while a limb is held. Physics transforms are explicitly synchronized before constructing joints and after resetting, avoiding stale attachment frames. No external pose or visitor save is written: the existing gold body and its Synthesis return remain independent.

[Godot PinJoint3D documentation](https://docs.godotengine.org/en/4.6/classes/class_pinjoint3d.html) describes the free joint; [RigidBody3D documentation](https://docs.godotengine.org/en/4.6/classes/class_rigidbody3d.html) describes force application. This is a stylized physics puppet, not a biomechanics model or an avatar worn by the player. Headset reach, comfort, haptic feel and Quest performance still require on-device testing. [Actual museum captures and controlled checks](../../../doc/book/iterations/2026-09-21-assembly-ragdoll/index.html).
