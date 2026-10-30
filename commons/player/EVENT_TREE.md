# The event tree — what a hand does, where

Palle, 2026-10-30: *"We need an event tree: if we are working in the workbench for the playground now, with
a hand menu or placing an artifact; inside glass VR we can use the menu but it is not one by default."*

The tree below is what the rig does TODAY (museum rig: `commons/player/museum_rig.tscn`, the Void's and the
museum's; the grid maps keep the bracelet), followed by what is proposed and not built. Each leaf names the
file that owns it, so a change is one place.

## Contexts (the root)

| context | where | the palette | owner |
|---|---|---|---|
| **tower** | the Void's floors (`commons/void/game.gd`) | off; **left X** puts it up, X again down; left palm up shows it while up | `inventory_prism.gd` |
| **workbench** | the playground workshop (floor 20, `Trans_Playground`) | *proposed:* up by default (`rig.prism_always` per floor), the right hand the wand | — |
| **glass hall** | the spatial lab / colour halls (`/spatial-lab`) | *proposed:* available on X, not up by default — the hall's own switches keep the trigger | — |
| **museum hall** | endless museum (`endless_museum.gd`, plain hands) | same as tower: X | `inventory_prism.gd` |
| **grid map** | a map loaded by itself (`vr_staging` → grid) | the bracelet's PLACE mode and ITEMS tab (`becoming_catalyst.gd`); no prism | `inventory_hand.gd` through the bracelet |

The per-context default is one number waiting for a home: `em_layout.json rig.prism_always` is global now.
The proposal is `rig.prism_contexts: {"workbench": "always", "glass": "x", "tower": "x"}` read by the prism from
the floor/hall it stands in (the Void knows its floor: `game.checkpoint`; the museum its chapter).

## The left hand (the wand hand)

```
left X ─────────── prism.toggle()                 the palette up / down            inventory_prism.gd, void/game.gd _left_button
left Y / stick ─── the Void's prefab board         (the other agent's)             void/inventory_board.gd
left palm up ───── prism shows while up            rig.palm_up 0.55               inventory_prism.gd _process
left stick ─────── move / strafe                                                   XR Tools MovementDirect
wrist roll ─────── the drum shows its next face    (Open Brush)                   inventory_prism.gd (the faces are in hand space)
◀ ▶ on a face ──── prism.turn(±1)                  90° snap + haptic tick          inventory_face.gd _ear
```

## The right hand (the pointer hand)

```
pointer on a face/switch ── the face's button / the switch      XR Tools FunctionPointer; the trigger is theirs
trigger, pointing at nothing of the UI:
  ├─ current = tape (worn) ──── roll.fire_worn / release_worn     tape_roll/roll.gd (leg rule, tap-tap)
  ├─ current = rubber (tool) ── hand.erase_at(pointed)            inventory_hand.gd
  ├─ current = a prefab ─────── hand.spawn_where_pointed           ghost shows the place first; refused: notice + long buzz
  │     ├─ hit a wall  ──── mount wall|any: hung, back to the wall
  │     ├─ hit a floor ──── mount floor|any: standing; snap:grid → the metre point, turned by _yaw
  │     ├─ hit nothing ──── hand.spawn_in: into the hand (the kit's tower-in-hand way)
  │     └─ over budget ──── BUDGET FULL, nothing made
  └─ current = nothing ──────── nothing
grip, palette up:
  ├─ pointing at a thing the hand placed ── that thing taken back     (Palle: "remove the object with the grip")
  └─ pointing elsewhere ─────────────────── the last thing taken back
grip, palette down ─────── the Void's grab (XR Tools FunctionPickup; ranged up to 2 m)
A / B ──────────────────── jump (the Void)
stick ──────────────────── forward/back, turn
```

## Distance grab

A hand can grab a pickable up to `ranged_distance` (2 m in the Void) in a narrow cone. `grab_hint.gd` on the
rig draws what the hand would grab — a line from the hand to the pickup's `closest_object` and a ring on it, in
the hand's colour — only while the thing is beyond the near zone. `rig.grab_hint false` removes it.

## The ghost

In place mode the prism keeps a ghost: a translucent copy of the current prefab at the place the trigger would
put it (the same rule as the placement, `hand.placement_at`), with the aim line from the hand to the hit. It is
the item's colour when the place is good, red when it would be refused (a floor for a wall thing, the budget).

## Not in the tree yet

- the per-context default (workbench up, glass on X) — the number has no home
- the bracelet's PLACE mode does not show the ghost (the grid maps place from the hand)
- a hall's own switches and the palette's faces both answer the pointer; whoever is hit first wins
