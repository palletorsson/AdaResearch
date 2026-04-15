# ===========================================================================
# DistanceFieldsSDF — Blend Operations & Ray Marching
# Signed distance field visualization with blend ops and ray marching
# Elevated features:
#   - Blend operations (union, intersection, smooth min)
#   - Ray marching visualization with step circles
#   - SDF gradient flow field arrows
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

extends Node3D

## Signed distance field with blend operations, ray marching, and gradient flow.
## Modes: SDF_FIELD shows the distance field colored by sign and magnitude;
## RAY_MARCH shows sphere-tracing steps from a moving origin;
## GRADIENT_FLOW shows gradient descent arrows flowing toward surfaces.

# --- Configuration ---
@export var field_resolution: int = 40
@export var field_size: float = 6.0
@export var step_speed: float = 1.0
@export var show_grid: bool = true
@export var show_shapes: bool = true
@export var smooth_k: float = 0.8

# --- Mode ---
enum Mode { SDF_FIELD, RAY_MARCH, GRADIENT_FLOW }
var _mode: int = Mode.SDF_FIELD

# --- Blend operation ---
enum BlendOp { UNION, INTERSECTION, SMOOTH_UNION, SUBTRACTION }
var _blend_op: int = BlendOp.UNION

# --- Internal state ---
var _time: float = 0.0
var _shapes: Array = []  # Array of Dicts {type, pos, radius/size}

# Ray march state
var _ray_origin: Vector2 = Vector2(-3.5, 0.0)
var _ray_dir: Vector2 = Vector2(1.0, 0.2).normalized()
var _ray_steps: Array = []  # Array of {pos: Vector2, dist: float}
var _ray_max_steps: int = 30
var _ray_hit: bool = false
var _ray_march_step: int = 0
var _ray_step_timer: float = 0.0
var _ray_animating: bool = false

# Gradient flow state
var _gradient_arrows: Array = []  # Array of {pos: Vector2, grad: Vector2}
var _flow_particles: Array = []  # Array of {pos: Vector2, vel: Vector2}

# --- Rendering ---
var _field_im: ImmediateMesh
var _field_mi: MeshInstance3D
var _shapes_im: ImmediateMesh
var _shapes_mi: MeshInstance3D
var _contour_im: ImmediateMesh
var _contour_mi: MeshInstance3D
var _ray_im: ImmediateMesh
var _ray_mi: MeshInstance3D
var _gradient_im: ImmediateMesh
var _gradient_mi: MeshInstance3D
var _grid_im: ImmediateMesh
var _grid_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _info_label: Label3D
var _blend_label: Label3D
var _mode_label: Label3D

# VR controls
# VR controls
var _control_rack: Node3D

# Colors
const COL_INSIDE := Color(1.0, 0.15, 0.2, 0.7)
const COL_BOUNDARY := Color(1.0, 1.0, 0.2, 0.9)
const COL_OUTSIDE := Color(0.2, 0.5, 1.0, 0.5)
const COL_SHAPE := Color(1.0, 0.85, 0.2)
const COL_SHAPE_OUTLINE := Color(1.0, 0.65, 0.1)
const COL_RAY := Color(0.1, 1.0, 0.4, 0.9)
const COL_RAY_CIRCLE := Color(0.1, 0.9, 0.5, 0.3)
const COL_RAY_HIT := Color(1.0, 0.2, 0.15)
const COL_GRADIENT := Color(0.9, 0.4, 1.0, 0.8)
const COL_FLOW := Color(0.4, 1.0, 0.8, 0.7)
const COL_CONTOUR := Color(1.0, 1.0, 1.0, 0.4)
const COL_GRID := Color(0.3, 0.3, 0.35, 0.15)

# Slider refs for export setter sync
var _smooth_slider: Node
var _res_slider: Node

func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_create_shapes()
	_init_mode()

# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_field_im = ImmediateMesh.new()
	_field_mi = MeshInstance3D.new()
	_field_mi.mesh = _field_im
	_field_mi.material_override = _mat_alpha
	add_child(_field_mi)

	_shapes_im = ImmediateMesh.new()
	_shapes_mi = MeshInstance3D.new()
	_shapes_mi.mesh = _shapes_im
	_shapes_mi.material_override = _mat_unshaded
	add_child(_shapes_mi)

	_contour_im = ImmediateMesh.new()
	_contour_mi = MeshInstance3D.new()
	_contour_mi.mesh = _contour_im
	_contour_mi.material_override = _mat_alpha
	add_child(_contour_mi)

	_ray_im = ImmediateMesh.new()
	_ray_mi = MeshInstance3D.new()
	_ray_mi.mesh = _ray_im
	_ray_mi.material_override = _mat_alpha
	add_child(_ray_mi)

	_gradient_im = ImmediateMesh.new()
	_gradient_mi = MeshInstance3D.new()
	_gradient_mi.mesh = _gradient_im
	_gradient_mi.material_override = _mat_alpha
	add_child(_gradient_mi)

	_grid_im = ImmediateMesh.new()
	_grid_mi = MeshInstance3D.new()
	_grid_mi.mesh = _grid_im
	_grid_mi.material_override = _mat_alpha
	add_child(_grid_mi)

# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, field_size * 0.5 + 1.2, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 22
	_info_label.outline_size = 3
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, field_size * 0.5 + 0.7, 0)
	_info_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_info_label)

	_blend_label = Label3D.new()
	_blend_label.font_size = 20
	_blend_label.outline_size = 3
	_blend_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_blend_label.position = Vector3(0, field_size * 0.5 + 0.3, 0)
	_blend_label.modulate = Color(1.0, 0.8, 0.6)
	add_child(_blend_label)

	_mode_label = Label3D.new()
	_mode_label.font_size = 18
	_mode_label.outline_size = 3
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.position = Vector3(0, -field_size * 0.5 - 0.6, 0)
	_mode_label.modulate = Color(0.7, 0.8, 1.0)
	add_child(_mode_label)

	_update_labels()

# =========================================================================
# VR Controls
# =========================================================================

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_rack = RackTpl.create_panel("SDF FIELDS", [
		[{"type": "slider_h", "label": "SMOOTH", "default": clampf(smooth_k / 2.0, 0.0, 1.0)}, {"type": "slider_h", "label": "RES", "default": clampf((field_resolution - 15.0) / 45.0, 0.0, 1.0)}],
		[{"type": "button", "label": "MODE"}, {"type": "button", "label": "BLEND"}, {"type": "button", "label": "RESTART"}],
	])
	_control_rack.position = Vector3(0, -field_size * 0.5 - 1.5, 0.3)
	_control_rack.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_rack)

	_smooth_slider = _control_rack.find_child("Param_0", true, false)
	if _smooth_slider and _smooth_slider.has_signal("slider_moved"):
		_smooth_slider.slider_moved.connect(_on_smooth_changed)

	_res_slider = _control_rack.find_child("Param_1", true, false)
	if _res_slider and _res_slider.has_signal("slider_moved"):
		_res_slider.slider_moved.connect(_on_res_changed)

	var mode_btn: Node = _control_rack.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_mode_pressed())

	var blend_btn: Node = _control_rack.find_child("Btn_1", true, false)
	if blend_btn:
		var area = blend_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_blend_pressed())

	var restart_btn: Node = _control_rack.find_child("Btn_2", true, false)
	if restart_btn:
		var area = restart_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_restart_pressed())

func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()

func _on_blend_pressed() -> void:
	_blend_op = (_blend_op + 1) % 4

func _on_restart_pressed() -> void:
	_create_shapes()
	_init_mode()

func _on_smooth_changed(_value: float) -> void:
	var slider: Node = _control_rack.find_child("Param_0", true, false)
	if slider and slider.has_method("get_normalized_value"):
		smooth_k = slider.get_normalized_value() * 2.0

func _on_res_changed(_value: float) -> void:
	var slider: Node = _control_rack.find_child("Param_1", true, false)
	if slider and slider.has_method("get_normalized_value"):
		field_resolution = int(lerpf(15.0, 60.0, slider.get_normalized_value()))

# =========================================================================
# Shape creation
# =========================================================================

func _create_shapes() -> void:
	_shapes.clear()
	_shapes.append({
		"type": "sphere",
		"pos": Vector2(-1.2, 0.5),
		"radius": 1.2
	})
	_shapes.append({
		"type": "sphere",
		"pos": Vector2(1.0, -0.3),
		"radius": 0.9
	})
	_shapes.append({
		"type": "box",
		"pos": Vector2(0.0, -1.5),
		"size": Vector2(1.5, 0.6)
	})
	_shapes.append({
		"type": "sphere",
		"pos": Vector2(2.0, 1.5),
		"radius": 0.7
	})

func _init_mode() -> void:
	_ray_steps.clear()
	_ray_hit = false
	_ray_march_step = 0
	_ray_step_timer = 0.0
	_ray_animating = false
	_flow_particles.clear()

	match _mode:
		Mode.RAY_MARCH:
			_ray_origin = Vector2(-field_size * 0.45, sin(_time) * 1.5)
			_ray_dir = Vector2(1.0, 0.15 + sin(_time * 0.5) * 0.3).normalized()
			_ray_animating = true
		Mode.GRADIENT_FLOW:
			_init_flow_particles()

func _init_flow_particles() -> void:
	_flow_particles.clear()
	var hs := field_size * 0.5
	for i in range(80):
		_flow_particles.append({
			"pos": Vector2(randf_range(-hs, hs), randf_range(-hs, hs)),
			"life": randf_range(0.0, 3.0)
		})

# =========================================================================
# SDF computation
# =========================================================================

func _sdf_sphere(pos: Vector2, center: Vector2, radius: float) -> float:
	return pos.distance_to(center) - radius

func _sdf_box(pos: Vector2, center: Vector2, half_size: Vector2) -> float:
	var d := Vector2(absf(pos.x - center.x), absf(pos.y - center.y)) - half_size
	return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length() + minf(maxf(d.x, d.y), 0.0)

func _sdf_shape(pos: Vector2, shape: Dictionary) -> float:
	match shape["type"]:
		"sphere":
			return _sdf_sphere(pos, shape["pos"], shape["radius"])
		"box":
			return _sdf_box(pos, shape["pos"], shape["size"])
	return INF

func _blend(a: float, b: float) -> float:
	match _blend_op:
		BlendOp.UNION:
			return minf(a, b)
		BlendOp.INTERSECTION:
			return maxf(a, b)
		BlendOp.SMOOTH_UNION:
			return _smooth_min(a, b, smooth_k)
		BlendOp.SUBTRACTION:
			return maxf(a, -b)
	return minf(a, b)

func _smooth_min(a: float, b: float, k: float) -> float:
	if k < 0.001:
		return minf(a, b)
	var h := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)

func _evaluate_sdf(pos: Vector2) -> float:
	if _shapes.is_empty():
		return INF
	var result := _sdf_shape(pos, _shapes[0])
	for i in range(1, _shapes.size()):
		var d := _sdf_shape(pos, _shapes[i])
		result = _blend(result, d)
	return result

func _evaluate_gradient(pos: Vector2) -> Vector2:
	var eps := 0.02
	var dx := _evaluate_sdf(pos + Vector2(eps, 0)) - _evaluate_sdf(pos - Vector2(eps, 0))
	var dy := _evaluate_sdf(pos + Vector2(0, eps)) - _evaluate_sdf(pos - Vector2(0, eps))
	var g := Vector2(dx, dy)
	var len := g.length()
	if len > 0.001:
		return g / len
	return Vector2.ZERO

# =========================================================================
# _process
# =========================================================================

func _process(delta: float) -> void:
	_time += delta

	# Animate shape positions gently
	for i in range(_shapes.size()):
		var shape = _shapes[i]
		var base_y: float
		match i:
			0: base_y = 0.5
			1: base_y = -0.3
			2: base_y = -1.5
			3: base_y = 1.5
			_: base_y = 0.0
		shape["pos"].y = base_y + sin(_time * 0.8 + float(i) * 1.7) * 0.3

	match _mode:
		Mode.RAY_MARCH:
			_process_ray_march(delta)
		Mode.GRADIENT_FLOW:
			_process_gradient_flow(delta)

	_draw_all()
	_update_labels()

func _process_ray_march(delta: float) -> void:
	if not _ray_animating:
		_ray_step_timer += delta
		if _ray_step_timer > 3.0:
			_init_mode()
		return

	_ray_step_timer += delta
	var interval := 1.0 / maxf(step_speed * 3.0, 0.1)
	if _ray_step_timer < interval:
		return
	_ray_step_timer = 0.0

	if _ray_march_step >= _ray_max_steps or _ray_hit:
		_ray_animating = false
		_ray_step_timer = 0.0
		return

	var current_pos: Vector2
	if _ray_steps.is_empty():
		current_pos = _ray_origin
	else:
		current_pos = _ray_steps[-1]["pos"]

	var dist := _evaluate_sdf(current_pos)
	_ray_steps.append({"pos": current_pos, "dist": absf(dist)})

	if absf(dist) < 0.02:
		_ray_hit = true
	else:
		# March along ray by distance
		var next_pos := current_pos + _ray_dir * absf(dist)
		# Check if out of field
		var hs := field_size * 0.5
		if absf(next_pos.x) > hs + 1.0 or absf(next_pos.y) > hs + 1.0:
			_ray_animating = false
			_ray_step_timer = 0.0
		else:
			_ray_march_step += 1

func _process_gradient_flow(delta: float) -> void:
	var hs := field_size * 0.5
	for p in _flow_particles:
		p["life"] += delta
		if p["life"] > 4.0:
			p["pos"] = Vector2(randf_range(-hs, hs), randf_range(-hs, hs))
			p["life"] = 0.0
			continue
		var grad := _evaluate_gradient(p["pos"])
		# Flow toward surface (negative gradient = toward lower distance)
		p["pos"] -= grad * delta * 1.5
		# Clamp to field
		p["pos"].x = clampf(p["pos"].x, -hs, hs)
		p["pos"].y = clampf(p["pos"].y, -hs, hs)

# =========================================================================
# Drawing
# =========================================================================

func _draw_all() -> void:
	_draw_grid_lines()
	_draw_field()
	_draw_contours()
	_draw_shapes_outline()

	match _mode:
		Mode.RAY_MARCH:
			_draw_ray_march()
		Mode.GRADIENT_FLOW:
			_draw_gradient_flow()

func _draw_grid_lines() -> void:
	_grid_im.clear_surfaces()
	if not show_grid:
		return
	_grid_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var hs := field_size * 0.5
	var x := -hs
	while x <= hs + 0.01:
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(x, -hs, -0.05))
		_grid_im.surface_add_vertex(Vector3(x, hs, -0.05))
		x += 1.0
	var y := -hs
	while y <= hs + 0.01:
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(-hs, y, -0.05))
		_grid_im.surface_add_vertex(Vector3(hs, y, -0.05))
		y += 1.0
	_grid_im.surface_end()

func _draw_field() -> void:
	_field_im.clear_surfaces()
	_field_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs := field_size * 0.5
	var cell := field_size / float(field_resolution)

	for ix in range(field_resolution):
		for iy in range(field_resolution):
			var wx := -hs + (float(ix) + 0.5) * cell
			var wy := -hs + (float(iy) + 0.5) * cell
			var dist := _evaluate_sdf(Vector2(wx, wy))
			var col := _distance_color(dist)
			var hc := cell * 0.48
			# Draw as quad (2 triangles)
			_field_im.surface_set_color(col)
			_field_im.surface_add_vertex(Vector3(wx - hc, wy - hc, -0.02))
			_field_im.surface_add_vertex(Vector3(wx + hc, wy - hc, -0.02))
			_field_im.surface_add_vertex(Vector3(wx + hc, wy + hc, -0.02))
			_field_im.surface_set_color(col)
			_field_im.surface_add_vertex(Vector3(wx - hc, wy - hc, -0.02))
			_field_im.surface_add_vertex(Vector3(wx + hc, wy + hc, -0.02))
			_field_im.surface_add_vertex(Vector3(wx - hc, wy + hc, -0.02))

	_field_im.surface_end()

func _distance_color(dist: float) -> Color:
	if dist < -0.1:
		# Deep inside — red
		var t := clampf(absf(dist) / 2.0, 0.0, 1.0)
		return Color(0.9, 0.1 + t * 0.2, 0.15, 0.5 + t * 0.3)
	elif dist < 0.1:
		# Near boundary — bright yellow
		var t := 1.0 - absf(dist) / 0.1
		return Color(1.0, 1.0, 0.2, 0.6 + t * 0.3)
	else:
		# Outside — blue fading with distance
		var t := clampf(dist / 3.0, 0.0, 1.0)
		return Color(0.15, 0.3 + (1.0 - t) * 0.4, 0.9, 0.2 + (1.0 - t) * 0.35)

func _draw_contours() -> void:
	_contour_im.clear_surfaces()
	_contour_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var hs := field_size * 0.5
	var step := field_size / float(field_resolution)
	# Draw iso-distance contour lines via marching squares on a few levels
	var levels := [0.0, 0.5, 1.0, 1.5, 2.0]
	for level in levels:
		var col: Color
		if absf(level) < 0.01:
			col = COL_BOUNDARY
		else:
			col = COL_CONTOUR
		_draw_contour_level(hs, step, level, col)
	_contour_im.surface_end()

func _draw_contour_level(hs: float, step: float, level: float, col: Color) -> void:
	# Simple contour: check adjacent cells for sign change relative to level
	for ix in range(field_resolution - 1):
		for iy in range(field_resolution - 1):
			var wx := -hs + (float(ix) + 0.5) * step
			var wy := -hs + (float(iy) + 0.5) * step
			var wx1 := wx + step
			var wy1 := wy + step
			var d00 := _evaluate_sdf(Vector2(wx, wy)) - level
			var d10 := _evaluate_sdf(Vector2(wx1, wy)) - level
			var d01 := _evaluate_sdf(Vector2(wx, wy1)) - level
			# Horizontal edge
			if d00 * d10 < 0.0:
				var t := d00 / (d00 - d10)
				var px := lerpf(wx, wx1, t)
				_contour_im.surface_set_color(col)
				_contour_im.surface_add_vertex(Vector3(px, wy - 0.01, 0.01))
				_contour_im.surface_add_vertex(Vector3(px, wy + 0.01, 0.01))
			# Vertical edge
			if d00 * d01 < 0.0:
				var t := d00 / (d00 - d01)
				var py := lerpf(wy, wy1, t)
				_contour_im.surface_set_color(col)
				_contour_im.surface_add_vertex(Vector3(wx - 0.01, py, 0.01))
				_contour_im.surface_add_vertex(Vector3(wx + 0.01, py, 0.01))

func _draw_shapes_outline() -> void:
	_shapes_im.clear_surfaces()
	if not show_shapes:
		return
	_shapes_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for shape in _shapes:
		match shape["type"]:
			"sphere":
				_draw_circle_outline(shape["pos"], shape["radius"], COL_SHAPE_OUTLINE, 32)
			"box":
				_draw_box_outline(shape["pos"], shape["size"], COL_SHAPE_OUTLINE)
	_shapes_im.surface_end()

func _draw_circle_outline(center: Vector2, radius: float, col: Color, segs: int) -> void:
	for i in range(segs):
		var a0 := float(i) / float(segs) * TAU
		var a1 := float(i + 1) / float(segs) * TAU
		_shapes_im.surface_set_color(col)
		_shapes_im.surface_add_vertex(Vector3(center.x + cos(a0) * radius, center.y + sin(a0) * radius, 0.03))
		_shapes_im.surface_add_vertex(Vector3(center.x + cos(a1) * radius, center.y + sin(a1) * radius, 0.03))

func _draw_box_outline(center: Vector2, half_size: Vector2, col: Color) -> void:
	var corners := [
		Vector3(center.x - half_size.x, center.y - half_size.y, 0.03),
		Vector3(center.x + half_size.x, center.y - half_size.y, 0.03),
		Vector3(center.x + half_size.x, center.y + half_size.y, 0.03),
		Vector3(center.x - half_size.x, center.y + half_size.y, 0.03),
	]
	for i in range(4):
		_shapes_im.surface_set_color(col)
		_shapes_im.surface_add_vertex(corners[i])
		_shapes_im.surface_add_vertex(corners[(i + 1) % 4])

func _draw_ray_march() -> void:
	_ray_im.clear_surfaces()
	_gradient_im.clear_surfaces()
	if _ray_steps.is_empty():
		return

	_ray_im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw ray path
	for i in range(_ray_steps.size()):
		var step_data = _ray_steps[i]
		var pos: Vector2 = step_data["pos"]
		var dist: float = step_data["dist"]

		# March distance circle
		var segs := 24
		var alpha := 0.4 - float(i) / float(_ray_max_steps) * 0.3
		var col := Color(COL_RAY_CIRCLE.r, COL_RAY_CIRCLE.g, COL_RAY_CIRCLE.b, maxf(alpha, 0.05))
		for s in range(segs):
			var a0 := float(s) / float(segs) * TAU
			var a1 := float(s + 1) / float(segs) * TAU
			_ray_im.surface_set_color(col)
			_ray_im.surface_add_vertex(Vector3(pos.x + cos(a0) * dist, pos.y + sin(a0) * dist, 0.04))
			_ray_im.surface_add_vertex(Vector3(pos.x + cos(a1) * dist, pos.y + sin(a1) * dist, 0.04))

		# Connect to next step
		if i < _ray_steps.size() - 1:
			var next_pos: Vector2 = _ray_steps[i + 1]["pos"]
			_ray_im.surface_set_color(COL_RAY)
			_ray_im.surface_add_vertex(Vector3(pos.x, pos.y, 0.05))
			_ray_im.surface_add_vertex(Vector3(next_pos.x, next_pos.y, 0.05))

	# Draw origin marker
	var origin_col := COL_RAY if not _ray_hit else COL_RAY_HIT
	_draw_cross(_ray_im, _ray_origin, 0.15, origin_col)

	# Draw hit marker
	if _ray_hit and not _ray_steps.is_empty():
		var hit_pos: Vector2 = _ray_steps[-1]["pos"]
		_draw_cross(_ray_im, hit_pos, 0.2, COL_RAY_HIT)

	_ray_im.surface_end()

func _draw_cross(im: ImmediateMesh, pos: Vector2, size: float, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_add_vertex(Vector3(pos.x - size, pos.y, 0.06))
	im.surface_add_vertex(Vector3(pos.x + size, pos.y, 0.06))
	im.surface_set_color(col)
	im.surface_add_vertex(Vector3(pos.x, pos.y - size, 0.06))
	im.surface_add_vertex(Vector3(pos.x, pos.y + size, 0.06))

func _draw_gradient_flow() -> void:
	_ray_im.clear_surfaces()
	_gradient_im.clear_surfaces()
	_gradient_im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw gradient arrows on a sparse grid
	var hs := field_size * 0.5
	var arrow_step := field_size / 12.0
	var x := -hs + arrow_step * 0.5
	while x < hs:
		var y := -hs + arrow_step * 0.5
		while y < hs:
			var pos := Vector2(x, y)
			var grad := _evaluate_gradient(pos)
			if grad.length() > 0.01:
				var arrow_len := arrow_step * 0.35
				var tip := pos + grad * arrow_len
				_gradient_im.surface_set_color(COL_GRADIENT)
				_gradient_im.surface_add_vertex(Vector3(pos.x, pos.y, 0.03))
				_gradient_im.surface_add_vertex(Vector3(tip.x, tip.y, 0.03))
				# Arrowhead
				var perp := Vector2(-grad.y, grad.x) * arrow_len * 0.25
				var back := tip - grad * arrow_len * 0.3
				_gradient_im.surface_set_color(COL_GRADIENT)
				_gradient_im.surface_add_vertex(Vector3(tip.x, tip.y, 0.03))
				_gradient_im.surface_add_vertex(Vector3(back.x + perp.x, back.y + perp.y, 0.03))
				_gradient_im.surface_set_color(COL_GRADIENT)
				_gradient_im.surface_add_vertex(Vector3(tip.x, tip.y, 0.03))
				_gradient_im.surface_add_vertex(Vector3(back.x - perp.x, back.y - perp.y, 0.03))
			y += arrow_step
		x += arrow_step

	# Draw flow particles as small crosses moving toward surfaces
	for p in _flow_particles:
		var pos: Vector2 = p["pos"]
		var life: float = p["life"]
		var alpha := clampf(1.0 - life / 4.0, 0.1, 0.8)
		var col := Color(COL_FLOW.r, COL_FLOW.g, COL_FLOW.b, alpha)
		var sz := 0.06
		_gradient_im.surface_set_color(col)
		_gradient_im.surface_add_vertex(Vector3(pos.x - sz, pos.y, 0.04))
		_gradient_im.surface_add_vertex(Vector3(pos.x + sz, pos.y, 0.04))
		_gradient_im.surface_set_color(col)
		_gradient_im.surface_add_vertex(Vector3(pos.x, pos.y - sz, 0.04))
		_gradient_im.surface_add_vertex(Vector3(pos.x, pos.y + sz, 0.04))

	_gradient_im.surface_end()

# =========================================================================
# Label updates
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["SDF Field", "Ray March", "Gradient Flow"]
	_title_label.text = "Distance Fields (SDF) — %s" % mode_names[_mode]

	var blend_names := ["Union", "Intersection", "Smooth Union (k=%.2f)" % smooth_k, "Subtraction"]
	_blend_label.text = "Blend: %s" % blend_names[_blend_op]

	match _mode:
		Mode.SDF_FIELD:
			_info_label.text = "Resolution: %d x %d  |  %d shapes" % [field_resolution, field_resolution, _shapes.size()]
		Mode.RAY_MARCH:
			var status := "marching..." if _ray_animating else ("HIT" if _ray_hit else "miss")
			_info_label.text = "Steps: %d/%d  |  %s" % [_ray_steps.size(), _ray_max_steps, status]
		Mode.GRADIENT_FLOW:
			_info_label.text = "Particles: %d  |  Arrows show gradient direction" % _flow_particles.size()

	_mode_label.text = "%s  |  %s" % [mode_names[_mode], blend_names[_blend_op]]

# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("field_resolution"):
		field_resolution = clampi(int(config["field_resolution"]), 10, 60)
	if config.has("field_size"):
		field_size = clampf(float(config["field_size"]), 3.0, 10.0)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 5.0)
	if config.has("smooth_k"):
		smooth_k = clampf(float(config["smooth_k"]), 0.0, 2.0)
	if config.has("show_grid"):
		show_grid = bool(config["show_grid"])
	if config.has("show_shapes"):
		show_shapes = bool(config["show_shapes"])
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"SDF_FIELD": _mode = Mode.SDF_FIELD
			"RAY_MARCH": _mode = Mode.RAY_MARCH
			"GRADIENT_FLOW": _mode = Mode.GRADIENT_FLOW
	if config.has("blend"):
		var b := str(config["blend"]).to_upper()
		match b:
			"UNION": _blend_op = BlendOp.UNION
			"INTERSECTION": _blend_op = BlendOp.INTERSECTION
			"SMOOTH_UNION": _blend_op = BlendOp.SMOOTH_UNION
			"SUBTRACTION": _blend_op = BlendOp.SUBTRACTION

	# Update label positions for field size
	_title_label.position.y = field_size * 0.5 + 1.2
	_info_label.position.y = field_size * 0.5 + 0.7
	_blend_label.position.y = field_size * 0.5 + 0.3
	_mode_label.position.y = -field_size * 0.5 - 0.6

	# Update sliders
	if _smooth_slider:
		_smooth_slider.set_normalized_value(clampf(smooth_k / 2.0, 0.0, 1.0))
	if _res_slider:
		_res_slider.set_normalized_value(clampf((field_resolution - 15.0) / 45.0, 0.0, 1.0))

	_create_shapes()
	_init_mode()
