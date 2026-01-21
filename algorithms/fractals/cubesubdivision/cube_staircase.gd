extends Node3D

# Cube Staircase - Progressive subdivision creating ascending steps
# Demonstrates how diagonal subdivision of a cube creates stairs
# Each step emerges from subdividing the remaining space

@export var stair_size: float = 2.0
@export var step_count: int = 6
@export var show_construction: bool = true
@export var step_delay: float = 0.3

# Colors - stone/concrete look
var step_color := Color(0.65, 0.63, 0.6, 1.0)        # Light stone
var riser_color := Color(0.55, 0.53, 0.5, 1.0)       # Darker stone
var side_color := Color(0.5, 0.48, 0.45, 1.0)        # Side walls
var rail_color := Color(0.3, 0.25, 0.2, 1.0)         # Dark metal rail

var all_parts: Array[MeshInstance3D] = []
var current_step: int = 0
var timer: float = 0.0
var is_constructing: bool = false
var build_phase: int = 0  # 0=steps, 1=sides, 2=rails

func _ready():
	if show_construction:
		is_constructing = true
		current_step = 0
		build_phase = 0
	else:
		_build_instant()

func _process(delta: float):
	if not is_constructing:
		return

	timer += delta
	if timer >= step_delay:
		timer = 0.0
		_execute_build()

func _execute_build():
	match build_phase:
		0:  # Building steps
			if current_step < step_count:
				_build_single_step(current_step)
				current_step += 1
			else:
				build_phase = 1
				current_step = 0
		1:  # Building sides
			_build_sides()
			build_phase = 2
		2:  # Building handrail
			_build_handrail()
			is_constructing = false
			print("Staircase complete! %d parts" % all_parts.size())

func _build_instant():
	for i in range(step_count):
		_build_single_step(i)
	_build_sides()
	_build_handrail()

func _build_single_step(index: int):
	var step_width = stair_size
	var step_depth = stair_size / step_count
	var step_height = stair_size / step_count
	var tread_thickness = step_height * 0.3

	# Calculate position - steps go up along Z axis
	var x_pos = 0.0
	var y_pos = step_height * index + tread_thickness * 0.5
	var z_pos = step_depth * index + step_depth * 0.5

	# Tread (horizontal surface you step on)
	_create_part(
		Vector3(x_pos, y_pos, z_pos),
		Vector3(step_width, tread_thickness, step_depth * 1.1),
		step_color, "Tread_%d" % index
	)

	# Riser (vertical face)
	if index > 0:
		var riser_height = step_height - tread_thickness
		var riser_y = y_pos - tread_thickness * 0.5 - riser_height * 0.5
		var riser_z = z_pos - step_depth * 0.5

		_create_part(
			Vector3(x_pos, riser_y, riser_z),
			Vector3(step_width * 0.98, riser_height, step_depth * 0.1),
			riser_color, "Riser_%d" % index
		)

	print("Step %d: Built tread and riser" % index)

func _build_sides():
	# Create side walls (stringers) that follow the stair profile
	var total_height = stair_size
	var total_depth = stair_size
	var wall_thickness = stair_size * 0.05

	# Left stringer - diagonal solid
	var stringer_height = total_height * 0.7
	var stringer_length = sqrt(total_height * total_height + total_depth * total_depth) * 0.5

	# Simplified: create a box for each side angled along stairs
	# Left side base
	_create_part(
		Vector3(-stair_size * 0.5 - wall_thickness * 0.5, total_height * 0.35, total_depth * 0.5),
		Vector3(wall_thickness, total_height * 0.7, total_depth),
		side_color, "LeftStringer"
	)

	# Right side base
	_create_part(
		Vector3(stair_size * 0.5 + wall_thickness * 0.5, total_height * 0.35, total_depth * 0.5),
		Vector3(wall_thickness, total_height * 0.7, total_depth),
		side_color, "RightStringer"
	)

	print("Built side stringers")

func _build_handrail():
	var rail_radius = stair_size * 0.025
	var post_height = stair_size * 0.4
	var rail_offset = stair_size * 0.52

	# Posts at bottom and top
	var bottom_post_y = post_height * 0.5
	var bottom_post_z = stair_size * 0.1

	var top_post_y = stair_size + post_height * 0.5
	var top_post_z = stair_size * 0.9

	# Bottom post (left side)
	_create_part(
		Vector3(-rail_offset, bottom_post_y, bottom_post_z),
		Vector3(rail_radius * 2, post_height, rail_radius * 2),
		rail_color, "BottomPostLeft"
	)

	# Top post (left side)
	_create_part(
		Vector3(-rail_offset, top_post_y, top_post_z),
		Vector3(rail_radius * 2, post_height, rail_radius * 2),
		rail_color, "TopPostLeft"
	)

	# Handrail (diagonal bar connecting posts)
	var rail_length = sqrt(pow(top_post_z - bottom_post_z, 2) + pow(stair_size, 2))
	var rail_angle = atan2(stair_size, top_post_z - bottom_post_z)

	# Create rail as series of segments following the stairs
	var segments = step_count
	for i in range(segments):
		var t = float(i) / segments
		var seg_y = lerp(post_height, stair_size + post_height, t)
		var seg_z = lerp(bottom_post_z, top_post_z, t)

		_create_part(
			Vector3(-rail_offset, seg_y, seg_z + (top_post_z - bottom_post_z) / segments * 0.5),
			Vector3(rail_radius * 2, rail_radius * 2, (top_post_z - bottom_post_z) / segments * 1.2),
			rail_color, "RailSeg_%d" % i
		)

	# Intermediate posts (balusters)
	for i in range(1, step_count):
		var t = float(i) / step_count
		var bal_y_base = stair_size / step_count * i
		var bal_z = lerp(bottom_post_z, top_post_z, t)
		var bal_height = post_height * 0.8

		_create_part(
			Vector3(-rail_offset, bal_y_base + bal_height * 0.5, bal_z),
			Vector3(rail_radius * 1.5, bal_height, rail_radius * 1.5),
			rail_color, "Baluster_%d" % i
		)

	print("Built handrail with %d balusters" % (step_count - 1))

func _create_part(pos: Vector3, size: Vector3, color: Color, part_name: String):
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.name = part_name

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.1
	material.roughness = 0.6
	mesh_instance.material_override = material

	add_child(mesh_instance)
	all_parts.append(mesh_instance)

func reset():
	for part in all_parts:
		if is_instance_valid(part):
			part.queue_free()
	all_parts.clear()
	current_step = 0
	build_phase = 0
	timer = 0.0

	if show_construction:
		is_constructing = true
	else:
		_build_instant()
