# The inventory — things to hold and place

Palle, 2026-10-29: *remake the catalyst into what we have in the inventory and can use … one panel where we
select the current thing we hold, or none; for each item its config; as we go along we get more things we can
place and play with, until we have a large arsenal to stack and build strange installations with.*

## One file is the truth

`commons/data/inventory/items.json`. One item = one registry token, how it mounts (`wall`, `floor`, `hand`,
`any`), its `size`, an optional `scale` (the clock is the 1.24 m `frame_counter_display` console at 0.48 — the
artifact's own size and its 39 placements are untouched), its own `defaults`, and its **knobs**: each names a
key the token's script reads (an `@export` it reads back, or a key its `apply_grid_config` takes).
`python tools/inventory_check.py` refuses a token with no scene on disk and a knob the code does not have
(exit = findings) — derive, never transcribe: a knob the code ignores would be set in silence.

- `unlock: ""` always; a sequence id = after that sequence (`LabManager.is_sequence_completed`).
- `coming: "..."` = no scene yet; shown greyed. The triangle waits for the playground workshop astra is
  building; it drops in by adding a token to its line.
- **The point is the ball, the line the rod** (`commons/artifacts/playground_kit/`, its README): a six-socket
  foam hub and a steel-cored foam rod that snaps into sockets, bridges two balls, and hits with a thwop. Both
  are pickables of their own, so the hand holds them as they are and they settle by their own rules.
- **The tape binds them** (Palle: "the tape binds balls and rods"). A strip laid from one body to another
  makes a reversible fixed joint (`tape_roll/binding.gd`): ball to rod, rod to rod, or a ball to the floor
  or a wall, which then holds it up. Lift one and the other comes; a bound thing pulled more than 28 cm from
  its place peels the tape. The tape item's **Binds** knob (`bind_objects`) turns this off for marking only.
  Probe: `commons/testing/probe_tape_binds_kit.tscn`.
- **The tape is WORN, not held** (Palle, 2026-10-29: "I pick up the tape with the hand, but that should really
  just be the last config of catalyst inventory, and a small version of the tape over the hand rather than
  holding the tape, then I can use the tape without holding it"). Its item mounts `worn`: choosing it in the
  ITEMS tab puts the roll on the bracelet's hand as a bangle at 0.4 (over the back of the hand, its axis along
  the forearm, not grabbable, no collision) and the **trigger lays tape from that hand**, with a thin aim line to
  the dot; **grip** puts the last strip back on the roll; choosing another item puts the bangle away (its strips
  stay) and choosing the tape again brings the same roll back. The hand stays free to hold a ball or a rod.
  Knobs: **Tape** (printed with words / masking / pink / barrier — the words tape is the printed kind, printing
  where it lies or the **Note**), **Leg**, Binds, Design, Prints, Note. The strips are full width whatever the
  bangle's size. `InventoryHand.sync_worn(controller)` / `worn_node()`; `roll.gd` `wear / put_away / fire_worn /
  release_worn / undo_last / apply_config`. See `tape_roll/README.md` § Worn, and the leg rule.
  Probe: `commons/testing/probe_tape_worn.tscn` (7 checks, `ada_run/inventory/tape_worn.{png,json}`).

## On the plain hand (2026-10-29): the prism, in the museum and the Void

Palle could not reach the inventory in VR: the museum rig keeps **plain hands** (`em_layout.json`
`rig.plain_hands`, Palle 2026-08-18: "no bracelet, no editing tool, just the VR hands"), which strips the wrist
tools, ends any bracelet and makes every `becoming_catalyst` ungrabbable - and the Void (`commons/void/game.gd`)
routes the buttons itself. Palle's rulings: **the inventory on the plain hand, no bracelet**, and then **the
prism in VR, the wrist panel retired** - the web palette (`ada_encyclopedia` `/catalyst-inventory`,
`OpenBrushCatalystInventory.tsx`) was the prototype for the headset. `commons/player/inventory_prism.gd` is a
node of `museum_rig.tscn`, the one rig scene the museum (base.tscn) and the Void both drive, so both have it:

- **Left palm up** (the left controller's +X against UP past `rig.palm_up`, 0.55, hysteresis 0.15) and a
  four-faced prism floats upright over the left hand, the active face turned to the eye; palm down and it goes.
  `rig.prism_always: true` keeps it there, as Open Brush keeps its palette.
- **Four faces as on the web** (`inventory_face.gd`, a Control per face in an XR Tools `Viewport2Din3D`,
  throttled to 10 fps for the Quest): **HAND** (Nothing · Clock · Tape · Ball · Rod, locked and coming ones dim),
  **KNOBS** (the current item's: choices as rows, ranges as − value +, text shown), **TAPE** (the designs from
  `tapes.json` as swatches, prints where it lies / the note, the leg, binds, metres left, UNDO LAST STRIP - it
  dresses the worn roll live whatever is in the hand, `InventoryHand.set_knob_for`), **PLACED** (what is in the
  world, last on top; TAKE BACK LAST, TAKE ALL BACK). The **◀ ▶ ears** on every face turn the prism, as the web's
  frame swipe and Q/E do.
- **The right hand is the wand**: its pointer presses the faces as any switch (the viewport bodies are on the
  layers the Void's pointer reads); **trigger** lays tape from the worn roll or makes the current item into the
  right hand's own `FunctionPickup` - never while the pointer is on a target; **grip, with the prism up**, takes
  the last thing back (grip alone stays the Void's grab). The web's size ring at the wand tip: a ring the tape's
  width on the right hand while the tape is in it.
- **The current item is a miniature of itself over the right hand** (Palle, 2026-10-29: "the current object
  must be a small version of the original"): the tape is its bangle; the ball, rod and clock are their own
  scenes scaled to 10 cm on the longest side, over the back of the hand, inert -
  collision off, frozen, pickup disabled, out of every group so a tiny ball never enters the support graph
  (`InventoryHand._sync_mini`, from `sync_worn`). A knob turned remakes it, so the miniature wears the colour.
  The trigger makes the full-size one; the bracelet's hand gets the same through the same call.
- `rig.inventory: false` switches it off. A grid map's bracelet keeps its own hand.
- **hand.json is applied only when it is newer than the game** (`InventoryHand._born`): a file the page wrote
  yesterday no longer overrides the choice made in VR a second later (which made the first probe lay no tape and
  make a clock instead of a ball); a SEND TO VR after launch still lands within a second.

Probe: `godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_prism.tscn` -
the real museum rig on fake trackers, 8 checks (the node, four faces bound, hidden; palm up shows it upright over
the left hand with HAND to the eye; ▶ makes KNOBS active and facing; the Tape card worn on the right hand with
the ring at half the width; the hazard swatch dresses the worn roll; a 3-point 0.8 m stroke from the right
trigger listed on PLACED; TAKE BACK LAST refills the roll; the Ball card + trigger into the right pickup, grip
takes it back, palm down hides). `ada_run/inventory/{prism.png, prism.json}`. The palm axis is my definition of
"up" for a controller, not measured on a hand: if the prism shows at the wrong turn, `rig.palm_up` is the knob.
A button freed inside its own `pressed` is a locked object: the faces `remove_child` + `queue_free` on refresh.

`hand.json` beside it is the **web page's hand**, `{item, config: {id: {knob: value}}}`, written by the page's
SEND TO VR and watched by the VR hand once a second. A copy at `user://inventory/` is read first (the headset).

## In VR — the bracelet's PLACE mode

`becoming_catalyst.gd` gained one mode, `place` (MODE_DEFS, always unlocked), one early-return in
`_on_controller_button`, and the panel mapping ITEMS ⇄ place. All the logic is in `commons/player/`:

| file | does |
|---|---|
| `inventory_items.gd` | reads items.json (user:// first), resolves a token to its scene through `registry/*.json`, merges an item's defaults under the hand's values |
| `inventory_hand.gd` | the choice (`current`, `""` = none), the knob values per item, `spawn_in(controller)` / `spawn_at(xform)`, `remove_last()`, the hand.json watch |
| `inventory_carrier.gd` | an `XRToolsPickable` body round an artifact that is not a pickable itself; fits a collider to the artifact's meshes; **settles** when let go |

**Trigger** makes the current item in the hand (picked up at once by that hand's `XRToolsFunctionPickup`; an
artifact that is a pickable itself, like the ball, is held as it is; an item that mounts `worn`, the tape, is
not made at all — it is on the hand already, and the trigger goes to it). **Let go** and the carrier settles:
with its back within 0.35 m of a wall (its `-Z`, the counter's back; the ray looks past the item's own collider)
it turns to face out of the wall and freezes there; a standing item let go above a surface stands on it;
otherwise it is a body — it falls and stacks on whatever is under it. **Grip** takes the last one back.
**A** cycles the item. The panel's **ITEMS** tab (`tabbed_editor_panel.gd`, fifth tab) is the same choice:
one button per item (locked and coming ones dimmed), NONE, and the held item's knobs — choices as rows of
buttons, ranges as sliders (committed on release), text shown as the web page set it.

## On the web — `/catalyst-inventory`, face 4 "In the hand"

The prism's fourth face (`paintInventoryFace`, `palette-faces.ts`) is the same list: hold a thing or nothing,
turn its knobs (the page re-makes its mesh — the counter shows its reading as a bar), click a wall to place it
there facing out, and **SEND TO VR** (`POST /api/inventory` → hand.json). `GET /api/inventory` returns the
items and the hand. Text knobs are typed under the scene. The rules are in `src/lib/inventory.ts`.

## Probe

`godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_place.tscn` (a
scene, since the carrier and the bracelet extend XR Tools pickables, which a `--script` probe cannot compile).
Nine checks with numbers: wall snap facing out, ~60 cm across, floor stand, free fall, hand.json applied to the
held counter within 2.5 s and the copy removed, the tape held as the roll, grip takes back, the bracelet and
panel load with the ITEMS tab filled. `ada_run/inventory/{place.png, report.json}`. The "Parameter material is
null" lines after the final "9/9" are the renderer's teardown at quit, not the placing.

Not yet: the real hand through `XRToolsFunctionPickup` is exercised only by the same call the hand inventory
makes (`_pick_up_object`), not by a fake rig; nothing persists across maps; VR → web (what VR holds, back to
the page) is one-way the other way only; hall-level unlocks (point in the point hall) wait for the workshop.
