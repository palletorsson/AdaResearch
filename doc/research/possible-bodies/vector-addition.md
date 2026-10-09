# The journey that adds up to nothing

[Working route](index.html#VFM_02_Operations) · [Primary artifact and book](/necklace/thread?map=VFM_02_Operations&role=primary) · [Vector / Forces plan](vectors-forces-plan.html)

The second vector hall now begins with **one addition encounter**. Two editable displacements feed the same result to a floor stage, a wall plan and a moving carriage. The primary remains **adder_board**, with a new room_sum configuration. The ordinary tabletop board remains available elsewhere.

![The addition arena in the actual endless museum](vector_sum_room.png)

## Try the comparison

1. **GO:** one metre across, one metre forward. The carriage travels two metres to the cyan destination.
2. **SWAP, GO:** it turns at a different corner and reaches the same endpoint.
3. **PATH, GO:** take the direct route. Same destination; about 1.41 metres travelled.
4. **CANCEL:** B becomes the opposite of A. Compare GO via A with GO direct. One goes out and returns; the other stays home. Both have zero resultant displacement.
5. **RULE:** reveal the component addition and compare total route length with resultant magnitude.

**A/B** selects an input. **X− / X+ / F− / F+** change its components in half-metre steps. Each component stops at ±1 metre. F is local forward on the floor, shown upward on the wall; it does not lift the carriage.

![Controls and wall from a standing approach](vector_sum_console.png)

The side readout leaves the centre view open. Glass edges distinguish the stage from the museum walkways. Both side routes continue to the earlier collection. Its **26 supporting instruments are retained**, with their relative placements unchanged ten source rows farther back. The hall is now 24 × 26 source cells. [Placement ledger](vector-addition-placements.json).

## What this adds to the thread

The first vector hall asked what stays when both endpoints move together. This hall asks what stays when two displacements exchange their order. A shared endpoint is useful, but cannot recover the route that produced it. Cancellation puts that limit into motion: **zero displacement can coexist with a journey**. Accumulated distance keeps another account.

The receiver matters. Here the sum becomes a destination, while a fixed speed advances the carriage. A velocity or force could use the same vector addition operation, but would need a different update rule and units. Those are still ahead. The room does not claim to simulate applied forces or transport the player.

GO instantly homes the carriage before running; edits reset the trip too. That reset is excluded from the distance counter. The chapter names this convenience as part of the apparatus: the system decides where the measured journey starts.

## What is checked, and what remains

**27 desktop checks pass**: actual pointer events; input selection and bounds; swapped endpoints; direct and via-A distances; cancellation; numerical reveal; frame partitioning; actual physics-clock carriage motion; control heights; sampled standing and side approaches; glass collision; ordinary board compatibility. [Machine-readable report](vector-addition-check.json).

These are Godot captures from the real endless-museum hall, with the probe making this hall's artifacts visible for capture. Tracked hands, headset legibility, comfort and sustained headset performance remain untested. Retaining the supporting gallery does not certify all of its older controls. The prior wider manuscript is preserved in the repository work record for further editing.

**Next: Vectors_Act2_VectorArithmetic.** Carry these operands into subtraction and projection, checking what each operation keeps. Then distinguish prescribed movement from persistent velocity and acceleration. The current sequence order is unchanged; moving Motion before Launch remains a proposal.

## Book passage

# The journey that adds up to nothing

<!-- @adder_board -->

A pale cube waits inside a glass-edged grid. Amber makes one leg of a route; pink continues from its end. A cyan mark waits elsewhere on the floor. Above them, the wall draws the same arrangement from overhead.

Press **GO**. The cube starts at home, follows amber, turns, follows pink. It stops at cyan.

Now **SWAP**, then **GO** again. The turn happens somewhere else. The destination has not moved.

There is already something here that the destination cannot tell us.

In the previous room we moved two points together and kept their difference. Here we keep two differences and exchange their order. Each contribution belongs to the same floor frame: X across the stage, F forward into it. Both are measured in metres. The wall turns that floor into a small upright plan; its upward direction means forward, not climbing.

The first pair is one metre across and one metre forward. **A/B** selects a contribution. **X−**, **X+**, **F−**, **F+** change one of its components in half-metre steps. Change the pink contribution and watch both cyan marks. The wall and the stage receive one result.

Try **PATH**. The console now says *direct*. **GO** sends the cube straight to cyan. The corner has gone, but the destination remains. On these opening inputs the two-legged trip covers two metres. The direct trip covers about 1.41.

Press **RULE** when you want to see the arithmetic that has been holding this together:

```gdscript
result = a + b
```

Small enough to pass over. Yet this is where two contributions become something a receiver can use. Component by component, one metre across plus no metres across; no metres forward plus one metre forward. The result is `(1, 1)`.

The carriage receives the result as a destination. The wall receives it as a point in a diagram. Neither has to invent another answer.

Addition needs compatible quantities and a shared frame. A metre of displacement can meet another metre of displacement here. Later, two velocities or two forces can be added by the same component rule, but the resulting numbers will have different jobs. The shape of a vector alone cannot tell us which job it has been given.

**CANCEL** sets B opposite to A. Keep A nonzero. Cyan returns home.

Choose the route *via A* and press **GO**. The cube leaves, reaches the corner, and comes back. The travelled counter grows. The sum stays zero.

Zero has not meant that nothing happened.

Switch to *direct* and run the same pair. This time the cube stays home. Two journeys now share both their start and their destination. One has movement, a turn, elapsed time. The other has no distance to cover. If we kept only the sum, we could not recover which one we had watched.

The out-and-back is useful precisely because it does not vanish from every account. Displacement cancels; distance accumulates. We have already met accumulation. Here it keeps a fact that the endpoint leaves behind. Which account would a delivery machine need? Which would a tired body insist on keeping?

There is a small choreography in the implementation too. The stage turns its two floor coordinates into three scene coordinates:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second number goes forward along local negative Z. Height is supplied separately. Turning a plan upright on the wall has not given the carriage permission to rise. Its body is possible within this particular translation between representations.

The controls stop each input component at plus or minus one metre. A larger request meets a limit chosen for this stage. That boundary is not a property of vector addition. You can see the refusal by pressing again at the edge: the button still exists, but the value stays where it is.

And **GO** has its own convenience. It puts the cube back at home instantly before each trip. Editing the route resets it too. That return is outside the travelled counter. The experiment makes repetition easy by deciding where a journey begins. The running museum has no obligation to begin there with it.

For now, a prescribed speed carries the cube along a chosen path. Nothing here measures a push or asks the cube's mass. Beyond this arena the other instruments are still waiting: subtraction, projection, alignment, rotation. We can carry one question into them. When a relationship becomes a usable result, what becomes possible—and what would we need to keep if we wanted to remember more?


## Continued: the gap and its remainder

[The linked subtraction and projection encounters are now implemented](vector-gap-projection.html), with real Godot images, the revised arithmetic chapter and desktop checks. Five primary artifacts and all twelve placements remain. The current next hall is Launch; changing the route to put Motion before Launch is still a proposal.
