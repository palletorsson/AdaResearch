# Test the printed Nails lesson

From the AdaResearch_46 root:

    python -X utf8 doc/book/iterations/2026-10-06-nails-a-position-to-colour/build.py
    python -X utf8 doc/book/iterations/2026-10-06-nails-a-position-to-colour/run_checks.py
    python -X utf8 doc/book/iterations/2026-10-06-nails-a-position-to-colour/build.py

The runner extracts the marked program from tutorial.md and checks exact agreement with lesson.gd. It also verifies that point_body.gd and line_skin.gd match the corresponding printed source blocks in the current Lines lesson. A private temporary Godot project receives those files and an unchanged copy of the repository's XR Tools addon, with the two required XR Tools autoloads. The addon is supplied by Day Zero and is not repackaged in the review ZIP.

The passing run contains 118 native assertions and 12 GPU checks; all five faults were rejected. The first harness attempt needed two corrections: the SceneTree runner must load XR Tools after its autoloads are registered, and its synthetic pickup must use the library's public drop_object method. These were test-fixture changes; the printed 48-line program was unchanged.

To try a downloaded variant, copy its lesson.gd beside the inherited point_body.gd and line_skin.gd in your working museum project. The variants directory records complete edited programs, not separate runnable projects. The transfer variant is one possible answer to the independent receiver task; successful execution does not demonstrate that the student can explain it.

Checks cover the baseline, all three printed edits and an example independent position choice; corner and outside values; unequal box dimensions; one-channel changes; purity of the mapping; local/world conversion under translated and rotated hosts; independent materials; an additional preview receiving the same returned colour; and real XR Tools near-grab selection, carrying and frozen release through a synthetic controller. Hardware grip events are bypassed.

Deliberate faults remove clamping, mix world and local positions, use one dimension for every channel, omit material assignment, and exchange red and blue. Each must fail a named behavioural assertion. Parse errors do not count as fault detection.

GPU renders show the exact program at several positions in a supplied neutral fixture. An orthographic camera, white light, dark background and neutral floor are supplied test infrastructure. Pixel samples check qualitative changes on the preview. These are isolated study renders, not fresh screenshots from the museum or calibrated colour measurements.

The report also includes existing native salon photographs, clearly labelled as earlier museum captures. No full museum integration, physical headset, student comprehension or automatic transfer to the next room is claimed.

verification.json binds current program, prose, helpers, test inputs, addon dependencies and capture images by hash. Preserved source hashes establish that canonical texts and museum logic were not edited.
