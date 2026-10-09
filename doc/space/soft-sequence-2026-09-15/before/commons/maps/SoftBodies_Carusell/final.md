Rotation makes a force field legible through softness: every point of a hanging body reads out a force you could not otherwise see.

You arrive inside the machine. The spawn puts you under four metres from the axis of a carousel three metres across, close enough that the soft bodies sweep past at chest height about half a metre clear of you. Stand still for one revolution, six and a quarter seconds, before you do anything else.

```gdscript
func _physics_process(delta: float) -> void:
    ride_hub.rotation.y += ride_speed * delta
```

That is the entire machine. One rotation applied to one hub, and everything hanging under it works out its own consequences.

## The field, made visible

<!-- @revolving_joy_ride -->

A torus overhead turning once every six seconds, four arms of chained capsules hanging from it, and four soft spheres half a metre across swinging at the bottom of those arms. Nothing tells the spheres where to go. They are dragged by the arms, the arms are dragged by the joints, and the angle each arm hangs at is the balance of the pull inward and the swing outward at that radius.

A rigid arm would tell you nothing: it would simply be where it was put. The softness is the instrument. The bodies are being deformed by exactly the force at their radius, so their shape is a reading of a field that has no appearance of its own.

Two of the four arms sweep through the room's own wall pillars on every revolution, and the twelve frosted posts ringing the ride stand five metres tall against walls of two, sunk half a metre into the floor. The ride was built for a bigger room than this one.

<!-- @cloth_straps -->

Ribbons of cloth hanging from gantries, and you can walk through them. This is the gentlest measurement in the room: the cloth reads whatever is moving nearby, including you, and goes on reading it for a second or two after you have passed. A field written on a surface that keeps a short memory of it.

<!-- @soft_mushroom -->

Fifteen mushrooms, each a rigid stem with a soft cap pinned to the top of it. Push a cap and it wobbles and settles; the stem does not move at all. One object, two materials, and the join between them is where you can feel the difference: the same push does nothing to one half and everything to the other.

<!-- @flex_cloth_pad -->

A small hanging cloth on a pedestal, rebuilt point by point every frame. It sways gently and nothing here disturbs it. Of everything in this room it is the only soft body that is not reading a force from something else, which makes it the control.

<!-- @ -->

## What you can pick up

<!-- @grab_long_stick -->

Two rods lying on the floor, and the only things in this room a hand can actually take. Pick one up and you can put a force into the field yourself: swing it through the ribbons, prod a mushroom cap. Everything else here reads forces. This is the one object that makes them.

<!-- @pick_up_cube -->

Three cubes hovering and turning near the west gap. You cannot carry these, despite the name. Walk into one and it is gone with a chirp and the count goes up by one.

<!-- @synthesis_stand -->

And the same cube's family on a plinth: five stocks of one object, ruled a series by measurement, with the far end of the ladder stood up as its representative. A cabinet card in a room full of things in motion.

<!-- @ -->

## Softness as an instrument

A force field is nothing you can look at. It has no surface, no colour and no edge, and the only way to see one is to put something in it that responds and then watch the response.

That is what this whole room is. The carousel does not demonstrate rotation; you could demonstrate rotation with a rigid bar. It demonstrates the field the rotation creates, and it does that by hanging things in the field that cannot help showing it. Every deformation you can see is a measurement, taken by a body that has no choice about taking it.

The chapter's question was who decides the form. In the last hall the material decided alone. Here the field decides, and the material is what makes the decision visible.

Next: what happens when the thing it meets pushes back.
