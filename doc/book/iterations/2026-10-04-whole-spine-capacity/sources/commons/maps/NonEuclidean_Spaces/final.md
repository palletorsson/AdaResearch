# Curvature as Choice

The triangle has followed us. Three corners again, but this time the number underneath is waiting on the shape.

<!-- @triangle_curvature_workbench -->

Start with PLANE at the bench near the entrance. Follow each yellow edge with your eye. Before moving the slider, predict what will happen to the angle sum when the triangle sits on a sphere. More than 180°? Less? The same, because it is still a triangle?

Move to SPHERE. The edges take the short great-circle routes between their endpoints. Look at a corner: each incoming direction has to be read on the sphere, where the corner lives. The total rises. Move back to PLANE. It returns to 180°.

Now try DISK. The triangle lies inside a circle; its sides curve towards the centre. Its angles add to less than 180°. The disk looks flat. That is already a complication worth staying with.

## What counts as straight here?

In the previous room, bowing an edge changed a picture. Here each model specifies which paths count as straight within it. These are *geodesics*: locally shortest paths, measured using that space's own distances. On the plane they are straight segments. On the sphere they follow great circles. In the Poincaré disk they follow diameters or circular arcs that would meet the boundary at right angles.

The curved arc in the disk is not a detour through its geometry. It is the direct route. Your eye is looking from the surrounding Euclidean room, using a different account of distance.

There are three settings, not a continuous dial for the curvature of the whole museum. Each rebuilds its own example triangle. We are comparing hosts; we have not carried an unchanged triangle between them.

```gdscript
# triangle_curvature_workbench.gd — the angle at corner v between edges to u and w
return acos(clampf(_edge_tangent(v, u).dot(_edge_tangent(v, w)), -1.0, 1.0))
```

The tangents are unit directions. Their dot product tells us the cosine of the angle between them. Do this at all three corners and add the results. On a sphere the directions lie in the corner's tangent plane; the disk model preserves angles, so we can measure them in its drawing.

The earlier triangle printed three sixties. This bench has to ask its edges. A small difference in how a number arrives can open a large difference in what we are able to question.

## What the corners can tell us

For a geodesic triangle bounding a disk-like patch of a smooth surface, Gauss–Bonnet relates the angle sum to the curvature enclosed: in radians, the sum minus π equals the integral of Gaussian curvature over that patch. With constant curvature this becomes curvature times area. The plane gives zero; the spherical example gives an excess; the hyperbolic example a deficit.[^1]

The bench measures the angles. It does not independently measure that integral, and one changing display is not a proof of the theorem. What it offers is an encounter with the question: what did our familiar 180° depend on?

Flatness has become one of the available answers. You can return to it, but it no longer arrives alone.

## The surfaces at the far end

<!-- @hyperbolic_surface -->
<!-- @elliptic_surface -->
<!-- @curvature_slider -->

A saddle, a dome, and another slider keep the comparison open. Their surfaces are useful things to look around: how does a curve present itself from above, then from the side? Where does the drawing suggest a route for your body?

The saddle is built from `y = a * (x*x - z*z)`. The coefficient controls its bend; it is not the Gaussian curvature at every point. A dome-like graph is not automatically a sphere either. Similar silhouettes can conceal different measurements. We met that danger with noise: a convincing appearance can satisfy the first desire to understand, then stand in the way of the next question.

The separate curvature slider changes its own surface sketch. It does not command all the other exhibits. Try it, then look across the room. The fixed studies remain fixed. For the measured three-way comparison, return to the bench with HOST on its control. The distinction matters because an available gesture can promise more authority than it has been given.

## A boundary you can see and cannot reach

<!-- @poincare_disk -->

Look towards the rim of the Poincaré disk. In its hyperbolic metric the distance to that boundary is infinite, although its Euclidean drawing fits inside a finite circle. A step of the same hyperbolic length occupies less and less of the drawing as it approaches the rim. The representation can keep a world close to your hand while its own distances keep the edge away.

<!-- @riemann_sphere -->

The Riemann sphere offers a different operation. Stereographic projection puts the complex plane on a sphere with one point missing; adding a point at infinity completes it. The disk's entire boundary and this added point are not the same kind of outside. One remains infinitely far away in the model's metric; the other belongs to a compactified space.

You can walk around the displayed sphere. You are walking in the museum, not around the infinity of the complex plane. Still, something has happened: an operation we could only name now has a surface we can approach. The gain is real, and so is the difference between the two journeys.

## What the control cannot decide

Mathematics lets us specify different geometries. Which geometry models a physical situation is a further question, answered with measurements and assumptions; a slider cannot settle it. Nor does one curvature value specify every possible space.

Here the question is close enough to touch. When we change the host, what must a line do to remain straight? What have we kept, and what have we quietly replaced?

The next hall moves from a rule for space to a rule for membership. It asks what happens when we try to collect all the sets that do not contain themselves. Choosing the rule will no longer be enough to make its promised collection possible.

For now, return the slider to PLANE. The floor has not moved. Your account of it has.

[^1]: See Mark Powell, [*Differential Geometry*, chapter 6: Gauss–Bonnet, Corollary 7.2](https://www.maths.gla.ac.uk/~mpowell/M435-chapter-6-gauss-bonnet.pdf). Angles in the equation are radians; the exhibit displays degrees. For the disk's geodesics and angle-preserving representation, see Cornell's [*Geometries of Surfaces*](https://pi.math.cornell.edu/~mec/Winter2009/Victor/part4.htm).
