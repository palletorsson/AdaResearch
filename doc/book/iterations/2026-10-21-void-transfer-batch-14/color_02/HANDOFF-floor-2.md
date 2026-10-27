# Color_Rainbow / Every Body, More Colour (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks:
- `floor-2.json` substituted into this trial's `rooms.json` validates against
  `rooms.schema.json`.
- All four IDs appear once with their `#` configs. `em_plan` gives a museum support of 0
  for all four.
- All four catalog keys exist and point at the original scenes. **No adapter or
  placement adjustment is needed.**

## Placement: rigid and unturned

This hall's spawn `s` is at (7,23) and its exit `t` at (7,2): the visitor enters at the
high-row end and walks toward lower rows. That is already the Void's direction (arrival
at z 12, walking toward -z), so the transform is a pure translation:
`x = col - 7`, `z = row - 11`, `facing = token rotation`. The spawn (7,23) lands on the
arrival (0, 12).

| id | at | facing | height | config |
|---|---|---|---|---|
| `f2_pick_up_cube_2_3` | -5, -8 | 0 | 0 | none |
| `f2_catalyst_pedestal_12_3` | 5, -8 | 0 | 0 | sequence auto, lease_s 45 |
| `f2_rainbow_7_13` | 0, 2 | 0 | 0 | stage celebration, plinth 0 |
| `f2_film_rainbow_partitions_13_16` | 6, 5 | 270 | 0 | plinth 0, pin true |

**Actual footprints, from the code, in Void coordinates:**
- **Celebration** (`rainbow_celebration.gd`, root at (0,2)). It spans x -5.43..5.45 and
  z -5.06..9.68.

  | element | position or extent | height |
  |---|---|---|
  | Solid arch (scale 0.23) | ends at x ±5.43, z 0 | top about 5.84 m |
  | Candy steps (solid, convex) | x -4.0..-2.2, z -2.9..9.0 | 0.18-0.9 m |
  | Six flush pavers | centre route | flush |
  | Three mushrooms | x 3.15..5.45 | caps 1.2-2.0 m |
  | Pride banners | x -5.3..-4.3 | |
  | Stars | z -3.8 | |
  | Finish banner and solid poles | x ±3.4, z -5 | 4.95 m |
  | Solid control plinth | (2.15, 9.35) | |
  | Welcome patch | (0, 8.4) | |
  | Five party cubes | z 6.2..-2.2 | |

- **Film.** The case spans z 3.66..6.34 at x 6, with the screen facing -x across the
  arch, between two mushrooms as in the source.
- **Pedestal.** A 1 m cage. The cube is 0.5 m and bobs ±0.2 m.

**Clearances:**

| from | to | gap |
|---|---|---|
| Arch feet | both shaft holes | 2.05 m (feet lie in the z band) |
| Arch feet | floor-2 landing pad | 2.1 m |
| Film | shaft B | 1.5 m in x, 0.66 m in z |
| Nearest mushroom cap | riser at (6.5, -4.2) | 1.48 m |
| Pickup and pedestal | risers | 3.8 m |
| Pickup and pedestal | columns | 6 m |
| Arrival | welcome patch | 3.1 m (source: 3.6 m) |
| Arrival | control panel | 3.4 m |

## Fit problems (reported, not fixed)

1. **Ceiling.** The source hall is 8 m tall; floor 2 has 5.64 m under floor 1's slab.
   - **Welcome panel and its label.** The purple `WelcomePanel` (5.8 x 0.65 x 0.1 m,
     y 5.625..6.275, no collision) and its label "EVERY BODY / MORE COLOUR" (y 5.95) sit
     inside floor 1's slab. The panel **protrudes 0.275 m above floor 1's walking surface**
     as a 5.8 m fin at x ±2.9, z ≈ 0. Please check this against your Color_Nails
     placements.
   - **Arch.** The top 0.2 m of the outer secondary bands is hidden inside the slab.
   - **Options.** Fixing this needs a taller storey, at least about 6.7 m for floor 2, or
     curation.
2. **Hidden scene extras.** `rainbow.tscn` keeps its own `DirectionalLight3D` and
   `Camera3D` even in celebration mode; `floor_content` hides the sun and un-currents the
   camera. It also keeps an invisible `Environment` Node3D, which is not a
   WorldEnvironment and so is not touched. That node holds a 140 m sky sphere and a
   100 m ground plane at y -10. Any GLB export or editor bounds pass that ignores
   visibility will include them.
3. **Walls not transferred** (structure 8). The candy-step route and the arch stand open
   to the shaft side. The arch has no collision.

## Interactions (handler bodies read)

- **`rainbow`, celebration stage.**
  - **Building the stage.** `_ready` reads meta `config_stage`, which the Void stamps
    before `add_child`, and builds `rainbow_celebration.gd` instead of the 15 m arcs.
    `apply_grid_config` reads only `banding` and `substance`, so this config is a no-op
    after ready.
  - **MAKE ANOTHER RAINBOW panel.**
    - RE-DIVIDE calls `next_banding`. It cycles 6 → 7 → 48 → 2 bands at the same arch
      width, recolours the 8 steps and 6 pavers, and celebrates.
    - CELEBRATE calls `celebrate`, which shows 96 confetti quads for 3.5 s and increments
      `celebration_count`.
  - **Welcome patch.** The `WelcomePatch` Area3D (mask layers 1 and 20) checks the groups
    player, player_body, vr_player and em_walker, then celebrates. The Void adds
    `player_body` to its body (`game.gd` :133), so both the desktop walker (layer 20) and
    the XR body should trigger it.
  - **Party cubes.** Five one-shot cubes (`rainbow_party_pickup`) are collected by
    walking in (mask 1|20). Each gives a spark burst in the current band palette and
    **no score**, because `collect()` is overridden.
- **`pick_up_cube` (legacy wire / none).**
  - **Behaviour.** It bobs and spins and is collected by walking in (DetectionArea mask
    524289; `_is_player` groups).
  - **Score.** `score_provider` resolves to `void_trial_score`, so a pickup adds 1 to the
    trial score, not to `GameManager`.
  - **Lifetime.** It is freed until the trial rebuilds the floor.
  - **Editor note.** Its bob writes `global_position.y` from an `original_y` cached in
    `_ready`. A mount raised in the editor snaps back to the old height until the cube
    is rebuilt.
- **`catalyst_pedestal` → `becoming_catalyst`.**
  - **Lease.** `lease_s 45` keeps the pedestal alive after pickup. The cage fades, then
    returns with a fresh crystal after 45 + 1.5 s, carrying the same forwarded config.
  - **Forwarded keys.** `sequence` and `lease_s` are stashed and applied to the crystal
    after it spawns.
  - **XR.** A grab absorbs the crystal into the `XRController3D`. The autoload
    `CatalystCapabilityManager` starts `begin_lease(45)` and
    `spawn_bracelet_on_controller`. The default active mode is `voxel_editor`.
  - **Desktop.** The Void mouse grip can pick up the crystal (an `XRToolsPickable`), but
    absorption finds no `XRController3D`. The crystal shrinks to 1 cm, frozen in place,
    and `_deferred_reparent` aborts, so there is no bracelet. The cage still fades and
    the lease still returns it. **The catalyst is effectively XR-only.**
  - **`sequence: auto`** resolves through `AdaSceneManager.get_current_sequence_data()`.
    The Void never sets it, so a fresh trial resolves "": nothing is armed, and it prints
    "no sequence resolved". After a museum session it may inherit a stale sequence. In
    the museum it resolved to `color`, which arms the `chromatic` mode. I kept the
    config verbatim; `sequence: color` would make it deterministic but is a curation
    change.
  - **Outside this floor.** The Void hides only `first_catalyst_ability`. An absorbed
    crystal stays on the controller across floors and survives a trial retry until its
    lease ends.
  - **Grid modes.** The voxel and wedge placement modes target a grid; this floor has no
    `GridSystem` and no `impact_cells`. Their behaviour here is unverified.
- **`film_rainbow_partitions`.** It uses the standard `concept_monitor` buttons PAUSE,
  REPLAY, STEP and TURN VIEW through `film_stage`; `rainbow_partitions.gd` overrides
  none of them. It plays on gaze within 14 m.
- **Not transferred:** the perimeter walls, spawn `s` (it has a `height 5.5` property),
  the teleporter `t` at (7,2), and the map lighting and nature layer.

## Focused checks

```gdscript
if level == 2:
	var c: Node3D = station("f2_rainbow_7_13")._celebration
	check(tag+"celebration stage built, imported sun hidden", c != null and not station("f2_rainbow_7_13").get_node("DirectionalLight3D").visible)
	var paver_before: Color = c.tiles[8].material_override.albedo_color
	await approach(c.buttons[0], 1.2); await press(c.buttons[0])          # RE-DIVIDE
	check(tag+"RE-DIVIDE: 7 bands, recoloured route, celebrated", c.mode_index==1 and c.arch.banding=="roygbiv" and c.tiles[8].material_override.albedo_color != paver_before and c.celebration_count>=1)
	var n: int = c.celebration_count
	game.place_player(c.to_global(Vector3(0,0.06,6.4))); await frames(20)  # welcome patch
	check(tag+"walking in celebrates", c.celebration_count > n)
	var score: int = game.trial_session.score if game.trial_session else 0   # adapt to the trial score API
	game.place_player(c.walk_pickups.get_child(0).global_position); await frames(20)
	check(tag+"party cube collected without scoring", c.collected_cubes==1)
	var ped: Node3D = station("f2_catalyst_pedestal_12_3")
	check(tag+"lease configured on pedestal and crystal", is_equal_approx(ped._lease_s,45.0) and is_equal_approx(ped._crystal.lease_s,45.0))
	# synthetic XR: grab the crystal → catalyst_taken, CatalystCapabilityManager.is_lease_running(); after 46.5 s catalyst_returned
	# walk into f2_pick_up_cube_2_3 → trial score +1, GameManager unchanged
```

Keep one assertion that records the ceiling clip, for example the welcome panel top
(6.275 m) against the 5.64 m clearance, so it stays visible until curation decides.
