# lsystem_tree.gd
# Simple deterministic L-system tree for the Grammar Lab.
# Uses the classic plant rule F -> F[+F]F[-F]F with a 25.7 degree
# branching angle, rendered as line segments with a brown-to-green
# depth gradient.

extends Node3D

class_name LSystemTree

## Display settings
@export var display_size: float = 0.6
@export var trunk_color: Color = Color(0.45, 0.28, 0.12)
@export var tip_color: Color = Color(0.2, 0.65, 0.15)

## L-system configuration
@export var iterations: int = 4
@export var base_angle: float = 25.7
@export var base_length: float = 0.1

var _axiom: String = "F"
var _rules: Dictionary = {"F": "F[+F]F[-F]F"}
var _current_string: String = ""
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D


func _ready() -> void:
	_create_display()
	_create_base()
	_create_label()
	_generate()


func _create_display() -> void:
	_immediate_mesh = ImmediateMesh.new()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "LSystemTreeDisplay"
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


func _generate() -> void:
	# Rewrite axiom through iterations
	_current_string = _axiom

	for _i in range(iterations):
		var next := ""
		for c in _current_string:
			if _rules.has(c):
				next += _rules[c]
			else:
				next += c
		_current_string = next
		if _current_string.length() > 80000:
			break

	_draw_tree()
	_update_label()


func _draw_tree() -> void:
	if not _immediate_mesh:
		return
	_immediate_mesh.clear_surfaces()
	if _current_string.is_empty():
		return

	# Turtle state
	var pos := Vector3.ZERO
	var dir := Vector3.UP
	var right := Vector3.RIGHT
	var up := Vector3.FORWARD
	var depth: int = 0
	var current_length: float = base_length

	# Stack stores turtle state
	var stack: Array = []

	# First pass: collect line segments with depth info for coloring
	var segments: Array = []  # [start, end, depth]
	var max_depth: int = 0

	var angle_rad: float = deg_to_rad(base_angle)

	for c in _current_string:
		match c:
			"F":
				var new_pos := pos + dir * current_length
				segments.append([pos, new_pos, depth])
				pos = new_pos
			"+":
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, angle_rad).normalized()
				right = right.rotated(axis, angle_rad).normalized()
			"-":
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, -angle_rad).normalized()
				right = right.rotated(axis, -angle_rad).normalized()
			"[":
				stack.append({
					"pos": pos,
					"dir": dir,
					"right": right,
					"up": up,
					"depth": depth,
					"length": current_length,
				})
				depth += 1
				if depth > max_depth:
					max_depth = depth
				# Shorten branches at deeper levels
				current_length *= 0.72
			"]":
				if stack.size() > 0:
					var state: Dictionary = stack.pop_back()
					pos = state["pos"]
					dir = state["dir"]
					right = state["right"]
					up = state["up"]
					depth = state["depth"]
					current_length = state["length"]

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
	# Anchor at bottom-center so tree base sits near y=0
	var center := (min_bounds + max_bounds) / 2.0
	center.y = min_bounds.y

	if max_depth == 0:
		max_depth = 1

	# Draw all segments with depth-based coloring
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for seg in segments:
		var p1: Vector3 = (seg[0] - center) * scale_factor
		var p2: Vector3 = (seg[1] - center) * scale_factor
		var d: int = seg[2]

		var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		# Brown trunk to green tips gradient
		var col: Color = trunk_color.lerp(tip_color, t)
		col = col.lightened(t * 0.15)

		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(p1)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(p2)

	_immediate_mesh.surface_end()


func _update_label() -> void:
	if not _info_label:
		return
	var segment_count: int = _current_string.count("F")
	_info_label.text = "L-System Tree\nRule: F->F[+F]F[-F]F\nIter: %d | Angle: %.1f° | Segments: %d" % [
		iterations, base_angle, segment_count
	]


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 1, 6)
	if config_data.has("base_angle"):
		base_angle = float(config_data["base_angle"])
	if config_data.has("base_length"):
		base_length = clampf(float(config_data["base_length"]), 0.01, 0.5)
	if config_data.has("display_size"):
		display_size = float(config_data["display_size"])
	_generate()
