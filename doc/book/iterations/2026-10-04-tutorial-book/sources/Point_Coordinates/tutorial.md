# Point Coordinates — carry a position

Take the black sphere at the entrance. Its label stays behind. The point now follows your hand.

Point One separated a position, a surface and a physical boundary. Here the body can be held, and two cards report where it is. We will change its starting position and examine how the same place receives different numbers.

Work in the existing **Point Coordinates** hall. The point, frame and cards are already there. The code below identifies parts of their scripts; make only the specified edits in your working copy. Save and restart the museum after each edit.

## A body that can follow

The black point uses the supplied `XRToolsPickable` component. It connects the body to the prepared player's grab and release. Try taking it, moving it and letting go. We borrow that interaction here; building the player or its input system would be another lesson.

Open `commons/primitives/point/point_condition.gd`, the same script we read in Point One. Inside the `held` condition, find:

```gdscript
held.position = CENTRE
```

`held` refers to the pickable body created just above this line. `CENTRE` is still `Vector3(0, 1.12, 0)`. The three components are X, Y and Z; here they place the body relative to its station.

Replace only this assignment with:

```gdscript
held.position = CENTRE + Vector3(0, 0.5, 0)
```

Adding two vectors adds their corresponding components. X and Z stay unchanged; Y becomes `1.62`. The same black point starts half a metre higher. Its surface and collider move together because both belong to the held body. The station's label stays put.

Restore `held.position = CENTRE`. We changed where this body begins, without changing the shared constant or the earlier white points.

## Give the movement three directions

Carry the point towards the frame in the L-shaped basin. Move along one arm, then another. Pink marks X, grey marks Y, black marks Z. The black arm is labelled **−Z**: moving along it away from the origin decreases the local Z value.

Watch the LOCAL card. Lifting the point changes Y; moving sideways changes X or Z. Your hand will rarely change only one component. The frame gives those movements directions we can distinguish.

The two cards follow this same point. WORLD reports its position in the museum's world coordinates. LOCAL reports it relative to the coloured frame.

## The same place, another address

Open `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd`. Within `_process()`, the script reads the point in two ways. These lines already exist at separate places in that function:

```gdscript
var world_p: Vector3 = pt.global_position
```

```gdscript
var lp: Vector3 = to_local(pt.global_position)
```

`pt` is the reference to the held point, found by the supplied reporting connection. `: Vector3` states the variable's type explicitly. `world_p` keeps its world position. `to_local(...)` expresses that position relative to the node running this script: the coloured frame. `lp` keeps the result.

The conversion includes the frame's position, orientation and scale. This frame is scaled by `1.5`, so one local unit spans 1.5 metres in the hall. Its LOCAL numbers are not simply WORLD numbers with another starting zero.

The earlier `held.position` belongs to the held body's parent. That parent and this coloured frame are different nodes. Whenever we say “local”, we need to say local to what.

Point Zero introduced `_process()`. Here it repeatedly reads a position that the pickup system changes. We can follow the movement without writing the hold again.

## How much can the card say?

Open `commons/primitives/point/coordinate_readout.gd`. In `show_coordinates()`, find:

```gdscript
t = "x = %.2f\ny = %.2f\nz = %.2f" % [p.x, p.y, p.z]
```

`p` is the position received by this card. `p.x`, `p.y` and `p.z` select its components. Each `%.2f` prints one number with two decimal places; `\n` starts another line. The formatting fills the three places in order.

Change the three occurrences of `%.2f` on this line to `%.3f`. Both cards now show another decimal place. A movement too small to alter the old display can become visible in the numbers.

The edit changes the report, not the position or the accuracy of your tracked hand. Restore `%.2f` when finished.

We can now place a body, carry it and name the reference for its address. Point Lines will relate two positions: how far apart they are, and what can join them.
