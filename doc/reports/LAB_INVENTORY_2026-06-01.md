# Lab System Inventory — 2026-06-01

> Audit run before deciding how to scale the "lab per map" pattern (Point_One)
> across the spine. Answers: what assets exist, where the labs are, where the gaps are.

## Headline numbers

| Asset | Count |
|-------|-------|
| Spine sequences | **22** |
| Sequences WITH a lab | **~5** (primitives, randomness, qfeplaboratory, foundationscrisis, softbodies) |
| Sequences WITHOUT a lab | **~17** |
| Hand-authored labs total | 8 (`point_one`, `point_line`, `primitives_test`, `monte_carlo_room`, `qfep_phase_chamber`, `turing_machine_lab`, `foundations_crisis_hall`, `simpel_lab`) |
| Unique registered artifacts | **1622** |
| GD scripts with `@identity` (DNA-documented) | **508** |
| Shader/substrate files (`.gdshader`) | **248** |
| Lab-generation rule/grammar | **none yet** (all labs hand-authored JSON) |

## Spine × assets × lab status

| Sequence | Phase | # artifacts available | Lab? | QFEP role (concept the lab must express) |
|----------|-------|----------------------:|------|------------------------------------------|
| primitives | F_order | 19 | ✅ | Foundation — points, lines, planes |
| transformation | F_order | 58 | — | Invariants — dot/cross enable rotation |
| array_tutorial | F_order | 46 | — | The grid, indexing, addressability |
| color | F_order | 42 | — | Color systems become composition |
| change | F_order | **12** | — | The calculus substrate. Derivatives |
| forces | oscillation | 58 | — | Newton's laws — vectors become physics |
| wavefunctions | oscillation | 84 | — | F↔E oscillation — sine creates curves |
| randomness | E_entropy | 112 | ✅ | Disorder as creative force |
| noise | E_entropy | 41 | — | Structured randomness — Perlin, flow |
| cellularautomata | lambda_edge | 29 | — | Simple rules → complex behaviour |
| fractals | lambda_edge | 43 | — | Self-similarity, infinite detail |
| lsystems | lambda_edge | 29 | — | Generative grammars |
| proceduralgeneration | lambda_edge | 32 | — | WFC, Markov, emergence from rules |
| isosurfaces | F_order | 30 | — | Implicit fields → explicit surfaces |
| boolean_surfaces | F_order | **5** | — | CSG as composition logic |
| softbodies | integration | 20 | ✅ | Deformable matter + Turing machine |
| swarmintelligence | lambda_edge | **13** | — | Collective behaviour, stigmergy |
| machinelearning | integration | 64 | — | Learning systems, neural nets |
| graphtheory | relation | 20 | — | Connections define structure |
| foundationscrisis | synthesis | 27 | ✅ | Gödel, Russell — limits of formal systems |
| qfeplaboratory | synthesis | 39 | ✅ | The complete QFEP formula embodied |
| postfoundationscrisis | synthesis | **17** | — | Applied limits — bias, rhizomes |

## What the inventory tells us

1. **The coverage gap is bounded and small.** ~17 spine sequences need a lab — not 503 maps. This is a one-to-two-week shaped problem, not a moonshot.

2. **Artifact supply is abundant — auto-research is NOT the bottleneck.** 1622 artifacts, and almost every sequence has 20–112 candidates. A lab rule book can lean **almost entirely on reuse** for its centerpiece + props. New-artifact creation is the exception, not the engine.

3. **DNA is rich.** 508 `@identity`-documented scripts means the rule book can read intent (essence/desire/critical_parameter) to pick the *right* centerpiece per concept, not just any artifact.

4. **Substrates are plentiful.** 248 shaders → the lab's wall/floor/material form has wide expressive range to match each map's theme.

5. **The genuine thin spots** (where auto-research may actually be warranted): **boolean_surfaces (5)**, **change (12)**, **swarmintelligence (13)**, **postfoundationscrisis (17)**. Even these have *some* — so auto-research is "fill 1–2 gaps each," not "build a sequence's worth."

## Conclusion → decision this enables

**The assets to scaffold labs across the whole spine already exist.** The real work is **composition** (a rule book that maps concept → existing artifact + substrate + lab form), not **creation** (auto-research). That de-risks the hybrid plan dramatically:

- Build the lab grammar to **prefer reuse**; it will succeed for ~18/22 sequences with zero new artifacts.
- Queue auto-research only for the **4 thin sequences**, and only for the specific missing centerpiece — a handful of artifacts, demand-driven.
- Validation gate stands: the grammar must re-derive Point_One's lab before it scaffolds the rest.

**Recommended next step:** extract the lab grammar v1 from the 5 existing good labs (what room size, signage, centerpiece, floor/window motif, prop acts, threshold ritual each concept implies), prove it by reproducing `point_one.lab.json`, then scaffold the 17 lab-less spine heads.
