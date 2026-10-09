# One course, the same code

6 October 2026 · repairs following the ghost student's starter notebook

The book addresses a person working inside Endless Museum in VR. Device setup and desktop accommodations now sit in the preface, Day Zero and the supplied player guide. The tutorials stay with the object and the operation.

## What went wrong

The student tested an older portable starter. Its builder refreshed tutorial text without refreshing the programs beside that text. It therefore presented a second curriculum: Coordinates was missing, the line renderer ignored the displacement exercise, and older unshaded faces hid some geometric changes. The notebook is useful evidence of that edition; it is not a verdict on the current canonical manuscript.

## Repairs by encounter

| Encounter | Repair |
|---|---|
| Day Zero / preface | Establish VR once. Explain camera-following desktop pickup and release here. Distinguish the setup counter from Point Zero's engine counter. |
| Point Zero | Include the current complete label-initialization program and the once-only edit in the download. |
| Point One → Coordinates | Include both current lessons. Coordinates continues the same sphere construction, adding pickup and LOCAL/WORLD positions. |
| Lines | Run the current displacement-driven LineSkin. Reversed subtraction visibly misses B while preserving length. Include the complete edit. |
| Trace | Preserve initial pickup offset in the supplied desktop adapter. Save through a named supplied archive boundary: intentional release saves; teardown and XR focus loss do not. Keep lifecycle protection outside the small learner algorithm. |
| Grid | Load the saved segment sculpture and source positions. Keep pink intact; place the independently rounded green copy beside it. Compare spacing by editing the value and running again. Include the flat-Y edit. |
| Triangle | Package the current lit, one-sided face and explicit winding discussion. Retain the real saved positions; do not invent a valid gesture. |
| Polyhedra | Use the current lit faces, and explicitly show both sides in this enclosure study so an omitted face reveals an interior. The count now comes from the lists. Triangle's winding lesson remains intact. |
| Cube | Use the current lit surface and a 0.35 m corner edit, with the untouched cube beside it. |
| Remaining Primitives | Synchronize current programs, dependencies and tutorial text through Melencolia, including Godot primitives, Columns and Profiles. |
| Portals | Replace the old pilot with the current perimeter/refinement study. Its old extra reference ring is not part of the new program. |
| Optional colonnade | Raise all 25 identification cards above the bases, with dark text on a pale card. No column geometry changes. |
| Published Trans_Pre companion | Show time/height at stage zero; show `t` only when its stage introduces it. The seven-hall review draft is not promoted by the package builder. |

## What keeps the editions together

`tools/build_student_starter.py` extracts every complete named GDScript block from the 15 canonical Primitives tutorials. The packager includes those files, the declared helpers and the current lesson text. `LESSONS.json` records source and file hashes. Three small exercise variants are derived from the specified edits. Current tutorial download links point to these same files.

The starter is a supplied workbench for the museum course. It is not a replacement for the actual halls. Its historical programs remain in the repository, excluded from the current download. The old JSON trace is not silently treated as the new geometry archive: make and intentionally release a new drawing in the updated project.

The current canonical tutorials and preface are updated. The reflective `final.md` manuscripts are unchanged. The facing pages and complete Primitives readings are rebuilt from current sources.

## What passed

**128 native Godot checks** passed in a fresh unpacked download after a clean import. All 15 main programs and declared local files match the printed source. The tests include Point Zero initialization/update/once-only reading, local/world coordinates, line reversal, retained trace samples, independent geometry resources, integer addressing, the flat-Y edit, lit faces, the cube crease, later-hall construction and all 25 colonnade cards.

Trace → Grid runs through separate Godot processes. A synthetic hand uses the real XR Tools pickup, moves the point and releases it. Another run takes and moves the point, then quits while holding. Grid receives the previously released drawing with the original file hash, positions and segment geometry intact. Scene teardown, adapter cleanup and XR focus loss are tested separately.

Three deliberately broken controls fail the expected assertions: restoring pickup teleport; ignoring the reversed displacement; saving immediately on cleanup. This gives the checks a demonstrated ability to catch those defects.

Eleven native rendered views show the current studies. The comparisons keep the camera fixed while changing the studied rule. These are supplied-workbench renders and an optional gallery render, not photographs of a headset session. The drawing is a clearly identified synthetic test fixture; no saved student work is bundled in the download.

Physical headset tracking, grip feel, comfort and Quest performance still require a device session. These code checks do not establish a human reader's understanding. The next reading trial should use this exact download and its bundled texts, and report any point where an instruction or visible consequence remains unclear.

## Open or reproduce

- [Download the repaired project](../2026-10-03-ada-xr-starter/ada-xr-starter.zip)
- [Complete current tutorial](../2026-10-06-primitives-complete-readings/tutorial.html)
- [Tutorial and reflection on facing pages](../2026-10-05-primitives-facing-pages/index.html)
- [Student's original notebook](ghost_student_notebook_starter.md)
- [Native results and source hashes](verification.json)
- [Capture provenance](captures.json)

Run `python -X utf8 doc/book/iterations/2026-10-06-starter-one-course/run_checks.py` from AdaResearch, then `capture.py` and `build_report.py` in this folder. The runner uses the Godot executable named in its source and an isolated user-data directory. It does not overwrite a student's saved drawing.
