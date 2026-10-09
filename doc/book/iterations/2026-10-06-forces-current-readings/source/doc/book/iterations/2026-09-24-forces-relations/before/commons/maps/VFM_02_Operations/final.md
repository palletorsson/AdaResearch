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
