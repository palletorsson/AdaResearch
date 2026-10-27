# Tutorial_Disco / A grid with a clock (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks:
- `floor-2.json` substituted into this trial's `rooms.json` validates against
  `rooms.schema.json`.
- All four IDs appear once, with every `#` config value and the token's rotation, y and
  scale.
- All four catalog keys exist and point at the original scenes.

**One adapter is required** for the disco floor; see Dependencies.

## Placement

The hall (19 x 23) is turned 180°: `x = 9 - col`, `z = 13 - row`,
`facing = rotation + 180`. The spawn (9,1) lands on the arrival (0, 12). Heights are
floor-relative and nothing exceeds 2.51 m, so a taller storey for floor 1 does not
affect this floor.

| id | at | facing | height | scale | config |
|---|---|---|---|---|---|
| `f2_disco_controls_9_4` | 0, 9 | 180 | 0 | 1 | mode mono |
| `f2_step_sequencer_3_5` | 6, 8 | 0 | 1.2 | 1.2 | sound_preset 90s_house |
| `f2_film_disco_phase_17_9` | **-8, 5** (rigid -8, 4) | 90 | 0 | 1 | plinth 0, pin true |
| `f2_standalone_disco_9_13` | 0, 0 | 180 | 0 | 1 | width 12, depth 12, tile_size 0.8, floor_y_offset 0, walkable true |

**Footprints:**
- **Disco floor, with config applied.** 12 x 12 tiles of 0.8 m make a 9.6 x 9.6 m square
  at x, z ±4.8. The tiles' top is at 0.02 m and the walk collider's top at 0.01 m. It
  stays 2.7 m from both shaft holes and from the floor-2 landing pad, and 1.3 m from the
  electrical riser at (-6.08, -4.2).
- **Console.** Two solid 1.35 x 0.5 m stands at z 9.0 and 9.38. The panels face the
  arrival, 2.4 m away, as in the source.
- **Sequencer.** A floating 0.72 x 0.30 m screen (0.6 x 0.25 at scale 1.2), 1.2 m up,
  facing the arrival. It is 1.5 m from shaft B's x edge but well outside the hole's
  z band.

**The one adjustment: the film moves +1 m in z.** At the rigid (-8, 4) the 2.68 m case
spans z 2.66..5.34 at x -8: it overhangs shaft A's opening by 0.34 m. Its TURN VIEW
button (local x +0.78, world z 3.22) would be pressed from 0.2 m off the hole's corner.
At (-8, 5), with x and facing kept:
- the case starts 0.66 m north of the hole edge;
- every button is at least 1.22 m from the hole edge;
- the viewer stands at x > -7.5, on the slab;
- the screen still faces +x across the disco.

## Controls and binding (handler bodies read)

- **`disco_controls` (mode mono).**
  - **Mode.** `_ready` reads meta `config_mode`, which the Void stamps before `add_child`.
    Mono means `colour` is false: palette 0 (black/white), panels "A GRID WITH A CLOCK"
    and "TEMPO", and no COLOUR button. `apply_grid_config` is a no-op, so a mode change
    needs re-instantiation.
  - **Buttons.** PATTERN calls `cycle_pattern` (CHECKER / ROWS / DIAGONALS / SNAKE /
    SUPER TRIANGLE). PLAY / HOLD calls `toggle_running`, ONE STEP calls `step`, and
    SPEED calls `cycle_speed` (0.5 → 0.25 → 1.0 s).
  - **Binding to the floor.** `_find_floor` (deferred, retried every 0.5 s) searches
    `Kit.room_root` = the Void floor root (meta `em_map`). It matches the node whose
    script **is exactly** `StandaloneDiscoFloor.gd`. It then sets
    `floor_node.set_process(false)` every frame, so the floor's own ten-pattern cycle never
    runs, and `monochrome = true`. The console then paints every tile on its own 0.5 s
    clock. The readout says "FINDING FLOOR" until bound.
  - **Binding to the sequencer.** `_bind_sequencer` takes `step_sequencer` from the
    floor's `SequencerBridge` child and connects `step_triggered`. A step on column
    `step % 12` is restored to the console's pattern 0.15 s later (`PULSE_SECONDS`).
- **`DiscoSequencerBridge` (inside the disco scene).**
  - **Search.** One frame after `_ready`, it walks up to the `em_map` root and searches it
    once for a `StepSequencer`. It never retries.
  - **On each triggered step.** It flashes that column 40% toward white; in mono the
    flash is grey. On track 0, step 0, it calls `next_pattern()`, which is invisible
    while the console holds the floor.
- **`step_sequencer` (90s_house).**
  - **Voices.** TR909_KICK, KORG_M1_PIANO, ACID_606_HIHAT and TB303_ACID_BASS. All
    exist in `AudioSynthesizer`, and the sound is generated per hit by
    `CustomSoundGenerator`, with no sample assets.
  - **Defaults.** `auto_play` is false and the grid starts empty, as in the source.
    Steps fire, and the floor responds, only after a visitor toggles cells and presses
    PLAY.
  - **Controls.** All controls are on the `Viewport2Din3D` screen. Its layers 1, 21 and
    23 are inside `PlayerRules.POINTER_MASK`, and the desktop hand is the museum's
    XRTools pointer, so mouse and XR pointer should both reach it.
  - **Sound.** The players are non-positional (bus Master), so the beat is heard on
    every floor while floor 2 processes.
- **`film_disco_phase`.** It uses the `concept_monitor` buttons PAUSE, REPLAY, STEP and
  TURN VIEW, which call `film_stage`. `disco_phase.gd` overrides none of them. It plays
  on gaze within 14 m.

## Dependencies

1. **Disco config adapter (required).** The scene root `StandaloneDiscoSetup` has no
   script. The grid forwards config to the first child with a handler
   (`GridInteractablesComponent` :1826-1853), but `floor_content._build_artifact` calls
   only the root.
   - **Without it** the floor builds the scene defaults: 0.5 m tiles (6 x 6 m) at
     `floor_y_offset` **0.5**. That is a thin collider floating at knee height, which
     blocks the walk instead of carrying it.
   - **Proposed fix.** An inherited scene with this root script, plus catalog
     `configure_before_ready: true`. The values then land before `DiscoFloor._ready`
     builds, so there is no deferred rebuild:
     ```gdscript
     extends Node3D
     ## The original root has no handler; the map config belongs to the floor child.
     func apply_grid_config(config: Dictionary) -> void:
     	get_node("DiscoFloor").apply_grid_config(config)
     ```
   - **Constraint.** Do **not** replace DiscoFloor's own script. The console matches it
     by exact script identity.
2. **Build order.** The deferred build makes one artifact per frame, in JSON order.
   The sequencer is listed before the disco, so the bridge's single search finds it. Keep
   that order, or the beat link silently fails ("Could not find both").
3. **Editor round trip.** Re-instantiating the sequencer alone leaves the bridge holding a
   freed reference, so the beat link stays dead until the disco is also rebuilt. Moving a
   mount is harmless.

**Not transferred:** the perimeter walls (structure 6), spawn `s` at (9,1) and the
teleporter `t` at (9,21).

## Meaningful native checks

```gdscript
if level == 2:
	var c: Node3D = station("f2_disco_controls_9_4")
	var d: Node3D = station("f2_standalone_disco_9_13").get_node("DiscoFloor")
	for i in 90:
		if is_instance_valid(c.floor_node): break
		await frames(1)
	check(tag+"disco config reached the floor", d.grid_width==12 and is_equal_approx(d.tile_size,.8) and is_zero_approx(d.floor_y_offset) and d.get_node_or_null("FloorCollision") != null)
	check(tag+"console bound, floor held in mono", c.floor_node==d and not c.colour and d.monochrome and not d.is_processing())
	var before: Color = d.multimesh.get_instance_color(0)
	await press(c.find_children("*","",true,false).filter(func(n): return n.has_signal("pressed"))[2])   # ONE STEP (3rd button)
	check(tag+"ONE STEP repaints a tile, grey only", c.phase>=1 and d.multimesh.get_instance_color(0) != before and is_equal_approx(d.multimesh.get_instance_color(0).r, d.multimesh.get_instance_color(0).b))
	var s: Node3D = station("f2_step_sequencer_3_5")
	check(tag+"90s_house preset, bridge paired with this sequencer", s.sound_preset=="90s_house" and d.get_node("SequencerBridge").step_sequencer==s and c.sequencer==s)
	# toggle one kick cell through the Viewport2Din3D UI, press PLAY, then:
	# within one bar step_triggered fires and a disco column flashes then returns to the console's value after 0.15 s
	game.place_player(floor_point(d, 2.0, 2.0)); await frames(30)
	check(tag+"disco tiles are walkable, flush", game.body.is_on_floor() and absf(game.body.global_position.y - (game.building.spec.levels[level]+.01)) < .05)
```

Use `monitor_press(film, "route")` for TURN VIEW. Also press PATTERN to reach SUPER
TRIANGLE (index 4): it adds a `super_triangle_surface` child to the floor.
