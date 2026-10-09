# What the line can keep

<!-- @vector_add -->

The carriage is behind us. We have watched two routes reach one destination, and a journey return with zero displacement. A smaller addition console offers the relationship again, through two pads that place the arrow tips on its upright diagram.

Move one pad. The sum moves with it. There is no carriage to wait for. A body given that destination would still need a way to get there.

<!-- @vector_sub -->

Two small blocks stand on the next gridded stage. Amber is A, pink is B. The cyan arrow runs from B to A. Its copy on the wall makes the same connection.

With **SWAP**, the arrow reverses.

In the previous hall, exchanging the contributions kept the sum. Here exchanging their roles changes the answer. The distance between the blocks has not changed. Which one we are trying to reach has.

**SHIFT** moves both addresses sideways together. The gap stays the same: the first vector room returns inside this new operation. **SAME** brings B to A, leaving no length for the cyan arrow to draw.

Behind **RULE** is the subtraction:

```gdscript
gap = a - b
```

From a shared origin, A and B each had an address. Subtraction gives the displacement needed to get from B to A. We could also add the reverse of B. We have asked a different question of the same coordinates.

The blocks and their wall picture use a reduced scale. They represent addresses on the stage, not the visitor's position. The arrow can tell the little block how to reach its neighbour. Applying it to our own body would require another connection.

<!-- @dot_aligner -->

## When an angle becomes agreement

Between the gap and its next use, a small aiming console makes a decision from an angle. Its **ALIGNMENT** slider brings the drawn aim toward a target direction. As they approach one another, the target acquires the name *FRIEND*.

The console compares normalised directions. Their dot product reaches one when they align. In the wider operation it is zero at a right angle and negative when the directions point sufficiently against each other; this slider explores only a limited angular range.

Here `0.985` is enough to cross the threshold. The direction changes continuously. The name changes at once.

Nothing about the target's intentions entered the calculation. It became a friend by pointing nearly the same way. The number measures alignment; the label supplies a story about whom to welcome. What happens to that story if agreement stops being our condition for approach?

<!-- @projection_shadow -->

## Somewhere for the remainder

At the next wall, the cyan gap has arrived before us. This station reads A and B from the subtraction stage we just left.

A rail lies across the diagram. Gold runs along it; pink reaches from gold's endpoint to cyan's. **RESET** returns both stations to their opening coordinates, with the rail along X. Then **SLIDE** moves A across the rail.

The cyan gap changes. Gold stays where it was. Pink grows.

The rail's along-direction reading cannot register this movement. Beside it, the remainder makes the change visible. A second SLIDE reverses the step.

Now **TURN** moves the rail thirty degrees while the incoming gap stays fixed. What was beside the rail becomes partly available along it. The vector did not become more complete. The direction of the question changed.

The rule separates the gap into two parts:

```gdscript
kept = axis * gap.dot(axis)
remainder = gap - kept
```

The axis has unit length. `gap.dot(axis)` gives a signed distance along it. Multiplying by the axis makes that number into the gold vector. Subtracting gold from the gap leaves the perpendicular pink remainder.

The addition we already know can put them together again:

```gdscript
kept + remainder
```

It gives the gap back. Nothing needs to disappear if we keep both parts. If a later machine stores only the projection, many different gaps will fit the answer it retained.

**FLIP** reverses the rail's orientation. The signed distance changes sign, but gold stays in place: both the axis and its coordinate reverse. A negative number needs its frame before it can tell us where to go.

There is pleasure in finding that the pink part has somewhere to go. It was excluded from this rail's account, not from existence. Turn the rail and the distinction moves. We can build a machine that needs only the gold part. We can also ask what another body could do with the pink.

<!-- @torque_crank -->

## Across the arm

The crank farther along brings this perpendicular part to a different question. Its **LEVERAGE** slider changes the angle between an illustrated arm and push. Along the arm, the cross-product magnitude is zero. Across it, the value grows toward one.

```gdscript
var torque_vec: Vector3 = r_dir.cross(f_dir)
```

These are unit directions. Their cross product supplies an axis and an angular factor. For physical torque we would also need the actual arm length and force magnitude. A push directed through the pivot supplies no torque about it; the perpendicular part can turn the arm.

The readout names the factor, sin θ, beside the chosen angle. The wheel changes its pose as the slider moves. Let go and it holds still.

We can study the relation here without waiting for a wheel to accelerate. But setting a pose has not yet given the wheel momentum. To let it keep turning, we would have to give it a state that carries from one moment into the next.

The larger comparisons and the distant laser-operated diagrams remain around this route. Ahead, in Launch, a vector will be given another job. It will leave the diagram and become an initial velocity for a moving body.
