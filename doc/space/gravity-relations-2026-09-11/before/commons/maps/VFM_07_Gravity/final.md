Attraction at a distance, and then what happens when more than two things believe in it.

This is a bench, not a walk: two plinth rows in a south gallery and a north row of larger machines, every one of them the same law. You met the law in the park as one machine among five. Here it is on its own, and the room takes it from two bodies to three, which is where the arithmetic stops being able to tell you the future.

## The law

```gdscript
func attract(a: Body, b: Body, G: float) -> Vector3:
    var arm := a.position - b.position
    var d := clamp(arm.length(), 1.0, 25.0)
    var strength := G * a.mass * b.mass / (d * d)
    return arm.normalized() * strength
```

<!-- @exercise_1_8_solution_attraction_magnitude_vr -->

A ball orbits a mass you can take hold of. Drag the mass and the orbit reshapes under your hand. The force runs along the line between them, and its strength is the product of the two masses divided by the distance *squared*. Read what the square costs: double the distance and you keep a quarter of the pull. Double it again and you keep a sixteenth. Closer means stronger, and not politely.

<!-- @example_2_8_two_body_attraction_vr -->

Two bodies, and the clamp in the code is worth a look. Without it a close encounter divides by nearly nothing and the numbers explode. That is not a fault in the law. It is the law taken further than a simulation can follow, and the clamp is honest engineering: it says where the machine stops trusting itself.

<!-- @ -->

## Falling and missing

```gdscript
# a stable orbit: sideways velocity exactly countering the fall
body.velocity = tangent * sqrt(G * central_mass / radius)
```

<!-- @orbit_pair -->

Two bodies orbiting a point that belongs to neither, the barycenter, each pulled toward the other by an arrow of exactly the same length. You stood on that point in the park. Here you can watch the trick of every moon from outside: it falls forever and forever misses, because its sideways speed exactly counters the fall, and there is one speed at every distance that does that.

<!-- @orbital_mechanics_demo -->

Launch a satellite and set that sideways speed yourself. Too slow and it spirals in. Too fast and it leaves and does not come back. The orbit that never returns has a number, and it is not far above the circular one: the square root of two times it. Go by increments and you will find it. Between the two, every ellipse Kepler drew, and beyond it, the hyperbola that is a visit rather than a stay.

<!-- @ -->

## Three

```gdscript
for i in bodies.size():
    for j in bodies.size():
        if i != j:
            bodies[i].acceleration += attract_accel(bodies[j], bodies[i])
```

Every body attracts every body. With two, the futures are circles and ellipses, and a formula will tell you where either body is at any time you name.

<!-- @three_body_problem -->

With three, stand at the three-body problem and watch prediction die.

There is no formula for where three bodies will be. There is a series, a century old, that converges so slowly it is useless for anything, and so in practice there is only simulation: step the law forward and see. And here is the part the machine can prove to you. Nudge one body by a millionth of a metre and run both versions. With two bodies the difference stays a few millionths. With three it grows to metres, half a million times as far, and then the two futures have nothing to do with each other. Same law, same code. Restart it three times and find what was different: the initial conditions are the third body's secret.

Two famous exceptions stand in this station's settings, the figure-eight and the Lagrange triangle, orbits so balanced that three bodies do repeat. They are exceptions, and they were found by searching, not by solving.

<!-- @chaos_attractor -->

The shape of that unpredictability, drawn. This is a different system, the one Lorenz found in the weather, but it has the same property, and eight thousand points of it trace the butterfly: a path that never repeats and never leaves. Chaos is not randomness. It is a law followed exactly, by a future that cannot be known in advance.

<!-- @ -->

## Many

<!-- @example_2_9_n_body_attraction_vr -->

More than three, and the law does not change; only the count does. Every body pulls on every other, which is a pair of forces for every pair of bodies.

<!-- @nbody_simulation -->

Twenty bodies from a cloud, and watch what the law does with them: a disc forms, a binary pair, a cluster that scatters. Nothing organises them. The pairwise pull does, and the cost of computing it is the number of pairs, which grows as the square of the count. That square is the bottleneck that drove astronomers to invent the tree methods that made galaxies simulable, and it is the same square as the law's own. Gravity is expensive in exactly the way it is strong.

<!-- @ -->

## The well

```gdscript
func well_depth(pos: Vector3, center: Vector3) -> float:
    return -G_well / max((pos - center).length(), 0.5)
```

<!-- @gravity_well -->

The rubber sheet, made real. A grid warps around a mass you can move, and coloured particles roll along the curve: orbiting, spiralling in, escaping, depending on how fast they arrive. The depth is not decoration. It is the energy a thing would need to climb out, drawn as geometry, and deeper always means closer in. This is the picture everyone reaches for when they explain gravity, and it is worth knowing that it is a picture of a *potential*, not of a force: the slope is the force, and the height is what the slope has cost you.

<!-- @ -->

## Gravity's office job

```gdscript
# force-directed layout: edges are springs, nodes repel like masses
for pair in node_pairs:
    apply(repulsion(pair))   # gravity's mirror
for edge in edges:
    apply(spring(edge))      # last room's force law
```

<!-- @forcedirected3d -->

A graph laying itself out. Every node repels every other by the inverse square, gravity's mirror, and every edge is a spring from the last hall pulling connected nodes together. Nobody arranges it. The two forces argue until they agree, and the arrangement is the equilibrium: the picture of the graph that costs the least.

<!-- @grid3d_force_directed -->

The same, on a grid, watching it settle. This is the sequence eating its own tail: attraction and springs, repurposed from physics into layout, so that a diagram can find its own shape. Graph theory is eleven chapters ahead, and it starts here, in a room about planets.

<!-- @ -->

## What three bodies cost

Two bodies and a formula. Three bodies and a simulation, which is the machine inventing the between, one step at a time, with no formula to check it against, because there is none. That is a strange place for a physics room to end, and it is the honest one: the law is exact, the future is not, and the difference between them is the number of things that believe in it.

The next bench takes one law you know, legs, and asks what a gait is once you know how many feet are on the ground.
