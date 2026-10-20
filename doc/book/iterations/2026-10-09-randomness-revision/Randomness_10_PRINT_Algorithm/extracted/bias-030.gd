extends Node3D

const PointBody = preload("point_body.gd")
const INK := Color(0.07, 0.07, 0.09)
const PINK := Color(0.72, 0.12, 0.34)
@export var columns := 8
@export var rows := 8
@export var cell_size := 0.22
@export var seed_value := 42
@export var probability := 0.3
var rng := RandomNumberGenerator.new()
var samples: Array[float] = []
var marks: Array[bool] = []
var rods: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func box_at(at: Vector3, size: Vector3, colour: Color) -> void:
    var box := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    box.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    box.material_override = material
    box.position = at
    add_child(box)

func _ready() -> void:
    assert(columns > 0 and rows > 0 and columns <= 16 and rows <= 16)
    assert(cell_size > 0.0 and probability >= 0.0 and probability <= 1.0)
    var width := columns * cell_size
    var height := rows * cell_size
    box_at(Vector3(0, 1.9, -0.045), Vector3(width + 0.12, height + 0.12, 0.05), Color(0.88, 0.87, 0.83))
    for column in range(columns + 1):
        box_at(Vector3(column * cell_size - width / 2, 1.9, -0.01),
            Vector3(0.004, height, 0.004), Color(0.5, 0.5, 0.5))
    for row in range(rows + 1):
        box_at(Vector3(0, 1.9 + height / 2 - row * cell_size, -0.01),
            Vector3(width, 0.004, 0.004), Color(0.5, 0.5, 0.5))
    for row in range(rows):
        for column in range(columns):
            var rod := MeshInstance3D.new()
            var mesh := CylinderMesh.new()
            mesh.top_radius = 0.009
            mesh.bottom_radius = 0.009
            mesh.height = cell_size * sqrt(2.0)
            mesh.radial_segments = 8
            rod.mesh = mesh
            rod.material_override = StandardMaterial3D.new()
            rod.position = Vector3((column + 0.5) * cell_size - width / 2,
                1.9 + height / 2 - (row + 0.5) * cell_size, 0)
            add_child(rod)
            rods.append(rod)
    status = text_at("", Vector3(0, 2.17 + height / 2, 0), 25)
    point = PointBody.new()
    point.position = Vector3(-0.75, 0.85, 0.65)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = INK
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-0.75, 0.5, 0.65))
    text_at("BIAS + 0.25", Vector3(0, 0.5, 0.65))
    text_at("NEXT SEED", Vector3(0.75, 0.5, 0.65))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.26, 0.65), 20)
    build_pattern()

func choose_backslash(sample: float) -> bool:
    return probability >= 1.0 or sample < probability

func build_pattern() -> void:
    rng.seed = seed_value
    samples.clear()
    marks.clear()
    for i in range(rods.size()):
        var sample := rng.randf()
        samples.append(sample)
        marks.append(choose_backslash(sample))
    draw_pattern()

func draw_pattern() -> void:
    var backslashes := 0
    for i in range(marks.size()):
        rods[i].rotation.z = PI / 4 if marks[i] else -PI / 4
        rods[i].material_override.albedo_color = PINK if marks[i] else INK
        if marks[i]:
            backslashes += 1
    status.text = "Seed %d | P(backslash) %.2f\nActual: %d of %d | expected mean: %.2f" % [
        seed_value, probability, backslashes, marks.size(), probability * marks.size()]

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
    elif point.position.x >= -0.4:
        probability += 0.25
        if probability > 1.0:
            probability = 0.0
    build_pattern()
