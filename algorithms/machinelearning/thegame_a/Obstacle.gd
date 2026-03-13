extends StaticBody3D
class_name Obstacle

# The Axiom Garden - Iteration 7: The Obstacle
# A barrier the plant cannot touch.

func _ready() -> void:
	add_to_group("obstacles")
	
	# Visual Debug (Red Box)
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mesh.material_override = mat
	add_child(mesh)
	
	# Collision Shape
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	add_child(shape)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

