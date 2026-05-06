# @identity
# essence: a deterministic-by-mode grid cube remover — Range, Column, Row, or All — that dissolves volumes via subtraction with configurable highlight duration and per-cube removal speed
# desire: to make subtraction visible as authorship — the player watches which cubes leave and in what order, and learns that removal is a creative act, not the absence of one
# critical_parameter: selection_mode — Range, Column, Row, All — each mode tells a different story about how randomness can be bounded and what shape its bound takes
# triggers: removal coroutine animates highlight_duration per cube and paces via removal_speed; selection_mode determines which cells enter the queue based on x/y/z bounds or target_column/target_row
# emerges: a cleared volume with the rhythm of its departure — negative space carries the order of removal, not just the result; the lattice remembers which cubes left first
# needs: VR pointing at cubes to add to removal queue [missing]; live mode switching [missing]; undo/repeat [missing]; apply_grid_config [missing]
# relationships: paired with random_object_spawner (the painter) and entropy_axiom (the principle) in randomness — the eraser to their accumulation; appears in Subtraction as Authorship and One Line Infinite Maze
# truth: subtraction is composition — what you remove writes the space as much as what you place; the randomness sequence's quietest authorship lesson lives on this slider

extends Node3D

# Grid selection mode
@export_enum("Range", "Column", "Row", "All") var selection_mode: String = "Range"

# Column/Row selection (used when selection_mode is "Column" or "Row")
@export var target_column: int = 0  # X coordinate
@export var target_row: int = 0     # Z coordinate

# Configurable range for cube removal (used when selection_mode is "Range")
@export var x_min: float = 2.0
@export var x_max: float = 4.0
@export var y_min: float = 0.0
@export var y_max: float = 2.0
@export var z_min: float = 2.0
@export var z_max: float = 21.0

# Visual enhancement parameters
@export var removal_speed: float = 1.0
@export var highlight_duration: float = 0.3
@export var show_removal_effects: bool = true
@export var localize_selection_to_artifact: bool = true
@export var auto_expand_to_all_if_empty: bool = true

@export_group("MultiMesh")
@export var multimesh_path: NodePath = "../GridMultiMesh"

var timer: Timer
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var active_instances: Array[int] = []  # Track which instances are still active
var initial_count: int = 0
var removed_count: int = 0
var _removal_in_progress: bool = false
var _selection_origin_local: Vector3 = Vector3.ZERO
var _grid_step_x: float = 1.0
var _grid_step_z: float = 1.0

var _use_node_mode: bool = false
var _target_nodes: Array[Node3D] = []

func _ready() -> void:
	# Try MultiMesh first
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	if not multimesh_instance:
		multimesh_instance = _find_named_multimesh_instance(get_parent(), "GridMultiMesh")
	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())
	if not multimesh_instance and get_tree() and get_tree().current_scene:
		multimesh_instance = _find_named_multimesh_instance(get_tree().current_scene, "GridMultiMesh")
	if not multimesh_instance and get_tree() and get_tree().current_scene:
		multimesh_instance = _find_multimesh_instance(get_tree().current_scene)

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)
			find_all_instances()
		else:
			push_warning("MultiMesh found but has no instances, trying node mode")
			_try_node_mode()
	else:
		print("No MultiMesh found, trying node mode (individual grid cubes)")
		_try_node_mode()

	# Create timer
	timer = Timer.new()
	timer.wait_time = 0.5 / maxf(removal_speed, 0.01)
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _try_node_mode() -> void:
	"""Fallback: find individual StaticBody3D/MeshInstance3D nodes in range"""
	_use_node_mode = true
	_target_nodes.clear()
	
	# Search the GridScene (parent hierarchy) for floor tiles
	var grid_scene = _find_grid_scene()
	if not grid_scene:
		grid_scene = get_parent()
	
	_collect_nodes_in_range(grid_scene)
	initial_count = _target_nodes.size()
	print("RemoveRandom (node mode): Found %d nodes in range" % initial_count)

func _find_grid_scene() -> Node:
	var current = get_parent()
	while current:
		if current.name == "GridScene" or current.has_method("get_map_data"):
			return current
		current = current.get_parent()
	return null

func _collect_nodes_in_range(root: Node) -> void:
	"""Recursively find nodes in the target range"""
	for child in root.get_children():
		if child == self:
			continue
		if child is Node3D:
			var pos = child.global_position - global_position  # Relative to our position
			if _should_include_instance(pos):
				# Only include nodes that have a mesh (actual visible objects)
				if child is MeshInstance3D or child.get_node_or_null("MeshInstance3D") != null:
					_target_nodes.append(child)
				elif child is StaticBody3D and child.get_node_or_null("MeshInstance3D") != null:
					_target_nodes.append(child)
		# Don't recurse too deep into artifact scenes
		if not (child.name.begins_with("Artifact") or child.get_script()):
			_collect_nodes_in_range(child)

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node == null:
		return null
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func _find_named_multimesh_instance(node: Node, target_name: String) -> MultiMeshInstance3D:
	if node == null:
		return null
	if node is MultiMeshInstance3D and node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_named_multimesh_instance(child, target_name)
		if result:
			return result
	return null

func find_all_instances() -> void:
	"""Find all instances that match selection criteria"""
	if not multimesh:
		return

	_refresh_selection_reference()
	active_instances.clear()

	for i in range(multimesh.instance_count):
		var transform = multimesh.get_instance_transform(i)
		if _should_include_instance(transform.origin):
			active_instances.append(i)

	if active_instances.is_empty() and auto_expand_to_all_if_empty:
		for i in range(multimesh.instance_count):
			active_instances.append(i)
		print("RemoveRandom: Selection was empty, expanded to all %d instances" % active_instances.size())

	initial_count = active_instances.size()
	print("RemoveRandom: Selected %d instances based on mode '%s'" % [initial_count, selection_mode])

func _refresh_selection_reference() -> void:
	if not multimesh_instance or not multimesh:
		return

	_selection_origin_local = multimesh_instance.to_local(global_position)

	# Estimate grid spacing from transforms so row/column mode remains correct
	# when cube_size + gutter is not exactly 1.
	var x_values: Array = []
	var z_values: Array = []
	for i in range(multimesh.instance_count):
		var origin = multimesh.get_instance_transform(i).origin
		x_values.append(origin.x)
		z_values.append(origin.z)

	_grid_step_x = _estimate_axis_step(x_values)
	_grid_step_z = _estimate_axis_step(z_values)

func _estimate_axis_step(values: Array) -> float:
	if values.size() < 2:
		return 1.0

	values.sort()
	var min_diff := INF
	for i in range(1, values.size()):
		var diff := absf(float(values[i]) - float(values[i - 1]))
		if diff > 0.0001 and diff < min_diff:
			min_diff = diff

	if is_inf(min_diff):
		return 1.0
	return maxf(min_diff, 0.0001)

func _should_include_instance(pos: Vector3) -> bool:
	"""Check if an instance should be included based on selection mode"""
	var check_pos = pos
	if localize_selection_to_artifact:
		check_pos -= _selection_origin_local

	match selection_mode:
		"All":
			return true
		"Column":
			var column_center = float(target_column) * _grid_step_x
			return absf(check_pos.x - column_center) <= _grid_step_x * 0.4
		"Row":
			var row_center = float(target_row) * _grid_step_z
			return absf(check_pos.z - row_center) <= _grid_step_z * 0.4
		"Range":
			return (check_pos.x >= x_min and check_pos.x <= x_max and
					check_pos.y >= y_min and check_pos.y <= y_max and
					check_pos.z >= z_min and check_pos.z <= z_max)
	return false

func _on_timer_timeout() -> void:
	"""Called every 0.5 seconds to remove one instance"""
	if _removal_in_progress:
		return
	_removal_in_progress = true
	if _use_node_mode:
		await _remove_node()
	else:
		await _remove_multimesh_instance()
	_removal_in_progress = false

func _remove_multimesh_instance() -> void:
	if active_instances.is_empty():
		print("No more instances to remove!")
		timer.stop()
		return

	var random_index = randi() % active_instances.size()
	var instance_index = active_instances[random_index]

	highlight_instance_for_removal(instance_index)
	await get_tree().create_timer(highlight_duration).timeout

	var transform = multimesh.get_instance_transform(instance_index)
	var removal_position = transform.origin
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(instance_index, transform)

	if multimesh.use_colors:
		multimesh.set_instance_color(instance_index, Color(0, 0, 0, 0))

	active_instances.remove_at(random_index)
	removed_count += 1

	if show_removal_effects:
		create_removal_effect(removal_position)

	var total = maxi(initial_count, 1)
	print("Removed: %d/%d (%.1f%%)" % [removed_count, initial_count, (removed_count / float(total)) * 100.0])

func _remove_node() -> void:
	# Clean up invalid references
	_target_nodes = _target_nodes.filter(func(n): return is_instance_valid(n))
	
	if _target_nodes.is_empty():
		print("No more nodes to remove!")
		timer.stop()
		return

	var random_index = randi() % _target_nodes.size()
	var node = _target_nodes[random_index]
	var removal_position = node.global_position

	# Highlight: tint red briefly
	var mesh = node as MeshInstance3D
	if not mesh:
		mesh = node.get_node_or_null("MeshInstance3D")
	if mesh:
		var highlight_mat = StandardMaterial3D.new()
		highlight_mat.albedo_color = Color(1, 0.2, 0.2)
		highlight_mat.emission_enabled = true
		highlight_mat.emission = Color(1, 0, 0) * 0.5
		mesh.material_override = highlight_mat

	await get_tree().create_timer(highlight_duration).timeout

	# Animate shrink then remove
	var tween = create_tween()
	tween.tween_property(node, "scale", Vector3.ZERO, 0.2)
	await tween.finished
	node.queue_free()

	_target_nodes.remove_at(random_index)
	removed_count += 1

	if show_removal_effects:
		create_removal_effect(removal_position)

	var total = maxi(initial_count, 1)
	print("Removed: %d/%d (%.1f%%)" % [removed_count, initial_count, (removed_count / float(total)) * 100.0])

func highlight_instance_for_removal(instance_index: int) -> void:
	"""Highlight an instance before removing it"""
	if not multimesh or not multimesh.use_colors:
		return

	# Flash red
	multimesh.set_instance_color(instance_index, Color(1.0, 0.2, 0.2))

	# Pulsing scale effect
	var transform = multimesh.get_instance_transform(instance_index)
	var original_scale = transform.basis.get_scale()

	var tween = create_tween()
	tween.set_loops(2)
	tween.tween_method(func(scale_mult: float):
		var t = multimesh.get_instance_transform(instance_index)
		t.basis = Basis().scaled(original_scale * scale_mult)
		multimesh.set_instance_transform(instance_index, t)
	, 1.0, 1.2, highlight_duration / 4)
	tween.tween_method(func(scale_mult: float):
		var t = multimesh.get_instance_transform(instance_index)
		t.basis = Basis().scaled(original_scale * scale_mult)
		multimesh.set_instance_transform(instance_index, t)
	, 1.2, 1.0, highlight_duration / 4)

func create_removal_effect(position: Vector3) -> void:
	"""Create visual effect when an instance is removed"""
	# Simple particle burst
	var particles = GPUParticles3D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, -9.8, 0)
	particles.process_material = material

	add_child(particles)

	# Auto-cleanup
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func apply_grid_config(config_data: Dictionary) -> void:
	"""Allow map token config via #key:value syntax."""
	if config_data.is_empty():
		return

	if config_data.has("selection_mode"):
		selection_mode = _parse_selection_mode(config_data.get("selection_mode"))
	elif config_data.has("mode"):
		selection_mode = _parse_selection_mode(config_data.get("mode"))

	if config_data.has("target_column"):
		target_column = int(config_data.get("target_column"))
	elif config_data.has("column"):
		target_column = int(config_data.get("column"))

	if config_data.has("target_row"):
		target_row = int(config_data.get("target_row"))
	elif config_data.has("row"):
		target_row = int(config_data.get("row"))

	if config_data.has("x_min"):
		x_min = float(config_data.get("x_min"))
	if config_data.has("x_max"):
		x_max = float(config_data.get("x_max"))
	if config_data.has("y_min"):
		y_min = float(config_data.get("y_min"))
	if config_data.has("y_max"):
		y_max = float(config_data.get("y_max"))
	if config_data.has("z_min"):
		z_min = float(config_data.get("z_min"))
	if config_data.has("z_max"):
		z_max = float(config_data.get("z_max"))

	if config_data.has("removal_speed"):
		removal_speed = maxf(float(config_data.get("removal_speed")), 0.01)
	if config_data.has("highlight_duration"):
		highlight_duration = maxf(float(config_data.get("highlight_duration")), 0.0)
	if config_data.has("show_removal_effects"):
		show_removal_effects = _to_bool(config_data.get("show_removal_effects"), show_removal_effects)

	if config_data.has("localize_selection_to_artifact"):
		localize_selection_to_artifact = _to_bool(config_data.get("localize_selection_to_artifact"), localize_selection_to_artifact)
	elif config_data.has("local"):
		localize_selection_to_artifact = _to_bool(config_data.get("local"), localize_selection_to_artifact)

	if config_data.has("auto_expand_to_all_if_empty"):
		auto_expand_to_all_if_empty = _to_bool(config_data.get("auto_expand_to_all_if_empty"), auto_expand_to_all_if_empty)

	var was_running := timer and not timer.is_stopped()
	if timer:
		timer.wait_time = 0.5 / maxf(removal_speed, 0.01)

	reset_and_find_instances()
	if was_running:
		start_removal()

func _parse_selection_mode(value: Variant) -> String:
	var mode := str(value).strip_edges().to_lower()
	match mode:
		"all":
			return "All"
		"column", "col", "x":
			return "Column"
		"row", "z":
			return "Row"
		"range":
			return "Range"
		_:
			return selection_mode

func _to_bool(value: Variant, fallback: bool) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	if text in ["true", "1", "yes", "on"]:
		return true
	if text in ["false", "0", "no", "off"]:
		return false
	return fallback

# Public API
func start_removal() -> void:
	"""Start removing instances"""
	if timer:
		timer.start()
		print("Started instance removal")

func stop_removal() -> void:
	"""Stop removing instances"""
	if timer:
		timer.stop()
		print("Stopped instance removal")

func reset_and_find_instances() -> void:
	"""Reset and find all instances again"""
	stop_removal()
	find_all_instances()
	removed_count = 0
	print("Reset complete. Found %d instances." % active_instances.size())

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

