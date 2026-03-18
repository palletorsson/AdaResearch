# ===========================================================================
# Recursive Boolean Cube - Menger-like hole pattern
# Creates a cube frame with recursively carved holes
#
# This demonstrates boolean-like subtraction through recursive geometry.
# Each iteration removes the center portion, creating a Sierpinski carpet
# pattern on each face, extended into 3D like a simplified Menger sponge.
# ===========================================================================

extends Node3D

## Recursive Boolean Cube
## Creates holes recursively in a cube structure
## Each iteration subdivides and removes center sections

@export var max_iterations: int = 3
@export var cube_size: float = 2.0
@export var show_frame: bool = true
@export var frame_thickness: float = 0.05

# Color palette for each iteration depth - light plastic look
var iteration_colors: Array[Color] = [
	Color(0.92, 0.92, 0.95, 1.0),  # Iteration 1: White plastic
	Color(0.82, 0.85, 0.9, 1.0),   # Iteration 2: Light blue-gray
	Color(0.75, 0.78, 0.85, 1.0),  # Iteration 3: Medium gray
	Color(0.68, 0.72, 0.8, 1.0),   # Iteration 4: Slightly darker
	Color(0.6, 0.65, 0.75, 1.0),   # Iteration 5: More contrast
	Color(0.52, 0.58, 0.7, 1.0),   # Iteration 6: Deeper gray-blue
]

var _sim_root: Node3D
var _mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	# Create outer frame
	if show_frame:
		_create_outer_frame()

	# Start recursive subdivision
	_create_recursive_cubes(Vector3.ZERO, cube_size, 0)
	set_process(false)


func _create_outer_frame() -> void:
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.7, 0.72, 0.78, 1.0)  # Light gray plastic frame
	frame_material.metallic = 0.15
	frame_material.roughness = 0.35
	frame_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX

	var half := cube_size * 0.5 + frame_thickness
	var bar_length := cube_size + frame_thickness * 4

	# 12 edges of a cube frame
	# Bottom 4 edges
	_create_bar(Vector3(-half, -half, 0), Vector3(frame_thickness, frame_thickness, bar_length), frame_material)
	_create_bar(Vector3(half, -half, 0), Vector3(frame_thickness, frame_thickness, bar_length), frame_material)
	_create_bar(Vector3(0, -half, -half), Vector3(bar_length, frame_thickness, frame_thickness), frame_material)
	_create_bar(Vector3(0, -half, half), Vector3(bar_length, frame_thickness, frame_thickness), frame_material)

	# Top 4 edges
	_create_bar(Vector3(-half, half, 0), Vector3(frame_thickness, frame_thickness, bar_length), frame_material)
	_create_bar(Vector3(half, half, 0), Vector3(frame_thickness, frame_thickness, bar_length), frame_material)
	_create_bar(Vector3(0, half, -half), Vector3(bar_length, frame_thickness, frame_thickness), frame_material)
	_create_bar(Vector3(0, half, half), Vector3(bar_length, frame_thickness, frame_thickness), frame_material)

	# Vertical 4 edges
	_create_bar(Vector3(-half, 0, -half), Vector3(frame_thickness, bar_length, frame_thickness), frame_material)
	_create_bar(Vector3(half, 0, -half), Vector3(frame_thickness, bar_length, frame_thickness), frame_material)
	_create_bar(Vector3(-half, 0, half), Vector3(frame_thickness, bar_length, frame_thickness), frame_material)
	_create_bar(Vector3(half, 0, half), Vector3(frame_thickness, bar_length, frame_thickness), frame_material)


func _create_bar(pos: Vector3, bar_size: Vector3, mat: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = bar_size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	_sim_root.add_child(mesh_instance)


func _create_recursive_cubes(center: Vector3, size: float, iteration: int) -> void:
	if iteration >= max_iterations:
		# Base case: create a solid cube at this position
		_create_cube(center, size, iteration)
		return

	# Subdivide into 3x3x3 = 27 sub-cubes
	# But skip the 7 "cross" cubes (center + 6 face centers) to create holes
	var sub_size := size / 3.0

	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				# Count how many coordinates are 0 (center along that axis)
				var zeros := 0
				if x == 0: zeros += 1
				if y == 0: zeros += 1
				if z == 0: zeros += 1

				# Skip if 2 or more zeros (this is the cross through the center)
				# This creates the Menger sponge pattern
				if zeros >= 2:
					continue

				var offset := Vector3(x, y, z) * sub_size
				_create_recursive_cubes(center + offset, sub_size, iteration + 1)


func _create_cube(center: Vector3, size: float, iteration: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size * 0.95, size * 0.95, size * 0.95)  # Slight gap between cubes
	mesh_instance.mesh = box
	mesh_instance.position = center

	var material := StandardMaterial3D.new()

	# Get color for this iteration
	var color: Color
	if iteration < iteration_colors.size():
		color = iteration_colors[iteration]
	else:
		color = iteration_colors[iteration % iteration_colors.size()]

	material.albedo_color = color
	# Light plastic look - slightly shiny, smooth
	material.metallic = 0.15
	material.roughness = 0.35
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
	_mesh_instances.append(mesh_instance)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
