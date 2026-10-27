# Applied Ethics (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Deliverable: `floor-2.json`, in the same shape as
`rooms.json` `floors[2]`, for Codex to merge. Nothing else was written. No Godot run.
Native, headset and curation remain pending.

**Counts:** 6 / 6 placements from `source-inventory.json`, none omitted. **No adapter
and no required catalog change.** Static checks: `floor-2.json` substituted into
`rooms.json` in memory validates against `rooms.schema.json`. The audit's coverage and
`#`-config rule passes for all six.

## Placement

The source grid (13 x 12) is turned 180°: `x = 6 - cell_x`, `z = 12 - cell_z`,
`facing = token_rotation + 180`. The entrance (6,0..1) lands at the arrival (0, 12).
Everything stands between x -2.4 and 5.8 and z 6 and 11.6, far from both shafts and
the A pad.

| id | at | facing | height | config | note |
|---|---|---|---|---|---|
| `f2_tt_2_1` | 4, 11 | 270 | **1.4** | none | see the `tt` note below |
| `f2_excluded_class_visualizer_4_2` | 2, 10 | 180 | 0 | none | 1.8 m floor disc |
| `f2_bias_from_inside_5_2` | 1, 10 | 180 | **1.085** | none | token says 0.3 |
| `f2_godel_statement_plaque_8_2` | -2, 10 | 0 | **1.3** | none | token says 0.5 |
| `f2_synthesis_stand_1_3` | 5, 9 | 180 | 0 | subject tt, mode hero | |
| `f2_room_shape_demonstrator_6_5` | 0, 7 | 0 | 0 | plan head, palette neutral, interactive true | |

**Heights raised for reach** (the README allows this; each is a placement change, not a
config change):
- **`bias_from_inside` at 1.085.** `_create_stand()` builds a 1.05 m stand reaching
  local y -1.085. The token's 0.3 buried 0.785 m of the stand in the slab and put its
  controls at 0.32 m. Floor 1's own token for the same artifact uses 1.085.
- **`godel_statement_plaque` at 1.3.** The 0.64 x 0.44 m plaque is centred on its origin
  and would read at knee height at 0.5.
- **`tt` at 1.4.** The 1 x 1.2 m panel is centred on its origin; at 0 it is half buried.

**The `tt` token (`tt:90:qfep_critical:180:0.5`) is a source defect, kept as is.** In
`GridInteractablesComponent.gd`, `_parse_token_params()` has no branch for five fields,
so the grid lane applies no overrides and no config. The museum plan reads rotation 90
and scale **180**. In neither lane does `qfep_critical` reach `codeDisplay.gd`
`apply_grid_config()`, which needs `#tutorial:` or a bare `#key`. The original placement
is therefore a blank display. I kept `config: {}` and scale 1, and used the museum's
rotation (facing 270, turned toward the room). A one-key `config: {"tutorial":
"qfep_critical"}` would show the text, but that is a fix, so it is left to curation.

The source is crowded and that is kept. The visualizer's disc (cell 4,2) lies 0.6 m
under the edge of the word cloud (cell 5,2), separated vertically. The room console
(z 8.2) and the word-positions controls (1, 9.0) stand 1 m apart.

## Real controls (handlers read)

- **`room_shape_demonstrator`** (`algorithms/postfoundationscrisis/room_shape_demonstrator.gd`).
  `_sync_console()` builds the ARRANGE panel when `interactive` is true:
  - Btn_0 to Btn_4 are HEAD, CIRCLE, PAIR, WATCH (panopticon) and VACANT, wired to
    `_choose_plan(_body, choice)`.
  - Btn_5 NEUTRAL and Btn_6 COLOUR are wired to `_choose_palette(_body, choice)`.
  - Both call `apply_grid_config()`, which rebuilds through `_rebuild_now()` and
    refreshes the status plate. Arity matches the one-argument `button_pressed` with
    `bind`. These are **working** controls.
  - Config is read only in `apply_grid_config()`, not from `config_*` metadata. With the
    Void's default order, `_ready()` first builds PAIR with no console, and the config
    call then rebuilds HEAD / NEUTRAL with the console. *Optional* catalog proposal for
    Codex: `room_shape_demonstrator.configure_before_ready = true`, so it builds once.
- **`bias_from_inside`** (`commons/artifacts/bias_from_inside/bias_from_inside.gd`).
  `_create_controls()` gives a COMPRESSION slider, wired to `_on_perspective_changed()`
  → `_apply_perspective()`, which moves both term clouds and the header, and a
  READ / CLOSE button that toggles `_reading`. Both are **working**.
- **`godel_statement_plaque`** (`commons/interfaces/foundations/godel_statement_plaque.gd`).
  `advance_statement()` is real, but it is reached only through
  `Area3D.input_event` → `_on_input_event()` (a mouse left click). That needs viewport
  physics picking, and no `physics_object_picking` is set anywhere in `commons/void/`.
  The XR path, `_on_grabbed()`, is **never connected**, a stub. Expect it to be
  observation only in the Void. It also has hover glow (mouse enter/exit), with the same
  dependency.
- **Observation only:**
  - `excluded_class_visualizer` (`_process` animation; no `exclusion` token, so the
    default `fringe`).
  - `synthesis_stand` (subject `tt`, mode hero). The `dna_synthesis.json` verdict for
    `tt` is *series* on axis `support`. A forced hero pins the far end of the ladder,
    `support=stand`, via `_build_hero()`.
  - The blank `tt` display.

## Focused check (for `focused_checks()` in the shared probe, floor 2)

```gdscript
if level == 2:
	var room: Node3D = station("f2_room_shape_demonstrator_6_5")
	check(tag+"ethics room opens HEAD / NEUTRAL with its console", room.plan=="head" and room.palette=="neutral" and room.interactive and room._console.visible)
	await approach(room, 2.2)   # front is local +z: the console side
	await press(room._panel.find_child("Btn_1",true,false))   # CIRCLE
	check(tag+"CIRCLE rebuilds the miniature", room.plan=="circle")
	await press(room._panel.find_child("Btn_6",true,false))   # COLOUR
	check(tag+"COLOUR changes palette, not plan", room.palette=="authored" and room.plan=="circle")
```

Optionally, `press(station("f2_bias_from_inside_5_2")._controls.find_child("Btn_0",true,false))`
should flip `_reading.visible`.

## Dependencies / risks

- `synthesis_stand` needs `commons/data/dna_synthesis.json` (the `tt` verdict is present).
  The extent of its `tt`-on-stand hero is unmeasured.
- The plaque's mouse picking in the Void is unverified, as above.
- `codeDisplay.tscn` is a `Viewport2Din3D` with XRTools hand-pose areas. Its residency
  and sleep behaviour are untested here.

The folder is frozen after this handoff.
