# Ada Research: Randomness, Noise and Particle Systems
## Evidence-led hall sequence and `to_spec` task proposal · 14 October 2026

**Status:** proposal, not implemented. The attached JSON goals follow `doc/tasks/_schema.md` in AdaResearch. They are not yet committed to the repository and do not prove any VR runtime tests.

### Evidence boundary

- **Tracked working branch inspected:** `palletorsson/AdaResearch`, `palm-scanner-door-entry`; actual `commons/maps/<Hall>/map_data.json` layers and `commons/maps/sequences/{randomness,noise,particles}.json`.
- **Earlier local capture:** Library review packages `randomness-review.md` and `noise-review.md`, captured 18 September 2026, explicitly containing uncommitted local changes. This snapshot reports a museum-authored route distinct from the sequence JSON.
- **Newer contextual evidence:** illustrated Random Definition review and writing-process discussion (13 October); local changes may be newer than either checked-in branch or September capture. Therefore `textile_comparison` still appears in the tracked Random_Definition map though the illustrated review says it moved to 10 PRINT.
- **Task conventions:** `doc/tasks/_schema.md`, existing `doc/tasks/book_randomness.json` (44 tasks) and `doc/tasks/book_noise.json` (20 tasks). These are not replacements for the existing tickets.
- **Do not assume:** present map token means tested VR interaction; scene existence means the tutorial can reconstruct it; measured jitter means validated physical entropy; coherent spatial noise means a system literally remembers its past.

### Conceptual contract: from explanation to exploration

Three different competencies must not be collapsed:
1. **Reconstruction:** the tutorial identifies inherited code, prints exact new code, supports one-variable intervention and independent rebuild.
2. **Encounter:** the final text allows the object, history, bodily consequences, uncertainty and strange alternatives to alter one another.
3. **Research:** the apparatus may yield an observation for which no final explanation yet exists. Preserve it as learning debt, with evidence, a next test and an accountable editorial decision. A result need not validate the initial author's intention.

The visitor should be able to **make a baseline → change one condition → observe → keep → replay → reconstruct**, followed, when productive, by **altering what can change at all**. Keep scene-loading/automated source tests, headset usability, and cross-hall carrying as separate verification layers. A research encounter can end in an honest unresolved question.

### Proposed RANDOMNESS path — same 14 hall identities, small early reorder

Legend: **E** = existing in the tracked hall; **P** = proposed new artifact or change. Order is a trial, not a map edit.

| Trial order | Hall | Existing encounter / installed artifacts | Proposed addition and role |
|---|---|---|---|
| R1 | `Random_Definition` | E: `seed_replay_demo`, `prng_crank_machine`, `slot_machine`, `trng_vs_prng`, `random_number_book_page_1955`, `textile_comparison` (tracked), `catalyst_pickup` | P: separate cryptographic source / experimental hardware-jitter comparison; keep 4×4 patch, +1 DRAW, REPLAY, source provenance; settle textile relocation first |
| R2 | `Random_Entropy` | E: `shannon_entropy_meter`, `entropy_jar`, `entropy_ruin`, `hardware_entropy_decay`, `random_butterflies` | P: adjacency comparator alongside histogram; same counts can conceal different neighbourhoods |
| R3 *(from 5)* | `Random_Cubes` | E: die, coin, `random_object_spawner`, 48 `random_edge_profile` | P: sample-count protocol and sampling-with/without-replacement link; basic chance before sophisticated distribution |
| R4 *(from 8)* | `Random_Gaussian` | E: `galton_board`, `distribution_sampler`, `distribution_comparator`, paint splatter | P: save and compare distribution parameters; histogram versus expected values |
| R5 *(from 3)* | `Random_Remove` | E: `remove_random`, `random_removal_arena` | P: observe irreversible-looking subtraction versus reset and whether state is recoverable |
| R6 *(from 4)* | `Randomness_10_PRINT_Algorithm` | E: three `ten_print_maze_3d`, `ten_print`, `composition_stochastique`, `ten_print_structure` | P: place/use textile mark comparison here only after reconciling actual local map; identical draws, different grammar |
| R7 *(from 6)* | `Random_Rotate_Random_XYZ` | E: `RotateGridCubes`, `Random_Rotate_Random_XYZ`, `random_decay_multimesh`, `hardware_entropy_decay` | P: distinguish variable axes from fixed geometry, test scope and out-of-bounds layouts |
| R8 | `Random_Walk` | E: `random_walk_terrarium`, `random_walk_collection`, `random_walk_leash`, `random_walk_128`, `random_draw_dot` | P: one common trace, different step rules; unpredictable direction versus constraints on location |
| R9 | `Random_Mushrooms` | E: `mushrooms`, `bubbles_random`, `silhouette_arrivals`, `couture_comparison` | P: chance and selection, spore/pattern/garment encounters; do not promise evolutionary causality without implementation |
| R10 | `Random_Space_Geometry` | E: `perlin_noise_bridge`, `curl_noise_particles`, `random_transformations_geometric`, `env_one`, `sculpt_one` | P: seeded Gaussian vertex-perturbation test at normalized 0.18; repair existing inaccessible artifact area before additions (existing task book_randomness.001) |
| R11 | `Randomness_Examples_of_Randomness` | E: `pollock_painting_in_3d`, `monte_carlo_dartboard`, `extreme_randomness`, `pipe_dream` | P: from drawing a sample to estimating the world; preserve artist/technical histories |
| R12 | `Random_Pheromone` | E: `pheromone_terrain` and two clipboard placements | P: trace and feedback; movement changes the conditions of subsequent movement |
| R13 | `Random_Space` | E: `noise_mixer`, `worley_noise`, `random_space`, `shannon_entropy_meter` | P: a world-scale open question desk, source/parameter/grammar experiment; preserve the path warning book_randomness.028 |
| R14 | `Random_Game` | E: `r_c`, `random_removal_arena`, `random_doors`, `cube_projectile_spawner`, `waiting_profile` | P: experiment with controls and changing boundaries, not only hazard survival; preserve VR comfort and alternate bypass |

The **tracked declaration** is R1, R2, R5, R6, R3, R7, R8, R4, R9…; changing it requires an authored/runtime topology decision. The **September museum-authored snapshot** omitted several declared maps and included `Biome_Cage` and `Biome_Ladder_Randomness`. Neither can be overwritten as stale without local verification.

### Proposed NOISE path — retain most of the 9-hall progression

| Trial order | Hall | Existing installed instruments | Next experimental capacity |
|---|---|---|---|
| N1 | `Random_Noise_Types` | `randompoint`, `randompoints`, `WhiteNoiseGallery`, `NoiseColors3D` | Contrast distributions/correlation without calling every surface 'random' |
| N2 | `Noise_Columns` | `MeltingBerniniScene`, `synthesis_stand`, `dark_sphere` | One field modifies an architectural body; distinguish baseline from displacement |
| N3 | `Noise_One` | `noisetorus`, `noiselayers`, `dark_sphere` | Build octaves with fixed seed; discover scale, persistence and lacunarity |
| N4 | `Noise_Voxel` | `perlin_terrain_sculptor`, `voxelnoise`, `science_screen` | The sampled continuous field becomes walkable/nonwalkable architecture through a threshold |
| N5 | `Noise_6_Wall` | two `shader_noise_space` placements | Compare CPU/GPU and shader sampling without mistaking hash for physical entropy |
| N6 | `Noise_Inside_Noise` | `noisesphere`, `dark_sphere` | Compose fields/domain warp; optional referenced mixer already present in Random_Space |
| N7 *(swap with 8)* | `Noise_Perlin_Simplex` | `simplex_noise`, `perlin_noise`, `perlin_noise_terrain`, `configurable_portal` | Compare implementation conventions before open field research |
| N8 *(swap with 7)* | `Noise_Space_10` | `noise_space`, `dark_sphere` | Open exploration: predict crossing, alter terrain parameter, keep failed route, revise model; optional field/particle bridge |
| N9 | `Lab_Path` | `dark_sphere` | Return/coda **only if actually generated in runtime**; see existing book_noise.014 |

`Noise_Blue`, `Noise_Functions`, `Noise_Volume` exist as mapped/deferred possibilities, not as active teaching progression. `Noise_Volume` currently places `VoxelNoiseROIs`; `Noise_Blue` places `blue_noise`. Activate only if a concrete research question needs extra architectural space.

### Five-hall PARTICLE TUTORIAL — keep existing branch unlocked after Forces

The checked branch already contains `Particles_SingleAndArrays`, `Particles_Emitters`, `Particles_Forces`, `Particles_LifetimeAndTypes`, and `Particles_Collision`, with placed Godot examples, but the tracked folders currently lack `tutorial.md`. Build these five tutorial files first rather than inventing a sixth canonical hall.

| Lesson | Existing hall and code anchors | Student reconstructs | Experiment and question |
|---|---|---|---|
| P1. One becomes many | `Particles_SingleAndArrays`: `example_4_1_single_particle_vr`, `example_4_2_array_particles_vr`; `core/particle.gd` | One particle, its state/integration, then array/spawn/removal loop | Keep initial state, vary acceleration or count, observe trajectory/population |
| P2. Source and emission | `Particles_Emitters`: `example_4_3_particle_emitter_vr`, `example_4_4_multiple_emitters_vr`, `example_particle_body`, `sub_emitters`; `core/particle_emitter.gd` | Rate, spawn position, birth velocity, source ownership, cleanup | Same mean rate but different emission schedule; does the cloud feel the same? |
| P3. Forces and fields | `Particles_Forces`: `force_fields`, `example_2_6_single_attractor_vr` | Apply force and integrate paths; compare constant force and vector fields | Which freedom does a particle have within a field? Optional bridge to curl flow |
| P4. Lives and populations | `Particles_LifetimeAndTypes`: `example_4_5_inheritance_polymorphism_vr`, `lifetime_curves`, `particle_systems` | Inheritance/typed behaviour, life curves, count-versus-time | What persists: the individual or the ensemble? CPU explanation versus GPU display |
| P5. Collision and synthesis | `Particles_Collision`: `example_4_6_particle_repeller_vr`, `particle_campfire` | Repulsion/boundaries and fire/embers/smoke synthesis | Change one condition until the fire stops appearing as fire; document new questions |

**Optional extensions** (not installed by this plan): compare (a) independent random impulses, (b) deterministic noise fields, and (c) curl-noise flow with identical initial particle positions. Reuse `curl_noise_particles` and verify `particle_randomness_pure`, `particle_randomness_perlin`, `particle_randomness_emergent` etc. before representing them as ready-to-place artifacts.

For each tutorial, follow the museum's *ghost-student* contract: **inheritance named and linked → one new operation printed in full → prediction → run → change one condition → measure → reset → independently reconstruct → reflective question.** Exact deterministic replay must be proven for the chosen CPU integration and event order; do not assume the GPU or physics engine promises it.

### Cross-hall carrying: light enough to remain reliable

Use a small, explicit experiment record, not a hidden global state rewrite. Suggested fields: `run_id`, `source_map`, `artifact`, `source_type`, `entropy_validation_status`, `generator_id`, `seed`, `draw_count`, `parameters`, `build_revision`, `observation`, `evidence_level`, `open_question`, `authorial_decision`. Do not record raw headset tracking or microphone data by default. Carrying should be optional: every destination hall must have its own usable baseline.

A useful handoff could be: RNG source → saved seed/trace → distribution → grammar → moving particles → noise-directed flow → altered architecture → an unresolved experiment. This creates a reference between halls **without requiring a single perfectly smooth narrative**.

### The final text: not the tutorial's narrator

The final texts can begin with an object doing something: a grid disagrees, a number disappears, a sphere returns, a crossing refuses the body. A technical fact can enter when the encounter needs it. History can interrupt the apparatus; an unbuilt possibility can expose a rule that might be rewritten. These are *research events*, not staged illustrations of a conclusion known in advance.

The author is **dissipated**, not dead. Writing always took time from other people's observations, sources, devices and conditions. AI makes that distributed time more explicit—and speeds the appearance of new dependencies and claims that the artist may not yet understand. This produces **learning debt**, which the work should record rather than conceal. Some lines may be proposed by another intelligence or survive from a previous version; publication still demands provenance, factual verification where possible and responsibility for what the text asserts.

A hall may finish with a question whose answer neither student nor author can supply. That is not a failed lesson, provided the question produces a testable or experiential route onward. The book becomes a world from which its maker can learn, and its observations can demand changes to the world.

### Work order and existing task intersections

1. Freeze current branch/local/runtime evidence and reconcile the map order. Do not replace undocumented or locally moved artifacts.
2. Trial the sequence of early randomness halls **as a proposal**. Preserve exact teleporter/biome chains until approved.
3. Specify one portable experiment record; test it in one room before making cross-hall persistence an assumption.
4. Improve existing instruments first; prototype only `randomness_source_comparator`, `entropy_adjacency_view`, `geometry_noise_test`, `particle_field_comparator` and a late open experiment if each is warranted.
5. Write and reconstruct the five particle tutorials independently; test desktop and headset behaviours separately.
6. Develop late-hall final writing with an explicit learning-debt and contribution ledger; do not overwrite tested passages wholesale.
7. Review as an author; approve/reject/defer modifications. Run map pathfinder, source checks, performance, actual headset tests and commit with evidence.

Existing tickets to keep visible: `book_randomness.001` (geometry bridge placement), `.017–.020` (VR interactions), `.021` (rotation field outside hall), `.026` (Gaussian console reach), `.028–.029` (Random Space path/mixer), `.030` (pheromone interaction); `book_noise.014` (Lab_Path not built), `.017` (Simplex readout), `.019` (global keys), `.020` (VR crossing claim). These must be checked against local task status before being claimed.

### Deliverables

Four goal JSON files, all with `status: open`, respecting `doc/tasks/_schema.md`:
- `doc/tasks/ada_random_noise_route.json` — route evidence, trial ordering, cross-hall protocol and validation.
- `doc/tasks/ada_random_noise_artifacts.json` — source claims, existing instruments, and proposed new comparisons.
- `doc/tasks/ada_particles_tutorial.json` — the five actual Nature of Code particle halls plus optional extensions.
- `doc/tasks/ada_dissipated_author_book.json` — final text, learning debt, co-authorship and verification.

**Stop before map or prose mutation.** This package constitutes a spec and task proposal, not authorization to reorder or overwrite the checked-in museum.
