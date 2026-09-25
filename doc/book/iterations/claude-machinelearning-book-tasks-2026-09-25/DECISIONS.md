# machinelearning — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_machinelearning.001`–`.014` (the 24 Sept tasks; .015–.021 were the Nature of Code series, closed earlier today): thirteen applied and closed, one left open with its prose half done. Walking the spine from its far end (forum 260925-tvljg).

| task | hall | what landed |
|---|---|---|
| .001 | ML_Sequence_Memory | the two histories flipped to pale-then-pale (h = 0.375, slab 34 cm up) and dark-then-pale (h = 0.125, 11 cm up): same last token, same 0.25 gap, both above the floor; "drops past where it started" gone; the band paragraph untouched |
| .002 | ML_Sequence_Memory | the clearing step written between the histories from the code's own reset (LSTMs_VR.gd:726-727): forget AND input spheres on the floor, one token through, c back at nought. The task said the forget sphere alone, which leaves c = i·x, not 0; the code comment has it right and the chapter follows the code. The later "run both histories again" needs no clearing because f = 0 keeps nothing, and says so |
| .004 | ML_Sequence_Memory | the real mapping: nought below a metre, one at three metres where no hand goes, one half where the spheres hang at two metres (the map places lstms_vr at scale 1, so these are world metres) |
| .005 | ML_Sequence_Memory | the readout named (step, f*c, i*x, c and h to three decimals); the panel's own line `c = f*c + i*x    h = o*c` in place of the gdscript block; the gap in c (2·f·i = one half) distinguished from the gap on the post (o × that = a quarter); "to every decimal the readout prints" |
| .006 | ML_Perception | the prose option: the two signs named and disowned in the chapter ("the signs describe a room that has not been built"); the label strings and the "Learn ed" typo remain a two-line code follow-up |
| .007 | ML_Gradient_Landscape | the prose option: "The unlabelled button beside the slider is the reset"; a Label3D remains a code follow-up |
| .008 | ML_Synthesis | the disc sentence: a rough marker at the average spread, the real boundary a diamond in standardised units (score = \|z_x\| + \|z_y\|, disc radius = mean spread × threshold) |
| .009 | ML_Perception | the eye sent to the matching cell of the edge image; "the outline marks the neighbourhood whose calculation you can read off the edge image" |
| .010 | ML_Generative | the disclosure moved to the end of paragraph one; paragraph five now refers back to it and keeps the "cannot provide evidence" sentence; paragraph six stays the specification |
| .011 | ML_Synthesis | **code**: the `[b]` tags stripped from the mode string in AnomalyDetection.gd:255 and anomaly_detection.tscn:63 (Label3D has no BBCode); compile-checked in one boot (rc printed in the run log); "In this room" for "In the default view" |
| .012 | ML_Classification | "The room is called Classification, but..." |
| .013 | ML_Evolution | "The plate under the title counts births and deaths; watch Born and Died tick..."; paragraph two opens on the sign's own line, no fitness function, no goal, just drift, as the claim the hall tests |
| .014 | sequence file | the three lines rewritten in `commons/maps/sequences/machinelearning.json`: description, objective, the ML_Sequence_Memory content line |

Left open:

- .003 (ML_Neural_Networks): the prose half is done (the chapter now says the training runs about fifty seconds from the hall's build and nothing in the hall restarts it); the button or the loop is a scene change for a follow-up commit.

Verification: every replacement matched exactly once; footnotes defined; fences balanced; the eight chapters LF and kept LF, the sequence file CRLF and kept CRLF (raw-text edit, JSON re-parsed); the anomaly script compiles.

Disclosure: ML_Sequence_Memory's chapter as found in the tree is an uncommitted rewrite from 23 September (the recurrence: 33 lines against HEAD, never committed by anyone), and the sequence file as found is an uncommitted whole-file rewrite ("Machine Learning: What Changes, and Why?", reindented; 546 lines against HEAD, file dated 2026-09-25 11:42). Both land here whole; `before/` is the tree as found, so the diffs beside it are this pass alone.
