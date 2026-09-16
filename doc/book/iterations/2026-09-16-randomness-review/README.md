# Randomness: a clearer first passage

16 September 2026. Transformation is paused at Trans_Pre at Palle's request. Its lerp revision remains in place. This document reviews Randomness and proposes the next editing pass; it does not reorder the museum or change its artifacts or book texts.

## What is actually on the route?

Both `ada_run/em_plan.json` and `commons/data/museum/em_plan.json` contain the same seven Randomness halls:

Definition → Entropy → Remove → Walk → Gaussian → Mushrooms → Game.

Their source maps declare 63 artifact placements. This is a placement count, not a claim that all 63 scenes currently instantiate: the Entropy field notes record a missing living scene for replay_casino. The seven books have eight primary artifact families in total; Game deliberately has two. Their primary book anchors agree with artifact_roles.json.

The broader `commons/maps/sequences/randomness.json` and generated/effective artifact orders still contain fourteen maps. The other seven are 10 PRINT, Cubes, Rotate Random XYZ, Space Geometry, Examples of Randomness, Pheromone and Space. Treat this collection as retained material when planning the walk. A route revision must also make clear which rooms belong to the main passage and which are extensions; fourteen catalog entries and seven museum rooms should not silently read as the same itinerary.

## Assessment

The existing texts have unusually concrete material: replayable colours, an eligible set, reflected steps, retained samples, template copies and unpredictable waits. They already connect code to what the visitor can see and do. Preserve those discoveries and the repaired instruments.

The main pacing problem is that a first explanation often becomes an account of several implementation limits. Random Walk introduces dimensionality, varying step lengths, reflection, truncated trails, frame time and mean squared displacement. Gaussian covers sampling laws, finite samples, numerical guards, clipping, rebinned estimates and display scales. Each observation can matter, but the learner needs a clear first operation to carry through them.

Entropy currently comes second. Its SORT experiment is strong, but its full explanation asks for frequencies, probabilities, logarithms and a measurement contract before the distribution hall has established the relation between a draw, a sample and its histogram. Moving it later is a pedagogical recommendation, not a mathematical requirement.

## Proposed order

| Hall | First capability | Existing primary | Further discovery to retain |
|---|---|---|---|
| Random_Definition | Request a value; recover a sequence with a seed and the same procedure | seed_replay_demo | One discarded draw changes the RGB grouping without moving any cells |
| Random_Remove | Define an eligible set, then draw from the remaining candidates | remove_random | An even draw cannot choose a cube excluded by the filter |
| Random_Walk | Add each sampled step to the position already reached | random_walk_terrarium | The enclosure changes a proposed endpoint; the visible trail is a partial record |
| Random_Gaussian | Distinguish a sampling law from the finite histogram it produces | distribution_sampler | Rebinning changes the account while the stored values stay fixed |
| Random_Entropy | Read a measurement made from frequencies | shannon_entropy_meter | SORT changes neighbours while marginal symbol entropy stays fixed |
| Random_Mushrooms | Use draws to choose templates and vary their transforms | mushrooms | More sampled variation does not supply a seventh template; the construction rules decide which differences can appear |
| Random_Game | Identify exactly what is sampled in a bodily encounter | r_c, then cube_projectile_spawner | Random waits and random launch positions are different mechanisms; cues change what the visitor can anticipate |

This retains all seven halls, moving only Entropy after Gaussian. It also retains the supporting artifacts. The core passage establishes a capability, follows one consequence, and leaves additional mechanisms available for a longer visit.

The thread is: **what can this random choice change, and what has already been decided before it is drawn?** Code permits variation within a construction; changing the construction makes other bodies possible. That gives the critical inquiry a specific operation to examine in every hall.

## Start with Random Definition

1. Keep the existing two grids and replay table. Begin by finding one colour patch and recovering it with REPLAY.
2. Explain a call to `_rng.randf()` before explaining three draws assigned to RGB. Show `_rng.seed = s` where the source restores the generator before colouring each grid.
3. Establish the first lesson: the same generator, seed and sequence of calls can reconstruct the colours. A seed alone is not the complete recipe.
4. Then press +1 DRAW. Let the failed match open the next question about the procedure. Retain this discovery in the main reading, after the basic operation is understood.
5. Move the slider's integer quantisation and detailed draw accounting into the tutorial or a later reading where they interrupt the first encounter. Keep the existing controls and the possibility of choosing an offset palette deliberately.

No new artifact is required to begin. Source for the relevant operations: `algorithms/randomness/seed_replay/seed_replay_demo.gd`, especially `_regenerate`, `_column_seeds` and `toggle_extra_draw`.

## Follow-up constraints

If the proposed order is adopted, revise the adjoining final/tutorial/intent transitions together with route/navigation data. In particular, the current Definition→Entropy, Entropy→Remove, Gaussian→Mushrooms and Mushrooms' reference to the previous distribution room would need attention. Do not change only the museum floor order.

Mushrooms already uses a noise field to reject candidate positions although the Noise sequence follows this chapter. Introduce that filter as an existing rule the learner can inspect, then return to how the field is made in Noise. It need not become a second full tutorial here.

Game's existing notes flag controlled activation of the folding creatures as unfinished. Investigating a random wait needs an observable crossing; unrelated attacks can prevent that comparison. Preserve the creatures and consider staged activation rather than deleting them.

The sequence metadata currently equates randomness, entropy and freedom too broadly. Keep the artistic proposition open to investigation. A deterministic generator, marginal Shannon entropy and the body's available actions describe different things; the existing encounters are valuable precisely because they let us distinguish them.

## Evidence and next task

Read the seven current final.md files, their intent records, the Definition tutorial, current map placements, artifact roles, both museum plans, sequence/catalog orders, and relevant seed-replay and entropy source. Existing field notes include later repairs superseding the earlier visual-review to-do list; do not restart those completed repairs from the older list.

This pass is a source and editorial review. It makes no new claim about runtime, sightlines, headset comfort or performance. Next task: revise Random_Definition's first passage using the existing instrument, then continue hall by hall along the agreed learning order.
