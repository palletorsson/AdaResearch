# Every Room Is a Difference

A building is a solid mass minus its rooms. A window is glass minus a rectangle. Architecture is the subtraction chapter applied at the scale you live in.

Start from the honest primitive — not walls, but *mass*:

```gdscript
func building(p: Vector3) -> float:
    return sd_box(p, Vector3(6, 3, 4))          # a solid block; no interior yet
```

Then carve inhabitation out of it:

```gdscript
func house(p: Vector3) -> float:
    var mass := sd_box(p, Vector3(6, 3, 4))
    var room_a := sd_box(p - Vector3(-2.5, 0, 0), Vector3(2.6, 2.4, 3.2))
    var room_b := sd_box(p - Vector3( 2.5, 0, 0), Vector3(2.6, 2.4, 3.2))
    var door   := sd_box(p - Vector3(0, -0.6, 0), Vector3(0.6, 1.4, 0.8))
    var window := sd_box(p - Vector3(-2.5, 0.4, 3.6), Vector3(1.0, 0.8, 0.8))
    var interior := min(min(room_a, room_b), min(door, window))   # union the voids
    return max(mass, -interior)                                    # mass EXCEPT voids
```

Read the last line slowly, because it is the whole map: the rooms are unioned *as voids first*, then subtracted once. The doorway is not a thing between two rooms — it is part of the same continuous absence, which is why you can walk from room to room: **circulation is the connectivity of the subtracted volume.**

The wall was never drawn. It is what remains between two voids:

```gdscript
# wall thickness = distance between room_a's face and room_b's face
# move the rooms 0.2 closer and the wall thins to 0.2 — or vanishes.
```

Slide the rooms toward each other in the demo and watch the shared wall thin, then perforate, then disappear — two rooms becoming one, no wall ever edited.

This is the same `max(a, -b)` from the difference room, three doors back, now load-bearing in both senses. And it inverts the way buildings are usually described: the plan is not an arrangement of walls; it is an arrangement of *emptinesses*, and the walls are the residue.

Try: add a `void_pit` — subtract a shaft straight down through the floor of room_a. The lab at the end of the curriculum does exactly this, and means it: every ordered interior stands on a subtraction it doesn't show. Here you can write that sentence in one line of GDScript and then walk into it.
