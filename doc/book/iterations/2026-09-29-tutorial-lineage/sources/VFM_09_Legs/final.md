# What lets a body stand?

<!-- @support_polygon_lab -->

In Gravity, the bodies passed through one another. A surface appeared in the light, but the calculation gave it no skin. This pink plate meets something different: four narrow posts, offering places where falling can be interrupted.

It is waiting. Press RELEASE. Almost nothing happens. That almost is worth watching: the plate drops the small distance to the supports, and they answer. Staying still is now an outcome of contact.

Press FEET once. One post disappears and the plate returns to its held beginning. Before releasing it, choose where you think it will go. SHIFT moves the load toward one corner; another press moves it toward the opposite corner. Compare those two releases with the same three supports. The missing post has not returned. Why can one beginning stay level?

Reveal PARTS. A gold marker shows the mass centre through the plate, and a line projects it onto the floor. The outline joins the outer edges of the available support pads. The wall carries that same initial footprint and the live projection of the mass centre. You can walk around the plate and still keep the relation in view.

```gdscript
hull=Geometry2D.convex_hull(corners)
```

The corners belong to the little squares at the tops of the posts. Their convex hull is the smallest convex outline enclosing them. With the load initially level, gravity vertical and the supports horizontal, the position of the projected mass centre tells us whether these upward contact forces can balance its weight without a tipping moment. Inside gives room to distribute the support. Outside asks the posts to provide something they cannot: a downward pull from a place where there is no fastening.

SHIFT changes the rigid body's custom centre of mass. Its silhouette remains the same. The gold mark moves because the simulation has changed where its load of ten kilograms is represented as acting. The kilograms are the mass; what the posts answer is their weight, the force those kilograms make under gravity. A body can become different without acquiring a different outline.

This is a deliberately sparse body: one rigid plate, a chosen inertia tensor, one mass centre. The fixed inertia stays the same across SHIFT. We are isolating a change of load position, not rebuilding a detailed internal distribution of matter. Its empty-looking interior is full of decisions.

Try FEET again. Two neighbouring posts remain. Try the next arrangement: two opposite posts. Same count, different relation. The diagonal pair leaves a very narrow region around the centre. Move the load out of it.

A foot is not necessarily a point. Each pad here is sixteen centimetres wide. Replace the pads by ideal points and the diagonal region contracts to a line: no room for a sideways displacement. On its boundary, balance would be marginal, not automatically a fall. Our earlier habit of counting points has left something out. Width can change what that count permits.

The right-hand display names its number **initial support margin**. Positive means the opening mass projection lies inside the footprint; negative means outside. After release, the plate can tilt, lose contacts and find new ones. The outline does not pretend to follow those changing contacts. It preserves the prediction beside what actually happens.

```gdscript
body.freeze=false
body.sleeping=false
```

Those are the small instructions that release the plate. The engine then integrates gravity and resolves collisions. We have not written its falling path. The museum floor and your body occupy a separate collision arrangement: you can inspect this experiment, but walking into the plate does not push it. Yet another permission deciding which bodies can meet.

<!-- @four_leg_critter -->

Beyond the table, seven creatures are already walking. Find the one with four legs. Follow a foot while the body travels past it. For a while the foot stays where it was planted. Then it swings through the air and lands ahead.

It looks like an answer to the table's problem. What happens to its support when that foot lifts?

This walker selects the planted foot furthest beyond its distance threshold, provided no other foot is already stepping. It moves one foot at a time. Four legs have not forced it into a trot; a branch in the program has chosen this sequence.

```gdscript
var smooth_t: float = t * t * (3.0 - 2.0 * t)
pos = _leg_step_from[leg_index].lerp(_leg_step_to[leg_index], smooth_t)
var arc: float = 4.0 * t * (1.0 - t)
pos.y += step_height * arc
```

The curve we met as a pattern over time now lifts a foot target. The joint chain reaches toward that target. This is useful work: it makes the planted interval and the swing legible. But reaching the ground and receiving support from it are different operations.

The body itself is a mesh whose position is advanced by the patrol code. Its gait does not ask the support hull for permission, and gravity does not tip this body when the answer would be no. The creature keeps going. The plate had to negotiate its stillness with contact; this walker has been granted movement directly.

Look along the row. One leg, two, three, four, five, six, eight. These are related constructions with different rigs and stepping rules, not a proof that a count dictates a way of living. The row is now a set of questions we can bring back to the table. Which feet are planted? How broad is a foot? Where is the load? Is the body trying to remain still, or carrying momentum into another step?

The gap between a persuasive walk and a supported body is material for another experiment. We could give a creature wider feet, a shifting load, a tail that can touch the ground, or a controller that catches a fall. Each addition would change what bodies this little world can sustain. It would also ask for new code and a new test.

The Arena is ahead. There, a moving body will share space with yours. We carry a more exact question into that encounter: which of its actions come from forces, which from a controller, and which relations to you has the world actually implemented?
