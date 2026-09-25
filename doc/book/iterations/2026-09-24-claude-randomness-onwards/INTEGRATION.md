# Integration — patches for Astra

Shared files this block does not edit directly (registries, `museum_core_encounters.json`, sequence membership, `curriculum_spine.json`, baked plans, `WORKING.md`, whole-book exports). Each entry: file, exact change, reason, hashes.

---

## 1. Randomness_10_PRINT_Algorithm — room record

**File:** `commons/data/museum_core_encounters.json`, key `rooms.Randomness_10_PRINT_Algorithm`.

**Why:** the record names `ten_print_maze_3d` as the primary and describes an ant-navigation repair. The revised chapter carries its first reading on the printer and the two works it prints onto: the floor, and a new walkable block of solid walls. The upright fields stay as the last section, seen and not entered. The text and map hashes in the record are the pre-revision ones.

**Exact change** (replace these fields, keep `sequence` and `text_path`):

```json
"primary_tokens": ["ten_print", "ten_print_structure"],
"reason": "Take one line of BASIC apart at its coin (205.5) and its semicolon, see the same stream laid on the floor, then walk into twelve of its characters stood up as solid walls to find whether they left a way through.",
"status": "desktop_checked_headset_pending",
"text_sha256": "56990ed63307386d326e6462b1dbce436bafc726d44514c0d27a62d272e51d4f",
"map_sha256": "e1fc0befa3a25392a31d57855d1a7db4b1090a57636ddee3c691e7e4dca6a77d",
"learner_verified": false,
"verification_scope": "Two headless gates. probe_ten_print_hall.gd (11 checks): floor linked on channel hall, 0 of 122 floor cells disagree with the screen, console line reads the book's line, SEMICOLON removes ';' and collapses the floor to one column and back, BIAS moves the constant (205.1 -> 0.87 forward, 205.9 -> 0.07), default coin breathes (0.70 / 0.29 forward over characters 0-269 / 270-399), next-cell tile visible, floor has no collider, upright maze has no collider and stands in the Y-Z plane. probe_ten_print_walkable.gd (museum lane): the slab block is kept verbatim, 12 solid slabs 2.40 m, same 12 coin results as the printer, 8 regions 7 open 1 sealed, every open region has exactly two mouths (no forks; four V bays, two corners, one way through), a way through, wrap-width comparison (3, 4, 6, 12 to a row), no museum seal severance, entry to exit reachable on the museum's own walk cells, a 0.5 m capsule walks the way through. No headset walk.",
"local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Randomness_10_PRINT_Algorithm/DECISIONS.md"
```

### 1a. Anchors

The record should also know that `@ten_print_structure` covers two placements of one token in this hall, the floor at [12,11] and the walkable slabs at [8,11]; the tag grammar is token-only. `@ten_print_maze_3d` now covers only its own section, where it previously covered the whole chapter.

---

## 2. The 10 PRINT clipboard text is wrong about the hall

**File:** `commons/context/clipboard/tutorial_text/ten_print_axioms.gd` and its `.md` twin. Shared: also placed in `Corridor_Randomness_10_PRINT_Algorithm` and `Curation_Bay_randomness_9`, both outside this block, so not edited here.

**What is wrong, measured against the source:**

| Clipboard says | Fact |
|---|---|
| "We have projected this 2D texture into 3D space, giving it height and collision." | `ten_print_maze_3d` has no collider and no static body (probe_ten_print_hall.gd case J). |
| "Every second, a wall rotates." | The scene sets `wall_change_interval = 0.08`: about twelve cells turn every second in each field. |
| "complexity emerges from simple rules (Cellular Automata)" | 10 PRINT is not a cellular automaton. Each cell is an independent draw with no neighbour rule. Cellular automata arrive two sequences later. |
| "Next: Noise. We leave discrete randomness behind." | The next hall is Random_Cubes, still in Randomness. |
| "It seeks an exit that doesn't exist" | True in effect, for a different reason. The exit exists in the drawing; the ant's own navigation grid (4-connected moves on 2×2 sub-cells) shuts every channel between parallel diagonals and holds it among the few sub-cells around one grid corner. |

**Proposed replacements** (same positions in the text):

- "We have projected this 2D texture into 3D space, giving it height and collision." → "In this hall the texture stands up as three large fields. They are only lines: you can walk through them but not along their passages. A smaller block, printed from the printer's own coin, has solid walls and can be walked."
- "In this simulation, the walls are not static. **Every second, a wall rotates.**" → "In this simulation, the walls are not static. **Several times a second, a cell turns.**"
- "10 PRINT demonstrates how complexity emerges from simple rules (Cellular Automata)." → "10 PRINT demonstrates how structure can appear from independent random choices, with no rule connecting one cell to the next."
- "[b]Next:[/b] Noise ... We enter the world of continuous, smooth chaos." → "[b]Next:[/b] Random Cubes. The coin gets six faces, and you compare one throw with a growing record."

**Also:** the clipboard's code display shows raw BBCode tags (`[center]`, `[font_size=28]`) as text in the hall. The source read traced it to the regex in the clipboard's code display; the exact fix was not worked out. Not fixed here; noted so the text patch is not blamed for it.

---

## 3. The science screen in the 10 PRINT hall shows invented data

**File:** none to patch in this block; `science_screen:180:1.5#mode:grid` in this hall's map.

The screen's grid mode looks for a SimGrid in the hall. This hall has none, so it draws a placeholder heatmap and cycles the blurb and intent. The placeholder reads as data about the maze and is not. Proposal: either remove the token from this hall's map, or give the science screen a text-only mode for halls without a grid. The chapter does not refer to it.

---

## 4. Leftover placements in the 10 PRINT hall

Not removed, per the assignment. Listed so a curator can decide.

| Token | What it does in this hall |
|---|---|
| `remove_random:90` | Nothing visible was found in the source read. The old intent claimed it modifies the maze; no link to any 10 PRINT artifact was found. |
| `pickup_cube_placer:90` | Scatters unseeded cubes, some beyond the hall's edge. Not linked to the maze. |
| `nature_system_demo:90` | Brings its own WorldEnvironment. The museum leaves it behind (`[em-pack] … 12 verbatim … of 13`). |
| `dark_sphere` | Remainder from an earlier layout. |

---

## 5. Random_Cubes — room record

**File:** `commons/data/museum_core_encounters.json`, key `rooms.Random_Cubes`.

**Why:** the record names only `dice_throw` and its scope says no throwing or settlement was validated. The status stays `source_checked_draft`: the new evidence is headless physics gates, not a desktop or headset session. Settlement is now validated in headless physics, with negative controls, and the chapter carries three more works.

**Exact change** (keep `sequence`, `text_path`):

```json
"primary_tokens": ["dice_throw", "coin_toss", "random_edge_profile"],
"reason": "Throw a die and a coin into two records that forget different things; walk through forty-eight bounded draws that show one rule in space.",
"status": "source_checked_draft",
"text_sha256": "58a37f7c2b4d7ef88230de60a8fd11ed71f5f4331a52fa8ad784958ca60ee3d4",
"map_sha256": "b90c08efcc188867994a514aecc34bcd5900abeee7ea09208b521c1dd9412415",
"learner_verified": false,
"verification_scope": "probe_random_cubes.gd, each case against the shipped script: reward rain now over the table (0.03 m, was 126.5 m); a die resting on its felt is read; sixteen seeded throws read correctly at 60 and 90 Hz (shipped: 2 and 15); the rain never moves the die (own collision layer) and lands on the felt instead of tunnelling; a desktop drop is read; a held coin is not counted in the hand (was); one throw adds one; a desktop coin is read once on landing; #disclosure:origin builds and fills SPIN/DROP/TILT. No headset throw.",
"local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Cubes/DECISIONS.md"
```

## 6. Random_Rotate_Random_XYZ — room record

**File:** `commons/data/museum_core_encounters.json`, key `rooms.Random_Rotate_Random_XYZ`.

**Exact change** (keep `primary_tokens`, `sequence`, `text_path`):

```json
"reason": "Watch two stacks of one size turn under one rule at one rate, with drift, sinking and darkening switched off; name what still differs; restore the arrangement without replaying its future.",
"status": "desktop_checked_headset_pending",
"text_sha256": "a418a65eab6c5a7d9bb107880a9e2c9f2c4d126d0f02aca176a55111373bb4b8",
"map_sha256": "9c71df12ff7f593dcf318283e33d0c936048a46d04f23a5f5e66b6b8d0deb9d4",
"learner_verified": false,
"verification_scope": "probe_rotation_study.gd: default placement unchanged; #study:rotation matches rates (0.3/0.3), removes drift, sinking and colour, lays the prisms on 12 even columns (shipped: 11), fits the display to 10 m alone, and turns each cube exactly as a matched run does (0.000000000 rad). Map placement keeps the whole display inside the hall. No headset walk.",
"local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Rotate_Random_XYZ/DECISIONS.md"
```

---

## 7. Engine notes found on the way (not patched here)

| Where | What | Suggested |
|---|---|---|
| `commons/scenes/endless_museum.gd`, `_stamp_necklace` | A bench-stamped hall reads only the FIRST `#key:value` of each token from the map (`cfg_of[...] = {kv[0]: kv[1]}`), with the rest of the string left on the value. | Parse every `#key:value` pair, as the transplant path does. Until then a token under a bench stamp should carry one key. |
| `commons/scenes/endless_museum.gd:13503`, `_suppress_chrome` | Defined, never called. A demo scene's own Camera3D marked current (the decay stacks' does) took over a museum proof shot in Random_Rotate_Random_XYZ. | Call it on each stamped and transplanted body, or rely on the walker's camera guard and make shot runs call it. `commons/testing/probe_hall_shot.gd` works around it for evidence photographs. |
| `commons/grid/GridInteractablesComponent.gd`, `CONFIG_PARAM_NAMES` | `#stack_fit:10` is read in the grid lane as the tutorial shorthand, giving a 2 m miniature display. Grid-system change, so not made here. | Add `"stack_fit"` to the list. Only Random_Rotate_Random_XYZ carried the key, and its token now uses `#study:rotation` instead. |
| `algorithms/randomness/dice_throw/dice_throw.gd` | On its felt a landed die hops a few mm per tick and, at the desktop's 60 Hz, usually keeps turning about the vertical at 5-9 degrees per tick (bounce 0.4, gravity scale 1.5); at the headset's 90 Hz it mostly comes to rest. The reading is repaired (same face on top at a steady height); the visible buzz and spin are not. Single-setting sweep, sixteen seeded throws each, 60 Hz, dice asleep after 6 s: see `Random_Cubes/die_settle_sweep.out.txt` (script `die_settle_sweep.gd` beside it). No single setting fixes it without changing the throw on the 22 maps that place it. | Leave the physics, or tune per placement once a headset has thrown it. |
| `algorithms/randomness/SlopeGradientCubes.tscn` (token `RotateGridCubes`) | A 7 x 30 field of 1 m cubes; in Random_Rotate_Random_XYZ most of it lies beyond the hall. | A smaller `grid_size` for that placement, if the field should stay. |
| `commons/scenes/endless_museum.gd` walk map | A walkable body with a collider is treated as an obstacle: Random_Space's random ground (a trimesh floor of +/-0.12 m bumps over the whole hall) seals the interior and the museum logs `[em-walk] Random_Space: SEVERED and nothing reopens it`, as it did under the bench layout. A body walks it; the museum's own walker cannot. | A venue flag for floor-like bodies, or leave as reported. |
| `ada_run/necklace_hand.json`, `randomness|random pheromone` | The bench passed `{"comparison": "true#walk_seed:190919"}` (first key only, tail attached), so the terrain's comparison console, ATTRACT/AVOID and the seeded replay were never built in the museum. The hall now opts out with `artifact_placement: "map"`; a museum boot reads back comparison=true, walk_seed=190919 and a StepComparison child. | Parse every key on the bench path (see the first row). |
| `ada_run/necklace_hand.json`, `randomness|random space` | The bench laid the noise mixer and the entropy meter on the 1 m raised ring, inside the block. The hall now opts out with `artifact_placement: "map"`, and the mixer stands on a 0.9 m plinth (`#plinth:0.9`); `noise_mixer.gd` gained a guard so config before `_ready` does not dereference a missing material. | — |
| `ada_run/necklace_hand.json`, `randomness|random cubes` | The force-placed bench overran the hall: two spawners at one point, up to four fence slabs in one cell, two slabs sunk in the raised block. The hall now opts out with `artifact_placement: "map"`. | Re-lay that bench, or leave the hall map-placed. |
| `ada_run/necklace_hand.json`, `randomness|random rotate random xyz` | The bench centres the 10 m decay display at x 10.5 in a 12 m hall. The hall now opts out with `artifact_placement: "map"`. | Re-lay that bench, or leave the hall map-placed. |
| `algorithms/cellularautomata/ca_showcase/base_ca.gd` and the CA halls' frame cost | `BaseCA._process` never stops: a work whose picture has stopped changing keeps paying for its update every frame while its hall is loaded. Script cost per frame, desktop, headless, every work in the eight CA halls configured from its map token (36 works; tool, specs and outputs in `_frame_cost/`: `script_cost.gd`, `sc_ca.out.txt` before and `sc_ca_now.out.txt` after the repairs, plus `probe_ca_stop_and_fit.out.txt`):<br>- `crackpropagation_ca` (CA_EdgeOfChaos): 61-76 ms across four runs, **repaired here**, now 1-6 µs.<br>- `line_network_ca` (CA_Introduction): 15-24 ms across five runs, **repaired here**, now 2-8 µs.<br>- `disease_spread_ca#museum_budget` (CA_EdgeOfChaos): 7.9 ms. Its script carries another session's uncommitted budget edits.<br>- `persian_rug`: 5-11 ms across two runs. Its picture keeps changing, so this is not a stop case.<br>- `crack_propagation_ca` (CA_SoftRules): 4.8 ms.<br>- The other 31 works: under 0.5 ms.<br>The 90 Hz headset budget is 11.1 ms for everything, and a Quest CPU is slower than this desktop. | Profile CA_Introduction, CA_EdgeOfChaos and CA_SoftRules in the headset. A generic 'stop when a step changes nothing' in BaseCA would change eight scripts and is left to Astra. |
| `algorithms/cellularautomata/ca_showcase/self_organization_ca.gd`, plain placements | Without `#study:difference` the work runs its 64³ averaging every frame: **about 4.9 s per frame** on a desktop, headless (`_frame_cost/bcc_so.out.txt`, `baseca_cost.gd`). CA_EdgeOfChaos is safe: its `#study:difference` mounts the study and sets `is_running = false`. Nine other maps place the plain work, eleven placements in all: MissionHall_Cellularautomata x2 and MissionRooms_Cellularautomata x2 (as `exhibit_furniture#mount:`), Ribbon_Cellularautoma_08 (bare token), and one furniture mount each in Trial_antrooms, Trial_castelvecchio, Trial_grande, Trial_kanazawa, Trial_sainsbury and Trial_uffizi _cellularautomata. Corridor_CA_EdgeOfChaos lists it in a curation station. All are outside this block and were not checked in the museum. | Give those placements the study key, or bound the loop. The file also carries another session's uncommitted edits. |
| `commons/artifacts/curl_noise_particles/curl_noise_particles.tscn` (Random_Space_Geometry) | The heaviest work in Randomness and Noise at 4.4 ms of script a frame. Every other work in the 23 halls measured under 1 ms (`_frame_cost/sc_rn.out.txt`). | Headset profile if that hall stutters. |
| `commons/artifacts/randomness_space/removal_arena.gd` | **Repaired here.** In the museum's headset branch `_player` is never set, so the arena recognised no body and removed nothing in VR (Random_Remove, Random_Game). It now recognises the XR Tools PlayerBody (group `player_body`) when there is no desktop walker. Its readout plate also hid the text (front face 1.5 mm in front of the label). Gate: `probe_removal_arena_vr.gd`, V/D/S/R. | Walk it in a headset. `endless_museum.gd` could expose one `is_player(body)` so artifacts stop re-deriving it. |
| `map_info.museum.piers` in CA_EdgeOfChaos and Random_Remove (**set here**), and Random_Entropy (proposed) | The plan stamps colonnades into these halls: 28 piers in CA_EdgeOfChaos, one enclosing the changed address inside volume B (the chapter's core encounter); 20 in Random_Remove, on the arena's apron; 27 in Random_Entropy, in the glass field and along the ruin's wall line. The museum reads piers from the plan row, which `tools/em_map_halls.py` derives from this key. | Re-run `tools/em_map_halls.py --apply` (it rewrites `ada_run/em_plan.json`, a baked plan, so it is Astra's), then boot the two halls. Decide Random_Entropy. |
| `commons/artifacts/perlin_terrain_sculptor` (`_input`), `monte_carlo_dartboard.gd:276-284` | Two works read the keyboard across the whole museum. In Noise_Voxel, R/N reseed and the arrow keys move the threshold off its ladder. In Randomness_Examples_of_Randomness, D/SPACE/R fire from the walking keys on desktop, and SPACE toggles AUTO, which can undo the chapter's AUTO step. | Gate the input on the visitor being at the work (or on a focused console), as other artifacts do. |
| CA_ExpandingSpace `proximity_study.gd:123-131` | The floor label reads `RECOVERY RAMPS ON LEFT`, which contradicts the corrected chapter (the ramps are on the desk's side), and it reads upright only to someone facing back toward the entry. The `WitnessTag` is upside down to an arriving visitor. | Re-text and re-orient both labels. |
| Random_Gaussian token `#controls:compact#control_front:1.05` | By the audit's arithmetic the compact console casing stands between the marked standing position and the readout plate the chapter reads from (in flight, clipped, mean, σ, the paused line). Plausible, not seen. | Look from the standing spot. If it is hidden, drop `#controls:compact` or raise the plate. |
| Random_Entropy `entropy_ruin` | The ruin does not wait, so the chapter carries two sentences about arriving mid-run. | An `autostart:false` option (as on the weathering wall). If it lands, remove the two sentences added in that hall's change 6. |
| Random_Mushrooms `mushrooms.tscn:5, 25-26` | A stray default PrismMesh stands at the centre of the bed, with a spare Camera3D and a 24 m FillLight. | The audit's `_prepare_stand` fix, or delete the prism. |
| Lab_Path | The museum does not build this hall (`commons/data/book/noise.json:193-197`, `drop: true`), and Noise_Perlin_Simplex already hands over to Cellular Automata, so a reader of the book meets two handovers. | Palle to decide: grid-lane pause only, or a hall. |

---

## 8. Room records: hashes for every hall in this block

**File:** `commons/data/museum_core_encounters.json`, `rooms.<Map>`.

**Why:** the block changed 30 of the 31 chapters and 8 maps. Separately, 16 records were already stale when the packet was cut: their hashes are older than the packet's own baseline (every Noise and CA record except CA_AgentsCircuits; Lab_Path's only in text). The table compares each record with **this block's version** of each file: the `after.md` it installed, and the map it left.

**Four chapters and one map were changed by another session after this block installed them**, between 14:16 and 14:20 on 24 September, with no forum post before the change (forum 260924-zgl38). They are the `final.md` of Randomness_10_PRINT_Algorithm, Random_Cubes, Noise_Perlin_Simplex and CA_Introduction, and CA_Introduction's `map_data.json` (`#study:arrival`). Those texts were not checked by this block. Hash whatever is canonical when you integrate; the `LIVE` lines in each hall's `HASHES.txt` give the values at handback.

**Status and learner fields are not changed here.** Per the brief, an edited text does not raise a runtime or learner status. The three halls whose encounters were rebuilt and gated (10 PRINT, Cubes, Rotate) carry their proposed `status` and `verification_scope` in sections 1, 5 and 6. Random_Pheromone, Random_Space and CA_Introduction were rebuilt in the museum and read back, and CA_Introduction's line network is also gated by `probe_ca_stop_and_fit.gd` (see their DECISIONS). None was walked in a headset, so their status is left for Astra to decide.

| seq | # | map | changed here | record text | now | record map | now | note |
|---|---|---|---|---|---|---|---|---|
| randomness | 1 | Random_Definition | text | 449ee9880e76 | a38185f6b49a | 9345ed71e5f7 | 9345ed71e5f7 | - |
| randomness | 2 | Random_Entropy | text | c9616c6da7d9 | 7ee078e1a76f | 9f817f4684ab | 9f817f4684ab | - |
| randomness | 3 | Random_Remove | text + map | 5156030db490 | 6c1dabdc09f8 | 16dbe8be6246 | 49ba0ecea389 | - |
| randomness | 4 | Randomness_10_PRINT_Algorithm | text + map | 259612018d57 | 56990ed63307 | 0e379f864cf0 | e1fc0befa3a2 | full record in section 1 |
| randomness | 5 | Random_Cubes | text + map | a7b9c7d24246 | 58a37f7c2b4d | 4d7b2e057730 | b90c08efcc18 | full record in section 5 |
| randomness | 6 | Random_Rotate_Random_XYZ | text + map | 4ab6e6a1681f | a418a65eab6c | fdb8aa33404f | 9c71df12ff7f | full record in section 6 |
| randomness | 7 | Random_Walk | text | a72a6459a2fd | a9aceb725976 | bb7b9a11ecf8 | bb7b9a11ecf8 | - |
| randomness | 8 | Random_Gaussian | text | 847f74319596 | c31b41764113 | fdf8781e1981 | fdf8781e1981 | - |
| randomness | 9 | Random_Mushrooms | text | 48de2a7ffa53 | 673ef28041b7 | 7b331ea18775 | 7b331ea18775 | - |
| randomness | 10 | Random_Space_Geometry | text | 29bf71622aa8 | 5a4da0bac6a3 | 623f375fab28 | 623f375fab28 | - |
| randomness | 11 | Randomness_Examples_of_Randomness | text | 1664e9ad746a | 2a5c95fbf29e | c09c7196da0d | c09c7196da0d | - |
| randomness | 12 | Random_Pheromone | text + map | 2ceed42c9941 | 2883c0f7873b | 722f2c04562e | 2283ff15d374 | - |
| randomness | 13 | Random_Space | text + map | 5ee4f8d430a5 | b4e80de791aa | 346b85110f9d | 8c6d4707ab9c | - |
| randomness | 14 | Random_Game | text | a076c53d5357 | 7ebe94c86cb4 | d58f1dd4bc35 | d58f1dd4bc35 | - |
| noise | 1 | Random_Noise_Types | none (preserved) | 7aa551478c31 | f94fc7ff8883 | 77936c9ead2c | 81fefdb5c28f | record already stale at baseline (text, map) |
| noise | 2 | Noise_Columns | text | 6431a6046c43 | 57cfa534fde3 | 6052c9aa186d | 06b174a5ef31 | record already stale at baseline (text, map) |
| noise | 3 | Noise_One | text | 24eb619b5cf1 | b0f02dc3f2a7 | d63c41e4f594 | 6c8620e7368a | record already stale at baseline (text, map) |
| noise | 4 | Noise_Voxel | text | 06264cd74c02 | 1714ff63c8bb | 62191f51cdc8 | 101246a54330 | record already stale at baseline (text, map) |
| noise | 5 | Noise_6_Wall | text | 399a8f654aba | fc9bc18446af | bf64859d03a7 | 63dc252b334e | record already stale at baseline (text, map) |
| noise | 6 | Noise_Inside_Noise | text | f10412f3539c | 121a5664f996 | d35a465d17c2 | f1a082ed07da | record already stale at baseline (text, map) |
| noise | 7 | Noise_Space_10 | text | 32e6473ae9e7 | 66acc8cc33ef | 3dd2e47b3b4a | 0c3d80cd8890 | record already stale at baseline (text, map) |
| noise | 8 | Noise_Perlin_Simplex | text | 669c8888b7f1 | afb16c279fd6 | efc6152f356c | 1964d1bb14a8 | record already stale at baseline (text, map) |
| noise | 9 | Lab_Path | text | 30ec6de21896 | f566363c70e8 | 8b14ce1bdba6 | 8b14ce1bdba6 | record already stale at baseline (text) |
| cellularautomata | 1 | CA_Introduction | text + map | 491dd3cd3a19 | af04853c2f53 | 0dd7f6783f53 | 4823488f2925 | record already stale at baseline (text, map) |
| cellularautomata | 2 | CA_ElementaryRules | text | 76266e161d5d | 0ce19707a1be | a9d84eccd76e | 2ca45cf62d98 | record already stale at baseline (text, map) |
| cellularautomata | 3 | CA_GameOfLife | text | 7bd487ca69fd | 5dfbd9069735 | 1bb63693cf5d | a4486083e834 | record already stale at baseline (text, map) |
| cellularautomata | 4 | CA_BeyondBinary | text | 9922a99ec9f4 | 2110f41e925b | 9bbeb8e919a8 | cc4b09ea600f | record already stale at baseline (text, map) |
| cellularautomata | 5 | CA_ExpandingSpace | text | a206ec9904d6 | a4d172fc5f2e | 2a76177aa29a | 1580ee6bc310 | record already stale at baseline (text, map) |
| cellularautomata | 6 | CA_SoftRules | text | ef9a7fe34cfb | 1da9b7e36817 | 60e4d9d98caa | 6eeea6ca3ca1 | record already stale at baseline (text, map) |
| cellularautomata | 7 | CA_AgentsCircuits | text | b192cbe9b731 | b17878f9d565 | d0fcd3ec00d5 | d0fcd3ec00d5 | - |
| cellularautomata | 8 | CA_EdgeOfChaos | text + map | 86d3283b5184 | 992937ab3cda | 80e06512c53e | ab0576883518 | record already stale at baseline (text, map) |

**Exact change** (merge each object into `rooms.<Map>`; keep every other field; sections 1, 5 and 6 cover their three halls in full):

```json
{
  "Random_Definition": {
    "text_sha256": "a38185f6b49ae97663585972d8876ab1b06498470f5be8eec9933d9bf6d3d1c8",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Definition/DECISIONS.md"
  },
  "Random_Entropy": {
    "text_sha256": "7ee078e1a76f9da1f2df98fc816578811b752cda1b8bc394dd5a6f3eab26bd8f",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Entropy/DECISIONS.md"
  },
  "Random_Remove": {
    "text_sha256": "6c1dabdc09f8564769826d5676e161ec39e4bf917f18a9f7bb59e625525c6de7",
    "map_sha256": "49ba0ecea3891195af06fe5a87c686795be91713d46174f8f770db0a604998ad",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Remove/DECISIONS.md"
  },
  "Random_Walk": {
    "text_sha256": "a9aceb72597616386492bb6737021b3ba34bc3f5339b4b049eb49c751ff7698c",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Walk/DECISIONS.md"
  },
  "Random_Gaussian": {
    "text_sha256": "c31b41764113d4a1ee3edb0aa20c752fac8abf95e51a1055f745e9fa7ecf7100",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Gaussian/DECISIONS.md"
  },
  "Random_Mushrooms": {
    "text_sha256": "673ef28041b76753d319aed4e9c0b50d65797c8efda8d294a95bc53fbeed54da",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Mushrooms/DECISIONS.md"
  },
  "Random_Space_Geometry": {
    "text_sha256": "5a4da0bac6a3b7fc22c1c796c54342b96b86a96ae57f7ecc6866f344f957cbf9",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Space_Geometry/DECISIONS.md"
  },
  "Randomness_Examples_of_Randomness": {
    "text_sha256": "2a5c95fbf29e2522f260d7fd076f15f2fa2ec43f1ed62149374cfbb6fe124302",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Randomness_Examples_of_Randomness/DECISIONS.md"
  },
  "Random_Pheromone": {
    "text_sha256": "2883c0f7873b95d086b79ae5b8d36785464c3a9cc0093047e35de45250aca293",
    "map_sha256": "2283ff15d3743a64c70a477b58f524f40f6d74dd52ac635a38e0405958f91901",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Pheromone/DECISIONS.md"
  },
  "Random_Space": {
    "text_sha256": "b4e80de791aac355e329f9a110d6e65b6efa1ccc4208255c726500a0983aa642",
    "map_sha256": "8c6d4707ab9c2c1ae08265b865b9653777460e733c0020a0d17c570352cef765",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Space/DECISIONS.md"
  },
  "Random_Game": {
    "text_sha256": "7ebe94c86cb420a0864fcecd656aa1c38cb1d245998dc7b2f5569fa99c5bd760",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Game/DECISIONS.md"
  },
  "Random_Noise_Types": {
    "text_sha256": "f94fc7ff88835c253ca2622e2a638acb6729b057176fe15a3bef42b55b818f30",
    "map_sha256": "81fefdb5c28f4943ea912123791c6dff61ab2938182ff6adfa03166bf51a9466"
  },
  "Noise_Columns": {
    "text_sha256": "57cfa534fde3c3c3842de491bbc2ad34c2e72718f189470daa6194123e0b4c88",
    "map_sha256": "06b174a5ef314896bf53620930252de9b58544b4e1faaa384866aae6c230ce1f",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Columns/DECISIONS.md"
  },
  "Noise_One": {
    "text_sha256": "b0f02dc3f2a7bcbb9671432b4df4ed442e8ba5c07e58efa5f2f46f1b28098536",
    "map_sha256": "6c8620e7368a67b4a648389f12602fd49995a8f6a7fcb5fa2db1f85ce0e7ce0d",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_One/DECISIONS.md"
  },
  "Noise_Voxel": {
    "text_sha256": "1714ff63c8bb015cbe067cce746d80fbfb9c3ba3754465c6415d16c211c35a8d",
    "map_sha256": "101246a5433011743c3a2bee79414684cdb21d164fa487f39d4c5c7b17821893",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Voxel/DECISIONS.md"
  },
  "Noise_6_Wall": {
    "text_sha256": "fc9bc18446aff43a62e6700aa7ce2fe2ce73323ba2572ae8c7272f8b4f8addcb",
    "map_sha256": "63dc252b334ea6af29028239ff0bec504e5b80e15c488ca2c5cdc3020f539169",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_6_Wall/DECISIONS.md"
  },
  "Noise_Inside_Noise": {
    "text_sha256": "121a5664f996a2b354607119716f77a646fa99dfc6f5ba88b311cdca0e79f6ba",
    "map_sha256": "f1a082ed07da35e4f417f22d05443dc8bbb33fe08b7ccc86f98c9245fbbfddcf",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Inside_Noise/DECISIONS.md"
  },
  "Noise_Space_10": {
    "text_sha256": "66acc8cc33efd1eee6583ec766ac014c383ccd78aa6d118873083caaf7a4cbdc",
    "map_sha256": "0c3d80cd8890d2f4335cdd5c9ba4c77ec75b9a4528646e3753a7c07c188b335e",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Space_10/DECISIONS.md"
  },
  "Noise_Perlin_Simplex": {
    "text_sha256": "afb16c279fd634e9d2a27bc264e310abb350084c75b06c082fc310b74ed6599c",
    "map_sha256": "1964d1bb14a85542ea5709bd6a9d2a7b04632cb141579ffb2ab33ff3e3b6fa35",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Perlin_Simplex/DECISIONS.md"
  },
  "Lab_Path": {
    "text_sha256": "f566363c70e8f4bdadb93630784b462da8751cdaa7cdd8127d3b9187a2b8ee6e",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/Lab_Path/DECISIONS.md"
  },
  "CA_Introduction": {
    "text_sha256": "af04853c2f5331407943305a38f05e88d789e627dfef856eb3df7f1062303a39",
    "map_sha256": "4823488f29257375379331cac5a11d1fe7c1bf9dd18ac81b86f9ebfe95f72bcf",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_Introduction/DECISIONS.md"
  },
  "CA_ElementaryRules": {
    "text_sha256": "0ce19707a1be0e7d9be98b92f81584fac7bdbbfefb109a1f8871a89fdbe5d1da",
    "map_sha256": "2ca45cf62d98ce89102e93615b42aa4838f359face570373d7a99e91b46f7aaf",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_ElementaryRules/DECISIONS.md"
  },
  "CA_GameOfLife": {
    "text_sha256": "5dfbd9069735b3890ac882fb86259f9db3d8931acefd5af8e66907fc032ee149",
    "map_sha256": "a4486083e834db8061f919ed37388069bf6cd64a51ca9ac1dda58d12e5d81808",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_GameOfLife/DECISIONS.md"
  },
  "CA_BeyondBinary": {
    "text_sha256": "2110f41e925bd25889d2e29d7b2b5960e5a40a3ac921587be7a179330217931b",
    "map_sha256": "cc4b09ea600f2dccc676f5060f72c3f5c80b725267623364e87875246eeeed57",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_BeyondBinary/DECISIONS.md"
  },
  "CA_ExpandingSpace": {
    "text_sha256": "a4d172fc5f2e1885202137e3328d156aa4dc5782e307ae08f34b2fb11d94b9cd",
    "map_sha256": "1580ee6bc3100cd09d980cab2fff66683de3c4e0a744bcf9c8a15c4e881115f2",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_ExpandingSpace/DECISIONS.md"
  },
  "CA_SoftRules": {
    "text_sha256": "1da9b7e3681701062041d516cc771b736ca2fce4b5ea5a11e1532f6a5488c997",
    "map_sha256": "6eeea6ca3ca1008ef23874351f126453ca7684fbd271d2ceab23fd2a809e575d",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_SoftRules/DECISIONS.md"
  },
  "CA_AgentsCircuits": {
    "text_sha256": "b17878f9d56510bdf200ac6e2b58155e1472e462ae6fc17f74141ca1b3da682f",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_AgentsCircuits/DECISIONS.md"
  },
  "CA_EdgeOfChaos": {
    "text_sha256": "992937ab3cdaf9719e007c973a75ddb65076d94f95a0e1d70a5d1cf93b1be0e3",
    "map_sha256": "ab0576883518ebca6cad2b42a1bb8971ecec1d9b34ed568ac1d997c46d82f602",
    "local_review": "doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_EdgeOfChaos/DECISIONS.md"
  }
}
```

Random_Noise_Types is preserved: the patch refreshes only its stale hashes, with no `local_review`, since nothing in the hall changed.

## 9. Source changed by this block

Registries are unchanged: no token, scene path or declared axis moved. These are the scripts behind existing tokens.

- **Placement counts** are maps whose interactables layer places the token directly. The bracket adds curation-station `#artifacts:` lists and furniture `#mount:` cells, which also instantiate it.
- **Impact reports.** `tools/artifact_impact.py` was run on every changed artifact after the change, not before it as OWNERSHIP.md asks; the reports are in `_impact/`. Each changed artifact is listed by exactly one sequence (randomness or cellularautomata, both in this block). Its other placements are grammar, A*, trial, gallery and showcase maps, where the new behaviour was not checked.
- **Each diff** runs from the `<file>.gd.before.txt` snapshot, taken before this block edited the file, to the live file. It shows this block's change only.

| file | sha256 now | tokens | maps placing it | diff | what |
|---|---|---|---|---|---|
| `algorithms/randomness/dice_throw/dice_throw.gd` | `1579c0406230c2b3` | `dice_throw` | 22 (+5 via curation stations and furniture mounts) | `Random_Cubes/dice_throw.diff` | settle on the same top face at a steady height (not velocity), never read a held die, clamp the settle timer, reward rain over the table on its own collision layer, desktop grab/drop hooks. `git diff` against HEAD also shows another session's uncommitted 19 Sept comment edits, which are not in `dice_throw.diff`. |
| `algorithms/randomness/coin_toss/coin_toss.gd` | `48d0a35058cc6af0` | `coin_toss` | 58 (+6) | `Random_Cubes/coin_toss.diff` | a held coin is not counted; settle on a steady face; desktop drop hook. (`#disclosure:origin` with SPIN/DROP/TILT already existed; this block only switched it on in Random_Cubes' map.) |
| `algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd` | `53a50bd31299814a` | `random_decay_multimesh, random_decay_objects` | 4 (+1) | `Random_Rotate_Random_XYZ/random_decay_multimesh.diff` | `#study:rotation` (matched stacks, no drift/sink/colour, 12 columns, 10 m fit); default placements unchanged. `git diff` against HEAD also shows another session's uncommitted 19 Sept edits (`_stack_fit` / `_fit_stacks` / `_toggle_decay` and the `@identity` desire/emerges/truth lines), which are not in the delivered diff. |
| `algorithms/randomness/RandomRotateRandomXYZ/RandomRotateRandomXYZ.gd` | `d892d621bdd4ec1b` | `Random_Rotate_Random_XYZ` | 13 (+3) | `Random_Rotate_Random_XYZ/RandomRotateRandomXYZ.diff` | fallback search takes only a node named `GridMultiMesh`, so in the museum it no longer tumbles the lobby's picture frames. |
| `commons/artifacts/noise_mixer/noise_mixer.gd` | `0e2917054017a22c` | `noise_mixer` | 5 (+1) | `Random_Space/noise_mixer.diff` | `_regenerate` returns early before `_ready` builds the material. `git diff` against HEAD also shows another session's uncommitted `@identity` header edits, which are not in `noise_mixer.diff`. |
| `algorithms/cellularautomata/ca_showcase/LineNetworkCA.gd` | `4d5bee51841e6a2b` | `line_network_ca, and its subclass dendrite_growth_ca` | 3: 2 + 1 (+1 via a curation station) | `CA_Introduction/LineNetworkCA.diff` | stops its 64^3 scan once its own growth has ended (probe: 20,886 us a frame shipped, 3 us repaired; same lines from the same seed); additive `#size:<m>` fits the tangle into a box above the floor (default 0 = unchanged); dendrite keeps growing. **Since 14:16 another session is editing this file on top of this block's change** (an opt-in `#study:arrival` history; forum 260924-zgl38). The hash is of the live file, which includes their in-progress work. This block's own version is `CA_Introduction/LineNetworkCA.gd.block.txt`, and their delta is `LineNetworkCA.other_session.diff`. |
| `algorithms/proceduralgeneration/growth_systems/crackpropagation_ca/crackpropagation_ca.gd` | `583671a276d1e571` | `crackpropagation_ca` | 2 | `CA_EdgeOfChaos/crackpropagation_ca.diff` | stops processing after two settled frames with every interior cell cracked at full stress (probe: 60,674 us a frame shipped, 1 us repaired; same cracked set, stress and mesh vertices as the shipped script 120 frames later); `add_stress_point` / `reset_simulation` resume it. |
| `commons/artifacts/randomness_space/removal_arena.gd` | `14ef958787c764fe` | `random_removal_arena` | 2 | `Random_Remove/removal_arena.diff` | recognises the headset body (XR Tools PlayerBody, group `player_body`) when the museum has no desktop walker, so the floor removes cells in VR; the readout plate moved from 16 to 20 mm behind its label so it no longer hides the text. The desktop walker and the grid lane are unchanged. |

New, untracked gates and tools in `commons/testing/`:

- `probe_ten_print_hall.gd` `75c210d352c717a4`
- `probe_ten_print_walkable.gd` `5afc89da761d1292`
- `probe_random_cubes.gd` `7793c8f08e637973`
- `probe_rotation_study.gd` `b4c4bb45accab666`
- `probe_ca_stop_and_fit.gd` `4ee961712d2e8378`
- `probe_removal_arena_vr.gd` `ea26088196295cee`
- `probe_hall_shot.gd` `63d44063aa864f6c`

