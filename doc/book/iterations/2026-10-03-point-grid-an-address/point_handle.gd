extends XRToolsPickable
## Supplied hold: Point One's mesh and collider, with XR Tools pickup.
## Remains in the shared study parent and stays where it is released.

func _init():
    freeze = true
    release_mode = ReleaseMode.FROZEN
    collision_layer = 4
    collision_mask = 0
    var sphere := SphereMesh.new()
    sphere.radius = 0.07
    sphere.height = 0.14
    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("edcfdb")
    material.roughness = 0.35
    marker.material_override = material
    add_child(marker)
    var shape := SphereShape3D.new()
    shape.radius = 0.07
    var collider := CollisionShape3D.new()
    collider.shape = shape
    add_child(collider)
