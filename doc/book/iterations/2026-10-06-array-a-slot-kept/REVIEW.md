# Array — a slot kept

A complete first lesson for the next sequence. The familiar BoxMesh cube and overlap sensor return from Transformation. Four copies become a plane; collecting one leaves its address intact.

150 native Godot checks passed; 3 printed exercise variants tested; 6 deliberate faults rejected. Feedback changed prose only; the printed code still matches that native run.

## What is new

Stable slots, independent references, occupancy values, a nested traversal and an event bound to its address. The clock rests in this lesson. Each cube stays still until the learner chooses a known transform.

One complete script starts with `depth = 1`, then the exact same construction opens into a plane with `depth = 4`. Both indices are visible from the beginning; all initial Z indices are zero. This refines the earlier proposal to keep the complete code visible once and avoid two competing script versions.

## Read and run

- [Tutorial](tutorial.html) · [tutorial.md](tutorial.md)
- [Tutorial beside existing final.md](parallel.html)
- [Complete program](lesson.gd) · [Code, tests and review ZIP](array-review.zip)
- [Verification](verification.json) · [Native checks](normal-report.json)

## Review focus

Can the reader explain the difference between a cube, its reference, its address and its occupancy? Is the row → plane step clear with both indices visible from the beginning? Does the complete program give enough context to choose and change another cube independently?

## Scope

This is an Array tutorial review draft. The canonical tutorial was missing and remains uncreated pending review. Existing final.md, maps, museum runtime, sequence order and plan acceptance are unchanged. The full report records actual checks and limitations; passing code is not evidence of human understanding.
