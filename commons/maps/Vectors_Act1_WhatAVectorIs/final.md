The question is on the wall before anything else is.

<!-- @3t -->

**WHAT IS A VECTOR, BEFORE IT IS ANY PARTICULAR ARROW?** The room asks it in capitals at the door and then refuses to answer it in words. It answers in four stations instead, walked in order, and the order is the definition: a where, a which-way, a how-far, and a how-far refused.

Nothing in this hall is added to anything. Nothing is multiplied. You are here to meet the object before anyone does anything to it.

<!-- @ -->

## A where

```gdscript
func project_onto_axes(p: Vector3) -> Array[Vector3]:
    return [
        Vector3(p.x, 0.0, 0.0),
        Vector3(0.0, p.y, 0.0),
        Vector3(0.0, 0.0, p.z),
    ]
```

Three axes and an origin have to exist before a single fact about a vector can be stated. Before the arrow, the frame.

<!-- @CoordinateSystem3M -->

You have stood in this frame before, in the first room of the first chapter, where it was the thing you were thrown into. Stand in it again and read your own address off it: three markers ride the three axes, and each is where your shadow lands when the light comes from one direction at a time.

A coordinate is not a property of you. It is a property of you *and the frame*, and the frame was chosen by somebody else. Move the axes and every address in the room changes while nobody in the room has moved. The first fact about a vector is that a *where* is not yet one.

<!-- @ -->

## A which-way, and a how-far

```gdscript
func get_vector(start: Node3D, end: Node3D) -> Vector3:
    return end.global_position - start.global_position
```

A subtraction. That is what a vector is made of: not a place but the difference between two, and the difference has thrown both places away in the making. Grab either handle and the vector changes. Grab both and carry them together, and it does not.

<!-- @VectorBasics -->

Take the tip and pull. Two facts survive whatever you do to it, and only two: the way it points, and how far it goes. Everything else about the arrow, where it sits, what it is near, which hand is holding it, is furniture.

```gdscript
func slide(arrow: Node3D, offset: Vector3) -> void:
    arrow.global_position += offset
```

Now slide the whole thing across the room. Same direction, same length, and the subtraction above returns an identical `Vector3` afterwards, to the last float. The arrow moved and the vector did not, because the vector was never *at* anywhere.

<!-- @route_vector -->

A from-pin, a to-pin, and one arrow between them, with a courier walking it to show that the trip is a single move. It is the sentence the whole room is built to say, and it says it once: **a vector is a journey with no starting address.**

Keep hold of how strange that is. Every journey you have ever taken began somewhere. This one keeps the going and discards the from, and it is more useful for it, because a going that belongs to no particular place can be reused in every place.

```gdscript
func component_legs(v: Vector3) -> Array[Vector3]:
    var x_end := Vector3(v.x, 0.0, 0.0)
    var z_end := Vector3(v.x, 0.0, v.z)
    return [x_end, z_end, v]
```

Take it apart and it stays one thing. Along the floor, then across it, then up: three legs laid tip to tail arrive exactly where the single arrow arrived. The room's three axes were never a cage. They were the three directions a journey can be told in.

<!-- @ -->

## How far

```gdscript
func magnitude(v: Vector3) -> float:
    var floor_diagonal := sqrt(v.x * v.x + v.z * v.z)
    return sqrt(floor_diagonal * floor_diagonal + v.y * v.y)
```

Two Pythagoras theorems, stacked. One lies flat on the floor and finds the diagonal of the x and the z. The second stands that diagonal up against the y and finds the diagonal of *that*. `v.length()` returns the same float in a single call and hides the nesting, which is fine until the day you need to know that "how far" was built out of two right angles.

<!-- @length_lantern -->

Stretch it and it brightens. The glow is the square root of x squared plus y squared plus z squared, and nothing else feeds it, so the lantern is a ruler that reports in light.

```gdscript
func magnitude_under(v: Vector3, norm: String) -> float:
    if norm == "taxicab":
        return absf(v.x) + absf(v.y) + absf(v.z)
    if norm == "chebyshev":
        return maxf(absf(v.x), maxf(absf(v.y), absf(v.z)))
    return v.length()
```

But read what the code allows. *Far* is a choice, and there are at least three. Euclidean is the diagonal, the way a crow goes. Taxicab is the walk along the legs, the way a body goes through a city with buildings in it. Chebyshev is the longest leg alone, the way a king moves on a board. The arrow never moves between these. The ruler does, and the same journey is three different distances depending on who is measuring.

The lantern here glows with the diagonal. It could be told otherwise. Two rooms ago, a ruler that altered what it did not measure; here, a ruler that is one of several and does not say so.

<!-- @ -->

## A how-far refused

```gdscript
func unit(v: Vector3) -> Vector3:
    var m := v.length()
    if m < 0.001:
        return Vector3.ZERO
    return v / m
```

Divide the vector by its own length. What is left has a length of exactly one and keeps nothing but the which-way, and every direction there is, in the whole room, lands somewhere on a single sphere of radius one. That sphere is where direction lives once distance has been sent away.

<!-- @vector_normalize_demo -->

Pull an arrow of any size and watch it snap to the sphere. Long or short, it lands on the same surface, and the only thing it brings with it is where on the surface it lands. This is the fourth fact, and it is a refusal: a vector can be asked to give up its how-far and it still has something to say.

```gdscript
func is_degenerate(v: Vector3, threshold: float = 0.18) -> bool:
    return v.length() < threshold
```

Except one. Zero has a magnitude, and it is zero, but it has no direction at all, and asking it for one is a division by zero. So the function hands back zero rather than lie about which way it points, and the demo has nowhere on its sphere to put it. That is worth more than it looks: a system that says *I cannot tell you* is rarer than one that tells you something wrong.

<!-- @ -->

## Four facts, one arrow

A where, which was not yet a vector. A which-way and a how-far, which are the whole of one. A how-far refused, which leaves direction alone on its sphere. Walked in order, they are a definition that no sentence could give you, because each fact was something you did with your hand before it was something you knew.

Nothing in this hall acted on anything else. The next one is where vectors first act on each other: to add is to walk, to dot is to agree, to cross is to turn. Carry the sentence in. *A vector is a journey with no starting address.* Everything that follows is what such journeys do when they meet.
