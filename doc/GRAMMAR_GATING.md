# Grammar Gating

`commons/artifacts/grammar_operations.json` is the declarative layer — what operations each sequence unlocks, what form_type each operation produces. `GrammarOperationsManager` (autoload, `commons/managers/GrammarOperationsManager.gd`) makes it **enforced at runtime**.

## The Mechanism

1. At boot, `GrammarOperationsManager` reads `grammar_operations.json` and builds `_form_type_order[form] = min_sequence_order_that_produces_it`.
2. `get_current_stage_order()` is pulled live from `EcosystemManager` (already driven by `soft_stages.json` and `sync_to_map`).
3. `is_form_type_unlocked(form)` answers: has the player progressed far enough for this form_type to exist?

## The Biome Gate

`BiomeRingComponent._place_foliage()` passes its planned foliage list through `GrammarOperationsManager.filter_foliage_types()`. The filter drops anything whose required form_type isn't yet unlocked.

Current foliage → form_type gates (`FOLIAGE_GRAMMAR_GATE` in the manager):

| Foliage | Required form_type | Emerges in | Sequence order |
|---|---|---|---|
| `tree` | `growth` | lsystems | 11 |
| `bush` | `growth` | lsystems | 11 |
| `mushroom` | `automaton` | cellularautomata | 8 |
| `creature` | `swarm` | swarmintelligence | 13 |
| `reed` | `wave` | wavefunctions | 5 |
| `grass` | — (ungated) | — | — |
| `flower` | — (ungated) | — | — |
| `fern` | — (ungated) | — | — |

## What This Buys Us

Before this wire, `soft_stages.json` could declare `"nature_kingdoms": ["tree"]` for sequence 3 and the biome would dutifully spawn trees — contradicting the curriculum, because the player hasn't learned recursive branching yet. The gate makes the declarations **consistent**: the biome can only manifest forms the curriculum has taught.

## Adding a New Gate

1. Add the foliage/creature/form key to `FOLIAGE_GRAMMAR_GATE` with its required form_type.
2. Make sure `grammar_operations.json` has an operation in some sequence producing that form_type.
3. No other changes — the index rebuilds at boot and `is_form_type_unlocked` picks it up.

## Extending Beyond Foliage

`GrammarOperationsManager` is general. Any runtime system can gate on it:

```gdscript
var grammar = get_node("/root/GrammarOperationsManager")
if grammar.is_form_type_unlocked("fractal"):
    spawn_sierpinski_tower()
```

Candidates: CritterSpawner (creature DNA complexity), NatureRenderer (ambient shader selection), HazardManager (which hazards can appear). Out of scope for `biome_engine.003` — listed here as hooks for future work.

## Verification

```
Godot_v4.6 --path . --xr-mode off --headless --check-only --quit
# Expect:
#   EcosystemManager: Initialized with 20 stages, 583 maps indexed, ...
#   GrammarOperationsManager: Loaded 18 sequences, 19 form types
```

When walking a map in sequences 1–4 with a biome that requests trees, look for:

```
[BiomeRing] Grammar gated foliage — dropped: ["tree"]
```

in the console. That's the gate firing.
