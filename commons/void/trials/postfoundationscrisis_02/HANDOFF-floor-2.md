# Situated Computation (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**

**Counts:** 7 / 7 inventoried floor-2 IDs, each once; none omitted. Static checks only:
`floor-2.json` substituted into this trial's `rooms.json` in memory validates against
`rooms.schema.json`, and every `#` config key and value is retained. **The head crab needs
an adapter.** Codex's `head_crab_void` already in this folder fits (below). I wrote none;
this batch allows only these two files.

## Placement

The source grid is turned 180°: `x = 5 - cell_x`, `z = 12 - cell_z`. The total yaw is the
source rotation + 180. The entrance (5,1) lands at the arrival (0, 12).

| id | at | facing + museum_yaw | height | config |
|---|---|---|---|---|
| `f2_situated_readout_2_2` | 3, 10 | 180 + 45 | 0 | NW, interactive, footnote |
| `f2_situated_readout_7_2` | -2, 10 | 90 + 45 | 0 | NE, interactive, footnote |
| `f2_forbidden_bands_4_4` | 1, 8 | 180 | 0.95 | none |
| `f2_head_crab_7_5` | -2, 7 | 0 | 0 | detection 14 |
| `f2_situated_readout_2_7` | 3, 5 | 270 + 45 | 0 | SW, interactive, footnote |
| `f2_situated_readout_7_7` | -2, 5 | 0 + 45 | 0 | SE, interactive, footnote |
| `f2_museum_witnesses_11_20` | **0, -7.25** | 0 | 0 | plinth 0, pin 1 |

- **Diagonal readouts.** The source rotations 45/315/135/225 are not in the `facing`
  enum. Each uses the nearest facing plus `config.museum_yaw: 45`, which `floor_content.gd`
  `_build_artifact()` applies to the artifact root (also used in `commons/void/rooms.json`
  and the isosurfaces trial). All four still face the centre of their square.
  `museum_yaw` is the only added config key.
- **Witness bay relocated.** The rigid position (-6, -8) puts the station's own
  14 x 12.5 m receiving plate (`station.gd`, `study == "witness"`) over the south edge of
  shaft A's hole. At (0, -7.25) the plate spans x -7..7, z -13.5..-1.0: 0.5 m from both
  shaft holes and 0.05 m from the columns at (±5, -14). The console (local z 6.2) faces
  the readout room. The museum held this bay as a separate reference room
  (`reference_studies`, rows 10-30).
- **`forbidden_bands` is absent from `em_plan.json`** (added to the map later). It is
  placed from `map_data` at the token's 0.95 m.

## Interactions (handler bodies read)

- **`situated_readout`, working.** `_sync_console()` builds the ADDRESS panel when
  `interactive` is true. Btn_0 FOOTNOTE, Btn_1 COVER (`erasure`) and Btn_2 WITNESS call
  `_choose_address(_body, value)` → `apply_grid_config({"address": value})` →
  `_populate_from_position()` → `_apply_address()`, `_sync_reading()`, `_sync_console()`.
  The verdict comes from config (`_verdict_override`) and wins over position. The footer
  prints `global_position` x, z, so it shows Void coordinates; that is cosmetic.
- **`museum_witnesses` (`station.gd`), working by code.** `activate(i)` calls
  `specimen.control(i)`:
  - 0 VIEWPOINT
  - 1 DELAY (3 / 6 / 1 s)
  - 2 HOLD / RELEASE
  - 3 RETURN CAMERAS

  Portable cameras A and B (`witness_camera.gd`, an XRTools pickable) can be carried;
  C is fixed, D delayed and E held. `find_sources()` walks up to the `em_map` ancestor,
  which the Void floor root carries, and collects `situated_readout` nodes. It needs at
  least three and finds four. Cameras are placed at
  `readout.to_global(Vector3(0.9,1.65,3.5))`, which is safe after relocation.
- **`head_crab` (`commons/hazards/head_crab/head_crab.gd`), hunts but bites through the
  wrong channel.**
  - `apply_grid_config()` maps `detection` to `detect_m` = 14.
  - `_find_target()` finds the Void body through group `player_body`.
  - `_damage()` finds no `em_lethal` and no `take_damage` on the body, so it falls to
    `GameManager.apply_health_damage()`. That drains GameManager's separate health and
    ends in GameManager's own death sequence, not the Void charge bar or a floor-2 retry.
    `final.md` says "enough bites restart the hall".
  - It starts about 5.4 m from the arrival, inside its detection radius, as in the source.
- **`forbidden_bands`: observation only.** It is a physics shell in `_physics_process`
  with no input handlers, and the defaults are `bands` pair and `lean` firm.

**Adapter: use Codex's `head_crab_void.gd` / `.tscn`, already in this folder.** It
overrides `_damage()` to call `void_health.apply_bite_damage(amount)`, the Void
spider's channel, and depletion then reaches `game.die("Charge depleted")`. This is the
fix the bite path needs. Its fresh `MeshInstance3D` root matches the original
`head_crab.tscn`, which is only a MeshInstance3D with the script. `floor-2.json` keeps the
original key `head_crab`, so floor 2 needs the same catalog `scene` override (or the key
the floor-1 merge uses for it). `apply_bite_damage()` already ignores bites while
`suspended` or at zero.

## Focused checks (shared probe helpers)

```gdscript
if level == 2:
	var r: Node3D = station("f2_situated_readout_2_2")
	check(tag+"readout keeps NW and footnote", r._verdict_override=="NW" and r.address=="footnote" and r._controls != null)
	await approach(r, 1.6)
	await press(r._controls.find_child("Btn_1",true,false))   # COVER
	check(tag+"COVER stages erasure", r.address=="erasure")
	var w: Node3D = station("f2_museum_witnesses_11_20").get_node("Study")
	check(tag+"witness found the four readouts", w.ready_sources and w.sources.size()==4)
	# with head_crab_void: place the crab beside the body; Void charge must fall, no GameManager death
	var crab: Node3D = station("f2_head_crab_7_5")
	var before: float = game.health.get_health()
	crab.global_position = game.body.global_position + Vector3(0.5,0,0); await frames(90)
	check(tag+"crab bite drains Void charge", game.health.get_health() < before)
```

## Fit concerns

- **Witness title.** The inscription "THE SAME ROOM, AT DIFFERENT TIMES" sits at local
  y 5.8, above the floor-2 ceiling (slab underside about 5.64 m). It is clipped or hidden.
  The subtitle at 5.4 and the tallest monitor (top about 5.4) fit.
- **Crowding.** Arrival, the readout square and the crab share z 5-12. The witness plate
  and its guard area occupy the south half.
- **`forbidden_bands`** extent is unmeasured (catalog footprint 1 m). It stands on no
  stand at 0.95 m.
