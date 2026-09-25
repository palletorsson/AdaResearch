# Random_Space: chapter decisions

Sequence `randomness`, hall 13 of 14. 24 September 2026. Verdict: **Development.** The encounter was fixed before this pass: map placement, `noise_mixer:0:-0.5#plinth:0.9` and the `_material == null` guard. This pass is a targeted revision of the text only. `after.md` is the full chapter. `commons/maps/Random_Space/final.md` is not touched.

## Preserved

Title, opening question, both anchors (`<!-- @noise_mixer -->` and `<!-- @ -->`), paragraph order and every sentence the audit lists under Preserve. All of paragraph 3 is kept, including "Begin with OCT at one..." and "The picture remaps its range...", because the re-checks showed the auditor was wrong on both. The chapter has no code excerpts or footnotes, and none were added.

## Changed (3 sentences, all in the closing paragraph)

1. "A neutral palette or fixed shared scale would expose another part of this construction and make a useful later comparison."
   → "This display offers neither a neutral palette nor a fixed shared scale; either would expose another part of this construction and make a useful comparison for a future display."
   - Reason: the auditor and the re-checker agree the sentence is at fault. The re-checker's precise charge is "overstated": "later" reads as a promise, and no later room keeps it. The rewrite is the re-checker's rewording without its middle clause, because that clause would have been the chapter's third statement of normalisation.
   - Evidence: the palette is hard-coded at `commons/artifacts/noise_mixer/noise_mixer.gd:33-43`. Normalisation is unconditional at `noise_mixer.gd:127-134`. `apply_grid_config` takes only octaves, lacunarity, persistence, base_frequency and seed (`noise_mixer.gd:321-335`). Random_Game's works (`commons/maps/sequences/randomness.json:244-252`) offer no such comparison.

2. "The cycling platform in the next room puts uncertainty into timing instead of texture."
   → "The cycling stones in the next room put uncertainty into timing instead of texture."
   - Reason: handover repair. The sequence reader flagged the singular. Random_Game builds three stones from one crossing token.
   - Evidence: `commons/maps/Random_Game/map_data.json:2429` (`r_c...#stand:chasm`), `commons/primitives/cubes/random_cycle_cube.gd:145` (`stone_count = 3`), and Random_Game `final.md:7`, "Three cyan stones".

3. "You will know the order of its states while remaining uncertain about when it moves between them."
   → "You will know the order of their states. The pauses between them are drawn, and how much you can know about one depends on where you look."
   - Reason: the auditor and re-checker agree the sentence is overstated. The tablet shows each stone's drawn wait and the time left (`random_cycle_cube.gd:1105-1124`). A gold crown lights on the stone for the last 1.2 s of a standing wait (`random_cycle_cube.gd:670`, `:586`). REPLAY reseeds from the printed seed (`random_cycle_cube.gd:1123`, `:1131-1145`).
   - Why not the re-checker's wording: it says the current pause "can be read before it ends" and the next "has not been chosen yet". That is Random_Game's own reveal at `final.md:27` ("The current pause has already been chosen. The next one has not yet been drawn."), and the sequence reader faults Cubes' handover for giving away the next hall's discovery. The version used here keeps "drawn" and the order. It hands Game its own question ("ask where its warning was readable", Random_Game `final.md:40`) without answering it. I also rejected the auditor's shorter fix, "watching the stone alone... not when it moves", because the advance crown sits on the stone itself, so that fix is overstated too.

## Added (5 sentences)

- **Paragraph 1, opening handover.** Added: "Step OCT back down and the earlier picture returns exactly: unlike the terrain in the last room, this field keeps no history of the settings you passed through."
  - Random_Pheromone closes on "without depending on a history of visits". Before this pass the chapter never took that up.
  - The picture is rebuilt from scratch on every regeneration (`noise_mixer.gd:105-139`), from octaves, lacunarity, persistence, base_frequency and the stored offsets only (`noise_mixer.gd:142-158`). OCT is stepped (`noise_mixer.gd:287`: `octaves = 1 + int(norm * 7)`), so it returns to the identical value. The paragraph already fixes LAC and PER, and SEED is not introduced until paragraph 2.
  - The pheromone terrain deposits (`algorithms/randomness/pheromone_terrain/pheromone_terrain.gd:352`) and later reads what it deposited (`pheromone_terrain.gd:387-421`).
- **New paragraph after "The field adds scaled versions...".** Three sentences add the random ground, the placed work the chapter ignored:
  - "Look down: the pale, bumpy ground you walk across is random too, but built another way."
  - "It is made of small triangles, and the height of every corner is drawn on its own, as each column was on the WHITE NOISE side in Random Space Geometry: one bump tells you nothing about the next."
  - "In the picture on the plinth, neighbouring pixels are samples of the same smooth sum taken a short distance apart, so they mostly agree, and a broad feature carries across many of them."
  - Evidence:
    - Placement: `commons/maps/Random_Space/map_data.json:637` (`random_space:0:-0.3:1.4`); the mixer's plinth is at `map_data.json:590`.
    - Scene settings: seed 1, 11 x 20 m, resolution 50, chaos 1.0, height_scale 0.12, animation off (`commons/context/walkgrids/random_space.tscn:13-18`).
    - One independent uniform draw per vertex: `commons/context/walkgrids/RandomSpace.gd:163-169` and `:187-189`.
    - Triangles built from the height grid: `commons/context/walkgrids/TopologySpace.gd:44-75`.
    - Walkable trimesh collider: `RandomSpace.gd:244-249` and `:363-368`.
    - Pale emissive material: `RandomSpace.gd:115-117` and `:251-266`.
    - The WHITE NOISE side draws one `randf()` per column: `algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd:116`, label at `:154`. Random_Space_Geometry `final.md:13` teaches it.
    - The picture is a continuous sum of sines sampled at `px/128`: `noise_mixer.gd:114-118` and `:142-171`.
    - The hall image `hall_plan_map.png` shows the pale ground across the hall interior.
- **Closing, handover to Random_Game.** Added: "The heights under your feet were drawn once and hold still while you stand on them."
  - Animation is off in the scene (`random_space.tscn:18`; `RandomSpace.gd:268-270` returns early), and no config is passed, so nothing regenerates the ground.
  - The sentence sets up Random_Game's opening ("whether a body will still be there when yours arrives", `final.md:3`) without giving away its first question.

## Left alone, and why

- "Begin with OCT at one and inspect a broad light region beside a broad dark region." The re-checker's simulation at OCT = 1 found a broad tan field beside dark green blobs. The repetition of paragraphs 1-2 is style, not error.
- "The picture remaps its range, so those two visual changes need not report the same numerical difference." The re-check found it true; "report" means "indicate", not a displayed readout.
- The second statement of normalisation in paragraph 7 is true. The brief says not to shorten for its own sake.
- **Non-monotone palette (flagged, not changed).** Brown rock, index 6, is darker than light sand, index 5 (`noise_mixer.gd:39-40`), so lightness does not rank the values. That weakens paragraph 7's exercise to describe "only high values, low values". No sentence in the chapter is false because of it, and the addition budget went to the ground and the handovers. A future pass could add one clause naming the ramp's order.
- **worley_noise, shannon_entropy_meter, dark_sphere stay unmentioned.**
  - worley_noise would be a second field that is also stretched to its own maximum. Its code comment has the colours reversed: borders render blue and seed centres near-white (`commons/artifacts/worley_noise/worley_noise.gd:100-111`).
  - The entropy meter repeats Random_Entropy's seeded sample with no controls.
  - The sphere is ambient.
  - None fits a few sentences without crowding the ground, which is the work the visitor stands on.

## Limits

- *(Written by the text editor, before install. The main agent booted the hall, and its readback is in "Encounter change and museum evidence" below; that probe output was not saved.)* I did not start Godot. The mixer's plinth placement and the "5 verbatim" readback come from the brief's museum boot, not from a run of mine.
- The museum walk map still reports this hall SEVERED, because the ground's trimesh collider covers the floor (see `INTEGRATION.md`). The chapter's "you walk across" rests on the collider code, not on a walk-through.
- The ground's bump size is not given in the text. The scene's height_scale is 0.12 m, but the token carries a 1.4 factor whose effect on height I did not trace.
- The registry description of `random_space`, "A crystal that contains mathematical chaos algorithms" (`commons/artifacts/registry/commons_artifacts.json:12067`), is still false. It is outside the files I may write.

## Encounter change and museum evidence (added at install)

- **What was wrong.** Under the 26 August bench stamp the noise mixer and the entropy meter were laid on the 1 m raised ring, inside the block; the mixer's picture and SEED row were hidden.
- **Changes.** `map_data.json`: `artifact_placement: "map"`; `noise_mixer:0:-0.5` → `noise_mixer:0:-0.5#plinth:0.9` (`map.diff`). `commons/artifacts/noise_mixer/noise_mixer.gd`: `_regenerate` returns when `_material` is null, because the museum configures a body before `_ready` (`noise_mixer.diff`); no other placement passed config, and the grid lane configures after `_ready`, so defaults are unchanged.
- **Readback** (scratch museum probe): `StationPlinth` under `NoiseMixer at y 1.00, material=true texture=true`; WorleyNoise, RandomSpace, DarkSphere placed; `[em-pack] randomness · random space <- Random_Space: 5 verbatim + 0 slid of 5, 0 left behind, 1 plinth(s)`. Plan image: `hall_plan_map.png`.
- **Still reported.** `[em-walk] Random_Space: SEVERED and nothing reopens it`: the random ground carries a trimesh collider over the whole floor and the museum's walk map treats it as an obstacle, as it did under the bench layout. A body walks it. INTEGRATION.md §7.
- Companions `blurb.md` and `intent.md` rewritten (they described Gaussians, butterflies and Pollock drippers that are not placed).

| file | before | after |
|---|---|---|
| `final.md` | `5ee4f8d430a547742015918ba2cbe935dfd120c197d07f6c27115019bd9b466a` | `b4e80de791aac355e329f9a110d6e65b6efa1ccc4208255c726500a0983aa642` |
| `map_data.json` | `346b85110f9d1e68b2da4df2e518fddd18844b2e4638201a8766b99c996bb6c4` | `8c6d4707ab9c2c1ae08265b865b9653777460e733c0020a0d17c570352cef765` |
