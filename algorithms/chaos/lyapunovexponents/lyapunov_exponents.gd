extends Node3D

## Lyapunov Exponents — Expressive VR 3D visualization
## Computes actual Lyapunov exponents λ(a,b) from the logistic map with
## alternating parameter sequences. Displays as a 3D heightmap where
## height and color encode chaos (λ>0) vs stability (λ<0).
## Includes divergence probe particles and bifurcation cross-section.

@export var grid_resolution: int = 48
@export var bounding_size: float = 0.8
@export var iterations: int = 80
@export var transient_skip: int = 20

# Parameter space bounds
var _a_min: float = 2.0
var _a_max: float = 4.0
var _b_min: float = 2.0
var _b_max: float = 4.0
var _sequence_pattern: String = "AB"

# Computed exponent grid: _lambda_grid[x][z] = float
var _lambda_grid: Array = []
var _lambda_min: float = 0.0
var _lambda_max: float = 0.0
var _needs_recompute: bool = true
var _computing: bool = false
var _compute_row: int = 0

# Heightmap mesh
var _heightmap_mesh_instance: MeshInstance3D
var _heightmap_imesh: ImmediateMesh
var _heightmap_material: StandardMaterial3D

# Probe system: show trajectory divergence at a point
var _probe_mesh_instance: MeshInstance3D
var _probe_imesh: ImmediateMesh
var _probe_material: StandardMaterial3D
var _probe_a: float = 3.5
var _probe_b: float = 3.2
var _probe_particles_a: PackedFloat64Array  # trajectory 1
var _probe_particles_b: PackedFloat64Array  # perturbed trajectory
var _probe_max_points: int = 120
var _probe_marker: MeshInstance3D

# Bifurcation cross-section
var _bifurcation_mesh_instance: MeshInstance3D
var _bifurcation_imesh: ImmediateMesh
var _bifurcation_material: StandardMaterial3D

# Labels
var _title_label: Label3D
var _metrics_label: Label3D
var _probe_label: Label3D

# VR controllers
var _a_center_ctrl: ParameterController3D
var _b_center_ctrl: ParameterController3D
var _zoom_ctrl: ParameterController3D
var _iter_ctrl: ParameterController3D

# Cursor position on grid (normalized 0-1)
var _cursor_u: float = 0.6
var _cursor_v: float = 0.5

var _is_initialized: bool = false
var _frame_count: int = 0


func _ready() -> void:
	_setup_heightmap_mesh()
	_setup_probe_mesh()
	_setup_bifurcation_mesh()
	_setup_probe_marker()
	_setup_labels()
	_setup_controllers()
	_init_lambda_grid()
	_needs_recompute = true
	_is_initialized = true


# ── Mesh setup ──────────────────────────────────────────────────────────

func _setup_heightmap_mesh() -> void:
	_heightmap_imesh = ImmediateMesh.new()
	_heightmap_mesh_instance = MeshInstance3D.new()
	_heightmap_mesh_instance.mesh = _heightmap_imesh
	_heightmap_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_heightmap_material = StandardMaterial3D.new()
	_heightmap_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_heightmap_material.vertex_color_use_as_albedo = true
	_heightmap_material.emission_enabled = true
	_heightmap_material.emission = Color(0.2, 0.3, 0.5)
	_heightmap_material.emission_energy_multiplier = 1.2
	_heightmap_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_heightmap_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_heightmap_mesh_instance.material_override = _heightmap_material
	add_child(_heightmap_mesh_instance)


func _setup_probe_mesh() -> void:
	_probe_imesh = ImmediateMesh.new()
	_probe_mesh_instance = MeshInstance3D.new()
	_probe_mesh_instance.mesh = _probe_imesh
	_probe_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_probe_material = StandardMaterial3D.new()
	_probe_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_probe_material.vertex_color_use_as_albedo = true
	_probe_material.emission_enabled = true
	_probe_material.emission = Color(1.0, 0.6, 0.2)
	_probe_material.emission_energy_multiplier = 2.5
	_probe_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_probe_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_probe_mesh_instance.material_override = _probe_material
	add_child(_probe_mesh_instance)


func _setup_bifurcation_mesh() -> void:
	_bifurcation_imesh = ImmediateMesh.new()
	_bifurcation_mesh_instance = MeshInstance3D.new()
	_bifurcation_mesh_instance.mesh = _bifurcation_imesh
	_bifurcation_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_bifurcation_material = StandardMaterial3D.new()
	_bifurcation_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bifurcation_material.vertex_color_use_as_albedo = true
	_bifurcation_material.emission_enabled = true
	_bifurcation_material.emission = Color(0.5, 0.8, 1.0)
	_bifurcation_material.emission_energy_multiplier = 2.0
	_bifurcation_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bifurcation_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_bifurcation_mesh_instance.material_override = _bifurcation_material
	# Position bifurcation view behind the heightmap
	_bifurcation_mesh_instance.position = Vector3(0, 0, -bounding_size * 0.55)
	add_child(_bifurcation_mesh_instance)


func _setup_probe_marker() -> void:
	_probe_marker = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	sphere.radial_segments = 10
	sphere.rings = 6
	_probe_marker.mesh = sphere
	_probe_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.8)
	mat.emission_energy_multiplier = 4.0
	_probe_marker.material_override = mat
	add_child(_probe_marker)


func _setup_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.pixel_size = 0.001
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.no_depth_test = true
	_title_label.modulate = Color(1, 1, 1, 0.9)
	_title_label.position = Vector3(0, bounding_size * 0.65, 0)
	add_child(_title_label)

	_metrics_label = Label3D.new()
	_metrics_label.font_size = 22
	_metrics_label.pixel_size = 0.001
	_metrics_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_metrics_label.no_depth_test = true
	_metrics_label.modulate = Color(0.7, 0.9, 1.0, 0.85)
	_metrics_label.position = Vector3(0, bounding_size * 0.65 - 0.06, 0)
	add_child(_metrics_label)

	_probe_label = Label3D.new()
	_probe_label.font_size = 20
	_probe_label.pixel_size = 0.001
	_probe_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_probe_label.no_depth_test = true
	_probe_label.modulate = Color(1.0, 0.8, 0.5, 0.85)
	_probe_label.position = Vector3(0, bounding_size * 0.65 - 0.12, 0)
	add_child(_probe_label)


func _setup_controllers() -> void:
	var y_pos := -bounding_size * 0.55

	_a_center_ctrl = ParameterController3D.new()
	_a_center_ctrl.parameter_name = "A center"
	_a_center_ctrl.min_value = 1.0
	_a_center_ctrl.max_value = 4.0
	_a_center_ctrl.default_value = 3.0
	_a_center_ctrl.step_size = 0.02
	_a_center_ctrl.position = Vector3(-0.3, y_pos, 0)
	_a_center_ctrl.value_changed.connect(_on_a_center_changed)
	add_child(_a_center_ctrl)

	_b_center_ctrl = ParameterController3D.new()
	_b_center_ctrl.parameter_name = "B center"
	_b_center_ctrl.min_value = 1.0
	_b_center_ctrl.max_value = 4.0
	_b_center_ctrl.default_value = 3.0
	_b_center_ctrl.step_size = 0.02
	_b_center_ctrl.position = Vector3(0.0, y_pos, 0)
	_b_center_ctrl.value_changed.connect(_on_b_center_changed)
	add_child(_b_center_ctrl)

	_zoom_ctrl = ParameterController3D.new()
	_zoom_ctrl.parameter_name = "Zoom"
	_zoom_ctrl.min_value = 0.2
	_zoom_ctrl.max_value = 3.0
	_zoom_ctrl.default_value = 2.0
	_zoom_ctrl.step_size = 0.05
	_zoom_ctrl.position = Vector3(0.3, y_pos, 0)
	_zoom_ctrl.value_changed.connect(_on_zoom_changed)
	add_child(_zoom_ctrl)

	_iter_ctrl = ParameterController3D.new()
	_iter_ctrl.parameter_name = "Iterations"
	_iter_ctrl.min_value = 20.0
	_iter_ctrl.max_value = 200.0
	_iter_ctrl.default_value = 80.0
	_iter_ctrl.step_size = 10.0
	_iter_ctrl.position = Vector3(0.0, y_pos - 0.12, 0)
	_iter_ctrl.value_changed.connect(_on_iter_changed)
	add_child(_iter_ctrl)


# ── Controller callbacks ────────────────────────────────────────────────

func _on_a_center_changed(val: float) -> void:
	var half_range := (_a_max - _a_min) * 0.5
	_a_min = maxf(0.0, val - half_range)
	_a_max = minf(4.0, val + half_range)
	_needs_recompute = true


func _on_b_center_changed(val: float) -> void:
	var half_range := (_b_max - _b_min) * 0.5
	_b_min = maxf(0.0, val - half_range)
	_b_max = minf(4.0, val + half_range)
	_needs_recompute = true


func _on_zoom_changed(val: float) -> void:
	var a_center := (_a_min + _a_max) * 0.5
	var b_center := (_b_min + _b_max) * 0.5
	var half := val * 0.5
	_a_min = maxf(0.0, a_center - half)
	_a_max = minf(4.0, a_center + half)
	_b_min = maxf(0.0, b_center - half)
	_b_max = minf(4.0, b_center + half)
	_needs_recompute = true


func _on_iter_changed(val: float) -> void:
	iterations = int(val)
	transient_skip = int(val * 0.25)
	_needs_recompute = true


# ── Lambda grid computation ─────────────────────────────────────────────

func _init_lambda_grid() -> void:
	_lambda_grid.clear()
	_lambda_grid.resize(grid_resolution)
	for x in range(grid_resolution):
		var row: PackedFloat64Array = PackedFloat64Array()
		row.resize(grid_resolution)
		_lambda_grid[x] = row


func _compute_lyapunov(a: float, b: float) -> float:
	## Compute Lyapunov exponent for logistic map with alternating parameters.
	## x_{n+1} = r_n * x_n * (1 - x_n), where r alternates per _sequence_pattern.
	var x: float = 0.5 + randf_range(-0.01, 0.01)
	var seq_len := _sequence_pattern.length()
	if seq_len == 0:
		return 0.0

	var lyapunov_sum: float = 0.0
	var total_steps := transient_skip + iterations

	for n in range(total_steps):
		var r: float
		var seq_char := _sequence_pattern[n % seq_len]
		if seq_char == "A" or seq_char == "a":
			r = a
		else:
			r = b

		# Logistic map derivative: d/dx [r*x*(1-x)] = r*(1 - 2x)
		var deriv := absf(r * (1.0 - 2.0 * x))

		if n >= transient_skip and deriv > 1e-12:
			lyapunov_sum += log(deriv)

		# Iterate
		x = r * x * (1.0 - x)

		# Clamp to prevent blowup
		if x < 0.0 or x > 1.0 or is_nan(x) or is_inf(x):
			x = 0.5 + randf_range(-0.01, 0.01)

	if iterations > 0:
		return lyapunov_sum / float(iterations)
	return 0.0


func _compute_grid_incremental() -> bool:
	## Compute a few rows per frame to avoid stalling. Returns true when done.
	var rows_per_frame := 4
	var end_row := mini(_compute_row + rows_per_frame, grid_resolution)

	for x in range(_compute_row, end_row):
		var a := lerpf(_a_min, _a_max, float(x) / float(grid_resolution - 1))
		var row: PackedFloat64Array = _lambda_grid[x]
		for z in range(grid_resolution):
			var b := lerpf(_b_min, _b_max, float(z) / float(grid_resolution - 1))
			row[z] = _compute_lyapunov(a, b)
		_lambda_grid[x] = row

	_compute_row = end_row
	return _compute_row >= grid_resolution


func _find_grid_bounds() -> void:
	_lambda_min = 0.0
	_lambda_max = 0.0
	for x in range(grid_resolution):
		var row: PackedFloat64Array = _lambda_grid[x]
		for z in range(grid_resolution):
			var val: float = row[z]
			if not is_nan(val) and not is_inf(val):
				_lambda_min = minf(_lambda_min, val)
				_lambda_max = maxf(_lambda_max, val)
	# Ensure symmetric range for nice coloring
	var abs_max := maxf(absf(_lambda_min), absf(_lambda_max))
	if abs_max < 0.01:
		abs_max = 1.0
	_lambda_min = -abs_max
	_lambda_max = abs_max


# ── Main loop ───────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _is_initialized:
		return

	_frame_count += 1

	# Incremental computation
	if _needs_recompute:
		_needs_recompute = false
		_computing = true
		_compute_row = 0

	if _computing:
		if _compute_grid_incremental():
			_computing = false
			_find_grid_bounds()
			_rebuild_heightmap()
			_rebuild_bifurcation()
			_update_probe()

	# Update probe marker position based on cursor
	_update_probe_marker()

	# Animate probe trajectories
	if _frame_count % 3 == 0 and not _computing:
		_animate_probe_step()
		_rebuild_probe_mesh()

	_update_labels()


# ── Heightmap rendering ────────────────────────────────────────────────

func _lambda_to_color(val: float) -> Color:
	## Map Lyapunov exponent to color:
	## Negative (stable): deep blue → cyan
	## Near zero (edge of chaos): green/yellow
	## Positive (chaotic): orange → red
	if is_nan(val) or is_inf(val):
		return Color(0.1, 0.1, 0.1, 0.3)

	var abs_max := maxf(absf(_lambda_min), absf(_lambda_max))
	if abs_max < 0.01:
		abs_max = 1.0
	var t := clampf(val / abs_max, -1.0, 1.0)

	var r: float
	var g: float
	var b: float

	if t < -0.5:
		# Deep stable: dark blue → blue
		var s := (t + 1.0) * 2.0
		r = 0.05
		g = 0.1 + 0.2 * s
		b = 0.3 + 0.5 * s
	elif t < 0.0:
		# Mildly stable: blue → cyan/green
		var s := (t + 0.5) * 2.0
		r = 0.05 + 0.15 * s
		g = 0.3 + 0.5 * s
		b = 0.8 - 0.3 * s
	elif t < 0.5:
		# Mildly chaotic: green/yellow → orange
		var s := t * 2.0
		r = 0.2 + 0.6 * s
		g = 0.8 - 0.2 * s
		b = 0.5 - 0.4 * s
	else:
		# Strongly chaotic: orange → red
		var s := (t - 0.5) * 2.0
		r = 0.8 + 0.2 * s
		g = 0.6 - 0.5 * s
		b = 0.1

	return Color(r, g, b, 0.9)


func _lambda_to_height(val: float) -> float:
	if is_nan(val) or is_inf(val):
		return 0.0
	var abs_max := maxf(absf(_lambda_min), absf(_lambda_max))
	if abs_max < 0.01:
		abs_max = 1.0
	return clampf(val / abs_max, -1.0, 1.0) * bounding_size * 0.25


func _rebuild_heightmap() -> void:
	_heightmap_imesh.clear_surfaces()
	if grid_resolution < 2:
		return

	var half := bounding_size * 0.5

	_heightmap_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(grid_resolution - 1):
		var row_a: PackedFloat64Array = _lambda_grid[x]
		var row_b: PackedFloat64Array = _lambda_grid[x + 1]
		for z in range(grid_resolution - 1):
			# Quad corners
			var u0 := float(x) / float(grid_resolution - 1)
			var u1 := float(x + 1) / float(grid_resolution - 1)
			var v0 := float(z) / float(grid_resolution - 1)
			var v1 := float(z + 1) / float(grid_resolution - 1)

			var val00: float = row_a[z]
			var val10: float = row_b[z]
			var val01: float = row_a[z + 1]
			var val11: float = row_b[z + 1]

			var p00 := Vector3(u0 * bounding_size - half, _lambda_to_height(val00), v0 * bounding_size - half)
			var p10 := Vector3(u1 * bounding_size - half, _lambda_to_height(val10), v0 * bounding_size - half)
			var p01 := Vector3(u0 * bounding_size - half, _lambda_to_height(val01), v1 * bounding_size - half)
			var p11 := Vector3(u1 * bounding_size - half, _lambda_to_height(val11), v1 * bounding_size - half)

			var c00 := _lambda_to_color(val00)
			var c10 := _lambda_to_color(val10)
			var c01 := _lambda_to_color(val01)
			var c11 := _lambda_to_color(val11)

			# Triangle 1: p00, p10, p01
			_heightmap_imesh.surface_set_color(c00)
			_heightmap_imesh.surface_add_vertex(p00)
			_heightmap_imesh.surface_set_color(c10)
			_heightmap_imesh.surface_add_vertex(p10)
			_heightmap_imesh.surface_set_color(c01)
			_heightmap_imesh.surface_add_vertex(p01)

			# Triangle 2: p10, p11, p01
			_heightmap_imesh.surface_set_color(c10)
			_heightmap_imesh.surface_add_vertex(p10)
			_heightmap_imesh.surface_set_color(c11)
			_heightmap_imesh.surface_add_vertex(p11)
			_heightmap_imesh.surface_set_color(c01)
			_heightmap_imesh.surface_add_vertex(p01)

	_heightmap_imesh.surface_end()


# ── Bifurcation cross-section ──────────────────────────────────────────

func _rebuild_bifurcation() -> void:
	## Draw bifurcation diagram: fix b at probe position, sweep a.
	## Shows the logistic map's stable orbits as vertical dots.
	_bifurcation_imesh.clear_surfaces()

	var b_fixed := lerpf(_b_min, _b_max, _cursor_v)
	var samples := grid_resolution * 2
	var half := bounding_size * 0.5
	var orbit_points := 40
	var transient := 60

	_bifurcation_imesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw axis frame
	var axis_color := Color(0.4, 0.5, 0.6, 0.5)
	_bifurcation_imesh.surface_set_color(axis_color)
	_bifurcation_imesh.surface_add_vertex(Vector3(-half, -half * 0.3, 0))
	_bifurcation_imesh.surface_set_color(axis_color)
	_bifurcation_imesh.surface_add_vertex(Vector3(half, -half * 0.3, 0))

	_bifurcation_imesh.surface_set_color(axis_color)
	_bifurcation_imesh.surface_add_vertex(Vector3(-half, -half * 0.3, 0))
	_bifurcation_imesh.surface_set_color(axis_color)
	_bifurcation_imesh.surface_add_vertex(Vector3(-half, half * 0.3, 0))

	# Plot orbit points
	for i in range(samples):
		var a := lerpf(_a_min, _a_max, float(i) / float(samples - 1))
		var x: float = 0.5
		var seq_len := _sequence_pattern.length()
		if seq_len == 0:
			continue

		# Skip transient
		for n in range(transient):
			var r: float
			if _sequence_pattern[n % seq_len] == "A" or _sequence_pattern[n % seq_len] == "a":
				r = a
			else:
				r = b_fixed
			x = r * x * (1.0 - x)
			if x < 0.0 or x > 1.0 or is_nan(x):
				x = 0.5

		# Record orbit
		for n in range(orbit_points):
			var r: float
			var step := transient + n
			if _sequence_pattern[step % seq_len] == "A" or _sequence_pattern[step % seq_len] == "a":
				r = a
			else:
				r = b_fixed
			x = r * x * (1.0 - x)
			if x < 0.0 or x > 1.0 or is_nan(x):
				x = 0.5
				continue

			var px := float(i) / float(samples - 1) * bounding_size - half
			var py := (x - 0.5) * bounding_size * 0.6
			var point_color := Color(0.6, 0.85, 1.0, 0.4)

			# Draw a tiny vertical line segment for each point
			_bifurcation_imesh.surface_set_color(point_color)
			_bifurcation_imesh.surface_add_vertex(Vector3(px, py - 0.001, 0))
			_bifurcation_imesh.surface_set_color(point_color)
			_bifurcation_imesh.surface_add_vertex(Vector3(px, py + 0.001, 0))

	_bifurcation_imesh.surface_end()


# ── Probe system ───────────────────────────────────────────────────────

func _update_probe() -> void:
	_probe_a = lerpf(_a_min, _a_max, _cursor_u)
	_probe_b = lerpf(_b_min, _b_max, _cursor_v)
	_reset_probe_trajectories()


func _reset_probe_trajectories() -> void:
	_probe_particles_a = PackedFloat64Array()
	_probe_particles_b = PackedFloat64Array()
	# Start with very close initial conditions
	_probe_particles_a.append(0.5)
	_probe_particles_b.append(0.5 + 1e-6)


func _animate_probe_step() -> void:
	if _probe_particles_a.size() == 0:
		return

	if _probe_particles_a.size() >= _probe_max_points:
		_reset_probe_trajectories()
		return

	var x_a: float = _probe_particles_a[_probe_particles_a.size() - 1]
	var x_b: float = _probe_particles_b[_probe_particles_b.size() - 1]
	var seq_len := _sequence_pattern.length()
	if seq_len == 0:
		return

	var step := _probe_particles_a.size() - 1
	var r: float
	if _sequence_pattern[step % seq_len] == "A" or _sequence_pattern[step % seq_len] == "a":
		r = _probe_a
	else:
		r = _probe_b

	var new_a := r * x_a * (1.0 - x_a)
	var new_b := r * x_b * (1.0 - x_b)

	if is_nan(new_a) or new_a < 0.0 or new_a > 1.0:
		new_a = 0.5
	if is_nan(new_b) or new_b < 0.0 or new_b > 1.0:
		new_b = 0.5

	_probe_particles_a.append(new_a)
	_probe_particles_b.append(new_b)


func _rebuild_probe_mesh() -> void:
	_probe_imesh.clear_surfaces()
	var count := _probe_particles_a.size()
	if count < 2:
		return

	var half := bounding_size * 0.5
	var y_base := bounding_size * 0.35

	_probe_imesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw trajectory A (white-yellow)
	for i in range(1, count):
		var age_t := float(i) / float(count)
		var x0 := float(i - 1) / float(_probe_max_points) * bounding_size - half
		var x1 := float(i) / float(_probe_max_points) * bounding_size - half
		var y0 := float(_probe_particles_a[i - 1]) * bounding_size * 0.3 + y_base
		var y1 := float(_probe_particles_a[i]) * bounding_size * 0.3 + y_base
		var color_a := Color(1.0, 0.95, 0.5, 0.3 + 0.7 * age_t)

		_probe_imesh.surface_set_color(color_a)
		_probe_imesh.surface_add_vertex(Vector3(x0, y0, 0))
		_probe_imesh.surface_set_color(color_a)
		_probe_imesh.surface_add_vertex(Vector3(x1, y1, 0))

	# Draw trajectory B (orange-red)
	for i in range(1, count):
		var age_t := float(i) / float(count)
		var x0 := float(i - 1) / float(_probe_max_points) * bounding_size - half
		var x1 := float(i) / float(_probe_max_points) * bounding_size - half
		var y0 := float(_probe_particles_b[i - 1]) * bounding_size * 0.3 + y_base
		var y1 := float(_probe_particles_b[i]) * bounding_size * 0.3 + y_base
		var color_b := Color(1.0, 0.4, 0.2, 0.3 + 0.7 * age_t)

		_probe_imesh.surface_set_color(color_b)
		_probe_imesh.surface_add_vertex(Vector3(x0, y0, 0))
		_probe_imesh.surface_set_color(color_b)
		_probe_imesh.surface_add_vertex(Vector3(x1, y1, 0))

	# Draw divergence lines connecting the two trajectories every few steps
	for i in range(0, count, 5):
		var x_pos := float(i) / float(_probe_max_points) * bounding_size - half
		var y_a := float(_probe_particles_a[i]) * bounding_size * 0.3 + y_base
		var y_b := float(_probe_particles_b[i]) * bounding_size * 0.3 + y_base
		var sep := absf(float(_probe_particles_a[i]) - float(_probe_particles_b[i]))
		var div_color := Color(0.8, 0.3, 0.3, clampf(sep * 1000.0, 0.1, 0.8))

		_probe_imesh.surface_set_color(div_color)
		_probe_imesh.surface_add_vertex(Vector3(x_pos, y_a, 0))
		_probe_imesh.surface_set_color(div_color)
		_probe_imesh.surface_add_vertex(Vector3(x_pos, y_b, 0))

	_probe_imesh.surface_end()


func _update_probe_marker() -> void:
	if _lambda_grid.size() < grid_resolution or grid_resolution < 2:
		_probe_marker.visible = false
		return

	var half := bounding_size * 0.5
	var gx := clampi(int(_cursor_u * (grid_resolution - 1)), 0, grid_resolution - 1)
	var gz := clampi(int(_cursor_v * (grid_resolution - 1)), 0, grid_resolution - 1)
	var row: PackedFloat64Array = _lambda_grid[gx]
	var val: float = row[gz]

	_probe_marker.position = Vector3(
		_cursor_u * bounding_size - half,
		_lambda_to_height(val) + 0.02,
		_cursor_v * bounding_size - half
	)
	_probe_marker.visible = true

	# Pulse color based on chaos
	var mat := _probe_marker.material_override as StandardMaterial3D
	if val > 0:
		mat.emission = Color(1.0, 0.5, 0.2)
	else:
		mat.emission = Color(0.3, 0.8, 1.0)
	mat.emission_energy_multiplier = 3.0 + 2.0 * absf(clampf(val, -1.0, 1.0))


# ── Labels ──────────────────────────────────────────────────────────────

func _update_labels() -> void:
	var status := ""
	if _computing:
		status = " (computing %d%%)" % [int(float(_compute_row) / float(grid_resolution) * 100)]

	_title_label.text = "Lyapunov Fractal  [%s]%s" % [_sequence_pattern, status]

	_metrics_label.text = "a ∈ [%.2f, %.2f]  b ∈ [%.2f, %.2f]  %dx%d  %d iter" % [
		_a_min, _a_max, _b_min, _b_max, grid_resolution, grid_resolution, iterations
	]

	# Probe info
	var gx := clampi(int(_cursor_u * (grid_resolution - 1)), 0, grid_resolution - 1)
	var gz := clampi(int(_cursor_v * (grid_resolution - 1)), 0, grid_resolution - 1)
	if gx < _lambda_grid.size():
		var row: PackedFloat64Array = _lambda_grid[gx]
		if gz < row.size():
			var val: float = row[gz]
			var chaos_label := "(chaotic)" if val > 0 else "(stable)"
			_probe_label.text = "Probe: a=%.3f b=%.3f  λ=%.4f %s" % [
				_probe_a, _probe_b, val, chaos_label
			]


# ── Public API ──────────────────────────────────────────────────────────

func reset() -> void:
	_a_min = 2.0
	_a_max = 4.0
	_b_min = 2.0
	_b_max = 4.0
	_cursor_u = 0.6
	_cursor_v = 0.5
	_sequence_pattern = "AB"
	_needs_recompute = true
	_sync_controllers()


func set_sequence(seq: String) -> void:
	_sequence_pattern = seq.to_upper()
	_needs_recompute = true


func set_probe_position(u: float, v: float) -> void:
	_cursor_u = clampf(u, 0.0, 1.0)
	_cursor_v = clampf(v, 0.0, 1.0)
	_update_probe()


func _sync_controllers() -> void:
	if _a_center_ctrl:
		_a_center_ctrl.set_value((_a_min + _a_max) * 0.5)
	if _b_center_ctrl:
		_b_center_ctrl.set_value((_b_min + _b_max) * 0.5)
	if _zoom_ctrl:
		_zoom_ctrl.set_value(_a_max - _a_min)
	if _iter_ctrl:
		_iter_ctrl.set_value(float(iterations))


func apply_grid_config(config: Dictionary) -> void:
	if config.has("a_min"):
		_a_min = float(config.a_min)
	if config.has("a_max"):
		_a_max = float(config.a_max)
	if config.has("b_min"):
		_b_min = float(config.b_min)
	if config.has("b_max"):
		_b_max = float(config.b_max)
	if config.has("sequence"):
		_sequence_pattern = str(config.sequence).to_upper()
	if config.has("resolution"):
		grid_resolution = clampi(int(config.resolution), 8, 128)
		_init_lambda_grid()
	if config.has("iterations"):
		iterations = clampi(int(config.iterations), 10, 500)
		transient_skip = int(iterations * 0.25)
	if config.has("probe_u"):
		_cursor_u = clampf(float(config.probe_u), 0.0, 1.0)
	if config.has("probe_v"):
		_cursor_v = clampf(float(config.probe_v), 0.0, 1.0)

	_needs_recompute = true
	_sync_controllers()


func _exit_tree() -> void:
	if _heightmap_imesh:
		_heightmap_imesh.clear_surfaces()
	if _probe_imesh:
		_probe_imesh.clear_surfaces()
	if _bifurcation_imesh:
		_bifurcation_imesh.clear_surfaces()
