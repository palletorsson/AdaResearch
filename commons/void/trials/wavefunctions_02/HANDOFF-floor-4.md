# WaveFunctions_3D_Wave_Propagation (floor 4) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-4.json` and this note. **No Godot run.**
Static checks:
- With floors 3 and 4 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 5 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  token height and scale 1.

## Placement

Same turn: `x = 11 - col`, `z = 14 - row`, with `sp` (11,2) on the arrival.
- **Depth.** The hall is 40 m deep and its pool is 13 m square.
- **Why everything moves.** Rigidly, the pool lands 1.5 m beyond the south edge, over both
  south columns and the risers. The pool can fit only in the central strip, crossing the
  shaft band; the other pieces move around it.

| id | at (rigid) | facing | h | notes |
|---|---|---|---|---|
| `f4_wave_propagation_3d_12_25` | **0, 3.5** (-1, -11) | 180 | 1.1 | See the pool notes below. |
| `f4_film_wave_neighbours_5_4` | **6, 11** (6, 10) | 0 | 0 | +1 z to clear the pool's north edge (0.75 m). The screen faces north. |
| `f4_coupled_oscillator_lattice_6_10` | **10.5, 9** (5, 4) | 180 | 0 | 4.5 m square, x 8.4..13.0, z 6.9..11.5. Rigid, it touched shaft B (0.04 m). |
| `f4_kusama_sine_18_11` | **0, -8.8** (-7, 3) | 180 | 2 | See the kusama notes below. |
| `f4_dark_sphere_21_32` | **-16, -8** (-10, -18) | 180 | 0 | Rigid was off the slab. |

**Pool:**
- **Extent.** About 13 x 13 m: x ±6.49, z -3.0..10.0. That is 1.0 m from both shaft
  openings and from the floor-4 pad (x -9.07..-7.53, z -3..-0.8).
- **Clearances.** 2 m south of the arrival; 1.2 m north of the risers.

**Kusama sine:**
- **Why it moved.** The 9.2 m field over shaft A.
- **New extent.** x -4.6..4.7, z -13.5..-4.3, y 0.84..3.58. It clears the columns at
  (±5,-14) and the risers by 1.4 m.

**Not transferred:** walls, `sp`, `t`.

## Supports, fit and dependencies

- **`wave_propagation_3d` (`museum:true`, `pool:true`)** (`WavePropagation3D.gd`):
  - **Deck.** Pool mode (:100) builds 20 x 20 tiles of 0.63 m with a 0.02 m gutter. Each
    tile is an `AnimatableBody3D` moved on the physics clock (:311). The deck is at the
    **token height of 1.1 m**.
  - **Access.** The rim is held "at the ramp landing" (:243), but **neither the map nor the
    script builds a ramp**. Visitors cannot step 1.1 m up onto the deck in the Void.
    Please check how the museum reached it. An access ramp or steps would be architecture,
    so I added none.
  - **Below the slab.** The `FrequencyControl` and `AmplitudeControl` CSG bars stand at
    local (±6.5, -3.0) (tscn). That is about 1.9 m below floor level, through the slab
    into floor 5's airspace at (±6.5, 3.5). It is the same in the source, where they
    were hidden under the grid floor.
  - **Lighting.** `museum` removes the scene's own Camera3D and lights (:115).
  - **Stale AABB.** The catalog's 22.6 m AABB is stale; the measured deck is about 13 m.
  - **Load.** 400 collision bodies is a performance note for Quest.
- **`coupled_oscillator_lattice`.** `config_fabric:bonds` and `config_comparison:true` are
  read from meta (:101-109). It has **buttons** (`act`, :368).
- **`kusama_sine`.** Reads `config_obsession` only, which is not set; the token y is 2.
  Animation; no controls found.
- **`film_wave_neighbours`.** The standard `concept_monitor` buttons.

## Focused tests

- **Pool:** after access is provided, walk onto the deck. Check that the tiles carry the
  visitor and that the outer row stays level.
- **Lattice:** press its comparison buttons and read back the bond and fabric state.
- **Kusama:** observation only.
- **Film:** TURN VIEW.
- **Clearances:** both shaft openings and the floor-4 pad, against the pool edges.
