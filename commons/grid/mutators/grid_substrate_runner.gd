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
const GRID_GLYPH_MUTATOR_PATH := "res://commons/grid/mutators/grid_glyph_mutator.gd"
const GRID_GLYPH_EXPR_PATH := "res://commons/grid/mutators/grid_glyph_expressions.gd"
const GRID_PART_MUTATOR_PATH := "res://commons/grid/mutators/grid_part_mutator.gd"
const GRID_PART_EXPR_PATH := "res://commons/grid/mutators/grid_part_expressions.gd"

# Which expressions to enable. Empty arrays = "use the registry's default
# (all of them)". Specific names = filter to just those.
@export var visibility_expressions: Array[String] = []  # e.g. ["rule_30", "sierpinski"]
@export var color_palettes: Array[String] = []  # empty = full default rotation

@export var enable_visibility: bool = true
@export var enable_color: bool = false  # off by default; CA maps usually want the floor white
@export var enable_3d_expressions: bool = false  # only useful on volumetric maps

@export var visibility_cycle_seconds: float = 8.0
@export var color_cycle_seconds: float = 12.0

# Floor-plan mode for visibility. PATH_GUARANTEE is the right choice for
# floor-CA maps: it BFS-fills the cheapest cubes needed so the player can
# walk from spawn to teleporter regardless of which pattern is active.
@export_enum("disabled", "spawn_largest", "auto_stitch", "algorithm_path", "path_guarantee")
var floor_plan_mode: int = 4  # default: PATH_GUARANTEE
@export var floor_plan_layers: int = 2

# Override start/goal cells. When (-1,-1,-1), the runner auto-discovers from
# the map's utilities layer (spawn marker = "sp", teleporter marker = "t").
@export var path_seed: Vector3i = Vector3i(-1, -1, -1)
@export var path_target: Vector3i = Vector3i(-1, -1, -1)

@export var debug_logs: bool = false

# --- glyph (subdivision) channel ------------------------------------------
@export var enable_glyph: bool = false
@export var glyph_policy: String = "subdivide_by_attention"
@export var glyph_max_subdivided_cells: int = 96
@export var glyph_viewer_radius: float = 4.0
@export var glyph_cycle_seconds: float = 9.0

# --- part (role-tagging) channel ------------------------------------------
@export var enable_part: bool = false
@export var part_grammar: String = "flower_grammar"

# When part + color-by-role both on, the runner paints the multimesh per-role
# using this palette after each visibility cycle. Keys are role-StringNames
# (cast from the dictionary's Node-side strings).
@export var enable_color_by_role: bool = false
@export var color_by_role_palette: Dictionary = {
	"pistil": Color(1.0, 0.85, 0.2),
	"stamen": Color(0.95, 0.55, 0.85),
	"petal":  Color(0.65, 0.2, 0.5),
	"sepal":  Color(0.3, 0.6, 0.35),
	"head":    Color(0.85, 0.3, 0.25),
	"thorax":  Color(0.95, 0.75, 0.2),
	"abdomen": Color(0.35, 0.4, 0.7),
}

var _vis_mutator: Node = null
var _color_mutator: Node = null
var _glyph_mutator: Node = null
var _part_mutator: Node = null


func _ready() -> void:
	# Defer mounting one frame so GridSystem has a chance to build its
	# MultiMesh before the mutators start searching for it.
	call_deferred("_mount_mutators")


func _mount_mutators() -> void:
	if enable_visibility:
		_mount_visibility()
	if enable_color:
		_mount_color()
	if enable_part:
		_mount_part()
	if enable_glyph:
		_mount_glyph()  # mount last so it sees visibility's final per-cube state
	if enable_color_by_role and _part_mutator:
		# Hook a per-frame poll so role-painting follows part-grammar updates.
		# Simplest reliable scheme: a Timer that paints periodically.
		var paint_timer := Timer.new()
		paint_timer.wait_time = 1.5
		paint_timer.autostart = true
		paint_timer.one_shot = false
		paint_timer.timeout.connect(_paint_by_role)
		add_child(paint_timer)
		# First paint immediately after the part mutator has had a chance to apply.
		await get_tree().create_timer(2.0).timeout
		_paint_by_role()


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
	# Set grid_dims to match the actual map. resolve_dims() can't auto-detect
	# rectangular maps from instance_count alone — it'd default to a square.
	var map_dims: Vector3i = _read_map_dimensions()
	if map_dims != Vector3i.ZERO:
		_vis_mutator.grid_dims = map_dims
		if debug_logs:
			print("GridSubstrateRunner: grid_dims=%s from map" % map_dims)
	_vis_mutator.cycle_interval_seconds = visibility_cycle_seconds
	_vis_mutator.auto_cycle_enabled = true
	_vis_mutator.debug_logs = debug_logs
	_vis_mutator.floor_plan_mode = floor_plan_mode
	_vis_mutator.floor_plan_layers = floor_plan_layers

	# Resolve spawn/teleporter for PATH_GUARANTEE.
	var seed: Vector3i = path_seed
	var target: Vector3i = path_target
	if seed.x < 0 or target.x < 0:
		var auto: Dictionary = _discover_spawn_and_teleporter()
		if seed.x < 0 and auto.has("seed"):
			seed = auto["seed"]
		if target.x < 0 and auto.has("target"):
			target = auto["target"]
	if seed.x >= 0:
		_vis_mutator.floor_plan_seed = seed
	if target.x >= 0:
		_vis_mutator.floor_plan_target = target
	# Diagnostic so we can see in capture logs whether discovery worked.
	print("GridSubstrateRunner: floor_plan_mode=%d layers=%d seed=%s target=%s (discovery=%s)" % [
		floor_plan_mode, floor_plan_layers, seed, target,
		"OK" if (seed.x >= 0 and target.x >= 0) else "DEFAULTED-TO-CORNERS",
	])
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


func _mount_part() -> void:
	var script: GDScript = load(GRID_PART_MUTATOR_PATH)
	var expr_script: GDScript = load(GRID_PART_EXPR_PATH)
	if not (script and expr_script):
		return
	_part_mutator = script.new()
	_part_mutator.name = "GridPartMutator"
	_part_mutator.multimesh_path = NodePath("")
	var map_dims: Vector3i = _read_map_dimensions()
	if map_dims != Vector3i.ZERO:
		_part_mutator.grid_dims = map_dims
	_part_mutator.auto_cycle_enabled = false  # part runs once at start, not on a cycle
	_part_mutator.debug_logs = debug_logs
	add_child(_part_mutator)
	var expr: Node = expr_script.new()
	expr.name = "GridPartExpressions"
	add_child(expr)
	expr.register_for(_part_mutator)
	# Apply the configured grammar once.
	for j in range(_part_mutator.get_pattern_count()):
		_part_mutator.set_pattern_by_index(j)
		if _part_mutator.get_current_pattern_name() == part_grammar:
			break


func _mount_glyph() -> void:
	var script: GDScript = load(GRID_GLYPH_MUTATOR_PATH)
	var expr_script: GDScript = load(GRID_GLYPH_EXPR_PATH)
	if not (script and expr_script):
		return
	_glyph_mutator = script.new()
	_glyph_mutator.name = "GridGlyphMutator"
	_glyph_mutator.multimesh_path = NodePath("")
	var map_dims: Vector3i = _read_map_dimensions()
	if map_dims != Vector3i.ZERO:
		_glyph_mutator.grid_dims = map_dims
	_glyph_mutator.cycle_interval_seconds = glyph_cycle_seconds
	_glyph_mutator.auto_cycle_enabled = true
	_glyph_mutator.max_subdivided_cells = glyph_max_subdivided_cells
	_glyph_mutator.viewer_radius = glyph_viewer_radius
	_glyph_mutator.debug_logs = debug_logs
	add_child(_glyph_mutator)
	var expr: Node = expr_script.new()
	expr.name = "GridGlyphExpressions"
	add_child(expr)
	expr.register_for(_glyph_mutator)
	# Set the configured policy.
	for j in range(_glyph_mutator.get_pattern_count()):
		_glyph_mutator.set_pattern_by_index(j)
		if _glyph_mutator.get_current_pattern_name() == glyph_policy:
			break


# Paint the multimesh per-role using the configured palette. Reads the part
# mutator's role table; cubes without a role-match in the palette stay white.
func _paint_by_role() -> void:
	if not _part_mutator or not _vis_mutator:
		return
	var multimesh = _vis_mutator.multimesh
	if not multimesh or not multimesh.use_colors:
		return
	# Build a StringName-keyed palette so the dict lookup matches part roles.
	var palette: Dictionary = {}
	for k in color_by_role_palette.keys():
		palette[StringName(str(k))] = color_by_role_palette[k]
	for i in range(multimesh.instance_count):
		var role: StringName = _part_mutator.get_role(i)
		var color: Color = palette.get(role, Color.WHITE)
		multimesh.set_instance_color(i, color)


# Read the map's actual W/D/H dimensions directly from GridDataComponent
# (the same component the spawn / interactables / structure systems read
# from). Falls back to a generic property search if the component isn't
# found, then to ZERO.
func _read_map_dimensions() -> Vector3i:
	var data_comp: Node = _find_grid_data_component()
	if data_comp and data_comp.has_method("get_grid_dimensions"):
		var dims: Variant = data_comp.call("get_grid_dimensions")
		if dims is Vector3i and dims != Vector3i.ZERO:
			return dims
	# Fallback heuristic — first node with width/depth/max_height. Less
	# reliable because preview / catalog components can match.
	var scene: Node = get_tree().current_scene if get_tree() else null
	if not scene:
		return Vector3i.ZERO
	for n in scene.find_children("*", "", true, false):
		if "width" in n and "depth" in n:
			var w: int = int(n.get("width"))
			var d: int = int(n.get("depth"))
			var h: int = int(n.get("max_height")) if "max_height" in n else 1
			return Vector3i(w, max(h, 1), d)
	return Vector3i.ZERO


# Find the map's spawn ("sp") and teleporter ("t") cells directly from the
# map data — the utilities layer holds them. This is more reliable than
# walking the scene tree for nodes named "spawn"/"teleport".
func _discover_spawn_and_teleporter() -> Dictionary:
	var out: Dictionary = {}
	var data_comp: Node = _find_grid_data_component()
	if not data_comp:
		print("GridSubstrateRunner: discovery — no GridDataComponent in scene")
		return out
	# Get the raw 2D Array of utility-cell strings via the data component's
	# json_loader (matches GridSpawnComponent's _find_teleporter_position).
	var utilities: Variant = null
	if "json_loader" in data_comp and data_comp.json_loader:
		var loader = data_comp.json_loader
		if loader.has_method("get_utilities_layer"):
			utilities = loader.get_utilities_layer()
	if not (utilities is Array):
		print("GridSubstrateRunner: discovery — utilities layer not Array (got %s)" % str(typeof(utilities)))
		return out
	for z in range(utilities.size()):
		var row = utilities[z]
		if typeof(row) != TYPE_ARRAY:
			continue
		for x in range(row.size()):
			var cell: String = str(row[x]).strip_edges()
			if cell.is_empty():
				continue
			if not out.has("seed") and (cell == "sp" or cell.begins_with("sp:")):
				out["seed"] = Vector3i(x, 0, z)
			if not out.has("target") and (cell == "t" or cell.begins_with("t:")):
				out["target"] = Vector3i(x, 0, z)
			if out.has("seed") and out.has("target"):
				return out
	return out


# Walk the loaded scene for a GridDataComponent (where the map's utilities
# layer lives).
func _find_grid_data_component() -> Node:
	var scene: Node = get_tree().current_scene if get_tree() else null
	if not scene:
		return null
	for n in scene.find_children("*", "", true, false):
		var s: Script = n.get_script()
		while s:
			if s.get_global_name() == "GridDataComponent":
				return n
			s = s.get_base_script()
	return null


func _node_to_cell(node: Node) -> Vector3i:
	if node is Node3D:
		var p: Vector3 = (node as Node3D).global_position
		return Vector3i(int(round(p.x)), 0, int(round(p.z)))
	return Vector3i(0, 0, 0)


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
