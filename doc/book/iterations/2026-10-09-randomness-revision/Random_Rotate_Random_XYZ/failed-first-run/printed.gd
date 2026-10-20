extends Node3D

const PointBody = preload("point_body.gd")
const TURN_AXIS := Vector3.BACK
@export var seed_value := 42
@export_range(1, 60) var step_count := 24
@export_range(1.0, 45.0) var limit_degrees := 20.0
@export_range(0.1, 5.0) var seconds_per_step := 0.8
var rng := RandomNumberGenerator.new()
var turns: Array[float] = []
var cursor := 0
var latest := 0.0
var total := 0.0
var elapsed := 0.0
var playing := false
var assigned: MeshInstance3D
var accumulated: MeshInstance3D
var status: Label3D
var point: XRToolsPickable

func _ready() -> void:
    for x in [-0.7, 0.7]:
        box(self, Vector3(x, 0.55, 0), Vector3(0.7, 1.1, 0.7), Color(0.88, 0.86, 0.82))
    assigned = cube(-0.7)
    accumulated = cube(0.7)
    label("LATEST ANGLE", Vector3(-0.7, 0.99, 0.4))
    label("SUM OF TURNS", Vector3(0.7, 0.99, 0.4))
    status = label("", Vector3(0, 2.3, 0))
    box(self, Vector3(0, 0.78, 0.8), Vector3(2.4, 0.05, 0.55), Color(0.88, 0.86, 0.82))
    label("REPLAY          STEP          PLAY / PAUSE", Vector3(0, 0.7, 1.1))
    point = PointBody.new()
    point.position = Vector3(0, 0.96, 0.8)
    add_child(point)
    point.action_pressed.connect(point_action)
    make_record()

func make_record() -> void:
    rng.seed = seed_value
    turns.clear()
    for i in range(step_count):
        turns.append(deg_to_rad(rng.randf_range(-limit_degrees, limit_degrees)))
    replay()

func replay() -> void:
    cursor = 0
    latest = 0.0
    total = 0.0
    elapsed = 0.0
    playing = false
    show_angles()

func step() -> void:
    if cursor >= turns.size():
        return
    latest = turns[cursor]
    total += latest
    cursor += 1
    if cursor == turns.size():
        playing = false
    show_angles()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed += delta
    while elapsed >= seconds_per_step and cursor < turns.size():
        elapsed -= seconds_per_step
        step()

func point_action() -> void:
    if point.position.x < -0.4:
        replay()
    elif point.position.x > 0.4:
        if cursor == turns.size():
            replay()
        playing = not playing
    else:
        playing = false
        elapsed = 0.0
        step()
    show_angles()

func show_angles() -> void:
    assigned.basis = Basis(TURN_AXIS, latest)
    accumulated.basis = Basis(TURN_AXIS, total)
    var state := "PLAYING" if playing else "PAUSED"
    if cursor == turns.size():
        state = "RECORD COMPLETE"
    status.text = "Seed %d | %d / %d | %s\nLatest %.1f deg | Sum %.1f deg" % [seed_value, cursor, turns.size(), state, rad_to_deg(latest), rad_to_deg(total)]

func cube(x: float) -> MeshInstance3D:
    var body := box(self, Vector3(x, 1.53, 0), Vector3.ONE * 0.6, Color(0.18, 0.18, 0.18))
    # An off-centre mark makes the cube's orientation distinguishable.
    box(body, Vector3(0.14, 0.23, 0.307), Vector3(0.22, 0.065, 0.025), Color(1.0, 0.35, 0.58))
    return body

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    body.material_override = material
    body.position = at
    parent.add_child(body)
    return body

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
