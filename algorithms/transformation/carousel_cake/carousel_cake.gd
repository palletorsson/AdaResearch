@tool
extends Node3D

@export var layer_radii: Array[float] = [4.0, 3.5, 3.0, 1.6, 3.0, 3.5, 4.0, 5.0]
@export var layer_heights: Array[float] = [0.05, 0.05, 0.05, 3.0, 1.0, 0.5, 0.5, 0.5]
@export var base_radial_segments: int = 32
@export var segments_increment: int = 2
@export var base_rotation_speed: float = 0.5
@export var rotation_speed_multiplier: float = 1.2  # Each layer spins faster
@export_group("Colliders")
@export var enable_colliders: bool = true
@export var collision_layer: int = 1
@export var collision_mask: int = 1
@export_group("Materials")
@export var alternating_colors: bool = true
@export var color_a: Color = Color(0.992, 0.323, 0.882, 1.0)  # Cake color
@export var color_b: Color = Color(0.228, 0.867, 1.0, 1.0)  # Frosting color
@export var regenerate: bool = false: set = _set_regenerate

@onready var mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
var _rotation_angle: float = 0.0
var _collider_bodies: Array[StaticBody3D] = []

func _ready() -> void:
	generate_carousel()
	set_process(true)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_rotation_angle += delta
		update_carousel_rotation()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_carousel()
		regenerate = false

func generate_carousel() -> void:
	# Clear existing multimesh instance
	if mm_inst.get_parent():
		mm_inst.get_parent().remove_child(mm_inst)

	# Clear existing colliders
	_clear_colliders()

	add_child(mm_inst)
	if Engine.is_editor_hint():
		mm_inst.owner = get_tree().edited_scene_root

	var mm := MultiMesh.new()
	mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = alternating_colors

	# Validate arrays
	if layer_radii.is_empty() or layer_heights.is_empty():
		push_error("CarouselCake: layer_radii and layer_heights cannot be empty")
		return

	var layer_count = min(layer_radii.size(), layer_heights.size())

	# Create base cylinder mesh (unit cylinder, will be scaled per instance)
	var cylinder := CylinderMesh.new()
	cylinder.height = 1.0  # Unit height
	cylinder.top_radius = 1.0  # Unit radius
	cylinder.bottom_radius = 1.0
	cylinder.radial_segments = base_radial_segments

	# Create material with vertex color support
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	cylinder.material = mat

	mm.mesh = cylinder
	mm.instance_count = layer_count

	var cumulative_y: float = 0.0

	for i in range(layer_count):
		var transform := Transform3D.IDENTITY

		var current_radius: float = layer_radii[i]
		var current_height: float = layer_heights[i]

		# Stack vertically at same XZ position (0, 0)
		# Position at center of cylinder (half height up from base)
		transform.origin.y = cumulative_y + current_height / 2.0

		# Scale the cylinder to the current radius and height
		transform.basis = transform.basis.scaled(Vector3(current_radius, current_height, current_radius))

		mm.set_instance_transform(i, transform)

		# Set alternating colors
		if alternating_colors:
			var use_color_a := i % 2 == 0
			mm.set_instance_color(i, color_a if use_color_a else color_b)

		# Update cumulative height for next layer
		cumulative_y += current_height

	# Generate colliders if enabled
	if enable_colliders:
		_generate_colliders()

func update_carousel_rotation() -> void:
	if not mm_inst.multimesh:
		return

	var mm := mm_inst.multimesh
	var cumulative_y: float = 0.0

	for i in range(mm.instance_count):
		# Each layer rotates at different speed (faster as you go up)
		var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
		var angle: float = _rotation_angle * layer_speed

		var current_radius: float = layer_radii[i] if i < layer_radii.size() else 1.0
		var current_height: float = layer_heights[i] if i < layer_heights.size() else 1.0

		# Create transform with rotation and scale
		var transform := Transform3D.IDENTITY
		transform.origin.y = cumulative_y + current_height / 2.0
		transform.basis = Basis.IDENTITY.rotated(Vector3.UP, angle)
		transform.basis = transform.basis.scaled(Vector3(current_radius, current_height, current_radius))

		mm.set_instance_transform(i, transform)

		# Update cumulative height for next layer
		cumulative_y += current_height

	# Update colliders rotation
	if enable_colliders:
		_update_colliders_rotation()

func _generate_colliders() -> void:
	var cumulative_y: float = 0.0

	for i in range(min(layer_radii.size(), layer_heights.size())):
		var current_radius: float = layer_radii[i]
		var current_height: float = layer_heights[i]

		# Create StaticBody3D
		var body := StaticBody3D.new()
		body.name = "ColliderLayer_%d" % i
		body.collision_layer = collision_layer
		body.collision_mask = collision_mask
		add_child(body)
		if Engine.is_editor_hint():
			body.owner = get_tree().edited_scene_root

		# Create CylinderShape3D
		var shape := CylinderShape3D.new()
		shape.radius = current_radius
		shape.height = current_height

		# Create CollisionShape3D
		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = shape
		collision_shape.position.y = cumulative_y + current_height / 2.0
		body.add_child(collision_shape)
		if Engine.is_editor_hint():
			collision_shape.owner = get_tree().edited_scene_root

		_collider_bodies.append(body)
		cumulative_y += current_height

func _update_colliders_rotation() -> void:
	for i in range(_collider_bodies.size()):
		var body := _collider_bodies[i]
		if not is_instance_valid(body):
			continue

		# Each layer rotates at different speed
		var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
		var angle: float = _rotation_angle * layer_speed

		body.rotation.y = angle

func _clear_colliders() -> void:
	for body in _collider_bodies:
		if is_instance_valid(body):
			body.queue_free()
	_collider_bodies.clear()
