extends Node3D

# Cube Chair - Recursive subdivision with non-uniform scaling
# Builds a chair by subdividing a cube and applying different scales to parts
# Demonstrates how fractal subdivision can create functional forms

@export var chair_size: float = 1.0
@export var show_construction: bool = true  # Animate the construction
@export var construction_delay: float = 0.3  # Seconds between steps

# Chair part colors
var seat_color := Color(0.6, 0.3, 0.1, 1.0)      # Brown wood
var back_color := Color(0.5, 0.25, 0.08, 1.0)    # Darker brown
var leg_color := Color(0.4, 0.2, 0.05, 1.0)      # Dark brown
var frame_color := Color(0.15, 0.15, 0.2, 1.0)   # Dark frame

var construction_step: int = 0
var construction_timer: float = 0.0
var is_constructing: bool = false
var chair_parts: Array[MeshInstance3D] = []


func _ready() -> void:
	if show_construction:
		is_constructing = true
		construction_step = 0
	else:
		_build_complete_chair()


func _process(delta: float) -> void:
	if not is_constructing:
		return

	construction_timer += delta
	if construction_timer >= construction_delay:
		construction_timer = 0.0
		_build_step(construction_step)
		construction_step += 1

		if construction_step > 10:
			is_constructing = false
			print("Chair construction complete!")


func _build_complete_chair() -> void:
	# Build all parts at once
	for i in range(11):
		_build_step(i)


func _build_step(step: int) -> void:
	match step:
		0:
			# Step 0: Create the seat (wide, flat cube)
			_create_part(
				Vector3(0, chair_size * 0.4, 0),
				Vector3(chair_size * 0.9, chair_size * 0.08, chair_size * 0.8),
				seat_color,
				"Seat"
			)
		1:
			# Step 1: Back support (tall, thin)
			_create_part(
				Vector3(0, chair_size * 0.85, -chair_size * 0.35),
				Vector3(chair_size * 0.85, chair_size * 0.8, chair_size * 0.06),
				back_color,
				"Back"
			)
		2:
			# Step 2: Front left leg
			_create_part(
				Vector3(-chair_size * 0.35, chair_size * 0.18, chair_size * 0.3),
				Vector3(chair_size * 0.08, chair_size * 0.4, chair_size * 0.08),
				leg_color,
				"FrontLeftLeg"
			)
		3:
			# Step 3: Front right leg
			_create_part(
				Vector3(chair_size * 0.35, chair_size * 0.18, chair_size * 0.3),
				Vector3(chair_size * 0.08, chair_size * 0.4, chair_size * 0.08),
				leg_color,
				"FrontRightLeg"
			)
		4:
			# Step 4: Back left leg (taller, goes up to back)
			_create_part(
				Vector3(-chair_size * 0.35, chair_size * 0.5, -chair_size * 0.35),
				Vector3(chair_size * 0.08, chair_size * 1.0, chair_size * 0.08),
				leg_color,
				"BackLeftLeg"
			)
		5:
			# Step 5: Back right leg
			_create_part(
				Vector3(chair_size * 0.35, chair_size * 0.5, -chair_size * 0.35),
				Vector3(chair_size * 0.08, chair_size * 1.0, chair_size * 0.08),
				leg_color,
				"BackRightLeg"
			)
		6:
			# Step 6: Left arm rest support
			_create_part(
				Vector3(-chair_size * 0.45, chair_size * 0.55, 0),
				Vector3(chair_size * 0.04, chair_size * 0.25, chair_size * 0.04),
				leg_color,
				"LeftArmSupport"
			)
		7:
			# Step 7: Right arm rest support
			_create_part(
				Vector3(chair_size * 0.45, chair_size * 0.55, 0),
				Vector3(chair_size * 0.04, chair_size * 0.25, chair_size * 0.04),
				leg_color,
				"RightArmSupport"
			)
		8:
			# Step 8: Left arm rest (horizontal)
			_create_part(
				Vector3(-chair_size * 0.45, chair_size * 0.7, -chair_size * 0.05),
				Vector3(chair_size * 0.06, chair_size * 0.04, chair_size * 0.6),
				seat_color,
				"LeftArmRest"
			)
		9:
			# Step 9: Right arm rest
			_create_part(
				Vector3(chair_size * 0.45, chair_size * 0.7, -chair_size * 0.05),
				Vector3(chair_size * 0.06, chair_size * 0.04, chair_size * 0.6),
				seat_color,
				"RightArmRest"
			)
		10:
			# Step 10: Back horizontal bar (decorative)
			_create_part(
				Vector3(0, chair_size * 1.15, -chair_size * 0.35),
				Vector3(chair_size * 0.7, chair_size * 0.06, chair_size * 0.04),
				back_color,
				"BackBar"
			)


func _create_part(pos: Vector3, size: Vector3, color: Color, part_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.name = part_name

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.1
	material.roughness = 0.8
	mesh_instance.material_override = material

	add_child(mesh_instance)
	chair_parts.append(mesh_instance)

	if show_construction:
		print("Built: %s at %s with size %s" % [part_name, pos, size])


func reset() -> void:
	for part in chair_parts:
		if is_instance_valid(part):
			part.queue_free()
	chair_parts.clear()
	construction_step = 0
	construction_timer = 0.0

	if show_construction:
		is_constructing = true
	else:
		_build_complete_chair()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
