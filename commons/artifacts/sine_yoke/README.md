# Hand wheel and visible sine yoke

The player's hand turns the exposed wheel. An ivory pin moves around its centre.
The pin can slide horizontally inside an open steel slot; the slot and its off-white outlined
cube share the pin's vertical coordinate. The cube's 76 cm stroke comes from a
38 cm crank radius. There is no automatic rotation, coasting or return on release.

Desktop: hold and drag around the wheel rim or pink crank. XR: grip the crank
and move the hand around the wheel. Both use the existing angular control,
unwrapped hinge driver and XRTools pickable handle. Direction and speed come from
the hand. A sine in time requires constant angular speed.

This is an ideal **kinematic constraint**, not a force/contact-based mechanical
solver. Its cube height is resolved from the actual pin transform in the mechanism
frame. No separate clock animates the cube, and no effort, inertia, load or friction
is claimed. The pin, slot and guide geometry make the allowed directions visible.

## Authoring

Main Wavefunctions opening, floor59, `hand-sine-yoke`, at (-2.3, 0, 5.9).
Existing artifacts and comparison benches remain. Desktop and VR use the same
saved `commons/void/rooms.json`. The shared prefab catalogue and graph expose
`sine_yoke`; the workbench uses the same two native exported mesh groups.

- `Support`: black-steel feet, bearing post and supported vertical guides.
- `Mechanism`: wheel, crank, pin, slotted yoke and attached cube. Keep these
  coupled parts together when arranging the working unit.

Each group can be moved, turned and copied in the lab editor. An isolated copy
removes the other group's geometry and colliders. Moving the mechanism relative
to its fixed support is an authoring operation: the author must align the guides
and bearing again. Move the whole artifact to preserve that alignment.
`initial_angle` is the starting wheel angle in degrees. No chapter text changed.

The web models are static native geometry snapshots; interaction runs in Godot.
Evidence: `ada_run/sine-yoke/`. Supplied XR controller poses do not constitute a
physical-headset test.

The finish is shared with the scale zoetrope through `machine_finish.gd`: black
steel structure, pink hand grip and an ivory subject with dark geometric outlines.
The pin, slot and original hand-driven displacement are unchanged.
