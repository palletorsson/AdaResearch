# ReactionDiffusion.gd — Gray-Scott bifurcation, 3D surface RD, spiral patterns
# Elevated: ImmediateMesh rendering, 3 modes, VR controls, apply_grid_config
extends Node3D

enum Mode { BIFURCATION, SURFACE_3D, SPIRAL }

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

# ─── Tunable parameters ───
@export var grid_size: int = 48
@export var feed_rate: float = 0.037
@export var kill_rate: float = 0.06
@export var diffusion_u: float = 0.21
@export var diffusion_v: float = 0.105
@export var step_speed: float = 1.0
@export var sphere_radius: float = 0.4

# ─── Mode state ───
var _mode: int = Mode.BIFURCATION
var _time: float = 0.0
var _steps_done: int = 0

# ─── Bifurcation mode state ───
var _bif_grid_size: int = 32  # parameter sweep resolution
var _bif_results: PackedFloat32Array  # classification for each (f,k) cell
var _bif_computed: bool = false
var _bif_f_min: float = 0.01
var _bif_f_max: float = 0.08
var _bif_k_min: float = 0.03
var _bif_k_max: float = 0.07
var _bif_probe_size: int = 16  # mini-grid for each probe
var _bif_sweep_row: int = 0
var _bif_sweep_col: int = 0
var _bif_computing: bool = false

# ─── Surface 3D mode state ───
var _sphere_n_lat: int = 32
var _sphere_n_lon: int = 64
var _sphere_u: PackedFloat32Array
var _sphere_v: PackedFloat32Array

# ─── Spiral mode state ───
var _spiral_size: int = 64
var _spiral_u: PackedFloat32Array
var _spiral_v: PackedFloat32Array
var _spiral_w: PackedFloat32Array  # recovery variable for Barkley model
var _spiral_a: float = 0.75
var _spiral_b: float = 0.06
var _spiral_eps: float = 0.08

# ─── ImmediateMesh instances ───
var _pattern_im: ImmediateMesh
var _pattern_mi: MeshInstance3D
var _grid_im: ImmediateMesh
var _grid_mi: MeshInstance3D
var _marker_im: ImmediateMesh
var _marker_mi: MeshInstance3D
var _info_im: ImmediateMesh
var _info_mi: MeshInstance3D

# ─── Materials ───
var _mat_unshaded: StandardMaterial3D
var _mat_unshaded_double: StandardMaterial3D

# ─── Labels ───
var _label_title: Label3D
var _label_info: Label3D
var _label_legend: Label3D

# ─── VR Controls ───
var _slider_feed: Node
var _slider_kill: Node
var _slider_speed: Node
var _btn_mode: Node
var _btn_reset: Node

# ─── Colors ───
const COL_BG = Color(0.05, 0.05, 0.08)
const COL_U_HIGH = Color(0.15, 0.55, 0.95)    # chemical U dominant
const COL_V_HIGH = Color(0.95, 0.25, 0.15)    # chemical V dominant
const COL_MIXED = Color(0.85, 0.75, 0.2)      # both present
const COL_DEAD = Color(0.12, 0.12, 0.15)      # uniform / no pattern
const COL_SPOTS = Color(0.2, 0.85, 0.4)       # bifurcation: spots
const COL_STRIPES = Color(0.95, 0.6, 0.1)     # bifurcation: stripes
const COL_WAVES = Color(0.4, 0.2, 0.9)        # bifurcation: oscillations
const COL_CHAOS = Color(0.9, 0.15, 0.5)       # bifurcation: chaotic
const COL_GRID = Color(0.25, 0.25, 0.3)
const COL_MARKER = Color(1.0, 1.0, 0.3)
const COL_SPIRAL_TIP = Color(1.0, 0.2, 0.8)
const COL_LABEL = Color(0.9, 0.9, 0.95)
const COL_TITLE = Color(0.7, 0.85, 1.0)


func _ready() -> void:
	_create_materials()
	_create_meshes()
	_create_labels()
	_create_controls()
	_init_mode()


func _process(delta: float) -> void:
	_time += delta * step_speed
	match _mode:
		Mode.BIFURCATION:
			_step_bifurcation()
		Mode.SURFACE_3D:
			_step_surface_3d(delta)
		Mode.SPIRAL:
			_step_spiral(delta)
	_draw_all()
	_update_labels()


# ─── Materials ───

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_BACK

	_mat_unshaded_double = StandardMaterial3D.new()
	_mat_unshaded_double.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded_double.vertex_color_use_as_albedo = true
	_mat_unshaded_double.cull_mode = BaseMaterial3D.CULL_DISABLED


# ─── Mesh setup ───

func _create_meshes() -> void:
	_pattern_im = ImmediateMesh.new()
	_pattern_mi = MeshInstance3D.new()
	_pattern_mi.mesh = _pattern_im
	_pattern_mi.material_override = _mat_unshaded_double
	add_child(_pattern_mi)

	_grid_im = ImmediateMesh.new()
	_grid_mi = MeshInstance3D.new()
	_grid_mi.mesh = _grid_im
	_grid_mi.material_override = _mat_unshaded
	add_child(_grid_mi)

	_marker_im = ImmediateMesh.new()
	_marker_mi = MeshInstance3D.new()
	_marker_mi.mesh = _marker_im
	_marker_mi.material_override = _mat_unshaded
	add_child(_marker_mi)

	_info_im = ImmediateMesh.new()
	_info_mi = MeshInstance3D.new()
	_info_mi.mesh = _info_im
	_info_mi.material_override = _mat_unshaded
	add_child(_info_mi)


# ─── Labels ───

func _create_labels() -> void:
	_label_title = Label3D.new()
	_label_title.font_size = 48
	_label_title.position = Vector3(0, 0.85, 0)
	_label_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_title.modulate = COL_TITLE
	_label_title.outline_size = 8
	add_child(_label_title)

	_label_info = Label3D.new()
	_label_info.font_size = 28
	_label_info.position = Vector3(0, -0.65, 0)
	_label_info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_info.modulate = COL_LABEL
	_label_info.outline_size = 6
	add_child(_label_info)

	_label_legend = Label3D.new()
	_label_legend.font_size = 22
	_label_legend.position = Vector3(0.65, 0.3, 0)
	_label_legend.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_legend.modulate = COL_LABEL
	_label_legend.outline_size = 4
	add_child(_label_legend)


# ─── VR Controls ───

func _create_controls() -> void:
	var x0 := -0.5
	var y0 := -0.85
	var spacing := 0.14

	# Mode button
	_btn_mode = ButtonScene.instantiate()
	_btn_mode.position = Vector3(x0, y0, 0)
	_btn_mode.scale = Vector3(0.2, 0.2, 0.2)
	add_child(_btn_mode)
	var mode_label = _btn_mode.get_node_or_null("Frame/LabelName")
	if mode_label:
		mode_label.text = "Mode"
	var mode_area = _btn_mode.get_node_or_null("InteractableAreaButton")
	if mode_area:
		mode_area.button_pressed.connect(_on_mode_pressed)

	# Reset button
	_btn_reset = ButtonScene.instantiate()
	_btn_reset.position = Vector3(x0 + spacing, y0, 0)
	_btn_reset.scale = Vector3(0.2, 0.2, 0.2)
	add_child(_btn_reset)
	var reset_label = _btn_reset.get_node_or_null("Frame/LabelName")
	if reset_label:
		reset_label.text = "Reset"
	var reset_area = _btn_reset.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)

	# Feed rate slider
	_slider_feed = SliderScene.instantiate()
	_slider_feed.position = Vector3(x0 + spacing * 2.5, y0, 0)
	_slider_feed.scale = Vector3(0.3, 0.3, 0.3)
	add_child(_slider_feed)
	_slider_feed.set_param_name("Feed")
	_slider_feed.set_normalized_value(_remap(feed_rate, 0.01, 0.08, 0.0, 1.0))
	_slider_feed.slider_moved.connect(_on_feed_changed)

	# Kill rate slider
	_slider_kill = SliderScene.instantiate()
	_slider_kill.position = Vector3(x0 + spacing * 4.0, y0, 0)
	_slider_kill.scale = Vector3(0.3, 0.3, 0.3)
	add_child(_slider_kill)
	_slider_kill.set_param_name("Kill")
	_slider_kill.set_normalized_value(_remap(kill_rate, 0.03, 0.07, 0.0, 1.0))
	_slider_kill.slider_moved.connect(_on_kill_changed)

	# Speed slider
	_slider_speed = SliderScene.instantiate()
	_slider_speed.position = Vector3(x0 + spacing * 5.5, y0, 0)
	_slider_speed.scale = Vector3(0.3, 0.3, 0.3)
	add_child(_slider_speed)
	_slider_speed.set_param_name("Speed")
	_slider_speed.set_normalized_value(0.5)
	_slider_speed.slider_moved.connect(_on_speed_changed)


func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()


func _on_reset_pressed() -> void:
	_init_mode()


func _on_feed_changed(_val: float) -> void:
	var nv: float = _slider_feed.get_normalized_value()
	feed_rate = lerp(0.01, 0.08, nv)
	if _mode == Mode.BIFURCATION:
		_bif_computed = false
		_bif_sweep_row = 0
		_bif_sweep_col = 0


func _on_kill_changed(_val: float) -> void:
	var nv: float = _slider_kill.get_normalized_value()
	kill_rate = lerp(0.03, 0.07, nv)
	if _mode == Mode.BIFURCATION:
		_bif_computed = false
		_bif_sweep_row = 0
		_bif_sweep_col = 0


func _on_speed_changed(_val: float) -> void:
	var nv: float = _slider_speed.get_normalized_value()
	step_speed = lerp(0.2, 3.0, nv)


# ─── Mode init ───

func _init_mode() -> void:
	_time = 0.0
	_steps_done = 0
	match _mode:
		Mode.BIFURCATION:
			_init_bifurcation()
		Mode.SURFACE_3D:
			_init_surface_3d()
		Mode.SPIRAL:
			_init_spiral()


# ═══════════════════════════════════════════
# MODE 1: BIFURCATION — Gray-Scott parameter space
# ═══════════════════════════════════════════

func _init_bifurcation() -> void:
	_bif_results.resize(_bif_grid_size * _bif_grid_size)
	_bif_results.fill(-1.0)
	_bif_computed = false
	_bif_sweep_row = 0
	_bif_sweep_col = 0
	_bif_computing = false


func _step_bifurcation() -> void:
	if _bif_computed:
		return
	# Compute a batch of cells per frame to avoid stuttering
	var cells_per_frame := 4
	for _i in range(cells_per_frame):
		if _bif_sweep_row >= _bif_grid_size:
			_bif_computed = true
			return
		var f := lerp(_bif_f_min, _bif_f_max, float(_bif_sweep_col) / float(_bif_grid_size - 1))
		var k := lerp(_bif_k_min, _bif_k_max, float(_bif_sweep_row) / float(_bif_grid_size - 1))
		var classification := _probe_gray_scott(f, k)
		_bif_results[_bif_sweep_row * _bif_grid_size + _bif_sweep_col] = classification
		_bif_sweep_col += 1
		if _bif_sweep_col >= _bif_grid_size:
			_bif_sweep_col = 0
			_bif_sweep_row += 1


func _probe_gray_scott(f: float, k: float) -> float:
	# Run a small Gray-Scott simulation and classify the result
	var n := _bif_probe_size
	var u := PackedFloat32Array()
	var v := PackedFloat32Array()
	u.resize(n * n)
	v.resize(n * n)
	u.fill(1.0)
	v.fill(0.0)

	# Seed center
	var cx := n / 2
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var ix := cx + dx
			var iy := cx + dy
			if ix >= 0 and ix < n and iy >= 0 and iy < n:
				u[iy * n + ix] = 0.5
				v[iy * n + ix] = 0.25

	# Run 500 steps
	var du := 0.21
	var dv := 0.105
	var dt := 1.0
	var new_u := PackedFloat32Array()
	var new_v := PackedFloat32Array()
	new_u.resize(n * n)
	new_v.resize(n * n)
	for _step in range(500):
		for y in range(n):
			for x in range(n):
				var idx := y * n + x
				var uc := u[idx]
				var vc := v[idx]
				# 5-point Laplacian with wrapping
				var xm := (x - 1 + n) % n
				var xp := (x + 1) % n
				var ym := (y - 1 + n) % n
				var yp := (y + 1) % n
				var lap_u := u[y * n + xm] + u[y * n + xp] + u[ym * n + x] + u[yp * n + x] - 4.0 * uc
				var lap_v := v[y * n + xm] + v[y * n + xp] + v[ym * n + x] + v[yp * n + x] - 4.0 * vc
				var uvv := uc * vc * vc
				new_u[idx] = clampf(uc + dt * (du * lap_u - uvv + f * (1.0 - uc)), 0.0, 1.0)
				new_v[idx] = clampf(vc + dt * (dv * lap_v + uvv - (k + f) * vc), 0.0, 1.0)
		# Swap
		var tmp := u
		u = new_u
		new_u = tmp
		tmp = v
		v = new_v
		new_v = tmp

	# Classify: measure variance and mean of v
	var mean_v := 0.0
	var max_v := 0.0
	for i in range(n * n):
		mean_v += v[i]
		if v[i] > max_v:
			max_v = v[i]
	mean_v /= float(n * n)

	var variance := 0.0
	for i in range(n * n):
		var d := v[i] - mean_v
		variance += d * d
	variance /= float(n * n)

	# Count how many cells are "active" (v > 0.1)
	var active_count := 0
	for i in range(n * n):
		if v[i] > 0.1:
			active_count += 1
	var active_frac := float(active_count) / float(n * n)

	# Classify
	if max_v < 0.05:
		return 0.0  # Dead / uniform
	elif variance < 0.005:
		return 1.0  # Uniform with some V (waves-like)
	elif active_frac < 0.3:
		return 2.0  # Spots
	elif active_frac < 0.6:
		return 3.0  # Stripes
	else:
		return 4.0  # Chaotic / filled


# ═══════════════════════════════════════════
# MODE 2: SURFACE 3D — Reaction-diffusion on sphere
# ═══════════════════════════════════════════

func _init_surface_3d() -> void:
	var total := _sphere_n_lat * _sphere_n_lon
	_sphere_u.resize(total)
	_sphere_v.resize(total)
	_sphere_u.fill(1.0)
	_sphere_v.fill(0.0)

	# Seed random spots on sphere
	for _i in range(8):
		var lat := randi_range(4, _sphere_n_lat - 5)
		var lon := randi_range(0, _sphere_n_lon - 1)
		for dl in range(-2, 3):
			for dln in range(-2, 3):
				var la := clampi(lat + dl, 0, _sphere_n_lat - 1)
				var lo := (lon + dln + _sphere_n_lon) % _sphere_n_lon
				_sphere_u[la * _sphere_n_lon + lo] = 0.5
				_sphere_v[la * _sphere_n_lon + lo] = 0.25


func _step_surface_3d(delta: float) -> void:
	var steps := int(ceil(step_speed * 8.0))
	var n_lat := _sphere_n_lat
	var n_lon := _sphere_n_lon
	var du := diffusion_u
	var dv := diffusion_v
	var f := feed_rate
	var k := kill_rate
	var dt := 0.9

	var new_u := PackedFloat32Array()
	var new_v := PackedFloat32Array()
	new_u.resize(n_lat * n_lon)
	new_v.resize(n_lat * n_lon)

	for _s in range(steps):
		for lat in range(n_lat):
			for lon in range(n_lon):
				var idx := lat * n_lon + lon
				var uc := _sphere_u[idx]
				var vc := _sphere_v[idx]

				# Neighbors with wrapping on longitude, clamping on latitude
				var lat_m := maxi(lat - 1, 0)
				var lat_p := mini(lat + 1, n_lat - 1)
				var lon_m := (lon - 1 + n_lon) % n_lon
				var lon_p := (lon + 1) % n_lon

				var lap_u := (_sphere_u[lat * n_lon + lon_m] + _sphere_u[lat * n_lon + lon_p]
					+ _sphere_u[lat_m * n_lon + lon] + _sphere_u[lat_p * n_lon + lon] - 4.0 * uc)
				var lap_v := (_sphere_v[lat * n_lon + lon_m] + _sphere_v[lat * n_lon + lon_p]
					+ _sphere_v[lat_m * n_lon + lon] + _sphere_v[lat_p * n_lon + lon] - 4.0 * vc)

				# Scale Laplacian by latitude to account for spherical geometry
				var theta := PI * float(lat) / float(n_lat - 1)
				var sin_theta := sin(theta)
				var scale := maxf(sin_theta, 0.1)  # avoid singularity at poles

				var uvv := uc * vc * vc
				new_u[idx] = clampf(uc + dt * (du * lap_u / scale - uvv + f * (1.0 - uc)), 0.0, 1.0)
				new_v[idx] = clampf(vc + dt * (dv * lap_v / scale + uvv - (k + f) * vc), 0.0, 1.0)

		# Swap
		var tmp := _sphere_u
		_sphere_u = new_u
		new_u = tmp
		tmp = _sphere_v
		_sphere_v = new_v
		new_v = tmp

	_steps_done += steps


# ═══════════════════════════════════════════
# MODE 3: SPIRAL — Barkley model spirals
# ═══════════════════════════════════════════

func _init_spiral() -> void:
	var n := _spiral_size
	var total := n * n
	_spiral_u.resize(total)
	_spiral_v.resize(total)
	_spiral_u.fill(0.0)
	_spiral_v.fill(0.0)

	# Create initial broken wavefront to nucleate spiral
	# Half-plane excitation with a perpendicular recovery barrier
	var half := n / 2
	for y in range(n):
		for x in range(n):
			var idx := y * n + x
			if x < half and y > half:
				_spiral_u[idx] = 1.0  # excited region (quarter)
			if y < half:
				_spiral_v[idx] = _spiral_a / 2.0  # recovery region (top half)


func _step_spiral(delta: float) -> void:
	var steps := int(ceil(step_speed * 6.0))
	var n := _spiral_size
	var a := _spiral_a
	var b := _spiral_b
	var eps := _spiral_eps
	var d_u := 0.05  # diffusion for u
	var dt := 0.15

	var new_u := PackedFloat32Array()
	var new_v := PackedFloat32Array()
	new_u.resize(n * n)
	new_v.resize(n * n)

	for _s in range(steps):
		for y in range(n):
			for x in range(n):
				var idx := y * n + x
				var uc := _spiral_u[idx]
				var vc := _spiral_v[idx]

				# 5-point Laplacian with wrapping
				var xm := (x - 1 + n) % n
				var xp := (x + 1) % n
				var ym := (y - 1 + n) % n
				var yp := (y + 1) % n
				var lap := _spiral_u[y * n + xm] + _spiral_u[y * n + xp] + _spiral_u[ym * n + x] + _spiral_u[yp * n + x] - 4.0 * uc

				# Barkley model: du/dt = (1/eps) * u * (1-u) * (u - (v+b)/a) + D*lap_u
				# dv/dt = u - v
				var threshold := (vc + b) / a
				var reaction := uc * (1.0 - uc) * (uc - threshold) / eps
				new_u[idx] = clampf(uc + dt * (reaction + d_u * lap), 0.0, 1.0)
				new_v[idx] = clampf(vc + dt * (uc - vc), 0.0, 1.0)

		var tmp := _spiral_u
		_spiral_u = new_u
		new_u = tmp
		tmp = _spiral_v
		_spiral_v = new_v
		new_v = tmp

	_steps_done += steps


# ═══════════════════════════════════════════
# DRAWING
# ═══════════════════════════════════════════

func _draw_all() -> void:
	match _mode:
		Mode.BIFURCATION:
			_draw_bifurcation()
		Mode.SURFACE_3D:
			_draw_surface_3d()
		Mode.SPIRAL:
			_draw_spiral()


func _draw_bifurcation() -> void:
	_pattern_im.clear_surfaces()
	_grid_im.clear_surfaces()
	_marker_im.clear_surfaces()
	_info_im.clear_surfaces()

	var im := _pattern_im
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_size := 0.8 / float(_bif_grid_size)
	var offset := Vector3(-0.4, -0.4, 0)

	for row in range(_bif_grid_size):
		for col in range(_bif_grid_size):
			var idx := row * _bif_grid_size + col
			var val := _bif_results[idx]
			var col_color: Color
			if val < 0.0:
				col_color = COL_BG  # not yet computed
			elif val < 0.5:
				col_color = COL_DEAD
			elif val < 1.5:
				col_color = COL_WAVES
			elif val < 2.5:
				col_color = COL_SPOTS
			elif val < 3.5:
				col_color = COL_STRIPES
			else:
				col_color = COL_CHAOS

			var x0 := offset.x + col * cell_size
			var y0 := offset.y + row * cell_size
			var a := Vector3(x0, y0, 0)
			var b := Vector3(x0 + cell_size, y0, 0)
			var c := Vector3(x0 + cell_size, y0 + cell_size, 0)
			var d := Vector3(x0, y0 + cell_size, 0)
			_add_quad(im, col_color, a, b, c, d)

	im.surface_end()

	# Draw current parameter marker
	var marker := _marker_im
	marker.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var f_norm := clampf((feed_rate - _bif_f_min) / (_bif_f_max - _bif_f_min), 0.0, 1.0)
	var k_norm := clampf((kill_rate - _bif_k_min) / (_bif_k_max - _bif_k_min), 0.0, 1.0)
	var mx := offset.x + f_norm * 0.8
	var my := offset.y + k_norm * 0.8
	var ms := 0.02
	_add_quad(marker, COL_MARKER,
		Vector3(mx - ms, my - ms, 0.01),
		Vector3(mx + ms, my - ms, 0.01),
		Vector3(mx + ms, my + ms, 0.01),
		Vector3(mx - ms, my + ms, 0.01))
	marker.surface_end()

	# Draw axes lines
	var gim := _grid_im
	gim.surface_begin(Mesh.PRIMITIVE_LINES)
	gim.surface_set_color(COL_GRID)
	# Bottom axis (feed rate)
	gim.surface_add_vertex(Vector3(-0.4, -0.42, 0))
	gim.surface_add_vertex(Vector3(0.4, -0.42, 0))
	# Left axis (kill rate)
	gim.surface_add_vertex(Vector3(-0.42, -0.4, 0))
	gim.surface_add_vertex(Vector3(-0.42, 0.4, 0))
	gim.surface_end()


func _draw_surface_3d() -> void:
	_pattern_im.clear_surfaces()
	_grid_im.clear_surfaces()
	_marker_im.clear_surfaces()
	_info_im.clear_surfaces()

	var im := _pattern_im
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var n_lat := _sphere_n_lat
	var n_lon := _sphere_n_lon
	var r := sphere_radius

	for lat in range(n_lat - 1):
		var theta0 := PI * float(lat) / float(n_lat - 1)
		var theta1 := PI * float(lat + 1) / float(n_lat - 1)
		for lon in range(n_lon):
			var phi0 := TAU * float(lon) / float(n_lon)
			var phi1 := TAU * float((lon + 1) % n_lon) / float(n_lon)

			# Sphere vertices
			var p00 := _sphere_pos(r, theta0, phi0)
			var p10 := _sphere_pos(r, theta0, phi1)
			var p01 := _sphere_pos(r, theta1, phi0)
			var p11 := _sphere_pos(r, theta1, phi1)

			# Get concentration for coloring
			var v00 := _sphere_v[lat * n_lon + lon]
			var v10 := _sphere_v[lat * n_lon + ((lon + 1) % n_lon)]
			var v01 := _sphere_v[(lat + 1) * n_lon + lon]
			var v11 := _sphere_v[(lat + 1) * n_lon + ((lon + 1) % n_lon)]

			var c00 := _rd_color(v00)
			var c10 := _rd_color(v10)
			var c01 := _rd_color(v01)
			var c11 := _rd_color(v11)

			# Displace vertices outward by v concentration for 3D effect
			var disp := 0.08
			p00 += p00.normalized() * v00 * disp
			p10 += p10.normalized() * v10 * disp
			p01 += p01.normalized() * v01 * disp
			p11 += p11.normalized() * v11 * disp

			# Triangle 1: p00, p10, p11
			var n0 := p00.normalized()
			im.surface_set_color(c00)
			im.surface_set_normal(n0)
			im.surface_add_vertex(p00)
			im.surface_set_color(c10)
			im.surface_set_normal(p10.normalized())
			im.surface_add_vertex(p10)
			im.surface_set_color(c11)
			im.surface_set_normal(p11.normalized())
			im.surface_add_vertex(p11)

			# Triangle 2: p00, p11, p01
			im.surface_set_color(c00)
			im.surface_set_normal(n0)
			im.surface_add_vertex(p00)
			im.surface_set_color(c11)
			im.surface_set_normal(p11.normalized())
			im.surface_add_vertex(p11)
			im.surface_set_color(c01)
			im.surface_set_normal(p01.normalized())
			im.surface_add_vertex(p01)

	im.surface_end()

	# Draw wireframe rings for reference
	var gim := _grid_im
	gim.surface_begin(Mesh.PRIMITIVE_LINES)
	gim.surface_set_color(Color(0.3, 0.3, 0.4, 0.3))
	# Equator
	for i in range(64):
		var a0 := TAU * float(i) / 64.0
		var a1 := TAU * float(i + 1) / 64.0
		gim.surface_add_vertex(Vector3(cos(a0) * r, 0, sin(a0) * r))
		gim.surface_add_vertex(Vector3(cos(a1) * r, 0, sin(a1) * r))
	# Prime meridian
	for i in range(64):
		var a0 := TAU * float(i) / 64.0
		var a1 := TAU * float(i + 1) / 64.0
		gim.surface_add_vertex(Vector3(cos(a0) * r, sin(a0) * r, 0))
		gim.surface_add_vertex(Vector3(cos(a1) * r, sin(a1) * r, 0))
	gim.surface_end()


func _draw_spiral() -> void:
	_pattern_im.clear_surfaces()
	_grid_im.clear_surfaces()
	_marker_im.clear_surfaces()
	_info_im.clear_surfaces()

	var im := _pattern_im
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var n := _spiral_size
	var cell := 0.9 / float(n)
	var offset := Vector3(-0.45, -0.45, 0)

	for y in range(n - 1):
		for x in range(n - 1):
			var idx := y * n + x
			var u_val := _spiral_u[idx]
			var v_val := _spiral_v[idx]
			var col := _spiral_color(u_val, v_val)

			var x0 := offset.x + x * cell
			var y0 := offset.y + y * cell
			# Height displacement based on excitation
			var z0 := u_val * 0.1
			var a := Vector3(x0, y0, z0)
			var b := Vector3(x0 + cell, y0, _spiral_u[idx + 1] * 0.1)
			var c := Vector3(x0 + cell, y0 + cell, _spiral_u[(y + 1) * n + x + 1] * 0.1)
			var d := Vector3(x0, y0 + cell, _spiral_u[(y + 1) * n + x] * 0.1)
			_add_quad(im, col, a, b, c, d)

	im.surface_end()

	# Draw spiral tip markers (where u ~ threshold and du/dx, du/dy are large)
	var marker := _marker_im
	marker.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip_count := 0
	for y in range(1, n - 1):
		for x in range(1, n - 1):
			var idx := y * n + x
			var uc := _spiral_u[idx]
			if uc > 0.3 and uc < 0.7:
				var grad_x := absf(_spiral_u[idx + 1] - _spiral_u[idx - 1])
				var grad_y := absf(_spiral_u[(y + 1) * n + x] - _spiral_u[(y - 1) * n + x])
				var grad_mag := grad_x + grad_y
				if grad_mag > 1.0 and tip_count < 12:
					var px := offset.x + x * cell + cell * 0.5
					var py := offset.y + y * cell + cell * 0.5
					var ms := cell * 1.5
					_add_quad(marker, COL_SPIRAL_TIP,
						Vector3(px - ms, py - ms, 0.12),
						Vector3(px + ms, py - ms, 0.12),
						Vector3(px + ms, py + ms, 0.12),
						Vector3(px - ms, py + ms, 0.12))
					tip_count += 1
	marker.surface_end()


# ─── Color helpers ───

func _rd_color(v_conc: float) -> Color:
	# Blue (low V) → green → yellow → red (high V)
	if v_conc < 0.25:
		return COL_U_HIGH.lerp(Color(0.1, 0.7, 0.5), v_conc * 4.0)
	elif v_conc < 0.5:
		return Color(0.1, 0.7, 0.5).lerp(COL_MIXED, (v_conc - 0.25) * 4.0)
	elif v_conc < 0.75:
		return COL_MIXED.lerp(COL_V_HIGH, (v_conc - 0.5) * 4.0)
	else:
		return COL_V_HIGH


func _spiral_color(u_val: float, v_val: float) -> Color:
	# Excited (u high) = bright cyan, recovering (v high) = purple, rest = dark
	var base := COL_BG
	if u_val > 0.5:
		base = Color(0.1, 0.9, 0.95).lerp(Color(1.0, 1.0, 0.3), clampf(u_val - 0.5, 0.0, 0.5) * 2.0)
	elif v_val > 0.1:
		base = Color(0.4, 0.15, 0.7).lerp(Color(0.1, 0.1, 0.2), clampf(v_val, 0.0, 1.0))
	return base


func _bif_class_name(val: float) -> String:
	if val < 0.5:
		return "Uniform"
	elif val < 1.5:
		return "Waves"
	elif val < 2.5:
		return "Spots"
	elif val < 3.5:
		return "Stripes"
	else:
		return "Chaotic"


# ─── Geometry helpers ───

func _sphere_pos(r: float, theta: float, phi: float) -> Vector3:
	return Vector3(
		r * sin(theta) * cos(phi),
		r * cos(theta),
		r * sin(theta) * sin(phi)
	)


func _add_quad(im: ImmediateMesh, col: Color, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(b)
	im.surface_set_color(col)
	im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(d)


func _remap(val: float, from_min: float, from_max: float, to_min: float, to_max: float) -> float:
	return to_min + (val - from_min) / (from_max - from_min) * (to_max - to_min)


# ─── Labels ───

func _update_labels() -> void:
	match _mode:
		Mode.BIFURCATION:
			_label_title.text = "Gray-Scott Bifurcation"
			var pct := 0.0
			if _bif_grid_size > 0:
				pct = float(_bif_sweep_row * _bif_grid_size + _bif_sweep_col) / float(_bif_grid_size * _bif_grid_size) * 100.0
			if _bif_computed:
				pct = 100.0
			_label_info.text = "f=%.4f  k=%.4f  sweep: %.0f%%" % [feed_rate, kill_rate, pct]
			_label_legend.text = "Legend:\n  Uniform\n  Waves\n  Spots\n  Stripes\n  Chaotic"
			_label_legend.position = Vector3(0.55, 0.2, 0)
		Mode.SURFACE_3D:
			_label_title.text = "3D Surface RD"
			_label_info.text = "f=%.4f  k=%.4f  steps=%d" % [feed_rate, kill_rate, _steps_done]
			_label_legend.text = "Gray-Scott on sphere\nDu=%.3f Dv=%.3f" % [diffusion_u, diffusion_v]
			_label_legend.position = Vector3(0.55, 0.2, 0)
		Mode.SPIRAL:
			_label_title.text = "Spiral Waves"
			_label_info.text = "Barkley model  a=%.2f b=%.2f ε=%.3f  steps=%d" % [_spiral_a, _spiral_b, _spiral_eps, _steps_done]
			_label_legend.text = "Cyan = excited\nPurple = recovery\nPink = spiral tips"
			_label_legend.position = Vector3(0.55, 0.2, 0)


# ─── apply_grid_config ───

func apply_grid_config(config: Dictionary) -> void:
	if config.has("feed_rate"):
		feed_rate = clampf(float(config["feed_rate"]), 0.001, 0.1)
	if config.has("kill_rate"):
		kill_rate = clampf(float(config["kill_rate"]), 0.001, 0.1)
	if config.has("diffusion_u"):
		diffusion_u = clampf(float(config["diffusion_u"]), 0.01, 1.0)
	if config.has("diffusion_v"):
		diffusion_v = clampf(float(config["diffusion_v"]), 0.01, 1.0)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 5.0)
	if config.has("sphere_radius"):
		sphere_radius = clampf(float(config["sphere_radius"]), 0.1, 1.0)
	if config.has("grid_size"):
		grid_size = clampi(int(config["grid_size"]), 16, 96)
	if config.has("spiral_a"):
		_spiral_a = clampf(float(config["spiral_a"]), 0.3, 1.5)
	if config.has("spiral_b"):
		_spiral_b = clampf(float(config["spiral_b"]), 0.01, 0.2)
	if config.has("spiral_eps"):
		_spiral_eps = clampf(float(config["spiral_eps"]), 0.01, 0.3)
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"BIFURCATION": _mode = Mode.BIFURCATION
			"SURFACE_3D", "SURFACE": _mode = Mode.SURFACE_3D
			"SPIRAL": _mode = Mode.SPIRAL
	_init_mode()
	# Update slider visuals
	if _slider_feed:
		_slider_feed.set_normalized_value(_remap(feed_rate, 0.01, 0.08, 0.0, 1.0))
	if _slider_kill:
		_slider_kill.set_normalized_value(_remap(kill_rate, 0.03, 0.07, 0.0, 1.0))
	if _slider_speed:
		_slider_speed.set_normalized_value(_remap(step_speed, 0.2, 3.0, 0.0, 1.0))


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
