extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const HALF := 0.85
const HEIGHT := 1.26
@export var seed_value := 42
@export_range(0.01, 0.4) var step_size := 0.24
@export_range(0.05, 1.0) var seconds_per_step := 0.25
@export_range(1, 256) var max_steps := 128
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var trail := Node3D.new()
var status: Label3D
var origin := Vector3(0, HEIGHT, 0)
var current := Vector3(0, HEIGHT, 0)
var positions: Array[Vector3] = []
var steps := 0
var elapsed := 0.0
var held := false
var replay_requested := false
var proposed := Vector3.ZERO

func _ready() -> void:
    box(Vector3(0, 0.5, 0), Vector3(0.8, 1, 0.8))
    box(Vector3(0, 1.05, 0), Vector3(2.2, 0.1, 2.2))
    var corners: Array[Vector3] = [Vector3(-HALF, HEIGHT, -HALF), Vector3(HALF, HEIGHT, -HALF), Vector3(HALF, HEIGHT, HALF), Vector3(-HALF, HEIGHT, HALF)]
    for i in range(4):
        var edge = join(self, corners[i], corners[(i + 1) % 4])
        edge.material_override.albedo_color = Color(0.3, 0.3, 0.3)
    add_child(trail)
    point = PointBody.new()
    add_child(point)
    point.picked_up.connect(on_pickup)
    point.dropped.connect(on_drop)
    point.action_pressed.connect(on_action)
    box(Vector3(0, 1.95, -0.80), Vector3(1.5, 0.34, 0.05))
    status = label("", Vector3(0, 1.95, -0.75))
    label("HOLD: pause | RELEASE: start here\nTRIGGER + RELEASE: replay", Vector3(0, 0.86, 1.12))
    restart(origin)

func restart(at: Vector3) -> void:
    origin = Vector3(clampf(at.x, -HALF, HALF), HEIGHT, clampf(at.z, -HALF, HALF))
    current = origin
    point.position = current
    rng.seed = seed_value
    steps = 0
    elapsed = 0.0
    proposed = current
    positions.assign([current])
    for line in trail.get_children():
        trail.remove_child(line)
        line.queue_free()
    show_status()

func _process(delta: float) -> void:
    if held or steps >= max_steps:
        return
    elapsed += delta
    while elapsed >= seconds_per_step and steps < max_steps:
        elapsed -= seconds_per_step
        step()
    point.position = current

func _physics_process(_delta: float) -> void:
    if not held:
        point.position = current

func step() -> void:
    if steps >= max_steps:
        return
    var angle := rng.randf() * TAU
    var displacement := Vector3(cos(angle), 0, sin(angle)) * step_size
    proposed = current + displacement
    var accepted := reflect_endpoint(proposed)
    join(trail, current, accepted)
    current = accepted
    point.position = current
    positions.append(current)
    steps += 1
    show_status()

func reflect_endpoint(p: Vector3) -> Vector3:
    if p.x < -HALF: p.x = -2.0 * HALF - p.x
    if p.x > HALF: p.x = 2.0 * HALF - p.x
    if p.z < -HALF: p.z = -2.0 * HALF - p.z
    if p.z > HALF: p.z = 2.0 * HALF - p.z
    return Vector3(p.x, HEIGHT, p.z)

func on_pickup(_body: XRToolsPickable) -> void:
    held = true
    replay_requested = false
    show_status()

func on_action(_body: XRToolsPickable) -> void:
    if held:
        replay_requested = true
        show_status()

func on_drop(_body: XRToolsPickable) -> void:
    var start := origin if replay_requested else to_local(point.global_position)
    held = false
    replay_requested = false
    restart(start)

func show_status() -> void:
    var state := "WALKING" if steps < max_steps else "COMPLETE"
    if held: state = "REPLAY ON RELEASE" if replay_requested else "HELD / PAUSED"
    status.text = "Seed %d | %d / %d | %s\nx %.2f   z %.2f | %d positions" % [seed_value, steps, max_steps, state, current.x, current.z, positions.size()]

func join(parent: Node3D, a: Vector3, b: Vector3) -> MeshInstance3D:
    var line = LineSkin.new()
    parent.add_child(line)
    var displacement := b - a
    line.show_segment(a, displacement, displacement.length())
    return line

func box(at: Vector3, size: Vector3) -> void:
    var body := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    body.mesh = shape
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.88, 0.86, 0.82)
    body.material_override = finish
    body.position = at
    add_child(body)

func label(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    text.modulate = Color(0.12, 0.12, 0.12)
    text.outline_size = 0
    add_child(text)
    return text
