extends Node3D

# Recursive Chair - True subdivision-based chair construction
# Starts with one cube, subdivides it, keeps some parts, removes others,
# then recursively subdivides remaining parts with non-uniform scaling

@export var chair_size: float = 1.5
@export var show_animation: bool = true
@export var step_delay: float = 0.4

# Colors for different generations - light plastic look
var generation_colors: Array[Color] = [
	Color(0.85, 0.85, 0.9, 1.0),   # Gen 0 - Light gray plastic (seat)
	Color(0.75, 0.8, 0.85, 1.0),   # Gen 1 - Slightly darker
	Color(0.65, 0.7, 0.75, 1.0),   # Gen 2 - Medium gray (legs)
	Color(0.55, 0.6, 0.65, 1.0),   # Gen 3 - Darker accent
	Color(0.45, 0.5, 0.55, 1.0),   # Gen 4 - Darkest (details)
]

var all_cubes: Array[Dictionary] = []  # {node, generation, role}
var step: int = 0
var timer: float = 0.0
var is_animating: bool = false


func _ready() -> void:
	if show_animation:
		is_animating = true
		_step_0_initial_cube()
	else:
		_build_instant()


func _process(delta: float) -> void:
	if not is_animating:
		return

	timer += delta
	if timer >= step_delay:
		timer = 0.0
		step += 1
		_execute_step(step)


func _execute_step(s: int) -> void:
	match s:
		1: _step_1_first_subdivision()
		2: _step_2_shape_seat()
		3: _step_3_create_legs()
		4: _step_4_create_back()
		5: _step_5_add_details()
		_:
			is_animating = false
			print("Recursive chair complete! Total parts: %d" % all_cubes.size())


func _build_instant() -> void:
	_step_0_initial_cube()
	_step_1_first_subdivision()
	_step_2_shape_seat()
	_step_3_create_legs()
	_step_4_create_back()
	_step_5_add_details()


func _step_0_initial_cube() -> void:
	# Create the initial cube that will become the chair
	_create_cube(Vector3(0, chair_size * 0.5, 0), Vector3(chair_size, chair_size, chair_size), 0, "base")
	print("Step 0: Initial cube")


func _step_1_first_subdivision() -> void:
	# Subdivide into 3x3x3 = 27 parts (like a Rubik's cube)
	# Remove original, create grid
	var base = _find_cubes_by_role("base")
	if base.is_empty():
		return

	var base_cube = base[0]
	var center = base_cube.node.position
	var size = chair_size / 3.0

	# Remove original
	_remove_cube(base_cube)

	# Create 3x3x3 grid, but we'll selectively keep parts
	# Bottom layer (y=0): legs corners, empty middle
	# Middle layer (y=1): seat
	# Top layer (y=2): back (only back row)

	for y in range(3):
		for x in range(3):
			for z in range(3):
				var offset = Vector3(
					(x - 1) * size,
					(y - 1) * size + chair_size * 0.5,
					(z - 1) * size
				)
				var pos = center + offset

				# Determine role based on position
				var role = "remove"

				if y == 0:  # Bottom layer - legs
					if (x == 0 or x == 2) and (z == 0 or z == 2):
						role = "leg_top"
				elif y == 1:  # Middle layer - seat
					role = "seat"
				elif y == 2:  # Top layer - back
					if z == 2:  # Back row only
						role = "back"

				if role != "remove":
					_create_cube(pos, Vector3(size * 0.95, size * 0.95, size * 0.95), 1, role)

	print("Step 1: Subdivided into chair shape")


func _step_2_shape_seat() -> void:
	# Flatten the seat cubes - make thinner for plastic look
	var seats = _find_cubes_by_role("seat")
	for cube_data in seats:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Flatten the seat - thinner for plastic
				box.size.y *= 0.15
				node.position.y -= chair_size / 3.0 * 0.42

	print("Step 2: Shaped seat (thin plastic)")


func _step_3_create_legs() -> void:
	# Extend the leg cubes downward - thinner for plastic
	var legs = _find_cubes_by_role("leg_top")
	for cube_data in legs:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Make legs taller and thinner - slim plastic legs
				var old_height = box.size.y
				box.size.x *= 0.4
				box.size.z *= 0.4
				box.size.y *= 2.5
				node.position.y -= old_height * 0.75

				# Update color to leg color
				_apply_color(node, generation_colors[2])

		cube_data.role = "leg"

	print("Step 3: Extended legs (thin plastic)")


func _step_4_create_back() -> void:
	# Make back taller - thinner for plastic
	var backs = _find_cubes_by_role("back")
	for cube_data in backs:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Make back taller and thinner - slim plastic back
				box.size.y *= 2.0
				box.size.z *= 0.2
				node.position.y += chair_size / 3.0 * 0.5
				node.position.z += chair_size / 3.0 * 0.4

				# Update color
				_apply_color(node, generation_colors[1])

	print("Step 4: Extended back (thin plastic)")


func _step_5_add_details() -> void:
	# Add armrests by creating new small cubes - thinner for plastic
	var arm_size = chair_size * 0.04
	var arm_length = chair_size * 0.5

	# Left armrest
	_create_cube(
		Vector3(-chair_size * 0.4, chair_size * 0.5, 0),
		Vector3(arm_size, arm_size, arm_length),
		3, "armrest"
	)

	# Right armrest
	_create_cube(
		Vector3(chair_size * 0.4, chair_size * 0.5, 0),
		Vector3(arm_size, arm_size, arm_length),
		3, "armrest"
	)

	# Armrest supports - thin plastic tubes
	_create_cube(
		Vector3(-chair_size * 0.4, chair_size * 0.4, chair_size * 0.15),
		Vector3(arm_size * 0.8, chair_size * 0.12, arm_size * 0.8),
		4, "support"
	)
	_create_cube(
		Vector3(chair_size * 0.4, chair_size * 0.4, chair_size * 0.15),
		Vector3(arm_size * 0.8, chair_size * 0.12, arm_size * 0.8),
		4, "support"
	)

	print("Step 5: Added armrests (thin plastic)")


func _create_cube(pos: Vector3, size: Vector3, generation: int, role: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos

	var color = generation_colors[generation % generation_colors.size()]
	_apply_color(mesh_instance, color)

	add_child(mesh_instance)
	all_cubes.append({"node": mesh_instance, "generation": generation, "role": role})


func _apply_color(mesh: MeshInstance3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	# Light plastic look - slightly shiny, smooth
	material.metallic = 0.15
	material.roughness = 0.35
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.material_override = material


func _find_cubes_by_role(role: String) -> Array:
	var result = []
	for cube in all_cubes:
		if cube.role == role:
			result.append(cube)
	return result


func _remove_cube(cube_data: Dictionary) -> void:
	if cube_data.node and is_instance_valid(cube_data.node):
		cube_data.node.queue_free()
	all_cubes.erase(cube_data)


func reset() -> void:
	for cube_data in all_cubes:
		if cube_data.node and is_instance_valid(cube_data.node):
			cube_data.node.queue_free()
	all_cubes.clear()
	step = 0
	timer = 0.0

	if show_animation:
		is_animating = true
		_step_0_initial_cube()
	else:
		_build_instant()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
