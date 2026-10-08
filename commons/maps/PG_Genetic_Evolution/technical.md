# Genetic Evolution — representation, estimate and selection

The primary is the existing GeneticProgramming artifact, opting into `GeneticProgramming:180#lesson:true`. Its original GeneticProgramming.gd supplies Genome/Gene, primitive construction, estimate_volume, calculate_fitness, tournament_selection, crossover, mutation and population visualization. This kernel is unchanged. The new genetic_museum.gd wrapper selects a museum lesson; ordinary placements keep their original 20-member population and UI.

## Controlled opening

selection_lesson.gd configures primitive genomes, the volume-target score, six members, two elites, manual steps and four-metre display spacing. It creates one-box genomes at scales .7, 1, 1.25, 1.5, 1.75 and 2. Each box begins with its base at zero. The initial target is 8. Resetting these data does not reseed the shared random generator.

TARGET cycles 8 → 16 → 32 → 8, reevaluating the same genes without advancing generation. Display positions represent current rank, not permanent identity. Score is `100 / (1 + abs(estimate - target))`. The scale-1 box initially scores 100; at target 16 the scale-1.25 box scores approximately 72.727 with estimate 15.625.

## Deliberate comparison with an existing omission

RING adds or removes one torus on the current leader. The original builder renders it; the original estimator has no torus branch. Under this fixed volume criterion the change therefore preserves score. The estimator's box term is eight times the scale product even though the rendered BoxMesh is unit-sized. It also sums primitive contributions without union/overlap correction. Label values are proxies, not cubic metres of measured occupied space. This lesson makes those existing defects inspectable; it does not silently correct the scoring kernel.

HOLD duplicates the leader's genome and builds a separate visible witness. Its single slot survives target changes, generation steps and RESET; another HOLD replaces it. It currently cannot nominate an arbitrary candidate.

## A generation

STEP calls the original evolve_generation. It copies two elites, then fills four slots. A parent tournament makes three independent random draws, with replacement, and takes the highest score. Crossover is attempted at the original .7 rate; the child then uses the original mutation routine/rate. The population is rescored and reordered. At a fixed criterion, retained elites prevent a lower best score in this step; an improvement is not guaranteed. The original limit is 50 generations. STEP reports reaching that limit instead of pretending to advance. RESET starts again; random offspring are not promised to replay.

The compact 3×2 desk supplies TARGET, STEP, RING, HOLD, RESET and RULE. RULE shows the score and estimator omissions. Per-candidate readouts give rank, estimate, score and part count. The main screen is a small inclined translucent plane.

## Floor and scene contract

The old 13×14 layout is retained at offset (3,20) inside a 19×39 hall. Its 25 numeric height-3 cells are two-metre decks when the museum wall threshold is 4; explicit w cells remain walls. Two old boundary cells at (3,25) and (3,26) open for a new closed convex ramp rising from x=1 to x=4 over three metres. The new eastern aisle and rear turning rows provide a route independent of the population. Generated specimens have no colliders and supply no floor. Both portable plans derive this hall from current map_data; other halls are untouched.

The scene's stale Control node carried a script that extends Node3D. Its attachment now uses Node3D, matching the existing programmatic 3D UI. GeneticUI.gd itself is unchanged; broader legacy slider behavior is not certified here. In lesson mode, that UI is hidden/disabled and its colliders are disabled.

The secondary science_screen remains in its earlier grid mode and scene. It is not wired to the genetic genome or score, and is not the lesson's readout. Full secondary functionality and headset reach/comfort/Quest timing remain pending.
