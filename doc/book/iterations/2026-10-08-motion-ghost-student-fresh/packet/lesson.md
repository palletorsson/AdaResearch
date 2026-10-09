# When the push ends

**Learning elements**

- Force
- Mass
- Physics updates
- Continued velocity

Press PUSH 1 s. Three equally sized black points start moving. Their masses are 1, 2 and 4 kilograms. Watch after the second has passed: the push ends, but the points keep going.

## What you bring

The point class comes from [Lines](Point_Lines.md), pickup and local/world positions from [Coordinates](Point_Coordinates.md), and arrays, indices and loops from [Trace](Point_Trace.md). [Transformation](Trans_Pre.md) used elapsed time to place a body; [Launch](VFM_05_Launch.md) used initial velocity and a clock. Keep those constructions. Here the new operation is a force applied during physics updates.

**Build:** create several instances of the inherited point, store them in an array and apply a timed force to each.

**Investigate:** predict how mass and push duration change velocity, then distinguish equal final speed from equal travelled distance.

## Make the small study

Use three instances of the familiar point. Give each the same force for the same time and vary only mass. The supplied `free_point.gd` lets them move freely, with gravity and damping set to zero.

**The hall adds:** Separate lanes keep the museum spheres at one height and moving along one axis. It also supplies RESET, recent trails and measured speeds beside the expected change. Your smaller points move freely in three dimensions and share one caption.

Save `03_mass.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](shared-code.md).

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

[Reflective text](reflection.md).
