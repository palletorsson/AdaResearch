extends Node3D

const PointBody = preload("point_body.gd")
const LIMIT := 256
const BATCH := 16

var sample_seed := 42
var x_span := 0.2
var samples: Array[Vector2] = []
var estimates: Array[float] = []
var inside := 0
var marks: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(2.8, 0.65, 0.8), Vector3(0, 0.325, 0.0), Color(0.25, 0.25, 0.25))
    box(Vector3(2.8, 2.1, 0.05), Vector3(0, 1.6, 0), Color(0.88, 0.86, 0.81))
    box(Vector3(1.2, 1.2, 0.01), Vector3(-0.65, 1.7, 0.03), Color(0.98, 0.97, 0.93))
    for i in range(64):
        var a := TAU * i / 64.0
        var b := TAU * (i + 1) / 64.0
        line(Vector3(-0.65 + cos(a) * 0.6, 1.7 + sin(a) * 0.6, 0.045),
            Vector3(-0.65 + cos(b) * 0.6, 1.7 + sin(b) * 0.6, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1, 0.045), Vector3(1.25, 1.1, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1, 0.045), Vector3(0.15, 2.1, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1 + PI * 0.25, 0.045), Vector3(1.25, 1.1 + PI * 0.25, 0.045), Color(0.65, 0.38, 0.05))
    label("ESTIMATE 0..4\nstep 1..%d | gold: pi" % LIMIT, Vector3(0.7, 2.3, 0.05), 22)
    status = label("", Vector3(0, 2.52, 0.05), 25)
    label("REPLAY           ONE           BATCH", Vector3(0, 0.83, 0.43), 24)
    point = PointBody.new()
    point.position = Vector3(0, 1.04, 0.55)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    samples.clear()
    estimates.clear()
    inside = 0
    for mark in marks:
        mark.free()
    marks.clear()
    update_status()

func add_samples(amount: int) -> void:
    for _i in range(mini(amount, LIMIT - samples.size())):
        var p := Vector2(rng.randf_range(-x_span, x_span), rng.randf_range(-1.0, 1.0))
        samples.append(p)
        var hit := p.length_squared() <= 1.0
        if hit:
            inside += 1
        var estimate := 4.0 * inside / samples.size()
        estimates.append(estimate)
        var colour := Color(0.04, 0.42, 0.37) if hit else Color(0.8, 0.12, 0.23)
        marks.append(dot(Vector3(-0.65 + p.x * 0.6, 1.7 + p.y * 0.6, 0.06), colour))
        var x := 0.15 + (samples.size() - 1) * 1.1 / (LIMIT - 1)
        marks.append(dot(Vector3(x, 1.1 + estimate * 0.25, 0.06), Color(0.08, 0.08, 0.08)))
    update_status()

func update_status() -> void:
    var value := "--" if estimates.is_empty() else "%.4f" % estimates[-1]
    status.text = "seed %d | %d / %d inside | estimate %s" % [sample_seed, inside, samples.size(), value]

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        replay()
    elif x < 0.4:
        add_samples(1)
    else:
        add_samples(BATCH)

func material(colour: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = colour
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func dot(at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.009
    mesh.height = 0.018
    mesh.radial_segments = 8
    mesh.rings = 4
    view.mesh = mesh
    view.position = at
    view.material_override = material(colour)
    add_child(view)
    return view

func line(a: Vector3, b: Vector3, colour: Color) -> void:
    var view := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.003
    mesh.bottom_radius = 0.003
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 6
    view.mesh = mesh
    view.position = (a + b) / 2.0
    view.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
    view.material_override = material(colour)
    add_child(view)

func box(size: Vector3, at: Vector3, colour: Color) -> void:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    view.material_override = material(colour)
    add_child(view)

func label(text: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = text
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
