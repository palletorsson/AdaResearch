# SubstrateBox.gd
# A tabletop 8×7×8 cube of cubes that mounts the grid-mutator substrate
# (color + visibility + 3D-native visibility expressions) and cycles through
# them autonomously. The first spine artifact built natively on the substrate.
#
# Purpose: a teaching object the player walks up to. They see Wolfram-style
# Rule 30 layers extruded into pillars, a Menger sponge fold itself out of
# the volume, a sphere shell carved from cubes, and BFS frontier expansion
# sweeping the box step by step. All driven by the same dispatch loop —
# colour cycles run alongside on a different rhythm.
#
# @identity
# essence: GridVisibilityMutator + GridColorMutator on a self-contained 8×7×8
#   MultiMesh, both auto-cycling
# desire: to be the first spine artifact built on the substrate, proving the
#   refactor produces genuine curriculum content (not just test scenes)
# critical_parameter: cycle_interval_seconds — slower = each rule reads as a
#   tableau, faster = animation; cube_size — 0.12 puts the artifact at ~1m
# triggers: _ready builds the box, mounts the mutators, registers expressions;
#   both mutators auto-cycle independently
# emerges: the same cycling pattern as the substrate test captures, embedded
#   in a real artifact that loads in any map
# needs: GridVisibilityMutator [✓ commons/grid/mutators], GridColorMutator [✓],
#   GridVisibilityExpressions3D [✓], SimpleGrid shader [optional]
# relationships: child of any CA-themed map placing it; uses rule_30 / sierpinski /
#   menger_sponge / sphere_shell / bfs_frontier expressions; sibling of the
#   existing hand-rolled StructureGrowth (125k-instance baked scene)
# truth: an artifact is a substrate plus a few choices about cube size, dims,
#   and cycle rhythm

extends Node3D
class_name SubstrateBox

const GRID_VIS_MUTATOR_PATH := "res://commons/grid/mutators/grid_visibility_mutator.gd"
const GRID_VIS_EXPR_PATH := "res://commons/grid/mutators/grid_visibility_expressions.gd"
const GRID_VIS_EXPR_3D_PATH := "res://commons/grid/mutators/grid_visibility_expressions_3d.gd"
const GRID_COLOR_MUTATOR_PATH := "res://commons/grid/mutators/grid_color_mutator.gd"
const SIMPLE_GRID_SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"

@export var grid_dims: Vector3i = Vector3i(8, 7, 8)
@export var cube_size: float = 0.12  # ~1m total artifact size
@export var visibility_cycle_seconds: float = 4.5
@export var color_cycle_seconds: float = 7.0
@export var debug_logs: bool = false

var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null
var _vis_mutator: Node = null
var _color_mutator: Node = null


func _ready() -> void:
	_build_multimesh()
	_mount_mutators()


# --- artifact build --------------------------------------------------------

func _build_multimesh() -> void:
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "GridMultiMesh"
	add_child(_multimesh_instance)

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3(cube_size * 0.92, cube_size * 0.92, cube_size * 0.92)
	_multimesh.mesh = box
	_multimesh.instance_count = grid_dims.x * grid_dims.y * grid_dims.z

	# Centre horizontally so the artifact stands on its origin's xz plane.
	# Y stacks upward starting at floor level.
	var ox_off: float = -(grid_dims.x - 1) * 0.5 * cube_size
	var oz_off: float = -(grid_dims.z - 1) * 0.5 * cube_size

	for y in range(grid_dims.y):
		for z in range(grid_dims.z):
			for x in range(grid_dims.x):
				var idx: int = y * (grid_dims.x * grid_dims.z) + z * grid_dims.x + x
				var xf := Transform3D()
				xf.origin = Vector3(
					ox_off + x * cube_size,
					y * cube_size + cube_size * 0.5,  # rest on floor
					oz_off + z * cube_size,
				)
				_multimesh.set_instance_transform(idx, xf)
				_multimesh.set_instance_color(idx, Color.WHITE)

	_multimesh_instance.multimesh = _multimesh

	# Material — SimpleGrid shader gives us per-instance colour visibility
	# plus wireframe edges. Falls back to a vertex-color StandardMaterial3D.
	var shader: Shader = load(SIMPLE_GRID_SHADER_PATH)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("show_interior", true)
		mat.set_shader_parameter("modelColor", Color.WHITE)
		mat.set_shader_parameter("wireframeColor", Color(0.4, 0.5, 0.8, 0.6))
		mat.set_shader_parameter("modelOpacity", 1.0)
		mat.set_shader_parameter("wireframeOpacity", 0.5)
		_multimesh_instance.material_override = mat
	else:
		var fallback := StandardMaterial3D.new()
		fallback.vertex_color_use_as_albedo = true
		_multimesh_instance.material_override = fallback


# --- mutator setup ---------------------------------------------------------

func _mount_mutators() -> void:
	var vis_script: GDScript = load(GRID_VIS_MUTATOR_PATH)
	var vis_expr_script: GDScript = load(GRID_VIS_EXPR_PATH)
	var vis_expr_3d_script: GDScript = load(GRID_VIS_EXPR_3D_PATH)
	var color_script: GDScript = load(GRID_COLOR_MUTATOR_PATH)
	if not (vis_script and vis_expr_script and vis_expr_3d_script and color_script):
		push_warning("SubstrateBox: substrate scripts missing — artifact will be an empty cube grid")
		return

	_vis_mutator = vis_script.new()
	_vis_mutator.name = "GridVisibilityMutator"
	_vis_mutator.multimesh_path = NodePath("../GridMultiMesh")
	_vis_mutator.grid_dims = grid_dims
	_vis_mutator.cycle_interval_seconds = visibility_cycle_seconds
	_vis_mutator.auto_cycle_enabled = true
	_vis_mutator.debug_logs = debug_logs
	add_child(_vis_mutator)

	# 2D expressions: rule_30, sierpinski, checkerboard, rings (extrude across y)
	var vis_expr: Node = vis_expr_script.new()
	vis_expr.name = "GridVisibilityExpressions"
	add_child(vis_expr)
	vis_expr.register_for(_vis_mutator)

	# 3D-native expressions: menger_sponge, sphere_shell, bfs_frontier_t1..t8
	var vis_expr_3d: Node = vis_expr_3d_script.new()
	vis_expr_3d.name = "GridVisibilityExpressions3D"
	vis_expr_3d.bfs_seed = Vector3i(0, 0, 0)
	vis_expr_3d.bfs_steps = 8
	add_child(vis_expr_3d)
	vis_expr_3d.register_for(_vis_mutator)

	# Color mutator runs on its own rhythm so colour and visibility shift
	# at different rates — the artifact never repeats exactly.
	_color_mutator = color_script.new()
	_color_mutator.name = "GridColorMutator"
	_color_mutator.multimesh_path = NodePath("../GridMultiMesh")
	_color_mutator.grid_dims = grid_dims
	_color_mutator.cycle_interval_seconds = color_cycle_seconds
	_color_mutator.auto_cycle_enabled = true
	_color_mutator.debug_logs = debug_logs
	add_child(_color_mutator)


# Standard hook called by GridSystem after instantiating the artifact.
# Lets a map-level config override the artifact's defaults.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("grid_dims"):
		var dims = config["grid_dims"]
		if dims is Vector3i:
			grid_dims = dims
	if config.has("cube_size") and (config["cube_size"] is float or config["cube_size"] is int):
		cube_size = float(config["cube_size"])
	if config.has("visibility_cycle_seconds") and config["visibility_cycle_seconds"] is float:
		visibility_cycle_seconds = config["visibility_cycle_seconds"]
	if config.has("color_cycle_seconds") and config["color_cycle_seconds"] is float:
		color_cycle_seconds = config["color_cycle_seconds"]
