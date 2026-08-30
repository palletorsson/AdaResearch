# What a Vector Is

Four facts make a vector, and none of them is a place. Before any of them, three axes and an origin must already exist.

Read a point's address off the frame.

```gdscript
func project_onto_axes(p: Vector3) -> Array[Vector3]:
    return [
        Vector3(p.x, 0.0, 0.0),
        Vector3(0.0, p.y, 0.0),
        Vector3(0.0, 0.0, p.z),
    ]
```

Three markers ride the three axes. A coordinate is not a property of the point — it is where the point's shadow lands on a frame someone else chose.

Build the arrow as a difference, not a position.

```gdscript
func get_vector(start: Node3D, end: Node3D) -> Vector3:
    return end.global_position - start.global_position
```

The vector is what separates the two handles. Grab either one and it changes; grab both and it does not.

Slide the whole arrow across the room.

```gdscript
func slide(arrow: Node3D, offset: Vector3) -> void:
    arrow.global_position += offset
```

Same direction, same length, same vector. The subtraction above returns an identical Vector3 afterwards. A vector is a journey with no starting address.

Take it apart into three legs that chain to its tip.

```gdscript
func component_legs(v: Vector3) -> Array[Vector3]:
    var x_end := Vector3(v.x, 0.0, 0.0)
    var z_end := Vector3(v.x, 0.0, v.z)
    return [x_end, z_end, v]
```

x along the floor, then z across it, then y rising. Tip to tail, three legs arrive exactly where the one arrow arrived.

Measure how far it would carry you.

```gdscript
func magnitude(v: Vector3) -> float:
    var floor_diagonal := sqrt(v.x * v.x + v.z * v.z)
    return sqrt(floor_diagonal * floor_diagonal + v.y * v.y)
```

Two Pythagoras theorems stacked: one on the floor, one rising to meet it. `v.length()` returns the same float in a single call and hides the nesting.

Change what "far" means.

```gdscript
func magnitude_under(v: Vector3, norm: String) -> float:
    if norm == "taxicab":
        return absf(v.x) + absf(v.y) + absf(v.z)
    if norm == "chebyshev":
        return maxf(absf(v.x), maxf(absf(v.y), absf(v.z)))
    return v.length()
```

Euclidean is the diagonal, taxicab is the walk along the legs, chebyshev is the longest leg alone. The arrow never moves; the ruler does.

Divide the vector by its own length.

```gdscript
func unit(v: Vector3) -> Vector3:
    var m := v.length()
    if m < 0.001:
        return Vector3.ZERO
    return v / m
```

Keep the which-way, refuse the how-far. Every direction in the room lands somewhere on one sphere of radius 1.

Flag the vector that has no direction to keep.

```gdscript
func is_degenerate(v: Vector3, threshold: float = 0.18) -> bool:
    return v.length() < threshold
```

Zero has a magnitude but no direction. Normalising it divides by zero, so the machine turns red rather than lie about which way it points.

You can now read a position against a frame, hold a vector as a difference between two handles, move it without changing it, split it into components, measure it under three different rulers, and strip its length away to leave pure direction. Nothing here was added to anything else. Act II is where vectors first act on each other.
