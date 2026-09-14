# The game loop — from launch to the first hall, and every frame after

> Written 2026-09-14, when the game became the endless museum. Palle: "document the game
> loop and what happens when the game starts and until the first map is loaded and we
> start playing … we are now playing the endless museum and the grid is only there as
> part of the endless museum."
>
> Everything here was read out of the code by a mapping pass (boot chain, museum boot,
> 26 autoloads, steady-state loop), then checked by a completeness critic. Citations are
> `file::function`, not line numbers: `commons/scenes/endless_museum.gd` is 23,500 lines
> and moves every day. `EM` means that file. Inferred claims are marked **[I]**.

`doc/ARCHITECTURE.md` still describes the grid-era game (teleporter → SceneManager →
GridSystem). Read this file for how the game actually runs today.

---

## 0. The picture in one paragraph

The engine starts, 26 autoloads are constructed, and the main scene
`commons/scenes/vr_staging.tscn` loads: XR Tools' staging (fades, loading screen, StartXR)
wrapped around the 3D main menu. While the menu waits, staging preloads the museum on a
loader thread. **New Game** and every sequence card call `MainMenu3D::_enter_museum`,
which hands the chapter to `EM::open_at` and asks staging to load the museum scene. The
museum's `_ready` defers `_boot_museum`, which loads its modules, the living registry, the
plan and the bake, sets up the world, and builds **segment 0** — the first hall — in one
synchronous pass on desktop (VR yields between steps). The desktop walker can move from the
first physics tick. The museum drains the queued bodies a few per frame; when the first hall
is complete (or after 15 s) `EM::_finish_initial_loading` releases it — writes the boot
record and **opens the first gate by itself**. From there on `EM::_process` streams halls
ahead of the eye, culls what is far, and polls for edits; `EM::_physics_process` moves the
desktop walker. The museum is the game now: inside it, `GridSystem` is only instantiated for
halls whose map asks for a real simulation grid (the menu's Browse still opens standalone
grid maps — §5).

---

## 1. The ways in

| Lane | How it starts | First hall | Notes |
|---|---|---|---|
| **New Game (staged)** | main scene `vr_staging.tscn` → menu → `_enter_museum("primitives", "Point_One")` | Point_One | the shipped path, desktop and Quest |
| **Sequence card (staged)** | menu → `_enter_museum(sequence)` | that chapter's first hall | same path |
| **Direct dev boot** | run `res://commons/scenes/endless_museum.tscn` (F6 in the editor, or `--path . --xr-mode off res://commons/scenes/endless_museum.tscn`) | the scene's Inspector `start_chapter` / `start_map` | no staging, no menu; what probes and most proof shots use |
| **Test lanes** | `--em-autostart` (clicks New Game after 2.5 s), `--em-die`, `--em-shot-*`, `--em-autopilot`, `--em-map`/`--em-chapter`; the FILE `user://em_autolaunch.txt` skips the menu entirely and loads the museum after 5 s | as asked | see `project_desktop_test_lanes` memory |
| **Reload** | F6, J, L, H, a watched file changing (§6.5) | H, F6 and the watchers: the hall you were in; J/L: the hall you picked | `EM::_reload_museum` — through staging's `load_scene` when there is staging |
| **Return after death** | `death_scene.gd::_on_continue` → staging loads `endless_museum_staged.tscn` | the hall you died in | a brand-new museum instance (§6.4) |

Comparing boot numbers across lanes is only fair when the first hall is the same:
New Game opens Point_One, the direct boot's Inspector currently opens Fractal_Recursion.

---

## 2. Launch → menu

### 2.1 Engine start (boot_ms `engine_pak`)
Servers come up, `res://` is mounted (the `.pck` in an export, the `.godot` cache in an
editor run), project settings are read, and — because `openxr/enabled=true` — OpenXR
starts unless `--xr-mode off` is passed. The engine's file logger opens
`user://logs/godot.log` (`application/run/file_logging`), which records every print from
here on. No project script runs in this window. `BootClock::_init`, the first autoload,
stamps its end.

### 2.2 Autoload construction (boot_ms `autoloads`)
Godot loads, compiles and constructs the 26 `[autoload]` entries in `project.godot` order:
`BootClock`, the two XR Tools autoloads, 22 project managers, `BootClockEnd`. Their `_init`
runs now; their `_ready` does **not** (§2.4). Compiling a script also compiles everything
it `preload`s — including `preload()` written inside a function body — so this window is
mostly GDScript compile:

- `GameManager` preloads `plus.tscn` and `FriendPowerGuard.gd`, and since 2026-09-14
  installs the System Console's engine logger in `GameManager::_init` (§7.3).
- `SoundBank` (`SoundBankSingleton.gd`) has eleven function-body `preload()`s (ten distinct
  sound-generator scripts, ~15k lines), all compiled at boot.
- `NatureRenderer` and `FloraSpawner` preload seven nature-system scripts.
- `SceneNarrator` types members as `GridSystem`, which pulls the grid's script chain into
  the compile even though the museum path builds no GridSystem at boot [I: depth of that
  compile unverified].

### 2.3 Main scene load
`run/main_scene` = `commons/scenes/vr_staging.tscn`, loaded synchronously with its whole
resource tree: XR Tools `staging.tscn` (loading screen, fade, shader cache, StartXR),
`vrStaging.gd` (whose `_XR_CLASS_WARMER` preloads eight XR Tools scripts on the main
thread to dodge the Quest loader-thread class race — `feedback_loader_thread_class_race`),
the splash, the map manual, and `MainMenu3D.tscn`. **`MainMenu3D.gd` preloads
`endless_museum.gd`** only to reach its two static fields, so the museum's 23.5k-line
compile happens here, before the menu is shown. None of this has its own stamp; it falls
inside `staging_load` (staged) or `scene_chain` (direct).

### 2.4 The autoload `_ready` parade
When the tree enters, every autoload's `_ready` runs. This is where the JSON is:

| Autoload | `_ready` work |
|---|---|
| `GameManager` | parses `sequence_index.json`, reads `user://savegame.save`, seeds the console |
| `MapProgressionManager` | scans and parses **all 94** `commons/maps/sequences/*.json` (521 KB) |
| `EcosystemManager` | parses `soft_stages.json` and **re-parses the 94 sequence files** |
| `AdaSceneManager` (`SceneManager`) | parses `map_sequences.json` and **the 94 sequence files a third time** |
| `HazardManager`, `CatalystCapabilityManager` | each parse `soft_stages.json` again, read a `user://` progression file |
| `SoundBank` | parses 66 preset JSONs listed in its manifest |
| `GrammarOperationsManager`, `BiomeAccrualManager` | grammar ops (26 KB); biome contributions + `load()` of 17 layer scripts |
| `ExamGate`, `DeathEffect`, `CatalystCapabilityManager` | connect `SceneTree.node_added` — a GDScript call for **every node added for the rest of the session** |
| `VRLink` | dormant unless `--vr-link` or `user://vr_link.on` |
| the rest | small (settings, empty stores, a timer) |

### 2.5 Staging and the menu
`StartXR` initialises OpenXR, `MainMenu3D` builds its buttons — each `MenuButton3D`
asks `SoundBank` for its hover and click sounds, synthesised in GDScript once and cached
(measured: 66 ms for the first button, 0 for the rest) — and `vrStaging::_ready` shows the
menu. In the menu branch
staging starts **two threaded preloads**: the staged museum scene and `lab.tscn`
(`vrStaging.gd`). The lab is grid-era: nothing on the menu leads to it any more, but its
load competes with the museum's for the loader and disk (measured: removing it changed
nothing, §8). With `user://em_autolaunch.txt` present, staging skips the menu branch
altogether (no lab preload, no `open_at`) and loads the museum after a fixed 5 s.

---

## 3. Menu → museum

1. **The click.** New Game and every sequence card call `MainMenu3D::_enter_museum(chapter,
   map)`: `EM::open_at` stores the chapter and map in statics, the pointers are hidden,
   and `staging.load_scene(MUSEUM_SCENE)` is called (or `change_scene_to_file` without
   staging).
2. **The transition** (`vrStaging` / XR Tools `staging.gd::load_scene`): fade out, the
   loading screen (always — `vr_staging.tscn` sets `force_loading_screen_for_all_transitions`),
   wait for the threaded load if the click beat it, instantiate the museum — the whole
   `base.tscn` player rig plus the Museum node, on the main thread — and add it under
   `$Scene`. Four 0.3 s fades and a 0.1 s delay, about 1.3 s, sit in this transition even
   when the preload is done.
3. **The hand-off.** The museum enters the tree: `EM::_ready` stamps `_boot_t0`, counts
   `museum_entries`, and `call_deferred("_boot_museum")`; `_boot_museum` reads the
   `BootClock`/`BootClockEnd` split as its first act.

---

## 4. The museum's boot, to the first hall

All stamps land in `EM._boot_ms`. At `content_ready` they are written to
`ada_run/em_boot_last.json` **on every entry** (a re-entry overwrites the real boot record);
only the `first_frame` write branches to `em_boot_reentry.json` for entry > 1 — see §7.1. On
desktop, steps 4.1–4.10 are **one frame**: the window does not redraw until segment 0
exists. VR yields five frames between them so the compositor keeps getting frames.

| # | Step (function) | Stamp | What it does |
|---|---|---|---|
| 4.1 | `EM::_ready` prelude | `loading_shell` | layout ledger (`em_layout_walk.json`, 455 KB), args, VR/night flags, the loading shell |
| 4.2 | `EM::_load_modules` | `modules_loaded` | the `commons/scenes/em/*.gd` modules (materials, lighting, environment, detail, props, gate, feel, audio, …) |
| 4.3 | museum data | `museum_data` | templates, crowns, the 2.6 MB relations file |
| 4.4 | `EM::_load_pool` | `pool_done` | **the living registry**: 260 registry files, 11.4 MB of JSON, a `ResourceLoader.exists` per scene, spine order; inside it `EM::_start_at_chapter` resolves the start chapter (flag → resume → menu statics → Inspector → `em_control.json`) — the largest pre-world cost, repaid on every re-entry |
| 4.5 | `EM::_load_plan` | `plan_parsed` | `ada_run/em_plan.json` (2.6 MB) + hand overrides |
| 4.6 | `EM::_load_bake` | `bake_parsed` | `ada_run/em_bake.json` replay + staleness check |
| 4.7 | `EM::_warm_grid_catalogue` | `grid_warm` | only when the plan has a `simulation.grid` row: `GridInteractablesComponent.warm_registry_cache()` so the first simulation-grid hall does not pay the registry scan |
| 4.8 | `EM::_start_at_map`, `EM::_load_guests` | `guests_loaded` | the first pearl/map of the chapter, guest artifacts |
| 4.9 | `EM::_setup_world` | `world_ready` | desktop: walker + camera, costume, pointer, AA, environment and sky (night panorama + moon), `em_feel`, `em_audio` synthesis. VR: only the environment, the `PlayerBoundsCheck` reshape and the plain-hands strip — the XR rig owns the rest |
| 4.10 | `EM::_build_segment` for segment 0 | `segment0_built` | the first hall (§6.2): tile, walls, colliders, deal, dress, lights, save point, gate, ledger and as-built writes |
| 4.11 | stream mode, placement, resume | `boot_tail` | `EM::_walker_drop_in` / `EM::_vr_drop_in` (arrive 4 m above the floor, `EM::_arrival_at`), `EM::_follow_resume` after a reload |
| 4.12 | deferred calls, first physics tick, first `_process` | `first_physics`, `first_frame` | broadphase registration of every new collider happens here; the procedural textures used to generate here (§8) |
| 4.13 | drain to release | `content_ready` | queued bodies at ≤ 8 per frame / 6 ms, the dress item, reach repair; then `EM::_finish_initial_loading` writes the boot record and **opens the first gate** (after 15 s it releases regardless) |

The desktop walker can move from the first physics tick; **4.13 is when the door opens**.
(The loading room was retired on 2026-08-26 — `_boot_cell` is never built.)

**Measured cold boots** (desktop, tier high, Point_One, 1280×720, 2026-09-14, after the
fixes in §8; ms since the museum's `_ready`, direct lane / staged lane):
`loading_shell` 11 / 13 · `modules_loaded` 316 / 520 · `museum_data` 392 / 603 ·
`pool_done` 890 / 1100 · `plan_parsed` 930 / 1200 · `bake_parsed` 970 / 1230 ·
`grid_warm` 1380 / 1650 · `world_ready` 2150 / 2230 · `segment0_built` 3620 / 3500 ·
`first_frame` 3900 / 6300 · `content_ready` 4880 / 8200. Segment 0 is the largest single
step (~1.4 s). Where the first draw of the hall (2.6 s with SDFGI, §8) falls differs by lane:
direct, it is drawn just after `content_ready`; staged, the loading screen keeps rendering, so
the first draw with the hall in it lands between `boot_tail` and `first_frame` [I: the
staged tail is 2.7 s with and without the costume; the frame events that would show the draw
were not captured].

A warm **re-entry** in the same process (F6, a watched file changing) skips most of this
cost — scripts, textures and the SDFGI buffers are already there — and it overwrites
`em_boot_last.json`, so that file after a reload is not a boot measurement.

---

## 5. The grid inside the museum

The grid (`commons/grid/`) is a part of the museum now. Inside the museum it is used in
these places (outside it, the menu's **Browse** → `SceneManager.load_map` and the
`prop_corridor` card still open standalone grid scenes):

1. **Registry warm-up** at boot (4.7): `GridInteractablesComponent.warm_registry_cache()`,
   a static cache, no node.
2. **Simulation-grid halls** — maps whose `map_data.json` sets `museum.simulation.grid`
   (20 maps: 9 colour, 4 tiling, 7 transformation). `EM::_transplant_from_map` creates
   `SimGrid_<map>` (`bare_world`, `skip_player_spawn`, 8 ms interactable budget) and, on
   `build_finished`, `EM::_sim_grid_disarm` switches off its teleport/danger/reset areas
   and `EM::_sim_grid_carry` hands its rides to the museum.
3. **Reactor / pool halls**: `EM::_stamp_simulation` (via `_build_courtyard` →
   `_build_hall` → `_build_sim_pool`) creates `Simulation_<map>` with
   `auto_load_map_on_ready`, then strips its exits.
4. **Map-authored halls** do *not* instantiate a GridSystem: `EM::_derive_map_row` reads
   the three layers itself and the museum re-implements the grid's rules
   (`feedback_museum_reimplements_grid_rules`).

**[I] VR gap:** path 2 sets no `em_vr_content` meta and ignores `_vr_shell_building`, so a
neighbour shell in VR probably builds the full grid and demotion never removes it.

---

## 6. The loop

### 6.1 Every frame — `EM::_process`
In order: guards → `--em-die` timer → VR `_last_ground` → moon (`EM::_aim_moon`) → doll
house canvas / edit gizmo / costume walk / VR showing-hand tick → first-frame boot record
→ *(returns until the core is ready)* → cartridge nodes → desktop lazy segment (a 1.2 s
timer that starts when the core is ready; release neither waits for it nor starts it) →
**autosave** of editor rulings every 0.6 s → **gate** stepping → *(proof
shots return here)* → the eye (VR waits for `EM::_vr_eye`) → **streaming** (§6.2) →
desktop `EM::_follow_check` every 2 s → tier A/B clock → VR wall-read trigger polling →
**`EM::_drain_stamps`** (repair debt first, then ≤ 8 queued bodies, ≤ 6 ms, nearest the eye,
within 50 m) → `EM::_finish_initial_loading` until released → **`EM::_cull_artifacts`**
every 0.3 s (hide beyond 38 m, show within 32 m, 8 per tick) → acoustic space.

### 6.2 Streaming
- **Desktop window.** The distances come from `commons/data/em_layout.json` `stream`, which
  overrides the code defaults in `EM::_load_modules` (shipped: `build_ahead_m` 6,
  `keep_behind_m` 6, `min_segments` 1, `keep_ahead_m` 30, `rebuild_margin_m` 2; the code's own
  defaults are 24 / 10 / 2 / 50 / 6). Build when the eye is within `build_ahead_m` of the
  frontier (one segment per frame, `EM::_build_segment`); free halls more than
  `keep_behind_m` behind (keeping `min_segments`) or `keep_ahead_m` ahead
  (`EM::_stream_free`); walking back rebuilds a freed hall from its cursor snapshot
  (`EM::_stream_rebuild`).
- **VR three-shell.** `EM::_vr_single_map_stream` keeps previous / current / next as
  architecture shells; crossing into a hall demotes the old one (`EM::_vr_demote_segment`:
  its bodies are freed, its queue items dropped) and promotes the new one
  (`EM::_vr_promote_segment`: every remembered body recipe goes back on the stamp queue).
- **A build** (`EM::_build_segment`, synchronous): pick the plan row → derive the map row
  (re-reads `map_data.json`) → passages → tile, floor, walls, colliders → deal → dress
  (queued when replaying the bake) → lights, side rooms, forecourt, courtyard → save point
  → gate (segment 0 only) → hand adds → numbering → as-built. It writes
  `em_layout_walk.json` (twice), `em_inventory.json`, `em_built*.json`,
  `em_pack_report.json`, and when due `em_bake.json`, `em_live_footprints.json`,
  `em_adoptions.json`.

### 6.3 The gate and the next hall
Only the first passage has a door (`em_gate.gd::build`: sealed `station_door` + palm
scanner), and not in proof shots, autopilot or studio runs, or when the map sets
`museum.gate=false`. **It opens by itself when the first hall is released**
(`EM::_finish_initial_loading` → `EM::_open_gate`, or at the 15 s release). Before that it
also opens on the palm scanner, a hand or eye within `gate.reach_m` of the scanner (1.5 m in
`em_layout.json`), standing 3.5 m from the door for 6 s, a desktop click, `E` within 5 m in the
doll house, or a resume. It steps open over 1.6 s (`em_gate.gd::step_open`). Later halls are joined by carved passages
(`EM::_authored_passages`), not doors. What a hall contains comes from its plan row: a
map-authored hall transplants its map (`EM::_transplant_from_map`), otherwise the template
dealer places the chapter's pearls (`EM::_deal_from_plan`).

### 6.4 The player's body across halls
- **Save points**: one per hall. `EM::_save_point_now` picks the deepest unburned one
  behind the eye, or the start of the current hall (`EM::_hall_start_point`) rather than
  evict you into the previous one.
- **The museum's own death** (`EM::on_lethal_touch` → `EM::_museum_death`): the laser (both
  lanes); fire basins and hazard cells on **desktop only** — `EM::_basin_burned` and
  `EM::_hazard_touched` ignore any body but the walker, and VR has no walker; and GameManager's
  "fell" fallback when `death_handover` cannot name a hall. Desktop: the splatter layer, moved
  to the save point behind the black. VR: the rig dropped at the save point under a veil. A
  6 s watchdog guarantees release.
- **The health bar** (spiders, crabs, silhouettes — creatures call `EM::walker_bitten`
  directly, other damage arrives through `GameManager::apply_health_damage`): one bite per
  0.55 s; three bites empty the bar;
  `GameManager::_handle_player_death` → `EM::death_handover` stores the hall →
  `DeathEffect` → `death_scene_staged.tscn` → *continue* loads a **new museum instance**
  at that hall. Save points, burned saves and freed halls do not survive it.
- **Falling** is not a death: desktop `EM::_catch_if_fallen` sets the walker back on a save
  point below y −6; VR relies on `PlayerBoundsCheck`.

### 6.5 Reloads (all rebuild from scratch)
What a reload keeps is decided by what it writes to `ada_run/em_control.json` and by the
start-chapter precedence in `EM::_start_at_chapter`: **flag → resume (`resume_eye` present) or
travel (`travel: 1`, one-shot) → menu statics → Inspector `start_chapter` →
`em_control.json`**. Both shipped scenes set an Inspector chapter (`endless_museum.tscn`:
fractals; `endless_museum_staged.tscn`: primitives), which is why a door that writes only the
control file would land where the scene says.

| Trigger | Function | Writes | Where you land |
|---|---|---|---|
| H (doll house ↔ walk) | `EM::_doll_toggle` | `EM::_resume_doc`: chapter, `first_map` + `_resume_hall` (the hall), eye, yaw, gate, doll house flipped | the same hall and spot — `EM::_follow_resume` builds forward up to 12 halls to reach it |
| F6 | `EM::_follow_reload` | the same `EM::_resume_doc`, doll house kept | the same hall and spot |
| the plan file changed (2 s poll, 2.5 s settle) | `EM::_follow_check` → `EM::_follow_reload` | same as F6 | same as F6 |
| rulings or the current hall's `map_data.json` changed **by another writer** (1 s poll) | `EM::_edit_watch` → `EM::_follow_reload` | same as F6 | same as F6. The museum's own ruling saves are recorded by `EM::_edit_watch_own_write` and do not rebuild; its own map writes (paint, passage, config) do, on purpose |
| J (jump list), L (spine strip) | `EM::_jump_go`, `EM::_spine_travel` | chapter + map + `travel: 1` | the target hall's start (its pearl's head hall); `travel` is spent on arrival |
| death | GameManager → death scene | nothing (statics `menu_chapter`/`menu_map`) | the hall you died in, at its arrival point, in a new instance |

Every reload goes through `EM::_reload_museum`: under XR Tools staging (the shipped desktop app
and the Quest) it asks staging to `load_scene` the museum's own scene, as the death scene's
continue does; without staging it reloads the current scene. Before 2026-09-14 every door
called `reload_current_scene`, which under staging reloaded `vr_staging.tscn` — the menu.
A hall without a map (a template hall) cannot be named, so F6 from one returns to its
chapter's start. Every reload except death flushes unsaved rulings first (`EM::_edit_flush`).
VR has no reload path except death. Tested by `commons/testing/probe_reload_resume.gd` (direct
lane: H, F6, J, L; staged lane: F6, J).

### 6.6 Input (desktop)
J jump list · F7 environment tier · F6 follow reload · H walk → iso → plan → walk · L spine
strip · O open the artifact on the web · TAB editor · SPACE jump (double jump) · Esc release
the mouse · **F12 System Console** (§7.3). Mouse: click reads a wall work / presses the
scanner / cycles a pattern; double-click opens the page. The editor and doll house have
their own maps (`EM::_edit_handle_key`, `EM::_dress_key`). In VR the XR Tools rig owns
locomotion; the museum reads trigger clicks and hand proximity.

### 6.7 Autoloads that keep working during play
`MushroomHand::_process` (always, even paused), `CatalystCapabilityManager::_process`
(lease tick; launcher check on an interval), `DeathEffect::_process`, `VRLink` when armed,
`vrStaging::_process` (map-loader shortcut, `user://reload_signal.txt` every 0.5 s),
`NatureRenderer`, `FloraSpawner` and `SubtitleManager` (`_process`, mostly early returns), and
three `node_added` listeners (`ExamGate`, `DeathEffect`, and `CatalystCapabilityManager`, which
connects its deferred) that run GDScript for every body the museum stamps. `StuckDetector` is
stood down by the museum.

---

## 7. Instruments

### 7.1 The boot record
`ada_run/em_boot_last.json` holds `boot_ms`, written at `content_ready` on every entry
(`em_boot_reentry.json` only receives the `first_frame` write of a re-entry). Two different
clocks are in it (all read in `EM::_boot_museum`):

| Key | Measures |
|---|---|
| `engine_pak` | engine start → `BootClock::_init` (engine + pak mount + OpenXR) |
| `autoloads` | `BootClock::_init` → `BootClockEnd::_init` (autoload construction and compile) |
| `staging_load` (staged) | `BootClockEnd::_init` → `vrStaging::_ready` — the main scene load and the autoload `_ready` parade |
| `staging_to_museum` (staged) | `vrStaging::_ready` → museum `_ready` (includes menu time, and `--em-autostart`'s 2.5 s) |
| `scene_chain` (direct) | `BootClockEnd::_init` → museum `_ready` |
| `entry` | a **counter** (`BootClockEnd.museum_entries`), not milliseconds |
| `loading_shell` … `content_ready` | ms since the museum's `_ready`, the steps of §4 |

Caveats found while writing this: every re-entry overwrites the real boot record;
`modules_pool` duplicates `museum_data`; in VR `first_frame`/`first_physics` stamp inside the
yielding boot and are not comparable with desktop.

### 7.2 The engine log and what reads it
Every print goes to stdout and `user://logs/godot.log`. Some lines are **machine-read** and
must stay byte-compatible: `tools/spine_run.py` parses `[em-plan] … stamped …`,
`[endless_museum] seg N = …` and `deal: N objects across …`; `spine_run.py` and
`tools/museum_wizard.py` read `shot composed at` and `proof shot ->`; the encyclopedia's
trunk route reads `LOOK at`; `tools/run_em_gates.py` reads PASS/FAIL verdicts. The museum's
bracketed tags (`[em-seal]`, `[em-walk]`, `[em-gate]`, `[em-death]`, …) are its diagnostics.

### 7.3 The System Console
Since 2026-09-14 `GameManager::_init` registers `commons/monitor/system_console_logger.gd`
with `OS.add_logger`, so **every print, printerr, push_warning and push_error** — from any
thread — also lands in `GameManager.console_messages` (last 200). Desktop: **F12** toggles
`commons/monitor/system_console_overlay.gd` (Ctrl+L clears). VR: the left-hand
`commons/monitor/VRconsole.tscn` panel reads the same buffer (the museum's plain-hands rig
strips it by default — see `em_layout.json` `rig.wrist_tools`). stdout and godot.log are
unchanged.

---

## 8. Where the time goes, and what was done about it

Measured 2026-09-14 on the development PC (RTX 3070), desktop, tier high, first hall
Point_One, window 1280×720. **Wall** is process spawn → the museum writes `content_ready`;
two runs per row, the game killed 6 s later; nothing else running but the editor.

| Step | New Game (staged, `vr_staging.tscn --em-autostart`) | Direct (`endless_museum.tscn`) | museum `content_ready` staged / direct |
|---|---|---|---|
| baseline (morning) | 22.3 s (the very first launch: 25.2 s) | 15.1 s | 13.3 s / 9.8 s |
| print sweep + System Console | 22.2–23.2 s (log 1,744 → 585 lines) | 14.6 s (log 1,557 → 530 lines) | 13.6 s / 9.7 s |
| **noise textures off the main thread** | **17.6 s** | **9.8 s** | 8.7 s / 4.9 s |
| hidden VR console builds no rows | **17.0–17.4 s** | — | 8.2 s / — |

Errors and warnings were counted in every run's log: 0 SCRIPT ERRORs, and the ERROR/WARNING
counts of the baseline (4/16 staged, 3/13 direct) never changed.

**Content ready is not first pixels.** In the direct lane the first frame that shows the
hall is drawn just *after* `content_ready`, and with SDFGI that draw costs ~2.6 s (below) —
add it when you think about what a person waits for. In the staged lane that draw falls
before `first_frame` and is already inside the number.

### How the costs were found
The stamps (§7.1) cover the museum's own steps; they could not split the 5–8 s between
`boot_tail` and `first_frame`, a stretch with no physics tick, no idle frame and no draw.
`commons/testing/probe_boot_frames.gd` records every tick, draw, added node and log line,
and queues a **deferred marker** behind every added node and log line. Deferred calls run
in the order they were queued, so the first marker that runs late names the moment the slow
call was queued. That found the textures in two runs. For effects, the probe variant
switches one Environment feature off as the WorldEnvironment enters the tree.

### Fixed
1. **~20 procedural textures generated on the main thread** (5.1 s). `em_materials.gd`
   warms its floor/wall/marble/oak `NoiseTexture2D` at boot, believing they generate on a
   worker thread. A NoiseTexture2D's *first* image is generated synchronously by the engine
   (`first_time` in `_update_texture`), from a deferred call. `em_materials.gd::_tex` now
   assigns the noise with `set_deferred`: the first update finds no noise and the real one
   runs threaded. Isolated: 4,264 ms of main-thread block → 5 ms, images ready after 505 ms,
   identical pixels. **Any other NoiseTexture2D created at boot has the same trap** (11
   other scripts create them; not swept).
2. **The VR console built a UI row for every log line while hidden** (~6 ms a row, ~0.4 s
   staged). `VRconsole.gd` builds rows only while its 3D host is visible.
3. **The museum rebuilt itself after its own ruling saves** (`EM::_edit_watch_own_write`).
   Not a boot cost, but a 10 s rebuild after an edit.
4. **A freed hall errored the utility seat** (`EM::_utility_seat`), and the segment log
   line now names its map.

### The big one left: SDFGI's first frame — Palle's call
With the high tier, the first frame that contains a hall costs **2.6 s** to draw. Switching
features off one at a time: SDFGI off → 86 ms; volumetric fog, SSIL or SSR off → no change.
Warming SDFGI on an empty scene first (215 ms) makes the museum's first draw 112 ms but moves
the cost into the boot (content_ready +2.9 s): it scales with the geometry, so it cannot be
pre-paid for free. `--em-quality=perf` draws the first frame in 71 ms. Options, all visual,
none taken:
- fewer SDFGI cascades or a larger `min_cell_size` (`em_environment.gd` `SDFGI_MIRROR`: 4 cascades, 0.2 m);
- start SDFGI a moment after the visitor is released (the 2.6 s hitch moves into play);
- keep the loading cell up until the first high-tier frame has drawn (same wait, but it
  reads as loading, not frozen).

### Checked and not worth changing (measured)
- menu button sounds: 66 ms once, cached;
- the menu's threaded `lab.tscn` preload: 17.0 s with it, 17.0 s without;
- the 94 sequence files parsed three times at autoload `_ready`: **not measured separately** —
  the whole autoload `_ready` parade sits inside `staging_load` (~2.1 s) — so left alone;
- removing 4,600 prints: ≤0.5 s (direct), inside run-to-run noise (staged).

### Still open (from the mapping pass, not measured here)
- `EM::_load_pool` re-parses 11.4 MB of registry on every **re-entry** (~1 s); a static cache
  keyed by file mtimes would make F6/follow reloads faster.
- A hall whose map is newer than the bake is measured live every boot
  (`[em-bake] … the map moved since the bake`); `python tools/em_bake.py` after map edits
  keeps the first hall replayed.
- External writers to `em_overrides.json` rebuild a running museum (four times in the
  16:31 session) — by design, but worth knowing when another session edits rulings while
  someone plays.
- The staged lane spends ~0.3 s longer than direct on each early museum step (loading
  screen rendering beside the boot) and 2.5 s in `--em-autostart`'s fixed wait.
