# The point continues

5 October 2026. One continuation pilot: Point One → Point Coordinates, pickup and release only.

The student continues the same point. Its sphere, material and matching collider are inherited. The new lesson prints three edits: change the physics body class; add its pickup settings; reparent the existing visible surface. Full files remain available outside the lesson's reading flow.

## What the test establishes

1. `incoming.gd` records the assumed student state and pins its source evidence.
2. `contract.json` contains exact edits printed in `tutorial.md`.
3. `prepare_lesson.py` mechanically applies those edits. A missing or ambiguous anchor fails; no solution is filled in behind the lesson.
4. Godot runs `assembled.gd` with a private copy of the actual XR Tools library.
5. The generated output is available as the next lesson's incoming code, with an exact hash in `next-input.json`.

| Check | Result |
|---|---|
| Printed edits assemble the saved outgoing code | Pass |
| Native behaviour | 62/62 checks pass |
| Missing reparent line | Rejected by four expected checks |
| Incoming source, lesson, contract, output and verifier freshness | Pass |
| Learner explanation and transfer | Not tested |
| Physical headset and museum integration | Not tested |

The native checks cover radii 0.14 and 0.30, a translated and rotated station, preserved geometry/material/world placement, real near-grab overlap, disabled pickup, movement of both surface and boundary, retained node/resource identity, and stationary release. They bypass hardware input with a synthetic controller. Runtime code and addon files were unchanged.

## The useful failure

Point One makes the visible mesh and static collision body siblings. Merely replacing `StaticBody3D` with `XRToolsPickable` can move the boundary without its visible sphere. Omitting `body.reparent(solid)` compiles but fails the same behaviour contract: the body and collider move while the surface stays. This tests a causal step, not just whether code parses.

## What remains an assumption

The incoming ghost is an explicit reconstruction of what Point One assumes the learner has built. Point One currently provides edits to an existing museum script, so this pilot does not yet prove that its incoming source can be produced from that lesson alone. Source material supplies the names, subdivision settings and material helper; their presence is not evidence that the student has mastered them.

An exact patch assembler cannot judge ambiguous prose. A fresh reader still needs to apply the instructions, and a learner needs to predict, explain and make a variation. The files are reproducible evidence of this bounded transition, not a certificate for the entire Coordinates tutorial or the book.

## Reproduce

From the repository root:

```text
python doc/book/iterations/2026-10-05-lesson-state-chain/prepare_lesson.py
python doc/book/iterations/2026-10-05-lesson-state-chain/run_checks.py
python doc/book/iterations/2026-10-05-lesson-state-chain/build_review.py
python -m unittest discover -s doc/book/course/functional_text -p test_reconstruction.py
```

The runner uses the installed Godot executable, overridable with `GODOT_EXE`; the report renderer requires Python Markdown. Only the private fixture project runs. Lesson/source changes require a fresh test before the report can pass again. The 22 checker tests include omitted printed edits, ambiguous anchors, stale input, manually changed output and incomplete runtime evidence.

The canonical museum tutorials and `final.md` were not revised by this pilot. The durable writing guide now says: **complete lineage, minimal new change**.
