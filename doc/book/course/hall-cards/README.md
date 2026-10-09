# Tutorial hall cards

5 October 2026. [Open the cards](http://localhost:3003/tutorial-cards?map=Point_Coordinates).

[Execution plan](http://localhost:3003/tutorial-plan) now connects these same saved choices to per-hall work, prerequisites, proposed behaviour checks, 25 sequence capacities and the 116-topic source inventory. Edit subject labels here; edit the construction/test plan there. Each view reads the live spine. The execution plan flags changed choices and source texts, retains save history, and exports a next-pass brief. Acceptance selects a plan; it does not establish a code or learner pass. [Working instructions](../execution-plan/README.md).

One large card per hall in the live museum spine: editable tutorial subject labels and learner action, a saved museum image where available, and one sentence summarising the current `final.md`. Previous/Next crosses sequence boundaries; selectors jump directly to a sequence or hall. Open the full reflective text when a summary needs context.

[All learning elements](http://localhost:3003/tutorial-cards/overview) collects the same labels as plain lists in sequence and hall order. Search by subject or hall, narrow to a sequence, open a hall to edit its focus, print the visible view, or download the full plain-text plan. This view reads the same live choices as the cards; refreshing it after a saved edit shows the new labels. Repeated subjects remain at each occurrence. Empty selections are shown explicitly.

## Choose the lesson

Use **Edit tutorial focus**, add/remove/rename subjects, edit the learner action, then **Save focus**. **Keep this focus** records an unchanged starting suggestion as a chosen focus. An empty subject list is allowed: a hall may be for reflection or composition. Unsaved drafts survive navigation between cards in the open page; save before closing or reloading.

Saving changes this planning layer only. It does not rewrite `tutorial.md`, `final.md`, museum code or sequence order. The current labels describe intended teaching, not a claim that the existing tutorial delivers it. Coordinates has two teaching subjects: local/global coordinates and the XR grabbable principle. Carrying the sphere is the experiment through which the student examines both. The prepared XR player is supplied; understanding what makes this body grabbable remains part of the lesson. Distance calculation belongs in Point Lines.

## Before writing a tutorial

The [reconstruction gate](../functional_text/RECONSTRUCTION.md) asks whether the student can build the selected capability from the tutorial and explicitly supplied support. Use its short six-field brief before drafting. A topic label or a correct source excerpt does not by itself meet that requirement. The first grabbable-point example remains a bounded writing pilot; it does not replace the whole Coordinates lesson.

Open each tutorial with a short **Learning elements** bullet list, using the same subject labels as its agreed hall card. Name the concepts plainly; keep the learner action in the prose. Apply this format as each tutorial is revised.

The 5 October pass adds these lists to the existing tutorials across the live spine. The three `lineage-*.json` files record manually selected subjects, earlier learning used, the added capability, what carries onward, and a concrete review note. They supersede the older automatically derived card suggestions; saved author choices still take precedence. A missing tutorial remains missing. A proposed-focus header identifies intended learning that the unchanged lesson does not yet deliver.

In the interface, **How this lesson fits** exposes these connections. **Focus needs revision** means the current lesson and its intended role need reconciliation. “Aligned” only means the selected focus is supported by the written lesson; it is not author acceptance or a runtime/learner test. Changing the author's focus, lesson source or prerequisite order prompts a recheck. Keep the sequence open to revision.

Read [the whole lineage](index.html) for the sequence overview and [the editorial review](REVIEW.md) for the main weak connections. Review these before expanding full lessons; do not mistake more labels for more learning.

The subsequent [eight-interaction pass](../../iterations/2026-10-05-eight-interaction-lessons/index.html) revises five full tutorials at Palle's request: Coordinates, Trace, Grid, Transformation Introduction and Paint. Their labels, focus and source fingerprints now match those lessons. The report includes the complete new text, before snapshots, diffs and dated museum images. This is a source-checked writing pass; no new headset or learner test is claimed.

1. Read the map's saved choice in `state.json`, if present. It takes precedence over older automated storyboard/foundation suggestions. A current direct instruction from Palle takes precedence over the saved choice.
2. Read the actual map, selected artifact source and tutorial, plus the adjacent hall choices. Distinguish existing support from the operation the learner will learn to change.
3. Read `final.md` separately. Its summary is a reading aid, not a list of programming subjects. Museum, tutorial and reflection remain overlapping sets.
4. Expand one agreed lesson at a time. Return a concrete conflict if the intended action is unsupported by the existing artifact; do not silently replace the teaching choice or alter runtime to match it.

## Sources and persistence

- Live order: `commons/maps/curriculum_spine.json` and its sequence files.
- Starting suggestions, titles and captures: `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`. These remain suggestions until selected.
- Curated tutorial selection: `lineage-opening.json`, `lineage-middle.json`, `lineage-later.json`. `subjects`/`focus` replace old defaults; `builds_on` names earlier halls and the particular capacity reused. Source fingerprints distinguish the inspected lesson from later edits. `build_lineage.py` validates the records and produces the review outline; it does not choose subjects or edit lessons.
- Saved author choices: `state.json`, keyed by map ID. Other maps retain their defaults. Removing a map from the live route does not erase its saved choice.
- Recovery: `history/` retains exact previous state bytes; the first entry records that no saved overlay existed. Saves use a revision guard and exclusive lock. A conflicting edit remains a draft for the user to reconcile.
- Reflective summaries: `final-summaries-opening.json` and `final-summaries-later.json`. All 207 current chapters were read; summaries are one sentence with a SHA-256 of the source bytes. Changed chapters receive a visible freshness warning rather than a silently regenerated summary.
- Eight halls currently lack a suitable saved image; their cards say so.

The page and API live in the sibling `ada_encyclopedia` web project under `src/app/tutorial-cards`, `src/app/api/tutorial-cards` and `src/lib/tutorial-cards.ts`. No cloud service or model call is required to browse or edit cards.

## Checks

The focused backend tests use temporary fixtures: live order, exact source hashes, state/history persistence, no chapter changes, stale and simultaneous saves, malformed state, input limits and same-origin HTTP handling. Run in the web project: `node --experimental-strip-types --test tests/tutorial-cards/backend.test.mjs`.
