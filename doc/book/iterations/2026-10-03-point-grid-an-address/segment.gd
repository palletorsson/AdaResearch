extends MeshInstance3D
## Supplied drawing: one finite cylinder, no physics body.
## Inputs are two positions in this node's parent frame. Thickness is authored.

func _init():
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.012
    cylinder.bottom_radius = 0.012
    cylinder.height = 1.0
    mesh = cylinder
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("f2eee4")
    material.roughness = 0.45
    material_override = material

func show_between(a: Vector3, b: Vector3):
    var displacement := b - a
    var distance := displacement.length()
    visible = distance > 0.0001
    if not visible:
        return
    position = (a + b) * 0.5
    mesh.height = distance
    quaternion = Quaternion(Vector3.UP, displacement / distance)
