The last room compared what a finite budget makes visible. This one stretches that comparison into a walk. When each ring has more sides, what are you approaching, and what would count as arriving?

<!-- @combine_portals -->

Begin beside an early faceted ring. Follow a straight edge around its opening, then compare with a later ring along the route. Move far enough away that the facets become harder to distinguish. Turn back and read the progression in reverse.

Before looking for an explanation, choose one ring that seems sufficiently round for the view you have. Keep that choice in mind as you move closer.

The placed ladder constructs twenty torus meshes. Its first has three rings and three segments; each subsequent member adds one ring and two segments. At the twentieth, those counts are twenty-two and forty-one. The sequence is finite, and both subdivisions of the torus are changing.

Find the side instrument. **NEXT RING** and **PREVIOUS** select a member of the sequence; the selected ring turns gold. The display reads its two subdivision counts and the triangle count from its actual mesh. Selection does not move you. It gives you a ring to find from a reachable viewpoint.

Now predict what **REVERSE** will change. Press it and inspect the beginning again. The positions remain; the same family of mesh resolutions runs in the opposite direction. The later refinement has become an earlier encounter.

The order made a claim: that coarse-to-fine was a direction worth walking. You can prefer the early facets for another purpose without having misunderstood the later refinement. Reverse again to return to the original progression.

<!-- @ -->

## Closer is a relation

To study circularity precisely, simplify the torus's two surface directions to one planar circle. Place a regular polygon inside a circle of radius `r` and measure its perimeter:

```gdscript
func polygon_perimeter(n: int, r: float) -> float:
    var total := 0.0
    for i in range(n):
        var a := Vector2.RIGHT.rotated(TAU * i / n) * r
        var b := Vector2.RIGHT.rotated(TAU * (i + 1) / n) * r
        total += a.distance_to(b)
    return total
```

Each finite polygon joins points by straight chords. Its perimeter is shorter than the circle's `TAU * r`, and the gap approaches zero as the side count grows without bound. The side instrument now makes this separate comparison explicit. It uses the selected torus's ring count as `n` for a regular polygon in a **unit circle**. Its perimeter is calculated by the equivalent chord formula:

```gdscript
var perimeter = 2.0 * n * sin(PI / n)
var gap = TAU - perimeter
```

These are numbers for the planar polygon, not a measurement of the three-dimensional portal's rim. The panel labels the comparison separately because changing two torus subdivisions is not the same experiment as refining one circle.

No finite member becomes the circle merely by having many sides. Yet a finite approximation can meet a chosen tolerance. “Close enough from here” and “exactly the mathematical circle” answer different questions.

Return to the ring you chose. State a tolerance in terms of a use: readable as a circle at the entrance, visibly faceted at arm's length, an opening whose silhouette you enjoy. The purpose supplies a stopping rule that endless refinement does not supply on its own.

<!-- @ -->

## Achilles, and the staging of a limit

<!-- @achilles_tortoise -->

The two markers wait at their initial positions. Before pressing **NEXT STEP**, point to where you expect Achilles to go. Follow the shrinking intervals toward the end marked *limit*. The button places each next stage directly, leaving you time to compare before continuing.

Keep an eye on two gaps: Achilles to the tortoise, and Achilles to the limit. They shrink together in this construction, but they are not the same distance.

The model sets Achilles' position after step `n` to:

```gdscript
var covered := track_length * (1.0 - 1.0 / pow(2.0, float(n)))
```

The tortoise is placed one halving step ahead. The initial gap and the successive remaining distances shrink under that rule. Each finite stage has a next one in the mathematical sequence.

After ten steps, the display stays where it is. On this six-metre track Achilles still has `6 / 1024` metres to the limit: about 5.86 millimetres. The remaining gap is small enough for the figures to overlap visually while their anchor positions remain distinct. An appearance of arrival deserves another look.

Press **RESTART**, then **PLAY**. Autoplay schedules stages at two-second intervals and eases the markers toward each target over one second. Pause partway through a movement and compare **A to limit now** with **A to limit at stage target**. One reads the current marker position; the other describes the endpoint of that stage.

The easing is another rule between the numbers and what you see. Manual stepping exposes the sequence of endpoints; autoplay makes a particular journey between them. Its equal display intervals do not model the shrinking durations of an infinitely subdivided physical journey. Pausing this instrument leaves the surrounding game running.

An infinite sequence of decreasing intervals can have a finite sum. Dividing a distance endlessly does not prove that crossing it takes endless time. Conversely, completing this ten-stage performance does not make its last marker the exact limit.

A separate numerical experiment could ask when a chosen floating-point calculation rounds a remaining gap away. This ten-stage instrument does not run that experiment. A rounded value, a completed display cycle and a mathematical limit each need their own test.

<!-- @ -->

## Further comparison: the hole survives the refinement

Compare the capsule's closed outline with the rings. Find a view that makes the opening unmistakable. Increasing the side count changes the approximation; it does not remove the torus's central passage.

The tetrahedral and cubic surfaces gave an Euler characteristic of two. A torus surface gives zero. An idealised grid drawn around a torus with `m` divisions in one direction and `n` in the other has:

```text
vertices = mn
edges    = 2mn
faces    = mn
V - E + F = 0
```

Splitting each grid face into two triangles adds one edge and one face together, leaving the result unchanged. These counts concern identified surface vertices and faces; a rendering buffer may duplicate vertices for seams or shading.

The hole belongs to the topology of the surface, while the side count belongs to a particular tessellation. Both matter, but increasing one number does not change the other kind of fact.

Passing your body through an aperture additionally depends on its size, placement and collision. Euler characteristic alone does not make a ring a walkable doorway. Nor does a ring mesh teleport you: that would require another mechanism for moving and reorienting the visitor.

<!-- @ -->

Choose two ways to complete this room. One might be reaching a later ring whose facets you can no longer see from a chosen distance. Another might be returning to a coarse ring and making its corners the point of the encounter. Describe what each ending values and what each leaves unresolved.

The next room gathers tools, forms and tests that can give exact answers. It asks you to choose a purpose those answers cannot choose for you.
