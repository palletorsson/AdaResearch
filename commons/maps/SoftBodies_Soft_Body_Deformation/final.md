A shape is only a rest configuration, and the springs keep renegotiating it with whatever arrives.

This chapter asks one question of a deformable body and answers it outward: who decides the form? Here the answer is the material itself. Nothing in this room is being shaped by anything except its own internal tension and the floor.

```gdscript
for s in springs:
    var diff: Vector3 = positions[s.b] - positions[s.a]
    var cur: float = diff.length()
    var pull: Vector3 = diff.normalized() * (cur - s.rest) * stiffness
    velocity[s.a] += pull
    velocity[s.b] -= pull
```

Every spring wants one length and pulls both its ends toward it. No spring knows the shape. There is no shape anywhere in the code, only a rest length repeated a few hundred times, and what you see is the standing disagreement between all of them and gravity.

## The body on its own

<!-- @jelly_cube -->

A green cube of jelly on a plinth, hanging just under half a metre clear of the floor. Push a hand into it and it gives and comes back. This is the chapter's first claim, and it is worth pressing more than once: the cube has no stored shape to return to. It returns because the springs are still pulling, and the returning is not a memory, it is the same argument continuing.

There is no update loop anywhere in its script. Everything you see moving is the physics solver, working on the mesh, all the time.

<!-- @jelly_variants -->

The same cube, five times, in a row two metres long, with fifteen sliders and ten buttons crowded between them. Stiffness, damping, pressure. Turn one and the same object becomes a different material, and the interesting reading is at the ends: soft enough and it stops behaving like a solid and starts behaving like a bag of liquid; stiff enough and it stops deforming at all and is simply a box.

Nothing was swapped to get there. It is one number, and the categories we have names for are regions of it.

<!-- @ -->

## The body under a machine

<!-- @softmill -->

A stand with two pink bars turning at thirty degrees a second, one revolution every twelve seconds, and a specimen hanging above them. Watch it a while and you will see the bars pass through the specimen without touching it.

That is not a rendering fault. The long arm is on one collision layer and the soft body listens to another, so the two are transparent to each other by arithmetic. The mill is here to be the outside force, the first thing in the chapter that would decide a form from outside the material, and it misses. Take it as the chapter's own timetable: the encounter is two rooms away, and here the body is still alone with itself.

<!-- @science_screen -->

A screen floating with the foot of its stand a metre and a half above the floor, set to draw a field map. It reads nothing in this room and says so: the panel is labelled SOURCE: DEMO, and the field rippling across it is the screen's own test pattern.

<!-- @radiolaria -->

In the corner, nine glass skeletons that do not belong to this argument yet. They are silicon lattices grown by single-celled organisms, and they are the last room of this chapter standing early in the first one. Look at them and move on; the sentence that makes sense of them needs the rest of the walk.

<!-- @ -->

## Rest is a negotiation

The word for the shape a soft body holds is the rest configuration, and both halves of that are misleading. It is not rest: the springs are pulling the whole time, and the stillness is a balance of pulls rather than an absence of them. And it is not a configuration in the sense of a plan, because nothing anywhere holds a picture of the cube. There is a list of rest lengths and a solver, and the cube is what those two produce when they are left alone together.

Which is why the cube comes back when you push it, and why turning one slider by a tenth turns a solid into a fluid. The form was never a thing the material had. It is a thing the material is doing.

Next: the same body, in a field that will not leave it alone.
