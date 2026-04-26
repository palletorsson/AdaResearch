# GridSubstrateRunner.gd
# Single-cell artifact that mounts the visibility + transform mutators (and
# optionally the colour mutator) on the MAP'S existing GridMultiMesh — same
# integration shape as the GridColorizer artifact. It does NOT build its own
# multimesh; instead, the mutators it spawns auto-find the GridMultiMesh in
# the scene tree (the floor/walls produced by GridSystem).
#
# Drop this in a map's interactables grid as `grid_substrate_runner` and the
# whole map's grid floor cycles through Wolfram CA / fractal / BFS frontier
# expressions, with optional colour overlay running on a different rhythm.
#
# @identity
# essence: mount mutators on the existing GridMultiMesh; cycle expressions
#   on the map the player walks
# desire: to be the integrated substrate, not a tabletop showcase — the
#   pattern runs on the actual floor cubes the curriculum already builds
# critical_parameter: visibility_expressions / color_palettes — pick which
#   expressions to register from each registry
# triggers: _ready waits for GridSystem, then mounts visibility + colour
#   mutators with the requested expression sets
# emerges: every map placing this artifact gets a CA-themed floor without
#   any per-map scene-graph editing — it's a one-cell registry placement
# needs: map's GridMultiMesh [from GridSystem]; existing color_palettes.tres;
#   GridVisibilityMutator + Expressions [✓]; GridColorMutator [✓]
# relationships: same integration pattern as GridColorizer (placed via
#   interactables grid, finds GridMultiMesh in scene); replaces the wrong
#   substrate_box approach (which built its own multimesh)
# truth: an integrated substrate edits the floor that's already there

extends Node3D
class_name GridSubstrateRunner

const GRID_VIS_MUTATOR_PATH := "res://commons/grid/mutators/grid_visibility_mutator.gd"
const GRID_VIS_EXPR_PATH := "res://commons/grid/mutators/grid_visibility_expressions.gd"
const GRID_VIS_EXPR_3D_PATH := "res://commons/grid/mutators/grid_visibility_expressions_3d.gd"
const GRID_COLOR_MUTATOR_PATH := "res://commons/grid/mutators/grid_color_mutator.gd"

# Which expressions to enable. Empty arrays = "use the registry's default
# (all of them)". Specific names = filter to just those.
@export var visibility_expressions: Array[String] = []  # e.g. ["rule_30", "sierpinski"]
@export var color_palettes: Array[String] = []  # empty = full default rotation

@export var enable_visibility: bool = true
@export var enable_color: bool = false  # off by default; CA maps usually want the floor white
@export var enable_3d_expressions: bool = false  # only useful on volumetric maps

@export var visibility_cycle_seconds: float = 8.0
@export var color_cycle_seconds: float = 12.0

# Floor-plan mode for visibility — keeps the player able to walk regardless
# of which CA pattern is active. SPAWN_LARGEST identifies the largest
# walkable component without modifying the pattern; AUTO_STITCH adds doors.
@export_enum("disabled", "spawn_largest", "auto_stitch", "algorithm_path")
var floor_plan_mode: int = 1  # default: SPAWN_LARGEST
@export var floor_plan_layers: int = 2

@export var debug_logs: bool = false

var _vis_mutator: Node = null
var _color_mutator: Node = null


func _ready() -> void:
	# Defer mounting one frame so GridSystem has a chance to build its
	# MultiMesh before the mutators start searching for it.
	call_deferred("_mount_mutators")


func _mount_mutators() -> void:
	if enable_visibility:
		_mount_visibility()
	if enable_color:
		_mount_color()


func _mount_visibility() -> void:
	var script: GDScript = load(GRID_VIS_MUTATOR_PATH)
	var expr_script: GDScript = load(GRID_VIS_EXPR_PATH)
	if not (script and expr_script):
		push_warning("GridSubstrateRunner: visibility scripts missing")
		return

	_vis_mutator = script.new()
	_vis_mutator.name = "GridVisibilityMutator"
	# Empty multimesh_path triggers the auto-search for "GridMultiMesh" in
	# the scene tree (parent → scene root). Same as GridColorizer.
	_vis_mutator.multimesh_path = NodePath("")
	_vis_mutator.cycle_interval_seconds = visibility_cycle_seconds
	_vis_mutator.auto_cycle_enabled = true
	_vis_mutator.debug_logs = debug_logs
	_vis_mutator.floor_plan_mode = floor_plan_mode
	_vis_mutator.floor_plan_layers = floor_plan_layers
	add_child(_vis_mutator)

	# 2D expressions always (rule_30, sierpinski, checkerboard, rings).
	var vis_expr: Node = expr_script.new()
	vis_expr.name = "GridVisibilityExpressions"
	add_child(vis_expr)
	vis_expr.register_for(_vis_mutator)

	# 3D expressions only when explicitly enabled and the multimesh is volumetric.
	if enable_3d_expressions:
		var expr_3d_script: GDScript = load(GRID_VIS_EXPR_3D_PATH)
		if expr_3d_script:
			var vis_expr_3d: Node = expr_3d_script.new()
			vis_expr_3d.name = "GridVisibilityExpressions3D"
			vis_expr_3d.bfs_seed = Vector3i(0, 0, 0)
			vis_expr_3d.bfs_steps = 8
			add_child(vis_expr_3d)
			vis_expr_3d.register_for(_vis_mutator)

	# Filter the cycle list if specific expressions were requested.
	if not visibility_expressions.is_empty() and _vis_mutator.has_method("set_pattern_by_index"):
		var filtered: Array = []
		for name in visibility_expressions:
			if _vis_mutator.pattern_names.has(name):
				filtered.append(name)
		if not filtered.is_empty():
			_vis_mutator.pattern_names = filtered
			_vis_mutator.current_pattern_index = 0


func _mount_color() -> void:
	var script: GDScript = load(GRID_COLOR_MUTATOR_PATH)
	if not script:
		return
	_color_mutator = script.new()
	_color_mutator.name = "GridColorMutator"
	_color_mutator.multimesh_path = NodePath("")  # auto-search
	_color_mutator.cycle_interval_seconds = color_cycle_seconds
	_color_mutator.auto_cycle_enabled = true
	_color_mutator.debug_logs = debug_logs
	add_child(_color_mutator)


# Standard hook called by GridSystem after instantiating the artifact.
# Allows per-placement config to override the @export defaults.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("visibility_expressions") and config["visibility_expressions"] is Array:
		visibility_expressions = config["visibility_expressions"]
	if config.has("color_palettes") and config["color_palettes"] is Array:
		color_palettes = config["color_palettes"]
	if config.has("enable_visibility"):
		enable_visibility = bool(config["enable_visibility"])
	if config.has("enable_color"):
		enable_color = bool(config["enable_color"])
	if config.has("enable_3d_expressions"):
		enable_3d_expressions = bool(config["enable_3d_expressions"])
	if config.has("floor_plan_mode"):
		floor_plan_mode = int(config["floor_plan_mode"])
