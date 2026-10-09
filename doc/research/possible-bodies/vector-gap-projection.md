# What the line can keep

[Working route](index.html#Vectors_Act2_VectorArithmetic) · [Primary artifacts and book](/necklace/thread?map=Vectors_Act2_VectorArithmetic&role=primary) · [Previous: addition](vector-addition.html) · [Vector / Forces plan](vectors-forces-plan.html)

Two stations in **Vectors_Act2_VectorArithmetic** now use one live pair of coordinates. Subtraction draws the gap from B to A. Projection receives that same gap, keeping its along-rail part and leaving the perpendicular remainder visible.

The room retains **all twelve artifacts and its five existing primaries**: vector_add, vector_sub, dot_aligner, projection_shadow, torque_crank. This pass upgrades subtraction and projection. The museum footprint remains 20 × 38 cells.

![The gap from B to A, on the floor and wall](vector_gap_RoomGap.png)

## First: a gap depends on direction

At subtraction, **SWAP** reverses the gap; **SHIFT** moves both addresses without changing it; **SAME** brings them together. **A/B** chooses an address, and **X− / X+ / F− / F+** move its components in half-metre coordinate steps. **RESET** restores the opening pair; **RULE** reveals the arithmetic.

Every component is bounded to ±1.5 coordinate metres. A common shift is refused as a whole if either address would exceed its limit. Both the floor and wall draw one coordinate metre as half a physical metre; the scale is stated on the display.

## Then: the receiver changes what counts

![The same gap decomposed along and across a rail](vector_gap_RoomProjection.png)

At projection, **RESET** returns the source pair and the rail to their opening values. **SLIDE** edits source A perpendicular to the rail: the incoming gap changes, but its gold projection stays fixed. The next press reverses that half-metre step.

**TURN** rotates the rail by thirty degrees while the input stays fixed. **FLIP** reverses the rail's orientation: the signed coordinate reverses, but the projected vector remains the same. **RULE** shows the kept part and the remainder; adding them reconstructs the incoming gap.

This is a connection between actual station states within the same loaded hall. The dot and torque consoles remain separate examples. There is no cross-session saved pair or player-force field implied by the connection.

## What this contributes

Subtraction makes direction matter where distance alone cannot. Projection makes the receiver's axis matter: what one rail excludes can participate when that rail turns. Keeping the remainder preserves the whole gap; keeping only the projection would lose the ability to distinguish many different inputs.

The revised book also checks the older exhibits against their source. The dot console uses an alignment slider and a classification threshold. The torque console derives a wheel angle and an rpm label from a normalized angular factor; it does not measure revolutions or integrate physical torque. That is an open implementation question for the forces work, now stated plainly in the chapter.

## Evidence and next step

[**30 desktop checks pass**](vector-gap-projection-check.json): actual pointer controls, shared source propagation, exchange and common translation, zero, perpendicular slide, reconstruction, orthogonality, rail reversal and repeated turns, input bounds, room isolation, ordinary-console compatibility and sampled standing/side approaches. Godot captures show the actual endless-museum placements. Headset reach, comfort and performance remain for later; the retained supporting exhibits are not all newly verified.

The next hall on the unchanged route is **VFM_05_Launch**. It should distinguish a destination from an initial velocity, then show what acts during flight. Moving Motion before Launch remains a proposal, not a completed sequence change.

## The book chapter

# What the line can keep

<!-- @vector_add -->

The carriage is behind us. We have watched two routes reach one destination, and a journey return with zero displacement. A smaller addition console offers the relationship again, through two pads that place the arrow tips on its upright diagram.

Move one pad. The sum moves with it. At this scale there is no carriage to wait for. That absence matters: the result appears immediately, although a body given that destination would still need a way to get there.

Keep the distinction as we walk. These operations give us relationships. A simulation has to decide what to do with them.

<!-- @vector_sub -->

Two small blocks stand on the next gridded stage. Amber is A, pink is B. The cyan arrow runs from B to A. Its copy on the wall makes the same connection.

Press **SWAP**. The arrow reverses.

In the previous hall, exchanging the contributions kept the sum. Here exchanging their roles changes the answer. The distance between the blocks has not changed. Which one we are trying to reach has.

**A/B** chooses an address; **X−**, **X+**, **F−**, **F+** move it in half-metre coordinate steps. Try **SHIFT** instead. Both addresses move sideways together, while the gap between them stays the same. That is the first vector room returning inside a new operation.

Then **SAME** brings B to A. The two addresses coincide. The cyan arrow has no length to draw.

Press **RULE**:

```gdscript
gap = a - b
```

From a shared origin, A and B each had an address. Subtraction gives the displacement needed to get from B to A. We could also add the reverse of B. We have not introduced another kind of number; we have asked a different question of the same coordinates.

The diagram has a scale of its own. Each coordinate metre is drawn as half a metre, on the floor and on the wall. X goes across; F goes forward on the floor and upward on the wall. An upward arrow in the drawing still does not authorize a climb. The little blocks are representations of addresses, not a measurement of the visitor's position.

The controls stop at ±1.5 metres per component. SHIFT refuses the whole move if either address would cross that boundary. It does not quietly move one and spoil the comparison. A limit chosen for the exhibit is already shaping which questions can be asked without rebuilding it.

<!-- @dot_aligner -->

Between the gap and its next use, a small aiming console makes a decision from an angle. Move its **ALIGNMENT** slider. The drawn aim changes relative to a target; the readout moves toward *FRIEND* as their directions approach one another.

The source compares normalized directions. Their dot product is one at complete alignment, zero at a right angle, negative when they point sufficiently against each other. This placement's ordinary slider covers only a limited angular range; it does not offer the whole operation. The larger dot-product exhibit beside it is a separate comparison, not another control for this console.

A threshold of `0.985` divides the illustrated target's status. The directions vary continuously, but the name changes at a boundary someone selected. The target is not learning to trust the turret. A drawing is being classified by a rule.

That is a useful place to pause before calling a number agreement. What relation have we measured, and what extra story did the label attach to it?

<!-- @projection_shadow -->

At the next wall, the cyan gap has arrived before us. This station reads the actual A and B values from the subtraction station in this hall. It has not invented a similar-looking example.

A rail lies across the diagram. Gold runs along it; pink reaches from gold's endpoint to cyan's. Press **RESET** to return both stations to their opening coordinates and the rail to X. Then **SLIDE**.

A moves in the source. The cyan gap changes. Gold stays where it was. Pink grows.

SLIDE moves A half a coordinate metre perpendicular to the rail, reversing that step on the next press. The rail cannot register this part of the movement in its along-rail reading. Here the remainder remains visible beside the answer.

Now **TURN**. The rail turns thirty degrees while the incoming gap stays fixed. What was beside the rail becomes partly available along it. The vector did not become more complete. The direction of the question changed.

When you press **RULE**, three short lines hold the experiment together:

```gdscript
kept = axis * gap.dot(axis)
remainder = gap - kept
```

The axis is maintained at unit length. `gap.dot(axis)` gives a signed distance along it. Multiplying by the axis turns that number back into a vector. Subtracting the kept part leaves the perpendicular remainder.

And the addition we already know can check the result:

```gdscript
kept + remainder
```

It gives the gap back. To ordinary floating-point precision, the remainder's dot with the rail is zero. Nothing needs to disappear if we keep both parts. If a later machine stores only the projection, many different gaps will fit the answer it retained.

Try **FLIP**. The signed distance changes sign, but the gold vector stays in place: both the axis and its scalar coordinate reverse. Even a negative number cannot tell its whole story without the frame it belongs to.

There is pleasure in finding that the pink part has somewhere to go. It was excluded from this rail's account, not from existence. Turn the rail and the distinction moves. We can build a machine that needs only the gold part. We can also ask what another body could do with the pink.

<!-- @torque_crank -->

The crank farther along takes the question toward turning. Its **LEVERAGE** slider changes the angle between an illustrated arm and push. Along the arm, the normalized cross-product magnitude is zero. Across it, the value grows toward one.

The source contains a compact expression of the geometric relation:

```gdscript
var torque_vec: Vector3 = r_dir.cross(f_dir)
```

These are unit directions. Their cross product supplies an axis and an angular factor. Physical torque would also need the actual arm length and force magnitude. The exhibit draws its wheel at an angle derived from that factor; it does not accumulate a wheel's angular velocity through time.

Look at the label that says *rpm*. In this implementation it is the factor multiplied by 320 and rounded. It is not a rotation counter. A plausible instrument has arrived before the dynamics that would make its reading a measurement.

We can use that discrepancy. The diagram shows a relation worth learning, and also where a future simulation must do more work. What the rail keeps of a push along an arm contributes no torque about that arm's origin; the perpendicular part can. Yet neither a projection nor a cross product, by itself, makes a body move.

The larger comparisons and the distant laser-operated diagrams remain around this route. We need not finish every version before continuing. The next hall in the current sequence is Launch. Carry the gap, its components and this unfinished wheel with you: a destination, a direction, an initial velocity and a force may all be written with vectors, but they ask different things of time.


## Continued: stand inside the curve

[Launch now has a full-scale chamber with central controls and paired flights](launch-chamber.html). The current next hall is VFM_03_Motion. The sequence order is unchanged.
