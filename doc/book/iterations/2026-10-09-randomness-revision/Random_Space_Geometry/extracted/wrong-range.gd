extends Node3D

const PointBody = preload("point_body.gd")
const SIDE := 8

var sample_seed := 42
var frequency := 0.1
var cell_gap := 0.16
var records: Array[Dictionary] = []
var columns: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.fractal_type = FastNoiseLite.FRACTAL_NONE
    box(Vector3(3.6, 0.9, 2.2), Vector3(0, 0.45, 0), Color(0.34, 0.34, 0.34))
    box(Vector3(3.6, 0.75, 0.05), Vector3(0, 1.75, -1.07), Color(0.65, 0.65, 0.65))
    status = label("", Vector3(0, 1.75, -1.03), 27)
    label("INDEPENDENT                  PERLIN", Vector3(0, 0.97, 0.8), 27)
    label("REPLAY       FREQUENCY       NEXT SEED", Vector3(0, 0.93, 1.03), 23)
    point = PointBody.new()
    point.position = Vector3(0, 1.12, 1.0)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    records.clear()
    for z in range(SIDE):
        for x in range(SIDE):
            records.append({"at": Vector2i(x, z), "white": rng.randf(), "field": 0.0})
    sample_field()

func sample_field() -> void:
    noise.seed = sample_seed
    noise.frequency = frequency
    for record in records:
        var at: Vector2i = record.at
        record.field = noise.get_noise_2d(at.x, at.y)
    rebuild()

func rebuild() -> void:
    for column in columns:
        column.free()
    columns.clear()
    for side in range(2):
        var key := "white" if side == 0 else "field"
        var centre := -0.86 if side == 0 else 0.86
        for record in records:
            var at: Vector2i = record.at
            var height := maxf(float(record[key]) * 0.65, 0.01)
            var position := Vector3(
                centre + (at.x - 3.5) * cell_gap,
                0.9 + height / 2.0,
                (at.y - 3.5) * cell_gap
            )
            columns.append(box(Vector3(0.13, height, 0.13), position, Color(0.22, 0.22, 0.22)))
    status.text = "WHAT NEIGHBOURS SHARE\nseed %d | frequency %.2f | one layer\nmean neighbour gap: %.3f / %.3f" % [
        sample_seed, frequency, neighbour_gap("white"), neighbour_gap("field")
    ]

func neighbour_gap(key: String) -> float:
    var total := 0.0
    var pairs := 0
    for i in range(records.size()):
        var at: Vector2i = records[i].at
        if at.x < SIDE - 1:
            total += absf(float(records[i][key]) - float(records[i + 1][key]))
            pairs += 1
        if at.y < SIDE - 1:
            total += absf(float(records[i][key]) - float(records[i + SIDE][key]))
            pairs += 1
    return total / pairs if pairs > 0 else 0.0

func toggle_frequency() -> void:
    frequency = 0.3 if is_equal_approx(frequency, 0.1) else 0.1
    sample_field()

func next_seed() -> void:
    sample_seed += 1
    replay()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        replay()
    elif x < 0.4:
        toggle_frequency()
    else:
        next_seed()

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    view.material_override = material
    add_child(view)
    return view

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
