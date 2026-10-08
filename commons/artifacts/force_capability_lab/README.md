# Forces — a capability court

Built inside the last Forces hall, `Vectors_Act5_ForceAsPlace`, after its existing field encounter. The thirteen-hall order stays intact. This is the first playable combined trial from the thirty-idea proposal, not implementation of all thirty.

Run `res://commons/scenes/force_capability_museum.tscn` (F6) to open the real Endless Museum at this hall. Walk past the field into the court. In the normal museum route, it is the final Forces hall before Form Finding. Restart/re-enter the hall to load the new map and registry.

## Controls and learning

| Encounter | Action | What changes |
| --- | --- | --- |
| Two black points | VR grip each; point where you want to fly; hold triggers. Desktop RMB carry, LMB held action, RMB drop. | Each point adds 11 m/s² along the controller/view pointing direction. Both add together. Release removes thrust; gravity and momentum remain. One point also gives a slow lift. |
| Cake mortar | Press LOWER/HIGHER in 5° steps, FIRE. | Fixed 8 m/s launch speed, 25–75° elevation. Real rigid torus rings fly and collide. The thin arc assumes gravity alone; collisions and damping can change the result. |
| Launch / landing | Walk onto the cyan pad. | Initial velocity 6 m/s up and 4 m/s forward. Gravity continues. The earlier transport cube moves across the landing path. |
| Falling pole | Press RELEASE POLE. | A real HingeJoint3D allows one rotational axis. Gravity drops the pole onto the receiver; it becomes a low bridge. |
| Spring points | Press GIVE ONE A PUSH, or pull a point and release. | Two constrained sphere bodies: F = −9x − 0.16v along the rail. Contact transfers motion. The rail locks Y/Z; the coils draw the actual extension. |
| Drag lane | Compare DRAG 0 / 3 with PUSH CUBES, or carry objects onto the slope. | Linear drag F = −cv acts on loose bodies inside the marked lane; contacts and floor friction remain. An intentional contrast with carrying/dragging an object. |
| Arrival | Bring the third black point from the entrance to the final plinth. | Its real Area3D arrival changes the court readout. Other displaced objects stay where the trial leaves them. |

Eight mortar rings per trial; a 0.3-second muzzle interval prevents overlapping births. Further shots wait for explicit reset. Misses remain pickable, with compound collision around the hole. Reset refuses while an object is held. Lost bodies below −12 m (or loose bodies beyond 65 m) are recovered explicitly; ordinary aftermath is retained only while this streamed hall remains loaded. Cross-hall saving is not added.

The court owns player velocity through the existing `ada_museum_carry` hook and XR `FieldCarryAdapter`. It applies gravity once and retains post-collision velocity. Flight has a declared 14 m/s speed cap. Ground walking works again on landing; leaving the court returns control to existing museum locomotion. The earlier force field keeps its separate model, replacing gravity locally. Main player/controller scripts are unchanged.

## Lineage

- `ignorance_gallery/point_body.gd`: the existing sphere, collision boundary and XR pickable, extended with thrust or physical release.
- `commons/interactables/grab_cube.gd`: the existing cube, five instances with the same grayscale body.
- `commons/scenes/mapobjects/transport_cube.tscn`: actual earlier moving platform and rider support.
- `force_pad/force_pad.gd`: existing launch pad; a small subclass hands the launch to the court's movement owner.
- Mortar and hinge precedents: `mortar_vector_siege` and `algorithms/joint/09_drawbridge_hinge`. The new compact court versions use their principles without importing their full arenas.

## Verify

```powershell
python tools/run_encounter_probe.py Vectors_Act5_ForceAsPlace --sequence forces --render --probe tools/probes/force_capability_lab.gd
```

The probe runs production artifacts in an isolated copy of the real museum. It supplies desktop grab/action/drop and an XR rig with two actual pickup functions, measures motion and contacts, checks reset/launch/drag behavior, and captures the hall. It does not establish tracked-controller ergonomics, Quest performance or headset comfort.

Reflection: to drag is to pull something along; physical drag resists motion. Drag performance offers another relation between a body and the forms available to it. These are associations, not interchangeable definitions. The room asks what a body can carry, what resists it, and what becomes possible when a familiar form gains another use.

## Body visor and hall teleport controls

The court now has a visor dock beside the two thrust points. Press WEAR / REMOVE
with the existing pointer or hand-poke interaction; on desktop F8 toggles the same
display while inside the court. The visor sits 1.4 m in front of the eye, below
the centre of the view. Its look marker stays with the head; its arrows represent
world directions. Numbers retain world XYZ coordinates when the visitor turns.

Velocity is the actual CharacterBody3D velocity in m/s. Thrust F/m is the exact
acceleration used by the court movement provider; gravity is 9.8 m/s² downward.
These are inputs, not a measurement of total contact force or net acceleration.
The player model does not define a physical mass here, so no Newton value is
invented. Arrow lengths saturate for display; the numbers give actual magnitude.
The pad sets an initial velocity, with a separate one-second notice.

The display hides outside the court and during hall transfers. Unloading the
court frees the camera attachment. It never changes velocity or takes ownership
of locomotion. Visual comfort and legibility still require a physical headset.

Every curated Forces entrance lectern now has PREVIOUS / NEXT teleport buttons.
They call the existing museum portal coordinator and use its supported arrival,
loading cell, velocity reset and XR origin handling. They do not invoke a separate
map loader. PREVIOUS reports when there is no earlier hall on this visit. NEXT
continues along the museum route, including beyond Forces at its end.

Checks: tools/probes/forces_body_visor.gd and
tools/probes/forces_teleport_buttons.gd. Captures and evidence:
doc/book/iterations/2026-10-07-forces-teleport-and-body/.
