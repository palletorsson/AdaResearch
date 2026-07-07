# Sieve pass — verification: after reorder

_Recorded 2026-05-13T11:05:00_

**Target:** the spine, sequences, and soft_stages after applying the macro QFEP-arc sieve's seven structural moves. The pass asks: does the reordered structure hold up to consistency checks?

## 1. Checks performed

1. **Spine phase composition** — every phase has the expected sequences in expected order.
2. **Phase truth statements** — every used phase has a `truth` field in the phases block.
3. **Sequence `layer` field vs spine `phase` field** — denormalized phase tag matches authoritative spine pointer.
4. **soft_stages order vs spine order** — ecology stages aligned with spine ordering.
5. **catalyst_affordances coverage** — every spine sequence has at least one affordance.
6. **Unlock graph integrity** — no backward edges (lower-order sequences unlocked from higher-order ones).

## 2. Results

```
Layer mismatches:               0
Soft_stages order mismatches:   0
Missing affordances:            0
Backward unlock edges:          0
```

All four checks pass. The reorder is internally consistent.

## 3. Phase final shape

| phase | n | sequences (order=name) | affordances |
|---|---|---|---|
| F_order | 7 | 1=primitives, 2=transformation, 3=array_tutorial, 4=color, 4.5=change, 4.6=isosurfaces, 4.7=boolean_surfaces | 16 |
| oscillation | 2 | 5=forces, 6=wavefunctions | 3 |
| E_entropy | 2 | 7=randomness, 8=noise | 2 |
| λ_edge | 5 | 9=CA, 10=fractals, 11=lsystems, 12=procgen, 13=swarm | 5 |
| integration | 2 | 14=softbodies, 15=ML | 3 |
| relation | 1 | 16=graphtheory | 1 |
| synthesis | 3 | 17=crisis, 18=lab, 19=post | 3 |

**Total catalyst affordances across the spine: 33** — one or more per major concept.

The bracelet at synthesis holds 33 affordances; at synthesis's final sequence, `compose` is added as the meta-affordance (combine any two).

## 4. Drift discovered and fixed (incidental)

While verifying, three pre-existing inconsistencies surfaced and were fixed:

1. **F_order order drift from v1.3 reorder**:
   - color, array_tutorial, forces had stale orders in soft_stages from before the v1.3 spine reorder. Realigned: color=4, array_tutorial=3, forces=5.

2. **softbodies → swarmintelligence backward unlock**:
   - softbodies (order 14) unlocked swarmintelligence (order 13). With swarm moved into λ_edge before softbodies, this was a regression. Changed to `softbodies.unlocks = ["machinelearning", "morphogenesis"]`.

3. **Sequence `layer` field idiosyncrasy**:
   - Several sequences used custom layer labels ("properties", "behaviors", "emergence", "integration", "calculus_substrate", "primitives") that didn't match phase taxonomy.
   - Normalized: every sequence file now has `layer` matching its spine phase.

## 5. The reorder summary (one place)

Seven structural moves applied across two files:

| change | from | to | files touched |
|---|---|---|---|
| cellularautomata phase | E_entropy | λ_edge | spine + sequence |
| isosurfaces order/phase | 12.5 / λ_edge | 4.6 / F_order | spine + sequence |
| boolean_surfaces order/phase | 12.7 / λ_edge | 4.7 / F_order | spine + sequence |
| swarmintelligence order/phase | 14 / integration | 13 / λ_edge | spine + sequence |
| softbodies order | 13 | 14 | spine + soft_stages |
| graphtheory order/phase | 19 / integration | 16 / relation | spine + sequence |
| foundationscrisis order | 16 | 17 | spine + soft_stages |
| qfeplaboratory order | 17 | 18 | spine + soft_stages |
| postfoundationscrisis order | 18 | 19 | spine + soft_stages |
| **new phase added** | — | relation | spine.phases |
| **phase truths added** | — | 7 phases | spine.phases |
| **postfoundationscrisis.unlocks** | `["qfeplaboratory"]` (backward) | `[]` (terminal) | sequence |
| **qfeplaboratory.unlocks** | (no post) | adds `postfoundationscrisis` | sequence |
| **softbodies.unlocks** | `["swarmintelligence", "morphogenesis"]` | `["machinelearning", "morphogenesis"]` | sequence |

And these affordances were added/filled to ensure 100% coverage:
- forces: `drive, push`
- wavefunctions: `oscillate`
- randomness: `scatter`
- noise: `flow`
- cellularautomata: `evolve`
- fractals: `split`
- lsystems: `grow`
- proceduralgeneration: `seed`
- swarmintelligence: `flock`
- softbodies: `flex, drape`
- machinelearning: `learn`
- graphtheory: `connect`
- foundationscrisis: `paradox`
- qfeplaboratory: `tune`
- postfoundationscrisis: `compose`

## 6. What this leaves

- **Schema duplication in machinelearning.json**: nested `artifact_groups` is empty, root-level is populated. Bug-fix scope, not blocking, flagged in macro sieve.
- **Empty boolean_surfaces artifact_groups**: 0/0 maps in the sequence file. Needs sequence-level scaffolding even if F_order ordering is fixed.
- **Hollow postfoundationscrisis**: 3/8 maps with artifacts. The thesis arc's third leg needs ~14 new artifacts (per synthesis sieve 6d).
- **Empty machinelearning nested artifact_groups**: artifacts ARE there at root level but the nested duplicate is hollow. Bug rather than gap.

## 7. Verdict

The reordered structure is internally consistent. All four invariants hold. The spine now reads as a single argument from primitive form to applied thesis. The next pass (master change list) catalogs:
1. The reorder itself (done — this pass verifies it)
2. Schema bugs (ML duplication)
3. The artifact build queue (boolean_surfaces, postfoundationscrisis fill, qfep_term_compass)

Load-bearing rule out:

> **Verification finds drift that wasn't named.** Three pre-existing inconsistencies (v1.3 order drift, idiosyncratic layer labels, softbodies/swarm backward unlock) surfaced only when we asked the system to be internally consistent. The reorder forced consistency-checking, and the system told us where it had quietly disagreed with itself. The lesson: reorders are also audits.
