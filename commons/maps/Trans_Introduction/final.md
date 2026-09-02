A transformation is defined by what it refuses to change.

Melencolia left you with a solid that would not move. This is the room where the primitives finally do, and there are exactly three ways they can: a thing can go somewhere else, it can turn, or it can grow. The chapter's whole question is asked in the first hall and answered in the last: when everything changes, what stays the same? Each of the three moves has a different answer, and that answer is its name.

## Three ways to close a gap

Three lanes leave this hall, one per move, and each is a cube. The cyan cube carries you across a gap by going somewhere else: position changes, nothing else does. The orange cube turns a floor into a ramp: the gap is bridged by facing differently, not by moving. The green cube grows into the gap until there is no gap: it is not crossed, it is filled. Same gap, three answers, and you will walk all three before the chapter is out.

```gdscript
func srt(position: Vector3, rotation_rad: Vector3, scale_factors: Vector3) -> Transform3D:
    var t := Transform3D.IDENTITY
    t = t.scaled(scale_factors)
    t = t.rotated(Vector3.UP, rotation_rad.y)
    t = t.rotated(Vector3.RIGHT, rotation_rad.x)
    t = t.rotated(Vector3.FORWARD, rotation_rad.z)
    t.origin = position
    return t
```

Scale, then rotate, then translate. The order is not a convention. Do it in another order and the same three numbers land the same point somewhere else, and the machine can show you exactly where.

## What each refuses

<!-- @invariants_demo -->

A triangle with its measurements written on it: side lengths, angles, area. Put it through a move and watch which numbers survive. The ones that survive glow green, the ones that change glow red. Slide it and every number stays green. Turn it and every number stays green. Grow it and the angles stay green while the sides and the area go red. Shear it and the sides and the angles go red and only the area holds. Each transformation has a signature, and the signature is what it cannot touch.

<!-- @x_translation_cube -->

<!-- @y_translation_cube -->

<!-- @z_translation_cube -->

Three cubes, each allowed one axis. One slides sideways, one lifts, one goes into the depth, and each leaves ghosts and a label so you can see that one coordinate changes while the other two hold. Translation, taken apart, is three of these, and the room after next will forbid you two of them at a time to prove it.

<!-- @spin -->

A row of copies that slides, then turns, then slides again. The turn is inserted in the middle of the process, and because of that the second slide goes a different way. The form on the plinth is not spinning. It is the shape of an order of operations, and you can read the order off it.

<!-- @transform_composition -->

The same house twice: rotated then moved, in blue, and moved then rotated, in red. It lands in two different places, and the two matrices beside it are written out so you can see that the product is different when the factors change sides. Order matters here in a way it never did for adding.

<!-- @rotation_gimbal -->

Three rings, one inside the other, one per axis. Turn the middle ring toward ninety degrees and the outer and inner rings come into line, and at that moment one of your three freedoms is gone: gimbal lock. It is the reason a rotation is better kept as a single turn about a single axis than as three angles, and the rest of the chapter keeps it that way.

<!-- @ -->

## One matrix

<!-- @homogeneous_coordinates -->

Why four by four for a three-dimensional world. The panel is colour-coded: the block of nine carries rotation and scale, the last column carries translation, and the bottom row is three zeros and a one. That extra row is the trick. It lets a move that is really an addition ride along with the moves that are multiplications, so that all three become one multiplication, and a chain of them is a chain of products.

<!-- @matrix_4x4_viewer -->

The same matrix, live. Sliders for the three translations, one rotation and a uniform scale, and a wireframe cube that obeys them while the sixteen numbers update in front of you. This is where the abstraction and the object are the same thing at the same time.

<!-- @balance_puzzle -->

Eight pieces to stack until the pile stops moving. Every drop is a translation and a small rotation, but the pile does not care about the moves. It cares about whether the centre of mass still sits over something. Some transformations preserve a standing thing and some topple it, and this is the first place in the chapter where a transformation has a consequence you can lose.

<!-- @scale_me -->

A sphere you can take hold of. Do, and the dark sphere in this hall grows a hundred times over five seconds while you are lifted and carried outward with it, and then, twenty seconds on, it all comes back. Alice had a bottle for this. It is scale as something that happens to you, and it gets a hall of its own at the end.

<!-- @pick_up_cube -->

A cube that can be carried. Translation reduced to a portable primitive, and the sequence's small change: the next halls count how many you move.

<!-- @head_crab -->

Something in this hall walks on its own. A small black crab on four jointed legs, looking for you from a distance, and following. Every step it takes is a transformation applied to a body by that body, and it is here so that the moves in this room are not only things done to objects.

<!-- @dark_sphere -->

A dark sphere that does almost nothing. It changes so little that the changes around it become readable, which is a job.

<!-- @ -->

## What stays the same

Here is the question in one sentence: what stays the same when everything changes? Translation keeps everything but position. Rotation keeps everything but direction. Scale keeps the angles and the proportions and gives up the sizes. Shear keeps only the area, which is why it is not one of the three lanes. A transformation is a promise about what will not be touched, and the chapter is a walk through three promises.

Next: translation on its own, and a floor made of it.
