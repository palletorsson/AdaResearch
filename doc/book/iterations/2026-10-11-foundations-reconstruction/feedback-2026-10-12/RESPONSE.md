# An experiment travels — feedback revision, 12 October 2026

The eight-hall order remains. This revision answers three specific points from the external assessment: the gap between checking and self-reference, the different kinds of difficulty collected under Foundations Crisis, and the absence of a visitor's own experimental record in Synthesis.

Subsequently, the [12 October whole-sequence ghost-student pass](ghost.html) reran all eight printed lessons and all eight native working copies: 131 code assertions and 122 museum checks passed. That later pass corrected Euclid's launcher instructions. The account below preserves the scope and first-run faults of the earlier feedback revision.

## Hofstadter across the existing rooms

A later reading pass on 12 October adds three short passages to the reflections. Gödel introduces *Gödel, Escher, Bach* through the distinction between a system and its description, keeping Hofstadter's account of selfhood separate from the theorem. Escher recalls the six-event score from Wavefunctions and the book's use of musical structures in its dialogues. Synthesis returns to the student's saved prediction and asks what the record leaves out, extending the same scrutiny to this AI-assisted text.

These are connections in the existing eight-hall reading, not new tutorial requirements or artifacts. Tutorial code, scenes and hall order are unchanged. The earlier executable receipts remain the evidence for that unchanged code; this prose pass checks the sources, rendered readings and review package without claiming a new ghost-student run.

## What changed in the readings

Gödel's tutorial and reflection now trace the conceptual bridge: a proof is a finite symbol record; such records can be encoded by numbers; sufficiently expressive arithmetic can represent proof-checking relations; a fixed-point construction is an additional mathematical step. The unary checker remains a decidable teaching model. No new animation is presented as a proof of incompleteness.

Synthesis distinguishes changing models, contradictory demands, bounded misses, unprovability under hypotheses, projection, missing witnesses and conflicting reports. The failure of one justification is not the disappearance of justification. Its final exercise returns to an earlier trace, woven pattern or trained sphere and asks what the observation supports.

## What now travels between halls

In the printed Gödel study, the upper controls remain available for exploration. A second row records a deliberate trial:

1. Choose the target and whether to damage the candidate.
2. PREDICT YES or PREDICT NO answers whether the checker will accept at the next budget.
3. TRY + KEEP runs that next search and appends the prediction, inputs, search output, actual candidate, checker result, UTC time, model identifier and source hash.
4. Open the supplied Synthesis lesson scene. Personal cards load from the journal. Earlier failures remain available beside later successes.

The file is `user://ada_foundations_trials_v1.json` in this Godot project's local user-data directory. Only the explicitly recorded trials are carried; exploratory clicks are not a session recording. Synthesis keeps its six labelled reference cards and adds personal cards without replaying or rewriting them. A missing or malformed journal produces a notice. A source mismatch is disclosed alongside the older result. Reading the file validates its schema, not its honesty or mathematical authority.

All new save/load and interface code is printed in the tutorials. The journal is taught in Gödel and reused in Synthesis, continuing the earlier Trace → Grid practice. The existing museum supplies the halls, player and XR controls. These changes are in the student working copies and their F6 launchers, beside the installed exhibits.

## What the reconstruction found

The revised six-lesson reconstruction passes **76 checks**, including **25 new journal and scene-handoff checks**. The unchanged opening lessons retain their earlier 23 and 32 passing checks, giving **131 recorded checks across the sequence**.

The first revised run caught two implementation faults: an invalid direct script-resource property access and integer fields returning from JSON as floats. Both were corrected. A failed prediction now survives exact comparison after append and a fresh read. The retained first-run log records these failures rather than hiding them behind the later result.

Two fresh native museum runs pass: **15 Gödel checks and 16 Synthesis checks**. Gödel saves a deliberately incorrect prediction using the real button signals. A separate Synthesis process reads that same saved experiment. Its display controls leave the journal bytes intact. The other six halls retain their earlier passing native receipts, giving **122 recorded museum checks**. These totals combine the original inspection with the revised affected halls; they do not claim that all eight rooms were rerun today.

Visual inspection found the new journal status sitting below Gödel's board. It was raised onto the board and enlarged; Synthesis's source line was raised too. The printed source and both native captures were regenerated and retested afterward.

This remains an author-informed ghost student using synthetic inputs. Tests use explicitly separate synthetic files and do not modify a visitor's journal. Headset reach, route comfort and human comprehension remain open. The six-hall bench design and the expanded Non-Euclidean wing still merit their separate spatial reviews. QFEP's operational definitions remain work for the laboratory.

## Try it

Run `res://doc/book/studies/foundations-lineage/godel.tscn` with F6. At SSS0 and budget 2, choose PREDICT NO, then TRY + KEEP. The next budget is 3; the intact candidate is accepted, so the prediction is retained as a failure. Run `res://doc/book/studies/foundations-lineage/synthesis.tscn`: the personal card should say MY PREDICTION FAILED IN THIS RUN. A prediction of YES produces the same search and candidate, with a different comparison to your expectation.
