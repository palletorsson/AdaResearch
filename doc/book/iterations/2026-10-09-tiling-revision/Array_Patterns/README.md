# Array Patterns review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots. learner/printed is extracted from the tutorial; learner/narrower is the independent width edit. Other learner folders deliberately contain faults. Requires the existing Endless Museum project and XR Tools; this ZIP is a review packet, not a standalone Godot project.

Run: python tools/test_tiling_surface.py
Native: python tools/run_encounter_probe.py Array_Patterns --sequence tiling --render --no-bridges --probe tools/probes/tiling_surface_room.gd --output-tag surface-frame --spec doc/book/iterations/2026-10-09-tiling-revision/Array_Patterns/spec-student.json

Native probe extends tools/probes/transformation_encounters.gd. Temporary learner root is hall-local (11.5,0,15.5). See REPORT.md for test scope and engine warnings. Reproduction scripts retain repository paths and are not portable without that project.
