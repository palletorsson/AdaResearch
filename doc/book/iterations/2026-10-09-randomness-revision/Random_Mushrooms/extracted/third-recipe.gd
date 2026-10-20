extends Node3D

const PointBody = preload("point_body.gd")

var population_seed := 42
var count := 12
var size_low := 0.7
var size_high := 1.3
var vary_size := true
var recipes: Array[Dictionary] = [
    {"cap": 0.2, "stem": 0.15, "colour": Color(0.8, 0.6, 0.4)},
    {"cap": 0.15, "stem": 0.1, "colour": Color(0.8, 0.2, 0.2)},
    {"cap": 0.12, "stem": 0.35, "colour": Color(0.9, 0.9, 0.8)}
]
var records: Array[Dictionary] = []
var bodies: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    var table := BoxMesh.new()
    table.size = Vector3(3.2, 0.9, 2.3)
    surface(self, table, Vector3(0, 0.45, 0), Color(0.82, 0.81, 0.76))
    label("REPLAY          SIZE          NEXT SEED", Vector3(0, 0.94, 1.02), 25)
    var board := BoxMesh.new()
    board.size = Vector3(3.2, 0.85, 0.05)
    surface(self, board, Vector3(0, 1.7, -1.12), Color(0.94, 0.93, 0.88))
    status = label("", Vector3(0, 1.7, -1.08), 29)
    point = PointBody.new()
    point.position = Vector3(0, 1.12, 1.0)
    add_child(point)
    point.action_pressed.connect(use_point)
    regrow()

func regrow() -> void:
    rng.seed = population_seed
    records.clear()
    for i in range(clampi(count, 0, 12)):
        var kind := rng.randi_range(0, recipes.size() - 1)
        var yaw := rng.randf() * TAU
        var size := lerpf(size_low, size_high, rng.randf())
        records.append({
            "kind": kind,
            "position": Vector3((i % 4 - 1.5) * 0.7, 0.9, (i / 4 - 1) * 0.65),
            "yaw": yaw,
            "size": size
        })
    rebuild()

func rebuild() -> void:
    for body in bodies:
        body.free()
    bodies.clear()
    for record in records:
        var body := make_mushroom(record.kind)
        add_child(body)
        body.position = record.position
        body.rotation.y = record.yaw
        bodies.append(body)
    apply_sizes()

func make_mushroom(kind: int) -> Node3D:
    var recipe: Dictionary = recipes[kind]
    var body := Node3D.new()
    var stem := CylinderMesh.new()
    stem.top_radius = recipe.cap * 0.2
    stem.bottom_radius = recipe.cap * 0.25
    stem.height = recipe.stem
    stem.radial_segments = 8
    surface(body, stem, Vector3(0, recipe.stem / 2, 0), recipe.colour.lightened(0.3))
    var cap := SphereMesh.new()
    cap.radius = recipe.cap
    cap.height = recipe.cap * 1.2
    cap.radial_segments = 16
    cap.rings = 8
    var top := surface(body, cap, Vector3(0, recipe.stem, 0), recipe.colour)
    top.scale.y = 0.5
    return body

func apply_sizes() -> void:
    for i in range(bodies.size()):
        var size: float = records[i].size if vary_size else 1.0
        bodies[i].scale = Vector3.ONE * size
    status.text = "A POPULATION KEPT\nseed %d | %d bodies | %d recipes\n%s" % [
        population_seed, records.size(), recipes.size(),
        "sampled scale" if vary_size else "scale 1 | recipe sizes kept"
    ]

func toggle_size() -> void:
    vary_size = not vary_size
    apply_sizes()

func next_seed() -> void:
    population_seed += 1
    regrow()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        regrow()
    elif x < 0.4:
        toggle_size()
    else:
        next_seed()

func surface(parent: Node3D, mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    view.mesh = mesh
    view.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    view.material_override = material
    parent.add_child(view)
    return view

func label(text: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = text
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.08, 0.08, 0.09)
    view.outline_size = 0
    add_child(view)
    return view
