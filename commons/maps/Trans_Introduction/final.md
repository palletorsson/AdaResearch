A transformation is defined by what it refuses to change.

Melencolia left you with a solid that would not move. This is the room where the primitives finally do, and there are exactly three ways they can: a thing can go somewhere else, it can turn, or it can grow. The chapter's whole question is asked in the first hall and answered in the last: when everything changes, what stays the same? Each of the three moves has a different answer, and each is named for the one thing it gives up.

## Three ways to close a gap

One lane runs the length of this hall and three pits are cut into it, and there is a different cube at each one. The cyan cube carries you across by going somewhere else: your position changes and nothing else does. The orange cube is a slab that turns a quarter circle about the upright, holds for four seconds and turns back. It does not tilt and it does not grow; the gap is bridged by facing differently. The green cube swells until there is no gap left to cross, holds while you walk over it, and shrinks away again. Same pit, three answers, and you will walk all three before the chapter is out.

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

A triangle with its measurements written on it: side lengths, angles, area. Press a button and watch which numbers survive. The ones that survive glow green, the ones that change glow red. Slide it and every number stays green. Turn it and every number stays green. Grow it and the angles stay green while the sides and the area go red. Shear it and all three angles go red, two of the sides go with them, and the base and the area hold. Each transformation has a signature, and the signature is what it cannot touch.

<!-- @x_translation_cube -->

Three cubes stand apart in this hall, each allowed one axis. This one slides sideways, on a rail, with four fading ghosts behind it and its one coordinate counting on a label.

<!-- @y_translation_cube -->

This one lifts. The same operation, and the one that reads least like it.

<!-- @z_translation_cube -->

This one goes into the depth, where the same displacement reads almost entirely as getting bigger. Translation, taken apart, is three of these, and the room after next will forbid you two of them at a time to prove it.

<!-- @ -->

## Order

<!-- @spin -->

A row of copies that slides, then turns, then slides again. The turn is inserted in the middle of the process, and it changes the copies without changing where they go. The row stays straight, because every phase adds the same step along the same axis and only the basis is turned. Twelve copies tumble fifteen degrees each, and the last ten stand upside down and still in line.

<!-- @transform_composition -->

The same house twice: rotated then moved, in blue, and moved then rotated, in red. It lands in two different places, and the two matrices beside it are written out so you can see that the product is different when the factors change sides. Order matters here in a way it never did for adding.

<!-- @rotation_gimbal -->

Three rings, one inside the other, one per axis, driven by a pad of three sliders. Push the Y slider toward ninety degrees and the outer and inner rings come into line, and at that moment one of your three freedoms is gone: gimbal lock. It is the reason a rotation is better kept as a single turn about a single axis than as three angles, and the rest of the chapter keeps it that way.

<!-- @ -->

## One matrix

<!-- @homogeneous_coordinates -->

Why four by four for a three-dimensional world. The panel is colour-coded: the block of nine carries rotation and scale, the last column carries translation, and the bottom row is three zeros and a one. That extra row is the trick. It lets a move that is really an addition ride along with the moves that are multiplications, so that all three become one multiplication, and a chain of them is a chain of products.

<!-- @matrix_4x4_viewer -->

The same matrix, live. Sliders for the three translations, one rotation and a uniform scale, and a wireframe cube that obeys them while the sixteen numbers update in front of you. This is where the abstraction and the object are the same thing at the same time.

<!-- @ -->

## Moves with something at stake

<!-- @balance_puzzle -->

Eight pieces, and a line at forty centimetres. Stack them past it and hold every piece still for a second and a half, and the pile stops being a pile: the eight blocks gather and walk away as a creature. Every drop is a translation and a small rotation, and the test is not the moves. The test is whether the stack is still standing when you take your hands off it.

<!-- @scale_me -->

A sphere you can take hold of. Do, and the dark sphere across the hall swells ten times over two seconds. You are not carried with it. In the instant you close your hand, before anything has started to grow, your distance from the room's corner is doubled and your height set to five metres, so you arrive at the new view before the sphere does. It does not come back while you are here, and neither do you. Alice had a bottle for this.

<!-- @pick_up_cube -->

A black cube in orange wireframe, turning and bobbing on its own axis. You cannot carry it. Walk into it and it is gone with a rising chirp and one point on the score, so the translation the room counts here is yours and not the cube's.

<!-- @head_crab -->

A small black crab on four jointed legs, which finds you at fourteen metres and comes. Inside two metres it dashes. The bite takes a third of your health and puts you back at the door, so the one thing in this hall that moves itself is also the only one that can undo your walk.

<!-- @dark_sphere -->

This is the sphere the grab handle goes looking for. It turns slowly and its purple emission breathes, and otherwise it is only ever acted upon, which is what makes a tenfold change in it legible.

<!-- @ -->

## What stays the same

Here is the question in one sentence: what stays the same when everything changes? Translation keeps everything but position. Rotation keeps everything but direction. Scale keeps the angles and the proportions and gives up the sizes. Shear keeps the area and the side it stands on, and gives up the rest; it is the fourth button on the first panel in the hall, and the chapter does not give it a lane, which is a choice the panel quietly argues with. A transformation is a promise about what will not be touched, and the chapter is a walk through three promises and one that did not get a door.

The next hall is translation on its own, and its floor has holes in it.
