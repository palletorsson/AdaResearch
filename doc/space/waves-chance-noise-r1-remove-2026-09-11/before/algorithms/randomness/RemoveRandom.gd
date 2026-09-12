# @identity
# essence: random removal without replacement from an explicitly owned candidate grid
# critical_parameter: selection_mode; eligibility is decided before the random draw
# needs: an owned MultiMesh, or local_grid:true for the restored eight-by-eight bench
extends Node3D

signal state_changed
signal instance_removed(index: int)

@export_enum("Range", "Column", "Row", "All") var selection_mode: String = "Range"
@export var target_column: int = 3
@export var target_row: int = 3
@export var x_min: float = 2.0
@export var x_max: float = 5.0
@export var y_min: float = -1.0
@export var y_max: float = 1.0
@export var z_min: float = 2.0
@export var z_max: float = 5.0
@export var removal_speed: float = 1.0
@export var highlight_duration: float = 0.3
@export var local_grid: bool = false
# Explicit descendants only. Missing or external targets fail closed.
@export var multimesh_path: NodePath = "LocalGrid/GridMultiMesh"

const ELIGIBLE := Color(1.0, 0.68, 0.18)
const EXCLUDED := Color(0.28, 0.35, 0.42)
const HIGHLIGHT := Color(1.0, 0.15, 0.12)
var timer: Timer
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh
var active_instances: Array[int] = []
var initial_count: int = 0
var removed_count: int = 0
var last_removed_index: int = -1
var last_selected_index: int = -1
var _original: Array[Transform3D] = []
var _removed: Dictionary = {}
var _removal_in_progress: bool = false
var _generation: int = 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	timer = Timer.new()
	timer.wait_time = 0.5 / maxf(removal_speed, 0.01)
	timer.timeout.connect(remove_one)
	add_child(timer)
	_bind_owned_grid()

func _bind_owned_grid() -> void:
	if local_grid and not has_node("LocalGrid"):
		var fixture := Node3D.new()
		fixture.name = "LocalGrid"
		fixture.set_script(load("res://algorithms/randomness/remove_random_fixture.gd"))
		add_child(fixture)
		fixture.call("build", self)
	var candidate := get_node_or_null(multimesh_path) as MultiMeshInstance3D
	if candidate == null or not is_ancestor_of(candidate) or candidate.multimesh == null:
		# Never search the room, an ancestor or current_scene for replacement targets.
		stop_removal()
		_generation += 1
		_removal_in_progress = false
		multimesh_instance = null
		multimesh = null
		_original.clear()
		_removed.clear()
		active_instances.clear()
		initial_count = 0
		removed_count = 0
		state_changed.emit()
		return
	if candidate == multimesh_instance:
		reset_and_find_instances()
		return
	multimesh_instance = candidate
	# A descendant node can still share its resource with another scene instance.
	# Own a private copy before changing any instance transforms or colours.
	var source := candidate.multimesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = source.transform_format
	multimesh.use_colors = source.use_colors
	multimesh.use_custom_data = source.use_custom_data
	multimesh.mesh = source.mesh
	multimesh.instance_count = source.instance_count
	for i in range(source.instance_count):
		multimesh.set_instance_transform(i, source.get_instance_transform(i))
		if source.use_colors:
			multimesh.set_instance_color(i, source.get_instance_color(i))
		if source.use_custom_data:
			multimesh.set_instance_custom_data(i, source.get_instance_custom_data(i))
	candidate.multimesh = multimesh
	_original.clear()
	for i in range(multimesh.instance_count):
		_original.append(multimesh.get_instance_transform(i))
	reset_and_find_instances()

func _should_include_instance(pos: Vector3) -> bool:
	# Coordinates belong to the explicit grid, not to museum-world positions.
	match selection_mode:
		"All": return true
		"Column": return is_equal_approx(pos.x, float(target_column))
		"Row": return is_equal_approx(pos.z, float(target_row))
		"Range":
			return pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max and pos.z >= z_min and pos.z <= z_max
	return false

func find_all_instances() -> void:
	active_instances.clear()
	if multimesh == null:
		return
	for i in range(_original.size()):
		if _removed.has(i):
			continue
		var included := _should_include_instance(_original[i].origin)
		if included:
			active_instances.append(i)
		if multimesh.use_colors:
			multimesh.set_instance_color(i, ELIGIBLE if included else EXCLUDED)
	# An empty set stays empty. It never expands to All.
	initial_count = active_instances.size() + removed_count
	state_changed.emit()

func remove_one() -> void:
	if _removal_in_progress or multimesh == null or active_instances.is_empty():
		if active_instances.is_empty():
			stop_removal()
		return
	_removal_in_progress = true
	var generation := _generation
	var offset := _rng.randi_range(0, active_instances.size() - 1)
	var index := active_instances[offset]
	last_selected_index = index
	if multimesh.use_colors:
		multimesh.set_instance_color(index, HIGHLIGHT)
	state_changed.emit()
	await get_tree().create_timer(maxf(highlight_duration, 0.0)).timeout
	# Reset or a new mode cancels a pending draw before it can alter the new run.
	if generation != _generation or not is_inside_tree():
		return
	var transform := _original[index]
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(index, transform)
	_removed[index] = true
	active_instances.remove_at(offset)
	removed_count += 1
	last_removed_index = index
	_removal_in_progress = false
	if active_instances.is_empty():
		stop_removal()
	state_changed.emit()
	instance_removed.emit(index)

func choose_mode(mode: String) -> void:
	selection_mode = _parse_selection_mode(mode)
	reset_and_find_instances()

func reset_and_find_instances() -> void:
	stop_removal()
	_generation += 1
	_removal_in_progress = false
	_removed.clear()
	removed_count = 0
	last_removed_index = -1
	last_selected_index = -1
	if multimesh:
		for i in range(_original.size()):
			multimesh.set_instance_transform(i, _original[i])
	find_all_instances()

func start_removal() -> void:
	if timer and multimesh and not active_instances.is_empty():
		timer.start()

func stop_removal() -> void:
	if timer:
		timer.stop()

func set_random_seed(value: int) -> void:
	_rng.seed = value

func get_state() -> Dictionary:
	return {"bound": multimesh != null, "mode": selection_mode,
		"total": _original.size(), "eligible_at_start": initial_count,
		"remaining": active_instances.size(), "removed": removed_count,
		"last_selected": last_selected_index, "last_removed": last_removed_index,
		"busy": _removal_in_progress, "generation": _generation}

func apply_grid_config(config: Dictionary) -> void:
	if config.has("local_grid"):
		local_grid = _to_bool(config["local_grid"])
	if config.has("selection_mode") or config.has("mode"):
		selection_mode = _parse_selection_mode(str(config.get("selection_mode", config.get("mode"))))
	target_column = int(config.get("target_column", config.get("column", target_column)))
	target_row = int(config.get("target_row", config.get("row", target_row)))
	for key in ["x_min", "x_max", "y_min", "y_max", "z_min", "z_max"]:
		if config.has(key):
			set(key, float(config[key]))
	removal_speed = maxf(float(config.get("removal_speed", removal_speed)), 0.01)
	highlight_duration = maxf(float(config.get("highlight_duration", highlight_duration)), 0.0)
	if is_node_ready():
		timer.wait_time = 0.5 / removal_speed
		_bind_owned_grid()

func _parse_selection_mode(value: String) -> String:
	match value.strip_edges().to_lower():
		"range": return "Range"
		"row", "z": return "Row"
		"column", "col", "x": return "Column"
		"all": return "All"
	return selection_mode

func _to_bool(value: Variant) -> bool:
	return str(value).strip_edges().to_lower() in ["true", "1", "yes", "on"]
