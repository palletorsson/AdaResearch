extends XRToolsPickable
# The earlier grabbable body's construction, now with a cube mesh and boundary.
func _init() -> void:
    collision_layer = 4
    collision_mask = 196615
    mass = 1.0
    release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    var surface := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3.ONE * 0.2
    surface.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("ee84b8")
    surface.material_override = material
    add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = mesh.size
    boundary.shape = shape
    add_child(boundary)
