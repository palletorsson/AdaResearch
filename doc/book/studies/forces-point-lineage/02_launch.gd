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

