# Tape rolls / Point Lines

A carried roll turns two selected points into a visible material strip. The line becomes a mark, a boundary or a connection between objects. Changing the roll changes the width and surface, rather than introducing a different interaction.

- Masking: 5 cm, warm paper.
- Marking: 7.5 cm, pink.
- Barrier: 12 cm, pink and black diagonal bands.
- Printed: 7.5 cm, ivory, printed with words (`printed.tscn`, registry `tape_roll_printed`).

**Printed tape** reads where it lies. With `print=environment` (the default) a strip prints its length, what it runs from and to or the one thing it marks (the artifact a body belongs to, by registry token or scene, not its collider's node name), whether it joins them, its heading and slope, and its number on the roll, e.g. `1.98 M · FROM TIMBER PLANK 2M TO PLATFORM BLOCK · HEADING NE · RISING 28° · TAPE 1`. The bodies and the number are fixed when it is laid; the length, heading, slope and whether it holds are read again whenever the strip is redrawn, so carrying a plank away with tape on it changes what the tape says. A freehand stroke prints along its curve and gives its stroke length beside its end-to-end length. With `print=note` it prints `note` instead: a tape is a way to annotate the space. The print is 2D in 3D: a Label in a SubViewport (96 px across the tape), the phrase repeated as many whole times as the strip holds (a short strip keeps whole items, cut at a separator), and that picture is the strip's own skin, since its UV runs in metres; it is redrawn only when the words or the length change. It reads the way it was laid; on a wall it turns to read upright, on a floor it turns to read for the head that laid it. Probe: `commons/testing/probe_printed_tape.gd` (windowed; `ada_run/printed_tape/`).

**Designs.** A roll with `tape: <id>` wears a design from `tapes.json` instead of its kind's skin: its width, two colours, a pattern (solid, diagonal, bands, stripe, edges, chevron, checker, dots, dashes), the repeat in metres, the pattern's share, a slant, the edge, grain, roughness, and optionally a print (environment or a note, in its own ink, on its own pattern). Designs are made at the encyclopedia's `/tape-studio`, which lays them on a floor, a wall, a span and a curve in three.js and saves to `tapes.json`. The page and the game paint with one rule (`src/lib/tape-design.ts` texel and `tape_design.gd` texel); `tools/tape_design_check.ts` compares every design texel for texel against the Godot dump (`probe_tape_designs.gd -- texels`), with a negative that must differ. The masking, pink, barrier and printed rolls keep their own skins and are shown on the page read only. `probe_tape_designs.gd` without `texels` lays one strip of each design in a window (`ada_run/tape_design/designs.png`).

Hold a roll, click once at a solid surface to fix A, move the aim while the preview stretches, then click again to fix B. These are two separate clicks, with no double-click timing requirement. Holding the button, moving the hand or releasing the first click never places tape. Only the second press commits one continuous strip with two endpoints. Desktop uses right mouse pickup and left mouse clicks; VR uses grip and trigger presses. Dropping a roll cancels an unfinished strip.

**Worn, from the inventory (2026-10-29).** The bracelet's ITEMS tab has the tape as an item that mounts `worn`
(`commons/data/inventory/items.json`, `commons/player/INVENTORY.md`): chosen, the roll is a bangle on the
bracelet's hand (`wear(controller, 0.4)`: over the back of the hand, axis along the forearm, not grabbable, no
collision, under the controller so it rides with it) and lays tape from that hand without being held — the
hand stays free. The bracelet's trigger is `fire_worn()` / `release_worn()`, its grip `undo_last()` (the last
strip back on the roll), another item `put_away()` (hidden, strips kept). A thin aim line runs from the hand to
the dot. The strips are the roll's full width: a held roll's scale sets its tape width (`_tape_scale()`), a worn
bangle is a picture of the roll. `apply_config()` takes a knob turned while worn (the kind, a design, the leg)
and rebuilds the skin. The item's defaults are `freehand_draw: true, leg: 0.3`, so a worn roll works both ways:
**tap, move, tap** lays a straight strip; **hold, move, let go** lays a stroke of legs.

**The leg rule** (Palle: "do not add lines if we have not moved the raycast point more than 30 cm, straight
between points"). With `leg > 0` the held stroke reads the aim every `drag_tick` (0.2 s, the slow ray) and
adds a point only when the aim has moved `leg` from the last point *and* the straight leg to it is clear (a ray
from point to point, excluding both bodies); the strip is the straight legs between those points, so a hand
that wavers lays a clean polyline. The ray missing (air, a gap) or a blocked leg starts a fresh patch, and the
gap leg is not paid. Letting go takes the point where the hand stopped from 6 cm, so the stroke ends there, not
a leg back; a tap that never moved a leg keeps its start for the next tap. `leg` 0 keeps the dense sampling
below. Probe: `commons/testing/probe_tape_worn.tscn` — a fake rig wearing the inventory's tape over two slabs
with a gap: 20 cm no point, 40 cm one leg, the gap a fresh patch, a 5-point stroke 0.9 m paid and printed at
7.5 cm, undo refills, tap-tap lays 1 m, put away and back. `ada_run/inventory/tape_worn.{png,json}`.

Freehand drawing is an explicit opt-in through `freehand_draw=true` on a roll. In that mode, holding fire and dragging samples the visible surface, and releasing commits the whole stroke. It follows collider curvature and breaks at missed rays instead of painting across empty air. The Point Lines supply defaults to two-click placement to avoid accidental broken patches.

Endpoints and stroke samples are stored in the touched physics bodies' local frames. They follow translation, rotation and scale. Hidden or unloaded endpoint bodies hide/remove the strip. Marks on one object remain surface decoration. Joining separate physics bodies, with at least one rigid body, adds a reversible native Jolt fixed joint. It preserves their relative pose and allows a taped assembly to carry load under gravity. It is an ideal adhesive constraint, not a cloth simulation or a collision wall. Render-only objects without solid colliders cannot be targeted. The standalone roll's `bind_objects=false` configuration enables marks/spans without binding.

Frozen utility pickables temporarily gain gravity and release dynamically while taped. A reference-counted lease restores the authored physics settings when their last binding disappears; ordinary dynamic exhibits retain their original gravity. Undo, Tidy, removing a strip or deleting an endpoint releases its constraints. Pulling a held object more than 28 cm out of its bound relative position peels the joint and visibly splits the tape, rather than moving a static wall or snapping a released hand back. Tape use is not refunded by peeling.

Each roll has 30 metres, an 8 metre aiming reach and maximum span/stroke length, and a 32-strip limit. A stroke has at most 256 surface samples; it is one Undo operation, not hundreds of separate strips. Only committed length is consumed. Undo refunds the latest strip. Tidy clears tape, refills rolls and returns unheld rolls to their authored storage poses. These controls require deliberate click/trigger input; brushing a plank past them does not erase the work. Runtime tape is session-local. Authored station members and roll placements are independently editable and reusable through the shared catalogue, workbench and lab editor.

The station reuses the existing timber finish and carryable one-metre plank. Real generated image textures preserve paper, pink and diagonal-band surfaces in exported editor models. The tool uses native XRTools pickup/action signals, actual physics rays and native joints; it does not copy one body's pose onto another every frame.

This makes the engine's collider boundary and fixed-joint assumption visible: a stripe follows the collision surface, which can differ from a decorative mesh; adhesion holds a relative frame, rather than reproducing the bend and friction of physical adhesive. Binding two separate things and peeling them apart is the deliberate seam to play with.

Verification receipts are in `ada_run/matter-reference/tape-rolls*-checks.json`, `ada_run/tape-rolls/` and `ada_run/tape-two-clicks/`. Run `python tools/test_tape_clicks.py` for the two-click regression, optional freehand, desktop mouse and synthetic tracked-controller checks. Desktop runs with a rendered window because its pointer requires mouse capture. These checks are separate from physical-headset acceptance. The focused floor-3 probe excludes asynchronous adjacent-floor loading; a pre-existing Trace hardware `Panel_left` readiness error is outside this tool's receipt.
