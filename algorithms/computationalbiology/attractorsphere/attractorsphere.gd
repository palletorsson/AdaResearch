# ===========================================================================
# AttractorSphere — Reaction-Diffusion Surface Patterns
# Morphogenetic sphere with Turing patterns and growth simulation
# Elevated features:
#   - Reaction-diffusion (Gray-Scott) surface patterns
#   - Diffusion gradient computation and visualization
#   - Temporal growth phase simulation
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

extends Node3D

## Morphogenetic attractor sphere with reaction-diffusion surface patterns.
## Modes: ATTRACTOR shows grab-sphere vertex deformation;
## TURING runs Gray-Scott reaction-diffusion on the sphere surface;
## GROWTH shows temporal growth phases with gradient arrows.

# --- Configuration ---
@export var sphere_radius: float = 0.85
@export var sphere_rings := 128
@export var sphere_radial_segments := 192
@export var attractor_count: int = 8
@export var attractor_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
@export var blob_color: Color = Color(0.85, 0.6, 0.95, 0.9)
@export var attractor_distance: float = 1.35
@export var pull_strength: float = 1.2
@export var pull_radius: float = 0.35
@export var max_displace: float = 1.0
@export var step_speed: float = 1.0

# Gray-Scott parameters
@export var feed_rate: float = 0.055
@export var kill_rate: float = 0.062
@export var diffusion_u: float = 0.16
@export var diffusion_v: float = 0.08
@export var rd_grid_size: int = 48

const MAX_ATTRACTORS := 64

# --- Mode ---
enum Mode { ATTRACTOR, TURING, GROWTH }
var _mode: int = Mode.ATTRACTOR

# --- Growth phase ---
enum GrowthPhase { SEED, SPREADING, MATURE, EQUILIBRIUM }
var _growth_phase: int = GrowthPhase.SEED
var _growth_time: float = 0.0
const GROWTH_SEED_DUR := 2.0
const GROWTH_SPREAD_DUR := 6.0
const GROWTH_MATURE_DUR := 4.0

# --- Internal state ---
var _time: float = 0.0
var _rd_u: Array = []  # 2D grid of U concentrations
var _rd_v: Array = []  # 2D grid of V concentrations
var _rd_steps_per_frame: int = 4

# --- Attractor mode ---
var sphere_mesh_instance: MeshInstance3D
var shader_mat: ShaderMaterial
var attractors: Array[Node3D] = []

# --- ImmediateMesh rendering ---
var _pattern_im: ImmediateMesh
var _pattern_mi: MeshInstance3D
var _gradient_im: ImmediateMesh
var _gradient_mi: MeshInstance3D
var _ring_im: ImmediateMesh
var _ring_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _info_label: Label3D
var _phase_label: Label3D

# VR controls
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
var _mode_button: Node3D
var _feed_slider: Node3D
var _kill_slider: Node3D

# Colors
const COL_U_HIGH := Color(0.15, 0.4, 0.95, 0.85)
const COL_U_LOW := Color(0.05, 0.08, 0.2, 0.6)
const COL_V_HIGH := Color(1.0, 0.35, 0.55, 0.9)
const COL_V_LOW := Color(0.3, 0.08, 0.12, 0.5)
const COL_GRADIENT := Color(0.9, 1.0, 0.4, 0.7)
const COL_RING := Color(1.0, 1.0, 1.0, 0.15)
const COL_SEED := Color(0.2, 1.0, 0.5, 0.8)
const COL_SPREAD := Color(0.9, 0.7, 0.2, 0.8)
const COL_MATURE := Color(0.7, 0.3, 1.0, 0.8)
const COL_EQUIL := Color(0.4, 0.9, 0.95, 0.8)


func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_make_sphere()
	_make_shader()
	_spawn_attractors_fibonacci()
	_init_rd_grid()
	_init_mode()


func _process(delta: float) -> void:
	_time += delta * step_speed
	match _mode:
		Mode.ATTRACTOR:
			_push_attractor_positions_to_shader()
		Mode.TURING:
			for i in _rd_steps_per_frame:
				_step_gray_scott()
			_draw_rd_pattern()
		Mode.GROWTH:
			_advance_growth(delta * step_speed)
			for i in _rd_steps_per_frame:
				_step_gray_scott()
			_draw_rd_pattern()
			_draw_gradient_arrows()
	_update_labels()


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
	_pattern_im = ImmediateMesh.new()
	_pattern_mi = MeshInstance3D.new()
	_pattern_mi.mesh = _pattern_im
	_pattern_mi.material_override = _mat_alpha
	add_child(_pattern_mi)

	_gradient_im = ImmediateMesh.new()
	_gradient_mi = MeshInstance3D.new()
	_gradient_mi.mesh = _gradient_im
	_gradient_mi.material_override = _mat_alpha
	add_child(_gradient_mi)

	_ring_im = ImmediateMesh.new()
	_ring_mi = MeshInstance3D.new()
	_ring_mi.mesh = _ring_im
	_ring_mi.material_override = _mat_alpha
	add_child(_ring_mi)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, sphere_radius + 1.6, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 22
	_info_label.outline_size = 3
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, sphere_radius + 1.15, 0)
	_info_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_info_label)

	_phase_label = Label3D.new()
	_phase_label.font_size = 20
	_phase_label.outline_size = 3
	_phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_phase_label.position = Vector3(0, -sphere_radius - 0.8, 0)
	_phase_label.modulate = Color(0.7, 0.8, 1.0)
	add_child(_phase_label)


# =========================================================================
# VR controls
# =========================================================================

func _create_vr_controls() -> void:
	# Mode cycle button
	_mode_button = BUTTON_SCENE.instantiate()
	_mode_button.position = Vector3(-1.4, -sphere_radius - 0.4, 0)
	add_child(_mode_button)
	var btn_area = _mode_button.get_node_or_null("InteractableAreaButton")
	if btn_area:
		btn_area.button_pressed.connect(_cycle_mode)

	# Feed rate slider
	_feed_slider = SLIDER_SCENE.instantiate()
	_feed_slider.position = Vector3(1.2, -sphere_radius - 0.2, 0)
	add_child(_feed_slider)
	_feed_slider.set_param_name("Feed")
	_feed_slider.set_normalized_value(feed_rate / 0.1)
	_feed_slider.slider_moved.connect(_on_feed_changed)

	# Kill rate slider
	_kill_slider = SLIDER_SCENE.instantiate()
	_kill_slider.position = Vector3(1.2, -sphere_radius - 0.6, 0)
	add_child(_kill_slider)
	_kill_slider.set_param_name("Kill")
	_kill_slider.set_normalized_value(kill_rate / 0.1)
	_kill_slider.slider_moved.connect(_on_kill_changed)


func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()


func _on_feed_changed(_value: float) -> void:
	feed_rate = _feed_slider.get_normalized_value() * 0.1


func _on_kill_changed(_value: float) -> void:
	kill_rate = _kill_slider.get_normalized_value() * 0.1


func _init_mode() -> void:
	# Show/hide attractor-mode components
	var show_attractors := (_mode == Mode.ATTRACTOR)
	if sphere_mesh_instance:
		sphere_mesh_instance.visible = show_attractors
	for a in attractors:
		if is_instance_valid(a):
			a.visible = show_attractors

	_pattern_mi.visible = (_mode != Mode.ATTRACTOR)
	_gradient_mi.visible = (_mode == Mode.GROWTH)
	_ring_mi.visible = (_mode != Mode.ATTRACTOR)

	if _mode == Mode.GROWTH:
		_growth_phase = GrowthPhase.SEED
		_growth_time = 0.0
		_init_rd_grid()
		_seed_rd_center()
	elif _mode == Mode.TURING:
		_init_rd_grid()
		_seed_rd_random()


# =========================================================================
# Sphere setup (attractor mode)
# =========================================================================

func _make_sphere() -> void:
	sphere_mesh_instance = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = sphere_radius
	sm.height = sphere_radius * 2.0
	sm.is_hemisphere = false
	sm.rings = sphere_rings
	sm.radial_segments = sphere_radial_segments
	sphere_mesh_instance.mesh = sm
	add_child(sphere_mesh_instance)


func _make_shader() -> void:
	var shader_code := """
shader_type spatial;

uniform int u_count = 0;
uniform vec3 u_points[64];
uniform float u_strength = 0.9;
uniform float u_radius  = 0.55;
uniform float u_max_displace = 1.0;
uniform vec4 u_color : source_color = vec4(0.85, 0.6, 0.95, 0.79);

varying vec3 v_obj_pos;

void vertex() {
	vec3 pos = VERTEX;
	vec3 nrm = normalize(NORMAL);
	float disp = 0.0;

	for (int i = 0; i < u_count; i++) {
		float d = distance(pos, u_points[i]);
		float w = exp(-(d*d) / (2.0 * u_radius * u_radius));
		disp += u_strength * w;
	}

	VERTEX   = pos + nrm * clamp(disp, -u_max_displace, u_max_displace);
	v_obj_pos = VERTEX;
}

void fragment() {
	vec3 dx = dFdx(v_obj_pos);
	vec3 dy = dFdy(v_obj_pos);
	vec3 n_obj = normalize(cross(dx, dy));
	NORMAL = n_obj;

	ALBEDO = u_color.rgb;
	ALPHA  = u_color.a;
}
	"""

	var shader := Shader.new()
	shader.code = shader_code
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	sphere_mesh_instance.material_override = shader_mat
	_update_shader_static_params()


func _update_shader_static_params() -> void:
	shader_mat.set_shader_parameter("u_strength", pull_strength)
	shader_mat.set_shader_parameter("u_radius", pull_radius)
	shader_mat.set_shader_parameter("u_max_displace", max_displace)
	shader_mat.set_shader_parameter("u_color", blob_color)


# =========================================================================
# Attractor spawning (Fibonacci lattice)
# =========================================================================

func _spawn_attractors_fibonacci() -> void:
	var n = min(attractor_count, MAX_ATTRACTORS)
	for i in range(n):
		var dir := _fibonacci_on_unit_sphere(i, n)
		var inst := attractor_scene.instantiate() as Node3D
		add_child(inst)
		inst.position = dir * (sphere_radius * attractor_distance)
		attractors.append(inst)


func _fibonacci_on_unit_sphere(i: int, n: int) -> Vector3:
	var ga := PI * (3.0 - sqrt(5.0))
	var y := 1.0 - (2.0 * float(i) + 1.0) / float(n)
	var r := sqrt(max(0.0, 1.0 - y * y))
	var theta := ga * float(i)
	var x := r * cos(theta)
	var z := r * sin(theta)
	return Vector3(x, y, z).normalized()


func _push_attractor_positions_to_shader() -> void:
	var local_positions := PackedVector3Array()
	var count = min(attractors.size(), MAX_ATTRACTORS)
	local_positions.resize(count)
	for i in range(count):
		local_positions[i] = sphere_mesh_instance.to_local(attractors[i].global_position)
	shader_mat.set_shader_parameter("u_count", count)
	shader_mat.set_shader_parameter("u_points", local_positions)


# =========================================================================
# Gray-Scott Reaction-Diffusion
# =========================================================================

func _init_rd_grid() -> void:
	var n := rd_grid_size
	_rd_u = []
	_rd_v = []
	_rd_u.resize(n)
	_rd_v.resize(n)
	for j in range(n):
		var row_u := PackedFloat32Array()
		var row_v := PackedFloat32Array()
		row_u.resize(n)
		row_v.resize(n)
		for i in range(n):
			row_u[i] = 1.0
			row_v[i] = 0.0
		_rd_u[j] = row_u
		_rd_v[j] = row_v


func _seed_rd_random() -> void:
	var n := rd_grid_size
	# Place 5-8 random seed spots
	var seed_count := randi_range(5, 8)
	for s in range(seed_count):
		var cx := randi_range(4, n - 5)
		var cy := randi_range(4, n - 5)
		var r := randi_range(2, 4)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var ix := (cx + dx) % n
				var iy := (cy + dy) % n
				if ix < 0: ix += n
				if iy < 0: iy += n
				if dx * dx + dy * dy <= r * r:
					_rd_u[iy][ix] = 0.5
					_rd_v[iy][ix] = 0.25


func _seed_rd_center() -> void:
	var n := rd_grid_size
	var cx := n / 2
	var cy := n / 2
	var r := 2
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var ix := cx + dx
			var iy := cy + dy
			if ix >= 0 and ix < n and iy >= 0 and iy < n:
				if dx * dx + dy * dy <= r * r:
					_rd_u[iy][ix] = 0.5
					_rd_v[iy][ix] = 0.25


func _step_gray_scott() -> void:
	var n := rd_grid_size
	var dt := 1.0
	var du := diffusion_u
	var dv := diffusion_v
	var f := feed_rate
	var k := kill_rate

	# Compute Laplacians and update in-place for speed
	var new_u := []
	var new_v := []
	new_u.resize(n)
	new_v.resize(n)

	for j in range(n):
		var nu := PackedFloat32Array()
		var nv := PackedFloat32Array()
		nu.resize(n)
		nv.resize(n)

		var jm := (j - 1) if j > 0 else (n - 1)
		var jp := (j + 1) if j < n - 1 else 0

		var u_row: PackedFloat32Array = _rd_u[j]
		var u_row_m: PackedFloat32Array = _rd_u[jm]
		var u_row_p: PackedFloat32Array = _rd_u[jp]
		var v_row: PackedFloat32Array = _rd_v[j]
		var v_row_m: PackedFloat32Array = _rd_v[jm]
		var v_row_p: PackedFloat32Array = _rd_v[jp]

		for i in range(n):
			var im := (i - 1) if i > 0 else (n - 1)
			var ip := (i + 1) if i < n - 1 else 0

			var u_c: float = u_row[i]
			var v_c: float = v_row[i]

			# 5-point Laplacian stencil
			var lap_u: float = u_row[im] + u_row[ip] + u_row_m[i] + u_row_p[i] - 4.0 * u_c
			var lap_v: float = v_row[im] + v_row[ip] + v_row_m[i] + v_row_p[i] - 4.0 * v_c

			var uvv: float = u_c * v_c * v_c
			nu[i] = clampf(u_c + dt * (du * lap_u - uvv + f * (1.0 - u_c)), 0.0, 1.0)
			nv[i] = clampf(v_c + dt * (dv * lap_v + uvv - (f + k) * v_c), 0.0, 1.0)

		new_u[j] = nu
		new_v[j] = nv

	_rd_u = new_u
	_rd_v = new_v


# =========================================================================
# Pattern drawing — colored patches on the sphere surface
# =========================================================================

func _draw_rd_pattern() -> void:
	_pattern_im.clear_surfaces()
	_ring_im.clear_surfaces()

	var n := rd_grid_size
	var r := sphere_radius + 0.01  # Slightly outside the sphere

	_pattern_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for j in range(n - 1):
		var theta0 := PI * float(j) / float(n - 1)
		var theta1 := PI * float(j + 1) / float(n - 1)
		var st0 := sin(theta0)
		var ct0 := cos(theta0)
		var st1 := sin(theta1)
		var ct1 := cos(theta1)

		for i in range(n):
			var i1 := (i + 1) % n
			var phi0 := TAU * float(i) / float(n)
			var phi1 := TAU * float(i1) / float(n)

			# Concentration at corners
			var v00: float = _rd_v[j][i]
			var v10: float = _rd_v[j][i1]
			var v01: float = _rd_v[j + 1][i]
			var v11: float = _rd_v[j + 1][i1]

			# Sphere positions
			var p00 := Vector3(st0 * cos(phi0), ct0, st0 * sin(phi0)) * r
			var p10 := Vector3(st0 * cos(phi1), ct0, st0 * sin(phi1)) * r
			var p01 := Vector3(st1 * cos(phi0), ct1, st1 * sin(phi0)) * r
			var p11 := Vector3(st1 * cos(phi1), ct1, st1 * sin(phi1)) * r

			var c00 := _rd_color(v00)
			var c10 := _rd_color(v10)
			var c01 := _rd_color(v01)
			var c11 := _rd_color(v11)

			# Triangle 1: p00, p10, p01
			_pattern_im.surface_set_color(c00)
			_pattern_im.surface_add_vertex(p00)
			_pattern_im.surface_set_color(c10)
			_pattern_im.surface_add_vertex(p10)
			_pattern_im.surface_set_color(c01)
			_pattern_im.surface_add_vertex(p01)

			# Triangle 2: p10, p11, p01
			_pattern_im.surface_set_color(c10)
			_pattern_im.surface_add_vertex(p10)
			_pattern_im.surface_set_color(c11)
			_pattern_im.surface_add_vertex(p11)
			_pattern_im.surface_set_color(c01)
			_pattern_im.surface_add_vertex(p01)

	_pattern_im.surface_end()

	# Latitude rings for orientation
	_ring_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var ring_r := sphere_radius + 0.02
	for ring_idx in [1, 2, 3]:
		var theta := PI * float(ring_idx) / 4.0
		var st := sin(theta)
		var ct := cos(theta)
		var segs := 48
		for s in range(segs):
			var phi0 := TAU * float(s) / float(segs)
			var phi1 := TAU * float(s + 1) / float(segs)
			_ring_im.surface_set_color(COL_RING)
			_ring_im.surface_add_vertex(Vector3(st * cos(phi0), ct, st * sin(phi0)) * ring_r)
			_ring_im.surface_add_vertex(Vector3(st * cos(phi1), ct, st * sin(phi1)) * ring_r)
	_ring_im.surface_end()


func _rd_color(v_conc: float) -> Color:
	# Lerp between low-V (substrate color) and high-V (activator color)
	var t := clampf(v_conc * 4.0, 0.0, 1.0)
	return COL_U_LOW.lerp(COL_V_HIGH, t)


# =========================================================================
# Gradient arrows — show diffusion direction on sphere surface
# =========================================================================

func _draw_gradient_arrows() -> void:
	_gradient_im.clear_surfaces()
	_gradient_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var n := rd_grid_size
	var r := sphere_radius + 0.04
	var arrow_step := maxi(n / 12, 2)

	var j := arrow_step
	while j < n - 1:
		var i := arrow_step
		while i < n:
			# Gradient of V via central differences
			var im := (i - 1) if i > 0 else (n - 1)
			var ip := (i + 1) if i < n - 1 else 0
			var jm := (j - 1) if j > 0 else (n - 1)
			var jp := (j + 1) if j < n - 1 else 0

			var dv_di: float = (_rd_v[j][ip] - _rd_v[j][im]) * 0.5
			var dv_dj: float = (_rd_v[jp][i] - _rd_v[jm][i]) * 0.5
			var grad_mag := sqrt(dv_di * dv_di + dv_dj * dv_dj)

			if grad_mag > 0.01:
				var theta := PI * float(j) / float(n - 1)
				var phi := TAU * float(i) / float(n)
				var st := sin(theta)
				var ct := cos(theta)

				var pos := Vector3(st * cos(phi), ct, st * sin(phi)) * r

				# Tangent vectors on the sphere
				var t_theta := Vector3(ct * cos(phi), -st, ct * sin(phi))
				var t_phi := Vector3(-st * sin(phi), 0, st * cos(phi))

				var grad_dir := (t_phi * dv_di + t_theta * dv_dj).normalized()
				var arrow_len := clampf(grad_mag * 2.0, 0.03, 0.15)

				var tip := pos + grad_dir * arrow_len
				var alpha := clampf(grad_mag * 8.0, 0.2, 0.8)
				var col := Color(COL_GRADIENT.r, COL_GRADIENT.g, COL_GRADIENT.b, alpha)

				_gradient_im.surface_set_color(col)
				_gradient_im.surface_add_vertex(pos)
				_gradient_im.surface_add_vertex(tip)

				# Arrowhead as two short barbs
				var perp := grad_dir.cross(pos.normalized()).normalized()
				var back := pos + grad_dir * arrow_len * 0.6
				var barb_len := arrow_len * 0.3
				_gradient_im.surface_set_color(col)
				_gradient_im.surface_add_vertex(tip)
				_gradient_im.surface_add_vertex(back + perp * barb_len)
				_gradient_im.surface_set_color(col)
				_gradient_im.surface_add_vertex(tip)
				_gradient_im.surface_add_vertex(back - perp * barb_len)

			i += arrow_step
		j += arrow_step

	_gradient_im.surface_end()


# =========================================================================
# Growth phase simulation
# =========================================================================

func _advance_growth(delta: float) -> void:
	_growth_time += delta
	match _growth_phase:
		GrowthPhase.SEED:
			if _growth_time >= GROWTH_SEED_DUR:
				_growth_phase = GrowthPhase.SPREADING
				_growth_time = 0.0
				# Add more seeds around the initial one
				_seed_rd_spread_ring()
		GrowthPhase.SPREADING:
			if _growth_time >= GROWTH_SPREAD_DUR:
				_growth_phase = GrowthPhase.MATURE
				_growth_time = 0.0
		GrowthPhase.MATURE:
			if _growth_time >= GROWTH_MATURE_DUR:
				_growth_phase = GrowthPhase.EQUILIBRIUM
				_growth_time = 0.0
		GrowthPhase.EQUILIBRIUM:
			# Stable — simulation continues but patterns are established
			pass


func _seed_rd_spread_ring() -> void:
	var n := rd_grid_size
	var cx := n / 2
	var cy := n / 2
	# Ring of seeds at distance ~8 from center
	var ring_r := 8
	var count := 6
	for s in range(count):
		var angle := TAU * float(s) / float(count)
		var sx := cx + int(ring_r * cos(angle))
		var sy := cy + int(ring_r * sin(angle))
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var ix := (sx + dx) % n
				var iy := (sy + dy) % n
				if ix < 0: ix += n
				if iy < 0: iy += n
				if dx * dx + dy * dy <= 4:
					_rd_u[iy][ix] = 0.5
					_rd_v[iy][ix] = 0.25


# =========================================================================
# Label updates
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["Attractor", "Turing Patterns", "Growth Simulation"]
	_title_label.text = "Attractor Sphere — %s" % mode_names[_mode]

	match _mode:
		Mode.ATTRACTOR:
			_info_label.text = "%d attractors  |  strength %.1f" % [attractors.size(), pull_strength]
			_phase_label.text = "Grab spheres deform the surface"
		Mode.TURING:
			_info_label.text = "Gray-Scott  |  F=%.3f  K=%.3f  |  %dx%d" % [feed_rate, kill_rate, rd_grid_size, rd_grid_size]
			_phase_label.text = "Reaction-diffusion on sphere surface"
		Mode.GROWTH:
			var phase_names := ["Seeding", "Spreading", "Maturing", "Equilibrium"]
			var phase_cols := [COL_SEED, COL_SPREAD, COL_MATURE, COL_EQUIL]
			_info_label.text = "Gray-Scott  |  F=%.3f  K=%.3f  |  Phase: %s" % [feed_rate, kill_rate, phase_names[_growth_phase]]
			_phase_label.text = "Growth: %s (%.1fs)" % [phase_names[_growth_phase], _growth_time]
			_phase_label.modulate = phase_cols[_growth_phase]


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("sphere_radius"):
		sphere_radius = clampf(float(config["sphere_radius"]), 0.3, 2.0)
	if config.has("attractor_count"):
		attractor_count = clampi(int(config["attractor_count"]), 2, MAX_ATTRACTORS)
	if config.has("pull_strength"):
		pull_strength = clampf(float(config["pull_strength"]), 0.1, 3.0)
	if config.has("pull_radius"):
		pull_radius = clampf(float(config["pull_radius"]), 0.05, 1.0)
	if config.has("max_displace"):
		max_displace = clampf(float(config["max_displace"]), 0.1, 2.0)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 5.0)
	if config.has("feed_rate"):
		feed_rate = clampf(float(config["feed_rate"]), 0.01, 0.1)
	if config.has("kill_rate"):
		kill_rate = clampf(float(config["kill_rate"]), 0.01, 0.1)
	if config.has("diffusion_u"):
		diffusion_u = clampf(float(config["diffusion_u"]), 0.01, 0.5)
	if config.has("diffusion_v"):
		diffusion_v = clampf(float(config["diffusion_v"]), 0.01, 0.5)
	if config.has("rd_grid_size"):
		rd_grid_size = clampi(int(config["rd_grid_size"]), 16, 80)
	if config.has("blob_color"):
		if config["blob_color"] is Color:
			blob_color = config["blob_color"]
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"ATTRACTOR": _mode = Mode.ATTRACTOR
			"TURING": _mode = Mode.TURING
			"GROWTH": _mode = Mode.GROWTH

	# Apply shader params if in attractor mode
	if shader_mat:
		_update_shader_static_params()

	# Re-init attractors if count changed
	if _mode == Mode.ATTRACTOR and attractors.size() != attractor_count:
		for a in attractors:
			if is_instance_valid(a):
				a.queue_free()
		attractors.clear()
		_spawn_attractors_fibonacci()

	# Re-init RD grid if size changed
	if _mode != Mode.ATTRACTOR:
		_init_rd_grid()
		if _mode == Mode.TURING:
			_seed_rd_random()
		elif _mode == Mode.GROWTH:
			_seed_rd_center()

	_init_mode()


# =========================================================================
# Cleanup
# =========================================================================

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
