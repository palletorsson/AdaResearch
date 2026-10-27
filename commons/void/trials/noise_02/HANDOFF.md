# noise_02: Noise_One, Noise_Voxel, Noise_6_Wall, Noise_Inside_Noise, Noise_Cellular

Owner: Claude worker C, batch 25, 2026-10-21. Godot jobs were run by the Claude
coordinator; this worker launched none. **Native, export and editor gates passed;
awaiting Codex review. Not accepted, not curated.**

| Gate | Result |
|---|---|
| Source audit | **127 / 127** |
| Schema + `validate_void_rooms --editor` | valid; 4 advisory spatial warnings (below) |
| Parse | OK |
| Focused, desktop | all pass: bounds-1..5, strands 8, flightseam 5, lattice 10, panel 8, rooms 10, warp 8, flight 7, crossfloor 5, torus 8, basin 8, film 6, room 6, relief 6 |
| Full native, desktop + synthetic XR | **235 / 235**, 124.6 s, exit 0, no engine errors; FIT empty on all five floors in both modes |
| GLB export | **55 models**, failures `[]`; all 17 placements have meshes; the strands are exported as a completed weave (R3) |
| Editor | **20 / 20** (`evidence/editor-checks.json`), see note |

**Editor note.** The editor test checked each of the 17 placements:
- real geometry;
- independent move, copy and rotation.

It also checked save/reload to the native layout and the Desktop mirror, rejection of a
stale save, and that all source map and chapter hashes are unchanged.

`rooms.json`'s **bytes changed** across save/restore, because the API re-serializes the
file. The test asserts deep semantic equality after the restore and refreshed the
manifest hash. Re-running `place_noise_02.py` would rewrite the same content in its own
formatting.

**Tower unchanged:**
- 42 x 32 m floor, 6 m storeys;
- both 5 x 6 m shafts and all columns;
- default sign positions; `layout.json` untouched.

**Placements.** All 17 inventoried IDs are placed once, each with its original key,
config, token height and scale, and facing = yaw + 180. Nothing is scaled.

**Not transferred** (outside the inventory):
- walls, `s`/`sp`, `t`, `an` labels;
- wedges and raised structure cells;
- Noise_Voxel's four transport cubes (`tc:10:y` x3, `tc:50:y`). In the open-roof museum
  hall they lifted the visitor 10 m and 50 m beside the volume.

**Museum plan check.** `em_plan` rows for all five maps match `map_data.json`.
Noise_Inside_Noise's plan cells are offset by +1, +1 by its ring expansion; the
arrangement is the same.

| Status | Count |
|---|---|
| Placed | 17 |
| Native verified | 17 (focused cases + full acceptance) |
| Editor verified | 17 |
| Curated | 0 |
| Headset | not tested (synthetic XR only) |

## Placement

The rigid turn is `x = cx - col`, `z = cz - row`, with the source spawn on (0, 12).

| Floor | Map | Rule |
|---|---|---|
| 1 | Noise_One | spawn (0, 0) |
| 2 | Noise_Voxel | spawn (10, 1) |
| 3 | Noise_6_Wall | spawn (1, 1) |
| 4 | Noise_Inside_Noise | spawn (4, 12). The hall lies behind the spawn, so the floor is translated as a whole by (+3, -19) |
| 5 | Noise_Cellular | spawn (34, 1) |

`place_noise_02.py` writes `rooms.json` and `moves.json` (rigid position, new position,
reason) from the inventory.

| id | at (rigid) | facing | h / scale | config |
|---|---|---|---|---|
| f1_film_noise_layers_1_2 | **-1.5, 10** (-1, 10) | 270 | 0 / 1 | plinth:0 pin:true |
| f1_noisetorus_5_4 | -5, 8 | 0 | 0 / 1 | stand:pair |
| f1_noiselayers_5_7 | -5, 5 | 180 | 0.8 / 1 | stand:basin |
| f1_dark_sphere_8_10 | **-8, 4** (-8, 2) | 180 | 0 / 1 | |
| f2_voxelnoise_16_24 | **-6, -30.1** (-6, -11) | 0 | 0 / 1 | stand:volume cell_size:1 flight_box:true |
| f2_science_screen_18_4 | -8, 9 | 0 | 0 / 1 | mode:voxel_slice support:stand screen_width:2.8 screen_height:1.8 |
| f2_perlin_terrain_sculptor_13_7 | -3, 6 | 0 | 1.35 / 1 | stand:lattice seed:31415 keyboard:off |
| f2_dark_sphere_5_8 | 5, 5 | 180 | 0 / 1 | |
| f3_shader_noise_space_6_4 | -5, 9 | 180 | 0 / 1 | stand:panel |
| f3_shader_noise_space_6_6 | -5, 7 | 180 | 0 / 1 | stand:room |
| f3_dark_sphere_10_10 | **-10.2, 4.4** (-9, 3) | 180 | 0 / 1 | |
| f4_dark_sphere_3_3 | **4, 2** (1, 21) | 180 | 0 / 1 | |
| f4_noisesphere_6_5 | **1, 0** (-2, 19) | 0 | 0 / 1 | stand:warp |
| f4_film_noise_relief_11_9 | **-4, -4** (-7, 15) | 90 | 0 / 1 | plinth:0 pin:true |
| f5_cellular_womb_space_17_19 | **14.5, 17.2** (17, -6) | 180 | 0 / 1 | floor:false plinth:0 pin:true |
| f5_cellular_atrium_space_51_19 | **-14, 16** (-17, -6) | 180 | 0 / 1 | floor:false plinth:0 pin:true |
| f5_voronoi_strands_34_40 | **17, -10.5** (0, -27) | 180 | 0 / 1 | plinth:0 pin:true |

**Heights.**
- **noiselayers 0.8** is relative to the hall floor. The museum measured the basin at
  y 0.12..2.0 (`doc/book/iterations/2026-09-25-noise-one-standing/museum-runtime.json`).
  The Void measured 0.12..2.00 as well. The source's 5 x 5 floor hole under the basin is
  not reproduced: the tray floats 0.12 m over the slab.
- **Bench 1.35.** The pedestal foot stands at 0.08 m, measured.

**Build order.** Floor 2 lists the volume before the bench, and floor 5 the rooms before
the strands. A lazy floor builds one placement per frame, so the bench's contract
broadcast and the strands' anchor rays need their partners first. Readiness was
measured: construction was complete at 0 frames after placement in the focused runs.

### Why these moved

- **Small fit moves.**
  - The floor-1 film's 2.68 m case entered the arrival keep-out.
  - The floor-1 and floor-3 orbs stood on shaft A's landing pads.
- **Floor 4 translated (+3, -19).** At the rigid spot all three works were off the floor.
  The orb stays inside the enclosure, as in the source.
- **Voxel volume, beyond the north edge.** The volume is 24^3 one-metre cells inside a
  28 m glass flight enclosure with collision.
  - Every on-slab spot crosses a shaft, or carries the cells and the walls through floor 1
    and the roof.
  - It moved 19.1 m north along its own axis. The door stands at the slab edge, and the
    enclosure's own glass floor carries the visitor.
  - Bench to volume: 36 m, against 17 m in the source.
- **Cellular rooms, straddling the south edge.** At the rigid spots the atrium covered
  shaft A (the descent onto floor 5) and the womb covered shaft B.
  - No on-slab pair clears shaft A without the two rooms intersecting.
  - Entrances and front halves stand on the slab; the back halves have no floor.
- **Strands: from (0, -12) to (17, -10.5).**
  - The work is a 6.6 x 7 x 5.8 m Voronoi core, 0.8..7.8 m high, plus up to 36 cords.
    Each cord ray-casts to the first solid surface within 80 m, as the cords ran to the
    museum hall's floor, walls and rooms.
  - At (0, -12) the cords spread over x -15.8..20.5, z -15.9..12.1 and up to 11.7 m, and
    the floor sign stood 1.3 m from the core.
  - (17, -10.5) is the north-east bay between columns (14, -14) and (20, -14), north of
    the womb. It is off the source's centre axis.

## Interactions and evidence

Native evidence comes from the desktop focused cases, plus the full desktop + XR
acceptance, which runs every focused check in both modes.

| id | action | evidence | fit / dependency | remaining |
|---|---|---|---|---|
| film_noise_layers | concept monitor | **real pointer** PAUSE toggles (`film`) | | REPLAY/STEP/TURN VIEW not pressed |
| noisetorus | relief and colour rings on one field | **real pointer** FREEZE holds, then resumes, the shared clock (`torus`) | rings have no collider (as authored); stray prism, see below | SAMPLE, AMPLITUDE, FREQUENCY, REMAP not pressed |
| noiselayers | 1:50 basin of the three-resource terrain | **real pointer** LOW isolates the low resource; SUM restores all three (`basin`) | tray 0.12 m over the slab | MIDDLE, HIGH not pressed |
| dark_sphere x4 | independent pulse | API: body built; gestation inert here | | |
| perlin_terrain_sculptor | lattice, seed 31415, keys off; broadcasts the contract | **real pointer** CELL moves the bench cell, the volume's marker and the screen's section (`lattice`). 6767 of 13824 cells occupied, 25 pieces; the volume holds the same 6767 | R1 | THRESHOLD, SEED, CUT not pressed |
| voxelnoise | 24^3 one-metre cells from the bench's contract; 28 m flight enclosure | API: contract seed 31415, rebuild 64.6 ms. **Real walking** from the slab through the south door enters flight (feet -6.39, -16.15; `flight`) | outside the footprint; R4 | flying among the cells not exercised |
| science_screen | live voxel section | API: slice from this floor's bench, seed 31415; layer follows CELL (`lattice`) | | |
| shader_noise_space (panel) | four-patch board driving the room | **real pointer** LAYERS changes the room's cloud sum; FREEZE holds the room clock (`panel`) | R1 | BASIS, DRESS not pressed |
| shader_noise_space (room) | five-metre room, two side doors, retained sphere | **real walking** in through the east door (`room`) | R1 | |
| noisesphere | warp study inside a 10 m relief enclosure with collision | **real pointer** WARP rebuilds field and shell; **real walking** in through the west opening (`warp`) | dome rises into floor 3, see below | SAMPLE, RELIEF, ZERO not pressed |
| film_noise_relief | concept monitor | **real pointer** PAUSE (`relief`) | faces the enclosure's outer wall from about 1 m, as in the source | |
| cellular_womb_space | walkable membrane, WOMB layout | API: membrane collision, no floor of its own. Ray support: front yes, back no. **Real walking** in through the entrance (`rooms`). Mesh 768-1011 ms, built once (R2) | back half unsupported | |
| cellular_atrium_space | CELLS layout | API as for the womb; mesh 1779-2025 ms (`rooms`) | back half unsupported | interior partitions not walked |
| voronoi_strands | Voronoi edge net, woven by a spider, anchored by rays, then tension | API: built; 30 anchors, none in a keep-out (`strands`, `bounds-5`). Diagnostic API `finish()` releases tension: knots travel up to 3.45 m in 90 frames | cords anchor to the Void's structure, see below | the natural weave was not run to completion natively (minutes at 2 m/s) |

Shared chain, both modes: safe arrival, original geometry and config meta, open shafts,
visitor camera, shaft-pad descent, sleeping floors, return, retry.

## Measured bounds and intrusion

| floor | work | world x | world z | y above its floor |
|---|---|---|---|---|
| 1 | noisetorus | -6.30..-3.70 | 7.50..8.63 | 0..**7.79** (stray prism) |
| 2 | voxelnoise (cells + enclosure) | -20.06..8.06 | -44.60..-15.60 | -0.12..**28.06** |
| 4 | noisesphere (mesh) / displaced relief | -3.90..5.90 / -4.42..5.90 | -4.80..5.20 / -4.71..4.99 | 0..6.50 / 0.06..**6.78** |
| 5 | womb | 3.24..25.12 | 4.06..30.56 | -0.50..**9.08** |
| 5 | atrium | -26.66..-1.34 | 3.43..28.66 | -0.50..**8.94** |
| 5 | strands, at (17, -10.5) | -3.29..20.50 | -14.49..9.70 | 0..**11.87** |

Full per-entry bounds: `evidence/measured-bounds.json`.

**Overhang.**
- Womb: 4.1 m past the east edge, 14.6 m past the south edge.
- Atrium: 5.7 m past the west edge, 12.7 m past the south edge.
- Voxel enclosure: entirely beyond the north edge.

**Into the storey above.**
- **Floor 4 (room caps, with collision).**
  - The womb rises 3.08 m above floor 4 and the atrium 2.94 m.
  - Rays on floor 4 meet the atrium membrane 2.52 m up at (-12, 12) and the womb 2.19 m up
    at (12, 12).
  - Photo `12-floor-5-room-caps.png` shows the atrium cap, with a column through it.
- **Floor 3 (dome cap, with collision).** The noisesphere's displaced relief tops out
  0.78 m above floor 3; a ray at (1, 0.2) meets it 0.49 m up.
- **Roof (noisetorus stray prism).** The noisetorus scene ships `MeshInstance3D3`, a
  PrismMesh 7.29 m above the ring with the noisePlanet2 shader.
  - `stray_planet` defaults to true, and the museum measured the same 7.9 m box.
  - In the Void it floats 0.8-1.8 m over the roof deck. It has no collision. Kept as
    shipped.
- **Strands, 8 of 30 anchors above floor 5's storey:**
  - floor 4's floor top;
  - column (14, -14) inside floor 4;
  - floor 3's slab underside, x4;
  - floor 3's beam;
  - shaft B's slab edge at floor 3's level, (10.3, 11.8, 3.0).

  The other 22: 10 on floor 5's slab, 4 at its ceiling and beam, 8 on columns and the
  room membranes (womb north face; atrium at (-3.2, 3.3, 9.6)). The cords that leave floor
  5 pass through floor 4's storey, with no collision. In `crossfloor`, run from floor 4,
  the strands unit was **not visible** (floor 5 residency), so from floor 4 those cords do
  not show while floor 5 is not live.
- **One cord crosses floor 5's shaft-B opening, lowest point 3.34 m.** Recorded, not
  failed (no collision). No anchor and no core segment lies in a shaft opening, the
  arrival or the floor sign. The FIT check is per instance: Liang-Barsky segments for the
  strands, origins for knots and plates.

**Validator warnings** (advisory):
- the voxel volume, womb and atrium leave the structural floor;
- the noiselayers footprint touches the decorative checkpoint strip at (-6, 4.5). The
  trial spawn is (0, 12).

## Screenshots (`evidence/`, desktop, native Mobile renderer)

This worker inspected photos 06, 12, 14 and 16.

| # | file | view |
|---|---|---|
| 01-02 | noise-one arrival; torus and basin | floor 1 |
| 03-06 | voxel arrival; bench and screen; flight door at eye; volume from the slab | floor 2. 06 is a close, near-ceiling view of the volume's cell faces |
| 07-09 | wall arrival; inside the shader room; floor-4 dome cap | floor 3 |
| 10-12 | inside-noise arrival; inside the enclosure; floor-5 room caps | floor 4 |
| 13-15 | cellular arrival; womb entrance (arch, column (14, 14) inside); atrium inside | floor 5 |
| 16 | **does not show the strands.** It was aimed at their first position (0, -12) and shows the floor sign and the north edge | floor 5 |

`probe.gd` now aims photo 16 at (17, -10.5). That change came after acceptance and only
touches the capture; the photo has not been re-taken.

## Requests (REQUESTS.md)

- **R1:** bench and noise-room placements configured before `_ready`. Wired by Codex,
  verified natively.
- **R2:** the same for the cellular rooms. Wired by Codex; each room is meshed once.
- **R3:** the exporter finishes the strand weave. Wired by Codex; the export passed.
- **R4:** flight zone residency. **Measured, open.** From floor 1, both as first loaded and
  after visiting floor 2, the floor-2 flight zone answers at (-6, -17), just past floor 1's
  north edge:
  - `flight_zone_active` true;
  - glass wall collision: none;
  - zone not visible and not processing.

  The hook is in REQUESTS.md; the decision is Codex's.

## Open (curation; Palle)

1. **Voxel volume.** The 28 m enclosure stands outside the tower beyond the north edge
   (external extent). The alternative is an isolated taller trial (array_tutorial_02 used
   14 m storeys).
2. **Cellular rooms.** The back halves have no floor; a visitor walking past z 16 falls.
   They need an exterior platform or a larger isolated layout.
3. **Cross-floor intrusion:** floor 5's domes into floor 4, the strand core and 8 cords
   into floors 4 and 3, floor 4's dome into floor 3, and noisetorus's shipped stray prism
   on the roof. `#stray_planet:false` would remove the prism, but it is a config change.
4. **Strands.** The cords anchor to the Void's structure where the museum gave walls. The
   work stands off its source centre axis, in the north-east bay, chosen for fit.
5. **Transport cubes.** Noise_Voxel's transport cubes are not in the inventory.

## Commands

```
python tools/audit_void_transfer.py noise_02
python tools/test_transfer_native.py noise_02 --focus <case> --mode desktop|xr
python tools/test_transfer_native.py noise_02
python tools/export_void_trial.py noise_02
node tools/test_void_transfer_editor.cjs noise_02
```

Focused cases:
- bounds: bounds-1..5;
- floor 1: torus, basin, film, flightseam;
- floor 2: lattice, flight;
- floor 3: panel, room;
- floor 4: warp, relief, crossfloor;
- floor 5: rooms, strands.

Receipts are in `evidence/debug/<case>-desktop/`. Acceptance is in
`evidence/checks.json` and `engine.log`.

## Exact files

**Mine:**
- `commons/void/trials/noise_02/rooms.json` (floors 1-5; re-serialized by the editor test)
- `commons/void/trials/noise_02/place_noise_02.py`
- `commons/void/trials/noise_02/moves.json`
- `commons/void/trials/noise_02/probe.gd`
- `commons/void/trials/noise_02/REQUESTS.md`
- `commons/void/trials/noise_02/STATUS.json`
- `commons/void/trials/noise_02/HANDOFF.md`
- `commons/void/trials/noise_02/transfer-status.json`

**Generated by the runners:**
- `commons/void/trials/noise_02/evidence/*`
- `../ada_encyclopedia/public/void-trials/noise_02/*`
- the Desktop mirror, written and restored by the editor test

**Codex's shared hooks, not mine:** R1, R2 and R3 in `floor_content.gd` and
`export_void_editor.gd`.

**Untouched:** sources, maps, chapter texts, catalog, `playable.json`, `layout.json`,
`trial.tscn`, `source-inventory.json`.
