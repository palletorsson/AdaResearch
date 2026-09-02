There is no size, only size relative to something else: scaling the object and scaling yourself are one operation seen from two sides, and proportion is what survives it.

Translation changed position. Rotation changed direction. Scale is the last freedom in the matrix, and it is the strange one, because it is the only transformation you cannot see from inside. Double everything, including your ruler, and nothing has happened. Size is not a property a thing has. It is a comparison, and this hall is a room full of things to compare.

```gdscript
func volume_ratio(before: Vector3, after: Vector3) -> float:
    return (after.x * after.y * after.z) / (before.x * before.y * before.z)
```

Double every length and the volume goes up eight times. That is the one place scale is not gentle: lengths scale as the factor, areas as its square, volumes as its cube, and the world is full of things that break when their weight grows eight times faster than their bones.

## Scale me

<!-- @scale_me -->

A sphere that asks to be held. Take it, and the dark sphere across the hall grows a hundred times over five seconds, from something you could carry to something the size of the building, while you are lifted five metres and carried outward with it. Twenty seconds later it shrinks back over five, and so do you. Every proportion of the sphere is kept exactly. What has changed is the comparison, and that is enough to make the same hall intimate, then monumental, without a wall moving. Alice ate a cake and drank from a bottle for this. Scaling the thing up and scaling yourself down are indistinguishable from where you stand, because from where you stand is the only place you can stand.

<!-- @prism_block -->

<!-- @cube_scene -->

Seven triangular prisms and three cubes, laid out in a row like a scale bar, all the same family and all at one size. They are the comparison. Without them the hall is a room; with them it is a room of a known size, and when the sphere changes you, it is against these that you know it. The prisms are here because a cube is too symmetrical to show the difference: turn a prism or grow it and a different face dominates, so aspect and orientation are readable in a way a box hides.

<!-- @chair_assembly_puzzle -->

Parts of a chair at a third of their size, and ghost guides showing where each should go. Move, turn and scale the parts into the ghosts, and when the last one aligns the whole chair grows to full size in a second and a half. The lesson is that a chair is not a special primitive. It is a relationship between transformed rectangles, and the relationship is what makes it a chair at any size.

<!-- @clipboard -->

A document you have to hold to read, with the scale controls on it. Reading it is an interaction, and the controls put the transformation in your hand.

<!-- @science_screen -->

The screen projects what stands near it into a flat diagram, every thing reduced to its outline on a plane. Take the sphere and watch the sphere's outline leave the frame while the prisms stay where they were: the diagram measures each thing against its neighbours, and it was never measuring you.

<!-- @dark_sphere -->

The dark sphere, at its one size. When you have changed, it is the thing that has not.

<!-- @ -->

## What survives

Every transformation in this chapter was a promise about what would not be touched. Scale's promise is proportion: every ratio in the room is kept, every angle is kept, and every size is given up. That is why it is the transformation that most directly shows what invariance means. When your body is the thing being scaled, what you notice is not that anything got bigger. It is that everything is still the same shape, and that "bigger" was never in the shapes at all.

That is the chapter's question answered three times. Position, direction, size: each move gives one of them up and keeps the rest. What stays the same when everything changes is whatever the move refused to touch, and the refusing is the move.

Next: the three moves from inside, where each one is a way of being removed.
