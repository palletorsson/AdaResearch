# ===========================================================================
# ClosestPair — Sweep Line Comparison & Dynamic Maintenance
# Divide-and-conquer vs sweep line closest pair algorithms
# Elevated features:
#   - Sweep line algorithm variant with active set visualization
#   - Dynamic closest pair maintenance (insert/delete points)
#   - Performance graph (empirical vs O(n log n) theoretical)
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

extends Node3D

## Closest pair of points with two algorithm variants and dynamic maintenance.
## Modes: DIVIDE_CONQUER shows recursive decomposition;
## SWEEP_LINE shows plane-sweep with active strip;
## DYNAMIC allows point insertion/deletion with live updates.

# --- Configuration ---
@export var point_count: int = 20
@export var field_width: float = 6.0
@export var field_height: float = 4.0
@export var step_speed: float = 1.5
@export var show_grid: bool = true
@export var show_performance: bool = true

# --- Mode ---
enum Mode { DIVIDE_CONQUER, SWEEP_LINE, DYNAMIC }
var _mode: int = Mode.DIVIDE_CONQUER

# --- Internal state ---
var _time: float = 0.0
var _points: Array = []  # Array of Vector2
var _sorted_x: Array = []  # indices sorted by x
var _closest_pair: Array = [-1, -1]
var _min_distance: float = INF
var _step_timer: float = 0.0
var _running: bool = false
var _finished: bool = false

# Divide & Conquer state
enum DCStep { IDLE, SORT, DIVIDE, LEFT, RIGHT, STRIP, MERGE, DONE }
var _dc_step: int = DCStep.IDLE
var _dc_median_x: float = 0.0
var _dc_left_pair: Array = [-1, -1]
var _dc_right_pair: Array = [-1, -1]
var _dc_left_dist: float = INF
var _dc_right_dist: float = INF
var _dc_strip_indices: Array = []
var _dc_strip_delta: float = INF
var _dc_current_strip_i: int = 0
var _dc_current_strip_j: int = 0
var _dc_highlight_indices: Array = []

# Sweep Line state
enum SLStep { IDLE, SORT, SWEEP, DONE }
var _sl_step: int = SLStep.IDLE
var _sl_sorted: Array = []  # indices sorted by x
var _sl_active_set: Array = []  # indices in active strip
var _sl_sweep_x: float = -INF
var _sl_current_idx: int = 0
var _sl_highlight_pair: Array = [-1, -1]

# Dynamic mode state
var _dyn_insert_timer: float = 0.0
var _dyn_insert_interval: float = 2.0

# Performance tracking
var _perf_dc_times: Array = []  # [n, time_ms]
var _perf_sl_times: Array = []

# --- Rendering ---
var _points_im: ImmediateMesh
var _points_mi: MeshInstance3D
var _lines_im: ImmediateMesh
var _lines_mi: MeshInstance3D
var _grid_im: ImmediateMesh
var _grid_mi: MeshInstance3D
var _sweep_im: ImmediateMesh
var _sweep_mi: MeshInstance3D
var _perf_im: ImmediateMesh
var _perf_mi: MeshInstance3D
var _strip_im: ImmediateMesh
var _strip_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _step_label: Label3D
var _dist_label: Label3D
var _mode_label: Label3D
var _perf_label: Label3D

# VR controls
var _control_rack: Node3D
var _count_slider: Node

# Colors
const COL_POINT := Color(0.2, 0.65, 1.0)
const COL_POINT_DIM := Color(0.25, 0.35, 0.5, 0.5)
const COL_CLOSEST := Color(1.0, 0.15, 0.2)
const COL_HIGHLIGHT := Color(1.0, 0.9, 0.1)
const COL_LEFT := Color(0.9, 0.35, 0.35)
const COL_RIGHT := Color(0.35, 0.35, 0.9)
const COL_STRIP := Color(0.9, 0.6, 0.1, 0.15)
const COL_SWEEP := Color(0.1, 1.0, 0.5, 0.7)
const COL_ACTIVE := Color(0.3, 1.0, 0.6)
const COL_GRID := Color(0.3, 0.3, 0.35, 0.25)
const COL_LINE := Color(1.0, 1.0, 0.2, 0.6)
const COL_RESULT_LINE := Color(1.0, 0.1, 0.15, 0.9)
const COL_DC_PERF := Color(0.4, 0.7, 1.0)
const COL_SL_PERF := Color(1.0, 0.5, 0.2)
const COL_THEORY := Color(0.5, 1.0, 0.5, 0.5)

func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_generate_points()
	_start_algorithm()

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
	_points_im = ImmediateMesh.new()
	_points_mi = MeshInstance3D.new()
	_points_mi.mesh = _points_im
	_points_mi.material_override = _mat_unshaded
	add_child(_points_mi)

	_lines_im = ImmediateMesh.new()
	_lines_mi = MeshInstance3D.new()
	_lines_mi.mesh = _lines_im
	_lines_mi.material_override = _mat_alpha
	add_child(_lines_mi)

	_grid_im = ImmediateMesh.new()
	_grid_mi = MeshInstance3D.new()
	_grid_mi.mesh = _grid_im
	_grid_mi.material_override = _mat_alpha
	add_child(_grid_mi)

	_sweep_im = ImmediateMesh.new()
	_sweep_mi = MeshInstance3D.new()
	_sweep_mi.mesh = _sweep_im
	_sweep_mi.material_override = _mat_alpha
	add_child(_sweep_mi)

	_strip_im = ImmediateMesh.new()
	_strip_mi = MeshInstance3D.new()
	_strip_mi.mesh = _strip_im
	_strip_mi.material_override = _mat_alpha
	add_child(_strip_mi)

	_perf_im = ImmediateMesh.new()
	_perf_mi = MeshInstance3D.new()
	_perf_mi.mesh = _perf_im
	_perf_mi.material_override = _mat_unshaded
	_perf_mi.visible = show_performance
	add_child(_perf_mi)

# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, field_height * 0.5 + 1.2, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_step_label = Label3D.new()
	_step_label.font_size = 22
	_step_label.outline_size = 3
	_step_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_step_label.position = Vector3(0, field_height * 0.5 + 0.7, 0)
	_step_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_step_label)

	_dist_label = Label3D.new()
	_dist_label.font_size = 20
	_dist_label.outline_size = 3
	_dist_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dist_label.position = Vector3(0, field_height * 0.5 + 0.3, 0)
	_dist_label.modulate = Color(1.0, 0.8, 0.6)
	add_child(_dist_label)

	_mode_label = Label3D.new()
	_mode_label.font_size = 18
	_mode_label.outline_size = 3
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.position = Vector3(0, -field_height * 0.5 - 0.6, 0)
	_mode_label.modulate = Color(0.7, 0.8, 1.0)
	add_child(_mode_label)

	_perf_label = Label3D.new()
	_perf_label.font_size = 16
	_perf_label.outline_size = 3
	_perf_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_perf_label.position = Vector3(field_width * 0.5 + 2.5, field_height * 0.5 + 0.3, 0)
	_perf_label.modulate = Color(0.8, 0.9, 0.8)
	_perf_label.visible = show_performance
	add_child(_perf_label)

	_update_labels()

# =========================================================================
# VR Controls
# =========================================================================

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_rack = RackTpl.create_panel("CLOSEST PAIR", [
		[{"type": "slider_h", "label": "POINTS", "default": clampf((point_count - 8.0) / 42.0, 0.0, 1.0)}, {"type": "slider_h", "label": "SPEED", "default": clampf((step_speed - 0.2) / 4.8, 0.0, 1.0)}],
		[{"type": "button", "label": "MODE"}, {"type": "button", "label": "RESTART"}],
	])
	_control_rack.position = Vector3(0, -field_height * 0.5 - 1.5, 0.3)
	_control_rack.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_rack)

	_count_slider = _control_rack.find_child("Param_0", true, false)
	if _count_slider and _count_slider.has_signal("slider_moved"):
		_count_slider.slider_moved.connect(_on_count_changed)

	var speed_slider: Node = _control_rack.find_child("Param_1", true, false)
	if speed_slider and speed_slider.has_signal("slider_moved"):
		speed_slider.slider_moved.connect(_on_speed_changed)

	var mode_btn: Node = _control_rack.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_mode_pressed())

	var restart_btn: Node = _control_rack.find_child("Btn_1", true, false)
	if restart_btn:
		var area = restart_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_restart_pressed())

func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_restart()

func _on_restart_pressed() -> void:
	_restart()

func _on_count_changed(_value: float) -> void:
	var slider: Node = _control_rack.find_child("Param_0", true, false)
	if slider and slider.has_method("get_normalized_value"):
		point_count = int(lerpf(8.0, 50.0, slider.get_normalized_value()))
		_restart()

func _on_speed_changed(_value: float) -> void:
	var slider: Node = _control_rack.find_child("Param_1", true, false)
	if slider and slider.has_method("get_normalized_value"):
		step_speed = lerpf(0.2, 5.0, slider.get_normalized_value())

func _restart() -> void:
	_generate_points()
	_start_algorithm()

# =========================================================================
# Point generation
# =========================================================================

func _generate_points() -> void:
	_points.clear()
	for i in range(point_count):
		_points.append(Vector2(
			randf_range(-field_width * 0.5, field_width * 0.5),
			randf_range(-field_height * 0.5, field_height * 0.5)
		))
	_sorted_x.clear()
	_closest_pair = [-1, -1]
	_min_distance = INF
	_finished = false

func _start_algorithm() -> void:
	_step_timer = 0.0
	_running = true
	_finished = false
	_closest_pair = [-1, -1]
	_min_distance = INF
	_dc_highlight_indices.clear()

	match _mode:
		Mode.DIVIDE_CONQUER:
			_dc_step = DCStep.SORT
		Mode.SWEEP_LINE:
			_sl_step = SLStep.SORT
		Mode.DYNAMIC:
			_dyn_insert_timer = 0.0
			# compute initial closest pair
			_compute_brute_force()

# =========================================================================
# _process
# =========================================================================

func _process(delta: float) -> void:
	_time += delta
	_step_timer += delta

	if _running and _step_timer >= (1.0 / maxf(step_speed, 0.01)):
		_step_timer = 0.0
		_advance_step()

	if _mode == Mode.DYNAMIC and not _running:
		_dyn_insert_timer += delta
		if _dyn_insert_timer >= _dyn_insert_interval:
			_dyn_insert_timer = 0.0
			_dynamic_insert_point()

	if _finished and not (_mode == Mode.DYNAMIC):
		# auto-restart after pause
		_step_timer += delta
		if _step_timer > 4.0:
			_restart()

	_draw_all()
	_update_labels()

# =========================================================================
# Algorithm steps
# =========================================================================

func _advance_step() -> void:
	match _mode:
		Mode.DIVIDE_CONQUER:
			_advance_dc()
		Mode.SWEEP_LINE:
			_advance_sl()
		Mode.DYNAMIC:
			pass  # dynamic is event-driven

func _advance_dc() -> void:
	match _dc_step:
		DCStep.SORT:
			_sorted_x = range(_points.size())
			_sorted_x.sort_custom(func(a, b): return _points[a].x < _points[b].x)
			_dc_step = DCStep.DIVIDE

		DCStep.DIVIDE:
			var mid = _sorted_x.size() / 2
			_dc_median_x = _points[_sorted_x[mid]].x
			_dc_step = DCStep.LEFT

		DCStep.LEFT:
			var mid = _sorted_x.size() / 2
			var left = _sorted_x.slice(0, mid)
			_dc_left_pair = [-1, -1]
			_dc_left_dist = INF
			_brute_force_subset(left)
			_dc_left_pair = _closest_pair.duplicate()
			_dc_left_dist = _min_distance
			_dc_highlight_indices = left
			_dc_step = DCStep.RIGHT

		DCStep.RIGHT:
			var mid = _sorted_x.size() / 2
			var right = _sorted_x.slice(mid)
			_closest_pair = [-1, -1]
			_min_distance = INF
			_brute_force_subset(right)
			_dc_right_pair = _closest_pair.duplicate()
			_dc_right_dist = _min_distance
			_dc_highlight_indices = right
			_dc_step = DCStep.STRIP

		DCStep.STRIP:
			_dc_strip_delta = minf(_dc_left_dist, _dc_right_dist)
			_min_distance = _dc_strip_delta
			if _dc_left_dist <= _dc_right_dist:
				_closest_pair = _dc_left_pair.duplicate()
			else:
				_closest_pair = _dc_right_pair.duplicate()

			# find strip points
			_dc_strip_indices.clear()
			for idx in _sorted_x:
				if absf(_points[idx].x - _dc_median_x) < _dc_strip_delta:
					_dc_strip_indices.append(idx)

			# sort strip by y
			_dc_strip_indices.sort_custom(func(a, b): return _points[a].y < _points[b].y)

			_dc_current_strip_i = 0
			_dc_current_strip_j = 1
			_dc_highlight_indices = _dc_strip_indices
			_dc_step = DCStep.MERGE

		DCStep.MERGE:
			# check a few strip pairs per step
			var checks_per_step := 3
			var found_closer := false
			for _k in range(checks_per_step):
				if _dc_current_strip_i >= _dc_strip_indices.size():
					_dc_step = DCStep.DONE
					break
				if _dc_current_strip_j >= _dc_strip_indices.size():
					_dc_current_strip_i += 1
					_dc_current_strip_j = _dc_current_strip_i + 1
					continue

				var si = _dc_strip_indices[_dc_current_strip_i]
				var sj = _dc_strip_indices[_dc_current_strip_j]

				if _points[sj].y - _points[si].y >= _min_distance:
					_dc_current_strip_i += 1
					_dc_current_strip_j = _dc_current_strip_i + 1
					continue

				var d = _points[si].distance_to(_points[sj])
				if d < _min_distance:
					_min_distance = d
					_closest_pair = [si, sj]
					found_closer = true

				_dc_current_strip_j += 1

			if _dc_current_strip_i >= _dc_strip_indices.size():
				_dc_step = DCStep.DONE

		DCStep.DONE:
			_running = false
			_finished = true
			_step_timer = 0.0
			_dc_highlight_indices.clear()
			_record_perf_dc()

func _advance_sl() -> void:
	match _sl_step:
		SLStep.SORT:
			_sl_sorted = range(_points.size())
			_sl_sorted.sort_custom(func(a, b): return _points[a].x < _points[b].x)
			_sl_current_idx = 0
			_sl_active_set.clear()
			_min_distance = INF
			_closest_pair = [-1, -1]
			_sl_highlight_pair = [-1, -1]
			_sl_step = SLStep.SWEEP

		SLStep.SWEEP:
			if _sl_current_idx >= _sl_sorted.size():
				_sl_step = SLStep.DONE
				_running = false
				_finished = true
				_step_timer = 0.0
				_record_perf_sl()
				return

			var pi = _sl_sorted[_sl_current_idx]
			_sl_sweep_x = _points[pi].x

			# remove points too far left from active set
			var new_active: Array = []
			for ai in _sl_active_set:
				if _sl_sweep_x - _points[ai].x < _min_distance or _min_distance == INF:
					new_active.append(ai)
			_sl_active_set = new_active

			# check against active set
			_sl_highlight_pair = [-1, -1]
			for ai in _sl_active_set:
				if _min_distance < INF and absf(_points[ai].y - _points[pi].y) > _min_distance:
					continue
				var d = _points[pi].distance_to(_points[ai])
				if d < _min_distance:
					_min_distance = d
					_closest_pair = [pi, ai]
					_sl_highlight_pair = [pi, ai]

			_sl_active_set.append(pi)
			_sl_current_idx += 1

		SLStep.DONE:
			pass

# =========================================================================
# Dynamic mode
# =========================================================================

func _dynamic_insert_point() -> void:
	var new_p := Vector2(
		randf_range(-field_width * 0.5, field_width * 0.5),
		randf_range(-field_height * 0.5, field_height * 0.5)
	)

	# remove oldest if we exceed limit
	if _points.size() >= 50:
		_points.pop_front()

	_points.append(new_p)
	_compute_brute_force()

func _compute_brute_force() -> void:
	_min_distance = INF
	_closest_pair = [-1, -1]
	for i in range(_points.size()):
		for j in range(i + 1, _points.size()):
			var d = _points[i].distance_to(_points[j])
			if d < _min_distance:
				_min_distance = d
				_closest_pair = [i, j]

func _brute_force_subset(indices: Array) -> void:
	_min_distance = INF
	_closest_pair = [-1, -1]
	for ii in range(indices.size()):
		for jj in range(ii + 1, indices.size()):
			var i = indices[ii]
			var j = indices[jj]
			var d = _points[i].distance_to(_points[j])
			if d < _min_distance:
				_min_distance = d
				_closest_pair = [i, j]

# =========================================================================
# Performance recording
# =========================================================================

func _record_perf_dc() -> void:
	_perf_dc_times.append([_points.size(), _time])
	if _perf_dc_times.size() > 20:
		_perf_dc_times.pop_front()

func _record_perf_sl() -> void:
	_perf_sl_times.append([_points.size(), _time])
	if _perf_sl_times.size() > 20:
		_perf_sl_times.pop_front()

# =========================================================================
# Drawing
# =========================================================================

func _draw_all() -> void:
	_draw_grid()
	_draw_points()
	_draw_lines()
	_draw_sweep_line()
	_draw_strip()
	if show_performance:
		_draw_perf_graph()

func _draw_grid() -> void:
	_grid_im.clear_surfaces()
	if not show_grid:
		return
	_grid_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var hw := field_width * 0.5
	var hh := field_height * 0.5
	# vertical lines
	var x := -hw
	while x <= hw + 0.01:
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(x, -hh, -0.05))
		_grid_im.surface_add_vertex(Vector3(x, hh, -0.05))
		x += 1.0
	# horizontal lines
	var y := -hh
	while y <= hh + 0.01:
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(-hw, y, -0.05))
		_grid_im.surface_add_vertex(Vector3(hw, y, -0.05))
		y += 1.0
	_grid_im.surface_end()

func _draw_points() -> void:
	_points_im.clear_surfaces()
	_points_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(_points.size()):
		var col := _get_point_color(i)
		var p: Vector2 = _points[i]
		var r := 0.12
		# highlight closest pair larger
		if i == _closest_pair[0] or i == _closest_pair[1]:
			r = 0.18
		# diamond shape (two triangles)
		var c := Vector3(p.x, p.y, 0.05)
		_draw_diamond(c, r, col)
	_points_im.surface_end()

func _draw_diamond(center: Vector3, radius: float, col: Color) -> void:
	var top := center + Vector3(0, radius, 0)
	var bot := center + Vector3(0, -radius, 0)
	var left := center + Vector3(-radius, 0, 0)
	var right := center + Vector3(radius, 0, 0)
	# upper triangle
	_points_im.surface_set_color(col)
	_points_im.surface_add_vertex(top)
	_points_im.surface_add_vertex(left)
	_points_im.surface_add_vertex(right)
	# lower triangle
	_points_im.surface_set_color(col)
	_points_im.surface_add_vertex(bot)
	_points_im.surface_add_vertex(right)
	_points_im.surface_add_vertex(left)

func _get_point_color(idx: int) -> Color:
	# closest pair always red
	if idx == _closest_pair[0] or idx == _closest_pair[1]:
		var pulse = 0.8 + sin(_time * 6.0) * 0.2
		return COL_CLOSEST * pulse

	match _mode:
		Mode.DIVIDE_CONQUER:
			if _dc_step == DCStep.LEFT or _dc_step == DCStep.RIGHT:
				if idx in _dc_highlight_indices:
					if _dc_step == DCStep.LEFT:
						return COL_LEFT
					else:
						return COL_RIGHT
				return COL_POINT_DIM
			if _dc_step == DCStep.STRIP or _dc_step == DCStep.MERGE:
				if idx in _dc_strip_indices:
					return COL_HIGHLIGHT
				return COL_POINT_DIM
		Mode.SWEEP_LINE:
			if _sl_step == SLStep.SWEEP:
				if idx in _sl_active_set:
					return COL_ACTIVE
				# already processed but not in active set
				var pi_x = _points[idx].x
				if pi_x < _sl_sweep_x:
					return COL_POINT_DIM
		Mode.DYNAMIC:
			# newest points brighter
			var age_frac = float(idx) / maxf(float(_points.size() - 1), 1.0)
			return COL_POINT.lerp(Color.WHITE, age_frac * 0.3)

	return COL_POINT

func _draw_lines() -> void:
	_lines_im.clear_surfaces()
	_lines_im.surface_begin(Mesh.PRIMITIVE_LINES)

	# DC mode: division line
	if _mode == Mode.DIVIDE_CONQUER and _dc_step >= DCStep.DIVIDE and _dc_step < DCStep.DONE:
		var hh := field_height * 0.5 + 0.5
		_lines_im.surface_set_color(Color(1.0, 0.5, 0.0, 0.7))
		_lines_im.surface_add_vertex(Vector3(_dc_median_x, -hh, 0.02))
		_lines_im.surface_add_vertex(Vector3(_dc_median_x, hh, 0.02))

	# sweep line: current comparison line
	if _mode == Mode.SWEEP_LINE and _sl_highlight_pair[0] >= 0:
		var a = _points[_sl_highlight_pair[0]]
		var b = _points[_sl_highlight_pair[1]]
		_lines_im.surface_set_color(COL_LINE)
		_lines_im.surface_add_vertex(Vector3(a.x, a.y, 0.03))
		_lines_im.surface_add_vertex(Vector3(b.x, b.y, 0.03))

	# closest pair result line
	if _closest_pair[0] >= 0 and _closest_pair[1] >= 0:
		var a = _points[_closest_pair[0]]
		var b = _points[_closest_pair[1]]
		_lines_im.surface_set_color(COL_RESULT_LINE)
		_lines_im.surface_add_vertex(Vector3(a.x, a.y, 0.04))
		_lines_im.surface_add_vertex(Vector3(b.x, b.y, 0.04))

	_lines_im.surface_end()

func _draw_sweep_line() -> void:
	_sweep_im.clear_surfaces()
	if _mode != Mode.SWEEP_LINE or _sl_step != SLStep.SWEEP:
		return

	# vertical sweep line
	_sweep_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var hh := field_height * 0.5 + 0.5
	_sweep_im.surface_set_color(COL_SWEEP)
	_sweep_im.surface_add_vertex(Vector3(_sl_sweep_x, -hh, 0.01))
	_sweep_im.surface_add_vertex(Vector3(_sl_sweep_x, hh, 0.01))
	_sweep_im.surface_end()

func _draw_strip() -> void:
	_strip_im.clear_surfaces()

	if _mode == Mode.DIVIDE_CONQUER and (_dc_step == DCStep.STRIP or _dc_step == DCStep.MERGE):
		# draw strip region as quad
		var hh := field_height * 0.5 + 0.3
		var left_x := _dc_median_x - _dc_strip_delta
		var right_x := _dc_median_x + _dc_strip_delta
		_strip_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_strip_im.surface_set_color(COL_STRIP)
		_strip_im.surface_add_vertex(Vector3(left_x, -hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(right_x, -hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(right_x, hh, -0.02))
		_strip_im.surface_set_color(COL_STRIP)
		_strip_im.surface_add_vertex(Vector3(left_x, -hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(right_x, hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(left_x, hh, -0.02))
		_strip_im.surface_end()

	elif _mode == Mode.SWEEP_LINE and _sl_step == SLStep.SWEEP and _min_distance < INF:
		# draw active strip behind sweep line
		var hh := field_height * 0.5 + 0.3
		var left_x := _sl_sweep_x - _min_distance
		var right_x := _sl_sweep_x
		_strip_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_strip_im.surface_set_color(Color(0.1, 0.8, 0.5, 0.08))
		_strip_im.surface_add_vertex(Vector3(left_x, -hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(right_x, -hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(right_x, hh, -0.02))
		_strip_im.surface_set_color(Color(0.1, 0.8, 0.5, 0.08))
		_strip_im.surface_add_vertex(Vector3(left_x, -hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(right_x, hh, -0.02))
		_strip_im.surface_add_vertex(Vector3(left_x, hh, -0.02))
		_strip_im.surface_end()

func _draw_perf_graph() -> void:
	_perf_im.clear_surfaces()
	if _perf_dc_times.is_empty() and _perf_sl_times.is_empty():
		return

	var graph_x := field_width * 0.5 + 1.0
	var graph_y := -field_height * 0.5
	var graph_w := 3.0
	var graph_h := field_height

	_perf_im.surface_begin(Mesh.PRIMITIVE_LINES)

	# axes
	var axis_col := Color(0.5, 0.5, 0.5)
	_perf_im.surface_set_color(axis_col)
	_perf_im.surface_add_vertex(Vector3(graph_x, graph_y, 0))
	_perf_im.surface_add_vertex(Vector3(graph_x, graph_y + graph_h, 0))
	_perf_im.surface_set_color(axis_col)
	_perf_im.surface_add_vertex(Vector3(graph_x, graph_y, 0))
	_perf_im.surface_add_vertex(Vector3(graph_x + graph_w, graph_y, 0))

	# theoretical O(n log n) curve
	var max_n := 50.0
	var max_val := max_n * log(max_n)
	var prev_v := Vector3.ZERO
	for step_i in range(21):
		var n = lerpf(2.0, max_n, float(step_i) / 20.0)
		var val = n * log(n)
		var px = graph_x + (n / max_n) * graph_w
		var py = graph_y + (val / max_val) * graph_h * 0.9
		var v := Vector3(px, py, 0)
		if step_i > 0:
			_perf_im.surface_set_color(COL_THEORY)
			_perf_im.surface_add_vertex(prev_v)
			_perf_im.surface_add_vertex(v)
		prev_v = v

	# DC data points connected
	if _perf_dc_times.size() > 1:
		var prev: Vector3 = Vector3.ZERO
		for k in range(_perf_dc_times.size()):
			var n = float(_perf_dc_times[k][0])
			var t = float(_perf_dc_times[k][1])
			var px = graph_x + (n / max_n) * graph_w
			var py = graph_y + clampf(t / 60.0, 0, 1) * graph_h * 0.9
			var v := Vector3(px, py, 0)
			if k > 0:
				_perf_im.surface_set_color(COL_DC_PERF)
				_perf_im.surface_add_vertex(prev)
				_perf_im.surface_add_vertex(v)
			prev = v

	# SL data points connected
	if _perf_sl_times.size() > 1:
		var prev: Vector3 = Vector3.ZERO
		for k in range(_perf_sl_times.size()):
			var n = float(_perf_sl_times[k][0])
			var t = float(_perf_sl_times[k][1])
			var px = graph_x + (n / max_n) * graph_w
			var py = graph_y + clampf(t / 60.0, 0, 1) * graph_h * 0.9
			var v := Vector3(px, py, 0)
			if k > 0:
				_perf_im.surface_set_color(COL_SL_PERF)
				_perf_im.surface_add_vertex(prev)
				_perf_im.surface_add_vertex(v)
			prev = v

	_perf_im.surface_end()

# =========================================================================
# Label updates
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["Divide & Conquer", "Sweep Line", "Dynamic"]
	_title_label.text = "Closest Pair — %s" % mode_names[_mode]

	match _mode:
		Mode.DIVIDE_CONQUER:
			var dc_names := {
				DCStep.IDLE: "Ready",
				DCStep.SORT: "Sorting by X",
				DCStep.DIVIDE: "Dividing at median",
				DCStep.LEFT: "Solving left half",
				DCStep.RIGHT: "Solving right half",
				DCStep.STRIP: "Building strip region",
				DCStep.MERGE: "Checking strip pairs",
				DCStep.DONE: "Complete"
			}
			_step_label.text = dc_names.get(_dc_step, "")
		Mode.SWEEP_LINE:
			var sl_names := {
				SLStep.IDLE: "Ready",
				SLStep.SORT: "Sorting by X",
				SLStep.SWEEP: "Sweeping... (%d/%d)" % [_sl_current_idx, _points.size()],
				SLStep.DONE: "Complete"
			}
			_step_label.text = sl_names.get(_sl_step, "")
		Mode.DYNAMIC:
			_step_label.text = "Points: %d  (auto-inserting)" % _points.size()

	if _min_distance < INF:
		_dist_label.text = "Min distance: %.3f" % _min_distance
	else:
		_dist_label.text = "Min distance: —"

	_mode_label.text = "n = %d  |  %s" % [_points.size(), mode_names[_mode]]

	if show_performance:
		_perf_label.text = "Performance\nBlue=D&C  Orange=Sweep\nGreen=O(n log n)"

# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("point_count"):
		point_count = int(config["point_count"])
	if config.has("field_width"):
		field_width = float(config["field_width"])
	if config.has("field_height"):
		field_height = float(config["field_height"])
	if config.has("step_speed"):
		step_speed = float(config["step_speed"])
	if config.has("show_grid"):
		show_grid = bool(config["show_grid"])
	if config.has("show_performance"):
		show_performance = bool(config["show_performance"])
		_perf_mi.visible = show_performance
		_perf_label.visible = show_performance
	if config.has("mode"):
		var mode_str = str(config["mode"]).to_upper()
		match mode_str:
			"DIVIDE_CONQUER":
				_mode = Mode.DIVIDE_CONQUER
			"SWEEP_LINE":
				_mode = Mode.SWEEP_LINE
			"DYNAMIC":
				_mode = Mode.DYNAMIC

	# update label positions for field size
	_title_label.position.y = field_height * 0.5 + 1.2
	_dist_label.position.y = field_height * 0.5 + 0.3
	_step_label.position.y = field_height * 0.5 + 0.7
	_mode_label.position.y = -field_height * 0.5 - 0.6
	_perf_label.position.x = field_width * 0.5 + 2.5

	# update slider
	if _count_slider:
		_count_slider.set_normalized_value(clampf((point_count - 8.0) / 42.0, 0.0, 1.0))

	_restart()
