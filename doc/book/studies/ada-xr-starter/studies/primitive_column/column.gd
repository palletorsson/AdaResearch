extends Node3D

const CircleSamples = preload("res://prepared/circle_samples.gd")
const ColumnSurface = preload("res://studies/primitive_column/column_surface.gd")

var profile: Array[float] = [0.50, 0.50, 0.32, 0.22, 0.32, 0.50, 0.50]
var height := 2.2
var sides := 8
var positions: Array[Vector3] = []
var surface := MeshInstance3D.new()

func column_positions(radii: Array[float], full_height: float, divisions: int) -> Array[Vector3]:
    var circle := CircleSamples.points_on_circle(divisions, 1.0)
    var step := full_height / (radii.size() - 1)
    var points: Array[Vector3] = []
    for i in range(radii.size()):
        for p in circle:
            points.append(Vector3(p.x * radii[i], i * step, p.y * radii[i]))
    return points

func _ready():
    # Supplied guards name this study's usable range before constructing a mesh.
    assert(profile.size() >= 2 and profile.size() <= 32, "Use 2 to 32 radii.")
    assert(height > 0.0 and height <= 2.5, "Use a height above zero and at most 2.5 metres in this room.")
    for radius in profile:
        assert(radius > 0.0 and radius <= 0.8, "Use radii above zero and at most 0.8 metres.")
    positions = column_positions(profile, height, sides)
    surface.mesh = ColumnSurface.make(positions, sides)
    surface.material_override = preload("res://studies/primitive_column/stone.tres")
    add_child(surface)
