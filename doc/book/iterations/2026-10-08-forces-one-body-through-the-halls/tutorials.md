# Forces — one body gains responses

Walk through the existing Endless Museum. Try the artifact first, then reconstruct one operation with the point you built earlier. The room contains more than the tutorial asks you to make. Return to those larger experiments when you want to combine what you have learned.

The point gains motion, force, resistance and attachments. The cube returns when support and shape matter. In the last hall, the points move you.

## Set up once

Keep `point_body.gd`, `free_point.gd` and `study.gd` in one Forces study folder. Their [complete source](forces-shared-code.md) accompanies the lessons:

- `point_body.gd` is your unchanged Lines point: sphere, collider and pickup.
- `free_point.gd` extends it with physical release. Gravity and damping begin at zero; each lesson changes these settings when needed.
- `study.gd` supplies a caption, a button and a thin cylinder for drawing relations. Each lesson contains its own motion or force rule.

Use your existing `PointStudy` Node3D in a clear working bay inside each hall, with a floor-level origin and scale `(1, 1, 1)`. Save each lesson script and replace the script attached to `PointStudy` as you proceed. You carry the class and your saved code; a single physical sphere does not automatically travel between halls.

The museum supplies the floor, lighting, camera and XR hands. These scripts use its installed Godot XR Tools and the declared `push_button.tscn`. The flight lesson also uses the existing capability court’s player movement adapter.

## Compare, then combine

Predict one change before editing. Restart the study to compare from the same beginning. Use metres, kilograms and seconds throughout. After the comparison, return to the larger artifact: another body, a second push or a changed release can make the next event harder to predict.

Each lesson keeps the complete code visible. “Model notes” records the limits and implementation details you may want to revisit after the first experiment.


---

# The relation between two points

**Learning elements**

- Displacement
- Length and direction
- Zero length
- Addition and projection

Take the two familiar points. Move one and watch the cylinder between them. Then move both by the same amount. Their addresses change; the gap between them stays the same.

## Make the small study

Continue the point class from Lines. Make two points report their separation as a vector, a length and a direction. Begin with those three readings; return to the projection after they make sense.

**The hall adds:** The hall adds two stations: joining movements by addition, and keeping the part of a movement along a rail.

Save `01_vectors.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 01_vectors.gd

<!-- student-code:01_vectors.gd -->

```gdscript
extends "study.gd"
var a = Point.new()
var b = Point.new()
var segment: MeshInstance3D
var reading: Label3D

func _ready() -> void:
    add_child(a)
    add_child(b)
    for point in [a, b]:
        point.freeze = true
        point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    a.position = Vector3(-0.5, 1.2, 0)
    b.position = Vector3(0.5, 1.5, 0)
    segment = rod()
    reading = caption("")

func relation() -> Dictionary:
    var displacement: Vector3 = b.position - a.position
    var length := displacement.length()
    var direction := Vector3.ZERO
    if length > 0.0001:
        direction = displacement / length
    var along_x := Vector3.RIGHT * displacement.dot(Vector3.RIGHT)
    return {"displacement": displacement, "length": length,
        "direction": direction, "along_x": along_x,
        "remainder": displacement - along_x}

func _process(_delta: float) -> void:
    var r := relation()
    join(segment, a.position, b.position)
    reading.text = "gap %s m\nlength %.2f m\ndirection %s" % [
        r.displacement, r.length, r.direction]
```

## Read the change

`b.position - a.position` gives the movement from a to b in the study’s local coordinates. Its three components tell us how far to move along each axis. `length()` measures the whole gap.

Divide that displacement by its length to keep only direction. The result has length one. When the points meet, the `if` leaves direction at zero: there is no direction to recover from a zero-length gap.

Read the projection last. `dot(Vector3.RIGHT)` takes the signed X component. Multiplying it by `Vector3.RIGHT` makes a vector along X; subtracting it from the full displacement leaves the remainder. Add the two parts and you get the original displacement back. This is another use of vector addition.

## Change one thing

Place the endpoints three metres apart along X and four along Y. Predict a five-metre gap, then check it. Move both together and check again. Finally bring them together: the cylinder disappears and the direction reads zero.

To inspect the projection, temporarily display `r.along_x` and `r.remainder` in the caption. The complete example already calculates both; its first readout shows only gap, length and direction.

## Model notes

The cylinder draws a relation. It applies no force. These positions share the PointStudy frame, so subtracting them is meaningful.

## Into the next room

Keep the distinction between a position and a displacement. In Launch, a vector describes how much position changes each second.

[Reflective text](final.html#Vectors_Act1_WhatAVectorIs).


---

# Give the point a beginning

**Learning elements**

- Initial velocity
- Constant acceleration
- Position over time
- A flight model

Press FIRE and watch the point rise and return. Before revealing PATH, trace the curve you expect with your hand. Then compare your prediction with the displayed path.

## Make the small study

Continue the sphere as a marker. Give it an initial velocity and calculate its position as time passes. Freeze its rigid body and turn collision off so this first flight follows the calculation alone.

**The hall adds:** The hall adds angle and speed controls, a path display and a second flight for comparison.

Save `02_launch.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 02_launch.gd

<!-- student-code:02_launch.gd -->

```gdscript
extends "study.gd"
const START := Vector3(-2, 1, 0)
var initial_velocity := Vector3(3, 4, 0)
var acceleration := Vector3(0, -10, 0)
var point = Point.new()
var time := 0.0
var running := false

func _ready() -> void:
    add_child(point)
    point.freeze = true
    point.enabled = false
    point.collision_layer = 0
    point.collision_mask = 0
    point.position = START
    button("FIRE", Vector3(0, 1, -0.8), fire)

func fire() -> void:
    time = 0.0
    running = true

func duration() -> float:
    return -2.0 * initial_velocity.y / acceleration.y

func at(t: float) -> Vector3:
    return START + initial_velocity * t + 0.5 * acceleration * t * t

func _process(delta: float) -> void:
    if not running:
        return
    time = minf(time + delta, duration())
    point.position = at(time)
    running = time < duration()
```

## Read the change

Read `at(t)` from left to right. `START` is the departure position. `initial_velocity * t` is the displacement that the initial velocity would produce on its own. With `(3, 4, 0)`, the point begins by moving right at 3 m/s and up at 4 m/s.

The last term, `0.5 * acceleration * t * t`, adds the effect of constant downward acceleration. As time grows, this term bends the flight downward. Its units are metres, so all three terms can be added.

FIRE sets time to zero and starts the updates. Each frame adds `delta` to time and asks `at(time)` for a position. `duration()` finds when this particular flight returns to its starting height; `minf` stops the clock at that instant.

## Change one thing

Keep the upward component at 4 m/s. Double the horizontal component from 3 to 6 m/s. Predict what changes before running: the return still takes 0.8 seconds, while horizontal range grows from 2.4 to 4.8 metres.

Back in the hall, try PAIR. Two complementary launch angles at the same speed can reach the same distance in different times.

## Model notes

The return-time formula assumes upward initial velocity, constant downward acceleration and equal departure and arrival heights. Drag is absent. The point stops at the calculated time; it does not collide with a landing surface.

## Into the next room

You have calculated where the point should be. Next, let the physics engine keep its velocity while you supply a push.

[Reflective text](final.html#VFM_05_Launch).


---

# When the push ends

**Learning elements**

- Force
- Mass
- Physics updates
- Continued velocity

Press PUSH 1 s. Three equally sized black points start moving. Their masses are 1, 2 and 4 kilograms. Watch after the second has passed: the push ends, but the points keep going.

## What you bring

The point class comes from [Lines](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/maps/Point_Lines/tutorial.md), pickup and local/world positions from [Coordinates](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/maps/Point_Coordinates/tutorial.md), and arrays, indices and loops from [Trace](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/maps/Point_Trace/tutorial.md). [Transformation](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/maps/Trans_Pre/tutorial.md) used elapsed time to place a body; [Launch](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/maps/VFM_05_Launch/tutorial.md) used initial velocity and a clock. Keep those constructions. Here the new operation is a force applied during physics updates.

**Build:** create several instances of the inherited point, store them in an array and apply a timed force to each.

**Investigate:** predict how mass and push duration change velocity, then distinguish equal final speed from equal travelled distance.

## Make the small study

Use three instances of the familiar point. Give each the same force for the same time and vary only mass. The supplied `free_point.gd` lets them move freely, with gravity and damping set to zero.

**The hall adds:** Separate lanes keep the museum spheres at one height and moving along one axis. It also supplies RESET, recent trails and measured speeds beside the expected change. Your smaller points move freely in three dimensions and share one caption.

Save `03_mass.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 03_mass.gd

<!-- student-code:03_mass.gd -->

```gdscript
extends "study.gd"
var points: Array[RigidBody3D] = []
var force := Vector3(0, 0, 1) # newtons in the study frame
var remaining := 0.0
var reading: Label3D

func _ready() -> void:
    for i in range(3):
        var point = Point.new()
        add_child(point)
        point.position = Vector3(i - 1, 1.2, 0)
        point.mass = pow(2.0, i)
        points.append(point)
    reading = caption("")
    button("PUSH 1 s", Vector3(0, 1, -0.8), push)

func push() -> void:
    remaining = 1.0

func _physics_process(delta: float) -> void:
    var interval := minf(remaining, delta)
    for point in points:
        if interval > 0 and not point.is_picked_up():
            point.apply_central_force(global_basis * force * interval / delta)
    remaining = maxf(0, remaining - delta)
    reading.text = "1 / 2 / 4 kg\n%.2f / %.2f / %.2f m/s" % [
        points[0].linear_velocity.length(), points[1].linear_velocity.length(),
        points[2].linear_velocity.length()]
```

## Read the change

`Point.new()` makes another instance of the class you already built. `points.append(point)` keeps the body itself in the array; Trace kept positions. The index `i` supplies its placement and mass. `pow(2.0, i)` gives 1, 2 and 4 for indices 0, 1 and 2.

`apply_central_force` supplies a push to the rigid body. Godot updates its velocity and position. A greater mass receives a smaller acceleration from the same force. For a constant force, acceleration is force divided by mass; the velocity change is force × duration ÷ mass. One newton acting for one second changes these bodies’ speeds by 1, 0.5 and 0.25 m/s, starting from rest and before contact.

`_physics_process(delta)` is the new callback here. Godot calls it at the physics update rate; `delta` is the duration of one such step in seconds. Use it to apply a continuing force. The engine integrates that force during the step.

The loop visits every point. While `remaining` is positive, it applies the force to points that are not held. The clock keeps counting down during a grab, so a held point misses that part of the push. Once time runs out, the code stops applying force. It never sets velocity back to zero.

The button connects to `push()`. Pressing it sets the shared clock to one second. Wait for one pulse to end before comparing a second: pressing during a pulse restarts its remaining time.

## Change one thing

Replace the mass expression with `[1.0, 2.0, 8.0][i]`, and change the caption’s heading from `1 / 2 / 4 kg` to `1 / 2 / 8 kg`. Predict a speed change of 0.125 m/s for the third point. Restart to compare from rest, and keep your hands off while measuring. The body’s mass and the words describing it need to agree.

## Build another comparison

Keep the complete example above as your working reference. In a separate script extending `study.gd`, make two points: 1 kg and 2 kg. One button begins both pushes. Apply the same 1 N force to the first for one second and the second for two seconds. Keep an independent remaining-time value for each point. A two-entry array and the loop pattern above are enough. Reading `remaining[i]` gets that point’s clock; assigning `remaining[i] = ...` replaces the entry. Update each clock separately, keeping its index paired with the same point.

Before running, predict their speeds after one second and after both pushes have finished. Also predict whether equal final speed puts them at the same distance from their starting places. Show both speeds and distances from the starting positions in the caption. Keep each starting position before the run; the length of `point.position - start_position` measures distance from it in these straight, forward paths. This reuses the displacement from Lines. Keep one snapshot of both distances when both push clocks first reach zero; the spheres will keep moving while you read it. A boolean flag can record that the snapshot has been taken, and the next button press can clear that flag. Allow for a small difference from the ideal values at the physics-step boundary. Use a clear bay, no gravity or damping, and separate the points so they cannot collide during this comparison.

Check your result by waiting after both clocks reach zero: both points should retain their final velocities until another influence intervenes. Explain which instructions end the push and which settings permit the coasting. Then choose another mass and work out a duration that would give the same final speed. Your code and your prediction are both part of the exercise.

## Return to the hall

After one pulse has ended, press again before the points hit anything. Predict another equal change in velocity. Then interrupt a trial by catching a point. The button command stayed the same; your intervention changed the starting state for what followed.

## Model notes

The study assumes unit scale. `global_basis` turns its local force direction into world axes. Godot accounts for the physics time step when applying force. `interval / delta` only shortens the last step if less than a full step remains in the pulse. The museum’s lane locks restrict movement; the tutorial leaves all three directions available. Its supplied readout and button are display and input helpers; the force rule is in this script. The tested bay is to the right of the mass lanes: PointStudy at (23, 0, 18) in this hall’s local metres, with zero rotation and unit scale. Leave four metres clear along local +Z for the trial. Restart the study for each fresh comparison.

## Into the next room

A push can end while its consequence continues. Next, choose the push from where the point is now.

[Reflective text](final.html#VFM_03_Motion).


---

# Ask the field where you are

**Learning elements**

- A field of vectors
- Sampling by position
- Acceleration and force
- Local and world directions

Follow one point through the vortex arrows. At each place it meets a different direction. Watch it turn before switching ONE / MANY to bring back the circulating cargo.

## Make the small study

Keep the moving point. Replace the fixed push with `sample()`, a function that reads its position and returns an acceleration. Combine an inward pull with a sideways turn.

**The hall adds:** The hall adds visible arrows, damping and several bodies that can collide. Your study isolates the acceleration rule, with a caption showing position and acceleration.

Save `04_field.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 04_field.gd

<!-- student-code:04_field.gd -->

```gdscript
extends "study.gd"
var point = Point.new()
var reading: Label3D

func _ready() -> void:
    add_child(point)
    point.position = Vector3(2, 1.2, 0)
    point.linear_velocity = global_basis * Vector3(0, 0, 1.8)
    reading = caption("")

func sample(p: Vector3) -> Vector3:
    var flat := Vector3(p.x, 0, p.z)
    if flat.length() < 0.05:
        return Vector3.ZERO
    var tangent := Vector3(-flat.z, 0, flat.x).normalized()
    return -flat * 0.65 + tangent * 2.8 # m/s²

func _physics_process(_delta: float) -> void:
    var acceleration := global_basis * sample(point.position)
    if not point.is_picked_up():
        point.apply_central_force(point.mass * acceleration)
    reading.text = "at %s m\nacceleration %s m/s²" % [point.position, acceleration]
```

## Read the change

`flat` is the point’s position in the study’s horizontal X–Z plane. Multiplying it by a negative number gives an inward vector toward the centre.

`Vector3(-flat.z, 0, flat.x)` turns that vector sideways by a quarter-turn. Normalizing gives it unit length; multiplying by 2.8 sets the sideways acceleration. Add this to the inward part to make the swirl.

Each physics update samples again at the point’s new position. `global_basis` turns the local result into world axes. Then `point.mass * acceleration` supplies the force needed for that acceleration. The point keeps its existing velocity as this new contribution acts.

## Change one thing

Change the point’s mass to 4 kg. With the same start and no contact, predict the same path: the requested force grows with mass. Restart, then set the sideways coefficient from 2.8 to zero. Watch what remains of the motion.

## Return to the hall

Return to the hall and choose MANY. Follow one body until it meets another. The field still samples position; contact has now changed the velocity with which the body reaches its next position.

## Model notes

The rule returns zero within 0.05 m of the centre, where this sideways direction is undefined. The caption’s position is local and its acceleration is in world axes. This study omits the museum vortex’s damping. The nearby flow display makes a separate choice: using a vector as velocity directly gives different motion from using it as acceleration.

## Into the next room

This force reads position. The next one reads how fast, and in which direction, the point is moving.

[Reflective text](final.html#Vectors_Act3_FieldsAndMotion).


---

# Let motion meet resistance

**Learning elements**

- Drag
- Speed-dependent resistance
- Entering a region
- Opposing velocity

Drop a point into a coloured region. Watch it slow as it falls. Begin with DRAG ONLY; leave BUOYANCY for a later comparison. Use RESET before the next drop.

## Make the small study

Keep the sphere and enable gravity. Add resistance while its centre lies between heights zero and two metres. The small study uses a height test; it does not build a liquid surface.

**The hall adds:** The hall makes three regions visible and lets you add buoyancy. The nearby ramps explore contact friction and rolling.

Save `05_drag.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 05_drag.gd

<!-- student-code:05_drag.gd -->

```gdscript
extends "study.gd"
var point = Point.new()
var coefficient := 0.6 # kg/m, chosen for this quadratic model
var released := false

func _ready() -> void:
    point.position = Vector3(0, 3, 0)
    add_child(point)
    point.freeze = true
    point.gravity_scale = 1.0
    caption("DROP · one point, one resistance coefficient")
    button("DROP", Vector3(0, 1, -0.8), drop)

func drop() -> void:
    point.freeze = false
    point.sleeping = false
    released = true

func resistance(velocity: Vector3, mass_kg: float, delta: float) -> Vector3:
    var force := -coefficient * velocity.length() * velocity
    return force.limit_length(mass_kg * velocity.length() / delta)

func _physics_process(delta: float) -> void:
    if not released or point.is_picked_up():
        return
    if point.position.y >= 0 and point.position.y <= 2.0:
        point.apply_central_force(resistance(point.linear_velocity, point.mass, delta))
```

## Read the change

The `if` asks whether the point is inside the height range. Outside it, this script adds no resistance. Inside it, the force opposes `linear_velocity`.

Start with the minus sign in `resistance()`: it reverses the velocity’s direction. Multiplying by `velocity.length()` makes faster motion meet stronger resistance. Double the speed and the force becomes four times as large, before the limit is reached.

`coefficient` controls the strength of that resistance. Gravity continues to pull down while drag opposes the fall. DROP unfreezes the point so the engine can begin this exchange.

## Change one thing

Increase `coefficient` from 0.6 to 3.0 and restart. At the same speed the drag is five times stronger, until capped. Compare the falling speeds over the available drop; the short fall may end before either reaches a steady speed.

## Model notes

The coefficient has units kg/m in this quadratic model. `limit_length` caps drag so that this contribution alone cannot reverse velocity in one physics step. This is a force model, not a fluid simulation. Set the starting position before `add_child`, as shown: moving a frozen kinematic body afterward can introduce unintended velocity. The museum uses a separate movement rule for the player walking through a region.

## Into the next room

Drag resists motion. A spring adds a reason to move back toward an attachment.

[Reflective text](final.html#Vectors_Act4a_KineticForces).


---

# Release the point; keep the attachment

**Learning elements**

- Rest length
- Spring force
- Damping
- Equilibrium
- Spring and hinge

Pull the rose grip beside the hanging point and release. The point returns, passes its resting place and turns again. The grip lets you pull while the spring keeps acting.

## Make the small study

Make one spring from the familiar point and a fixed anchor. In your small study, grab the point itself to set its position, then release it to see the spring act. The thin cylinder shows the attachment.

**The hall adds:** The hall’s separate rose grip pulls through force while you hold it. ONE / MANY adds six more points and connecting springs. Nearby hinges offer a different kind of attachment.

Save `06_spring.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 06_spring.gd

<!-- student-code:06_spring.gd -->

```gdscript
extends "study.gd"
const ANCHOR := Vector3(0, 2.8, 0)
var point = Point.new()
var rest_length := 1.0
var stiffness := 20.0 # N/m
var damping := 0.5 # kg/s
var tether: MeshInstance3D

func _ready() -> void:
    add_child(point)
    point.position = Vector3(0.5, 1.8, 0)
    point.gravity_scale = 1.0
    tether = rod()
    caption("Pull the point. Release it. The spring keeps its anchor.")

func spring_force(offset: Vector3, velocity: Vector3) -> Vector3:
    var length := offset.length()
    if length < 0.0001:
        return -damping * velocity
    return (offset / length * (length - rest_length) * stiffness
        - damping * velocity).limit_length(150.0)

func _physics_process(_delta: float) -> void:
    var offset: Vector3 = to_global(ANCHOR) - point.global_position
    if not point.is_picked_up():
        point.apply_central_force(spring_force(offset, point.linear_velocity))
    join(tether, point.position, ANCHOR)
```

## Read the change

`offset` points from the body to the anchor. Its length tells us their current separation. Subtract `rest_length` to find how far the spring is stretched or compressed.

Multiplying that difference by `stiffness` gives the force magnitude. The normalized offset gives its direction. A stretched spring pulls toward the anchor; compression reverses the sign.

The last term subtracts `damping * velocity`. It opposes movement, so the returns gradually settle. Gravity still acts: the hanging point rests with the spring stretched enough to support its weight.

## Change one thing

Release from the same position with damping at 0.5, then at 3.0. Predict which will keep moving longer. Restore damping and double stiffness. Compare the stronger return without changing rest length.

## Return to the hall

Return to the full row with ONE / MANY. Pull one grip and follow the movement into its neighbours. Try releasing a second point while the first is still moving. Each spring follows its rule, but the next movement now depends on several bodies.

## Model notes

The zero-length check avoids dividing by zero; the force is capped at 150 N. The student point is placed by the hand while held, and resumes spring motion on release. A hinge keeps a pivot attached; this spring permits its length to change.

## Into the next room

Here a repeating movement comes from forces changing velocity. Next, make a similar repetition by assigning positions.

[Reflective text](final.html#Vectors_Act4b_Oscillation).


---

# The same return, a different cause

**Learning elements**

- Period
- Phase
- Relative rate
- Accumulated angle
- Prescribed motion

Watch the rods turn together, then notice one that is out of step. Look back toward the spring. Both repeat. What keeps each one moving?

## Make the small study

Use two sphere points as the tips of two arms. Give each an angle and a turning rate. OFFSET changes one angle once; DRIFT changes how quickly that angle advances.

**The hall adds:** The hall adds a whole rod array and eyes that follow you. The conveyor nearby shows what repeated arrivals can do to a physical queue.

Save `07_phase.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 07_phase.gd

<!-- student-code:07_phase.gd -->

```gdscript
extends "study.gd"
var points: Array[RigidBody3D] = []
var arms: Array[MeshInstance3D] = []
var angles := [0.0, 0.0]
var rates := [TAU / 6.0, TAU / 6.0]
var reading: Label3D

func _ready() -> void:
    for i in range(2):
        var point = Point.new()
        add_child(point)
        point.freeze = true
        point.enabled = false
        point.collision_layer = 0
        point.collision_mask = 0
        points.append(point)
        arms.append(rod())
    reading = caption("")
    button("OFFSET", Vector3(-0.5, 1, -0.8), offset)
    button("DRIFT", Vector3(0.5, 1, -0.8), drift)

func offset() -> void:
    angles[1] += PI / 4.0

func drift() -> void:
    rates[1] = TAU / 6.0 * 1.04

func _process(delta: float) -> void:
    for i in range(2):
        angles[i] = fposmod(angles[i] + rates[i] * delta, TAU)
        var pivot := Vector3(i * 1.6 - 0.8, 1.3, 0)
        points[i].position = pivot + Vector3(sin(angles[i]), cos(angles[i]), 0) * 0.6
        join(arms[i], pivot, points[i].position)
    reading.text = "gap %.1f degrees · prescribed position" % rad_to_deg(
        fposmod(angles[1] - angles[0], TAU))
```

## Read the change

`angles` stores where each arm is in its turn. `rates` stores how much angle it gains per second. `TAU` is one full turn, so `TAU / 6` completes it in six seconds.

Each frame adds rate times `delta`. The `sin` and `cos` you met in periodic motion turn the angle into a position on a circle. The point is frozen and has no collision; the script places it.

OFFSET adds 45° to one angle. With equal rates, the gap stays fixed. DRIFT raises one rate by 4%, so the gap keeps growing. `fposmod` wraps angles after each complete turn.

## Change one thing

Press OFFSET with equal rates and watch the 45° gap persist. Restart, press DRIFT and wait thirty seconds: predict an added gap of 72°. Change the rate difference to 2% and predict 36°.

## Model notes

The study accumulates angle so a rate change preserves the current position. The museum’s full rod array calculates angle from elapsed time, frequency and phase; changing frequency there can cause a jump. Neither calculation applies a spring force or torque.

## Into the next room

A circular path can be prescribed. Next, let two points attract each other and see what path results.

[Reflective text](final.html#Change_Choreography).


---

# Let both points answer

**Learning elements**

- Mutual attraction
- Equal and opposite forces
- Adding pair forces
- Initial conditions
- Softening at close range

Begin with PAIR. Follow both spheres: each turns toward a source that is itself moving. Neither one is fixed. Save PAIR / FIVE until you have watched the pair.

## Make the small study

Return to two physical points. Give them opposite starting velocities. Calculate the attraction between them once, apply it to one body, and apply its negative to the other.

**The hall adds:** The hall can add three more spheres and make the visitor another source. Your first reconstruction keeps the pair isolated, with collisions and ordinary downward gravity off.

Save `08_attraction.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 08_attraction.gd

<!-- student-code:08_attraction.gd -->

```gdscript
extends "study.gd"
var a = Point.new()
var b = Point.new()
var strength := 4.0 # m³ / (kg s²), an authored model value
var softening := 1.2 # metres

func _ready() -> void:
    add_child(a)
    add_child(b)
    a.position = Vector3(-1.5, 1.2, 0)
    b.position = Vector3(1.5, 1.2, 0)
    a.linear_velocity = global_basis * Vector3(0, 0, 0.6)
    b.linear_velocity = -a.linear_velocity
    for point in [a, b]:
        point.mass = 2.0
        point.collision_layer = 0
        point.collision_mask = 0
    caption("Two sources. Neither is fixed.")

func pair_force(displacement: Vector3) -> Vector3:
    var denominator := pow(displacement.length_squared() + softening * softening, 1.5)
    return displacement * strength * a.mass * b.mass / denominator

func _physics_process(_delta: float) -> void:
    var force := pair_force(b.global_position - a.global_position)
    a.apply_central_force(force)
    b.apply_central_force(-force)
```

## Read the change

Subtract the two world positions to get a displacement from a to b. The force follows that displacement. Both masses multiply its strength.

The denominator makes attraction weaker with separation. Read `softening` as a chosen length that changes the calculation when the points get close. It keeps the force finite even when their positions coincide.

The two calls apply `force` and `-force`. The engine then uses each body’s mass to find its acceleration. Both velocities change, so the next update begins with two new source positions.

## Change one thing

Double only `a.mass` and keep the starting velocities. Predict both responses: the shared force doubles; a’s acceleration stays the same because its mass also doubled; b’s acceleration doubles. Restart to compare.

## Return to the hall

Choose PAIR / FIVE in the hall, then enter the field. Your presence adds another attraction. Track one sphere and notice when a new encounter makes its earlier path a poor guide to what happens next.

## Model notes

This softened attraction is an authored model. Far from the softening length it approaches an inverse-square force. It does not guarantee a circular orbit. Equal and opposite forces preserve the isolated pair’s total momentum within numerical tolerance; the simulation does not conserve energy exactly. Once the visitor joins, the spheres alone are no longer an isolated system.

## Into the next room

These points attract while passing through each other. Bring back collision to ask what lets one body support another.

[Reflective text](final.html#VFM_07_Gravity).


---

# What lets the cube stay up?

**Learning elements**

- Visible shape and collision shape
- Contact support
- Gravity
- Waking a body

Pull the rose leg from under the loaded table. Watch what loses support first, then what it meets on the way down. The fall follows the changed arrangement.

## Make the small study

Bring back the cube from Primitives. Start with one box resting on one support. Move the support sideways and let the physics engine determine what happens to the load.

**The hall adds:** The hall adds a tabletop, several supports and a load you can rearrange. Your study begins with one contact so its role is easy to see.

Save `09_support.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 09_support.gd

<!-- student-code:09_support.gd -->

```gdscript
extends "study.gd"
var leg: StaticBody3D
var load: RigidBody3D

func _ready() -> void:
    leg = StaticBody3D.new()
    leg.position = Vector3(0, 0.5, 0)
    add_child(leg)
    box_on(leg, Vector3(0.4, 1.0, 0.4))
    load = RigidBody3D.new()
    load.position = Vector3(0, 1.31, 0)
    load.mass = 2.0
    add_child(load)
    box_on(load, Vector3.ONE * 0.6)
    caption("A cube stays up because something meets it.")
    button("REMOVE SUPPORT", Vector3(0, 1, -0.8), remove_support)

func box_on(body: PhysicsBody3D, size: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    surface.mesh = mesh
    body.add_child(surface)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)

func remove_support() -> void:
    leg.position.x = 1.5
    load.sleeping = false
```

## Read the change

`box_on()` gives each body a visible `BoxMesh` and a matching `BoxShape3D`. The engine uses the collision shape to detect contact.

The leg is a `StaticBody3D`. The load is a `RigidBody3D` with gravity. It begins one centimetre above the support, falls onto it and settles.

REMOVE SUPPORT changes the leg’s position. It gives no downward instruction to the cube: gravity was already acting. `sleeping = false` wakes the load if the engine had paused its settled simulation.

## Change one thing

Change the support’s movement from 1.5 m to 0.1 m and restart. Predict that enough overlap will remain to support the centred cube. Then restore the larger movement. Keep the dimensions and gravity the same.

## Return to the hall

At the full table, move the load toward one side before removing a leg. Predict which contacts matter now. Compare the collapse with the centred arrangement.

## Model notes

A mesh alone supplies no physical support. This example pairs visible dimensions with collision dimensions; the contact result depends on the latter. The walkers nearby add foot placement and control, which this small reconstruction leaves for later.

## Into the next room

Contact can hold a body still. Next, let contact pass motion from one body to another.

[Reflective text](final.html#VFM_09_Legs).


---

# One impact, then the world

**Learning elements**

- Impulse
- Momentum change
- A one-shot action
- Collision response

Send the black bowling point down the lane. Watch the first pin it reaches and follow that pin into the next contact. Your throw starts a sequence you no longer direct.

## Make the small study

Use the same point twice: one striker and one target. Give the striker one impulse, then let their collision unfold. Start without gravity or a floor so the first question is the impact.

**The hall adds:** The hall adds ten pins, floor friction, rolling and a score. Its ROLL control can be used repeatedly; your study allows one launch before a restart.

Save `10_impulse.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

## Complete code — 10_impulse.gd

<!-- student-code:10_impulse.gd -->

```gdscript
extends "study.gd"
var point = Point.new()
var target: RigidBody3D
var used := false
var impulse := Vector3(0, 0, 3) # N·s in the study frame

func _ready() -> void:
    add_child(point)
    point.position = Vector3(0, 1.2, -1)
    target = Point.new()
    add_child(target)
    target.position = Vector3(0, 1.2, 1)
    for body in [point, target]:
        body.mass = 1.0
        body.collision_layer = 4
        body.collision_mask = 4
    caption("One impulse. Then the contact has its turn.")
    button("ROLL ONCE", Vector3(0, 1, -1.8), roll)

func roll() -> void:
    if used:
        return
    used = true
    point.apply_central_impulse(global_basis * impulse)
```

## Read the change

An impulse changes momentum in one action. With a 1 kg body, the chosen 3 N·s impulse gives a velocity change of 3 m/s before contact. Doubling mass halves that initial change in velocity.

`roll()` calls `apply_central_impulse` once. The `used` flag stops another button event from adding a second impulse. This differs from the sustained force you applied during repeated physics updates.

Both points use collision layer and mask 4, so they can meet. The script never assigns a velocity to the target. Its response comes from contact with the striker.

## Change one thing

Double the striker’s mass while keeping the impulse. Predict its initial speed, then observe the collision separately. Restart each trial. A prediction about the launch speed does not yet tell you how the whole collision will end.

## Return to the hall

Back at the lane, throw slightly off-centre. Follow the first sideways deflection and the contacts it makes possible. A small change in aim can produce a different arrangement of fallen pins.

## Model notes

Impulse is measured in N·s, equivalent to kg·m/s. The collision settings and body properties determine the contact response; this code does not promise a perfectly elastic collision. The study’s points meet in mid-air, before the hall adds rolling and floor contact.

## Into the next room

An impulse happens once. In the last hall, hold a trigger to keep adding acceleration to your own movement.

[Reflective text](final.html#VFM_08_Arena).


---

# The player becomes the receiver

**Learning elements**

- Pickup and trigger actions
- Hand direction
- Player acceleration
- Combining two inputs
- Continued velocity

Take the two black points. Aim where you want to travel and hold the triggers. Let go of the triggers while keeping hold of the points. The thrust ends; your movement continues under gravity and contact.

## Make the small study

Extend the familiar point into a thruster. While held and activated, it reports an acceleration in the direction of your hand. The small station script creates two of these points.

**The hall adds:** The existing capability court supplies the player movement, collisions, gravity and visor. Your new code supplies the held action, direction and identity of the player who receives it.

Save `11_flight.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](forces-shared-code.md).

Work inside the existing capability court, whose movement adapter is required for flight. Save `thrust_point.gd` beside the other files.

### thrust_point.gd

<!-- student-code:thrust_point.gd -->

```gdscript
extends "free_point.gd"
var firing := false

func _ready() -> void:
    super()
    freeze = true
    gravity_scale = 1.0
    add_to_group("ada_thrust_points")
    action_pressed.connect(func(_hand): firing = is_picked_up())
    action_released.connect(func(_hand): firing = false)
    dropped.connect(func(_hand): firing = false)

func held() -> bool:
    return is_picked_up()

func receiver() -> CharacterBody3D:
    var controller := get_picked_up_by_controller()
    if controller == null:
        return null
    var origin := XRHelpers.get_xr_origin(controller)
    for body in get_tree().get_nodes_in_group("player_body"):
        if origin != null and body is XRToolsPlayerBody and origin.is_ancestor_of(body):
            return body
    return null

func acceleration() -> Vector3:
    var controller := get_picked_up_by_controller()
    if not firing or not held() or controller == null:
        return Vector3.ZERO
    return -controller.global_basis.z.normalized() * 11.0
```

## Complete code — 11_flight.gd

<!-- student-code:11_flight.gd -->

```gdscript
extends "study.gd"
const ThrustPoint = preload("thrust_point.gd")
var points: Array = []

func _ready() -> void:
    for x in [-0.3, 0.3]:
        var point = ThrustPoint.new()
        point.position = Vector3(x, 1.2, 0)
        add_child(point)
        points.append(point)
    caption("Hold both points. Aim where you want to go. Press triggers.")
```

## Read the change

`action_pressed` turns firing on while the point is held. Releasing the trigger or dropping the point turns it off. `held()` reports whether someone has picked it up.

`receiver()` follows the holding controller to its XR origin, then finds the player body under that origin. This connects the action to the player whose hand holds the point.

`acceleration()` reads the controller’s forward direction, local -Z, and multiplies it by 11 m/s². When firing stops, it returns zero. It does not clear the player’s velocity.

Adding the point to `ada_thrust_points` lets the existing court find it. The court asks each held point who its receiver is and what acceleration it requests. Two aligned points request 22 m/s²; opposed directions cancel. The court combines those requests, adds gravity once and moves the player with collisions.

## Change one thing

Aim one hand up and one down. Before pressing, predict that the two thrusts cancel while gravity still acts. Then aim both upward: their 22 m/s² request exceeds the court’s 9.8 m/s² gravity. Release the triggers and watch how velocity continues to change.

## Model notes

Mount this study inside the loaded capability court. Its FieldCarryAdapter owns player movement; the points do not set the camera position. The required connection is `receiver()`, `acceleration()` and `held()` in the `ada_thrust_points` group. This small script uses XR hands; the museum version also supports a desktop pointer. Physical headset comfort still needs a playtest.

## Into the next room

The point now gives you a capacity in the world. Direction, acceleration, resistance and contact are things you can use together. The racer and the larger experiments give you places to try.

[Reflective text](final.html#Vectors_Act5_ForceAsPlace).
