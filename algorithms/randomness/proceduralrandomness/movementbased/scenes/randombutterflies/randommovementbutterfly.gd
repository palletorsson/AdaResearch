extends Node3D

# Random Movement Butterfly — upgraded to seek entropy_axiom grid points
# Butterflies wander randomly, but are drawn to entropy gradients.
# Grab and release a butterfly in VR → it finds a new entropy point.

@export var area_size: Vector3 = Vector3(20, 10, 20)
@export var min_move_time: float = 5.0
@export var max_move_time: float = 10.0
@export var speed: float = 3.0
@export var area_center: NodePath
@export var sitting_points: Array[NodePath] = []
@export var use_random_sitting_points: bool = true
@export var num_random_sitting_points: int = 5
@export var sitting_duration: float = 3.0

## Entropy-seeking behavior
@export var entropy_seek_chance: float = 0.55  # Chance to seek entropy vs random wander
@export var entropy_sit_duration: float = 4.0  # Sit longer on entropy points (contemplate)
@export var wing_tint_speed: float = 0.8  # How fast wings absorb entropy color
@export var entropy_search_radius: float = 50.0  # Max distance to look for entropy nodes

var move_direction: Vector3
var move_timer: float = 0.0
var center_node: Node3D

var is_sitting: bool = false
var sitting_timer: float = 0.0
var target_sit_position: Vector3
var _seeking_entropy: bool = false

var random_sitting_points: Array[Vector3] = []

# Entropy system references
var _entropy_nodes: Array[Node3D] = []
var _current_entropy_color: Color = Color.WHITE
var _target_wing_color: Color = Color.WHITE
var _wing_material: StandardMaterial3D
var _has_been_grabbed: bool = false


func _ready() -> void:
	center_node = get_node(area_center) if area_center else self

	if use_random_sitting_points:
		for i in range(num_random_sitting_points):
			var random_point: Vector3 = center_node.position + Vector3(
				randf_range(-area_size.x / 2, area_size.x / 2),
				randf_range(-area_size.y / 2, area_size.y / 2),
				randf_range(-area_size.z / 2, area_size.z / 2)
			)
			random_sitting_points.append(random_point)

	position = center_node.position + Vector3(
		randf_range(-area_size.x / 2, area_size.x / 2),
		randf_range(-area_size.y / 2, area_size.y / 2),
		randf_range(-area_size.z / 2, area_size.z / 2)
	)

	change_direction()
	rotation = Vector3(0, 0, 0)
	$AnimationPlayer.play("fly")

	# Add to group so spawner/VR can find us
	add_to_group("entropy_butterfly")

	# Discover entropy_axiom nodes after a short delay (let scene load)
	_find_entropy_nodes.call_deferred()

	# Set up wing material for color tinting
	_setup_wing_material()


func _find_entropy_nodes() -> void:
	_entropy_nodes.clear()

	# First try the fast path: group lookup
	for node in get_tree().get_nodes_in_group("entropy_axiom"):
		if node is Node3D:
			var dist: float = global_position.distance_to(node.global_position)
			if dist < entropy_search_radius:
				_entropy_nodes.append(node as Node3D)

	# Fallback: scan scene tree by name if group was empty
	if _entropy_nodes.is_empty():
		_collect_entropy_nodes(get_tree().root)


func _collect_entropy_nodes(node: Node) -> void:
	var node_name: String = node.name.to_lower()
	if node is Node3D:
		if "entropy_axiom" in node_name or "entropyaxiom" in node_name:
			var dist: float = global_position.distance_to(node.global_position)
			if dist < entropy_search_radius:
				_entropy_nodes.append(node as Node3D)
	for child in node.get_children():
		_collect_entropy_nodes(child)


func _setup_wing_material() -> void:
	# Find wing meshes and create a shared tintable material
	for child_name in ["pngegg_rightwing", "pngegg_leftwing"]:
		var wing: MeshInstance3D = find_child(child_name, true, false) as MeshInstance3D
		if wing and wing.mesh:
			if not _wing_material:
				# Clone the existing material so we can tint it
				var existing: Material = wing.get_active_material(0)
				if existing is StandardMaterial3D:
					_wing_material = existing.duplicate() as StandardMaterial3D
				else:
					_wing_material = StandardMaterial3D.new()
					_wing_material.albedo_color = Color.WHITE
			wing.material_override = _wing_material


func _process(delta: float) -> void:
	if is_sitting:
		sitting_timer -= delta

		# Gradually tint wings toward entropy color while sitting
		if _wing_material and _seeking_entropy:
			var current: Color = _wing_material.albedo_color
			_wing_material.albedo_color = current.lerp(_target_wing_color, wing_tint_speed * delta)

		if sitting_timer <= 0:
			is_sitting = false
			_seeking_entropy = false
			change_direction()
			$AnimationPlayer.play("fly")
	else:
		var previous_position: Vector3 = position
		position += move_direction * speed * delta
		point_in_direction(position - previous_position)

		move_timer -= delta

		if move_timer <= 0:
			# Decide: seek entropy or wander?
			if _entropy_nodes.size() > 0 and randf() < entropy_seek_chance:
				_seek_entropy_point()
			elif (sitting_points.size() > 0 or random_sitting_points.size() > 0) and randf() < 0.3:
				choose_sitting_point()
			else:
				change_direction()

		stay_within_bounds()


func _seek_entropy_point() -> void:
	# Pick a random entropy_axiom node
	var target_node: Node3D = _entropy_nodes[randi() % _entropy_nodes.size()]

	# Sample a random point along the entropy gradient
	# The axiom runs along local Z with grid_size_z * base_spacing extent
	var grid_z: int = 40  # default
	var spacing: float = 0.2
	var grid_x: int = 10
	var grid_y: int = 10

	# Try to read actual params from the node
	if target_node.get("grid_size_z"):
		grid_z = int(target_node.get("grid_size_z"))
	if target_node.get("base_spacing"):
		spacing = float(target_node.get("base_spacing"))
	if target_node.get("grid_size_x"):
		grid_x = int(target_node.get("grid_size_x"))
	if target_node.get("grid_size_y"):
		grid_y = int(target_node.get("grid_size_y"))

	# Pick a random Z slice (biased slightly toward higher entropy = more interesting)
	var z_float: float = randf()
	z_float = pow(z_float, 0.7)  # Slight bias toward chaos end
	var z_index: int = int(z_float * (grid_z - 1))
	var entropy_factor: float = float(z_index) / float(grid_z - 1)
	var curved_entropy: float = pow(entropy_factor, 2.0)

	# Compute a point position in the entropy grid (matching axiom's generation)
	var x_index: int = randi() % grid_x
	var y_index: int = randi() % grid_y
	var base_pos: Vector3 = Vector3(
		(x_index - grid_x / 2.0) * spacing,
		(y_index - grid_y / 2.0) * spacing,
		z_index * spacing
	)

	# Convert to global space
	var target_global: Vector3 = target_node.global_transform * base_pos
	# Hover slightly above the point
	target_global.y += 0.05

	# Set up flight toward this point
	target_sit_position = target_global
	var to_target: Vector3 = target_sit_position - global_position
	if to_target.length() < 0.1:
		to_target = Vector3(randf_range(-1, 1), 0.1, randf_range(-1, 1))
	move_direction = to_target.normalized()
	move_timer = to_target.length() / speed

	# Compute the entropy color at this point for wing tinting
	var hue: float = lerpf(0.66, 0.0, curved_entropy)
	_target_wing_color = Color.from_hsv(hue, 0.6, 1.0)  # Desaturated for subtle tint
	_seeking_entropy = true

	point_in_direction(move_direction)


## Called when VR player releases this butterfly (connected externally)
func on_released() -> void:
	_has_been_grabbed = true
	is_sitting = false
	$AnimationPlayer.play("fly")

	# Immediately seek a new entropy point if available
	if _entropy_nodes.size() > 0:
		_seek_entropy_point()
	else:
		change_direction()


func change_direction() -> void:
	var horizontal_direction: Vector3 = Vector3(
		randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1)
	).normalized()
	move_direction = horizontal_direction
	point_in_direction(horizontal_direction)
	move_timer = randf_range(min_move_time, max_move_time)


func choose_sitting_point() -> void:
	var target_point: Vector3
	if sitting_points.size() > 0:
		var sit_node: Node3D = get_node(sitting_points[randi() % sitting_points.size()]) as Node3D
		if sit_node:
			target_point = sit_node.position
		else:
			return
	elif random_sitting_points.size() > 0:
		target_point = random_sitting_points[randi() % random_sitting_points.size()]
	else:
		return
	target_sit_position = target_point
	move_direction = (target_sit_position - position).normalized()
	move_timer = (target_sit_position - position).length() / speed
	_seeking_entropy = false


func stay_within_bounds() -> void:
	var pos: Vector3 = position
	var center: Vector3 = center_node.position

	if pos.x > center.x + area_size.x / 2:
		pos.x = center.x + area_size.x / 2
		change_direction()
	elif pos.x < center.x - area_size.x / 2:
		pos.x = center.x - area_size.x / 2
		change_direction()

	if pos.y > center.y + area_size.y / 2:
		pos.y = center.y + area_size.y / 2
		change_direction()
	elif pos.y < center.y - area_size.y / 2:
		pos.y = center.y - area_size.y / 2
		change_direction()

	if pos.z > center.z + area_size.z / 2:
		pos.z = center.z + area_size.z / 2
		change_direction()
	elif pos.z < center.z - area_size.z / 2:
		pos.z = center.z - area_size.z / 2
		change_direction()

	position = pos


func point_in_direction(direction: Vector3) -> void:
	if direction.length() > 0:
		look_at(position + direction, Vector3(0, 1, 0))


func _physics_process(_delta: float) -> void:
	if not is_sitting and target_sit_position != Vector3.ZERO:
		if global_position.distance_to(target_sit_position) < 0.5:
			is_sitting = true
			sitting_timer = entropy_sit_duration if _seeking_entropy else sitting_duration
			$AnimationPlayer.stop()
