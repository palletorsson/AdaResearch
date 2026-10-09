# What lets a body stand?

[Working route](index.html#VFM_09_Legs) · [Book primary](/necklace/thread?map=VFM_09_Legs&role=primary) · [Previous: Gravity](gravity-relations.html)

**The Legs hall now starts with a physical support experiment.** A large pink plate waits above four narrow posts. Remove supports, shift its mass centre, and release. Then visit the original seven walkers and distinguish an image of walking from a body supported by contact.

![Three posts supporting the released plate, with the load shifted toward the supported corner](legs_support.png)

## The experiment

1. Press RELEASE on the opening four-post arrangement. Watch the plate settle.
2. Press FEET once to remove the first corner post and reset.
3. Press SHIFT once, then RELEASE: the mass moves toward the supported corner.
4. Press SHIFT again, then RELEASE: the same plate tips toward the missing corner.
5. Reveal PARTS and RULE. Compare the initial support footprint with the live mass projection and measured tilt.

![The same three supports with the mass centre shifted toward the missing corner; the plate tips](legs_tipping.png)

The first checked release stayed level. The second reached about 39.9 degrees of tilt after 120 physics frames. These are actual rigid-body outcomes under the tested settings; their paths are not animated by this artifact.

| Control | What changes |
| --- | --- |
| FEET | Four posts → three → adjacent pair → diagonal pair; each edit resets held. |
| SHIFT | Mass centre at the middle → supported diagonal → opposite diagonal; each edit resets held. |
| RELEASE | Unfreeze the rigid load so engine gravity and contact determine motion. |
| RESET | Return to the level, held beginning; retain the selected settings. |
| PARTS | Reveal the X-ray mass centre, floor projection, initial footprint, wall comparison, tilt and signed initial margin. |
| RULE | Explain finite pads, vertical gravity and the limits of a static forecast. |

The load is 10 kg. Its silhouette stays fixed while its custom centre of mass changes. Its assigned inertia tensor also stays fixed: this is an experiment isolating load position, not a detailed model of material redistribution. Plate, posts and catch floor have friction 0.8 and zero bounce. The player does not collide with or push the experimental plate.

## A foot has width

The footprint encloses the corners of the selected **0.16 m square pads**, not ideal contact points. Two opposed pads can therefore make a narrow support region. Reducing them to points would make a line, leaving no margin for sideways movement. Leg count alone cannot settle the question.

The floor and wall outline keep the initial support geometry. The mass projection and measured tilt follow the released body. Once the plate tips, contacts can change; the outline is explicitly a forecast, not a live contact sensor. The wall compresses the plan's Z dimension to fit its display.

## The walker that keeps going

![The retained four-leg procedural walker in the current museum](legs_walker.png)

The second book anchor is **four_leg_critter**. Its mesh advances through patrol code; planted feet wait and a selected foot swings to a new target. Inverse kinematics fits the joint chain toward that target. Its controller does not consult a support polygon before lifting, and gravity does not tip the mesh. The body can look supported without the simulation solving body support.

All seven original walkers remain in their row, shifted sixteen cells along Z to make space for the new encounter. Twenty-nine interior wall/platform cells were flattened so the architecture no longer cuts through the walking comparison; the outer walls remain. The map grows from 32 × 18 to 32 × 34, with eight artifact identities total and two primary book anchors. We retain the row as related implementations rather than claiming that only leg count varies, or that four legs necessarily imply diagonal pairing.

**37 actual-museum desktop checks pass.** They cover held state, engine release, support and tipping outcomes, reset, finite-pad margins, explicit material, exact mass marker, floor/wall display, controls, sampled standing approaches and the retained four-leg walker. Captures are actual desktop views. Headset reach, readability, comfort and sustained performance remain open, along with detailed review of the other six walkers.

[Desktop report](legs-support-check.json) · [Placement ledger](legs-support-placements.json)

The boot still reports an existing unresolved UID and shader-cache write warnings. These are outside this experiment's verification.

**Next: [VFM_08_Arena](arena-relations.html).** Which parts of an agent's movement come from forces, which from its controller, and which relations to the player are implemented?

---

## Book draft

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

SHIFT changes the rigid body's custom centre of mass. Its silhouette remains the same. The gold mark moves because the simulation has changed where its ten kilograms are represented as acting. A body can become different without acquiring a different outline.

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
