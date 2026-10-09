# Test the printed lesson

Run from the AdaResearch_46 project root with Python, the Python markdown package and Godot 4.6 available:

    python -X utf8 doc/book/iterations/2026-10-06-colour-the-same-parts/build.py
    python -X utf8 doc/book/iterations/2026-10-06-colour-the-same-parts/run_checks.py
    python -X utf8 doc/book/iterations/2026-10-06-colour-the-same-parts/build.py

The engine path is declared at the top of run_checks.py. The runner creates an isolated temporary Godot project, extracts the one marked code block from tutorial.md, and checks it against lesson.gd. No museum autoload, child node, asset or hidden geometry helper is needed. The host provides a translated and rotated Node3D; headless tests exercise its real scene tree, mesh resources and material assignments.

There are five configurations: the printed baseline, three exact exercise edits, and one possible answer to the independent composition exercise. verify.gd records every behavioural assertion and returns a nonzero exit code on failure. The runner also demands that each of five deliberately broken versions fails the specific assertion it should violate. A parser error is not accepted as fault detection.

Repainting must retain node, mesh and material identities, mesh bounds and local/world transforms. Other checks cover distinct resources, intended group colours, palette values being copied rather than linked, independent study instances, assignment length and the chosen five-part construction. The lesson's own assertions guard assignment length and valid indices; the native suite exercises valid authored assignments, not malformed-input rejection.

The first geometry check incorrectly expected the finite SphereMesh bounds to reach its mathematical radius exactly. In Godot 4.6 the default rings produce widths about 1.08 mm and 0.96 mm below the nominal sphere and dome diameters. The corrected test checks the requested radius and height exactly and allows less than 2 mm of undershoot only in the sampled X/Z bounds. Floor contact, vertical continuity and total height remain exact within normal floating-point comparison. Repainting must preserve the exact original mesh and bounds; it gets no such tolerance. No lesson-code change was needed.

These are program tests, not a measurement of perceived colour, museum lighting, headset comfort or student understanding. The existing museum photographs are dated evidence of the source exhibit, not new screenshots of this reduced program.

The three printed edits are reviewed in order: group blocks and round forms; recolour the red group; restore red and alternate the assignments. Keep the five-entry list and palette in view when explaining a result.
