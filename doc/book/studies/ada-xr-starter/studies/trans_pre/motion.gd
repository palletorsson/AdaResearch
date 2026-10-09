extends Node3D

const Cube = preload("res://studies/trans_pre/marked_cube.gd")
const MotionReadout = preload("res://studies/trans_pre/motion_readout.gd")

var stage := 0
var elapsed := 0.0
var centre := Vector3(0, 1.3, 0)
var travel := 0.25
var leg_seconds := 1.5
var turn_speed := TAU / 8.0
var pulse := 0.3
var cube := Cube.new()
var readout := MotionReadout.new()

func _ready():
    # Supplied guards keep this study within its intended working range.
    assert(stage >= 0 and stage <= 3, "Use stage 0, 1, 2 or 3.")
    assert(leg_seconds >= 0.25, "Use at least 0.25 seconds for each leg.")
    assert(travel >= 0.0 and travel <= 0.5, "Use a travel extent from 0 to 0.5 metres.")
    assert(pulse >= 0.0 and pulse <= 0.5, "Use a pulse extent from 0 to 0.5.")
    cube.position = centre
    add_child(cube)
    add_child(readout)
    readout.configure(centre, travel)
    _process(0.0)

func _process(delta: float):
    elapsed += delta
    var t := pingpong(elapsed / leg_seconds + 0.5, 1.0)
    if stage >= 1:
        cube.position.y = lerp(centre.y - travel, centre.y + travel, t)
    if stage >= 2:
        cube.rotate_y(turn_speed * delta)
    if stage >= 3:
        var factor: float = lerp(1.0 - pulse, 1.0 + pulse, t)
        cube.scale = Vector3.ONE * factor
    # Supplied annotation observes the values. It does not drive the animation.
    readout.show_values(stage, elapsed, t, cube.position.y)
