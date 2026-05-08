# Iter 1 — steppedpyramid → PROMOTED (composition)

**Verdict:** PROMOTED as 10-component composition of `BoxMesh`.

**Notes:** Original was a Blender-exported vertex array (~110 vertices for 10 stepped layers). Each step is the same height (0.1) and 0.2 narrower than the one below — so 10 stacked `BoxMesh` boxes with sizes 2.0, 1.8, 1.6, ..., 0.2 reproduce the ziggurat exactly.

**Spec:** `commons/primitives/promoted/_specs/steppedpyramid_v2.compose.json`
**Scene:** `commons/primitives/promoted/steppedpyramid_v2/steppedpyramid_v2.tscn`
**Capture:** clean ziggurat silhouette, 10 visible steps from base to tip.

**Replaces:** ~250 lines of hand-coded Blender export → 10-line JSON spec.
