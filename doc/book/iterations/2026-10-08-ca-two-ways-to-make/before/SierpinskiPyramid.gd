@tool
extends Node3D
## Finite recursive cube construction. The inherited recipe has six calls:
## four lower corners and two upper placements. The opt-in comparison can gate
## the additional upper call at every depth. Ordinary placements retain it.

# @identity
# essence: six descendants per call by default; the lesson compares a five-call recipe at the same depth and leaf size
# desire: To make a difference between a named recipe and its implementation available to the eye and hand
# critical_parameter: tick sets depth; packing sets leaf size relative to its placements; lesson reveals the extra recursive call
# triggers: COMPARE gates the extra upper call; RULE reveals call and leaf-instance counts; RESET restores the inherited recipe
# emerges: One extra call at each level changes both silhouette and construction cost
# needs: The comparison is source- and desktop-testable; headset comfort and understanding need separate observation
# relationships: Rule 90 comparison in CA_AgentsCircuits; procedure versus resemblance in Fractal_KochSierpinski
# truth: This finite collection of overlapping cubes does not establish the dimension or volume of an ideal Sierpinski limit

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")
const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 3, "dense": 4, "limit": 5}
const PACKING_FILL := {"fused": 1.35, "contact": 1.0, "open": 0.6, "dust": 0.28}

@export var depth: int = 4:
	set(value):
		depth = value
		if Engine.is_editor_hint(): generate()

@export_enum("once", "coarse", "fine", "dense", "limit") var tick: String = "dense":
	set(value):
		tick = value
		depth = int(TICK_LEVELS.get(value, 4))

@export_enum("fused", "contact", "open", "dust") var packing: String = "contact":
	set(value):
		packing = value
		if Engine.is_editor_hint(): generate()

@export var size: float = 1.0:
	set(value):
		size = value
		if Engine.is_editor_hint(): generate()

@export var generate_on_ready: bool = true
var extra_crown: bool = true
var lesson_enabled: bool = false
var leaf_count: int = 0
var _built: bool = false

func _ready() -> void:
	lesson_enabled = lesson_enabled or str(get_meta("config_lesson", "false")) == "true"
	if generate_on_ready and not Engine.is_editor_hint(): generate()
	if lesson_enabled: _install_lesson.call_deferred()

func generate() -> void:
	for child in get_children():
		if not child.get_meta("pyramid_study", false): child.queue_free()
	leaf_count = 0
	_recursive_build(Vector3.ZERO, size * pow(2, depth - 1), depth)
	_built = true

func _recursive_build(pos: Vector3, current_size: float, current_depth: int) -> void:
	if current_depth == 0:
		_spawn_cube(pos)
		return
	var half_size: float = current_size / 2.0
	# This was an unconditional sixth call in the inherited construction.
	# Keep its order and position exactly; the lesson changes only this gate.
	if extra_crown:
		_recursive_build(pos + Vector3(0, half_size, 0), half_size, current_depth - 1)
	var offset: float = half_size / 2.0
	_recursive_build(pos + Vector3(0, offset, 0), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(-offset, -offset, -offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(offset, -offset, -offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(-offset, -offset, offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(offset, -offset, offset), half_size, current_depth - 1)

func _spawn_cube(pos: Vector3) -> void:
	var cube = CUBE_SCENE.instantiate()
	add_child(cube)
	cube.position = pos
	var fill: float = float(PACKING_FILL.get(packing, 1.0))
	cube.scale = Vector3(size, size, size) * fill
	leaf_count += 1

## Switch only the extra call. The remaining placements, depth and leaf size stay.
func set_extra_crown(enabled: bool) -> void:
	if extra_crown == enabled: return
	extra_crown = enabled
	if _built: generate()

func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("tick"):
		var want_tick: String = str(config["tick"])
		if TICK_LEVELS.has(want_tick) and want_tick != tick:
			tick = want_tick
			changed = true
	if config.has("packing"):
		var want_packing: String = str(config["packing"])
		if PACKING_FILL.has(want_packing) and want_packing != packing:
			packing = want_packing
			changed = true
	if changed and _built: generate()
	if str(config.get("lesson", "false")) == "true":
		lesson_enabled = true
		if is_inside_tree(): _install_lesson.call_deferred()

func _install_lesson() -> void:
	if Engine.is_editor_hint() or has_node("PyramidComparison"): return
	var study: Node3D = load("res://commons/artifacts/koch_sierpinski_lesson/pyramid_comparison.gd").new()
	study.name = "PyramidComparison"
	study.set_meta("pyramid_study", true)
	add_child(study)
