extends MeshInstance3D
## Supplied visible body, created entirely in code. No collider or collection.
## The corner mark lets a learner follow a particular face as the cube turns.

func _init():
    var box := BoxMesh.new()
    box.size = Vector3.ONE * 0.6
    mesh = box
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color("e3e3e3")
    stone.roughness = 0.7
    material_override = stone
    var mark := MeshInstance3D.new()
    var patch := BoxMesh.new()
    patch.size = Vector3(0.09, 0.09, 0.006)
    mark.mesh = patch
    mark.position = Vector3(0.16, 0.16, 0.302)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color("242424")
    ink.roughness = 0.9
    mark.material_override = ink
    add_child(mark)
