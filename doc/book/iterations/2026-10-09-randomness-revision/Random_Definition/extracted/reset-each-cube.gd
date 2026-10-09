extends Node3D

const PointBody = preload("point_body.gd")
@export var side := 4
@export var seed_value := 42
var discard_first := false
var rng := RandomNumberGenerator.new()
var grids: Array = []
var samples: Array = []
var point: RigidBody3D
var label := Label3D.new()

func text_at(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    add_child(text)
    return text

func _ready() -> void:
    assert(side > 0 and side <= 8)
    for panel in range(2):
        var cubes: Array[MeshInstance3D] = []
        for row in range(side):
            for column in range(side):
                var cube := MeshInstance3D.new()
                var box := BoxMesh.new()
                box.size = Vector3.ONE * (0.9 / side)
                cube.mesh = box
                cube.material_override = StandardMaterial3D.new()
                cube.position = Vector3(
                    (panel - 0.5) * 1.35 + (column + 0.5) / side - 0.5,
                    1.1 + (row + 0.5) / side, 0)
                add_child(cube)
                cubes.append(cube)
        grids.append(cubes)
    point = PointBody.new()
    point.position = Vector3(-0.8, 0.95, 0.7)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-0.8, 0.65, 0.7))
    text_at("+1 DRAW", Vector3(0, 0.65, 0.7))
    text_at("NEXT SEED", Vector3(0.8, 0.65, 0.7))
    text_at("Hold the point above a label; press trigger", Vector3(0, 0.4, 0.7))
    label.position = Vector3(0, 2.35, 0)
    label.font_size = 30
    label.pixel_size = 0.0025
    add_child(label)
    replay()

func colour_grid(cubes: Array, skip: bool) -> Array[Color]:
    rng.seed = seed_value
    if skip:
        rng.randf()
    var colours: Array[Color] = []
    for cube in cubes:
        rng.seed = seed_value
        var a := rng.randf()
        var b := rng.randf()
        var c := rng.randf()
        var colour := Color(a, b, c)
        cube.material_override.albedo_color = colour
        colours.append(colour)
    return colours

func replay() -> void:
    samples = [colour_grid(grids[0], false), colour_grid(grids[1], discard_first)]
    var draws := side * side * 3
    label.text = "Seed %d | LEFT %d draws | RIGHT %d draws\n%s" % [
        seed_value, draws, draws + int(discard_first),
        "right discards its first draw" if discard_first else "same procedure twice"]

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
    elif point.position.x >= -0.4:
        discard_first = not discard_first
    replay()
