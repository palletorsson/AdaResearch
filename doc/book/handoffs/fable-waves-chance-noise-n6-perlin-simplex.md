# N6 — Noise_Perlin_Simplex: what must stay the same (Fable, 13 September 2026)

Astra's card for active hall 6: set an explicit basis on each instance through the existing configuration path if it reaches the actual generator; match sample positions, grid size, amplitude, octave count, lacunarity, persistence, animation state and colour mapping, and record seeds; provide reachable common controls plus a selected-coordinate readout, freeze first and allow one-variable changes; fix the portal's role. Her status line: **"Logic/route probe passed; actual input and headset pending."**

## What was already there

The 2026-09-10 repair was right. It placed `#generator:perlin` on the right-hand display, matched every other term through the token, and gave both panels readouts that name the basis read back from the instantiated generator rather than from the scene name. The pilot probe was green: 51 checks bare, 54 live.

What it could not do was let anyone check the match.

- `contract()` on both roots reports each script's own bookkeeping variables. "The frequencies are the same" was a claim about two GDScript floats, not about the two FastNoiseLite objects that drew the fields.
- No saved run in this room had ever recorded a basis readback from the **perlin** side. The only readout quoted anywhere in the folder is the simplex panel's.
- Exactly **one** control in the whole room had ever been pressed through the input pipeline: REGEN on the simplex panel, and only under the live harness. Every slider and the REPLAY button were driven by `set_normalized_value()` plus `emit_signal()` — no pointer, no ray, no collider.

## What it is now

`#witness:show` on the simplex token, default `none` so the ten `simplex_noise` and twenty `perlin_noise` placements elsewhere are byte-identical:

- **`generator_readback()`** on both roots asks the live FastNoiseLite for its own `noise_type`, `seed`, `frequency`, `fractal_type`, `fractal_octaves`, `fractal_gain` and `fractal_lacunarity`, plus the visualizer's own `sample_scale` and `sample_offset` — the two terms applied to x and z before `get_noise_2d`.
- **A plate between the panels**, at about 1.25 m, printing both sides at once with no argument on it. Scoped to its own hall by the same ancestor walk the voxel bench and the wall panel needed.
- **Measured:** seed 20260910, generator frequency 0.05, fractal octaves 4, gain 0.5, lacunarity 2.0, fractal type 1, sample multiplier 10.0, sample offset 0.0 — every one of them equal. `noise_type` 0 against 3. The room's claim holds, and it is now a measurement instead of a label.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh noise`) | 71 checks, 0 failures |
| live (`run_wcn_probe.sh noise live`) | 88 checks, 0 failures |

**Actual input, which is what the card asked for.** Every control on both panels is now pressed or dragged through the desktop rig's pointer, each press counted at the button's own signal, with the basis read back after each: simplex REPLAY, perlin REGEN, perlin REPLAY, and the perlin FREQ slider dragged from 10.00 to 20.00 with the pointer reporting a drag midway. The basis survives all of them.

That mattered more than it looked. `PerlinNoise.apply_grid_config` only pushes the basis down when `_built` is already true, and the museum configures before `_ready`, so the two paths reach TYPE_PERLIN by different routes — and the child `NoiseVisualizer._ready` builds the whole field on TYPE_SIMPLEX before either of them runs. Reading the basis once, before any control is touched, cannot see any of that.

## Three defects in the pilot probe, each fixed

- `check(not (A and B))` on the two sampled coordinates passes when only **one** of them differs, so a single coincidence satisfied the two-bases-differ control. It now requires both, and prints all four values.
- The terrain check matched on token `noise_terrain`; the map places `perlin_noise_terrain`. Two distinct tokens, so the check passed without looking at anything. It now finds the body the map holds and measures its extent.
- The report said "no tracked hand" on runs where the pointer lane had passed, and said nothing at all on runs where it never started — `_live()` is a filename test, so the whole desktop block can be skipped in silence while the run still exits 0. The report now carries a `lanes` block naming which lane was expected and which ran.

## The door does not work, and now says so

`configurable_portal#dest_map:Lab_Path` resolves its destination by asking the grid system for a `load_map` method and then a node in group `scene_manager` for `load_scene`. GridSystem has neither, and nothing in the repo joins that group, so every path reaches a `push_warning`. A read-only `resolve_destination()` runs the same lookups and reports which branch would be taken without taking it. Measured at runtime: `resolves: false, via: "nothing"`.

**I did not make it live.** One line reaches the SceneManager autoload and GridSystem already performs exactly that lookup, so the fix is small — but in the museum a map switch severs the endless walk, so a door that starts working is a decision about the walk rather than a hall pass. **This is for Palle and Astra.**

## The route to Cellular Automata is the spine's, not this sequence's

Four texts asserted the active route continues to CA_Introduction. `curriculum_spine.json` does put cellularautomata straight after noise, and the museum carries its own passage — but `commons/maps/sequences/noise.json` ends its maps array at Lab_Path and names `proceduralgeneration` and `morphogenesis` as unlocks, and morphogenesis was absorbed into softbodies, so one of the two no longer names a sequence on the spine. The sentences now say which of those they mean. Making the sequence agree with the spine is a fold-level edit and is not made here. **Also for Palle and Astra.**

## Texts corrected

- `tutorial.md`: "Every line matches except the first" was false in both directions — one format string prints both readouts, the first line differs in one word and the second differs in every number. Its quoted `_noise_type_for` had two branches; the real one has four.
- `field_notes.md` quoted the placements as `#frequency:1`; the map carries `#frequency:10`.
- `artifacts.md` said "Thirty years of refinement" over 1983 to 2001, which `critical.md` correctly calls eighteen years apart.
- `artifacts.md`, `eye_shot.md` and `walked.md` predate the 2026-09-10 removal of `noise_terrain` and still list a six-body cast. They carry a dated head naming what changed; their generated clearance measurements are left as a record of the hall they measured, because hand-editing them would be inventing numbers.

## Not done, said plainly

- No headset walk, and no person at the controls.
- Whether a visitor can actually see the lattice signature `critical.md` argues for, at four octaves and half-metre cubes, is unmeasured. It is the room's own open question and the room now lets it be put to the fields instead of to their names.
- The portal and the sequence route, both above, are decisions rather than omissions.
- Astra's review.

## Files

`algorithms/randomness/simplexnoise/SimplexNoise.gd`, `algorithms/randomness/perlinnoise/PerlinNoise.gd`, `commons/scenes/mapobjects/configurable_portal.gd`, `commons/maps/Noise_Perlin_Simplex/map_data.json`, `commons/maps/Noise_Perlin_Simplex/{final,summary,technical,tutorial,field_notes,intent,artifacts,eye_shot,walked}.md`, `commons/testing/probe_wcn_noise_pair.gd` and its live port (both previously untracked), `tools/build_wcn_captures_page.py` (N6's views), and the captures page rebuilt and published. Forum: 260913-ix8mv.
