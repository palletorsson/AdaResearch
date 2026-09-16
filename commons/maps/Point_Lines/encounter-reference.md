# Point–Line: encounter reference

Companion to final.md, updated 16 September 2026.

## Required path and optional returns

The current chapter teaches two distinct points determining a straight line, with a finite segment between them. Its five primary tokens are `line_demo`, `do_not_cross_barrier`, `line`, `walk_this_line_marking`, and `player_trace`, in that order. Joining, changing the endpoints, and comparing an instruction with a walk carry the reading towards Trace.

The other studies remain available as secondary encounters. The full preceding chapter is retained in [the chapter before the focused path](../../../doc/space/point-lines-proof-2026-09-16/chapter-before-focused-path.md). Its artifact markers document that earlier reading, not the current primary set. These reference notes preserve the experiments' working details for return visits and later chapters.

## Relations, geometry and consequences

The connection manager appends each endpoint to the other's adjacency list after duplicate checks. The demo listens for `connection_created` and recognises its endpoints. Their first connection calls the nearby barrier's `trigger_explosion()` in this hall. The collider is removed and visible pieces scatter; disconnecting does not reconstruct the barrier. Larger endpoint spheres previously hid a short connecting segment, illustrating the difference between maintaining a relation and drawing it legibly.

The floor marking generates a stripe and lettering, without obedience tracking. The intact barrier uses a collider extending from the floor to its plank. The picked-up rod is one body with a fixed span. Its resistance effect responds to proximity to whole-number world coordinates, rather than its length. The dance-pole association in the archived chapter describes a possible way of thinking about the relation; the short rod is not a physically supporting pole.

## Instruments

The half-metre ruler is pickable. Its action requires the tip to be within the pale subject's padded bounds. It reads the subject mesh's world-space width, then separately scales the blue witness by 0.72 with a bounded 0.35-second tween. Taking the tip away re-arms the action. This is an authored side effect, not an inherent property of measurement. The preceding description of this as a proposed interaction was stale; the scene already implemented it. The map placement was restored on 16 September 2026.

The bead uses interpolation along a segment and cosine to vary its parameter. The measuring laser reports its first physics hit within its range; this hall enables dwelling on the barrier to break it. The orange sphere responds instead to controller pointer entry and returns after a cooldown. It remains on the floor as a secondary pointer experiment and is no longer a required book encounter.

The held rod is now secondary; carrying a fixed span remains a useful preparation for comparison by a unit. Its coordinate-triggered jitter belongs with the coordinate questions in Grid. The ruler advances authored causality, the bead separates path from timing, and the laser makes a reading depend on the bodies it encounters. The freestanding parallels let the visitor change viewpoint around actual rods after studying camera images. These investigations can be revisited without becoming requirements of the first reading.

## Paired acceptance tests — 16 September 2026

`line_proof_pair` places two `PlusLinePuzzle` derivatives together with identical scattered stock and visible target rings. A uses `proof=relation`; B uses `proof=invariant`. Both reuse the existing perpendicular and midpoint constraints. Only A requires its endpoints near the targets. A dedicated subclass keeps handles and markers available and continuously re-evaluates acceptance. Ordinary plus puzzles retain their original completion behaviour.

Each bay has move-left, reset and move-right buttons. The move buttons translate all four endpoints by the same vector, within a 16 cm offset each way; they do not move the reference targets. Hands can move the endpoints independently. The existing constraints allow error: 8 cm target proximity, 5 cm between midpoints, and an absolute normalized dot product below 0.26 for perpendicular directions (about 15 degrees either side of a right angle). Degenerate segments are rejected. Acceptance therefore records a tolerance test, not a proof of exact mathematical equality.

The four workshop monitors show separately filmed arrangements. Walking past a monitor changes the visitor's view of that screen, not the private camera's view of the rods. The four-line camera already orbits automatically. A visitor-controlled second camera and an angle-only comparison remain extensions, not current instructions.

The workshop passage was shortened in the second editorial pass while keeping its four discoveries: projected crossing versus spatial intersection; the planarity of three joined segments; a closed four-edge boundary folding out of a plane; and edge arrangements that do not prescribe a unique surface. The third pass moves that passage out of the required reading; it remains in the archived chapter linked above. The earlier, longer version is retained in `doc/space/point-lines-proof-2026-09-16/workshop-extended.md` for later rooms.

Parallel segments retain their shared orientation as viewpoint changes; their spacings need not all be equal. Ordinary Euclidean straightness is not changed by viewing the line in VR.

The endpoint subtraction in final.md is an illustrative calculation. For distinct endpoints, displacement divided by its nonzero length supplies a unit direction. Geometry and the graph's adjacency data serve different purposes.

## Further code from the earlier passage

These excerpts are preserved from the preceding chapter version for reference. They include illustrative reductions; consult the surrounding notes and technical.md before treating one as a complete implementation.

```gdscript
_adjacency[point_a].append(point_b)
_adjacency[point_b].append(point_a)
```

```gdscript
var direction := displacement / distance
```
