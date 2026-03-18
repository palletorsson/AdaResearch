# ===========================================================================
# NOC Example 8.5: Koch Curve
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.5: Koch Curve
## Koch snowflake fractal with animated depth growth, color gradient, and VR controls
## Chapter 08: Fractals

signal generation_complete(depth: int, segment_count: int)

@export var max_depth: int = 4
@export var line_thickness: float = 0.003
@export var animate_growth: bool = true
@export var snowflake_mode: bool = true

enum ColorScheme { COOL_WARM, ICE, NEON, PINK }
@export var color_scheme: ColorScheme = ColorScheme.COOL_WARM

# Animation state
var _current_depth: int = 0
var _growth_timer: float = 0.0
var _growth_speed: float = 1.2  # Seconds per depth level

# Geometry
var _lines_by_depth: Array = []  # Array of Array[Dictionary] per depth
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh

# UI
var _info_label: Label3D
var _dimension_label: Label3D
var _depth_controller: ParameterController3D

func _ready() -> void:
	_precompute_all_depths()
	_setup_mesh()
	_create_ui()
	_create_controllers()

	if animate_growth:
		_current_depth = 0
		_draw_depth(0)
	else:
		_current_depth = max_depth
		_draw_depth(max_depth)
		generation_complete.emit(max_depth, _lines_by_depth[max_depth].size())

	_update_info_label()

func _process(delta: float) -> void:
	if animate_growth and _current_depth < max_depth:
		_growth_timer += delta
		if _growth_timer >= _growth_speed:
			_growth_timer = 0.0
			_current_depth += 1
			_draw_depth(_current_depth)
			_update_info_label()
			if _current_depth == max_depth:
				generation_complete.emit(max_depth, _lines_by_depth[max_depth].size())

# ---------------------------------------------------------------------------
# Koch subdivision
# ---------------------------------------------------------------------------

func _precompute_all_depths() -> void:
	_lines_by_depth.clear()

	# Starting shape: triangle (snowflake) or single line
	var initial_lines: Array[Dictionary] = []
	if snowflake_mode:
		var r := 0.35
		var p0 := Vector3(-r, 0, 0)
		var p1 := Vector3(r, 0, 0)
		var p2 := Vector3(0, r * sqrt(3.0), 0)
		initial_lines = [
			{"start": p0, "end": p1, "depth": 0},
			{"start": p1, "end": p2, "depth": 0},
			{"start": p2, "end": p0, "depth": 0},
		]
	else:
		initial_lines = [{"start": Vector3(-0.4, 0, 0), "end": Vector3(0.4, 0, 0), "depth": 0}]

	_lines_by_depth.append(initial_lines)

	var current := initial_lines
	for d in range(1, max_depth + 1):
		var next: Array[Dictionary] = []
		for seg in current:
			next.append_array(_koch_subdivide(seg.start, seg.end, d))
		_lines_by_depth.append(next)
		current = next

func _koch_subdivide(start: Vector3, end: Vector3, depth: int) -> Array[Dictionary]:
	var vec := end - start
	var len := vec.length()
	var dir := vec.normalized()

	var a := start
	var b := start + dir * (len / 3.0)
	var d := start + dir * (2.0 * len / 3.0)
	var e := end

	# Equilateral triangle peak
	var mid_point := (b + d) / 2.0
	var perpendicular := Vector3(-dir.y, dir.x, 0)
	var height := (len / 3.0) * sqrt(3.0) / 2.0
	var c := mid_point + perpendicular * height

	return [
		{"start": a, "end": b, "depth": depth},
		{"start": b, "end": c, "depth": depth},
		{"start": c, "end": d, "depth": depth},
		{"start": d, "end": e, "depth": depth},
	]

# ---------------------------------------------------------------------------
# Drawing with ImmediateMesh
# ---------------------------------------------------------------------------

func _setup_mesh() -> void:
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)

func _draw_depth(depth: int) -> void:
	if depth < 0 or depth >= _lines_by_depth.size():
		return

	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var segments: Array = _lines_by_depth[depth]
	for seg in segments:
		var col := _color_for_depth(seg.depth, depth)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(seg.start)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(seg.end)

	_immediate_mesh.surface_end()

func _color_for_depth(seg_depth: int, max_d: int) -> Color:
	var t := 0.0 if max_d == 0 else clampf(float(seg_depth) / float(max_d), 0.0, 1.0)

	match color_scheme:
		ColorScheme.COOL_WARM:
			# Blue → cyan → yellow → red
			return Color(t, 0.4 + 0.4 * (1.0 - abs(2.0 * t - 1.0)), 1.0 - t)
		ColorScheme.ICE:
			# White → pale blue → deep blue
			return Color(0.7 - 0.5 * t, 0.8 - 0.3 * t, 1.0)
		ColorScheme.NEON:
			# Green → magenta
			return Color(t, 1.0 - t, 0.5 + 0.5 * t)
		ColorScheme.PINK:
			# Classic pink with emission feel
			return Color(1.0, 0.6 + 0.3 * (1.0 - t), 0.95 - 0.3 * t)

	return Color.WHITE

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

func _create_ui() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 28
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.9, 1.0)
	_info_label.position = Vector3(0, 0.75, 0)
	add_child(_info_label)

	_dimension_label = Label3D.new()
	_dimension_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dimension_label.font_size = 20
	_dimension_label.modulate = Color(0.8, 0.9, 1.0)
	_dimension_label.position = Vector3(0, 0.6, 0)
	# log(4)/log(3) ≈ 1.2619 — the Koch curve's fractal dimension
	_dimension_label.text = "Fractal dimension: log(4)/log(3) = %.4f\nMore than a line (1), less than a plane (2)" % (log(4.0) / log(3.0))
	add_child(_dimension_label)

func _create_controllers() -> void:
	_depth_controller = ParameterController3D.new()
	_depth_controller.parameter_name = "Depth"
	_depth_controller.min_value = 1.0
	_depth_controller.max_value = 6.0
	_depth_controller.default_value = float(max_depth)
	_depth_controller.step_size = 1.0
	_depth_controller.position = Vector3(0, -0.55, 0)
	_depth_controller.value_changed.connect(_on_depth_changed)
	add_child(_depth_controller)

func _on_depth_changed(new_depth: float) -> void:
	max_depth = int(new_depth)
	_precompute_all_depths()
	_current_depth = max_depth
	_draw_depth(max_depth)
	_update_info_label()
	generation_complete.emit(max_depth, _lines_by_depth[max_depth].size())

func _update_info_label() -> void:
	if _info_label:
		var seg_count := _lines_by_depth[_current_depth].size() if _current_depth < _lines_by_depth.size() else 0
		_info_label.text = "Koch Curve | Depth: %d / %d | Segments: %d" % [_current_depth, max_depth, seg_count]

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func reset() -> void:
	_current_depth = 0
	_growth_timer = 0.0
	_draw_depth(0)
	_update_info_label()

func replay_animation() -> void:
	_current_depth = 0
	_growth_timer = 0.0
	animate_growth = true
	_draw_depth(0)
	_update_info_label()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("depth"):
		max_depth = clampi(int(config.depth), 1, 6)
	if config.has("line_thickness"):
		line_thickness = config.line_thickness
	if config.has("color_scheme"):
		var scheme_name: String = str(config.color_scheme)
		match scheme_name.to_lower():
			"cool_warm": color_scheme = ColorScheme.COOL_WARM
			"ice": color_scheme = ColorScheme.ICE
			"neon": color_scheme = ColorScheme.NEON
			"pink": color_scheme = ColorScheme.PINK
	if config.has("snowflake"):
		snowflake_mode = config.snowflake
	if config.has("animate"):
		animate_growth = config.animate

	_precompute_all_depths()
	if animate_growth:
		replay_animation()
	else:
		_current_depth = max_depth
		_draw_depth(max_depth)
		_update_info_label()
		generation_complete.emit(max_depth, _lines_by_depth[max_depth].size())

	if _depth_controller:
		_depth_controller.set_value(float(max_depth))
