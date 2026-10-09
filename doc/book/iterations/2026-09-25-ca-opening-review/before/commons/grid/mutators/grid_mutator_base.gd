# GridMutatorBase.gd
# Abstract base for per-instance grid-cube mutators that cycle through named
# expressions and write into a target MultiMeshInstance3D's per-instance buffer.
#
# Subclasses override:
#   _initialize_pattern_names()      — populate `pattern_names`
#   _apply_named_pattern(name)       — apply one named expression to the multimesh
#   _post_find_multimesh_setup()     — enable channel-specific MultiMesh flags
#                                       (use_colors / use_custom_data / etc.)
#
# Shared lifecycle handled here: multimesh discovery, NextCube integration,
# auto-cycling, public pattern-control API. Lifted verbatim from the original
# GridColorizer so existing scenes keep working unchanged.
#
# @identity
# essence: lifecycle(find_multimesh, register_patterns, cycle, dispatch) — the
#   shared stem under per-instance grid-cube mutation
# desire: to be the one place every grid-cube mutator (color, visibility,
#   transform, ...) reuses, so per-sequence expressions stay tiny
# critical_parameter: pattern_names — subclass-populated registry that drives
#   the cycle and the NextCube dispatch
# triggers: _ready waits for the GridSystem, finds GridMultiMesh, calls subclass
#   hooks to register patterns and apply the first one
# emerges: a curriculum where one substrate (the multimesh buffer) carries every
#   sequence's principle as a different mapping function
# needs: subclass overrides for _initialize_pattern_names / _apply_named_pattern
#   / _post_find_multimesh_setup
# relationships: GridColorMutator extends this; future GridVisibilityMutator and
#   GridTransformMutator extend this; NextCube drives advance_to_next_pattern
# truth: mutation is a function of position and time, not a property of the cube

class_name GridMutatorBase
extends Node

@export var multimesh_path: NodePath = ""
@export var debug_logs: bool = false
@export var auto_cycle_enabled: bool = true
@export var cycle_interval_seconds: float = 10.0

# Volume dimensions (width, height, depth) in cube units. Vector3i.ZERO means
# "auto-detect a square 2D grid from MultiMesh.instance_count" — the legacy
# behaviour. Set explicitly for 3D volumes (e.g. Vector3i(12, 8, 12) for the
# canonical VR mutation box).
@export var grid_dims: Vector3i = Vector3i.ZERO

var pattern_names: Array = []
var current_pattern_index: int = 0

var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var grid_structure: GridStructureComponent = null
var _cycle_active: bool = false


func _log(message: String) -> void:
	if debug_logs:
		print(message)


# --- subclass contract -----------------------------------------------------

# Subclass populates `pattern_names` (and any internal registry state).
# Called from _ready and again whenever the registry needs a refresh.
func _initialize_pattern_names() -> void:
	pass

# Subclass dispatches one named pattern to the MultiMesh.
func _apply_named_pattern(_pattern_name: String) -> void:
	pass

# Subclass enables channel-specific MultiMesh flags (e.g. use_colors).
# Returns true on success.
func _post_find_multimesh_setup() -> bool:
	return true


# --- shared lifecycle ------------------------------------------------------

func _ready() -> void:
	_initialize_pattern_names()
	await get_tree().create_timer(1.0).timeout

	if not find_multimesh():
		_log("GridMutator: WARNING - Could not find MultiMeshInstance3D")
		return

	if pattern_names.size() > 0:
		_apply_named_pattern(pattern_names[current_pattern_index])
		_log("GridMutator: applied initial pattern: %s" % pattern_names[current_pattern_index])

	connect_to_next_cubes()

	if auto_cycle_enabled:
		start_pattern_cycling()


func find_multimesh() -> bool:
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)
	if not multimesh_instance:
		multimesh_instance = _find_multimesh_recursive(get_parent())
	if not multimesh_instance:
		var scene: Node = get_tree().current_scene if get_tree() else null
		if scene:
			multimesh_instance = _find_multimesh_recursive(scene)

	if not multimesh_instance:
		_log("GridMutator: ERROR - No MultiMeshInstance3D found")
		return false

	multimesh = multimesh_instance.multimesh
	if not multimesh:
		_log("GridMutator: ERROR - MultiMeshInstance3D found but multimesh is null")
		return false

	grid_structure = _find_grid_structure(get_parent())
	if not grid_structure:
		var scene2: Node = get_tree().current_scene if get_tree() else null
		if scene2:
			grid_structure = _find_grid_structure(scene2)

	return _post_find_multimesh_setup()


func _find_multimesh_recursive(node: Node) -> MultiMeshInstance3D:
	if node == null:
		return null
	if node is MultiMeshInstance3D and node.name == "GridMultiMesh":
		return node
	for child in node.get_children():
		var result = _find_multimesh_recursive(child)
		if result:
			return result
	return null


func _find_grid_structure(node: Node) -> GridStructureComponent:
	if node == null:
		return null
	if node is GridStructureComponent:
		return node
	for child in node.get_children():
		var result = _find_grid_structure(child)
		if result:
			return result
	return null


func start_pattern_cycling() -> void:
	if _cycle_active:
		return
	if pattern_names.is_empty():
		_initialize_pattern_names()
		if pattern_names.is_empty():
			_log("GridMutator: no patterns - cycling aborted")
			return
	if not multimesh or multimesh.instance_count == 0:
		_log("GridMutator: no MultiMesh - cycling aborted")
		return

	_cycle_active = true
	while _cycle_active and auto_cycle_enabled and is_inside_tree():
		var pattern_name: String = pattern_names[current_pattern_index]
		_log("GridMutator: pattern %s (%d/%d)" % [pattern_name, current_pattern_index + 1, pattern_names.size()])
		_apply_named_pattern(pattern_name)

		await get_tree().create_timer(max(cycle_interval_seconds, 0.1)).timeout
		if not _cycle_active or not auto_cycle_enabled:
			break

		if pattern_names.is_empty():
			_initialize_pattern_names()
			if pattern_names.is_empty():
				break
		current_pattern_index = (current_pattern_index + 1) % pattern_names.size()
	_cycle_active = false


# --- NextCube integration --------------------------------------------------

func connect_to_next_cubes() -> void:
	var next_cubes: Array = find_next_cubes()
	if next_cubes.size() > 0:
		_log("GridMutator: found %d NextCube(s), disabling auto-cycle" % next_cubes.size())
		auto_cycle_enabled = false
		_cycle_active = false
		for next_cube in next_cubes:
			if next_cube.has_signal("next_requested"):
				next_cube.next_requested.connect(_on_next_requested)


func find_next_cubes() -> Array:
	var next_cubes: Array = []
	var scene: Node = get_tree().current_scene if get_tree() else null
	if scene:
		_find_next_cubes_recursive(scene, next_cubes)
	return next_cubes


func _find_next_cubes_recursive(node: Node, next_cubes: Array) -> void:
	if node == null:
		return
	if node.get_script() and node.get_script().get_global_name() == "NextCube":
		next_cubes.append(node)
	for child in node.get_children():
		_find_next_cubes_recursive(child, next_cubes)


func _on_next_requested(_from_position: Vector3) -> void:
	advance_to_next_pattern()


func advance_to_next_pattern() -> void:
	if pattern_names.is_empty():
		_initialize_pattern_names()
		if pattern_names.is_empty():
			return
	current_pattern_index = (current_pattern_index + 1) % pattern_names.size()
	_apply_named_pattern(pattern_names[current_pattern_index])


# --- public API ------------------------------------------------------------

func get_current_pattern_index() -> int:
	return current_pattern_index


func get_pattern_count() -> int:
	return pattern_names.size()


func set_pattern_by_index(index: int) -> void:
	_initialize_pattern_names()
	if index >= 0 and index < pattern_names.size():
		current_pattern_index = index
		_apply_named_pattern(pattern_names[current_pattern_index])


func get_current_pattern_name() -> String:
	if pattern_names.is_empty():
		return ""
	return pattern_names[current_pattern_index]


func enable_auto_cycle() -> void:
	auto_cycle_enabled = true
	if not _cycle_active:
		start_pattern_cycling()


func disable_auto_cycle() -> void:
	auto_cycle_enabled = false
	_cycle_active = false


func _exit_tree() -> void:
	_cycle_active = false


# --- volumetric helpers ---------------------------------------------------

# Resolve effective grid dimensions. Returns the explicit `grid_dims` if set
# (non-zero), else auto-detects a square 2D grid from instance_count.
func resolve_dims() -> Vector3i:
	if grid_dims != Vector3i.ZERO:
		return grid_dims
	if not multimesh or multimesh.instance_count == 0:
		return Vector3i(1, 1, 1)
	var n: int = multimesh.instance_count
	var s: int = int(ceil(sqrt(float(n))))
	return Vector3i(s, 1, s)


# Convert a flat instance index into a 3D cell coordinate (x, y, z) for the
# given dims. Layout: i = y * (W * D) + z * W + x.
static func cell_xyz(i: int, dims: Vector3i) -> Vector3i:
	var w: int = max(dims.x, 1)
	var d: int = max(dims.z, 1)
	var x: int = i % w
	var z: int = (i / w) % d
	var y: int = i / (w * d)
	return Vector3i(x, y, z)


# Backward-compat: derive a single "grid_size" int for 2D expressions whose
# signature is (i, row, col, grid_size, t, ctx). Use the larger of width/depth
# so wrap-modulo math in old expressions stays correct on rectangular grids.
static func legacy_grid_size(dims: Vector3i) -> int:
	return max(max(dims.x, dims.z), 1)
