The last room kept turning the number down. This one turns it up, and walks toward what it ought to become.

The hall is long, and it is a tunnel of rings. The rings are tori, the first form in this chapter with a hole in it, and every one of them is drawn the only way the machine can draw anything round, out of straight sides. As you walk, the sides multiply. The circle is somewhere at the far end. You will not reach it, and the room is about why, and about what you do instead.

<!-- @capsule -->

The pill from the last room is at the door, closed, five-sided, exactly as it was. It is here so you can see what a hole does to a form. Everything you have held so far has been closed; the rings ahead are the first things you will pass *through*.

<!-- @ -->

## The number goes up

```gdscript
func polygon_perimeter(n: int, r: float) -> float:
    var total := 0.0
    for i in n:
        var a := Vector2.RIGHT.rotated(TAU * i / n) * r
        var b := Vector2.RIGHT.rotated(TAU * (i + 1) / n) * r
        total += a.distance_to(b)
    return total
```

<!-- @combine_portals -->

Twenty tori down the hall, and the first one is a triangle: three sides round, three rings through, the coarsest torus the engine will allow. Each portal after it has one more ring and two more sides than the one before, so by the twentieth you are walking through forty-one sides, and it looks, from a few metres, like a circle.

It is not one. Measure what is missing and you find it is never nothing.

```gdscript
func gap_to_circle(n: int, r: float) -> float:
    return TAU * r - polygon_perimeter(n, r)
```

Archimedes did this by hand. He started from a hexagon and doubled, twelve, twenty-four, forty-eight, ninety-six, and with ninety-six sides he boxed the number that a circle is between 3.1408 and 3.1429. Ninety-six sides give 3.1410. It is very close. It is not there, and no doubling you can name gets there, because the gap at every finite n is a positive number, smaller than the last one and larger than zero. A circle is a limit, and a limit is not a place. You can walk toward it down this hall for as long as the hall lasts and be nearer at every ring, and the ring you are standing in will still have a side count.

<!-- @ -->

## Achilles, and what the machine does instead

```gdscript
func achilles(steps: int) -> float:
    # each step covers half of what remains of one unit of track
    var covered := 0.0
    for i in steps:
        covered += (1.0 - covered) * 0.5
    return covered
```

<!-- @achilles_tortoise -->

Six metres of track, and the runner takes the distance in halves: half the way, then half of what is left, then half of that. Ten steps and he has covered all but a thousandth of it. He will never cover the last part, because every step leaves half of what it found, and the label at the far end says *limit* for that reason. Zeno said this to prove motion impossible. What it proves is that a finite distance can hold infinitely many steps, and that arrival is not one of them.

Then run the code, and watch the machine disagree.

At the fifty-fourth step, `covered` becomes exactly one. Not close to one: equal. The half that remained was smaller than a float can hold next to the number one, so it rounded away, and the runner arrived. The machine reaches the limit by running out of digits. That arrival is exactly as honest as the sphere in the last room, which was round because nobody counted its sides, and it is worth knowing that every *arrived* this machine will ever report to you is of that kind. Mathematics never gets there. Floats do, by forgetting.

<!-- @ -->

## A surface with a hole

```gdscript
func torus_counts(rings: int, segments: int) -> Dictionary:
    var v := rings * segments
    var f := rings * segments
    var e := 2 * rings * segments
    return {"vertices": v, "edges": e, "faces": f, "euler": v - e + f}
```

Two rooms ago every closed solid you counted gave two. Vertices minus edges plus faces, the tetrahedron and the cube and the twenty-sided one, two, every time, however many corners it spent its 720 on.

Count a torus. At three rings and three sides, at twenty-two and forty-one, at any resolution you like, the answer is zero. The hole is not something the surface has. It is a change in the number the surface cannot help giving you, and that number does not care how finely the ring is drawn. You can push the side count toward the circle forever and the torus stays a torus, with its zero, because the hole was never made of sides.

That is what a portal is, before it is anything magical: a surface whose count is zero, which you can walk through because of it.

<!-- @ -->

## Transformation, not transport

```gdscript
func through_portal(entry: Transform3D, exit: Transform3D, velocity: Vector3) -> Vector3:
    var turn := exit.basis * entry.basis.inverse()
    return turn * velocity
```

There is a way out of this hall, and it is not the far end. It is a portal, and read what a portal does. It does not cover the distance between its two mouths; Achilles would never finish that. It changes the frame. Whatever direction you were carrying in is turned by the difference between the mouths and handed back to you at the same speed, pointing somewhere else. You did not travel. You were re-described.

Crossing a boundary requires transformation, not mere transport. That is the room's sentence and it has been the museum's sentence since the trace room: what cannot be reached by adding more can sometimes be reached by changing what counts. The next chapter after this one is called transformation, and it begins there.

The next room is what it is like to stand inside the limit with every tool in your hands, and not reach it, and stay.
