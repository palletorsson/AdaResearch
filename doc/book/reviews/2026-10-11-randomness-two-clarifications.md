# Randomness: two clarifications

11 October 2026. Two sentences added to the current reflective texts after review of the restoration list. All earlier uncommitted work was preserved. The tutorials retain the implementation and reconstruction; no code was changed.

## Decisions and current-map checks

- **Random Entropy:** define H as average surprise per symbol under the observed shares. The installed `shannon_entropy_meter` uses `stand:ledger` and `disclosure:ledger` in both the map and its authored museum hall. Its `_measure()` implementation tallies symbols and sums `-p * log2(p)` using sample shares. The sentence concerns empirical marginal entropy, without claiming a measure of spatial disorder or thermodynamic entropy.
- **Random Walk:** distinguish the proposed step, the retained position and the selected earlier positions in the trail. The installed `random_walk_terrarium` uses `stand:logbook` in both the map and its authored museum hall. `_step_all_walkers()` adds a proposal to the position, folds boundaries, stores the previous position, trims the trail, then updates the position. The existing next sentences retain generator state and counter as memory; the new sentence does not claim that position is the only state or that the trail is complete.

The current Gaussian text already explains WIDTH and the disc-shaped exclusion. Mushrooms already distinguishes rejection from direct transformation, and Game already explains the stored wait. These passages were not expanded. A second clock with probabilistic launches would be a new tutorial experiment, not a description of the installed field.

## Sources

- `commons/maps/sequences/randomness.json`: fourteen active halls.
- `commons/maps/Random_Entropy/map_data.json` and `commons/maps/Random_Walk/map_data.json`.
- `commons/data/museum/em_plan.json`: both authored halls and their configured lead artifacts.
- `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`, `_measure()`.
- `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`, `_step_all_walkers()`.

## Verification

Exactly two sentence insertions. Existing text, artifact markers and original line endings preserved byte for byte. Both tutorials, the two maps, sequence, museum plan and inspected scripts remain identical to the pre-edit snapshot. Added-line whitespace checked. This is a source and text check; no new runtime or headset test was run. No commit made in this pass.

## Exact changes

### commons/maps/Random_Entropy/final.md

```diff
--- before/commons/maps/Random_Entropy/final.md
+++ after/commons/maps/Random_Entropy/final.md
@@ -12,3 +12,3 @@
 
-It makes one tally per symbol, then condenses those shares into an entropy reading. Neither operation asks which tile was next to which. A repeated pair, a rhythm or a message could pass unremarked. A high reading cannot certify meaninglessness; a low one cannot certify value.
+It makes one tally per symbol, then condenses those shares into an entropy reading. H measures average surprise per symbol when we use only these observed shares as probabilities. Neither operation asks which tile was next to which. A repeated pair, a rhythm or a message could pass unremarked. A high reading cannot certify meaninglessness; a low one cannot certify value.
 
```

### commons/maps/Random_Walk/final.md

```diff
--- before/commons/maps/Random_Walk/final.md
+++ after/commons/maps/Random_Walk/final.md
@@ -18,3 +18,3 @@
 
-Nothing in the heading rule reads the trail. Erasing its stored points in a controlled test leaves subsequent positions unchanged. There is still memory: current position, generator state, counter. To make the walker avoid its own drawing, another relation would have to be built.
+The step proposes a change, the position retains its result, and the trail stores selected earlier positions for us. Nothing in the heading rule reads the trail. Erasing its stored points in a controlled test leaves subsequent positions unchanged. There is still memory: current position, generator state, counter. To make the walker avoid its own drawing, another relation would have to be built.
 
```

