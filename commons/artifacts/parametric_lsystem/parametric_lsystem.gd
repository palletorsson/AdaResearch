# parametric_lsystem.gd
# Symbol rewriting with a turtle whose saved state includes length and angle.
# Parameters change on branch entry and return to their saved values on exit.
# The opt-in Growth lesson exposes the actual interpreter trace in metres.
#
# @identity
# essence: angle(depth) = base_angle * 0.95^depth + random(-var, +var) — parametric decay per branch level
# desire: Follow what a branch inherits, changes and returns to its parent
# critical_parameter: length_decay — the branch length ratio; values above one lengthen
# triggers: Preset switch → Bushy Tree, Willow, Fern Spray, Coral Branch — same engine, different character
# emerges: Natural-looking trees from angle randomization and length decay — no biological model, just parameter gradients
# needs: Growth lesson STEP/RATIO/HOLD/TREE/RESET/RULE [has]; headset review [pending]
# relationships: Feeds into LSystems_Growth. Extends lsystem_tree (fixed angle → parametric decay). Contrasts with AnimatedTree (time vs parameters).
# truth: A resemblance to a plant does not establish a biological growth model.

extends Node3D

class_name ParametricLSystem

signal tree_changed
var lesson_enabled := false
var _built := false
var _batching := false
var _config_overrides: Dictionary = {}
var tree_segments: Array = []
var trace_frames: Array = []
var effective_iterations := 0
var budget_limited := false
var max_symbols := 80000

## Display settings
@export var display_size: float = 1.2
@export var trunk_color: Color = Color(0.55, 0.35, 0.15)
@export var tip_color: Color = Color(0.3, 0.8, 0.2)

## Parametric L-system configuration
@export var axiom: String = "F"
@export var iterations: int = 4
@export var base_length: float = 0.12
@export var base_angle: float = 25.7
@export var length_decay: float = 0.72
@export var angle_variation: float = 8.0

## Current preset index
@export_enum("Bushy Tree", "Willow", "Fern Spray", "Coral Branch") var preset: int = 0:
	set(value):
		preset = clampi(value, 0, 3)
		if not _batching: _apply_preset()

## Preset definitions: [axiom, rules, base_angle, iterations, length_decay, angle_var, name]
const PRESETS = {
	0: ["F", {"F": "F[+F]F[-F]F"}, 25.7, 4, 0.72, 8.0, "Bushy Tree"],
	1: ["F", {"F": "FF[-F][+F]"}, 18.0, 5, 0.68, 12.0, "Willow"],
	2: ["X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, 22.5, 4, 0.75, 6.0, "Fern Spray"],
	3: ["F", {"F": "F[+F][-F]F[++F]F"}, 30.0, 3, 0.65, 15.0, "Coral Branch"],
}

var _rules: Dictionary = {}
var _current_string: String = ""
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42
	_create_display()
	_create_base()
	_create_label()
	_built = true
	_apply_preset()
	if lesson_enabled: _install_lesson()


func _create_display() -> void:
	_immediate_mesh = ImmediateMesh.new()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "ParametricLSystemDisplay"
	_mesh_instance.mesh = _immediate_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)


func _create_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = display_size * 0.35
	cylinder.bottom_radius = display_size * 0.4
	cylinder.height = 0.03
	base.mesh = cylinder

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.1, 0.08)
	mat.metallic = 0.4
	mat.roughness = 0.6
	base.material_override = mat

	base.position = Vector3(0, -0.015, 0)
	add_child(base)


func _create_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 22
	_info_label.modulate = Color(0.85, 0.85, 0.8)
	_info_label.position = Vector3(0, display_size + 0.08, 0)
	add_child(_info_label)


func _apply_preset() -> void:
	if preset < 0 or preset >= PRESETS.size():
		return
	var p: Array = PRESETS[preset]
	axiom = p[0]
	_rules = p[1].duplicate()
	base_angle = p[2]
	iterations = p[3]
	length_decay = p[4]
	angle_variation = p[5]

	for key in _config_overrides: set(key, _config_overrides[key])
	_generate()


func _generate() -> void:
	if not _built: return
	_current_string = axiom
	effective_iterations = 0
	budget_limited = _current_string.length() > max_symbols
	if budget_limited: _current_string = ""
	for _i in range(clampi(iterations, 0, 6)):
		if budget_limited: break
		var next_size := 0
		for c in _current_string:
			next_size += str(_rules.get(c, c)).length()
			if next_size > max_symbols: break
		if next_size > max_symbols:
			budget_limited = true
			break
		var next := ""
		for c in _current_string: next += str(_rules.get(c, c))
		_current_string = next
		effective_iterations += 1
	reinterpret()

func reinterpret() -> void:
	if not _built: return
	_rng.seed = 42
	_draw_tree()
	_update_label()
	tree_changed.emit()


func _draw_tree() -> void:
	if not _immediate_mesh:
		return
	_immediate_mesh.clear_surfaces()
	tree_segments.clear()
	trace_frames.clear()
	if _current_string.is_empty():
		return

	# Turtle state
	var pos := Vector3.ZERO
	var dir := Vector3.UP
	var right := Vector3.RIGHT
	var up := Vector3.FORWARD
	var depth: int = 0
	var current_length: float = base_length
	var current_angle: float = base_angle

	# Stack stores full parametric state
	var stack: Array = []

	# First pass: collect line segments with depth info for coloring
	var segments: Array = []  # [start, end, depth]
	var max_depth: int = 0

	var angle_rad: float = deg_to_rad(current_angle)

	if lesson_enabled:
		trace_frames.append({"symbol":"START", "pos":pos, "dir":dir, "length":current_length, "angle":current_angle, "depth":depth, "stack_depth":0, "segments":0})
	for c in _current_string:
		match c:
			"F", "G":
				var new_pos := pos + dir * current_length
				segments.append([pos, new_pos, depth])
				pos = new_pos
			"f":
				pos += dir * current_length
			"+":
				var varied_angle: float = angle_rad + deg_to_rad(_rng.randf_range(-angle_variation, angle_variation))
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, varied_angle).normalized()
				right = right.rotated(axis, varied_angle).normalized()
			"-":
				var varied_angle: float = angle_rad + deg_to_rad(_rng.randf_range(-angle_variation, angle_variation))
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, -varied_angle).normalized()
				right = right.rotated(axis, -varied_angle).normalized()
			"[":
				stack.append({
					"pos": pos,
					"dir": dir,
					"right": right,
					"up": up,
					"depth": depth,
					"length": current_length,
					"angle": current_angle,
					"angle_rad": angle_rad
				})
				depth += 1
				if depth > max_depth:
					max_depth = depth
				# Parametric decay on branch entry
				current_length *= length_decay
				current_angle *= 0.95
				angle_rad = deg_to_rad(current_angle)
			"]":
				if stack.size() > 0:
					var state: Dictionary = stack.pop_back()
					pos = state["pos"]
					dir = state["dir"]
					right = state["right"]
					up = state["up"]
					depth = state["depth"]
					current_length = state["length"]
					current_angle = state["angle"]
					angle_rad = state["angle_rad"]
			"X":
				pass  # Placeholder symbol, no drawing

		if lesson_enabled:
			trace_frames.append({"symbol":c, "pos":pos, "dir":dir, "length":current_length, "angle":current_angle, "depth":depth, "stack_depth":stack.size(), "segments":segments.size()})
	tree_segments = segments
	if segments.is_empty():
		return

	# Compute bounds for centering and scaling
	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for seg in segments:
		var s: Vector3 = seg[0]
		var e: Vector3 = seg[1]
		min_bounds = min_bounds.min(s).min(e)
		max_bounds = max_bounds.max(s).max(e)

	var bounds_size := max_bounds - min_bounds
	var max_dim: float = maxf(maxf(bounds_size.x, bounds_size.y), maxf(bounds_size.z, 0.001))
	var scale_factor: float = display_size * 0.75 / max_dim
	var center := (min_bounds + max_bounds) / 2.0
	# Shift center down so tree base sits near y=0
	center.y = min_bounds.y

	if max_depth == 0:
		max_depth = 1

	# Draw all segments with depth-based coloring
	# Multi-pass rendering: draw offset copies for thicker appearance
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		Vector3(0.002, 0, 0),
		Vector3(-0.002, 0, 0),
		Vector3(0, 0, 0.002),
		Vector3(0, 0, -0.002),
	]

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for offset in offsets:
		for seg in segments:
			var p1: Vector3 = (seg[0] - center) * scale_factor + offset
			var p2: Vector3 = (seg[1] - center) * scale_factor + offset
			var d: int = seg[2]

			var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
			# Brown trunk → green tips, brightness increases at tips
			var col: Color = trunk_color.lerp(tip_color, t)
			# Brighten tips slightly for implied "line width"
			col = col.lightened(t * 0.15)

			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(p1)
			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(p2)

	_immediate_mesh.surface_end()


func _update_label() -> void:
	if not _info_label:
		return
	var name_str: String = "Custom"
	if preset >= 0 and preset < PRESETS.size():
		name_str = PRESETS[preset][6]
	_info_label.text = "%s\nIter: %d | Angle: %.1f° | Decay: %.2f" % [
		name_str, effective_iterations, base_angle, length_decay
	]
	if effective_iterations != iterations:
		_info_label.text += "\nRequested %d / retained complete generation %d" % [iterations, effective_iterations]


## Grid configuration is retained across readiness and preset resolution.
func apply_grid_config(config_data: Dictionary) -> void:
	if str(config_data.get("lesson", "false")).to_lower() == "true":
		lesson_enabled = true
		max_symbols = 4096
	_batching = true
	if config_data.has("preset"): preset = int(config_data["preset"])
	for key in config_data:
		match str(key):
			"iterations": _config_overrides[key] = clampi(int(config_data[key]), 0, 6)
			"base_angle", "angle_variation": _config_overrides[key] = clampf(float(config_data[key]), 0.0, 180.0)
			"length_decay": _config_overrides[key] = clampf(float(config_data[key]), 0.3, 1.2)
			"base_length", "display_size": _config_overrides[key] = clampf(float(config_data[key]), 0.01, 12.0)
	for key in _config_overrides: set(key, _config_overrides[key])
	_batching = false
	if _built:
		_apply_preset()
		if lesson_enabled: _install_lesson()

func _install_lesson() -> void:
	if has_node("GrowthLesson"): return
	var lesson = load("res://commons/artifacts/growth_lesson/growth_lesson.gd").new()
	lesson.name = "GrowthLesson"
	add_child(lesson)
