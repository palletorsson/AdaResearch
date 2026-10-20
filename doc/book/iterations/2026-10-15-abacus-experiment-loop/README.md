# An abacus experiment we can reopen

Later on 15 October: the introductory tutorial was reduced to a small four-assignment shelf at Palle's request. This complete abacus lesson is preserved as [abacus-reconstruction.md](../../../../commons/maps/Random_Definition/abacus-reconstruction.md). Its builder and verifier now target that extension so running them cannot replace the new introduction. The account below records the earlier abacus revision.

15 October 2026. Palle requested an updated Random Definition tutorial centred on the current abacus, with a clear experiment loop, usable save/replay/reconstruction instructions and repaired stale directions. The 48-value bench remains the first research pilot.

The [canonical chapter](../../../../commons/maps/Random_Definition/tutorial.md) now follows: baseline → one changed condition → observation → save → reopen/replay → independent reconstruction → further proposal. The comparison keeps seed 435, the actual target pairs, bounds and interpolation fixed. Row 2 traverses eight steps in ten seconds; row 3 takes five seconds and produces the same 96 marks. Whether that different pace changes attention or feeling remains an observation to collect.

## What changed

The four complete apparatus files remain identical to the current runtime sources. A fifth, [experiment_notebook.gd](experiment_notebook.gd), belongs only to the learner's reconstructed scene. It supplies save/load/pause shortcuts, unique files and a readable question/prediction/observation/next-change envelope. The museum artifact still has one REPLAY button; no production scene, placement, final, literary candidate or writing-wall data was edited.

The lesson explains how to find a saved file, edit its observation, reopen it in a fresh scene, resume its phase or restart the retained path. Snapshots preserve bead state and ink, not the physical controller trajectory or sensation. A recording taken during an empty return resumes that return. The experiment record is not itself evidence of unpredictability.

MOVE / KEEP is no longer promised as an available step while its saved placement is removed. The optional colour-grid extension now describes SEED +1 rather than RANDOM and does not prescribe an obsolete occupied bay. Its simpler two-grid learner build and chosen seed remain distinct from the installed three-window comparison. The abacus's 48 coordinate pairs are explicitly distinct from the pilot bench's 48 scalar values.

The previous [tutorial](before/tutorial.md), [plan](before/tutorial-plan.md) and [extension](before/seed-picture-extension.md) are retained. The [current text plan](../../course/text-plans/Random_Definition/tutorial.md) records completed work and remaining observations. Current prose is 1,336 words, compared with 1,335 before; complete GDScript grows from 457 to 528 nonblank lines for the notebook. The four apparatus blocks are unchanged.

## A recording discrepancy found by the test

The first round-trip check found that Godot 4.6's JSON reader changes some least-significant decimal digits, even with full-precision output. For example, a stored target `-0.0016619563102722168` was read as `-0.00166195631027221`. Existing ink restoration converts coordinates back to 32-bit vectors, but the target array itself still differed at double precision. The notebook therefore stores both a readable `record` and `record_bytes`, a packed copy that preserves the numeric representation exactly. Restoration reads the packed copy and runs the artifact's existing validator. Observations may be edited; both record fields should be left intact.

This is a measured technical finding, not a human reading result. It gives a possible further question about what recording procedures retain, without making that question the required interpretation of the encounter. Existing runtime retention helpers were not changed.

## Verification

From the repository root:

```text
node doc/book/iterations/2026-10-15-abacus-experiment-loop/build-tutorial.mjs
python -X utf8 doc/book/iterations/2026-10-15-abacus-experiment-loop/verify.py
```

Set `GODOT_EXE` on another machine. The verifier extracts the five marked code blocks exactly into [reconstructed](reconstructed/), verifies their source correspondence, then executes them in Godot 4.6. It builds a fresh instance for reopening. Temporary recordings have unique paths and are removed after the test; no learner files are overwritten.

| Check | Result |
| --- | --- |
| Printed experiment workflow | PASS, 25 checks; [log](printed-loop.log) |
| Existing ink/distribution/replay tests | PASS; [log](ink.log) |
| Existing XR hand attachment/release tests | PASS; [log](hand.log) |
| Existing shared hall-seed integration tests | PASS; [log](hall-seed.log) |

The workflow checks the keyboard dispatch, unchanged active state on save, both controlled conditions, unique files, metadata, exact packed record, fresh restore paused without a hand, continuation on recontact, full replay, pause/return and refusal of a changed rate recipe. The comparison helper accepts JSON's integer/float number-type distinction where relevant, without a numeric tolerance; packed-state equality is checked directly. Expected refusal warnings are deliberate negative tests. Startup logs also contain the project's skipped sequence dictionaries, absent headless player and Jolt solver-bias warning. No script errors or failed assertions remain.

These are automated artifact and experiment-cycle checks, plus an existing shared-seed integration check. They are not an independent person's reconstruction, a live full-map performance test or a physical headset comfort result. The authored map, generated museum plan, registry and active sources were inspected before revision; the generated plan lag and removed MOVE / KEEP placement are not repaired by this text change. The next research step is an observed baseline/comparison and an independent reconstruction, followed by a justified apparatus or text revision.
