# Two contributions, one destination

**Learning elements**

- Vector addition
- Resultant displacement
- Route length
- Coordinate conversion

Primary: `adder_board`, opt-in `lesson:room_sum`. Start with GO; then SWAP and GO. Predict the endpoint before revealing RULE. Compare PATH via A with direct. CANCEL makes B = -A; compare nonzero out-and-back distance with zero resultant.

Controls use real push_button pointer events: A/B selects input; X-/X+/F-/F+ change components by 0.5 m within [-1,1]. PATH switches route, SWAP exchanges inputs, CANCEL opposes them, GO homes and runs, RULE toggles arithmetic. There are no draggable pins in this room variant. The ordinary board retains its original interface in other placements.

`result = a + b` drives both wall and floor. Vector2 stores (local X, local forward) in metres; floor placement is Vector3(v.x, height, -v.y). Wall plotting uses 0.48 display metres per input metre. Both operands and all sums fit the chart; no projection component or result is clipped. Carriage speed is prescribed at 0.8 m/s. Waypoint traversal consumes leftover time across corners; movement is updated in the physics callback. The guarded AnimatableBody is not a force experiment or a player transport platform.

GO instantly resets position and travelled distance. Input/path changes stop and reset the trip; input selection and RULE do not stop it. The old 26 supporting instruments remain in their original relative arrangement, shifted ten source rows behind this arena. The next sequence hall remains Vectors_Act2_VectorArithmetic.

## From the floor plan into the scene

The carriage's coordinate conversion is:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second plan component becomes local negative Z; height is supplied separately. The wall's upward diagram axis denotes forward movement on the stage, not a climb. Starting values A=(1,0), B=(0,1) give route length 2 m and direct length sqrt(2) m. The travelled counter starts again after GO's instantaneous homing; it does not include the reset movement.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/VFM_02_Operations/final.md) is retained for comparison.
