# Non-Euclidean Spaces — what counts as straight

Open `res://doc/book/studies/noneuclid-lineage/museum.tscn` in the prepared AdaResearch project, Godot 4.6, and run the current scene (F6). The supplied launcher opens the existing hall and adds the student study at hall-local `(13,1,7)`, on the existing raised floor. It writes its own lesson control file under `user://`. It does not permanently change the ordinary route or map placement.

PLANE / P and SPHERE / S select a model once every point is released. RESET / R restores the three coordinate pairs while retaining the selected model. Grab A, B or C to edit its record. The same small PointBody and LineSkin return from Euclid. The spherical model extends Euclid's triangle record; all five student files are printed in the canonical `commons/maps/NonEuclidean_Spaces/tutorial.md`.

The sphere interprets `(x,z)` as the unit direction `(x,1,z)`. Hand input inverts this upper-hemisphere chart, bounds both coordinates to ±1, and refuses positions too near or below the equator. The last valid record survives refusal. On release the point returns to the displayed surface. The whole study must have unit scale. Surfaces are visual models, not physical player constraints.

Mode changes keep the three point objects and coordinate records. They change displayed positions, edge paths and angle values; this correspondence is not an isometry. The records are session-only. Neither this study nor the separate original three-model bench changes the museum's walking geometry. DISK remains an existing comparison artifact; this focused coding exercise reconstructs plane and sphere only.

To reconstruct elsewhere, put all five printed scripts together, attach `surface_study.gd` to a Node3D, and point the supplied launcher's `LESSON` preload to it. `study.tscn` is a minimal attachment without its own camera, light or player. The project supplies XRToolsPickable and `res://commons/interactables/push_button.tscn`. This folder is not a blank-project export.

From the repository root:

```text
python -X utf8 tools/test_noneuclid_lesson.py
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --no-bridges --output-tag surface-lesson-raised --probe tools/probes/noneuclid_lesson_museum.gd
python -X utf8 tools/publish_noneuclid_lesson.py
```

The first command reconstructs the printed code and runs Godot assertions. The second mounts that reconstruction in an isolated run of the real museum and captures it from above and close up. Fresh ghost-student evidence, predictions and its own variation are under `doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/ghost/`.

Synthetic hand tests supply the pose continuously. They do not establish physical XR usability, desktop ray targeting, Quest performance or human learning. Existing UID/Jolt diagnostics are retained in the logs. The reference sphere is drawn with a finite mesh; its angle calculation uses analytical tangents, not the tessellated surface normals.
