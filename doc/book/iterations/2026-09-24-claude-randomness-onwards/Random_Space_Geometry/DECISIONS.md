# Random_Space_Geometry — decisions

Sequence `randomness`, hall 10 of 14. 24 September 2026. Verdict: **Targeted revision** (text only; no map or code change).

## Preserved

Title, opening question, the single `@perlin_noise_bridge` … `@` anchor block, and every paragraph inside it except two insertions and one extended sentence. In particular: "Describe the difference before calling either one a landscape", the three-adjacent-columns exercise, the chance-run caveat, "comparable height displays … identical distributions", "a rule about relationships in space", the erosion/geology caution and "height fields with a colour mapping". The audit's structural point about repeated directions was not acted on (see below).

## Changes (audit and re-check agree)

1. **"Perception is good at supplying landscapes."** (overstated) — extended with the re-checker's wording: the work itself prompts the landscape. Subtitle label "From chaos to terrain": `algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd:183-190`. One blue → green → white ramp for every column on both grids: `perlin_noise_bridge.gd:122-123, 133-140`.
2. **"One productive misuse is …"** (overstated) — "misuse" → "discipline", with the re-checker's clause pointing at the subtitle and palette (shortened, since the previous paragraph now names both). The re-checker's reading was taken over the auditor's "cut it": the instruction is the room's discipline, and the artifact's own desire line says the same (`perlin_noise_bridge.gd:11`).
3. **"A future shared scale or alternative palette …"** (false) — replaced with the re-checker's wording. One `MAX_HEIGHT` (`perlin_noise_bridge.gd:26`) and one `_apply_column` for both grids (`:122-127`); panel rows are OCTAVES, FREQUENCY, SEED, RESAMPLE only (`:199-208`); `apply_grid_config` is `pass` (`:254-255`).
4. **"The next room uses random samples for estimation …"** (overstated, scope) — re-checker's wording: the dartboard, not the whole room, estimates. `monte_carlo_dartboard.gd:426-437`; next hall's four works confirmed in `commons/maps/Randomness_Examples_of_Randomness/final.md`.

## Additions (four sentences, each code-verified)

- **FREQUENCY leaves the white grid still** (paragraph 2). The white heights come from `rng.seed = _seed_val` and `rng.randf()` only; frequency and octaves go to `_noise` alone (`perlin_noise_bridge.gd:104-116, 119, 122`). Every rebuild reseeds, so the same 256 white values return.
- **OCTAVES exists** (paragraph 2). Slider sits in the same panel row as FREQUENCY (`:200-203`), sets `fractal_octaves` 1–6 (`:105, 216-218`). "Finer layers of the same noise" relies on FastNoiseLite's default fractal type (FBM), which the script does not override. Named here so Random_Space can build on it rather than introduce it.
- **env_one, the placed work doing the white-noise rule at room scale** (closing). Positions uniform in a 30×15×30 box (`algorithms/randomness/envOne.gd:72, 1014-1018`); link pairs drawn by `randi()` with no distance test (`:1047-1052`); distance picks only the link type (`:1060-1068`). Placed at `env_one:0:4:0.5` in `map_data.json` interactables row 24. No location word is used, because the map lane and the museum bench put it in different places.
- **Handover to the dartboard** (closing). Each THROW is two independent uniform draws (`monte_carlo_dartboard.gd:239-244, 431-432`) that consult no earlier dart — the same kind of draw as the white grid and env_one. The question (even cover, or clumps and gaps?) feeds the next hall's "covers the space fairly enough".

## Left alone, and why

- **Repeated directions** (FREQUENCY given at paragraphs 2 and 3, landscape reading withheld at 1, 3, 6). Not among the re-checked claims, and the re-checker showed these are not exact repeats (delay vs. withhold; paragraph 6 asks you to look for terrain). All true sentences; not rewritten.
- **Where the bridge stands / its controls facing away.** Not re-checked, and not code-verifiable: the map puts the bridge (row 23, col 6) beside env_one (row 24, col 5), the museum bench puts env_one at the entrance and the bridge deep in the hall. Needs a walk.
- **random_transformations_geometric, sculpt_one, curl_noise_particles, dark_sphere.** Not added. The three far works sit beyond the map's 24 structure rows, and whether the museum stands them in the hall, in the passage or over void is unwalked. random_transformations_geometric also contradicts its own docs (translation overwritten). dark_sphere does nothing for the inquiry. curl_noise_particles ("coherence without chance") would be the next addition if a walk confirms it is visible.
- **Back-reference to the mushroom clearings** (sequence notes: `mushrooms.gd:650-665`, a FastNoiseLite field thresholded at -0.3). The audit rates the incoming handover as working; kept to four added sentences.
- **Bench stamp drops y offset and scale** (env_one full-size, half below deck). Curator matter, not chapter text.

## Limits

No Godot run, no walk, no capture. env_one's visibility at full museum scale, and the effect of the four extra directional lights on the grid colours, were not measured. `final.md` untouched; only `after.md` and this file written. `map_data.json` carries an uncommitted 1234-line change from another session (and an untracked `landscape_research.md` sits beside it); its interactables layer matches `map_data.before.json` cell for cell, so the placements cited above hold for both.

## Installed

`after.md` was installed to `commons/maps/Random_Space_Geometry/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `29bf71622aa8…`, after `5a4da0bac6a3…`. No runtime or learner status changes, because the text changed and nothing new was walked.
