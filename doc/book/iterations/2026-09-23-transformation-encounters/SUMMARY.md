# Transformation: let the encounter answer

Applied 23 September 2026 in the canonical museum source and manuscript.

- Restored the existing composition workbench after the combined rotation array; promoted it in roles, reading order and sequence metadata. It opens on the X/Y comparison and exposes intermediate forms.
- Added asymmetric face marks to the rotating cube and all 48 array cubes. Array marks occupy the visible top faces; collision stays unchanged.
- Moved MOVE THE BANK controls beside the third crossing without moving the landing or rails. RESET and the side aisles remain available.
- Revised Introduction and Rotation around those encounters; removed three short recaps across Introduction, Rotation and Body. All earlier code excerpts and named encounter anchors remain.
- Corrected the parser’s treatment of the numeric `initial_pair` option. It no longer silently changes station yaw and loses the selected pair.

Read [the review](index.html) for paired native photographs, changed passages, and whole revised halls. [Decisions](DECISIONS.md) distinguish accepted, qualified and deferred feedback. Exact source baselines are under `before/`; [source changes](source-changes.diff) and [file hashes](changed-files.json) describe this pass rather than the whole working tree.

## Verification

The isolated production museum passed 81 Rotation checks and 16 Introduction checks. These cover supplied control events, rendered transforms, unchanged collision, marker attachment, approach-floor support and bank reset. Native images inspected, including a visual correction to buried array marks. The two bank images use the same aligned bridge pose for a fair comparison. Text/code/anchor, grid-preservation, metadata, syntax and HTTP checks are recorded in `verification.json`.

No claim of headset comfort or learner acceptance. No live restart, save/bake replacement, commit, or historical full-book/audio regeneration. Cross-hall carving persistence remains a separate development possibility; retired source halls remain deliberately retained.
