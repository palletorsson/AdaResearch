# Machine Learning → Void transfer

Owner: Codex. Batch 05, 21 October 2026. Transfer accepted; curation pending.

Ten original placements across ML_Evolution and ML_Gradient_Landscape are independently
editable in the lab editor. The museum scenes supply their actual geometry and behaviour;
the trial does not replace them with stand-ins. Original map and chapter hashes are unchanged.

## Collections

| Trial floor | Original placements |
|---|---|
| 1 / ML_Evolution | Evolved creatures, gradient descent, non-teleological evolution, evolving flowers, science screen in scatter mode |
| 2 / ML_Gradient_Landscape | Gradient descent, PCA with desktop overlay off, learning-step film, three-loss comparator, evolved creatures |

The trial slabs are 116 × 48 m with eight-metre storeys. This provisional space fits
the original 40 × 40 m creature arena to the side of the shafts without shrinking it.
Both creature placements retain their respective 0.6 and 1.0 source scales. Other
source scales and token configurations are also preserved. No change to the main tower.

## Necessary local adaptations

- `evolved_creatures.gd/tscn`: inherits the original creature scene. The original fitness
  mixed global torso coordinates with a local starting point. The adapter measures both
  displacement and height in arena coordinates. Moving or rotating the exhibit now leaves
  the score unchanged. Population, joints, genomes, fitness weights, selection and generation
  timing remain original.
- `pca.gd/tscn`: inherits the original PCA scene. Component rods now use a local basis
  aligned with the computed eigenvector, avoiding an orphan `look_at` and the extra rotation
  that pointed the long axis incorrectly. The 100-point, four-dimensional calculation and
  two-component projection remain original. Export-only preparation finishes the calculation
  so the editor contains the resulting geometry; runtime still shows the staged process.
- Consoles/clouds were lifted to sit above the slab. Creature ground is 0.025 m above the
  deck to avoid coincident surfaces. Source geometry was not reduced to fit.

The adapter catalog keys are `void_ml_evolved_creatures` and `void_ml_pca`; the inventory
records each original scene and its current placement. Both are local to this transfer.

## Evidence and controls

- Source preservation: 68/68 checks.
- Native Mobile renderer: 73/73 checks across desktop and synthetic XR.
- Editor: 13/13 checks; every original has real exported geometry and can be moved,
  copied and turned. Save/reload reaches the same native rooms file and Desktop backup;
  stale revisions are rejected. The temporary test move was restored.
- Native checks cover original populations, energy clock, creature/flower generations,
  fitness invariance under relocation, MODE/FUNCTION buttons, completed PCA and eigenvector
  directions, three loss surfaces and their shared data, RESET and descent, film playback,
  pause/step/replay, camera ownership, floor sleeping and checkpoint retry.
- Loss outlier variation was tested through the slider's value/signal API, not a real drag.
  The buttons and film controls were exercised with actual desktop mouse events and synthetic
  tracked XR rays/triggers. This is not physical-headset testing.

Four screenshots in `evidence/` are native Godot captures. The web models are static
arrangement snapshots; use the game menu → Void trials → Machine Learning for live simulation.

## Deliberately deferred

Final circulation, light, encounter order and the wide room's fit are for curation. The
science screen has no source `boid_count` provider and retains its demonstration fallback.
PCA retains the source automatic demonstration and `desktop_ui:off`; no hand controls were
invented. The original creature dynamics, including toppling, remain. Main-tower integration,
physical-headset comfort and all chapter rewrites are pending.

Editor: http://localhost:3003/lab-editor?mode=void&trial=machinelearning&floor=1
