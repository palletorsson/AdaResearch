# Rotation — the carried body

16 October 2026. Four printed edits (19 code lines) continue Translation's tested files. Canonical tutorial.md is updated; final.md, Translation and museum runtime remain unchanged.

Before: a separate complete script reconstructed its own mesh. After: BoxBody, box(), _process(), travel and its dimensions are retained. The new code creates a pivot, reparents the body with its local transform retained, assigns an axis-angle basis, and adds a mark using the same BoxBody constructor.

## Short brief

MAKE: body spins, then orbits when offset; mark stays attached.
BRING: exact Translation complete/lesson.gd and box_body.gd; body, clock, placement function.
GIVEN: existing museum room, light, viewer and empty study host.
BUILD: pivot; local-preserving reparent; degrees to radians; orientation from time; attached mark.
CHECK: local offset fixed; world centre moves; shape preserved; mark returns after full turn; next turn continues.
CARRY: same constructor, clock and placement function; pivot/body/mark hierarchy into Scale.
LATER: composing multiple axes, sweep meshes, rider counter-rotation, physics.

## Evidence

253 passing assertions in Godot 4.6. Three exercise variants and one additional axis-length case. Five deliberately faulty versions rejected by the ordinary behavioural tests; eight missing/ambiguous edit anchors rejected. Tests execute the mechanically assembled scenes, incoming Translation and both checkpoints. Physical headset use and human learning are not established by these tests.

From repository root, run `python doc/book/iterations/2026-10-16-rotation-carried-body/verify.py`, then `publish.py`. The one-time `prepare.py` is guarded against replay.

## Book and encyclopedia

First constructions get full small examples; continuing lessons get precise new code. Keep full runnable states at checkpoints and in the dated download. The book's lesson remains understandable through its explanation, predictions and named edits; the encyclopedia holds full files and exact incoming line anchors. This local edition does not claim a permanent public print URL.

Next: repair Rotation → Scale using these complete files. The existing Scale tutorial still rebuilds its boxes; do not silently claim that handoff is finished.
