extends "study.gd"
const Cube = preload("cube_body.gd")
var cubes: Array[RigidBody3D] = []
var required_height := 0.5
var required_time := 1.5
var credit := 0.0
var accepted := false
var readout: Label3D

func _ready() -> void:
    for i in 3:
        var cube := Cube.new()
        cube.position = Vector3((i - 1) * 0.5, 0.22, 0)
        add_child(cube)
        cubes.append(cube)
    readout = caption("", Vector3(0, 1.8, 0))
    button("RESET", Vector3(0, 1, -0.8), restart)

func restart() -> void:
    credit = 0.0
    accepted = false
    for i in cubes.size():
        cubes[i].position = Vector3((i - 1) * 0.5, 0.22, 0)
        cubes[i].rotation = Vector3.ZERO
        cubes[i].linear_velocity = Vector3.ZERO
        cubes[i].angular_velocity = Vector3.ZERO

func observe(height: float, quiet: bool, delta: float) -> void:
    if accepted:
        return
    if height < required_height:
        credit = 0.0
    elif quiet:
        credit += delta
    else:
        credit = maxf(0, credit - delta * 2.0)
    accepted = credit >= required_time

func _physics_process(delta: float) -> void:
    var height := 0.0
    var quiet := true
    for cube in cubes:
        # Transform all corners: a turned cube has another vertical extent.
        for x in [-0.1, 0.1]:
            for y in [-0.1, 0.1]:
                for z in [-0.1, 0.1]:
                    height = maxf(height, to_local(cube.to_global(Vector3(x, y, z))).y)
        quiet = quiet and cube.linear_velocity.length() <= 0.05 and cube.angular_velocity.length() <= 0.1
        quiet = quiet and not cube.is_picked_up()
    observe(height, quiet, delta)
    readout.text = "%s | top %.3f / %.3f m\nQuiet credit %.2f / %.2f s" % [
        "ACCEPTED" if accepted else "BUILD", height, required_height, credit, required_time]
