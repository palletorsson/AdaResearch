# Pattern Temple review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots. learner/printed is extracted from the four tutorial code fences. learner/four_columns is the independent edit. Other learner folders deliberately contain faults. The museum and XR Tools are prerequisites.

Run: python tools/test_tiling_temple.py
Native: python tools/run_encounter_probe.py Pattern_Temple --sequence tiling --render --no-bridges --probe tools/probes/tiling_temple_room.gd --output-tag receiver-copy --spec doc/book/iterations/2026-10-09-tiling-revision/Pattern_Temple/spec-student.json

The native probe temporarily places the learner at temple-local (0,0,1); three approaches were collision-checked. reproduce/ preserves scripts with repository-relative assumptions. Code, pointer and synthetic XR checks do not replace headset or student observation. before/ records absent canonical texts and the original obstructed desk; desk.diff is the sole production artifact change.
