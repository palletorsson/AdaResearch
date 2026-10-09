# Point_Triangle_Context — encounter reference

16 September 2026; control instructions updated 19 September 2026. Working record behind the [book chapter](final.md), following the [operational inquiry method](../../../doc/book/OPERATIONAL_INQUIRY.md).

| Question | Current answer |
| --- | --- |
| Capability | Construct a closed boundary and a visible face as separate operations; inspect a filling procedure. |
| Prior knowledge | Points and endpoints, recorded paths, repeatable grid positions. |
| Primary encounter | `triangle_line_puzzle`, then `draw_triangle_faces`; these match the book and room-specific primary cards. |
| First observation | Three fitted edges close; the face waits for the fill button. |
| Further comparison | SHIFT START moves the fan start of the last completed six-corner planar L from A to B. Manual retracing from the adjacent corner remains available. |
| What changes | Input order and therefore the fan's fixed first vertex. No algorithm switch is installed. |
| What stays fixed | Stored corner positions, boundary and intended interior. SHIFT START cyclically rotates the loop's corner indices and replaces its fill. |
| Observable disagreement | From B, the fan covers part of the notch that the boundary leaves open. |
| Cost and count | SHIFT START retains one L loop and four logical triangles; earlier loops remain in the totals. The manual route keeps two L loops and eight triangles. This is not an entropy or freedom measure. |
| Possible response | Choose a suitable start, choose another outline, develop another triangulator, or use the excess for another purpose. |
| Handoff | Faces can now meet; what further connectivity encloses volume? |

## Evidence already available

The 16 September actual-scene primary probe passes 23 checks. The fan probe drives the scene with supplied positions and presses its actual NEW OUTLINE button callback. It finds four triangles from each start; the second has two triangle centroids inside the excluded notch. The summed areas are approximately 0.8 and 1.44 square metres, against a boundary area of 0.8. The larger sum includes overlaps and is not a union-area measurement.

These checks establish behavior for this specified input through the manual route. They do not test SHIFT START or demonstrate a person's comprehension or ease of drawing. [Implementation and scope](technical.md); [dated evidence record](../../../doc/space/point-triangle-focus-2026-09-16/README.md).

On 19 September, the new [SHIFT START regression](../../../tests/museum/triangle_shift_check.gd) passed 60 Godot assertions, alongside two authored placement/anchor checks. It exercises real pickup/release and pointer methods with supplied hand positions: the six corners and boundary stay fixed, the fan changes from A to B, and a complete cycle restores the original mesh geometry. Earlier loops, manual retracing, fill visibility, unfinished-outline guards, clear/redraw and the shared puzzle panel are covered. [Complete suite report](../../../ada_run/test-results/museum/20260919T114824Z-3f7651db/report.md).

Fresh [Godot images and findings](../../../doc/book/iterations/2026-09-19-triangle-shift-start/SUMMARY.md) show the notch comparison and the three-button panel in an isolated production scene. They verify neither full-museum placement nor headset reach. The original drawing in that probe crossed its panel; only the isolated observation stage was moved to leave the controls clear, with the first staging preserved.

## Next useful observation

When a headset is available, let a learner close the initial triangle without explaining the fill in advance. Then observe whether they can distinguish the boundary, the fill and its visibility. For the L, watch whether the one-second timing, snapping and DRAW START indicator let them preserve the intended six corners. Check whether they can reach SHIFT START, read its readiness and START marker, and compare A with B while recognizing that the boundary and triangle count stay fixed. A mistake in hand placement is not evidence against the specified fan comparison.

The optional SHIFT START control works on the last completed loop while the pen and all corners are released and no unfinished outline remains. The continuation anchor retained after closing a loop is allowed. START marks that loop's fan anchor; DRAW START marks an unfinished outline's first corner. NEW OUTLINE and manual retracing remain available. No preset selector or fan-quality warning is installed by this pass.

Keep the twelve secondary works available through [detours.md](detours.md). Choosing a focused first encounter must not silently erase the rest of the room.
