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

Save `02_launch.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

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

[Reflective text](final.md).
