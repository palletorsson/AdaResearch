extends Node3D
class_name ContextSensitiveLTree

## Context-Sensitive L-System Tree
## Grows a tree that prunes branches when they encounter obstacles.
## Branches that would collide with obstacles are pruned (drawn as red stubs).

var lsystem: LSystem
var turtle: Turtle3D

@export var iterations: int = 5
@export var step_length: float = 0.12
@export var angle: float = 25.0

func _ready() -> void:
	# Setup Turtle
	turtle = Turtle3D.new()
	turtle.use_pink_palette = false
	add_child(turtle)
	turtle.branch_thickness = 0.012
	turtle.branch_color = Color(0.5, 0.35, 0.2)
	turtle.leaf_color = Color(0.25, 0.7, 0.3)

	# Setup L-System (Fractal Plant)
	lsystem = LSystem.create_fractal_plant()

	# Create obstacles
	_create_obstacles()

	# Wait for physics world to register collision shapes
	await get_tree().process_frame
	await get_tree().process_frame

	_generate_tree()
	_add_decorations()


func _create_obstacles() -> void:
	# Obstacles sized to interact with the tree's natural growth space
	var obstacle_data: Array[Dictionary] = [
		{"pos": Vector3(0.2, 0.25, 0.0), "size": Vector3(0.12, 0.35, 0.12)},
		{"pos": Vector3(-0.12, 0.45, 0.08), "size": Vector3(0.1, 0.2, 0.1)},
	]

	for data in obstacle_data:
		var body := StaticBody3D.new()
		var col_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = data["size"]
		col_shape.shape = box
		body.add_child(col_shape)

		# Semi-transparent violet tinted blocks
		var mesh_inst := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = data["size"]
		mesh_inst.mesh = box_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.5, 0.65, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)

		body.position = data["pos"]
		body.add_to_group("obstacle")
		add_child(body)


func _generate_tree() -> void:
	lsystem.reset()
	lsystem.generate_n(iterations)
	var sentence: String = lsystem.get_sentence()

	turtle.reset()
	turtle.branch_length = step_length
	turtle.angle = deg_to_rad(angle)

	_interpret_with_context(sentence)


func _interpret_with_context(instructions: String) -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

	var context_stack: Array[bool] = []
	var is_dead: bool = false

	for ch in instructions:
		match ch:
			"F":
				if is_dead:
					turtle.move_forward()
				else:
					var start: Vector3 = turtle.cursor_transform.origin
					var direction: Vector3 = turtle.cursor_transform.basis.y
					var end: Vector3 = start + direction * step_length

					var global_start: Vector3 = global_transform * start
					var global_end: Vector3 = global_transform * end

					var query := PhysicsRayQueryParameters3D.create(global_start, global_end)
					var result: Dictionary = space_state.intersect_ray(query)

					if not result.is_empty():
						is_dead = true
						var saved_color: Color = turtle.branch_color
						turtle.branch_color = Color(0.9, 0.2, 0.15)
						turtle.create_branch(start, start + (end - start) * 0.2)
						turtle.branch_color = saved_color
						turtle.cursor_transform.origin = end
					else:
						turtle.forward()

			"X":
				pass
			"+":
				turtle.turn_left()
			"-":
				turtle.turn_right()
			"&":
				turtle.pitch_down()
			"^":
				turtle.pitch_up()
			"\\":
				turtle.roll_counterclockwise()
			"/":
				turtle.roll_clockwise()
			"|":
				turtle.turn_left(180)
			"L":
				if not is_dead:
					turtle.create_leaf()
			"[":
				turtle.push_state()
				context_stack.append(is_dead)
			"]":
				turtle.pop_state()
				if not context_stack.is_empty():
					is_dead = context_stack.pop_back()


func _add_decorations() -> void:
	# Info label
	var label := Label3D.new()
	label.text = "Context-Sensitive Tree\nIter: %d | Pruned by obstacles" % iterations
	label.font_size = 48
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.9, 0)
	label.modulate = Color(0.9, 0.9, 0.95)
	add_child(label)

	# Pedestal
	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.45
	cyl.bottom_radius = 0.5
	cyl.height = 0.04
	pedestal.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.22)
	mat.roughness = 0.85
	pedestal.material_override = mat
	add_child(pedestal)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("iterations"):
		iterations = int(config_data["iterations"])
	if config_data.has("angle"):
		angle = float(config_data["angle"])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

