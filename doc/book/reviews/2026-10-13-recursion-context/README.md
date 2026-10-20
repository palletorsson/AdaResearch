# Recursion, Cantor and the opening L-system lesson

13 October 2026. A focused teaching revision following the user's reading of the parallel book. The request was for the context and explanation a student needs, beyond a working reconstruction. Five Markdown files changed; four hall PDFs refreshed. No artifact or map code changed.

## Editorial decisions

| Text | Addition or correction | Reason |
| --- | --- | --- |
| Fractal_Recursion/tutorial.md | Explain the purpose of a self-call; trace the four calls, their separate arguments and return order; name the call stack and finite cost. | The student needs to understand why recursion is useful and what execution does. The nested frames remain a simple case that could use a loop. |
| Fractal_RecursiveTrees/tutorial.md | Trace a trunk and two distinct returned children; connect one recipe to a hierarchy; contrast the placement of the stopping test with Frames. | The branching case makes recursion's usefulness visible. An explanation prompt distinguishes understanding from copying the code. |
| Fractal_RecursiveTrees/tutorial.md | Replace the promise of another self-call in Cantor with an array holding the next generation. | The actual Cantor tutorial uses old/next arrays and a loop. A shared branching construction does not imply identical implementation. |
| Fractal_CantorSet/final.md | Introduce Cantor, sets, countability and different sizes of infinity; connect counting, length, finite display and bodily passage to Ada. | The historical name belongs in the argument, with a reason to care about it. This is context and reflection, not another implementation task. |
| LSystems_Grammar_Lab/tutorial.md | Introduce Lindenmayer and the five building blocks; work through two Cantor rewrites and explain normalized step length; separate these concepts from workspace setup. | The reader can explain the vocabulary and trace an example before reading the complete program. The existing loop-based implementation and the opening Koch preset are stated accurately. |
| LSystems_Grammar_Lab/final.md | Introduce the biological motivation; recall Cantor when the construction returns as a sentence. | The reflection asks what a description makes possible and what an outline does not establish about living growth. |

The Cantor tutorial already explicitly connects Trees' child calls with its two array appends. That useful explanation was retained without rewriting it. Unrelated working-tree edits in Grammar Lab were preserved. No prose was removed to meet an arbitrary length target.

Exact pre-edit working-tree files are in `before/`; `changes.diff` records every addition and replacement. `text-checks.json` records before/after hashes. Existing fenced code and artifact/student-code markers are unchanged in all five texts.

## Existing halls and implementations checked

- Current fractals and L-systems sequence order, also listed in `commons/data/museum/em_plan.json` under `_map_halls.chapters`.
- Recursion's map token: `fractal_recursion_2:180:2.2#initial_size:2.2#depth:1#lesson:true#room:thresholds`; registry scene and `algorithms/fractals/example_8_2_recursion_vr.gd`.
- Recursive Trees' map tokens: `recursive_tree:180:0:0.42#lesson:true` and `recursive_tree_2:180#lesson:true#room:canopy`. The tutorial distinguishes its nested-node reconstruction from the museum's generation queue.
- Cantor's map tokens include `cantor_set:180#lesson:true` and `example_8_4_cantor_pagoda_vr:180#lesson:true`. `algorithms/fractals/cantorset/cantor_set.gd` retains the thirds rule and installs the lesson fixture.
- Grammar Lab uses `lsystem_editor:180#lesson:true#grammar:koch#depth:1`. The registered `commons/artifacts/lsystem_editor/lsystem_editor.gd` has the turning Koch rule, Cantor `F → FfF` / `f → fff`, old/next rewriting, and the lesson branch. The historical additions do not assert new hall behaviour.

## Validation

`python -X utf8 doc/book/reviews/2026-10-13-recursion-context/verify.py`

- Reconstructed the student scripts directly from current tutorial fences in a fresh review folder.
- 24 Fractals Godot checks passed, including distinct 0.49-metre child nodes in the new one-generation trace, inherited transforms, stopping conditions and the supplied XR/desktop interaction paths.
- 33 Grammar Godot checks passed, including the new two-generation Cantor trace. The existing probe also compares 40 combinations of rules, depth and angle against the museum generator's fitted endpoints.
- This is author-led execution with supplied poses. It validates the numerical examples and reconstruction; it does not establish a human student's understanding or a new headset playtest.
- Four PDFs contain 20 spreads and all 19 code fences. Export checks found no missing text, out-of-bounds text or warnings. Rendered contact sheets and detailed opening spreads were inspected; the L-system table and its introduction stay together on the second spread.

The export script, source snapshots, previous PDFs and visual checks are in `C:/Users/palle/Documents/book/_export/recursion-context-2026-10-13`. The executable refresh script is `C:/Users/palle/Documents/book/_export/refresh_recursion_context.py`. The rest of the book retains its existing snapshots.

## Sources and teaching reference

- Daniel Shiffman, [The Nature of Code, Fractals](https://natureofcode.com/fractals/): recursive functions, their termination, branching and L-system teaching. The examples added here trace our existing Godot programs rather than copying the book's JavaScript examples.
- J. J. O'Connor and E. F. Robertson, [Georg Cantor, MacTutor](https://mathshistory.st-andrews.ac.uk/Biographies/Cantor/): historical context for sets, countability and different infinite cardinalities.
- Przemyslaw Prusinkiewicz and Aristid Lindenmayer, [The Algorithmic Beauty of Plants](https://algorithmicbotany.org/papers/#abop): further reading on biological modelling and graphical interpretation. The publisher-hosted listing was accessible; the chapter PDF timed out during this pass. The origin/date claim was checked in Shiffman's chapter.

The learning questions now ask for an explanation, a trace, a prediction and a controlled variation. Automated checks address the trace and output; a reader must still tell us whether the explanations make the construction intelligible.
