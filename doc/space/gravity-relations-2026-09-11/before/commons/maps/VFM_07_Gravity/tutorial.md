# Gravity Lab

Attraction at a distance. Newton's law of universal gravitation, then what happens when more than two things believe in it.

Write the attraction.

```gdscript
func attract(a: Body, b: Body, G: float) -> Vector3:
    var arm := a.position - b.position
    var d := clamp(arm.length(), 1.0, 25.0)
    var strength := G * a.mass * b.mass / (d * d)
    return arm.normalized() * strength
```

NoC example 2.8's heart: force along the line between them, divided by distance squared. The clamp is honest engineering — without it, close encounters explode.

Check the magnitude curve.

```gdscript
# d=1 → strength = G·m·m
# d=2 → a quarter of that
# d=4 → a sixteenth
```

Exercise 1.8 made walkable: the attraction magnitude station plots the inverse square. Double the distance costs you three quarters of the force.

Orbit the pair.

```gdscript
# a stable orbit: sideways velocity exactly countering the fall
body.velocity = tangent * sqrt(G * central_mass / radius)
```

The orbit pair shows the trick of every moon: it falls forever and forever misses. The orbital mechanics demo lets you set the sideways speed yourself — too slow spirals in, too fast escapes.

Add a third body.

```gdscript
for i in bodies.size():
    for j in bodies.size():
        if i != j:
            bodies[i].acceleration += attract_accel(bodies[j], bodies[i])
```

NoC example 2.9: every body attracts every body. With two, the futures are circles and ellipses. With three — stand at the three-body problem and watch prediction die. No formula exists; only simulation.

Fall into the gravity well.

```gdscript
func well_depth(pos: Vector3, center: Vector3) -> float:
    return -G_well / max((pos - center).length(), 0.5)
```

The well renders potential as geometry: depth is energy you'd need to climb out.

Let gravity lay out a graph.

```gdscript
# force-directed layout: edges are springs, nodes repel like masses
for pair in node_pairs:
    apply(repulsion(pair))   # gravity's mirror
for edge in edges:
    apply(spring(edge))      # last room's force law
```

The force-directed structures are this sequence eating its own tail: attraction and springs, repurposed from physics into layout. Graph theory, eleven sequences ahead, starts here.

> Try: at the three-body problem, restart it three times. Same law, same code — find what was different. (Initial conditions are the third body's secret.)

> Try: at the orbital demo, find the escape velocity by increments. The orbit that never returns has a number.

Next: the Arena — everything in this sequence, armed and colliding.
