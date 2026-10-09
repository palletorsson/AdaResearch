# Test the printed Flashlight lesson

From the AdaResearch_46 root:

    python -X utf8 doc/book/iterations/2026-10-06-flashlight-keep-the-surface/build.py
    python -X utf8 doc/book/iterations/2026-10-06-flashlight-keep-the-surface/run_checks.py
    python -X utf8 doc/book/iterations/2026-10-06-flashlight-keep-the-surface/build.py

Python needs the markdown package. The runner declares its Godot 4.6 executable path. It creates a temporary minimal Godot project, extracts the sole marked code block from tutorial.md and verifies byte-for-byte agreement with lesson.gd. No main-project autoloads or child scenes are imported.

102 native assertions cover the baseline, three printed edits and one possible independent target choice. They exercise scene creation, distinct lights, fixed board geometry/material, colour assignments, light range/energy/angle, and negative-Z aiming under a translated and rotated host. Live changes to one light must preserve the surface and the second light. A direct surface edit must preserve the lights. Two study instances own separate materials.

Five deliberately broken programs must fail named behavioural checks. They repaint the surface, omit local-to-world conversion, aim positive Z instead of negative Z, set energy to zero, or give both variables the same light. Parser errors are not accepted as successful fault detection.

The GPU fixture uses the exact normal variant scripts in a 960×640 SubViewport. Its supplied orthographic camera, 0.035 ambient-light energy, background and receiving material stay fixed. It samples 9×9-pixel regions at the two original target positions. Thirteen checks cover image availability, dominant channels, colour substitution, additive overlap and withdrawal while keeping green. The capture window is minimized; it closes after rendering. An initial attempt to hide Godot's main window was rejected by the engine; the fixture uses the supported minimized window mode instead.

The colour comparison is qualitative. The test does not estimate luminous flux or claim calibrated colour mixing. Bright channels clip in this fixture, and the oblique red beam has a different footprint in the overlap image. The real museum contributes other lights, shadows and exposure conditions.

No new headset, full museum integration or student-comprehension test is claimed. The dated museum image on the review page shows an earlier installed encounter. The five new PNGs show this reduced lesson in its explicitly supplied rendering fixture.

verification.json pins the printed program, both test scripts, runner and test-project configuration. Its image hashes bind the reported rendering evidence. protected hashes preserve the current canonical manuscript, reflection, museum artifacts, map, sequence and execution plan.
