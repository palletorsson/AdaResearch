# Ghost student — Soft Bodies

## Role and scope

Read as a student entering the existing Endless Museum after the preceding spine lessons. Camera, player, lighting, XRTools and Jolt are prepared. The book teaches selected artifacts; the rest of the collection remains a field for exploration. Tutorial and reflection have different jobs.

This is an author-operated reconstruction with real Godot checks. It is not a blind external review. The source of each assertion is available in the per-hall evidence and probe; a passing assertion establishes that behaviour, not a feeling or universal interpretation.



## Fresh run after the revision

All nine printed lessons were run again: **263 checks passed**, with no cached receipts. The three-attachment composition was also repeated inside the museum: **21 checks passed**. No learner-code repair was needed. [Read the fresh ghost-student report and native captures](ghost-rerun/index.html). Earlier evidence below is preserved as the development history.

## Handoffs and independent actions

|Hall|I bring|The new operation|I can change independently|Executable checks|
|---|---|---|---|---|
|1. A point that stays|Cube mesh; the carried point; prepared museum|Select one attachment; separate material settings from a restart.|Reduce cube subdivisions; select a valid top attachment again.|28 passed|
|2. Which points must stay?|SoftBody3D construction and the same point|Select a row, two corners or no pins from reference coordinates.|6 → 10 subdivisions: 12 row pins, 2 corner pins, 168 entries.|27 passed|
|3. The support moves|The unchanged cloth sheet and point|Drive the two attachments; let the free surface respond.|Double rate: twice the commanded angle, without promising twice the deformation.|29 passed|
|4. A drive and a room|The closed cube construction and boundary selection|Send a periodic pressure command to a closed surface.|Halve amplitude: pressures 0.125, 0.25, 0 at the three chosen phases.|32 passed|
|5. The same start|The unchanged pressure panel and point|Repeat a fall, vary damping and retain a timed reading.|Set both damping values to 0.1; match recipes and repeat the measured fall.|30 passed|
|6. A shape kept|Sampling an observation; supplied vessel and solver|Copy positions and connectivity while the source continues.|Capture at step 200; retain indices while the live body keeps changing.|27 passed|
|7. One shape, one cue|The same vessel recipe, solver and point|Keep geometry; isolate a turn or a material change.|Halve turn speed; leave the recorded shape and the reference alone.|25 passed|
|8. What keeps a pattern changing?|Earlier CA field and the same point|Open local conversion, supply and removal beside neighbour exchange.|Feed 0.050: at W, U=0.49375 and V=0.25375 after one step.|33 passed|
|9. Who connected the controls?|Matched comparison and the same point; a supplied 3D field|Separate frequency, disturbance and cut; preview before committing.|Double CUT_SPAN: opening cut −0.12 and endpoint 0.30; other parameters stay.|32 passed|

## Reading findings addressed

1. Cloth had repeated rebuild explanations and a second solver encounter mixed into the main lesson. The repeat is removed; the membrane is explicitly optional.
2. Sampling changes implementation. The tutorial identifies the supplied vessel solver before asking the reader to work on copying arrays.
3. The phrase “carry the shape” could imply persistent state. Sampling and Affect now agree: the next host reconstructs the step-40 recipe. This is known geometry, not a saved session.
4. The final transition could imply that the reaction concentrations become the gyroid. Both departures now state that the field changes; the point and comparison method carry forward.
5. Reprinted helpers can bury a short operation. Affect's unchanged files are expandable and remain complete in the text and download.
6. Each tutorial now identifies what carries forward, what the student writes here and what is supplied. The complete files remain visible.
7. The final handoffs distinguish a recorded surface, a pattern sustained by exchanges and a surface reconstructed from a spatial rule.

## Additional composition

After the nine-hall run, the authoring assistant composed a new comparison using Cloth's existing sheet and PointBody. Two upper corners were compared with three selected reference positions. All other pins were cleared. The freed corner moved while the selected entries stayed within the predicted tolerance. All 21 native checks passed. The [complete exercise](extensions/three-attachments/index.html) includes predictions recorded before execution, code, captures, corrected checker and the rejected first attempt.

This supports reuse beyond a supplied parameter edit. It remains an author-operated exercise with prior context. An unfamiliar learner's ability to devise such an experiment is still an open test.

The later editorial changes alter no printed code. `ghost-checks.json` retains the earlier engine result; `text-revision.json` records the current text hashes and exact code comparison. That prose-only revision preserved its existing evidence; the subsequent fresh run is recorded separately above.

## What was actually exercised

The per-hall probes initialize the printed scripts, inspect their resulting objects and execute interaction paths. They check such distinctions as pin flags versus reconstruction, elapsed time versus response, a kept reading versus a continuing body, saved vertices versus node motion, old versus next field state, and preview versus commit. The independent parameter edits are executed. Fault programs test whether assertions notice specific mistakes, including missing unpinning, coupled comparisons, a moving snapshot and a wrong parameter recipient.

Every hall contains the same PointBody source. Cloth → Carusell retains hanging_sheet.gd; Pressure → Contact retains pressure_panel.gd; Sampling → Affect retains vessel_surface.gd and solver.gd. These checks concern source and declared data relationships. Each host creates its own instances in the museum; this is not a test of inventory persistence or walking through all portals in one session.

The first five hall results were retained during the earlier run after a harness-only correction: the supplied particle solver uses Windows line endings. Its printed text was already identical when decoded; no learner code needed repair. The extraction comparison now normalizes line endings while the protected-source hashes continue to use original bytes.

## Open tests

- Ask a second reader to reconstruct an exercise from the printed instructions without these probes as hints.
- Test the entire learning session with controllers only. Some reduced hosts currently depend on keyboard actions beyond their grab/trigger path.
- Ask an unfamiliar reader to devise another variation and explain its result. The author-operated three-attachment composition is one example, not independent learner evidence.
- Test comfort and performance on the actual headset.

The result is ready for external review as a coherent, executable draft. These checks do not certify the pedagogy as finished.
