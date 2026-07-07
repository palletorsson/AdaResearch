# Vector Foundations Lab

The examples hall for Nature of Code chapter 1. A vector is a difference between two points — everything else in this room is arithmetic on that idea.

Stand at the origin of the coordinate frame.

```gdscript
var origin := Vector3.ZERO
var here := player.global_position
var to_you := here - origin  # you ARE a vector from the origin
```

The big coordinate system makes the frame walkable. Your position is three coefficients you can read off the rails.

Switch the coordinate system and watch nothing move.

```gdscript
func to_local_frame(v: Vector3, frame: Basis) -> Vector3:
    return frame.inverse() * v
```

The switcher re-describes every arrow in a different basis. The world stays put; only the numbers change. The vector is the thing, not its coordinates.

Add at the addition table.

```gdscript
var sum := a + b           # (a.x+b.x, a.y+b.y, a.z+b.z)
```

Subtract at the subtraction table.

```gdscript
var between := target - source   # the arrow FROM source TO target
```

Multiply by a scalar at the stretch bench.

```gdscript
var doubled := v * 2.0
var reversed := v * -1.0
```

NoC example 1.4, in your hands: scaling stretches or flips, never turns.

Measure at the magnitude demo.

```gdscript
var length := v.length()   # sqrt(x² + y² + z²)
```

Normalize at the normalize demo.

```gdscript
var direction := v.normalized()   # same heading, length 1
```

Magnitude and direction are the vector's two halves. Normalizing keeps the heading and gives the length away.

Read Newton's three laws on the wall.

```gdscript
# 1. velocity persists unless forced
# 2. acceleration = force / mass
# 3. every force has a mirror
```

They hang here, ahead of the forces rooms, because every law is a sentence about vectors.

> Try: at the stretch bench, find the scalar that turns the display vector into a unit vector. You have just done by hand what `normalized()` does.

> Try: walk from the add table to the subtract table. The vector you walked is the difference of the two table positions — compute it at the board.

Next: Operations. Two new products — dot and cross — that take vectors in and give back alignment and perpendicularity.
