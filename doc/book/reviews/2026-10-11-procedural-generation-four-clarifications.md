# Procedural generation: four clarifications

11 October 2026. Small additions to the two current reflective texts, following the source review. Existing working-tree revisions were preserved; this receipt records only this pass.

## Decisions

- **Genetic Evolution: score.** Name the match and one-unit-difference scores in estimator units. This makes the room's criterion legible without claiming measured physical volume.
- **Genetic Evolution: survival.** Name the two unchanged leading descriptions and four offspring places. Crossover is possible, not guaranteed. This gives the uncounted ring's survival a mechanism.
- **Space Colonization: branching.** State the one-child-per-site-per-generation limit. An older site must answer again in a later generation to acquire a fork.
- **Space Colonization: authorship.** Name the sine offsets that make the canopy field uneven and connect them to earlier learning. No new random field is drawn on each step.

The tutorials already explain scoring, reproduction scope and deferred growth. They remain byte-identical. The genetic learner reconstructs the evaluator and comparison; reproduction remains supplied museum material. The additional list of what fitness does not mean was omitted because the existing reflection already gives that distinction an encounter.

## Current-map receipts

Both maps and their authored halls in `commons/data/museum/em_plan.json` place the lead token at 180 degrees with `lesson:true`. The seven-hall sequence still begins Genetic Evolution, Space Colonization, Branching Growth. The registry entries in `commons/artifacts/registry/procgen_extra.json` resolve to the scenes below. Each scene's active museum wrapper enables its lesson script from the configured flag.

- `algorithms/proceduralgeneration/growth_systems/genetic_programming/GeneticProgramming.tscn` and `genetic_museum.gd`: installed lesson branch.
- `algorithms/proceduralgeneration/growth_systems/genetic_programming/selection_lesson.gd`, `_ready()`: population six, two elites, volume-target score; RULE names the estimate rather than measured union volume.
- `algorithms/proceduralgeneration/growth_systems/genetic_programming/GeneticProgramming.gd`, `calculate_fitness()` and `evolve_generation()`: score 100/(1+absolute difference); elite copies and conditional crossover before mutation. `tournament_selection()` really does use three random draws with replacement, already correctly described in the tutorial.
- `algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/SpaceColonizationAlgorithm.tscn` and `colonization_museum.gd`: installed lesson branch.
- `algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/colonization_lesson.gd`, `points_for_field()`: deterministic sine offsets construct the larger canopy field.
- `algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/SpaceColonizationAlgorithm.gd`, `_grow_network_iteration()`: one possible child per eligible site, read from the unchanged generation; additions appended after all decisions.

## Verification

Source and configuration inspection, not a new Godot or headset run. Only the four additions below changed the snapshotted files. Both tutorials, technical records, maps, sequence, museum plan and the snapshotted scripts/scenes remain byte-identical. Existing final text, artifact markers and line endings were preserved. Added-line whitespace checked. No commit made in this pass.

## Exact changes

### commons/maps/PG_Genetic_Evolution/final.md

```diff
--- before/commons/maps/PG_Genetic_Evolution/final.md
+++ after/commons/maps/PG_Genetic_Evolution/final.md
@@ -10,3 +10,3 @@
 
-The score rewards proximity to the current target. It says nothing about why you wanted a small body, or what you might someday do with the large one. We can understand this criterion without agreeing that it measures what we value.
+The score rewards proximity to the current target. An estimate equal to the target scores 100; a difference of one in the estimator's units scores 50. It says nothing about why you wanted a small body, or what you might someday do with the large one. We can understand this criterion without agreeing that it measures what we value.
 
@@ -16,3 +16,3 @@
 
-Advance a generation and look for that ring. An elite copy can carry it forward although it earned no points. Survival does not tell us that every surviving feature was rewarded. The held witness remains separate from this changing population. It gives us something to compare, without preserving every event that led here.
+Advance a generation and look for that ring. Two leading descriptions are copied unchanged; four more places are filled through parent selection, possible crossover and mutation. An elite copy can carry it forward although it earned no points. Survival does not tell us that every surviving feature was rewarded. The held witness remains separate from this changing population. It gives us something to compare, without preserving every event that led here.
 
```

### commons/maps/PG_Space_Colonization/final.md

```diff
--- before/commons/maps/PG_Space_Colonization/final.md
+++ after/commons/maps/PG_Space_Colonization/final.md
@@ -20,3 +20,3 @@
 
-Keep a specimen, then change the policy to NETWORK. The same field and root return. Watch for an earlier site that produces another child. Each request chooses its nearest eligible site; the requests assigned there combine their directions. Older sites can now answer again. Changing that permission makes a fork possible.
+Keep a specimen, then change the policy to NETWORK. The same field and root return. Watch for an earlier site that produces another child. Each request chooses its nearest eligible site; the requests assigned there combine their directions. Older sites can now answer again. Each eligible site adds at most one child per generation; a fork appears when a site adds another child in a later generation. Changing that permission makes a fork possible.
 
@@ -24,3 +24,3 @@
 
-The larger canopy has its own authored arrangement. Calling the result organic does not remove that authorship. More requests do not promise more branches, and some may remain when the program reaches its budget. A computational limit is not a tree's natural maturity.
+The larger canopy has its own authored arrangement. Sine offsets give that field its unevenness, using a tool we have met before. It is not newly randomized at each step. Calling the result organic does not remove that authorship. More requests do not promise more branches, and some may remain when the program reaches its budget. A computational limit is not a tree's natural maturity.
 
```

