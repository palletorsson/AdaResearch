# Fractals — a smaller, corrected reading pass

11 October 2026. Five text files changed across three halls. The seven-hall order remains Recursion, Recursive Trees, Cantor, Koch/Sierpinski, Menger, Golden Spiral and Synthesis.

| Place | Change and reason |
| --- | --- |
| Recursion, tutorial after the returned-call explanation | Explain that either reachable stop can terminate the example. Removing both leaves no programmed end to the call chain. The starting-depth clamp does not replace a check inside the function. |
| Recursion, final after the two limits | Add the consequence of stopping: nested calls finish and the result becomes available for the next action. Avoid the inaccurate claim that an unterminated self-call necessarily creates nothing. |
| Recursion, DRILL/SPREAD comparison | Extend “Equal counts have bought different bodies” to name the choice: spend the same budget along one branch or across many. Do not describe recursion in general as exhaustive. |
| Recursive Trees, final comparison | Replace the closing question with the number–seed–sentence comparison, qualified as choices within a rule. |
| Koch/Sierpinski, tutorial | Add an optional similarity-dimension explanation, checked with a halved line, a quartered square, Koch and Sierpinski. Separate ideal rule arithmetic from a finite box-counting estimate. The required reconstruction remains the Koch path. |
| Koch/Sierpinski, final | Name replacement and removal as the two moves. Distinguish the cabin and bookshelf's staged assembly from the pyramid's self-calls. Relate the bent arch's visible detail to cylinder thickness and viewing distance. |

Synthesis already names the grammar laboratory's ninety-degree `F+F-F-F+F` Koch rule and distinguishes it from the earlier snowflake. No duplicate was added. Cantor, Menger and Golden Spiral needed no restoration from this list.

## Source checks

The current sequence, placed tokens/configuration and saved museum plan contain the subjects discussed. In particular, the Recursion and Koch studies are in lesson mode, and the Koch arch is placed with `tick:coarse`.

- `example_8_2_recursion_vr.gd` draws before its next self-call and stops at depth zero or the minimum size. The learner's printed `repeat_frame()` has corresponding count and size tests.
- `cube_subdivision.gd:_pick_target()` selects the latest corner for DRILL and a shallowest surviving cell for SPREAD.
- The current tree text and sources distinguish the generation queue, seeded block tree and rewritten-string tree. The new sentence retains that comparison.
- `example_8_5_koch_curve_vr.gd` constructs four segments of one-third length. `sierpinski_triangle.gd` constructs the three half-side corner triangles. Their ideal similarity dimensions are approximately 1.261860 and 1.584963; the line and square checks give 1 and 2.
- `cube_cabin.gd` and `cube_bookshelf.gd` use named stages and loops. The Sierpinski pyramid uses recursive calls. `KochCurve3D.gd` renders successive path segments as cylinders of `line_width` radius; the text makes no claim that every depth looks identical.
- `lsystem_editor.gd` confirms the already-present Synthesis distinction: preset 0 uses `F → F+F-F-F+F` and ninety-degree turns.

## Validation

All code fences and `student-code` markers in the five edited files match their pre-edit versions. The dimension arithmetic and the presence of the discussed artifacts in their maps and museum-plan rows were checked. The scoped Git whitespace check passed.

This is source and prose validation. No artifact code, map, museum plan or lesson ordering was changed; no new Godot execution, ghost-student run or headset test is claimed.
