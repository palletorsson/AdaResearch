# The corridor has a spine

Eight procedural architectural bays form a parent-child Node3D chain. Each bay has a floor, frame, roof and balustrades. All parts are created once. The controls transform their parent nodes; no geometry is regenerated while interacting.

Open `preview.tscn` and press F6 to use the existing desktop player in a separate museum research room. The lookup `architecture_spine` is registered as a prototype, not inserted in the curriculum. The previous Omoss-inspired creature remains unchanged.

## Controls

- Lift the pink handle: shared hinge height from floor to roof, mapped from 0.65 m of hand movement to 2.6 m in the model.
- BEND / JOINT: the same local rotation on the seven child joints.
- SEPARATE: alternating local offsets intentionally break their attachment.
- EACH BAY: a uniform local scale ratio compounds through the hierarchy. With 0.9, the eighth bay is 0.9^7 of the first.
- PASSAGE and RESET: straight, original size and floor pivots. FOLD: 24 degrees at each child joint. SLIP: nine degrees with 0.65 m alternating separation.

The same native XRTools dials, rectangular buttons and desktop/XR grab proxy used by the previous creature are reused at their authored physical scale. Lateral hand movement is ignored; the handle returns to its vertical guide on release.

## Exact operation

For the child joint, `L` is the parent bay length, `p` the chosen local pivot, `B` rotation times uniform scale, and `d` deliberate separation:

```text
child.origin = (L, 0, 0) + p - B*p + d
child.basis = B
```

At `d=0`, transforming `p` produces `(L,0,0)+p`, the matching hinge in the parent. This fixed-point condition survives rotation and scaling. It does not guarantee that entire floor edges, roofs, rails or volumes remain compatible. At a floor pivot the roofs intersect during strong folding. At a roof pivot gaps open in the floors. Scaling keeps the centreline attachment, but changes the width of adjacent bays.

This is a visual assembly model. It has no Skeleton3D skin, joint physics, self-collision, portal graph, gravity rotation or navigable moving surfaces. A Node3D hierarchy is sufficient for rigid pieces. The stage, room and console have fixed colliders; the moving model deliberately has none. The low rail marks the observation area but is not a complete enclosure.

## Verification

`tools/probes/architecture_spine.gd` runs the real scene with Godot 4.6. Twenty-seven checks pass: hierarchy, source reuse, rigid shape, fixed hinge positions, floor gaps, deliberate disconnection, compounded scale, complete reset, parameter bounds, desktop pointer controls and simulated XRTools grip/move/release. The suite captures five states, detail, console and plan view. A physical headset and walkable conversion are not tested.

```text
Godot --path . --xr-mode off --no-window --rendering-method gl_compatibility --script res://tools/probes/architecture_spine.gd -- --capture-architecture --no-bridges
```

`--no-bridges` suppresses the museum ecosystem's modulation in comparison captures. The native log retains an unrelated pre-existing UID warning. Receipts: `ada_run/architecture_spine/`. Images and game references: `doc/book/iterations/2026-10-09-the-corridor-has-a-spine/`.
