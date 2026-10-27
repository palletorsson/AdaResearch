# cellularautomata_02: CA_GameOfLife (floor 1)

**Draft.** Claude worker D, batch 25, 2026-10-21. The coordinator completes the native,
export and editor rows.

| Gate | Result |
|---|---|
| Source audit (`audit_void_transfer.py cellularautomata_02`) | **41 / 41**; 6 placements, 15 preserved source hashes unchanged |
| Schema + editor validator | valid, no warnings |
| Probe syntax | gdtoolkit `gdparse` OK. This is not a Godot parse. |
| Native, desktop + synthetic XR | pending; no shared request blocks it |
| GLB export / editor | pending |

The trial has a single content floor: layout levels 0 / −6 / −12 (canopy, CA_GameOfLife,
catch floor). The shared `visit()` runs floor 1 only: focused checks, then return and retry
on floor 1. No descent is tested.

| Status | Count |
|---|---|
| Placed | 6 / 6 |
| Native verified | 0 |
| Editor verified | 0 |
| Curated | 0 |

The floor is the standard 42 x 32 m, with 6 m storeys and pillars and shafts unchanged.
No walls and no ceilings. Nothing was scaled.

## Placement

The hall is turned 180° rigidly: `x = 6 − col`, `z = 12 − row`. The source spawn `sp` (6, 0)
lands on the arrival. Facing = yaw + 180. Configs are the token's own strings. Script:
`place_cellularautomata_02.py`.

| id | token (head) | rigid → placed | facing | height | scale | config |
|---|---|---|---|---|---|---|
| f1_ca_bridge_6_5 | ca_bridge:0:0 | (0, 7), rigid | 180 | 0 | 1 | study:history plinth:0 follow:walk |
| f1_film_cellular_history_1_15 | film_cellular_history:90:0 | (5, −3), rigid | 270 | 0 | 1 | plinth:0 pin:true |
| f1_lab_room_6_22 | lab_room | (0, −10) → **(−7.5, −9.6)** | 180 | 0 | 1 | all 24 source keys (8 x 7 x 3.8 m, windows, east door, signage, mounted turing_apparatus) |
| f1_dark_sphere_4_28 | dark_sphere | (2, −16) → **(2, −13)** | 180 | 0 | 1 | — |
| f1_ca_columns_8_28 | ca_columns:0:−0.5:0.2 | (−2, −16) → **(−2, −13)** | 180 | **0** (token −0.5) | **0.2** | — |
| f1_mirrored_cellular_automata_6_32 | mirrored_cellular_automata:0:−0.5 | (0, −20) → **(0, −15)** | 180 | **0** (token −0.5) | 1 | — |

**Floor-1 `basin`:**
- depth 0.72, `glass: false`;
- rect `[-3.6, -2.6, 7.2, 10.2]`.

It is the source hole (structure 0, cols 3..9 x rows 5..14 → x −3.5..3.5, z −2.5..7.5) plus
0.1 m per side.

### Why things moved

The source hall is 37 rows deep, so with the spawn at z 12, rows beyond 28 fall off the 32 m
floor.

**Lab room.** At (0, −10) the room enclosed the default floor sign (3.5, −7.8). It moved
west:
- its north wall is 0.45 m off column (−5, −14);
- its door (east wall in the source, west after the turn) and buried entry stairs face the
  open strip east of shaft A.

**Rear gallery.**
- The dark sphere and ca_columns were at the slab edge (z −16). Both moved 3 m in; x is kept.
- The mirrored automaton (z −20) was 4 m beyond the slab. It moved 5 m in and still stands
  behind that line: 2 m behind instead of 4 m.

**Heights.**
- The schema minimum is 0, so the two −0.5 tokens stand at 0 (REQUESTS Q1).
- The mirrored plate at −0.5 would lie under the floor, which is static inference. Here it is
  visible.

### The basin (REQUESTS Q2)

`ca_bridge`'s history study is built for this hole:
- `Basin`, a collecting floor 7 x 10 m, top −0.60;
- `EntryRamp` and `ExitRamp` from that floor up to slab level;
- support tiles whose collision is enabled only for occupied cells.

The study says so in its source: "Only occupied recorded cells offer support. The basin is
lower down."

The Void basin cuts the slab there. Its bottom at −0.72 carries the study's own floor. A gap
is then a real 0.6 m drop, and the study's ramps lead out. On solid slab the gaps would hold
the visitor up like every other cell. The basin hangs 5.3 m above the catch floor.

## Interactions: what each work does, and the planned evidence

Probe check names are in `probe.gd`. **Nothing below is native-verified yet.**

| id | action | probe evidence (planned) | fit / dependency | remaining |
|---|---|---|---|---|
| ca_bridge history study | rule 30 record 15 x 24; support tiles; lattice; desk STEP / RUN / REPLAY / SEED / FLIP X9 / ROW; walk-follow | **API**: rule 30, twelve rows held, walk-follow. **Geometry rays**: occupied cell at slab height; the gap opens onto −0.6. **Standing** on an occupied pair: carried, gold follows. **Real walking** into the first live 2 x 2 hole (rule 30: cells 7–8, rows 6–7): drops 0.6 m, gold follows the fallen row, record unchanged. **Measured (desktop, first run):** a one-cell gap (0.4 m along the walk) is bridged by the 0.4 m capsule; the body walked from row 1 to row 4 at slab height. The probe now prints that crossing rather than asserting a fall. **Real walking** out of the basin up the exit ramp. **Real pointer**: STEP, RUN ×2, SEED, FLIP X9, REPLAY | basin required (in rooms.json) | ROW not pressed; climbing out of a narrow gap cell without the ramp (needs a jump) not run |
| film_cellular_history | concept monitor PAUSE / REPLAY / STEP / TURN VIEW | **Real pointer**: PAUSE toggles the stage, standing 1.1 m in front, on the slab beside the basin edge | | other buttons not pressed |
| lab_room | 8 x 7 x 3.8 m room, windows, sliding door, Turing apparatus on the plinth, signage | **API**: dimensions, door handler, mounted apparatus. **Real walking** to the door: it stays shut (measured) | the door waits for a palm scanner that this hall does not place (`auto_open_on_proximity` false; source behaviour); the room is seen through its windows | interior not entered |
| ca_columns | Life generations stacked as a MultiMesh, 1 layer per 0.6 s, continuous after 80 | **API**: a new generation appears within 3.3 s; instances > 0 | standalone camera, sun and environment neutralised by `floor_content` | height still follows from the capture time |
| mirrored_cellular_automata | 31 x 31 motif-stencil mandala, 0.8 m plate, evolves every 5 s | **API**: grid 31, symmetry 2, mesh present | height 0 (token −0.5) | |
| dark_sphere | presence | inspect | | |

## Not transferred

These are not inventoried:
- `sp`;
- `t`;
- the `bp:f,f,s,f,f,u,f` big-pipe utility at (5, 31). It would land at (1, −19), off the
  slab.

Walls (`w`) are not transferred.

## Museum differences (reported, not substituted)

- **em_plan row 93** matches the map: cells, rotation 90 for the film, offsets −0.5 and scale
  0.2.
- **The as-built bake differs.** Segment `cellularautomata|ca gameoflife` places the dark
  sphere and ca_columns at (5, 29) / (5, 30) in the segment frame, inside the lab room's seal.
  The bridge, lab and mirrored work sit at their map cells + 4 rows.

## Commands (coordinator)

```
python tools/audit_void_transfer.py cellularautomata_02
python tools/test_transfer_native.py cellularautomata_02 --focus bounds-1 --mode desktop
python tools/test_transfer_native.py cellularautomata_02 --focus record --mode xr
python tools/test_transfer_native.py cellularautomata_02
python tools/export_void_trial.py cellularautomata_02
node tools/test_void_transfer_editor.cjs cellularautomata_02
```

Focused cases: bounds-1, record, desk, film, lab, growth.

## Readiness notes (static)

- **History study:** builds its desk, 360 support shapes and 12 held rows synchronously in
  `_ready`.
- **ca_columns:** grows one Life generation per 0.6 s; 80 layers is about 48 s.
- **Mirrored automaton:** evolves every 5 s.
- **Film:** advances only while gazed.
- **Lab room:** builds synchronously; the chalkboard is deferred one frame.

## Untested claims

- Physical headset.
- Lab interior.
- ROW and the film's other buttons.
- Jumping out of a gap cell.
- Column walkers: continuous mode never spawns them in the source.

## Exact files (mine)

- `commons/void/trials/cellularautomata_02/rooms.json`
- `place_cellularautomata_02.py`
- `probe.gd`
- `REQUESTS.md`
- `STATUS.json`
- `HANDOFF.md`
- `transfer-status.json`
- `evidence/source-checks.json` (written by the audit)

Untouched: sources, maps, texts, catalog, `playable.json`, `layout.json`, `trial.tscn`,
shared code.
