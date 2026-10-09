# Randomness_Examples_of_Randomness

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## When can an uncertain sample support a precise estimate?

Body/layer: A sampling region, an inclusion test and a growing ratio.

Proposed primary encounter: `monte_carlo_dartboard`.

## Starting evidence

Outside the active route. The apparatus generates samples with THROW/AUTO/RESET; it is not a hand-aimed dart game. It may begin with 140 preseeded darts and caps at 500. Existing disclosure modes expose the measurement. Platform/wall recovery on 10 September: 2 interior cells restored as platforms; 1 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/. The spawn is now on existing floor at (1,1), preserving access after the old border became a wall.

Current map dimensions: {'width': 12, 'depth': 22, 'max_height': 4}. Current final: 405 words.

Current primaries: monte_carlo_dartboard. Book anchors: monte_carlo_dartboard.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Begin the lesson at zero or make preseeded history explicit. Put sample count, inside count and estimate together in the existing cabinet.
2. Offer one-sample THROW before AUTO. Add a deliberate biased-sampling comparison only if it is labelled and uses a separate mode; more points must not be presented as correcting bias.
3. Keep optional painting/pipe artifacts as a gallery of other uses of chance, with this estimator as the one clear primary experiment.

## Revise final.md

1. Predict what an inside or outside sample will do before asking for it.
2. Let the estimate wobble and occasionally get worse as N grows.
3. Read the actual inside-circle condition and 4*inside/total expression.
4. Distinguish random sample placement from skillful aim and numerical stability from correctness; carry the question of selection into feedback.

**Code to trace and quote after implementation:** monte_carlo_dartboard.gd: _throw_dart, _unit_draw, _preseed, _update_display and reset seed handling.

## Evidence to return

- Generated samples remain in the intended square; counts and estimate agree.
- AUTO stops/caps cleanly and RESET clears the displayed and numerical state.
- If bias mode is built, demonstrate it can stabilise at the wrong value rather than selecting a flattering run.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable may lean into the casino or laboratory. The experiment should reward a careful explanation, not a lucky estimate.

**Reusable method:** R3 explicit time; R6 local state/seed; R7 measurement contract.

## Open and inspect

- Map: `commons/maps/Randomness_Examples_of_Randomness/map_data.json`
- Book and supporting texts: `commons/maps/Randomness_Examples_of_Randomness/`
- [Primary view](http://localhost:3003/necklace/thread?map=Randomness_Examples_of_Randomness&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Randomness_Examples_of_Randomness)
- `res://algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.tscn`
- `algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
