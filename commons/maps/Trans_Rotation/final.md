Rotation is the first operation where the order you do things in changes where you end up.

Translation left direction alone: space was the same in every direction and a move was a move. Rotation makes facing matter. Front is now different from back, left from right, and the sentence on the wall says it: rotation produces space as anisotropic. Every turning form in this hall carves an orientation into the void, and declares this way and not that way.

```gdscript
func euler_rotate(node: Node3D, euler: Vector3) -> void:
    node.rotate(Vector3.UP, euler.y)
    node.rotate(Vector3.RIGHT, euler.x)
    node.rotate(Vector3.FORWARD, euler.z)
```

Three turns about three axes, and the order is in the body, not the name: up first, then right, then forward. Turn about up and then about right, or about right and then about up, and the same two angles leave the thing facing two different ways. Adding never did this. Rotation in three dimensions does, and it is the first thing in the chapter that cannot be undone by doing the same steps backwards in the same order.

## Direction

<!-- @rotate_grid_cubes -->

Look down. The field of cubes in rows is the floor of this hall. The token has no geometry of its own; it reaches into the grid the room is built from and turns that. The rows turn to a score. Six tip about one axis, four stay flat, six about the next axis, four flat, six about the third, four flat, and then six that tip about all three at once, thirty-five degrees on two of the axes and twenty-five on the third. The score runs forty-four rows and the hall is forty long, so you meet it once and walk off the end of it before it can come round. The collision cubes turn with the picture, so a tilted band is tilted underfoot.

<!-- @science_screen -->

The screen is not looking at the room. It is running as a waveform instrument, and what it draws is a sine rolling across an axis grid with an angle read out beside it. That is a rotation seen sideways: take a point going round a circle, keep one of its two numbers and plot it against time, and this is the curve you get. The diagram is a loss on purpose, and the number it threw away is the one that tells you where the point is.

<!-- @furniture_turntable -->

A record deck, playing a crate at thirty-three and a third. Watch the needle. It never moves, and the platter turns under it, and the point where they meet holds one radius forever, tracing the circle that was hidden in the motion. Thirty-three homecomings a minute. This is the second thing rotation makes, after direction: it makes a form come back to itself.

<!-- @spin -->

Thirty-three small cubes in a straight line against a red bar, alternating black and white. The first eleven all lean the same way. Through the middle twelve each copy is turned fifteen degrees further than the last, a hundred and eighty in all, and the ten that follow keep the new lean. The row never bends. Every step is the same step; only the orientation it is carrying has changed, and that is what the order cost. Placed twice on their plinths, one of them yawed half round, and the difference is the claim: the turn inside the sequence changes what each copy is doing, and the turn applied to the finished row only changes which way the row is pointing. Same angle, two places to put it, two different objects.

<!-- @dark_sphere -->

A dark sphere with no front. It is turning the whole time you stand there, slowly, and nothing about it changes, which is why it is the reference: it is the one thing in the hall a rotation cannot get hold of.

<!-- @ -->

## Sameness of form

Turn a square a quarter of a turn and it is the same square, corner for corner. Turn it an eighth and it is not. The turns that change nothing are a form's symmetry, and they are the part of rotation this chapter cares about most: not where a thing ends up, but which turns bring it home. A circle comes home under every turn, which is why the needle can hold one radius forever. A square comes home under four. And this is not only a fact about shapes. When physics asks what a particle is, one of the answers is how many turns it takes to come home, and there are particles that need two. How many turns a thing needs is a number physics gives to every particle, and it calls that number spin. It is sameness of form, taken as far as it goes.

## What a turn does to a body

<!-- @catalyst_prompter_box -->

A floor hatch, one cell wide, whose lid slides open as you approach. A crystal rises from the recess. Walk away without taking it and the lid slides shut again. Take it and it is yours for forty-five seconds; let the lease run out and the floor takes it back, and the vent goes quiet with it.

<!-- @catalyst_vent -->

Turn round. Back up the hall a grey pillar four metres tall has been standing there all along, ringed on the floor at its foot with a dark orb sitting in it, and now that the crystal is in your hand it starts to breathe out bodies: five seconds, then one every two and a half, three of them, and then it goes quiet. They come as foes. The crystal does not damage them. Each hit walks one body a single step along an arc, foe to wary to neutral to curious to friend, so a friend costs four. That is the chapter's argument done to something living: a transformation is contact, not harm, and it does not finish in one go. Folded is not less.

<!-- @pick_up_cube -->

<!-- @pickup_gate -->

A cube and a gate that wants seven on the running score, as before. You do not carry this one. You walk into it and it is gone with a chirp, one point richer, and the gate one cell over reads the total. The rule has not changed since the first hall, and here it is the calm part of the room.

<!-- @ -->

## Process and outcome

In the translation halls a move was reducible to its result: here, then there, and the between did not matter. Rotation ends that. Two turns in one order and two turns in the other are the same two turns and two different outcomes, so the process is now part of the thing. From this hall on, how you got somewhere is a fact about where you are.

Next: the same turn, repeated, until it becomes architecture.
