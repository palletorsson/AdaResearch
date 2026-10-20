# Bring. Learn. Carry onward.

16 October 2026. [Open the live whole-spine overview](http://localhost:3003/tutorial-plan/lineage) · [Primitives only](http://localhost:3003/tutorial-plan/lineage?seq=primitives).

Palle requested one row per hall so we can review the tutorial lineage and then fix one sequence at a time. The new view uses the existing execution plan and saved teaching choices. It changes no lesson, reflective text, museum code or spine order.

## Read the table

- **What we bring:** the saved lesson's incoming skills, objects or records, with links to named prerequisites.
- **What we learn:** the hall card's selected subject labels. Author-saved choices keep their existing precedence.
- **What carries on:** the saved lesson's outgoing capability or material.
- **Review notes and lesson details:** source changes, missing plans, dependency-order questions, selected action, planned code change, supplied support, proposed checks and transfer exercise.

The first live read contains **209 halls in 25 sequences**. Three have no execution-plan entry: `Random_Entropies`, `Noise_Cellular` and `Noise_Box`. Their rows remain explicitly unplanned. The last two currently have short encounter descriptions in tutorial.md, not code reconstructions; their programming contribution needs a choice. Random_Entropies contains entropy calculations and prepared comparisons, but its teaching selection has not yet been entered in the existing plan. These are future editorial decisions, not missing code invented by this view.

Many source files have changed since their plan or curated lineage was reviewed. A review marker means check that relationship. It does not mean all marked lessons are weak, untested or wrong. Similarly, absent linked Ghost Student evidence does not establish that no tests exist elsewhere. Historical evidence, a plan decision and actual learning remain separate claims.

## Work one sequence at a time

Select a sequence; read its incoming and outgoing capacities down the three columns. Open a suspect row's current tutorial and saved notes. Change the learning subjects in the existing hall card, or the incoming/outgoing work in the existing execution plan. Refresh this view after saving. Once a sequence's choices are coherent, revise its tutorials one hall at a time using the [book/encyclopedia reading agreement](../2026-10-16-tutorial-lineage-and-editions/README.md).

The page supports search across the three columns, a review-notes filter, previous/next sequence, a filtered Markdown download and a print stylesheet. `overview.md` is a dated export for reading outside the app; the editable authority remains `doc/book/course/execution-plan/plan.json` and the existing hall-card choices.

## Implementation and verification

In the sibling `ada_encyclopedia` project:

- `src/lib/tutorial-lineage-overview.ts` makes a read-only projection and the same filtered Markdown table.
- `src/app/tutorial-plan/lineage/` displays it.
- `src/app/api/tutorial-plan/route.ts` adds `download=lineage` with matching sequence/search/review filters.
- The existing learning overview and execution plan link to the new view.

Focused tests cover live ordering, an absent plan, saved focus precedence, source drift, future/missing prerequisites, reflective stops, combined filters and Markdown escaping. Existing planner tests exercise its persistence and API safeguards. These validate the overview, not tutorial execution. Native Godot and human learner tests are outside this display change.

Verification: 17 focused tests passed; the scoped TypeScript check returned no errors. Live HTTP checks matched all 209 rows to the spine order and returned 15 rows for the Primitives export. Browser checks confirmed sequence selection, next/previous navigation, search, empty results and per-hall details. The live scan also found one missing tutorial file, `ISO_RhizomeBody`, which remains visible as a review note.

![Primitives overview with incoming work, learning subjects and carried work](preview.png)
