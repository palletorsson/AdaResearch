# Supplied pane: one rendered sheet, one persistent physical boundary.
extends StaticBody3D

var surface: StandardMaterial3D
var boundary: CollisionShape3D

func _ready() -> void:
    var view := MeshInstance3D.new()
    var sheet := QuadMesh.new()
    sheet.size = Vector2(2, 2.5)
    view.mesh = sheet
    surface = StandardMaterial3D.new()
    surface.cull_mode = BaseMaterial3D.CULL_DISABLED
    surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = surface
    add_child(view)
    boundary = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2, 2.5, 0.04)
    boundary.shape = shape
    add_child(boundary)
