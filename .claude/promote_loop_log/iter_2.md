# Iter 2 — chair → PROMOTED (composition)

**Verdict:** PROMOTED as 4-component `BoxMesh` composition.

**Notes:** Profile chair (side view, 2D-style not 4-leg). Front leg + back leg + seat + back rest. Each is a single BoxMesh.

**Spec:** `commons/primitives/promoted/_specs/chair_v2.compose.json`
**Capture:** clean side-profile chair silhouette — two legs, seat plane, vertical back rest. Recognizable as a chair.

**Replaces:** ~205 lines of hand-coded vertex/face arrays for 4 boxes → 4-line JSON composition.

**Note:** Original was already a "profile chair" (side view), not a 4-legged 3D chair. Composition matches the original's intent exactly.
