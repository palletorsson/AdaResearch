# Two, three, four, more — room research pilot

Palle's correction: the workshop should investigate what a given number of lines can do, rather than collect forms under broad themes. This also establishes a first repeatable workflow for autonomous investigations in museum rooms.

The primary artifact now has four stations. Two segments compare parallel, plus, X, skew, rails and a drawing. Three compare a triangle with opened and displaced edges. Four compare a square, a folded closed outline and a grid. More compares three six-rod arrangements (grid, separated grid, tetrahedron) before adding a twelve-edge cube. Counts and lengths are invariant within the first three stations. Two uses 0.8 m rods; the other stations use 0.6 m rods. The visitor can freely grab and rearrange them. Controls show the actual count.

Revised only the workshop's book section, registry description and encounter summary. Its primary role and physical map position remain unchanged. Earlier prose and every existing map artifact are preserved. Original files from before this revision are in `before/`.

## The bounded experiment

Run `python -X utf8 ada_run/research_line_counts.py` from the repo. It runs the Godot geometry exporter, verifies fresh output and unchanged source hashes, measures the exported endpoints, checks specific claims and creates `research-results.json` and `line-count-research.html` here. It does not update the website automatically; the current HTML was copied to the local encyclopedia at `/research/possible-bodies/line-count-research.html` and verified through HTTP.

- Sixteen production presets.
- Six triangle-edge translations, including zero displacement.
- Seven four-edge folds from 0 to 90 degrees.
- Measurements: segment count, length range, affine dimension, unique endpoint count and whether endpoint connections form one closed cycle. Tolerance: 0.00001 m.

The tested positive triangle displacements open joins; positive four-edge folds retain a closed cycle and side lengths while becoming nonplanar. Two skew segments already span three dimensions. These examples undermine a simple equation of more lines with more dimensions. The experimental sample is finite and does not prove an exhaustive classification. Interior crossings, rod thickness, faces, solids, physical passage, comfort and aesthetic quality are outside its measurements.

## The reusable working contract

For the next room, derive one question from its place in the spine. Identify what stays fixed and which changes are allowed. Generate a bounded set of candidates against the actual artifact implementation; retain parameters, source version, failures, measurements and visual evidence. Compare what becomes possible or impossible. Use those differences to propose an encounter and a local book revision. A meaningful bodily or critical claim must remain distinguishable from a computed metric. No repeated background automation has been scheduled.

This pilot exports and examines geometry in a separate Godot run. It is not an agent navigating the live room, observing headset behavior or automatically judging artistic value. It supplies a small reproducible investigation that can support those later steps.

## Validation

44 runtime checks passed: count and length invariants across every preset, actual XRTools grab-driver motion, held-reset protection, frozen release, collision-layer restoration, reset recovery and geometric relations. All 29 research cases exported and their measurements checked. The live encounter model has eight connected floor-model legs and shows the new book passage and primary artifact without source warnings. An actual museum capture confirms the four stations instantiate at unit scale. The floor model does not certify collider clearance. Headset comfort and reach remain unverified.
