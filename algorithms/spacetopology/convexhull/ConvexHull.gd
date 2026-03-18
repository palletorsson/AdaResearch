# ===========================================================================
# Convex Hull — Live Algorithm Step Visualization
# Graham Scan vs Jarvis March with step-by-step execution,
# point highlighting, edge properties, winding order display,
# and VR sliders for parameter exploration.
# ===========================================================================

extends Node3D

## Convex Hull — step-by-step algorithm visualization
## Points generated on XZ plane, hull computed with animated steps

# ── Algorithm state ──────────────────────────────────────────────────
enum State { IDLE, STEPPING, COMPLETE }
enum Algo { GRAHAM_SCAN, JARVIS_MARCH }

var _state: int = State.IDLE
var _algo: int = Algo.GRAHAM_SCAN

# ── Point cloud ──────────────────────────────────────────────────────
var _points: Array[Vector3] = []
var _hull_indices: Array[int] = []

# ── Graham scan state ────────────────────────────────────────────────
var _graham_sorted_idx: Array[int] = []
var _graham_stack: Array[int] = []
var _graham_scan_i: int = 0
var _graham_pivot: int = -1
var _graham_rejected: Array[int] = []  # recently popped (flash red)

# ── Jarvis march state ──────────────────────────────────────────────
var _jarvis_hull: Array[int] = []
var _jarvis_current: int = -1
var _jarvis_candidate: int = -1
var _jarvis_check_i: int = 0
var _jarvis_start: int = -1

# ── Step timing ──────────────────────────────────────────────────────
var _step_timer := 0.0
var _step_interval := 0.12
var _comparisons := 0
var _total_steps := 0

# ── Tunables ─────────────────────────────────────────────────────────
var point_count := 24
var distribution := 0  # 0=Uniform, 1=Normal, 2=Clustered
var step_speed := 1.0
var _bounds := 0.35

# ── Visual nodes ─────────────────────────────────────────────────────
# Points (MultiMesh with per-instance color)
var _point_mm: MultiMesh
var _point_mmi: MultiMeshInstance3D

# Hull edges (confirmed)
var _hull_im: ImmediateMesh
var _hull_mi: MeshInstance3D

# Sweep / candidate line
var _sweep_im: ImmediateMesh
var _sweep_mi: MeshInstance3D

# Winding order arrows & edge annotations
var _arrow_im: ImmediateMesh
var _arrow_mi: MeshInstance3D

# Ground plane grid
var _grid_im: ImmediateMesh
var _grid_mi: MeshInstance3D

# Labels
var _title_label: Label3D
var _stats_label: Label3D
var _algo_label: Label3D

# VR controllers
var _count_ctrl: ParameterController3D
var _speed_ctrl: ParameterController3D
var _dist_ctrl: ParameterController3D
var _algo_ctrl: ParameterController3D

# ── Colors ───────────────────────────────────────────────────────────
const COL_POINT := Color(0.85, 0.45, 0.2)          # default point
const COL_HULL := Color(0.2, 1.0, 0.4)              # hull point
const COL_CURRENT := Color(1.0, 1.0, 0.2)           # currently processing
const COL_CANDIDATE := Color(0.4, 0.8, 1.0)         # candidate edge
const COL_PIVOT := Color(0.0, 1.0, 1.0)             # extreme/pivot point
const COL_REJECTED := Color(1.0, 0.2, 0.2)          # just rejected
const COL_EDGE := Color(0.15, 0.9, 0.35)            # confirmed hull edge
const COL_SWEEP := Color(1.0, 0.8, 0.1, 0.7)       # sweep/scan line
const COL_ARROW := Color(0.3, 0.7, 1.0, 0.9)       # winding arrows
const COL_GRID := Color(0.3, 0.3, 0.4, 0.15)        # ground grid


func _ready() -> void:
	_setup_grid()
	_setup_point_mesh()
	_setup_hull_mesh()
	_setup_sweep_mesh()
	_setup_arrow_mesh()
	_setup_labels()
	_setup_controllers()
	_generate_points()
	_start_algorithm()


# ── Ground grid ──────────────────────────────────────────────────────

func _setup_grid() -> void:
	_grid_im = ImmediateMesh.new()
	_grid_mi = MeshInstance3D.new()
	_grid_mi.mesh = _grid_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_grid_mi.material_override = mat
	add_child(_grid_mi)
	_draw_grid()


func _draw_grid() -> void:
	_grid_im.clear_surfaces()
	_grid_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var steps := 8
	var extent := _bounds + 0.05
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var pos := -extent + t * extent * 2.0
		# X-axis lines
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(pos, -0.01, -extent))
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(pos, -0.01, extent))
		# Z-axis lines
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(-extent, -0.01, pos))
		_grid_im.surface_set_color(COL_GRID)
		_grid_im.surface_add_vertex(Vector3(extent, -0.01, pos))
	_grid_im.surface_end()


# ── Point mesh (MultiMesh) ───────────────────────────────────────────

func _setup_point_mesh() -> void:
	_point_mm = MultiMesh.new()
	_point_mm.transform_format = MultiMesh.TRANSFORM_3D
	_point_mm.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	sphere.radial_segments = 8
	sphere.rings = 4
	_point_mm.mesh = sphere

	_point_mmi = MultiMeshInstance3D.new()
	_point_mmi.multimesh = _point_mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_point_mmi.material_override = mat
	add_child(_point_mmi)


func _update_point_visuals() -> void:
	if _points.is_empty():
		return
	_point_mm.instance_count = _points.size()
	for i in _points.size():
		var xf := Transform3D.IDENTITY
		xf.origin = _points[i]
		_point_mm.set_instance_transform(i, xf)
		_point_mm.set_instance_color(i, _get_point_color(i))


func _get_point_color(idx: int) -> Color:
	# Pivot / extreme point
	if _state == State.STEPPING:
		if _algo == Algo.GRAHAM_SCAN:
			if idx == _graham_pivot:
				return COL_PIVOT
			if idx in _graham_rejected:
				return COL_REJECTED
			if idx in _graham_stack:
				return COL_HULL
			if _graham_scan_i < _graham_sorted_idx.size() and _graham_sorted_idx[_graham_scan_i] == idx:
				return COL_CURRENT
		elif _algo == Algo.JARVIS_MARCH:
			if idx == _jarvis_start:
				return COL_PIVOT
			if idx in _jarvis_hull:
				return COL_HULL
			if idx == _jarvis_current:
				return COL_CURRENT
			if idx == _jarvis_candidate:
				return COL_CANDIDATE
	elif _state == State.COMPLETE:
		if idx in _hull_indices:
			return COL_HULL
		# Identify extreme points in completed hull
		if _hull_indices.size() > 0:
			var pivot := _hull_indices[0] if _hull_indices.size() > 0 else -1
			if idx == pivot:
				return COL_PIVOT
	return COL_POINT


# ── Hull edges mesh ──────────────────────────────────────────────────

func _setup_hull_mesh() -> void:
	_hull_im = ImmediateMesh.new()
	_hull_mi = MeshInstance3D.new()
	_hull_mi.mesh = _hull_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hull_mi.material_override = mat
	add_child(_hull_mi)


func _rebuild_hull_edges() -> void:
	_hull_im.clear_surfaces()
	var indices: Array[int] = []
	if _state == State.STEPPING:
		if _algo == Algo.GRAHAM_SCAN:
			indices = _graham_stack.duplicate()
		else:
			indices = _jarvis_hull.duplicate()
	elif _state == State.COMPLETE:
		indices = _hull_indices.duplicate()

	if indices.size() < 2:
		return

	_hull_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(indices.size()):
		var a := _points[indices[i]]
		var b := _points[indices[(i + 1) % indices.size()]]
		# Elevate slightly so edges float above grid
		a.y = 0.005
		b.y = 0.005
		_hull_im.surface_set_color(COL_EDGE)
		_hull_im.surface_add_vertex(a)
		_hull_im.surface_set_color(COL_EDGE)
		_hull_im.surface_add_vertex(b)
	# Close the hull if complete
	if _state == State.COMPLETE and indices.size() >= 3:
		var a := _points[indices[-1]]
		var b := _points[indices[0]]
		a.y = 0.005
		b.y = 0.005
		_hull_im.surface_set_color(COL_EDGE)
		_hull_im.surface_add_vertex(a)
		_hull_im.surface_set_color(COL_EDGE)
		_hull_im.surface_add_vertex(b)
	_hull_im.surface_end()


# ── Sweep / candidate line mesh ──────────────────────────────────────

func _setup_sweep_mesh() -> void:
	_sweep_im = ImmediateMesh.new()
	_sweep_mi = MeshInstance3D.new()
	_sweep_mi.mesh = _sweep_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sweep_mi.material_override = mat
	add_child(_sweep_mi)


func _rebuild_sweep() -> void:
	_sweep_im.clear_surfaces()
	if _state != State.STEPPING:
		return

	_sweep_im.surface_begin(Mesh.PRIMITIVE_LINES)

	if _algo == Algo.GRAHAM_SCAN:
		# Show line from stack top to current candidate
		if _graham_stack.size() >= 1 and _graham_scan_i < _graham_sorted_idx.size():
			var from := _points[_graham_stack[-1]]
			var to := _points[_graham_sorted_idx[_graham_scan_i]]
			from.y = 0.01
			to.y = 0.01
			_sweep_im.surface_set_color(COL_SWEEP)
			_sweep_im.surface_add_vertex(from)
			_sweep_im.surface_set_color(COL_SWEEP)
			_sweep_im.surface_add_vertex(to)
		# Show stack-top to second-from-top (the turn check)
		if _graham_stack.size() >= 2:
			var a := _points[_graham_stack[-2]]
			var b := _points[_graham_stack[-1]]
			a.y = 0.01
			b.y = 0.01
			_sweep_im.surface_set_color(Color(0.7, 0.5, 1.0, 0.5))
			_sweep_im.surface_add_vertex(a)
			_sweep_im.surface_set_color(Color(0.7, 0.5, 1.0, 0.5))
			_sweep_im.surface_add_vertex(b)

	elif _algo == Algo.JARVIS_MARCH:
		# Show line from current to candidate
		if _jarvis_current >= 0 and _jarvis_candidate >= 0:
			var from := _points[_jarvis_current]
			var to := _points[_jarvis_candidate]
			from.y = 0.01
			to.y = 0.01
			_sweep_im.surface_set_color(COL_SWEEP)
			_sweep_im.surface_add_vertex(from)
			_sweep_im.surface_set_color(COL_SWEEP)
			_sweep_im.surface_add_vertex(to)
		# Show line being checked (current to check point)
		if _jarvis_current >= 0 and _jarvis_check_i < _points.size():
			var from := _points[_jarvis_current]
			var to := _points[_jarvis_check_i]
			from.y = 0.01
			to.y = 0.01
			_sweep_im.surface_set_color(Color(1.0, 0.5, 0.3, 0.4))
			_sweep_im.surface_add_vertex(from)
			_sweep_im.surface_set_color(Color(1.0, 0.5, 0.3, 0.4))
			_sweep_im.surface_add_vertex(to)

	_sweep_im.surface_end()


# ── Winding order arrows ─────────────────────────────────────────────

func _setup_arrow_mesh() -> void:
	_arrow_im = ImmediateMesh.new()
	_arrow_mi = MeshInstance3D.new()
	_arrow_mi.mesh = _arrow_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_arrow_mi.material_override = mat
	add_child(_arrow_mi)


func _rebuild_winding_arrows() -> void:
	_arrow_im.clear_surfaces()
	if _state != State.COMPLETE or _hull_indices.size() < 3:
		return

	_arrow_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(_hull_indices.size()):
		var a := _points[_hull_indices[i]]
		var b := _points[_hull_indices[(i + 1) % _hull_indices.size()]]
		a.y = 0.015
		b.y = 0.015
		var mid := (a + b) * 0.5
		var dir := (b - a).normalized()
		var arrow_len := 0.018
		# Perpendicular in XZ (rotate 90 degrees)
		var perp := Vector3(-dir.z, 0, dir.x)
		var tip := mid + dir * arrow_len
		# Arrowhead
		_arrow_im.surface_set_color(COL_ARROW)
		_arrow_im.surface_add_vertex(tip)
		_arrow_im.surface_set_color(COL_ARROW)
		_arrow_im.surface_add_vertex(tip - dir * arrow_len * 0.6 + perp * arrow_len * 0.4)
		_arrow_im.surface_set_color(COL_ARROW)
		_arrow_im.surface_add_vertex(tip)
		_arrow_im.surface_set_color(COL_ARROW)
		_arrow_im.surface_add_vertex(tip - dir * arrow_len * 0.6 - perp * arrow_len * 0.4)
	_arrow_im.surface_end()


# ── Labels ───────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_title_label = Label3D.new()
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.font_size = 24
	_title_label.outline_size = 4
	_title_label.modulate = Color(1.0, 0.95, 0.9)
	_title_label.position = Vector3(0, 0.58, 0)
	add_child(_title_label)

	_stats_label = Label3D.new()
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.font_size = 18
	_stats_label.outline_size = 3
	_stats_label.modulate = Color(0.7, 0.9, 1.0)
	_stats_label.position = Vector3(0, 0.50, 0)
	add_child(_stats_label)

	_algo_label = Label3D.new()
	_algo_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_algo_label.font_size = 16
	_algo_label.outline_size = 3
	_algo_label.modulate = Color(0.9, 0.8, 1.0)
	_algo_label.position = Vector3(0, 0.44, 0)
	add_child(_algo_label)


func _update_labels() -> void:
	var algo_name := "Graham Scan" if _algo == Algo.GRAHAM_SCAN else "Jarvis March"
	var state_name := "Idle"
	match _state:
		State.STEPPING: state_name = "Running..."
		State.COMPLETE: state_name = "Complete"

	if _title_label:
		_title_label.text = "Convex Hull — %s" % algo_name

	if _stats_label:
		var hull_count := _hull_indices.size()
		if _state == State.STEPPING:
			hull_count = _graham_stack.size() if _algo == Algo.GRAHAM_SCAN else _jarvis_hull.size()
		_stats_label.text = "Points: %d  |  Hull: %d  |  Steps: %d  |  %s" % [
			_points.size(), hull_count, _total_steps, state_name]

	if _algo_label:
		if _state == State.STEPPING:
			if _algo == Algo.GRAHAM_SCAN:
				var progress := "Scanning point %d/%d" % [_graham_scan_i, _graham_sorted_idx.size()]
				if _graham_stack.size() >= 2:
					progress += "  |  Stack: %d" % _graham_stack.size()
				_algo_label.text = progress
			else:
				_algo_label.text = "Wrapping from point %d  |  Checking: %d/%d" % [
					_jarvis_current, _jarvis_check_i, _points.size()]
		elif _state == State.COMPLETE:
			var pct := 100.0 * float(_hull_indices.size()) / maxf(float(_points.size()), 1.0)
			_algo_label.text = "Hull: %.0f%% of points  |  Winding: CCW  |  Comparisons: %d" % [pct, _comparisons]
		else:
			_algo_label.text = "Press Space or wait for auto-start"


# ── VR controllers ───────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_pos := -_bounds - 0.20

	_count_ctrl = ParameterController3D.new()
	_count_ctrl.parameter_name = "Points"
	_count_ctrl.min_value = 6.0
	_count_ctrl.max_value = 60.0
	_count_ctrl.default_value = float(point_count)
	_count_ctrl.step_size = 1.0
	_count_ctrl.position = Vector3(-0.3, y_pos, 0)
	_count_ctrl.value_changed.connect(_on_count_changed)
	add_child(_count_ctrl)

	_speed_ctrl = ParameterController3D.new()
	_speed_ctrl.parameter_name = "Speed"
	_speed_ctrl.min_value = 0.2
	_speed_ctrl.max_value = 4.0
	_speed_ctrl.default_value = step_speed
	_speed_ctrl.step_size = 0.1
	_speed_ctrl.position = Vector3(-0.1, y_pos, 0)
	_speed_ctrl.value_changed.connect(_on_speed_changed)
	add_child(_speed_ctrl)

	_dist_ctrl = ParameterController3D.new()
	_dist_ctrl.parameter_name = "Distrib"
	_dist_ctrl.min_value = 0.0
	_dist_ctrl.max_value = 2.0
	_dist_ctrl.default_value = float(distribution)
	_dist_ctrl.step_size = 1.0
	_dist_ctrl.position = Vector3(0.1, y_pos, 0)
	_dist_ctrl.value_changed.connect(_on_dist_changed)
	add_child(_dist_ctrl)

	_algo_ctrl = ParameterController3D.new()
	_algo_ctrl.parameter_name = "Algorithm"
	_algo_ctrl.min_value = 0.0
	_algo_ctrl.max_value = 1.0
	_algo_ctrl.default_value = float(_algo)
	_algo_ctrl.step_size = 1.0
	_algo_ctrl.position = Vector3(0.3, y_pos, 0)
	_algo_ctrl.value_changed.connect(_on_algo_changed)
	add_child(_algo_ctrl)


func _on_count_changed(val: float) -> void:
	point_count = int(val)
	_generate_points()
	_start_algorithm()

func _on_speed_changed(val: float) -> void:
	step_speed = val

func _on_dist_changed(val: float) -> void:
	distribution = int(val)
	_generate_points()
	_start_algorithm()

func _on_algo_changed(val: float) -> void:
	_algo = int(val)
	_start_algorithm()


# ── Point generation ─────────────────────────────────────────────────

func _generate_points() -> void:
	_points.clear()
	match distribution:
		0:  # Uniform
			for i in range(point_count):
				_points.append(Vector3(
					randf_range(-_bounds, _bounds),
					0.0,
					randf_range(-_bounds, _bounds)))
		1:  # Normal (Gaussian)
			for i in range(point_count):
				var x := clampf(randfn(0.0, _bounds * 0.4), -_bounds, _bounds)
				var z := clampf(randfn(0.0, _bounds * 0.4), -_bounds, _bounds)
				_points.append(Vector3(x, 0.0, z))
		2:  # Clustered (3 clusters)
			var centers := [
				Vector3(-0.18, 0.0, -0.12),
				Vector3(0.2, 0.0, 0.15),
				Vector3(-0.05, 0.0, 0.22)
			]
			for i in range(point_count):
				var c: Vector3 = centers[i % 3]
				var x := clampf(c.x + randfn(0.0, 0.08), -_bounds, _bounds)
				var z := clampf(c.z + randfn(0.0, 0.08), -_bounds, _bounds)
				_points.append(Vector3(x, 0.0, z))

	_hull_indices.clear()
	_update_point_visuals()


# ── Algorithm entry ──────────────────────────────────────────────────

func _start_algorithm() -> void:
	_state = State.IDLE
	_hull_indices.clear()
	_comparisons = 0
	_total_steps = 0
	_graham_rejected.clear()

	if _points.size() < 3:
		return

	_state = State.STEPPING
	_step_timer = 0.0

	if _algo == Algo.GRAHAM_SCAN:
		_init_graham()
	else:
		_init_jarvis()

	_update_point_visuals()
	_rebuild_hull_edges()
	_rebuild_sweep()
	_update_labels()


# ── Graham Scan ──────────────────────────────────────────────────────

func _init_graham() -> void:
	# Find lowest-z point (bottom-most); ties broken by x
	_graham_pivot = 0
	for i in range(1, _points.size()):
		if _points[i].z < _points[_graham_pivot].z or \
			(_points[i].z == _points[_graham_pivot].z and _points[i].x < _points[_graham_pivot].x):
			_graham_pivot = i

	# Sort by polar angle from pivot
	_graham_sorted_idx.clear()
	for i in range(_points.size()):
		if i != _graham_pivot:
			_graham_sorted_idx.append(i)

	var pivot_pos := _points[_graham_pivot]
	# Insertion sort by angle (stable, fine for small n)
	for i in range(1, _graham_sorted_idx.size()):
		var key := _graham_sorted_idx[i]
		var key_angle := _polar_angle(pivot_pos, _points[key])
		var key_dist := pivot_pos.distance_to(_points[key])
		var j := i - 1
		while j >= 0:
			var cmp_angle := _polar_angle(pivot_pos, _points[_graham_sorted_idx[j]])
			var cmp_dist := pivot_pos.distance_to(_points[_graham_sorted_idx[j]])
			if cmp_angle > key_angle or (absf(cmp_angle - key_angle) < 0.001 and cmp_dist > key_dist):
				_graham_sorted_idx[j + 1] = _graham_sorted_idx[j]
				j -= 1
			else:
				break
		_graham_sorted_idx[j + 1] = key

	# Initialize stack with pivot and first sorted point
	_graham_stack.clear()
	_graham_stack.append(_graham_pivot)
	if _graham_sorted_idx.size() > 0:
		_graham_stack.append(_graham_sorted_idx[0])
	_graham_scan_i = 1


func _step_graham() -> void:
	_graham_rejected.clear()

	if _graham_scan_i >= _graham_sorted_idx.size():
		# Done
		_hull_indices = _graham_stack.duplicate()
		_state = State.COMPLETE
		_rebuild_winding_arrows()
		return

	var candidate := _graham_sorted_idx[_graham_scan_i]
	_comparisons += 1

	# Check for left turn
	if _graham_stack.size() >= 2:
		var a := _points[_graham_stack[-2]]
		var b := _points[_graham_stack[-1]]
		var c := _points[candidate]
		if not _is_ccw(a, b, c):
			# Pop — not a left turn
			var popped := _graham_stack.pop_back()
			_graham_rejected.append(popped)
			_total_steps += 1
			return  # Don't advance scan_i; recheck with new stack top

	_graham_stack.append(candidate)
	_graham_scan_i += 1
	_total_steps += 1


# ── Jarvis March (Gift Wrapping) ────────────────────────────────────

func _init_jarvis() -> void:
	# Find leftmost point
	_jarvis_start = 0
	for i in range(1, _points.size()):
		if _points[i].x < _points[_jarvis_start].x or \
			(_points[i].x == _points[_jarvis_start].x and _points[i].z < _points[_jarvis_start].z):
			_jarvis_start = i

	_jarvis_hull.clear()
	_jarvis_hull.append(_jarvis_start)
	_jarvis_current = _jarvis_start
	_jarvis_candidate = -1
	_jarvis_check_i = 0


func _step_jarvis() -> void:
	if _jarvis_candidate < 0:
		# Start new wrap iteration — pick first candidate different from current
		_jarvis_candidate = 0
		if _jarvis_candidate == _jarvis_current:
			_jarvis_candidate = 1 if _points.size() > 1 else 0
		_jarvis_check_i = 0

	# Check one point per step for animated sweep
	while _jarvis_check_i < _points.size():
		var i := _jarvis_check_i
		_jarvis_check_i += 1
		_comparisons += 1

		if i == _jarvis_current or i == _jarvis_candidate:
			continue

		if _is_ccw(_points[_jarvis_current], _points[i], _points[_jarvis_candidate]):
			_jarvis_candidate = i

		_total_steps += 1
		return  # One comparison per visual step

	# Finished checking all points — lock in the candidate
	if _jarvis_candidate == _jarvis_start:
		# Completed full loop
		_hull_indices = _jarvis_hull.duplicate()
		_state = State.COMPLETE
		_rebuild_winding_arrows()
		return

	_jarvis_hull.append(_jarvis_candidate)
	_jarvis_current = _jarvis_candidate
	_jarvis_candidate = -1
	_jarvis_check_i = 0
	_total_steps += 1

	# Safety: prevent infinite loop
	if _jarvis_hull.size() > _points.size():
		_hull_indices = _jarvis_hull.duplicate()
		_state = State.COMPLETE
		_rebuild_winding_arrows()


# ── Geometry helpers ─────────────────────────────────────────────────

func _polar_angle(origin: Vector3, p: Vector3) -> float:
	return atan2(p.x - origin.x, p.z - origin.z)


func _is_ccw(a: Vector3, b: Vector3, c: Vector3) -> bool:
	# Cross product Y component in XZ plane
	var cross := (b.x - a.x) * (c.z - a.z) - (b.z - a.z) * (c.x - a.x)
	return cross > 0.0


# ── Process loop ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _state == State.STEPPING:
		_step_timer += delta * step_speed
		while _step_timer >= _step_interval and _state == State.STEPPING:
			_step_timer -= _step_interval
			if _algo == Algo.GRAHAM_SCAN:
				_step_graham()
			else:
				_step_jarvis()

		_update_point_visuals()
		_rebuild_hull_edges()
		_rebuild_sweep()

	elif _state == State.COMPLETE:
		# Gentle pulse on hull edges
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := 0.7 + 0.3 * sin(t * 3.0)
		if _hull_mi and _hull_mi.material_override:
			(_hull_mi.material_override as StandardMaterial3D).albedo_color = Color(pulse, pulse, pulse)

	_update_labels()


# ── Input ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_generate_points()
				_start_algorithm()
			KEY_R:
				_start_algorithm()  # Restart with same points
			KEY_1:
				_algo = Algo.GRAHAM_SCAN
				if _algo_ctrl:
					_algo_ctrl.set_value(0.0)
				_start_algorithm()
			KEY_2:
				_algo = Algo.JARVIS_MARCH
				if _algo_ctrl:
					_algo_ctrl.set_value(1.0)
				_start_algorithm()


# ── Cleanup ──────────────────────────────────────────────────────────

func _exit_tree() -> void:
	for im in [_hull_im, _sweep_im, _arrow_im, _grid_im]:
		if im:
			im.clear_surfaces()


# ── Grid config ──────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("points"):
		point_count = clampi(int(config.points), 6, 60)
		if _count_ctrl:
			_count_ctrl.set_value(float(point_count))

	if config.has("speed"):
		step_speed = clampf(float(config.speed), 0.2, 4.0)
		if _speed_ctrl:
			_speed_ctrl.set_value(step_speed)

	if config.has("distribution"):
		distribution = clampi(int(config.distribution), 0, 2)
		if _dist_ctrl:
			_dist_ctrl.set_value(float(distribution))

	if config.has("algorithm"):
		_algo = clampi(int(config.algorithm), 0, 1)
		if _algo_ctrl:
			_algo_ctrl.set_value(float(_algo))

	_generate_points()
	_start_algorithm()
