# Vector & Forces — concept tutorial scripts

The teaching script for the comprehensive vectors → forces 3D space. One tutorial per
concept, in sequence, each anchored to its **best artifact** (see
`vector_forces_concept_map.md`). The pedagogy is embodied: the diagram demotes to a wall
label, the artifact *is* the lesson. Each script has four beats —

- **Hook** — the question/scene that opens the room.
- **Do** — what the hand (or body) does.
- **See** — the math made visible by the doing.
- **Truth** — the one line the player leaves with.

Scale note: where a concept has both an intimate and a walk-in version (addition, dot,
cross, projection), the *small* one teaches and the *large* one lets you stand inside the
idea. Concepts marked **[needs scale]** only have one size — a candidate for an XL twin.

---

## Act I — what a vector is

### 01. Coordinate system — `CoordinateSystem3M`
- **Hook:** before there are vectors there is a *where*. Three axes meet at an origin.
- **Do:** walk the axes; read a point's address (x, y, z) off the grid.
- **See:** a position is three numbers, and the order is the agreement.
- **Truth:** space is a promise three numbers keep.

### 02. Vector basics — `VectorBasics`  **[needs scale]**
- **Hook:** an arrow from here to there. Not a place — a *displacement*.
- **Do:** grab the tip and move it; the arrow follows.
- **See:** a vector has only two facts: direction and length. Slide it anywhere — same vector.
- **Truth:** a vector is a journey with no starting address.

### 03. Magnitude / length — `length_lantern`
- **Hook:** how *much* is this arrow?
- **Do:** stretch the lantern; it brightens/grows with √(x²+y²+z²).
- **See:** length is the Pythagorean diagonal of the components.
- **Truth:** magnitude is how far the arrow would carry you if you walked it.

### 04. Unit vector / normalize — `vector_normalize_demo`  **[needs scale]**
- **Hook:** keep the direction, throw away the distance.
- **Do:** divide by length; the arrow snaps to length 1.
- **See:** every direction has a unit twin on the sphere of radius 1.
- **Truth:** to normalise is to ask "which way?" and refuse "how far?"

## Act II — vector arithmetic

### 05. Addition — `vector_add`  (intimate) + `vector_addition_walk` (walk-in)
- **Hook:** two pushes at once. Where do you end up?
- **Do:** drag two tips on the dual pad; the resultant swings live.
- **See:** a + b is where you arrive if you walk a, then b — head to tail.
- **Truth:** forces add by walking, not by counting.

### 06. Subtraction — `vector_sub`
- **Hook:** what turns a into b?
- **Do:** flip b to −b and add; the difference appears.
- **See:** a − b is the arrow from b's tip back to a's.
- **Truth:** subtraction is the direction of the gap.

### 07. Scaling — `example_2_3_gravity_scaled_by_mass`
- **Hook:** twice as heavy, twice the pull.
- **Do:** turn the mass dial; the force arrow grows proportionally.
- **See:** scalar × vector keeps the line, changes the length.
- **Truth:** a scalar is a volume knob for a direction.

### 08. Dot product — `dot_aligner`  (turret) + `vector_dot_product_xl` (walk-in)
- **Hook:** aim a beam at a drifting foe.
- **Do:** close the angle between aim and target; the lock charges.
- **See:** a · b = |a||b| cos θ — agreement is the charge, and at full agreement the foe converts FOE → FRIEND.
- **Truth:** the dot product is how much two directions agree — and here, agreeing is mercy.

### 09. Projection / reflection — `projection_shadow`  + `vector_projection_reflection_xl`
- **Hook:** a sun overhead, an object off a rail.
- **Do:** swing the object from perpendicular to along the rail.
- **See:** the shadow's length on the rail *is* (a · n̂); the perpendicular drop is the rejection.
- **Truth:** projection is the part of you that lives along someone else's line.

### 10. Cross product / torque — `torque_crank`  + `vector_cross_product_xl`
- **Hook:** push a lever; spin a flywheel.
- **Do:** push along the arm (nothing) then across it (it spins hardest).
- **See:** r × F = |r||F| sin θ points up the axle — a third direction born of two that refuse to align.
- **Truth:** the cross product is the turn left over when two directions disagree.

## Act III — fields and motion

### 11. Vector field / flow — `weather_vector_field`  **[needs scale]**
- **Hook:** a vector at *every* point — wind over a whole map.
- **Do:** walk the field; feel the arrows push you.
- **See:** a field is a function from place to push; streamlines are where it carries things.
- **Truth:** a field is force that has decided to be everywhere at once.

### 12. Motion / velocity — `launch_arc`  **[needs scale]**
- **Hook:** you only ever launch a straight line.
- **Do:** set angle + power; fire.
- **See:** velocity decomposes into vx (carries) and vy (fights gravity); the straight launch bends to a parabola.
- **Truth:** motion is a vector the world keeps editing.

## Act IV — forces

### 13. Work (F·d) — `force_mower`  **[needs scale]**
- **Hook:** push a mower by its angled handle.
- **Do:** raise the handle; watch the work fall.
- **See:** W = F d cos θ — only the part of the push along the ground does work; the rest is wasted into the dirt.
- **Truth:** the world only feels the part of a force that goes its way.

### 14. Friction / drag — `drag_lane`  **[needs scale]**
- **Hook:** run into honey.
- **Do:** enter media of rising resistance.
- **See:** F = −b·v, so velocity decays e^(−bt) — the snapshots bunch up.
- **Truth:** drag is the world charging you rent on speed.

### 15. Projectile / launch — `launch_arc` / `force_pad`
- **Hook:** a pad that throws you.
- **Do:** step on; arc through the air.
- **See:** range = v² sin 2θ / g, peaking at 45°.
- **Truth:** a launch is a velocity you're given; gravity writes the rest.

### 16. Centripetal — `circle_train`  **[needs scale]**
- **Hook:** a high-speed loop.
- **Do:** dial the speed; the train leans into the curve.
- **See:** a = v²/r — double the speed, quadruple the inward pull.
- **Truth:** going in a circle is constant acceleration toward a centre you never reach.

### 17. Gravity / orbit — `orbit_pair`  **[needs scale]**
- **Hook:** two bodies falling around a point that belongs to neither.
- **Do:** slide the mass ratio; the barycenter moves.
- **See:** F = G m₁m₂/r², equal and opposite; the orbits resize to balance.
- **Truth:** an orbit is two things falling toward each other and missing, forever.

### 18. Spring / Hooke — `spring_bob`  **[needs scale]**
- **Hook:** a mass on a coil.
- **Do:** stiffen the spring; it gives less and ticks faster.
- **See:** F = −kx, period 2π√(m/k).
- **Truth:** a spring is honest — it returns exactly what it's given, which is why it keeps time.

### 19. Pendulum — `pendulum_swing`  **[needs scale]**
- **Hook:** gravity and a string, the oldest clock.
- **Do:** lengthen the string; the swing slows.
- **See:** T = 2π√(L/g); the restoring force is mg sin θ along the swing.
- **Truth:** a pendulum keeps time because the pull back is proportional to how far it's pulled.

### 20. Momentum / collision — `momentum_cradle`  **[needs scale]**
- **Hook:** one ball in, one ball out.
- **Do:** lift and release.
- **See:** p = mv passes through the still middle, conserved.
- **Truth:** momentum is motion that refuses to be destroyed, only handed on.

### 21. Restitution / bounce — `bounce_well`  **[needs scale]**
- **Hook:** a ball that never quite returns.
- **Do:** set the bounciness e.
- **See:** h' = e·h — each bounce a fraction of the last.
- **Truth:** every bounce is a tax on a fall.

### 22. Lever / balance — `lever_balance`  (+ `calder_mobile` as showpiece)
- **Hook:** slide a weight along a beam.
- **Do:** move the load; the beam tips, then balances, then tips back.
- **See:** τ = F·d — far out, a small weight outweighs a big one near in; balanced at F₁d₁ = F₂d₂.
- **Truth:** a lever trades force for distance and never gets something for nothing. *(The Calder mobile is this law, drifting — every arm balanced by real weights.)*

### 23. Wind / weather — `weather_vane`  **[needs scale]**
- **Hook:** a force you can't see, only the bend of the things it pushes.
- **Do:** crank the wind; the flag snaps toward horizontal.
- **See:** F_drag = ½ρv²C_dA ∝ v² — double the wind, quadruple the push.
- **Truth:** wind is air with somewhere to be; the force is in the speed, squared.

## Act V — force as place

### 24. Force field (zone) — `force_field_zone` + `vector_machine`
- **Hook:** you must cross a void.
- **Do:** dial the field on the workbench; throw a cube in to test; then step in yourself.
- **See:** inside the cube the field replaces gravity — point it down and you fall, up-and-across and you're carried over.
- **Truth:** falling isn't a property of the void; it's a property of the field over it — and the field is a vector you can turn.

---

## Forming the 3D field — how to order these into maps

- **The spine is the script above:** 24 concepts, five acts (what a vector is → arithmetic → fields/motion → forces → force-as-place), ascending in stakes from "an arrow" to "a force you stand inside."
- **Scale rhythm:** open each act with an *intimate* artifact (a toy you hold) and close it with a *walk-in* one (an idea you stand in). Acts I–II already have this (the `_walk`/`_xl` vector versions); Acts III–IV mostly don't yet.
- **Beauty anchors:** the `calder_mobile` (lever), `force_field_zone` chevron cube (force), `circle_train` neon loop (centripetal), and `bubble_blaster` (velocity) are the rooms that should *look* like art.
- **What's missing for the full field (gap list):**
  1. **Large/walk-in twins** for the 14 single-size concepts — most urgently the forces (spring, pendulum, gravity, centripetal, friction, momentum, restitution) so each act can close at body scale.
  2. **A `vector_basics` and `vector_normalize` showpiece** — these foundational rooms are thin (one small artifact each).
  3. The 8 `_xl` variants need fresh captures so the concept-map sheet is complete.

We have the **breadth** — every concept has at least one good artifact, and the vector algebra has real size range. The work to make it a true *field of understanding* is **scale variety for the forces half** and **these scripts dressed into maps**.
