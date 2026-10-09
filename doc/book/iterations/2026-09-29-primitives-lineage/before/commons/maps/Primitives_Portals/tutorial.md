# Primitives Portals

The number goes up, and the circle does not arrive.

Draw a circle the only way the machine can.

```gdscript
func polygon_perimeter(n: int, r: float) -> float:
    var total := 0.0
    for i in n:
        var a := Vector2.RIGHT.rotated(TAU * i / n) * r
        var b := Vector2.RIGHT.rotated(TAU * (i + 1) / n) * r
        total += a.distance_to(b)
    return total
```

n points evenly round, joined by n straight edges. That is every ring, torus and portal in this hall.

Measure what is missing.

```gdscript
func gap_to_circle(n: int, r: float) -> float:
    return TAU * r - polygon_perimeter(n, r)
```

The true circumference is TAU times the radius. The polygon's is always less, and the gap is positive for every n you can name. Archimedes doubled from a hexagon to a 96-gon and boxed the ratio between 3.1408 and 3.1429. The 96-gon gives 3.1410. It is close. It is not there, and no finite doubling gets there.

Walk toward the far end the way Achilles does.

```gdscript
func achilles(steps: int) -> float:
    # each step covers half of what remains of one unit of track
    var covered := 0.0
    for i in steps:
        covered += (1.0 - covered) * 0.5
    return covered
```

Ten steps cover 0.999 of the track. A hundred would cover more. In mathematics no number of steps covers all of it, because every step leaves half of what was left. Run the code and watch what the machine does instead: at fifty-four steps `covered` becomes exactly `1.0`, because the remaining half is smaller than a float can hold next to one. The last number a float can hold below one is one minus two to the fifty-third, and the next halving rounds away. The machine arrives. It arrives by running out of digits, and that arrival is exactly as honest as the sphere in the last room.

Count a surface with a hole in it.

```gdscript
func torus_counts(rings: int, segments: int) -> Dictionary:
    # a torus mesh of rings x segments quads
    var v := rings * segments
    var f := rings * segments
    var e := 2 * rings * segments
    return {"vertices": v, "edges": e, "faces": f, "euler": v - e + f}
```

For every closed solid so far, vertices minus edges plus faces was two. For a torus it is zero, at any resolution. The hole is not a feature of the surface; it is a change in the number the surface cannot help giving you.

Cross a portal.

```gdscript
func through_portal(entry: Transform3D, exit: Transform3D, velocity: Vector3) -> Vector3:
    var turn := exit.basis * entry.basis.inverse()
    return turn * velocity
```

A portal does not cover the distance between its two mouths. It changes the frame: whatever direction you carried in is rotated by the difference between the mouths and handed back at the same speed. Crossing is a transformation, not a transport.

You can now draw the machine's circle and measure how far it falls short, watch a halving sequence fail to arrive in mathematics and arrive in a float, count the hole in a torus, and cross a portal by rotating a frame. Primitives_Melencolia will next stand inside the limit and not reach it either.
