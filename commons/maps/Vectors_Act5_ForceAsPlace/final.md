A hole in the floor, and two ways over it. One of them somebody built. The other one is five centimetres above your head.

This is the last room of the forces field, and it asks one question you have to walk through: what is a floor *for*? Everything up to here drew vectors on things: on an arrow, on a thrown ball, on a limb. Here the vector is not on anything. It is on a volume of air, and whatever enters that air obeys it.

Read that as a claim about ownership. A force has always been something a thing *has*. This room takes it away from the thing and gives it to the place.

## The cage

```gdscript
# force_field_zone.gd — the whole of the physics, both branches
rb.gravity_scale = 0.0                    # on entry, remembered
rb.linear_velocity += f * delta           # every tick, thereafter

pb.velocity += (f - pg) * delta           # you: your own gravity, subtracted
```

<!-- @force_field_zone -->

Five metres of nothing, marked by a wire cage and one arrow. Five is not a round number chosen for looks: the chasm is five rows deep, so the volume is exactly as wide as the gap it hangs over.

Those two lines are shorter than they should be, and the missing thing is mass. A force divided by a mass gives an acceleration; this skips the division and adds `f` to velocity directly. A heavy thing and a light thing move identically. Not because the code checks and compensates, but because it never asks. The field has no way to find out what you are and nowhere to put the answer if it did.

Your own body arrives at the same rule by subtraction. Your legs are already adding gravity every frame, so the volume adds `f` minus the gravity you brought, and the two cancel exactly. Inside, the only force in the world is the one on the dial.

## The dial

```gdscript
# vector_machine.gd — three numbers into one direction
f = Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

<!-- @vector_machine -->

Three sliders: how steep, which way round, how hard. Fourteen centimetres of travel each, and between them every direction there is, up to a ceiling of fifteen.

It ships pointing straight down at 9.8, which is gravity: the setting where this room looks exactly like every other room you have been in. That is the lesson before you touch anything: the ordinary world is not the absence of a setting. It is a setting. Somebody chose down.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down and `cos(pitch)` is zero, so both horizontal terms are multiplied by nothing, and the slider beside it, the one that says which way round, does nothing at all. You can run it through its entire range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault in the machine, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing to mean. It is the oldest problem in spherical coordinates, and here it is at hand height, in wood and metal, where you can feel it.

<!-- @ -->

## The probe

```gdscript
# force_cube.gd — the arrow is measured, not scripted
var v := (global_position - _last) / delta
_draw(v * 0.5)                            # clamped at 2.6 m
```

<!-- @force_cube -->

Three glass cubes, forty centimetres, each drawing its own motion out of its own centre as a yellow arrow with three coloured legs and a live readout.

Nothing tells the cube what the field is. It does not subscribe to the machine and it has not been given the rule. It differences its own position against where it was last frame and draws the answer. So the arrow is not a prediction. It is the field, having already happened, to something that was in the way. This is the only honest way to read a field you cannot see: put something in it and watch.

One thing to know before you trust it. These cubes are weightless from the moment the room loads. They do not fall, ever, field or no field. They will show you where a field pushes them, but they will not show you the thing this room is named for, because they were never going to drop.

## What the plank is for

<!-- @force_field -->

Two cells wide, straight across the gap, and it was not in the plan. The museum's walker cannot be carried by a field. Every carry volume in the building ignores it, in silence, so a hall built entirely around being carried arrived severed, its far half unreachable and every object in it stranded. Somebody laid a plank. It was the right call and it is why you can be standing here.

Stand on it and look down, then look up at the cage hanging over the same hole, and the room has said its whole sentence without a word. There are two ways to make a place crossable. You can put matter under the walk. That is what a floor is, and a bridge, and nearly every building you have ever been inside. Or you can leave the hole and change what happens in the air above it.

The plank works for anyone, forever, and nobody has to know why. The field works only for whoever set it, only while it is set, and it can be set wrong. That is the cost, and it is why this is the last room. A floor is a decision somebody made once and then stopped thinking about. Falling is not a property of the hole; it is a property of the rule over the hole, and somebody chose the rule.

## Five centimetres

Here is the part the room did not intend to teach, and teaches best.

The plank sits at half a metre. The field starts at fifty-five centimetres, because the cage's corner spheres poke five centimetres below its floor and the grid lifts anything it seats by exactly as much as it hangs low. What the volume tests is whether your *feet* are inside it.

So you can stand directly beneath a five-metre field, in a room built around entering one, and not be in it. Not by a metre. By the width of two fingers.

That is the truest thing in this hall. A field is not an atmosphere and not an influence and not a mood. It is a place, with an edge, and an edge is a fact about geometry rather than about intent. You can want to be inside something, aim it correctly, walk to it, and miss by five centimetres, because a region does not meet you halfway. The room's own vocabulary has a preset named `crossing`, seven across and seven up, and it points along the length of the trench rather than over it.

None of that softens the claim. It sharpens it. If a force belonged to you, being near it would be enough.

## The green

<!-- @invisible_hill -->

Off at the edge, a dark green disc four and three quarter metres across with a brass lip, over which glowing pucks glide in from the rim, bend hard away from a centre that has nothing in it, and leave.

No collider, no signal, nothing to touch. A diorama of this room's idea, placed where you can look at it from outside and see the shape of the thing you are standing in.

Nothing at that centre is doing the bending. No mass, no attractor, no object. The curve is the entire content, and it belongs to the region rather than to anything in it. Which is the sentence the rest of this hall spends five metres of cage and three sliders arriving at, said quietly, in a corner, by four lights and an empty middle.

<!-- @ -->

## Out

The way out returns to Act I, where a vector was an arrow you could take hold of by the tip. It has not changed since. What changed is where you are willing to put one: on an object, then on a motion, then on a limb, and now on a room-sized piece of empty air with an edge you can be standing five centimetres outside of.

The field is a circle. Go round again, and notice that the first arrow was always this.
