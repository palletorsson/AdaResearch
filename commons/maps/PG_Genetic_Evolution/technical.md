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


## Reconstructed tutorial — 9 October 2026

Three complete files: evaluator.gd, selection.gd and byte-identical carried PointBody. Six box records retain IDs0..5 and the installed scales/positions. The pure estimator reproduces the installed box/sphere/cylinder coefficients and omitted torus. Score is100/(1+absolute difference). Ranking shallow-copies a list of references and sorts without mutating the input; equal scores choose lower ID, an explicit learner convention not declared by the source sort. HOLD deep-copies the whole record. Target changes reposition existing nodes and update captions without rebuilding meshes. The installed source itself rebuilds its display; the learner's renderer exposes the separation more directly. Only a ring edit rebuilds one body; reset rebuilds the opening six while held remains.

The bounded learner builder accepts box and torus genes only, matching their unit mesh parameters/transforms. Candidate bodies use a0.38 display scale outside their genomes; estimates remain in the original proxy units. The same point changes TARGET on held trigger; moving alone edits nothing. T/G/H/R map to target/ring/hold/reset. Release parks at local(0,1.15,1.1). All study geometry/captions are in printed code, with no scene-node references. No support collision, plinth or replacement XR system. A tested temporary host is hall-local(9.5,0,16.8),yaw180,unit scale, approach(9.5,0,15). The original museum remains in place; this is not a permanent added artifact.

25 exact-printed native assertions pass, including36 source estimates/scores across four gene types,three positive scale settings and three targets. Known leading IDs1/2/3 for targets8/16/32;100 exact and50 one-unit scores; no input mutation; explicit ties; ring omission/restoration; retained mesh instance IDs during target change; independent witness; source mesh bounds/transforms; keyboard and supplied XRTools poses under a rotated/translated host. The complete student variant removes only the box factor8: ID5,scale2,estimate8,score100 at target8; originalID1 scores12.5. It keeps all candidate genes and geometry. Torus still omitted. Signed-distance, in-place-list-sort and shallow-witness mutants are rejected. These checks do not validate arbitrary genomes or prove every possible surface property.

34 native museum checks pass, including eight cameras,six actual pointer buttons,unchanged candidate descriptions under target change,two unchanged elites in one source generation,held witness persistence,generation50 guard,collision-free specimens,13 supported ramp points, 202 supported capsule samples on the eastern bypass,valid entry/exit records,clear learner bay,reachable point,supplied pickup/action/release and the full student variation in the museum. This is not a full traversal,headset/Quest-performance or independent-student test; science_screen remains outside scoring acceptance.

Four baseline and eight final native images were inspected. The first wide baseline opening included the near wall; the final camera is inside it. The first learner images showed small labels and an obstructing original cube: label pixel size increased .0012->.002 and capture camera moved closer. The earlier passing receipt/images/code are kept in first-visual-run. Final close shots expose both rankings; tiny rear captions still require approaching. TARGET and RING desk captures are darker than the opening and learner views; the cause has not been established. Retained deck/ramp and raised structures remain unchanged. Existing UID/renderer diagnostics persist; accepted logs have no SCRIPT ERROR or Parse Error.

Production GeneticProgramming,wrapper,selection lesson,scene,authored map,canonical sequence and target runtime row unchanged. final.md retains its argument and encounters; two code excerpts and their procedural explanation move to the tutorial. Review doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html. First of seven procedural-generation halls in this reconstruction pass; Space Colonization next. Static HTML/code/link/archive checks are not browser layout verification.
