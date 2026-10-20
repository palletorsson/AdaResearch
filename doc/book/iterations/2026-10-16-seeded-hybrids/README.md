# Seeded hybrids

16 October 2026. User asks for seeds to change the forms themselves while KEEP/REPLAY retains interesting results.

[Native visual comparison](index.html) · [Guide](implementation.md) · [Apparatus checks](verification.json) · [Actual hall checks](museum-report.json) · [Kept seed 435](kept-trial.json) · [Seed 436](seed-436.json) · [Source manifest](manifest.json).

`seeded_grafts.gd` distributes fifteen recognisable bundles across four display pads, then varies joining order, attachment faces, small offsets and quarter turns. All fifty original meshes remain. Each hybrid receives at least three source objects. The grammar fits each finished assembly uniformly to its pad. This is a geometric assembly procedure, not physical self-assembly.

81/81 native apparatus checks and 25/25 actual-hall checks pass. Thirty-nine sampled seeds (including negative and int64 boundary values) produce thirty-nine distinct membership sets after ignoring pad permutations. Checks cover deterministic reconstruction, complete bounded mixed-source inventory, seed-wrap behavior, intermediate reversal, original geometry/materials, fresh saved replay and invalid-record rejection. Historical separation-only records and previous fixed-hybrid records retain their old geometry and recipe identity. SEED +1 after an old replay explicitly switches to the new generator.

The suite initially found two test-fixture issues: canonical membership comparison needed to normalize JSON numeric item IDs to integers; the invalid-scale case needed to zero a whole basis column rather than a component that can already be zero after a quarter turn. Both were corrected before recording the passing receipt. No generator or replay check was weakened.

Reproduce apparatus evidence with `python -X utf8 doc/book/iterations/2026-10-16-seeded-hybrids/run.py`. Reproduce room evidence with `python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag seeded-hybrids --probe doc/book/iterations/2026-10-16-seeded-hybrids/museum_probe.gd`. Run `publish.py` here after both pass.

The artifact guide, optional map tutorial/writing-wall entry, registry and research card/plan now describe seeded recombination. The six-stop main room/final order and first 48-value research pilot remain in place. Human recognition, independent learner reconstruction and headset comfort remain untested. Next: preserve two seeds at the same stage and compare a part's apparent role or use; a later controlled rule change should retain the separated baseline.
