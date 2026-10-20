# Euclid — the same triangle

Inside AdaResearch, open `res://doc/book/studies/euclid-lineage/museum.tscn` in Godot 4.6 and run the current scene (F6). This supplied launcher opens the existing Euclid hall and adds the student's reconstruction beside the original comparisons. The ordinary museum route, map and artifact registry are unchanged. The launcher writes only its own lesson control file under `user://`; the construction is session-only.

Grab A, B or C. Hand movement is projected into the study's local X/Z plane and bounded to ±1 metre. The sphere stays with the hand while held, then returns to its recorded table position on release. GUIDE, G or the held trigger toggles the gold parallel. RESET or R restores the points when none is held; it keeps the guide setting.

The canonical lesson is `commons/maps/Euclid_Parallel/tutorial.md`. All four student scripts are printed there in full. Two are new: `triangle_record.gd` stores and measures the construction, and `euclid_study.gd` constructs its view and controls. The small `point_body.gd` is carried unchanged from Graph Theory / Gradient Landscape; `line_skin.gd` is carried unchanged from Point Lines. This is class and construction continuity, not a saved live object moving between scene loads. No learned model weights enter this lesson.

`study.tscn` is the minimal attachment scene. It has no player, camera or lights; use the museum launcher for an actual visit. A reconstructed student folder can be mounted by changing the supplied launcher's `LESSON` preload to its `euclid_study.gd`, or by adding its Node3D on clear floor in a working copy. Keep study scale at `(1,1,1)`. The prepared project's XRTools and `res://commons/interactables/push_button.tscn` are declared dependencies; this is not a blank-project export.

Reproduce from the repository root:

```text
python -X utf8 tools/test_euclid_lesson.py
python -X utf8 tools/run_encounter_probe.py Euclid_Parallel --sequence foundationscrisis --render --no-bridges --output-tag euclid-lesson-readout --probe tools/probes/euclid_lesson_museum.gd
python -X utf8 tools/publish_euclid_lesson.py
```

The first command extracts the printed listings and runs real Godot assertions. The second mounts that exact reconstruction in an isolated capture of the existing hall. Fresh ghost-student evidence and earlier failures remain in `doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/`. Synthetic grab tests supply hand poses continuously across physics frames; a one-time rigid-body teleport is not an adequate held-hand simulation.

The tests establish selected software behaviour in a flat Euclidean coordinate model. They do not prove Euclid's postulate, establish human learning, or validate physical headset interaction. Engine UID and Jolt diagnostics are retained in the review logs.
