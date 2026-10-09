# Point One — A body for a position

<!-- @point_absent -->

The corridor begins with a label: “Point one”. Above it, nothing.

There is somewhere to look because the words have given you a place to look. The name arrives before its object. You can stand in front of it, lean closer, and pass your hand through the empty space.

Here is the point, but you cannot see it. We can keep its position in three numbers:[^point-one-code]

```gdscript
var point_position := Vector3(0.0, 1.12, 0.0)
```

The three numbers are X, Y and Z: here, 1.12 metres above this station's origin, with no shift along X or Z. We have given that position a name, `point_position`. The numbers locate a place. They draw nothing.

A mathematical point has no extent.[^point-one-euclid] To let it appear in the room, we will have to give it something a point does not have: a surface.

<!-- @point_visible -->

Further along, the same label sits below a small white sphere. Now there is something to look around. Its curved surface holds a highlight; as you move, the highlight moves too.

Walk towards it. The sphere does not stop you. Your view can pass through its surface and come out the other side. You have crossed something you could see.

We have given the position a surface for the light to meet. Make the sphere larger and more of the room disappears behind it. Its centre can stay exactly where it was. Drawing this body has still given it no power to stop you.

<!-- @point_solid -->

The next white sphere has the same size and finish. It says “Point one” too. Try the same approach.

This time a collision body occupies the place the surface describes. Your movement meets a limit. The difference was invisible until you tried to cross it. Two objects can look alike and permit different lives around them.

Its visible surface and its physical boundary are made separately. We have given them the same size and position. They could have been arranged otherwise. Make only the boundary larger, and your approach would stop before you reached the sphere. The empty space would resist you.

<!-- @point_held -->

At the fourth label the sphere is black. Take hold of it. The place you were looking towards can now leave with your hand.

Its visible size has not changed. While you hold it, its movement answers to yours. Put it down and look back at the label. “Point one” stays in the corridor; the point has gone elsewhere.

Which part did the name belong to? The position, the sphere, the possibility of taking hold?

Each station has a different address in the corridor, although its label repeats the same name. The three numbers we began with could never have told us whether the point would be white or black, resist a body or leave with a hand. We have had to give it each of those relations.

The corridor lets us encounter the decisions separately. In an ordinary object they arrive together, and we can forget that what appears solid has been given a separate reason to resist us.

Keep the black point. There are other ways to approach it in the wider room: arrows meeting at an empty centre, a screen unfolding the code, another point whose surface changes in your hand. We can return to them. For now, carry this one towards the coloured frame.

<!-- @coordinate_readout -->

## Two addresses

Keep the point in your hand and watch the white card as you move.

The corridor opens into the coordinate room. Its guides and the card follow the point you are already holding.

The card marked `WORLD` puts its position into another visible form. Move the point slightly while watching the card. A printed component may stay unchanged through a movement you can see.

The card rounds each component to two decimal places: `1.231` and `1.234` both appear as `1.23`. The stored position is left alone. Several nearby positions can share this shorter address. Your hand can move without the number changing. The apparent stillness belongs to the report.

Now compare it with the card marked `LOCAL`. Move the same point between two places. Both cards answer, but with different numbers. What would you need to know to read either address?

<!-- @CoordinateSystem3M -->

Follow the coloured frame's guides as you move the point in your hand. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

The two cards give the same point different addresses. `WORLD` measures from the scene's origin; `LOCAL` uses the coloured frame, including its position, orientation and scale. The point has not become two things. We have asked where it is from two different references.

A coordinate needs its reference. Reading more digits cannot supply one that has been left unnamed.[^point-one-haraway]

Carry the point beyond an arrow's end. The drawn axis has a length; the coordinate system can describe positions beyond it. A drawing made to explain movement could also become a limit on movement. Here the guides keep following your hand.

<!-- @drag_point_target -->

## Room to arrive

The red arrow says “drag point here”. Carry the point towards it without letting go, and watch what falls.

“Here” has become a request, and the request has a tolerance. The target accepts the point when it comes within 45 centimetres of its centre. It measures the gap between the two positions. A hand has room to arrive. “Here” has become a small region.

The target remembers whether the point is already inside. Staying there produces no further fall; leaving and returning allows another. A careful delivery and an accidental pass can bring the same rain. Your intention never enters this comparison.

Return again, and a destination can become an instrument. Come straight back once; next time, take a longer way round. The target accepts both arrivals, but you have changed the pause between them. Your detour has given the falling balls another rhythm.

<!-- @point_pedestal -->

## The size of a point

Before leaving, you meet a white sphere on a pedestal. It is 1.3 metres across. The text still says “Point one”.

The small sphere travelled in your hand. This one asks you to walk around it. A change in size has changed how much of the room you can see, and where your body can go. Its centre can still be written with three numbers. The same short address leaves a great deal unsaid.

Look from the sphere you carried to the sphere on the pedestal. We have given each a body and called each a point. Neither has to stop being interesting once we know the difference.

The next room brings two points into relation. A line begins.

[^point-one-code]: The position comes from the station's construction in `point_condition.gd`. The absent station creates no hidden sphere. The separate making passage follows this position into a visible body and a collision boundary, using the supplied Godot study.

[^point-one-euclid]: Euclid, [*Elements*, Book I, Definition 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/defI1.html), defines a point as that which has no part. This is a historical starting point for the abstraction, not a specification of a Godot object. A stored position, a visible marker and a collision body require different constructions; the invisible point lets us keep them apart.

[^point-one-haraway]: Donna Haraway, [“Situated Knowledges: The Science Question in Feminism and the Privilege of Partial Perspective”](https://doi.org/10.2307/3178066), *Feminist Studies* 14, no. 3 (1988), 575–599, especially 581–585. Haraway argues for embodied, situated and accountable knowledge, challenging both a view from nowhere and an easy relativism. This room asks a related question through its two coordinate readings: what must accompany a reading for someone else to understand its reference and limits?
