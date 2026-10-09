# What admits a body into a rule?

[Working route](index.html#Vectors_Act5_ForceAsPlace) · [Book primary](/necklace/thread?map=Vectors_Act5_ForceAsPlace&role=primary) · [Previous: Arena](arena-relations.html)

**Force as Place now connects the machine, a loose cube and the visitor's movement.** Aim a local acceleration before entering its five-metre volume. The solid plank remains as a second crossing. All eight original artifact placements, including the three probes, are retained; the supporting invisible hill now loads too.

![The acceleration volume over the pit and retained solid plank](place_crossing.png)

## Try the crossing

1. At the machine, move YAW while PITCH points straight down. Compare the large arrow with the faint horizontal bearing.
2. Tilt PITCH upward and toward +Z. Start around 45 degrees upward, yaw zero, magnitude 7.5 m/s².
3. Release a cube into the volume. Its arrow shows sampled movement, scaled and capped for display.
4. Enter from the plank with forward motion. The field owns keyboard/stick locomotion inside; ordinary steering returns outside. Observe the landing.
5. Set acceleration to zero before another entry. Compare the visitor's retained motion with the cube's damping.

The automated crossing starts just inside the near face, with forward speed 2 m/s. It rises above the plank, leaves the far face and lands on the far shore. This demonstrates one configured crossing; a different incoming velocity or field setting can produce a different outcome.

![The machine's cased controls at standing reach](place_machine.png)

## Same instruction, different receivers

| Receiver | Inside the field | What remains different |
|---|---|---|
| Released cube | Gravity is replaced; velocity gains a × dt | Damping, physical contact and area overlap |
| Desktop visitor | Acceleration accumulates before movement; collision output is retained | Foot-position boundary; ordinary steering takes over on exit |
| XRTools visitor | An exclusive movement provider calls move_player | Tracked physical movement remains; headset experience awaits testing |
| Arena crab | No receiver added here | Its commanded mesh does not automatically become a physical field body |

The control names **acceleration**, in m/s². Its update has no division by mass. Zero acceleration preserves incoming velocity; it does not stop a body. A stationary probe now draws no invented resting-force arrow. The field's central arrow disappears at zero too.

The three primary identities are **vector_machine → force_cube → force_field_zone**. Free Vector, Force Field and Invisible Hill remain supporting exhibits. The developed passage about yaw at a pole stays in the book; obsolete claims about the walker ignoring the field are replaced with the actual receiver boundary.

![The existing invisible-hill diorama restored as a supporting encounter](place_hill.png)

## What changed in the room

All map layers reverse in Z so the machine precedes the pit along museum travel. The authored walls, five-row pit and two-cell plank remain. The machine's console is raised to standing reach with a supporting base. The field's visual box no longer seals the museum walk graph, so route repair does not move it off the pit. The registry now admits Invisible Hill's existing scene.

This is a reusable repair principle: inspect the receiver and the museum's placement rules together. A visible field can fail because its controller erases motion, or because a route calculation mistakes its drawing for a wall. Neither failure can be solved by changing the prose alone.

## Evidence and next step

45 checks pass in the actual desktop museum: local versus other-hall binding, late field loading, control defaults and reach, field boundary, full crossing and landing, zero acceleration, re-entry, equal velocity increments for 1 kg and 4 kg bodies, gravity restoration, late XR provider dispatch and all supporting probes. XRTools code is exercised without a headset. Physical comfort, tracked walking, stereo legibility and a learner walkthrough remain open.

[Check report](force-as-place-check.json) · [Placement ledger](force-as-place-placements.json) · [Book source](force-as-place.md)

**Next: Form Finding.** Forces ends by asking which bodies can receive a spatial rule. The next sequence asks how rules can participate in forming the world itself. A later Wavefunctions chapter retains the deeper study of oscillation.

## Book passage

A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

The crab in the previous room needed a rule for finding its next encounter. The collision carts needed an account of what the encounter preserved. Bring both questions here. What will this place recognise when you enter it, and what motion will you bring?

## A direction waiting

<!-- @vector_machine -->

The machine stands before the gap. Three sliders: PITCH, YAW, ACCEL. Before trying to cross, move YAW while the field points straight down. Watch the large arrow and the faint horizontal one. Which has heard you?

It opens at an acceleration of 9.8 metres per second squared, downward. That resembles ordinary falling, but the field supplies that value locally. Down is a setting you can change here.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

It is the oldest problem in spherical coordinates, and here it is at hand height, in metal, where you can feel it happen.


The two angles become a direction. Magnitude gives it a size:

```gdscript
# vector_machine.gd — world coordinates; yaw zero points along +Z
return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

The last slider stops at fifteen. Aim partly upward and along the hall. Read the components before leaving the bench: positive Z leads toward the far side. The machine speaks only to this hall's field. A dial elsewhere in the museum cannot quietly rewrite your crossing.

## Something in the way

<!-- @force_cube -->

Three glass cubes wait near the machine. Take one and move it slowly. Stop your hand. Its motion arrow should disappear; a body at rest need not invent a direction merely to remain a useful exhibit.

Release it into the volume and watch before following. Aim down, then repeat with the field tilted up and forward. Your release matters too. The field changes a velocity that has already begun.

The cube differences its current position against the previous frame:

```gdscript
# force_cube.gd — the visible arrow follows sampled movement
var vel: Vector3 = (global_position - _last_pos) / maxf(delta, 0.0001)
_last_pos = global_position
var f_world: Vector3 = (vel * 0.5).limit_length(2.6)
```

The name `f_world` has survived from an earlier account of this object. The quantity is a motion arrow. It shows half a metre for each metre per second, with its length capped at 2.6 metres. A fast throw can outrun what that length can tell you. The coloured legs decompose the drawing in the cube's own axes; turn the cube and those axes turn with it.

The arrow arrives after the movement. It cannot tell you, on its own, how much came from your hand, the field, damping or a collision. Even this small instrument has a past it cannot separate for you.

The probe has ordinary gravity outside the field and damping that slows its motion. If it falls four metres below its starting height, it returns there and waits frozen for another pickup. Returning is a recovery rule, not the field bringing it home. A cube resting in the basin may still need to be fetched.

## Enter the sentence

<!-- @force_field_zone -->

Five metres of air, marked by a cage. The thin edges are visible; they are not walls. A solid plank remains through the gap. Look along it, then into the air beside it. What would have to change for both to carry you?

With the field tilted up and forward, enter its near face from the plank. The field takes over locomotion inside. Your incoming velocity is retained, acceleration is added each physics step, and collision can still stop or deflect that movement. Ordinary keyboard or stick steering resumes when your feet leave the volume. Physical tracked movement remains possible in VR; this is a controller handoff, not a force applied to your muscles.

For a released cube, the central operation is short:

```gdscript
# force_field_zone.gd — remembered gravity is restored on exit
rb.gravity_scale = 0.0
rb.linear_velocity += f * delta
```

The missing division matters. This field gives an acceleration directly. It never divides a force by the receiver's mass. A one-kilogram body and a four-kilogram body receive the same velocity increment. They can still meet different contacts or have different damping. Equal instruction does not promise equal journeys.

The visitor's controller carries its velocity through a separate receiver:

```gdscript
# carry_velocity — incoming on entry, post-collision velocity thereafter
return Vector3(_carry.get(body.get_instance_id(), incoming)) + field_vector * delta
```

Set ACCEL to zero before another crossing. Enter with some motion. Zero has removed the new contribution; it has not removed what you brought. The loose cube slows through its damping. This visitor receiver does not add that damping. The same empty-looking volume holds two different accounts of persistence.

The boundary is another decision. The cube is detected by overlapping its physical body with an area; the visitor is admitted by a test of the body's position near its feet. Their entries need not happen at the same instant. At the far face, the desktop walker returns horizontal movement to its ordinary input controller and keeps its vertical velocity under ordinary gravity. That seam can be felt as a change in how you travel.

<!-- @ -->

## What the plank keeps

The plank originally repaired a promise the museum could not keep: a field drew its arrows, but the walker did not accept its acceleration. Writing the same vector into two objects had not made them the same kind of body. One controller erased what another had just written.

The repair belongs in the argument. Keep the plank. It gives you a way through while you investigate the other crossing, and it makes a comparison available: contact underneath, or a rule changing motion around you. Both depend on what the receiver can do.

The small free-vector display and the green invisible-hill diorama remain as side encounters. A vector can be drawn at another address without changing its components. A region can assign vectors to addresses and make paths bend. Between those two statements lies the work of this hall: admitting a body into a rule, retaining its history, and deciding where the rule stops.

What bodies are possible here? A carried visitor and a damped cube have become possible through related operations, implemented differently. The crab from the previous room would need its own receiver before this field could carry its commanded mesh. Shared code as a medium does not make that translation automatic. It gives us somewhere to work on it.

We leave with more than a new route across a hole. We have learned to look for the place where an instruction becomes a consequence. In the next sequence, Form Finding, that question reaches the shape of the world itself.
