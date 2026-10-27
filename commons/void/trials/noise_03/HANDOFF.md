# noise_03: Noise_Box (1), Noise_Space_10 (2), Noise_Perlin_Simplex (3), Lab_Path (4, optional)

**Draft.** Claude worker D, batch 25, 2026-10-21. The coordinator completes the native,
export and editor rows. Lab_Path is an optional trial floor only; the main spine and the
curated tower are untouched.

| Gate | Result |
|---|---|
| Source audit (`audit_void_transfer.py noise_03`) | **90 / 90**; 10 placements, 48 preserved source hashes unchanged |
| Schema + editor validator | valid. Two warnings: the two Noise_Box shells "leave the structural floor", which is deliberate (below) |
| Probe syntax | gdtoolkit `gdparse` OK. This is not a Godot parse; the coordinator runs Godot. |
| Native, desktop + synthetic XR | pending. **Needs R1 first** (see REQUESTS.md) |
| GLB export / editor | pending |

The tower is standard: 42 x 32 m floor, 6 m storeys, pillars and both shafts unchanged. No
walls and no ceilings were added. Nothing was scaled.

| Status | Count |
|---|---|
| Placed | 10 / 10 |
| Native verified | 0 |
| Editor verified | 0 |
| Curated | 0 |

## Placement

Each hall is turned 180° rigidly: `x = cx − col`, `z = cz − row`, with the source spawn on
the arrival (0, 12). Facing = yaw + 180. Every config is the token's own strings. Scale is 1
everywhere (no token scale).

| hall | rigid transform | spawn cell |
|---|---|---|
| Noise_Box | `34 − col`, `13 − row` | `s` (34, 1) |
| Noise_Space_10 | `−col`, `12 − row` | `sp` (0, 0) |
| Noise_Perlin_Simplex | `1 − col`, `13 − row` | `sp` (1, 1) |
| Lab_Path | `−col`, `12 − row` | `sp` (0, 0) |

Script: `place_noise_03.py` in this folder.

Heights follow the museum lane: em_plan `support_height_m` + token offset.

| id | token (head) | rigid → placed | facing | height | config |
|---|---|---|---|---|---|
| f1_box_shell_space_17_19 | box_shell_space | (17, −6) → **(35, −6)** | 180 | 0 | floor:false plinth:0 pin:true |
| f1_box_atrium_space_51_19 | box_atrium_space | (−17, −6) → **(−35, −6)** | 180 | 0 | floor:false plinth:0 pin:true |
| f2_dark_sphere_11_3 | dark_sphere | (−11, 9) → **(−11.5, 11.2)** | 180 | **1.0** | — |
| f2_noise_space_6_6 | noise_space | (−6, 6) → **(−6.5, 8.2)** | 180 | 0 | stand:walk |
| f3_perlin_noise_terrain_2_17 | perlin_noise_terrain:0:1.0 | (−1, −4) → **(3, −4)** | 180 | 1.0 | — |
| f3_dark_sphere_6_17 | dark_sphere | (−5, −4) → **(−1, −4)** | 180 | 0 | — |
| f3_perlin_noise_8_13 | perlin_noise:0:1.1 | (−7, 0) → **(−3, 0)** | 180 | 1.1 | generator, seed 20260910, size 8, ramp shared, panel front, frequency 10, amplitude 0.8, persistence 0.5, octaves 4 |
| f3_simplex_noise_3_13 | simplex_noise:0:1.1 | (−2, 0) → **(2, 0)** | 180 | 1.1 | as perlin (no generator) + witness:show study:compare enclosure:arches |
| f3_configurable_portal_9_19 | configurable_portal | (−8, −6) → **(−4, −6)** | 180 | 0 | dest_map:Lab_Path, label "Lab Path - not connected", active:false |
| f4_dark_sphere_2_2 | dark_sphere | (−2, 10), rigid | 180 | 0 | — |

### Why things moved

**Noise_Box: exterior specimens (open question for Palle).**
- **Size.** The two cellular shells are box-sampled ellipsoid membranes. In the source
  (`cellular_volume.gd`):
  - mesh BOUNDS 27 x 11 x 29 m, from y −0.5 to about 9.5;
  - WOMB radii 10 / 6.2 / 12 plus noise;
  - CELLS radii 12 / 6.2 / 12.

  Each is about 24–27 x 29 x 10 m.
- **Why not inside.** Side by side they need 51 m or more on a 42 m floor. Any shell over a
  shaft also fills that shaft's column in the storey above: its dome rises 3.5 m above the
  canopy and would cover shaft A's roof descent.
- **Where they are.** Both stand beside the tower at x ±35, keeping their rigid sides (shell
  east, atrium west) and rigid z. This follows the isosurfaces mc_cave precedent.
- **What is lost.** Their entrance (local +z, north after the turn) opens over the void.
  `floor:false` is the source config: the museum hall supplies the floor. Nobody can walk in.
  An exterior platform or `floor:true` is curation.

**Noise_Space_10.**
- At its rigid position, the noise space's 9.6 m stone margin and control panel entered
  shaft A.
- The hall moved (−0.5, +2.2) as a group. The −0.5 keeps the entry wedge 0.55 m off column
  (−5, 14).

**Noise_Perlin_Simplex.**
- At its rigid position, the perlin's 4 m field entered shaft A.
- The hall moved +4 x as a group. The pair keeps its 5 m spacing; the arches, panels and
  witness sit between the shafts.

## Source structure reproduced (floor 2 `construction`, removable)

The source ring of `2` cells (1 m) and its two `wp` walkways are what lift a visitor onto
the noise space's 1 m stone margin. Abstract floors draw no support rods, so without them
the dark sphere floats and the field is unreachable.

| construction id | kind | at | what it reproduces |
|---|---|---|---|
| f2_raised_cell_11_3 | cube (1 m platform block, `structure_2`) | (−11.5, 0, 11.2) | the `2` cell under the dark sphere (museum support 1.0 m) |
| f2_access_wp_entry | wedge (the original `wp` mesh + collision, 1 x 2 x 1 m) | (−6.5, 0, 14.0), facing 180 | access onto the margin at the entry gate (arrival side) |
| f2_access_wp_exit | wedge | (−6.5, 0, 2.4), facing 0 | access at the exit gate (shaft side) |

The rest of the 55-cell ring is not reproduced. The wedges do not follow the noise space if
the editor moves it.

## Interactions: what each work does, and the planned evidence

Probe check names are in `probe.gd`. **Nothing below is native-verified yet.**

| id | action | probe evidence (planned) | fit / dependency | remaining |
|---|---|---|---|---|
| box shell / atrium | walk-in membrane rooms; entrance tube; 4 lights each | **API**: membrane, collision, no floor disc. **Geometry rays**: entrance open, back closed. **Measured**: clear of the tower footprint; build_msec | exterior, unsupported (floor:false); built twice (R3) | walk-in impossible without a platform |
| noise_space | stand:walk field; HEIGHT / ROUTE / SAMPLE / RESET; walked trail; SMALLER door 1:8 | **Real walking**: wedge → margin → field, trail records. **Real pointer**: HEIGHT refused on the field, then 0.65 from outside; ROUTE; RESET. **Real walking**: through SMALLER (desktop: camera in a scaled pivot, capsule ×0.125; XR: world_scale ×0.125), then off the field to restore | the wedges are reproduced source access. **Host finding R4 (measured):** on desktop the round trip reparents the `DesktopHand`, whose `_exit_tree` disables it for good, so later presses are dead until a retry. The probe asserts this, then re-enables the hand through the API (`PROBE_RESTORE`) | SAMPLE not pressed |
| dark_sphere (×3) | presence; catalyst / projectile gestures | inspect only | f2 stands on its reproduced 1 m cell | gestures not run |
| simplex / perlin | named-seed fields, front panels FREQ / OCTAVES / REGEN / REPLAY, witness plate | **API**: contract, basis readback, panels at z −2.7 (R1). **Real pointer**: REGEN, REPLAY. **Real drag**: perlin FREQ handle | **R1 required** | OCTAVES not dragged |
| pair study | SAMPLE / VIEW / MATCH, two walk-through noise arches, terrain plinth | **Real pointer**: SAMPLE, VIEW ×2. **Real walking**: through the simplex arch while `occupied()`. **API**: plinth anchor (R2) | R1; R2 | MATCH not pressed |
| perlin_noise_terrain | animated 1 m relief, 0.5 s steps | inspect | plinth only with R2 | |
| configurable_portal | inactive door labelled "not connected" | **API**: config. **Real walking** through it changes nothing. `resolve_destination()` is printed | source builds its children twice (all lanes) | |

## Not transferred

These are not inventoried:
- Noise_Box: `s`, two `wp`, two `an` info boards, `t`;
- Noise_Space_10: `sp`, `an`, the `wp` pair (access reproduced as wedges), `t`;
- Noise_Perlin_Simplex: `sp`;
- Lab_Path: `sp`, `an`, `t`.

Walls (`w`) and the `2` ring are not transferred except the three construction cells above.
Lab_Path's centre cell is structure `0` (sphere and teleporter in a 1 m pit in the grid
lane). The pit is not reproduced: the sphere stands on the slab.

## Museum plan differences (reported, not substituted)

- **Noise_Space_10.** `em_plan` row 89 uses cells shifted +1/+1 ("ring: expand"), with the
  dark sphere's `support_height_m 1.0`; this transfer uses the 1.0. The as-built bake
  (`em_bake`, segment `noise|noise space 10`) places the sphere and field at (5, 9) / (5, 10):
  a different arrangement.
- **Noise_Perlin_Simplex.** The plan matches the map (offsets 1.1 / 1.1 / 1.0).
- **Lab_Path.** Not in the museum plan; the spine skips it.

## Commands (coordinator; runners queue on the OS lock)

```
python tools/audit_void_transfer.py noise_03
python tools/test_transfer_native.py noise_03 --focus bounds-1 --mode desktop
python tools/test_transfer_native.py noise_03 --focus bounds-4 --mode desktop
#   after Codex installs R1 (+R2):
python tools/test_transfer_native.py noise_03 --focus bounds-2 --mode desktop
python tools/test_transfer_native.py noise_03 --focus bounds-3 --mode desktop
python tools/test_transfer_native.py noise_03 --focus scale --mode xr
python tools/test_transfer_native.py noise_03 --focus pair --mode desktop
python tools/test_transfer_native.py noise_03
python tools/export_void_trial.py noise_03
node tools/test_void_transfer_editor.cjs noise_03
```

Focused cases: bounds-1..4, shells, field, scale, pair, arch, portal.

Without R1, any run that loads floor 3 has a SCRIPT ERROR (`pair_study.gd:24`). Floor 3 is
loaded by bounds-2 (as preview), bounds-3 and the full run. bounds-1 and bounds-4 never load
floor 3.

## Readiness notes for the runner

These are static readings, not measured:
- **Shells:** built synchronously in `_ready`, then again in `apply_grid_config`. Expect a
  frame spike of seconds on floor-1 load.
- **Noise space:** builds synchronously (81 x 81 vertices, trimesh).
- **Noise fields:** 64 CSG cubes each, after a 400-cube first build that is freed.
- **Pair study:** deferred one frame after the simplex.
- **Portal:** builds one frame after `_ready`, twice.
- **Terrain:** steps every 0.5 s.

## Untested claims

- Physical headset.
- Shell walk-in (impossible here).
- Dark-sphere gestures.
- OCTAVES, SAMPLE (noise space), MATCH.
- Listening; there is no audio in these works.

## Exact files (mine)

- `commons/void/trials/noise_03/rooms.json`
- `place_noise_03.py`
- `probe.gd`
- `REQUESTS.md`
- `STATUS.json`
- `HANDOFF.md`
- `transfer-status.json`
- `evidence/source-checks.json` (written by the audit)

Untouched: sources, maps, texts, catalog, `playable.json`, `layout.json`, `trial.tscn`,
shared code.
