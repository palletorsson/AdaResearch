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
artifact that is a pickable itself, like the tape roll, is held as it is). **Let go** and the carrier settles:
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
