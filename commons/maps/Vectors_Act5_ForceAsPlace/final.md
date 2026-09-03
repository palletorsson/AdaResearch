A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

This is the last room of the forces field, and it asks one question you have to walk through: what is a floor *for*? Everything up to here drew vectors on things: on an arrow, on a thrown ball, on a limb. Here the vector is not on anything. It is on a volume of air, and whatever enters that air obeys it.

Read that as a claim about ownership. A force has always been something a thing *has*. This room takes it away from the thing and gives it to the place.

## No starting address

<!-- @free_vector -->

Four arrows on a small grid by the door, and they are all the same arrow. One is drawn in colour with its two facts written beside it, a length and an angle. The other three are the same length at the same angle, standing somewhere else.

That is the whole of what a vector is, and this room spends five metres of cage on its consequences. A vector is two facts, a direction and a length. It has no third fact called *where*. Slide it across the floor and it has not changed, because there was never anything about it that knew where it was.

If a vector has no address, then attaching one to an object was always a convenience rather than a truth. And if it was only a convenience, you can attach it to something else. To a region, for instance.

## The cage

```gdscript
# force_field_zone.gd, the whole of the physics, both branches
rb.gravity_scale = 0.0                    # on entry, remembered
rb.linear_velocity += f * delta           # every tick, thereafter

pb.velocity += (f - pg) * delta           # you: your own gravity, subtracted
```

<!-- @force_field_zone -->

Five metres of nothing, marked by a wire cage and one arrow. Five is not a round number chosen for looks: the chasm is five rows deep, so the volume is exactly as wide as the gap it hangs over. Its floor is the floor you are standing on.

Those two lines are shorter than they should be, and the missing thing is mass. A force divided by a mass gives an acceleration; this skips the division and adds `f` to velocity directly. A heavy thing and a light thing move identically. Not because the code checks and compensates, but because it never asks. The field has no way to find out what you are and nowhere to put the answer if it did.

The book this whole field grew from, Daniel Shiffman's *The Nature of Code*, defines a force as a vector that causes an object *with mass* to accelerate, and then spends a section on the awkwardness that follows. To make falling look right you must multiply gravity by an object's mass so that dividing by the same mass cancels it out again. Two operations that exist only to undo each other, and a generation of us have typed them.

This room does not cancel the mass. It never introduces it. That is the difference between reading the sentence and standing inside it.

Your own body arrives at the same rule by subtraction. Your legs are already adding gravity every frame, so the volume adds `f` minus the gravity you brought, and the two cancel exactly. Inside, the only force in the world is the one on the dial.

## The dial

```gdscript
# vector_machine.gd, three numbers into one direction
f = Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

<!-- @vector_machine -->

Three sliders: how steep, which way round, how hard. Fourteen centimetres of travel each, and between them every direction there is, up to a ceiling of fifteen.

It ships pointing straight down at 9.8, which is gravity: the setting where this room looks exactly like every other room you have been in. That is the lesson before you touch anything. The ordinary world is not the absence of a setting. It is a setting. Somebody chose down.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault in the machine, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing to mean. It is the oldest problem in spherical coordinates, and here it is at hand height, in wood and metal, where you can feel it.

<!-- @ -->

## The probe

```gdscript
# force_cube.gd, the arrow is measured, not scripted
var v := (global_position - _last) / delta
_draw(v * 0.5)                            # clamped at 2.6 m
```

<!-- @force_cube -->

Three glass cubes, forty centimetres, each drawing its own motion out of its own centre as a yellow arrow with three coloured legs and a live readout.

Nothing tells the cube what the field is, and it has not been given the rule. It differences its own position against where it was last frame and draws the answer, so the arrow is not a prediction: it is the field, having already happened, to something that was in the way. That is the only honest way to read a field you cannot see: put something in it and watch.

One thing to know before you trust it. These cubes are weightless from the moment the room loads. They do not fall, ever, field or no field. They will show you where a field pushes them, but they cannot show you the thing this room is named for, because they were never going to drop.

## What the plank is for

<!-- @force_field -->

Two cells wide, straight across the gap, and it was not in the plan. The museum's walker cannot be carried by a field. Every carry volume in the building ignores it, in silence, so a hall built entirely around being carried arrived severed, its far half unreachable and every object in it stranded. Somebody laid a plank. It was the right call, and why you are standing here.

Stand on it and look down, then look up at the cage hanging over the same hole, and the room has said its whole sentence without a word. There are two ways to make a place crossable. You can put matter under the walk. That is what a floor is, and a bridge, and nearly every building you have ever been inside. Or you can leave the hole and change what happens in the air above it.

The plank works for anyone, forever, and nobody has to know why. The field works only for whoever set it, only while it is set, and it can be set wrong. That is the cost, and it is why this is the last room. A floor is a decision somebody made once and then stopped thinking about. Falling is not a property of the hole; it is a property of the rule over the hole, and somebody chose the rule.

A place has an edge, and an edge is geometry rather than intent. For a while this field began five centimetres above the deck, and you could aim it perfectly, walk to it, stand beneath five metres of it, and not be in it. If a force belonged to you, being near it would have been enough.

## The green

<!-- @invisible_hill -->

Off at the far end, a dark green disc four and three quarter metres across with a brass lip, over which glowing pucks glide in from the rim, bend hard away from a centre that has nothing in it, and leave.

No collider, no signal, nothing to touch. A diorama, placed where you can look at it from outside and see the shape of the thing you have been standing in. It answers the little grid of arrows at the other end of the room: that one says a vector has no address, this one says what happens when you give an address a vector.

Nothing at that centre is doing the bending. No mass, no attractor, no object. The curve is the entire content, and it belongs to the region rather than to anything in it.

<!-- @ -->

## Out

The way out returns to Act I, where a vector was an arrow you could take hold of by the tip. It has not changed since. What changed is where you are willing to put one: on an object, then on a motion, then on a limb, and now on a room-sized piece of empty air with you inside it.

The field is a circle. Go round again, and notice that the first arrow was always this.
