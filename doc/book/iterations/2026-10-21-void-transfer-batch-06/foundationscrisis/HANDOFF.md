# Foundations Crisis → Void transfer: HANDOFF

Placement owner: Claude Opus, 2026-10-21. Coordinator acceptance completed below;
physical headset and curation remain pending. `python tools/audit_void_transfer.py foundationscrisis`:
**74 / 74**. Schema: valid.

**Counts:** 12 / 12 placed: Euclid_Parallel 4 on floor 1, NonEuclidean_Spaces 8 on floor 2.
None omitted. There are no floor captions; provenance lives in `source-inventory.json`.
**One movement adapter**, the non-Euclidean wing, is installed through the catalog.

## Placement

Each floor is its source grid turned 180°, 1 cell = 1 m: `x = cx - cell_x`,
`z = cz - cell_z`, `facing = token_rotation + 180`. Height is the museum support plus the
token's y offset, and scale comes from the token. Euclid uses cx 5, cz 12; NonEuclidean
uses cx 8, cz 12. Every body stands between x -6.3 and 6.5, clear of both shafts and
the A landings.

| id | at | facing | height | config |
|---|---|---|---|---|
| `f1_science_screen_3_5` | 2, 7 | 0 | 1.5 | mode grid |
| `f1_euclid_postulates_plaque_5_7` | 0, 5 | 0 | 1.7 | lesson_controls on |
| `f1_parallel_lines_3_9` | 2, 3 | 180 | 1.2 | none |
| `f1_angle_sum_triangle_7_9` | -2, 3 | 0 | 1.2 | none |
| `f2_film_curvature_triangle_4_1` | 4, 11 | 180 | 0 | plinth 0, pin true |
| `f2_triangle_curvature_workbench_11_2` | -3, 10 | 0 | 0 | model plane |
| `f2_noneuclidean_wing_13_4` | -5, 8 | 180 | 0 | pin true, plinth 0 |
| `f2_curvature_slider_2_9` | 6, 3 | 180 | 0.5 | witness surface |
| `f2_elliptic_surface_4_11` | 4, 1 | 180 | 0.5 | none |
| `f2_poincare_disk_5_11` | 3, 1 | 180 | **1.8** on a 1 m cube | none |
| `f2_hyperbolic_surface_2_12` | 6, 0 | 180 | 0.5 | none |
| `f2_riemann_sphere_7_13` | 1, -1 | 180 | **1.8** on a 1 m cube | none |

## Fit exceptions

- **Terrain is not rebuilt.** Both maps are terraced: structure 0 is a museum hole, 2 a
  1 m raised floor, 3 a wall, and NonEuclidean has four `wp` ramps. Only the two raised
  cells under the disk and the sphere (museum `support_height_m` 1.0) are 1 m
  construction cubes. The slider, elliptic and hyperbolic surfaces stood over hole cells
  at 0.5 m in the museum; here they stand at 0.5 m over the slab.
- **The wing is missing from `em_plan.json`.** It was added to the map after the plan was
  generated, so the museum never stood it. It is placed from `map_data` at cell (13,4).
  `noneuclidean_wing.gd` `build()` repositions it to museum hall (13,1,7) only when
  `get_parent()` carries `em_map == "NonEuclidean_Spaces"`. In the Void the parent is the
  mount, so the rooms.json position holds.
- **The wing's remote spaces sit far above and beside the tower.** In world terms they
  span y 48 to 183, x about -197 to 27, at z 8. They are invisible until visited, but
  their colliders always exist. The editor export may include them.
- **Not transferred.** The `tt:` text utilities and `sub:map` (utilities, not artifacts).
  Also the tutorial learner reconstructions that `final.md` describes: Euclid's carried
  triangle with an angle readout and gold guide, and NonEuclidean's tutorial
  PLANE/SPHERE study with lifted points. Neither is a map placement.

## The adapter: `noneuclidean_wing_void.gd` (extends `noneuclidean_wing.gd`)

**The source problem.** All visitor movement goes through `move_together()` →
`shift_player()`. That covers `enter_by_door`, `return_by_door`, `visit`, `leave`, the
corridor wrap in `_process`, `overlapping_rooms.gd` `cross()`, and
`repeating_gallery.gd`. `shift_player()` moves only an Endless Museum player, found as an
ancestor with `_eye_pos`. In the Void `museum == null`, so it returned, and the door
showed a room 60 m overhead without carrying the visitor there.

**The changes.**
1. `shift_player()` runs the original first. If `museum == null`, it then moves the Void
   player by the same delta: `PlayerBody.teleport()` in VR, `body.global_position +=` on
   desktop. It then calls `game.rebase_player_motion()`, so the 60 m return is not a
   "fell more than one floor" death.
2. The wing joins `void_floor_extension`, and `contains_visitor(p)` is true when
   `to_local(p).y > 20`. That keeps floor 2 live while the visitor is in a remote space.
3. The wing joins `void_exterior_walk`, so the chamber decks count as support beyond the
   slab footprint.

`eye_position()` is unchanged: with no museum it reads the viewport camera.

**Focused assertions for the shared probe** (`wing` is the artifact at mount
`2/f2_noneuclidean_wing_13_4`):

```gdscript
check("wing adapter loaded", wing.get_script().resource_path.ends_with("noneuclidean_wing_void.gd") and wing.built)
check("wing region", wing.is_in_group("void_floor_extension") and wing.contains_visitor(wing.to_global(Vector3(0,60,0))) and not wing.contains_visitor(wing.to_global(Vector3(0,1.6,2))))
var deaths = game.deaths
wing.visit(0); await frames(60)
var e = wing.rooms[0].to_local(wing.eye_position())
check("visit carries the visitor", absf(e.y-1.6) < 0.3 and absf(e.x) < 7 and absf(e.z) < 6 and game.floor_stream.focus == 2 and game.deaths == deaths)
wing.visit(1); await frames(120)  # chamber 2 lies ~37 m outside the slab in x
check("outside chamber is supported", game.deaths == deaths and not game.recovering)
wing.leave(); await frames(90)
check("return is a cut, not a fall", game.deaths == deaths and game.checkpoint == 2 and wing.to_local(wing.eye_position()).distance_to(Vector3(0,1.6,1.8)) < 0.4)
```

On desktop, also walk through the frame from the south side, from world z < 8 toward
z > 8. Expect `wing.current == 0`, then walk back out to get `current == -1`.

## Real controls (function bodies checked)

- **`euclid_postulates_plaque`, lesson_controls on.** NEXT calls `next_postulate()`, whose
  `current_postulate` setter calls `_update_display()`. GOLD calls `_toggle_emphasis()`
  and redraws. Its mouse `_input` is disabled whenever lesson_controls is on.
- **`triangle_curvature_workbench`.** The HOST slider has three detents, Disk / Plane /
  Sphere (`_on_slider_changed` → throttled refresh). `model:plane` opens on the Plane
  detent. This slider is the "PLANE / SPHERE / DISK" choice in `final.md`.
- **`curvature_slider`, witness surface.** The CURVATURE K slider calls `_on_slider_moved`,
  which rebuilds the specimen and label. As the text says, it governs only its own sketch.
- **`film_curvature_triangle`.** Buttons in `concept_monitor.gd` call
  `film_stage.gd`: PAUSE `toggle_pause()`, REPLAY `replay()`, STEP `step_sample()`,
  TURN VIEW `next_route()` (orbit). It activates on gaze within 14 m.
- **`noneuclidean_wing`.** Walk-through door; carried `CarriedPoint` (grip, trigger =
  `trigger()`). Each chamber has Previous / Museum / Next / Recall point. Chambers 3-7
  add Reset. Chamber 3 adds One arc, chamber 4 Disk / Klein, chambers 5-6 Step forward
  and Left / Right / Up / Down, chamber 7 Launch. Chamber 1 holds the overlapping-room
  portals. All handlers have bodies.
- **Observation only:** `parallel_lines` (no script on the root), `angle_sum_triangle`
  (labels are supplied, as `final.md` says), `poincare_disk` (pulsing geodesics),
  `elliptic_surface`, `hyperbolic_surface`, `riemann_sphere`.
- **`science_screen#mode:grid`** finds no `grid_size` sibling under a Void mount and
  shows its fallback.

## Unresolved

- The wing's portal preview uses stencil materials (`build_portal`). Representative
  native Mobile views were captured; physical headset review is pending.
- Remote chambers sit tens of metres above the open sky with no Void atmosphere around
  them. Lighting and comfort there are uncurated.
- Leaving a chamber by falling off its edge triggers the normal Void fall death and
  retry, which rebuilds the wing.
- The workbench's standing area is about 1.2 m from the wing frame's back.

Commands:

```bash
python tools/audit_void_transfer.py foundationscrisis
```
```bash
python tools/export_void_trial.py foundationscrisis
```

## Coordinator acceptance

87 shared/native and focused checks pass with process exit zero. NEXT and GOLD were
pressed with mouse and synthetic tracked XR. The HOST slider API callback, visits
to the first two remote rooms, outside support, return, residency and retry pass
in both rigs. Physical walk-through of every portal/chamber and a real headset
remain pending. Native measured preview geometry spans y -12.4 to -6.0, but this is a stencil-masked
virtual room, not added walkable geometry. The web preview hides that masked copy
and shows the real entry frame, since GLB cannot preserve the portal stencil.
The proposed catalog adapter is installed.
