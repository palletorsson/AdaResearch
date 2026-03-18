extends Node3D

# Recursive Table - Subdivision-based table construction
# Starts with one cube, subdivides it, keeps tabletop and legs
# Similar approach to recursive_chair but for a table form

@export var table_size: float = 2.5
@export var show_animation: bool = true
@export var step_delay: float = 0.4

# Colors for different generations - light plastic look
var generation_colors: Array[Color] = [
	Color(0.9, 0.9, 0.92, 1.0),    # Gen 0 - White plastic (tabletop)
	Color(0.8, 0.82, 0.85, 1.0),   # Gen 1 - Light gray
	Color(0.7, 0.72, 0.75, 1.0),   # Gen 2 - Medium gray (legs)
	Color(0.6, 0.62, 0.65, 1.0),   # Gen 3 - Darker (apron)
	Color(0.5, 0.52, 0.55, 1.0),   # Gen 4 - Darkest
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
		2: _step_2_shape_tabletop()
		3: _step_3_create_legs()
		4: _step_4_add_supports()
		_:
			is_animating = false
			print("Recursive table complete! Total parts: %d" % all_cubes.size())


func _build_instant() -> void:
	_step_0_initial_cube()
	_step_1_first_subdivision()
	_step_2_shape_tabletop()
	_step_3_create_legs()
	_step_4_add_supports()


func _step_0_initial_cube() -> void:
	# Create the initial cube that will become the table
	_create_cube(Vector3(0, table_size * 0.4, 0), Vector3(table_size, table_size * 0.8, table_size), 0, "base")
	print("Step 0: Initial cube")


func _step_1_first_subdivision() -> void:
	# Subdivide into 3x3x2 grid (3 wide, 3 deep, 2 tall)
	# Top layer = tabletop, bottom corners = legs
	var base = _find_cubes_by_role("base")
	if base.is_empty():
		return

	var base_cube = base[0]
	var center = base_cube.node.position
	var size_x = table_size / 3.0
	var size_z = table_size / 3.0
	var size_y = table_size * 0.4  # Half height for 2 layers

	# Remove original
	_remove_cube(base_cube)

	# Create 3x3x2 grid
	# Bottom layer (y=0): only corners are legs
	# Top layer (y=1): entire layer is tabletop

	for y in range(2):
		for x in range(3):
			for z in range(3):
				var offset = Vector3(
					(x - 1) * size_x,
					y * size_y + size_y * 0.5,
					(z - 1) * size_z
				)
				var pos = center + offset - Vector3(0, table_size * 0.2, 0)

				# Determine role based on position
				var role = "remove"

				if y == 0:  # Bottom layer - legs at corners only
					if (x == 0 or x == 2) and (z == 0 or z == 2):
						role = "leg_top"
				elif y == 1:  # Top layer - entire tabletop
					role = "tabletop"

				if role != "remove":
					_create_cube(pos, Vector3(size_x * 0.95, size_y * 0.95, size_z * 0.95), 1, role)

	print("Step 1: Subdivided into table shape")


func _step_2_shape_tabletop() -> void:
	# Remove the 9 individual tabletop cubes and replace with single solid piece
	var tabletops = _find_cubes_by_role("tabletop")

	# Get the Y position from first tabletop piece before removing
	var tabletop_y = table_size * 0.48
	if not tabletops.is_empty():
		tabletop_y = tabletops[0].node.position.y

	# Remove all individual tabletop pieces
	for cube_data in tabletops:
		if cube_data.node and is_instance_valid(cube_data.node):
			cube_data.node.queue_free()
		all_cubes.erase(cube_data)

	# Create single solid tabletop - thin plastic
	var tabletop_thickness = table_size * 0.04
	_create_cube(
		Vector3(0, tabletop_y + table_size * 0.08, 0),
		Vector3(table_size * 0.95, tabletop_thickness, table_size * 0.95),
		0, "tabletop_solid"
	)

	print("Step 2: Shaped tabletop (thin plastic)")


func _step_3_create_legs() -> void:
	# Extend the leg cubes to meet tabletop - thinner plastic legs
	var legs = _find_cubes_by_role("leg_top")

	# Find actual tabletop position to calculate proper leg height
	# Tabletop is created at: tabletop_y + table_size * 0.08, with thickness table_size * 0.04
	# So bottom of tabletop is at: tabletop_y + table_size * 0.08 - (table_size * 0.04 / 2)
	var tabletop_solid = _find_cubes_by_role("tabletop_solid")
	var tabletop_bottom_y = table_size * 0.5  # Default fallback
	if not tabletop_solid.is_empty():
		var tabletop_node = tabletop_solid[0].node as MeshInstance3D
		if tabletop_node and tabletop_node.mesh:
			var tabletop_box = tabletop_node.mesh as BoxMesh
			if tabletop_box:
				tabletop_bottom_y = tabletop_node.position.y - tabletop_box.size.y / 2.0

	for cube_data in legs:
		var node = cube_data.node as MeshInstance3D
		if node and node.mesh:
			var box = node.mesh as BoxMesh
			if box:
				# Calculate leg dimensions to bridge gap
				var leg_bottom_y = 0.0  # Floor
				var leg_top_y = tabletop_bottom_y
				var leg_height = leg_top_y - leg_bottom_y
				var leg_center_y = leg_height / 2.0

				# Make legs thinner - slim plastic
				box.size.x *= 0.35
				box.size.z *= 0.35
				box.size.y = leg_height

				# Position leg to touch floor and reach tabletop
				node.position.y = leg_center_y

				# Update color to leg color
				_apply_color(node, generation_colors[2])

		cube_data.role = "leg"

	print("Step 3: Extended legs (thin plastic, bridging gap)")


func _step_4_add_supports() -> void:
	# Add cross supports between legs (apron) - thinner plastic
	var apron_thickness = table_size * 0.025
	var apron_height = table_size * 0.05

	# Find actual tabletop position to place apron just below it
	var tabletop_solid = _find_cubes_by_role("tabletop_solid")
	var apron_y = table_size * 0.42  # Default fallback
	if not tabletop_solid.is_empty():
		var tabletop_node = tabletop_solid[0].node as MeshInstance3D
		if tabletop_node and tabletop_node.mesh:
			var tabletop_box = tabletop_node.mesh as BoxMesh
			if tabletop_box:
				# Position apron just below tabletop
				apron_y = tabletop_node.position.y - tabletop_box.size.y / 2.0 - apron_height

	var leg_inset = table_size * 0.35

	# Front apron
	_create_cube(
		Vector3(0, apron_y, leg_inset),
		Vector3(table_size * 0.65, apron_height, apron_thickness),
		3, "apron"
	)

	# Back apron
	_create_cube(
		Vector3(0, apron_y, -leg_inset),
		Vector3(table_size * 0.65, apron_height, apron_thickness),
		3, "apron"
	)

	# Left apron
	_create_cube(
		Vector3(-leg_inset, apron_y, 0),
		Vector3(apron_thickness, apron_height, table_size * 0.65),
		3, "apron"
	)

	# Right apron
	_create_cube(
		Vector3(leg_inset, apron_y, 0),
		Vector3(apron_thickness, apron_height, table_size * 0.65),
		3, "apron"
	)

	print("Step 4: Added apron supports (thin plastic)")


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
