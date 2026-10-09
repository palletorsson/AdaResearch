# Transformation sequence refresh — 16 September 2026

The active sequence is now seven halls: Pre → Introduction → Translation → Rotation → Scale → Body → Pit. Its question is what changing position, orientation or size makes possible for a body. Each comparison is attached to an operation present in the room.

## Implemented

- **Pre:** the first still cube can be collected on contact. Three moving demonstrations remain available; four completed platform pickups remain collectible.
- **Introduction:** the scale surface and rotating plank meet the floor. The plank is 3.6 × 0.2 × 1 m and overlaps both banks after its quarter-turn.
- **Translation:** preserves seven rides and thirteen pickups; adds two hand-operated door mechanisms at the exit. One requires up then sideways, the other permits both directions together. Handles stand about 1.3 m above the deck. The same endpoint does not imply the same permitted journey.
- **Rotation:** combines Rotation and Spectacle in 39 × 60 m, 54.1% less source floor than the two previous halls. Retains full-size centre blades, four 2 × 6 arrays, a five-segment tunnel and all five distinct cake profiles. The former Spectacle source folder remains intact.
- **Scale:** the starting room is 4 × 4 m and grows fourfold to 16 × 16 m, within a 21 × 22 m hall. The bottle, figure, food tower and thirteen serving steps remain. An unchanged doorway outside the growing room makes the parent/child boundary visible.
- **Body:** preserves the three responsive thresholds, repairs the exit floor and distinguishes reversible rotation/scaling from persistent deletion in the text.
- **Pit:** floor-anchored cubes grow from 0.3 to 3.5 m over a 6⅔-second cycle. Pushers now obey their configured directions. Text describes measured timing and the contrast with Body's proximity input.

Updated all seven `final.md` files and relevant teaching documents. The core encounters, editable artifact roles, authored museum list, runtime/export plan, beat score, wall-text book and generated spine views follow the same order. The old AxisDecomposition stop no longer reappears through a stale plan. Other chapters' runtime plan rows and existing curator operation lists were checked unchanged.

## Evidence and practical limits

| Suite | Passed | Scope |
|---|---:|---|
| Pre | 8/8 | Actual museum; real XRTools collision body collects first cube |
| Introduction | 15/15 | Actual museum; floor rays, mesh/collision parity, held crossings |
| Translation permissions | 19/19 | Actual museum; handle reach, configured constraints, pickup/release signals |
| Compact Rotation | 42/42 | Real source grid; held blades, array comparisons, returns, tunnel and aisles |
| Scale | 30/30 | Actual museum; bottle, all serving steps, doors and furniture clearance |
| Body | 8/8 | Actual museum instances and repaired exit floor; not a full gate traversal |
| Pit | 27/27 | Actual museum; complete growth cycle, pusher paths and legacy defaults |

149 checks passed, plus the separate Rotation museum smoke/capture checks. Tests distinguish held walkable states from live crossing timing. No headset comfort or complete learner walkthrough is claimed.

Shared defects fixed during the pass: numeric configuration keys being mistaken for tutorial yaw shorthand; pusher endpoints cached before map configuration; grower geometry drifting because a synchronized body origin was moved while its shape resized.

`tools/long_museum.py --check` and `tools/museum_necklace.py --check` pass against current sources. They still report preexisting ragged/mismatched layers in Tutorial_Disco and Noise_Inside_Noise, outside this pass. Those source maps were not changed.

The live encyclopedia returned HTTP 200 for the review, images and revised source documents. Its roles API returned exactly seven Transformation halls with primary artifacts matching the book (`http-checks.json`, `role-checks.json`). Browser automation was unavailable in this run; the actual Godot captures were visually inspected, and the review's image/link paths were checked.

## Review and next action

Open http://localhost:3003/research/possible-bodies/transformation-refresh/index.html for screenshots and links to the editable text and encounter map of every hall. `transformation-reading.md` gathers all seven current drafts. The `before/` folder preserves the state before these edits; per-hall reports provide reproduction commands.

The next useful pass is a headset walk from Pre to Pit, recording where boarding, landing, grabbing or finding the next opening needs attention. Revise the sentence and artifact together where that encounter disagrees with the intended comparison.
