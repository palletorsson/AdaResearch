extends Node3D

const PointBody = preload("point_body.gd")
@export var sample_count := 16
@export var seed_value := 42
var palette: Array[Color] = [Color(0.08, 0.08, 0.1), Color(0.9, 0.4, 0.6),
    Color(0.25, 0.65, 0.7), Color(0.95, 0.8, 0.3)]
var rng := RandomNumberGenerator.new()
var record: Array[int] = []
var shown: Array[int] = []
var sorted_view := false
var rows: Array = []
var bars: Array = []
var captions: Array = []
var point: RigidBody3D
var title: Label3D
var view_label: Label3D

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func box_at(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var cube := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    cube.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    cube.material_override = material
    cube.position = at
    add_child(cube)
    return cube

func _ready() -> void:
    assert(sample_count > 0 and sample_count <= 64 and palette.size() > 0)
    for row in range(2):
        var cubes: Array = []
        for i in range(sample_count):
            var x := (float(i) + 0.5) / sample_count * 3.2 - 1.6
            cubes.append(box_at(Vector3(x, 2.5 - row * 0.45, 0),
                Vector3(2.9 / sample_count, 0.16, 0.12), Color.WHITE))
        rows.append(cubes)
    for symbol in range(palette.size()):
        var x := (float(symbol) + 0.5) / palette.size() * 3.2 - 1.6
        bars.append(box_at(Vector3(x, 0.95, 0), Vector3(2.2 / palette.size(), 1, 0.12), palette[symbol]))
        captions.append(text_at("", Vector3(x, 0.8, 0)))
    title = text_at("", Vector3(0, 3.05, 0), 30)
    text_at("ORIGINAL: as drawn", Vector3(0, 2.72, 0))
    view_label = text_at("", Vector3(0, 2.27, 0))
    text_at("Bars: fraction of all draws | full height = 100%", Vector3(0, 1.77, 0), 22)
    point = PointBody.new()
    point.position = Vector3(-1.2, 0.9, 0.75)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-1.2, 0.5, 0.75))
    text_at("SORT / DRAWN", Vector3(0, 0.5, 0.75))
    text_at("NEXT SEED", Vector3(1.2, 0.5, 0.75))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.27, 0.75), 22)
    new_sample()

func new_sample() -> void:
    rng.seed = seed_value
    record.clear()
    for i in range(sample_count):
        record.append(rng.randi_range(0, palette.size() - 1))
    draw_state()

func counts_of(values: Array[int]) -> Array[int]:
    var counts: Array[int] = []
    counts.resize(palette.size())
    counts.fill(0)
    for symbol in values:
        assert(symbol >= 0 and symbol < counts.size())
        counts[symbol] += 1
    return counts

func entropy_of(counts: Array[int]) -> float:
    var total := 0
    for count in counts:
        total += count
    assert(total > 0)
    var entropy := 0.0
    for count in counts:
        if count > 0:
            var p := float(count) / counts.size()
            entropy -= p * log(p) / log(2.0)
    return entropy

func neighbour_changes(values: Array[int]) -> int:
    var changes := 0
    for i in range(1, values.size()):
        if values[i] != values[i - 1]:
            changes += 1
    return changes

func draw_state() -> void:
    shown = record.duplicate()
    if sorted_view:
        shown.sort()
    var counts := counts_of(shown)
    for i in range(sample_count):
        rows[0][i].material_override.albedo_color = palette[record[i]]
        rows[1][i].material_override.albedo_color = palette[shown[i]]
    for symbol in range(palette.size()):
        var fraction := float(counts[symbol]) / record.size()
        bars[symbol].visible = counts[symbol] > 0
        bars[symbol].scale.y = maxf(0.001, 0.7 * fraction)
        bars[symbol].position.y = 0.95 + 0.35 * fraction
        captions[symbol].text = "%d: %d" % [symbol, counts[symbol]]
    title.text = "Seed %d | N %d | H %.3f bits/symbol\nOriginal neighbours %d | shown %d" % [
        seed_value, record.size(), entropy_of(counts), neighbour_changes(record), neighbour_changes(shown)]
    view_label.text = "COPY: sorted" if sorted_view else "COPY: as drawn"

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
        new_sample()
    elif point.position.x >= -0.4:
        sorted_view = not sorted_view
        draw_state()
    else:
        new_sample()
