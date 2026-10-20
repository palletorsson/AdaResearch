# Foundations Crisis — runnable tutorial handoff

11 October 2026. User asked to begin Euclid, carry the museum's point/line/triangle, update tutorial.md and final.md, and test through a fresh ghost student. Graph Theory and Machine Learning already have revised lessons; do not restart them as the next sequence.

## Euclid_Parallel

Carry PointBody + LineSkin + three vertices/face. New: interior-angle measurement, parallel through C using B−A, degenerate-state refusal. Separate assumptions / finite display / numerical evidence / proof. Hand maps world→study-local X/Z; bounds ±1m; release returns the point to the recorded plane. GUIDE/G/held trigger changes display only. RESET/R restores points only when all are released and retains guide choice.

Two new complete files in `doc/book/studies/euclid-lineage`: triangle_record.gd and euclid_study.gd. point_body.gd and line_skin.gd are exact carried files, also fully printed. Prepared museum/XRTools/button infrastructure is explicitly supplied. museum.tscn launches the existing hall and mounts the working copy at hall-local `(5,0,13.3)`. This is not a permanent registry or map-placement edit. Original plaque, parallel modules and triangle remain; its old fixed 60° labels are acknowledged as supplied labels, not readings.

Canonical texts: `commons/maps/Euclid_Parallel/{tutorial,final}.md`. Reflection asks which conditions a construction already accepts, staying close to the plaque, parallel modules, angle display, finite line and projected hand. No code blocks. Primary mathematical sources: Euclid Postulate 5 and Proposition I.32, linked in both texts. The study does not demonstrate independence or prove a universal geometry.

Author tests: `tools/test_euclid_lesson.py` extracts all four printed files and compares with source, then runs Godot assertions. Native room probe: `tools/probes/euclid_lesson_museum.gd`, through run_encounter_probe.py. Read `doc/book/iterations/2026-10-11-euclid-the-same-triangle/index.html` and its receipts for final counts and source hashes. Earlier placement failures and presentation corrections are retained. Visual checks found buttons below the tabletop and low readout contrast; raised/upward buttons and the readout outline correct those issues.

Fresh ghost student read only a frozen text packet and declared dependencies, reconstructed the four files and wrote its own tests. Its independently predicted variation is area-preserving shear: area/sum stay, angles/lengths change. First grab probe had three failures after a one-shot teleport; a separately predicted continuous-hand probe passed without changing lesson logic. Preserve both. Subsequent presentation revision checks are the same learner rerunning, not a new blind student. Exact results/logs are under `ghost/student/` in the dated review.

Physical XR, actual desktop pointer targeting, human learning and Quest performance are not established. UID `rwex60pqapc` and Jolt solver-bias diagnostics remain in execution logs. Keep these separate from the scoped passing assertions.

## NonEuclidean_Spaces

Completed the next focused lesson: plane → sphere. Carry PointBody, LineSkin and triangle_record.gd byte-for-byte from Euclid; add surface_triangle.gd and surface_study.gd. All five files appear in tutorial.md. Three coordinate pairs and PointBody instances survive the switch. Their positions, paths, lengths and angles can change; this correspondence is not an isometry or live persistence between museum scenes.

The spherical chart maps `(x,z)` to the unit direction `(x,1,z)`. Short great-circle arcs join the directions; analytical tangents measure the corners. Normalised linear samples draw the arc but are not equally spaced along it. Hand input inverts the upper-hemisphere chart, bounds each coordinate to ±1, and refuses a direction near/below its equator. Release restores the displayed surface point. Modes and reset wait until all points are released; reset retains the model. PLANE/P, SPHERE/S, RESET/R. Unit-scale study only.

The installed PLANE/SPHERE/DISK bench and other existing exhibits remain. The tutorial reconstructs plane/sphere only; it explicitly distinguishes the original bench's three example triangles from the retained student record. final.md reflects on paths, model choices and the difference between a chart boundary and the sphere's extent. Neither model changes the room's walking geometry. Cornell's surface geometry notes and Powell's Gauss–Bonnet notes support specific mathematical claims; numerical results are not proofs.

Run `doc/book/studies/noneuclid-lineage/museum.tscn` with F6 inside the prepared AdaResearch project. The supplied launcher adds the working copy at hall-local `(13,1,7)` on the raised floor. Initial placement failed against the stepped floor; the corrected placement passes bounded obstacle-clearance and supported-approach probes. This is a session study, not permanent map/registry placement. Native images show it in the actual hall and from above.

Author: 32/32 assertions. Native museum: 20/20 checks. Fresh ghost student independently reconstructed the frozen tutorial and predicted a variation that halves the chart coordinates: planar angles stay while spherical excess reduces; spherical arcs do not simply halve. First run passed 103 assertions but logged XRTools singleton compile errors from early scene preloading. Its independently frozen deferred-loading harness passed 109/109, including six dependency-health checks, with no SCRIPT ERROR. No lesson changes were needed. Preserve both attempts; a passing process exit alone did not establish a healthy run.

Canonical texts: `commons/maps/NonEuclidean_Spaces/{tutorial,final}.md`. Review, exact predictions, logs, code hashes and full texts: `doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/`. Author runner: `tools/test_noneuclid_lesson.py`; native probe: `tools/probes/noneuclid_lesson_museum.gd`; publisher: `tools/publish_noneuclid_lesson.py`. Physical headset interaction, actual desktop ray targeting, full walking access, Quest performance and human learning remain unverified. Native Compatibility-renderer, UID and Jolt diagnostics are retained.

## Next: Russell_Paradox

Do not reorder. Read the existing hall, artifacts and both texts before choosing its teaching object. Carry the practice of stating a rule, distinguishing a record from its display and refusing invalid states. Changing a geometric model and meeting an unrestricted set-membership demand are different operations; do not collapse them into a generic claim that all rules fail. Seek one complete inspectable construction, a declared finite computational scope and a fresh independently predicted variation. Continue one hall at a time.

Remaining route: Russell_Paradox → Godel_Incompleteness → Escher_Impossible → Brouwer_Intuitionism → Florensky_Paraconsistent → Crisis_Synthesis. This pass completes Euclid and Non-Euclidean Spaces; it does not claim the remaining runnable tutorials have been revised.
