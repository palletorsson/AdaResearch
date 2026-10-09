from pathlib import Path
import hashlib,json
root=Path.cwd()
out=root/'doc/book/iterations/2026-09-24-forces-relations'
base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
texts={}
texts['Vectors_Act1_WhatAVectorIs']='''# The same difference, somewhere else

<!-- @VectorBasics -->

Two pins hold a small arrow between them. On the wall, two larger yellow arrows show it from different directions: one from the side, one from above. Move the tip. The wall answers.

Now **SHIFT** moves both pins sideways together. The small arrow has gone somewhere. The two wall arrows stay where they were.

We can see the movement and the lack of change at once. The wall has been asked for the difference between the pins. Both addresses have changed by the same amount, so their difference has not.

The point rooms gave us addresses; transformation let us move them. Here we can carry a relation from one place to another. *This far, this way* can begin somewhere else.

**PARTS** brings out the coloured component legs and their numbers. The calculation is short:

```gdscript
var displacement = end.global_position - start.global_position
```

The subtraction gives the displacement from the beginning to the end. It does not retain either address on its own. Many pairs of points can make this same arrow.

With **SHORT** and **LONG**, the gap changes from a quarter metre to one metre. Its direction stays. The wall pictures grow, although their display scale differs from the arrow in our hands. What they share is the measured displacement.

One wall view keeps X and Y, leaving out depth along Z. The other keeps X and Z, leaving out height along Y. Move the tip in a direction that disappears from one view and watch it arrive in the other. A movement can be missing from a picture while still taking place in the room.

These are world axes. Turning the bench changes its relation to them; it does not turn the world's frame with it. The arrow has a direction within an arrangement we inherited when we entered.

**ZERO** brings the pins together. There is no longer a direction from one to the other. SHORT or LONG can separate them again, but now the control has to supply a direction: it chooses the normalised diagonal (1,1,1). There was no little arrow hidden inside zero, waiting to be enlarged.

<!-- @ -->

The coordinate frame, route courier and length lantern remain nearby. A courier has to begin somewhere, even when its instruction is only *this far, this way*. Later, the point where a force is applied will matter too. The freedom to move a displacement arrow does not make every use of a vector independent of place.

<!-- @vector_normalize_demo -->

At the next diagram, an input arrow has a companion whose tip stays at the unit sphere. Lengthen the input: its companion keeps its length. Change the direction: both turn.

A long arrow becomes shorter here. A short one becomes longer. Both approach the same condition—one unit of length—with their different directions intact.

This is normalisation. A nonzero vector is divided by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

The sphere and rings make that common length visible at the scale of the diagram. They do not tell us how far a body should travel. A unit direction could guide a short step or a long journey; we would have to supply the distance separately.

Near zero, the companion disappears. The code treats any input length at or below 0.001 as too small to supply a direction and returns zero instead. That small neighbourhood belongs to the implementation. Mathematics leaves only the exact zero vector without a direction.

<!-- @ -->

At the first bench, the same difference could begin elsewhere. At the second, different lengths could share a direction. These are two ways of finding something in common without making the inputs identical.

In the next room, two displacements meet. The question becomes where they can take us together.
'''
texts['VFM_02_Operations']='''# The journey that adds up to nothing

<!-- @adder_board -->

A pale cube waits inside a glass-edged grid. Amber makes one leg of a route; pink continues from its end. A cyan mark waits elsewhere on the floor. Above them, the wall draws the same arrangement from overhead.

Press **GO**. The cube starts at home, follows amber, turns, follows pink. It stops at cyan.

Now **SWAP**, then **GO** again. The turn happens somewhere else. The destination has not moved.

There is already something here that the destination cannot tell us.

In the previous room we moved two points together and kept their difference. Here we keep two differences and exchange their order. Each contribution belongs to the same floor frame: X across the stage, F forward into it. Both are measured in metres. The wall turns that floor into an upright plan; upward in the picture means forward on the stage.

The first pair is one metre across and one metre forward. Change either contribution with the console and watch the cyan marks on the wall and floor move together. Both receive one result.

**PATH** offers another journey. In *direct* mode, GO sends the cube straight to cyan. The corner has gone, but the destination remains. On the opening inputs the two-legged trip covers two metres. The direct trip covers about 1.41.

Behind **RULE**, the arithmetic is waiting:

```gdscript
result = a + b
```

Small enough to pass over. Yet this is where two contributions become something a receiver can use. Component by component, one metre across plus no metres across; no metres forward plus one metre forward. The result is `(1, 1)`.

The carriage receives it as a destination. The wall receives it as a point in a diagram. Neither has to invent another answer.

Addition needs compatible quantities and a shared frame. Here a metre of displacement meets another metre of displacement. Later, two velocities or two forces can be added by the same component rule. The numbers will have different jobs. The shape of a vector alone cannot tell us which job it has been given.

## Coming home

**CANCEL** sets B opposite to A. With A still nonzero, cyan returns home.

Choose the route *via A* and press **GO**. The cube leaves, reaches the corner, and comes back. The travelled counter grows. The sum stays zero.

Zero has not meant that nothing happened.

Switch to *direct* and run the same pair. This time the cube stays home. Two journeys now share both their start and their destination. One has movement, a turn, elapsed time. The other has no distance to cover. If we kept only the sum, we could not recover which one we had watched.

The out-and-back is useful precisely because it does not vanish from every account. Displacement cancels; distance accumulates. We have already met accumulation. Here it keeps a fact that the endpoint leaves behind. Which account would a delivery machine need? Which would a tired body insist on keeping?

The counter also has a beginning. Each GO puts the cube home instantly and starts a new trip. That reset is not part of the distance it reports. The experiment lets us start again; it has chosen which movement belongs to the journey.

A prescribed speed carries the cube along its route. We have not yet needed a push or the cube's mass. Addition supplied a destination; another part of the program supplied the travel.

In the next room, exchange will matter differently. The gap from here to there has the same length as the gap back. It points the other way.
'''
texts['Vectors_Act2_VectorArithmetic']='''# What the line can keep

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
'''
for m,t in texts.items():
 rel=f'commons/maps/{m}/final.md'
 assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==base[rel], 'Concurrent manuscript edit: '+m
for m,t in texts.items():
 (root/f'commons/maps/{m}/final.md').write_text(t,encoding='utf-8')
print(json.dumps({m:len(t.split()) for m,t in texts.items()},indent=2))
