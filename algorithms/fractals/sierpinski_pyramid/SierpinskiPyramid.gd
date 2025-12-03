extends Node3D

var bodies = []
var max_level = 3
var size = 5.0

var pyramid_material: ShaderMaterial

func _ready():
	_setup_material()
	generate_sierpinski(Vector3(0, 0, 0), max_level, size)
	# Unfreeze after a delay
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_Timer_timeout)

func _setup_material():
	var shader = preload("res://algorithms/fractals/sierpinski_pyramid/pyramid_shader.gdshader")
	pyramid_material = ShaderMaterial.new()
	pyramid_material.shader = shader

func generate_sierpinski(position, level, current_size):
	if level == 0:
		var rigid_body = RigidBody3D.new()
		rigid_body.position = position
		rigid_body.freeze = true
		
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(current_size * 2, current_size * 2, current_size * 2)
		box_mesh.material = pyramid_material # Apply the shader material
		mesh_instance.mesh = box_mesh
		
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(current_size * 2, current_size * 2, current_size * 2)
		collision_shape.shape = box_shape
		
		rigid_body.add_child(mesh_instance)
		rigid_body.add_child(collision_shape)
		add_child(rigid_body)
		bodies.append(rigid_body)
		return

	var new_size = current_size / 2.0
	var new_level = level - 1

	# The 4 vertices of a tetrahedron
	var positions = [
		Vector3(1, 1, 1),
		Vector3(1, -1, -1),
		Vector3(-1, 1, -1),
		Vector3(-1, -1, 1)
	]

	for i in range(4):
		var new_pos = position + positions[i] * new_size
		generate_sierpinski(new_pos, new_level, new_size)

func _on_Timer_timeout():
	for body in bodies:
		body.freeze = false
