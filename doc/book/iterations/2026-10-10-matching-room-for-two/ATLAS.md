# Ada — which relation does the line record?

The new native table stands in Matching. It connects the finished graph sequence back to the research that produced it. It is a companion exhibit; learners do not have to implement it to complete the matching operation.

| View | A node means | A link means | Source | It does not claim |
|---|---|---|---|---|
| Spine | Sequence, or hall in detail view | Comes next in the recommended walk | curriculum_spine.json and sequence files | Chronology or prerequisite |
| Depends on | Sequence, or hall | A lesson declares this prerequisite | execution-plan/plan.json → lessons[].dependsOn | Mastery or a verified best order |
| Concept returns | Sequence, or hall | Declared first introduction → later return | execution-plan/plan.json → topics[] | Semantic similarity inferred by AI |
| Shared artifact | Sequence | Same placed token occurs in both | Actual map_data.json interactable layers | Same runtime instance or state |
| Timeline | Selected saved review | Next selected date | Existing dated iteration folder | First invention, completion, exhaustive history |

VIEW changes the relation. PREVIOUS/NEXT selects a sequence. HALLS/ALL changes scale. Within-sequence dependency/concept groups expand into their hall relations. Shared-token mode describes cross-sequence connections; use ALL for it. The native display draws thin cylinders and arrow cones for directed relations. Shared-token rods have no arrow. Counts and detailed evidence remain available in the browser ledger below.

Edit the authoritative sources, then run `python tools/build_ada_relations.py`, `python tools/test_graph_matching.py` and the native probe/publisher recorded in technical.md. Do not edit generated data.json as if it were the authoritative plan. Nothing here automatically changes a lesson's decision or rewrites the spine. The snapshot records 10 October 2026.

The eleven references below are outside the current spine. They mainly refer to earlier vector-room IDs. They may be retained catalog material or stale plan references; absence from the current spine alone does not decide which. We expose them for review rather than automatically redirecting their dependencies.

| Kind | From | To / topic |
|---|---|---|
|dependency_outside_current_spine|VFM_02_Operations|Randomness_Examples_of_Randomness|
|dependency_outside_current_spine|VFM_02_Operations|Shader_01_Shaping|
|dependency_outside_current_spine|VFM_02_Operations|Shader_11_QueerRubber|
|dependency_outside_current_spine|Vectors_Act2_VectorArithmetic|PG_Space_Colonization|
|dependency_outside_current_spine|Vectors_Act2_VectorArithmetic|ISO_Metaballs|
|dependency_outside_current_spine|Vectors_Act2_VectorArithmetic|SwarmIntelligence_Boids_Algorithm|
|topic_reference_outside_current_spine|Point_Lines|Vectors_Act2_VectorArithmetic / Distance|
|topic_reference_outside_current_spine|Point_Lines|Vectors_Act2_VectorArithmetic / Vectors|
|topic_reference_outside_current_spine|Trans_Translation|VFM_02_Operations / Vector addition|
|topic_reference_outside_current_spine|Point_Lines|Vectors_Act2_VectorArithmetic / Vector subtraction|
|topic_reference_outside_current_spine|Point_Lines|Vectors_Act2_VectorArithmetic / Magnitude|

## Selected chronology

- 2026-10-03 — Opening lesson; `doc/book/iterations/2026-10-03-point-zero-one-lesson`.
- 2026-10-04 — Storyboards; `doc/book/iterations/2026-10-04-museum-tutorial-storyboards`.
- 2026-10-05 — Ghost state chain; `doc/book/iterations/2026-10-05-lesson-state-chain`.
- 2026-10-06 — Trace travels; `doc/book/iterations/2026-10-06-trace-saved-to-grid`.
- 2026-10-07 — Forces experiments; `doc/book/iterations/2026-10-07-forces-extravaganza`.
- 2026-10-08 — Fractal readings; `doc/book/iterations/2026-10-08-fractals-complete-readings`.
- 2026-10-09 — Soft-body readings; `doc/book/iterations/2026-10-09-soft-bodies-complete-readings`.
- 2026-10-10 — Graph worlds; `doc/book/iterations/2026-10-10-flow-room-for-another`.

## Quantities

25 sequences; 206 halls; 24 walk, 138 dependency, 54 concept, 197 shared aggregate relation groups. Evidence lists can contain multiple declarations or placements per group. These counts are not counts of distinct algorithms or proof of curriculum completeness.
