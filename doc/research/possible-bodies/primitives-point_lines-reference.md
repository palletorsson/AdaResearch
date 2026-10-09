# Point–Line: encounter reference

Companion to the revised final.md, 15 September 2026.

## Relations, geometry and consequences

The connection manager appends each endpoint to the other's adjacency list after duplicate checks. The demo listens for `connection_created` and recognises its endpoints. Their first connection calls the nearby barrier's `trigger_explosion()` in this hall. The collider is removed and visible pieces scatter; disconnecting does not reconstruct the barrier. Larger endpoint spheres previously hid a short connecting segment, illustrating the difference between maintaining a relation and drawing it legibly.

The floor marking generates a stripe and lettering, without obedience tracking. The intact barrier uses a collider extending from the floor to its plank. The picked-up rod is one body with a fixed span. Its resistance effect responds to proximity to whole-number world coordinates, rather than its length. The dance-pole association in final.md describes a possible way of thinking about the relation; the short rod is not a physically supporting pole.

## Instruments

The half-metre ruler is a visual comparison display. A measuring action that changes another object remains a proposal. The bead uses interpolation along a segment and cosine to vary its parameter. The measuring laser reports its first physics hit within its range; this hall enables dwelling on the barrier to break it. The orange sphere responds instead to controller pointer entry and returns after a cooldown.

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
