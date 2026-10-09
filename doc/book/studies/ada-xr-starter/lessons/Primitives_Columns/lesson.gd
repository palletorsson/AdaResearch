extends Node3D
const Circle = preload("circle_samples.gd")
const ColumnSurface = preload("column_surface.gd")
const PROFILE: Array[float] = [0.35, 0.35, 0.18, 0.25, 0.4, 0.4]
const HEIGHT := 2.2

func _ready() -> void:
    var choices := [4, 6, 8, 12, 16]
    for i in range(choices.size()):
        var column := MeshInstance3D.new()
        var points := column_positions(PROFILE, HEIGHT, choices[i])
        column.mesh = ColumnSurface.make(points, choices[i])
        column.position.x = (i - 2) * 1.0
        var finish := StandardMaterial3D.new()
        finish.albedo_color = Color(0.92, 0.91, 0.87)
        finish.roughness = 0.7
        column.material_override = finish
        add_child(column)

func column_positions(profile: Array[float], height: float, sides: int) -> Array[Vector3]:
    assert(profile.size() >= 2 and height > 0.0 and sides >= 3)
    var result: Array[Vector3] = []
    for ring in range(profile.size()):
        var y := height * ring / (profile.size() - 1)
        for point in Circle.make(sides, profile[ring]):
            result.append(point + Vector3(0, y, 0))
    return result
