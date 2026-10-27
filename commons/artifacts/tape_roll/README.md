# Tape rolls / Point Lines

A carried roll turns two selected points into a visible material strip. The line becomes a mark, a boundary or a connection between objects. Changing the roll changes the width and surface, rather than introducing a different interaction.

- Masking: 5 cm, warm paper.
- Marking: 7.5 cm, pink.
- Barrier: 12 cm, pink and black diagonal bands.

Hold a roll, click once at a solid surface to fix A, move the aim while the preview stretches, then click again to fix B. These are two separate clicks, with no double-click timing requirement. Holding the button, moving the hand or releasing the first click never places tape. Only the second press commits one continuous strip with two endpoints. Desktop uses right mouse pickup and left mouse clicks; VR uses grip and trigger presses. Dropping a roll cancels an unfinished strip.

Freehand drawing is an explicit opt-in through `freehand_draw=true` on a roll. In that mode, holding fire and dragging samples the visible surface, and releasing commits the whole stroke. It follows collider curvature and breaks at missed rays instead of painting across empty air. The Point Lines supply defaults to two-click placement to avoid accidental broken patches.

Endpoints and stroke samples are stored in the touched physics bodies' local frames. They follow translation, rotation and scale. Hidden or unloaded endpoint bodies hide/remove the strip. Marks on one object remain surface decoration. Joining separate physics bodies, with at least one rigid body, adds a reversible native Jolt fixed joint. It preserves their relative pose and allows a taped assembly to carry load under gravity. It is an ideal adhesive constraint, not a cloth simulation or a collision wall. Render-only objects without solid colliders cannot be targeted. The standalone roll's `bind_objects=false` configuration enables marks/spans without binding.

Frozen utility pickables temporarily gain gravity and release dynamically while taped. A reference-counted lease restores the authored physics settings when their last binding disappears; ordinary dynamic exhibits retain their original gravity. Undo, Tidy, removing a strip or deleting an endpoint releases its constraints. Pulling a held object more than 28 cm out of its bound relative position peels the joint and visibly splits the tape, rather than moving a static wall or snapping a released hand back. Tape use is not refunded by peeling.

Each roll has 30 metres, an 8 metre aiming reach and maximum span/stroke length, and a 32-strip limit. A stroke has at most 256 surface samples; it is one Undo operation, not hundreds of separate strips. Only committed length is consumed. Undo refunds the latest strip. Tidy clears tape, refills rolls and returns unheld rolls to their authored storage poses. These controls require deliberate click/trigger input; brushing a plank past them does not erase the work. Runtime tape is session-local. Authored station members and roll placements are independently editable and reusable through the shared catalogue, workbench and lab editor.

The station reuses the existing timber finish and carryable one-metre plank. Real generated image textures preserve paper, pink and diagonal-band surfaces in exported editor models. The tool uses native XRTools pickup/action signals, actual physics rays and native joints; it does not copy one body's pose onto another every frame.

This makes the engine's collider boundary and fixed-joint assumption visible: a stripe follows the collision surface, which can differ from a decorative mesh; adhesion holds a relative frame, rather than reproducing the bend and friction of physical adhesive. Binding two separate things and peeling them apart is the deliberate seam to play with.

Verification receipts are in `ada_run/matter-reference/tape-rolls*-checks.json`, `ada_run/tape-rolls/` and `ada_run/tape-two-clicks/`. Run `python tools/test_tape_clicks.py` for the two-click regression, optional freehand, desktop mouse and synthetic tracked-controller checks. Desktop runs with a rendered window because its pointer requires mouse capture. These checks are separate from physical-headset acceptance. The focused floor-3 probe excludes asynchronous adjacent-floor loading; a pre-existing Trace hardware `Panel_left` readiness error is outside this tool's receipt.
