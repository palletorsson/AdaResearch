# Cellular Automata → Void transfer: HANDOFF

Owner: Claude. Written 2026-10-21. Batch: `doc/void-transfer/2026-10-21-batch-01/`.
Stage: **placed**. Native-tested: no. Headset-tested: no. Curated: no.
Nothing in this folder has been run in Godot (transfer rule: no parallel Godot). Every
claim below about runtime behaviour is read from the scripts, the museum plan rows and
the floor contract; `probe.gd` is the list of claims written as checks, unrun.

## Changed files (all inside `commons/void/trials/cellularautomata/`)

| file | change |
|---|---|
| `rooms.json` | 8 + 2 original placements, 12 provenance floor captions (`route`), one glass-lidded `basin` on floor 2 |
| `layout.json` | text only: `status`, `floor_roles` titles, `route_note`. Frame, levels, shafts, columns, descent untouched |
| `source-inventory.json` | every placement `status: placed` with a `void` record (floor, rooms id, position, height, facing, station, config); a `transfer` block states the placement rule and what was not transferred |
| `transfer-status.json` | stage, counts, adaptations, dependencies, checks run |
| `catalog-additions.json` | four **optional** footprint proposals for the lab-editor boxes; nothing is needed to load |
| `probe.gd`, `run_probe.py` | native probe (desktop + synthetic XR + bounds report + screenshots) and its runner, authored without a run |
| `HANDOFF.md` | this file |

Untouched: `playable.json`, `catalog.json`, `reviews.json`, `briefs.json`, `line_parts.json`,
every source map, text, scene and script, the main tower, the batch directory. No git
operations. `trial.tscn` is the scaffold as Codex left it.

## Placement rule

Each source grid is turned **180 degrees about its own centre**, one cell = one metre,
and dropped into the central bay of its floor:

```
void_x = cx - cell_x        void_z = cz - cell_z        facing = (token_rotation + 180) mod 360
CA_Introduction   13 x 19   cx = 6, cz = 9
CA_ElementaryRules 13 x 14  cx = 6, cz = 6.5
```

Why the turn and not a plain shift: the shared spawn in `playable.json` is (0, 12) on both
floors, at the south end. The original visitor spawned at row 0 (north) and walked +z. After
the turn the original entrance line lies at z = 9 (floor 1) and z = 6.5 (floor 2), two to
three metres north of the spawn, so a visitor walks into each hall the way the original
visitor did, and every left/right relation in the chapter texts is preserved (a rotation,
not a mirror). The original exit lines are at z = -9 and z = -6.5; both shafts are then
beside the visitor at mid-hall. A plain shift (`void = cell - centre`) would put the
rule-110 end of the hall at the spawn; if that is wanted, negate both coordinates and
subtract 180 from every facing.

Heights follow the museum lane (`em_plan.json` rows 91 and 92: every body `support_height_m
0.0`, the rug `offset 0.025`, the explorer `offset 1.04`), which is also how the Void places
imported bodies (origin on the deck, no auto-ground). One exception, listed under
adaptations: `ca_showcase` is raised 0.5 m.

## The ten placements

| rooms id | map, cell | original token | void x, z | facing | height | station | config passed |
|---|---|---|---|---|---|---|---|
| `f1_synthesis_stand_2_3` | CA_Introduction (2,3) | `synthesis_stand#subject:dark_sphere#mode:hero` | 4, 6 | 180 | 0 | SE | subject, mode |
| `f1_dark_sphere_5_3` | CA_Introduction (5,3) | `dark_sphere` | 1, 6 | 180 | 0 | SE | none |
| `f1_persian_rug_4_4` | CA_Introduction (4,4) | `persian_rug:0:0.025#plinth:0` | 2, 5 | 180 | 0.025 | SE | plinth |
| `f1_ca_rule_explorer_10_5` | CA_Introduction (10,5) | `ca_rule_explorer:270:1.04#study:neighbours#rule:90#speed:4#plinth:0#room:ring` | -4, 4 | 90 | 1.04 | SW | study, rule, speed, plinth, room |
| `f1_langton_swarm_10_9` | CA_Introduction (10,9) | `langton_swarm` | -4, 0 | 180 | 0 | SW | none |
| `f1_line_network_ca_10_12` | CA_Introduction (10,12) | `line_network_ca:0:0#size:2.0#study:arrival` | -4, -3 | 180 | 0 | NW | size, study |
| `f1_ca_showcase_3_14` | CA_Introduction (3,14) | `ca_showcase` | 3, -5 | 180 | **0.5** | NE | none |
| `f1_rule110_computer_10_16` | CA_Introduction (10,16) | `rule110_computer` | -4, -7 | 180 | 0 | NW | none |
| `f2_structure_growth_6_6` | CA_ElementaryRules (6,6) | `structure_growth:0:0#study:states#plinth:0#room:neighbours` | 0, 0.5 | 180 | 0 | SE | study, plinth, room |
| `f2_dark_sphere_10_9` | CA_ElementaryRules (10,9) | `dark_sphere:0:0#plinth:0` | -4, -2.5 | 180 | 0 | NW | plinth |

Scale is 1 everywhere. Config values are the token's own strings, unchanged; `plinth:"0"`
is passed through because the original token carries it (the Void ignores it, the grid
built nothing for 0, and `dark_sphere` rebuilds once on any non-empty config exactly as it
did under the grid and museum lanes). Station is the nearest supply corner; these floors
are `abstract`, so no leads or conduits are drawn.

How the config reaches each body in the Void (`floor_content._build_artifact`, trial path):
`config_<key>` metadata is stamped before `add_child`, so `ca_rule_explorer._ready` reads
`config_study`/`config_rule`, `neighbour_study` reads `config_room`, and
`CellularAutomata3D_Flexible._ready` mounts the states study and `structure_study` reads
`config_room`. `apply_grid_config` is then called after `add_child` for every non-empty
config: the explorer takes `rule`/`speed`, the network takes `size` and enables the arrival
history (`is_node_ready()` branch), the stand rebuilds with subject/mode, the growth and rug
see no axis change and keep their first build. None of the ten needs
`configure_before_ready`.

## Adaptations, each visible and reversible

1. **180-degree turn of both grids** (above). Relational only; no body changed.
2. **`ca_showcase` height 0.5.** Its twelve sphere grids are 20 x 20 x 20 at 0.15 m pitch,
   centred one metre above the origin, so the lowest half-metre sat below the museum deck
   (registry measurement: y from -0.5). The grid lane's auto-ground would have lifted it by
   the same 0.5. Set `height` back to 0 to reproduce the museum exactly.
3. **Glass-lidded basin under the volume** (floor 2 `basin`, depth 1, four 1 m strips
   covering the map's structure-0 cells rows 4 to 7, turned with the grid). The museum built
   that region as a hollow with the volume above it ("A small volume waits above the opening
   in the floor. Walk along its rim."). The Void's own basin reproduces the opening while the
   lid at y = 0 keeps the floor walkable. Delete the `basin` key to get a flat slab; set
   `glass: false` for an open 1 m pit (then a fallen visitor needs a way out, not provided).
   The console foot (world 1.08..2.22, 3.06..3.66) stays on the rim; the basin's south edge
   is z = 3 and coincides with the slab-strip boundary, which `Basin.slab` treats as a
   non-intersection (touching rectangles). If the slab tiling misbehaves there, move the
   southmost strip to `[-1.5, 2, 3, 0.98]`.
4. **Twelve provenance captions** as `route` entries (floor text, trial floors only): the
   map name and the source cell + token beside each body. Delete the `route` arrays to remove
   them; they are not chapter text.

No local wrapper scripts or scenes were needed; no artifact was replaced, scaled, clamped
or re-configured.

## Not transferred (every omission)

- **The interior partitions of CA_Introduction**: the structure-4 column at x = 7 (rows 1-2,
  6-10, 14-16), the row at z = 7 (x 1-4), the strip at x = 1 (rows 3-7) and the two
  blocks at (3,1), (4,1). These made the rug room, the board's corridor and "the opening
  beside the board". `rooms.json` supports up to twelve `walls` per floor; the sources are
  the map, so a curator can add them from `map_data.json` (turned: `x' = 6 - x`, `z' = 9 -
  z`). Left out because the brief asks for the collection first and walls change the
  walking routes.
- Spawn and teleporter utilities (the trial uses the shared spawn and the shafts),
  lighting, sky, `nature_layer.json`, the museum's open roof and colonnade dressing.
- `grid_substrate_runner`: already removed from the map before the inventory was generated
  (`artifacts.md` records why). Not in the ten; not re-added.
- Of the ten, **none** was omitted. 10 of 10 stand on the floors.

## Uncertain bounds for the native pass

Floor-local predictions from the scripts; `probe.gd` writes the measured AABBs to
`measure.json`. Where measured and predicted disagree, the prediction is wrong.

| body | predicted floor-local extent | what is uncertain |
|---|---|---|
| explorer desk + hand rail | x -4.92..-2.55, z 3.11..4.89, legs to the floor, board top at 1.05 | the desk's `box(..., solid=true)` colliders sit under the mesh; confirm the desk cannot be walked through and the chair-height rail (y 1.14) is not a collider |
| stored-row ring | centre (-3.5, 2.4), radius 1.65 (+0.03 outline), rows from 1.83 (labels) to 4.30 m | overhead geometry over the aisle; the lowest labels at 1.83 m clear a 1.7 m capsule but not necessarily a tall headset view; the ring crosses nothing solid |
| NEXT GENERATION / CA RULES panels | x about -2.8 and -3.05, y about 1.06, tilted -30 degrees, facing +x | the exact face normal of a RackTemplates panel; the XR press in the probe approaches from +x |
| line network (fitted) | x -5..-3, y 0.3..2.3, z -4..-2; plinth at (-4, -1.88), 0.64 x 0.88 x 0.3; REPLAY button at y 0.95 facing +z | the 2 m fit is applied on the first draw; before the first `update_visualization` the tangle may be unfitted for a frame |
| ca_showcase | x 1.5..4.5, y 0..3.25, z -6.5..-3.5; info panel 2.5 x 1.5 at y 2.5 | the twelve systems are built differently (3D sphere grids, 2D platform grids, a road network, terrain); the -0.5 bottom is from the measured AABB of the whole, so a single system's floor contact may differ. Cycle all twelve and read the minimum y |
| synthesis stand (hero) | slab 1.34 square at (4, 6), plaque at (4, 5.17); subject hush + swarm, small | slab width comes from the registry `measurements.aabb_size` of dark_sphere (0.84) |
| rug + orb | rug 2.56 x 3.84 at y 0.025; orb at (1, 6) stands on the rug's edge, halo disc at y 0.01 | the orb's `_gest_arm` adds a catalyst collision sphere (radius about 0.42); a walker brushing the rug's south-west corner may bump it. Original overlap, kept |
| langton, rule110 | 1.08 x 1.56 x 0.35 and 1.0 x 1.01 x 0.45, decks at the floor | `_box` meshes in `embodied_prop` carry no colliders as far as I read; confirm |
| structure growth | volume x -1.6..1.6, y 0.06..3.26, z -1.1..2.1; console (1.65, 1.05, 3.36) facing +z; neighbour room x 2.46..5.24, y 0.11..2.89, z -2.69..0.09; hand plate at (1.65, 0.8, 4.05); state point parked at (1.65, 1.12, 4.05) | the room's cubes and the volume have no colliders by design ("their appearance is not a promise of footholds"); the console foot and stem are solid |
| basin | strips x -1.5..1.5 (rows 4, 5, 7) and -1.5..0.5 (row 6), z -1..3, depth 1, glass lid | slab-tiling edge case at z = 3 noted above; the lid is a `StaticBody3D` named `Glass` with `void_floor_index` 2 |

Both shafts (x in ±[7.5, 12.5], z in [-3, 3]) and the A corner landings ((-8.3, 1.9) on
floors 1 and 3, (-8.3, -1.9) on floor 2) are clear by at least 2.3 m from any body below
head height; the nearest things are the ring's overhead edge at x -5.15 and the network at
x -5. Columns at x ±5, ±14, ±20 / z ±14 are untouched (nothing stands beyond |z| 9.5).

## Controls to test, exactly

Floor 1, CA_Introduction:

- `ca_rule_explorer` (desk at -4, 4; stand east of it at about x -2, looking west):
  NEXT GENERATION panel: **STEP**, **RUN**, **SEED**, **CELL**. CA RULES panel: **RULE**
  slider, **SPEED** slider, **30 / 90 / 110 / 184 / RST**. The black **hand point** parked on
  the gold rail (grip to carry; moving it along the rail changes the witness cell on the
  readout plate and the three marks on the board; **trigger while held = STEP**). The
  **readout plate** (THREE CELLS / GEN / CELL / LEFT SELF RIGHT / NEXT / RULE / SEED). The
  overhead **ring** centred at (-3.5, 2.4) mirrors the board's stored rows and the witness
  marks. Expected: single seed reads `0 1 0`, NEXT 0 under Rule 90; after one STEP `1 0 1`;
  RUN alternates auto-run; SEED resets to the pair; RST/SEED clear the ring.
- `line_network_ca` (-4, -3): approach within 3 m to start the unfolding; **REPLAY** button
  on the plinth at (-4, -1.9), facing the spawn. Caption reads APPROACH TO UNFOLD, then
  GROWTH HISTORY n OF 20, then TWENTY SAVED STAGES.
- `persian_rug`, `langton_swarm`, `rule110_computer`, `dark_sphere`, `synthesis_stand`:
  observe only (the rug steps, the ants paint, the console cycles its 32 rows, the orb
  pulses, the stand pins hush + swarm with its plaque).
- `ca_showcase` (3, -5): cycles every 10 s. Its `_input` also reacts to keyboard
  **SPACE / A / R / 1-9 / + / - / H**; SPACE is the Void's desktop jump and R its retry, so
  on desktop a jump also cycles the showcase and a retry also resets it. Original behaviour,
  not adapted; flagged for curation (a trial-local wrapper could `set_process_input(false)`).

Floor 2, CA_ElementaryRules:

- `structure_growth` console at (1.65, 3.36), hand height, facing the spawn: **STEP**,
  **RUN**, **REPLAY**, **VIEW**, **+20**; readout (GEN n / 20, PINK ACTIVE, GREEN FADING,
  DRAWN, CHANGED). The **state hand point** parked beside the console (grip + trigger =
  STEP). The **neighbour room** at (3.85, 1.5, -1.3): 27 addresses, golden frame, caption
  with CENTRE state and ACTIVE NEIGHBOURS. Expected (seed 23090, pinned in the study):
  generation 0 centre ACTIVE; after one STEP centre FADING with **7** active neighbours;
  after the next STEP centre EMPTY; VIEW swaps to height colours and back; +20 extends the
  budget after LIMIT.
- `dark_sphere` (-4, -2.5): observe.

## Walking and descents (floor-local)

Floor 1: spawn (0, 12) → entry line (0, 9.5) → aisle at x about -2 between the rug (x
0.72..3.28) and the desk (x ≥ -4.92) → under the ring → past the network plinth → showcase on
the east, rule 110 at the far end → exit line (0, -9) → east side around the showcase →
back → west along z about 6.5 to x -6.2, then to (-6.4, 1.9) → off the slab edge into shaft
A, landing on floor 2's boards at (-8.3, -1.9). Floor 2: boards → orb → console front (1.65,
4.8) → east of the console → around the neighbour room → across the glass lid through the
volume (no collision) → (-6.4, 1.9) → into A onto the catch floor's boards at (-8.3, 1.9).
Retry from the catch floor returns to floor 2 (`retry_floors` in `playable.json`); the
streaming window then holds floors 2 and 3, so floor 1 rebuilds on return.

## Commands ready for the coordinator

```bash
python commons/void/trials/cellularautomata/run_probe.py
```
```bash
python commons/void/trials/cellularautomata/run_probe.py --capture
```
```bash
python tools/export_void_trial.py cellularautomata
```
```bash
python tools/void_sequence_trials.py --check
```

Editor: `http://localhost:3003/lab-editor?mode=void&trial=cellularautomata&floor=1`.
None of the ten artifacts declares editor parts, so copy / move / turn act on whole bodies;
the explorer's desk, ring and hand point and the growth's console and room are built in
`_ready` under the artifact root and travel with it.

The probe runs desktop and synthetic XR passes. It checks: ten exhibits with their original
scripts and identity stamps; no imported camera or sun active; the explorer's study values,
STEP/SEED/rule readings, the ring's row height; the network's fit, twenty kept stages and
REPLAY; rug stepping and plane height; ants and rule 110 running; the showcase's twelve
systems, grounding and cycling; the stand's hero; the growth study's generation-1 reading
(fading, seven active neighbours), VIEW, REPLAY, console position and the basin lid; every
body inside the frame; XR pointer presses on both STEP buttons and a real grip-carry of both
hand points; the two walking routes; both A drops onto the boards; retry. Output:
`doc/book/iterations/2026-10-21-void-cellularautomata-transfer/{tests,images}/`
(`checks.json`, `measure.json`, `engine.log`, screenshots).

Because it was written blind, treat a failure as a question about the probe first and the
placement second: likely weak spots are the XR approach offsets for the two panels, the
assumption that `move_to` tolerates the glass lid's y = 0 surface, and the exact
`floor_stream` window after retry.

## Dependencies and risks

- `commons/data/dna_synthesis.json` holds the dark_sphere verdict (hero: presence hush, body
  swarm, 35 %); the stand reads it at build. Present today.
- `RackTemplates.create_panel` buttons (`InteractableAreaButton.button_pressed`) and
  `XRToolsPickable` points on collision layer 4 (`point_body.gd`): the same mechanisms the
  noise trial already exercised with the shared player.
- Cost: `ca_showcase` builds twelve 8000-instance MultiMeshes and updates one per frame;
  `line_network_ca` allocates a 64³ nested Array at `_ready` and scans its frontier for 20
  frames, then stops; `structure_growth` steps 125 000 cells only on STEP/RUN at 1 Hz;
  `persian_rug` updates 40 texture rows per frame; two `dark_sphere` pulse every frame.
  Floor residency sleeps floor 1 while floor 2 is live. Nothing here is measured.
- `CellularAutomata3D_Flexible.gd` is `@tool`; `StructureGrowth.tscn` is 7.8 MB (a saved
  MultiMesh buffer). Load time unknown.
- Keyboard conflicts from `ca_showcase._input` (above). `ca_rule_explorer._input` is gated
  off by the study.
- `void_sequence_trials.py --check` inventories first maps only (CA_Introduction); it does
  not read `rooms.json`, so it says nothing about floor 2.

## For curation, later

The original encounter order (board → rug → ants → network → showcase → rule 110; then the
volume) is preserved by the turn; the partitions that made the rug room and the corridor
are not. The chapter texts refer to "the dividing wall", "the opening beside the board",
"the open gallery beyond the rug's room", "the opening in the floor" and "the rim": the
first three need walls, the last two are the basin. Nothing in `tutorial.md` or `final.md`
was changed or should be until the lived floors are compared with them.
