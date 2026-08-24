# Architecture-first placement contract

`tools/build_uffizi_footprint_pilot.py` generates the map in five explicit stages:

1. build the ordered Uffizi spine and room partitions;
2. mark route invariants and expandable room edges;
3. read the three artifact requests encoded by their dressing-room contracts;
4. negotiate bay dimensions without consuming the spine;
5. stamp artifact anchors and a non-runtime footprint evidence layer.

The hard architectural rules are a three-metre clear spine, a separate one-metre display band, aligned door bands, the south U-turn, and an axial end-stop. Side-room width, partition position, and vertical envelope may change. An artifact is rejected or moved to another bay before any hard route rule is weakened.

The map is 21 × 30 cells on the one-metre grid. Its pathfinder check reports one map OK with zero issues. The teleporter occupies a void threshold at `(3, 28)` with a safe catch strip behind it. Artifact anchors are `(12, 2)`, `(7, 11)`, and `(3, 21)`; the footprints remain wholly inside their side rooms.

This generator is intentionally separate from the dressing-room row composer. The latter asks, “How can these rooms be connected?” This pilot asks, “Which existing museum bay can accept this artifact, and what part of the bay may legally change?”
