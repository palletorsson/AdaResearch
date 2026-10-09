# Point One — A body in the light

<!-- @point_absent -->

The corridor begins with a label: “Point one”. Above it, nothing.

There is somewhere to look because the words have given you a place to look. The name arrives before its object. You can stand in front of it, lean closer, and pass your hand through the empty space.

Here is the point, but you cannot see it. We can keep its position in three numbers:[^point-one-code]

```gdscript
var point_position := Vector3(0.0, 1.12, 0.0)
```

We have given that position a name, `point_position`. The numbers locate a place. They draw nothing. In the next hall, we will take them apart.

A mathematical point has no extent.[^point-one-euclid] To let it appear in the room, we will have to give it something a point does not have: a surface.

<!-- @point_visible -->

Further along, the same label sits below a small white sphere. Now there is something to look around. Its curved surface holds a highlight; as you move, the highlight moves too.

Walk towards it. The sphere does not stop you. Your view can pass through its surface and come out the other side. You have crossed something you could see.

We have given the position a surface for the light to meet. Make the sphere larger and more of the room disappears behind it. Its centre can stay exactly where it was. Drawing this body has still given it no power to stop you.

<!-- @point_solid -->

The next white sphere has the same size and finish. It says “Point one” too. Try the same approach.

This time a collision body occupies the place the surface describes. Your movement meets a limit. The difference was invisible until you tried to cross it. Two objects can look alike and permit different lives around them.

Its visible surface and its physical boundary are made separately. We have given them the same size and position. They could have been arranged otherwise. Make only the boundary larger, and your approach would stop before you reached the sphere. The empty space would resist you.

<!-- @point_sun_switch -->

## First there was light

First there was light, right? Look at the crooked shadows under the white spheres. Round bodies leave stretched marks on the floor. Something outside the shape has helped to draw them.

There is a switch on the wall. Turn it.

You have removed their sun.

The long shadows disappear. The spheres remain, faintly lit. Try approaching the solid one again. Its boundary has not gone with its shadow. What helped you see the body was never what stopped your body.

Here the sun is a direction from which light arrives. We did not have to build a burning star. A few instructions gave the room a familiar consequence, and familiarity let the source go unquestioned. The switch puts that borrowed certainty within reach.

Turn it back. A shadow returns to the same place. It makes the sphere easier to locate, but it is not another point beneath the first one. It belongs to a relation between a surface, a light and somewhere for the light to be interrupted.

<!-- @point_pedestal -->

## The size of a point

Before leaving, you meet a white sphere on a pedestal. It is 1.3 metres across. The text still says “Point one”.

The small sphere let you approach its centre. This one asks you to walk around it. A change in size has changed how much of the room you can see, and where your body can go. Its centre can still be written with three numbers. The same short address leaves a great deal unsaid.

Look from the small white spheres to the sphere on the pedestal. We have given each a body and called each a point. Neither has to stop being interesting once we know the difference.

In the next room, the point can leave its place with your hand. Now we can ask where it has gone.

[^point-one-code]: The position is drawn from the station's construction in `point_condition.gd`. The absent station creates no hidden sphere. The separate tutorial keeps a position, adds a visible surface and compares it with a collision boundary. Reading the three components and using pickup belong to the next hall, Point Coordinates.

[^point-one-euclid]: Euclid, [*Elements*, Book I, Definition 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/defI1.html), defines a point as that which has no part. This is a historical starting point for the abstraction, not a specification of a Godot object. A stored position, a visible marker and a collision body require different constructions; the invisible point lets us keep them apart.

