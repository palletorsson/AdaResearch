extends Node3D

const PointBody = preload("point_body.gd")
const AMBER := Color(1.0, 0.68, 0.18)
const GREY := Color(0.28, 0.35, 0.42)
@export var side := 8
@export var seed_value := 42
var rng := RandomNumberGenerator.new()
var candidates: Array[int] = []
var history: Array[int] = []
var cubes: Array[MeshInstance3D] = []
var slots: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D
var last_offset := -1
var last_address := -1

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
    assert(side >= 2 and side <= 16)
    var pitch := 2.0 / side
    for row in range(side):
        for column in range(side):
            var at := Vector3((column + 0.5) * pitch - 1.0, 0.976 + pitch * 0.36,
                (row + 0.5) * pitch - 1.0)
            cubes.append(box_at(at, Vector3.ONE * pitch * 0.72, GREY))
            slots.append(box_at(Vector3(at.x, 0.96, at.z),
                Vector3(pitch * 0.88, 0.015, pitch * 0.88), Color(0.65, 0.65, 0.65)))
    for i in range(side):
        var across := (i + 0.5) * pitch - 1.0
        var column_label := text_at(str(i), Vector3(across, 0.99, 1.12), 20)
        column_label.rotation_degrees.x = -90
        var row_label := text_at(str(i), Vector3(-1.12, 0.99, across), 20)
        row_label.rotation_degrees.x = -90
    box_at(Vector3(0, 0.47, 0), Vector3(2.4, 0.93, 2.4), Color(0.09, 0.1, 0.12))
    status = text_at("", Vector3(0, 1.9, -1.0), 26)
    point = PointBody.new()
    point.position = Vector3(0, 1.1, 1.45)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("RESET", Vector3(-0.9, 0.65, 1.45))
    text_at("REMOVE ONE", Vector3(0, 0.65, 1.45))
    text_at("NEXT SEED", Vector3(0.9, 0.65, 1.45))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.38, 1.45), 22)
    reset_run()

func eligible(column: int, row: int) -> bool:
    return column == 3

func reset_run() -> void:
    rng.seed = seed_value
    candidates.clear()
    history.clear()
    last_offset = -1
    last_address = -1
    for address in range(cubes.size()):
        var column := address % side
        var row := floori(float(address) / side)
        var allowed := eligible(column, row)
        cubes[address].visible = true
        cubes[address].material_override.albedo_color = AMBER if allowed else GREY
        if allowed:
            candidates.append(address)
    show_status()

func remove_one() -> int:
    if candidates.is_empty():
        return -1
    last_offset = rng.randi_range(0, candidates.size() - 1)
    last_address = candidates[last_offset]
    cubes[last_address].visible = false
    candidates.remove_at(last_offset)
    history.append(last_address)
    show_status()
    return last_address

func show_status() -> void:
    status.text = "Seed %d | eligible at start %d\nRemaining %d | removed %d" % [
        seed_value, candidates.size() + history.size(), candidates.size(), history.size()]
    if last_address >= 0:
        status.text += "\nOffset %d chose address %d (column %d, row %d)" % [
            last_offset, last_address, last_address % side, floori(float(last_address) / side)]
    if candidates.is_empty():
        status.text += "\nNo eligible cubes remain. RESET restores the set."

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
        reset_run()
    elif point.position.x >= -0.4:
        remove_one()
    else:
        reset_run()
