# What carries you across?

A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

The crab in the previous room needed a rule for finding its next encounter. The collision carts needed an account of what the encounter preserved. Bring both questions here. What will this place recognise when you enter it, and what motion will you bring?

## A direction waiting

<!-- @vector_machine -->

The machine stands before the gap. Three sliders: PITCH, YAW, ACCEL. Before trying to cross, move YAW while the field points straight down. Watch the large arrow and the faint horizontal one. Which has heard you?

It opens at an acceleration of 9.8 metres per second squared, downward. That resembles ordinary falling, but the field supplies that value locally. Down is a setting you can change here.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Tilt the field away from vertical. YAW begins to turn its horizontal part; as that part grows, the turn becomes easier to see.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. The console marks a small neighbourhood around either pole as idle too, even though a slight horizontal part is already there. Its readout gives the waiting bearing, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

A direction can be well defined while one of its coordinates is not. Here that ambiguity is at hand height, in metal, where you can feel it happen.


The two angles become a direction. Magnitude gives it a size:

```gdscript
# vector_machine.gd — world coordinates; yaw zero points along +Z
return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

The last slider stops at fifteen metres per second squared. Aim partly upward and along the hall. Read the components before leaving the bench: positive Z leads toward the far side. The machine speaks only to this hall's field. A dial elsewhere in the museum cannot quietly rewrite your crossing.

## Something in the way

<!-- @force_cube -->

Three glass cubes wait near the machine. Take one and move it slowly. Let your hand settle. The motion arrow disappears when the sampled movement becomes small enough. Even stillness has a threshold in this picture.

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

![The plank and the outlined carrying field seen from inside the museum](/book-review/doc/book/figures/forces/two-crossings-museum.png)

*The plank keeps a route through the gap. Beside it, the outline marks where another rule can carry you.*

With the field tilted up and forward, enter its near face from the plank. The field takes over locomotion inside. Your incoming velocity is retained, acceleration is added each physics step, and collision can still stop or deflect that movement. Leaving the volume ends this override; the return to ordinary stick steering also needs support under your feet. Physical tracked movement remains possible in VR; this is a controller handoff, not a force applied to your muscles.

For a released cube, the central operation is short:

```gdscript
# force_field_zone.gd — remembered gravity is restored on exit
rb.gravity_scale = 0.0
rb.linear_velocity += f * delta
```

The missing division matters. This field gives an acceleration directly. It never divides a force by the receiver's mass. A one-kilogram body and a four-kilogram body receive the same velocity increment. They can still meet different contacts or have different damping. Equal instruction does not promise equal journeys.

Gravity arrives at the same place by a different route: its pull grows with the mass it pulls, and the division by that same mass cancels the growth, which is why Galileo's two balls reached the ground together. This field skips the multiplication and the division at once.

The visitor's controller carries its velocity through a separate receiver:

```gdscript
# carry_velocity — incoming on entry, post-collision velocity thereafter
return Vector3(_carry.get(body.get_instance_id(), incoming)) + field_vector * delta
```

Set ACCEL to zero before another crossing. Enter with some motion. Zero has removed the new contribution; it has not removed what you brought. The loose cube slows through its damping. This visitor receiver does not add that damping. The same empty-looking volume holds two different accounts of persistence.

The boundary is another decision. The cube is detected by overlapping its physical body with an area; the visitor is admitted by a test of the body's position near its feet. Their entries need not happen at the same instant. At the far face, the carry receiver lets go. In the air, you keep the motion you leave with while ordinary gravity changes it. Once your feet find the floor, the stick can steer again. That seam can be felt as a change in how you travel.

<!-- @ -->

## What the plank keeps

The plank originally repaired a promise the museum could not keep: a field drew its arrows, but the walker did not accept its acceleration. Writing the same vector into two objects had not made them the same kind of body. One controller erased what another had just written.

The repair belongs in the argument. Keep the plank. It gives you a way through while you investigate the other crossing, and it makes a comparison available: contact underneath, or a rule changing motion around you. Both depend on what the receiver can do.

The small free-vector display and the green invisible-hill diorama remain as side encounters. A vector can be drawn at another address without changing its components. A region can assign vectors to addresses and make paths bend. Between those two statements lies the work of this hall: admitting a body into a rule, retaining its history, and deciding where the rule stops.

What bodies are possible here? A carried visitor and a damped cube have become possible through related operations, implemented differently. The crab from the previous room would need its own receiver before this field could carry its commanded mesh. Shared code as a medium does not make that translation automatic. It gives us somewhere to work on it.

We leave with more than a new route across a hole. We have learned to look for the place where an instruction becomes a consequence. In the next sequence, Form Finding, that question reaches the shape of the world itself.
