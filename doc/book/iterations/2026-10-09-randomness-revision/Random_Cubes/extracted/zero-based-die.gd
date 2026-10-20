extends Node3D

const PointBody = preload("point_body.gd")
const UNIT := 0.065
const INK := Color(0.07, 0.07, 0.09)
const PINK := Color(0.85, 0.25, 0.46)
const BLUE := Color(0.18, 0.63, 0.75)
@export var seed_value := 42
@export var max_draws := 5
var rng := RandomNumberGenerator.new()
var history: Array[int] = []
var total := 0
var closed := false
var limited := false
var units: Array[MeshInstance3D] = []
var joins: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D

func box_at(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var box := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    box.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    box.material_override = material
    box.position = at
    add_child(box)
    return box

func text_at(words: String, at: Vector3, size: int = 25) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func _ready() -> void:
    assert(max_draws >= 1 and max_draws <= 8)
    box_at(Vector3(0.65, 0.15, 0), Vector3(0.55, 0.3, 0.55), Color(0.88, 0.87, 0.83))
    for i in range(max_draws * 6):
        units.append(box_at(Vector3(0.65, 0.3 + (i + 0.5) * UNIT, 0),
            Vector3(0.34, UNIT - 0.004, 0.34), PINK))
    for i in range(max_draws):
        joins.append(box_at(Vector3.ZERO, Vector3(0.36, 0.004, 0.36), INK))
    var ceiling := 0.3 + max_draws * 6 * UNIT
    box_at(Vector3(0.65, ceiling + 0.04, 0), Vector3(0.56, 0.02, 0.56), Color(0.9, 0.65, 0.2))
    text_at("%d-DRAW DISPLAY LIMIT" % max_draws, Vector3(0.65, ceiling + 0.17, 0), 21)
    box_at(Vector3(-0.65, 1.5, -0.03), Vector3(1.2, 0.85, 0.05), INK)
    status = text_at("", Vector3(-0.65, 1.5, 0.01))
    point = PointBody.new()
    point.position = Vector3(-0.85, 0.85, 0.7)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = INK
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-0.85, 0.5, 0.7))
    text_at("DRAW", Vector3(0, 0.5, 0.7))
    text_at("NEXT SEED", Vector3(0.85, 0.5, 0.7))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.26, 0.7), 20)
    reset_run()

func continues(face: int) -> bool:
    return face == 6

func reset_run() -> void:
    rng.seed = seed_value
    history.clear()
    total = 0
    closed = false
    limited = false
    draw_record()

func draw_face() -> int:
    if closed or limited:
        return 0
    var face := rng.randi_range(0, 5)
    accept_face(face)
    return face

func accept_face(face: int) -> bool:
    if closed or limited or face < 1 or face > 6:
        return false
    history.append(face)
    total += face
    closed = not continues(face)
    limited = not closed and history.size() >= max_draws
    draw_record()
    return true

func draw_record() -> void:
    for unit in units:
        unit.visible = false
    for join in joins:
        join.visible = false
    var offset := 0
    var terms := PackedStringArray()
    for i in range(history.size()):
        var face := history[i]
        terms.append(str(face))
        joins[i].position = Vector3(0.65, 0.3 + offset * UNIT, 0)
        joins[i].visible = true
        for j in range(face):
            units[offset + j].visible = true
            units[offset + j].material_override.albedo_color = PINK if i % 2 == 0 else BLUE
        offset += face
    var condition := "DRAW TO BEGIN" if history.is_empty() else "CONTINUE / DRAW AGAIN"
    if closed:
        condition = "CLOSED / REPLAY TO BEGIN"
    elif limited:
        condition = "DISPLAY LIMIT / UNFINISHED"
    var equation := "?" if history.is_empty() else " + ".join(terms) + " = " + str(total)
    status.text = "CODED DRAW / Seed %d\n%d of %d draws\n%s\n%s" % [
        seed_value, history.size(), max_draws, equation, condition]

func activate(_body: Variant = null) -> void:
    if point.position.x < -0.4:
        reset_run()
    elif point.position.x > 0.4:
        seed_value += 1
        reset_run()
    else:
        draw_face()
