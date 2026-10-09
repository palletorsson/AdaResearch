# Give the point a beginning

**Learning elements**

- Initial velocity
- Constant acceleration
- Position as a function of time
- Model limits

Stand between the two flight lanes. Press FIRE before revealing PATH. The point rises and returns to its departure height. PAIR gives the same launch speed to a second angle. Equal range can take a different amount of time.

## Continue the object

Continue the sphere as a visible marker. For this experiment it is frozen, not pickable and has no collision. We calculate its position from an initial velocity and elapsed time. This is the small version of Launch Arc, with one lane and a fixed launch vector.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `02_launch.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 02_launch.gd

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

## Read what changes

`initial_velocity * t` is displacement in metres. The acceleration contribution grows with time squared. Here acceleration is constant, vertical and negative, launch velocity has a positive Y component, and landing means returning to START.y. Under those conditions `duration()` gives the positive return time. The clamp stops at that time; it does not resolve an impact. The smaller code uses (3, 4, 0) m/s so both contributions are easy to follow. The museum chamber supplies angle/speed controls around the same calculation.

## Try another beginning

Keep the vertical component at 4 m/s and double the horizontal component from 3 to 6. Flight time remains 0.8 seconds; horizontal range doubles from 2.4 to 4.8 metres. Predict this before editing.

## Carry onward

Keep initial velocity and acceleration distinct. The next hall lets the engine retain velocity while a force acts for a limited time.

PAIR in the museum uses complementary angles at equal speed. Under its equal-height, uniform-gravity, drag-free model the two flights share horizontal range but usually have different durations. Keep this comparison after the single flight.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/VFM_05_Launch/tutorial.md).
