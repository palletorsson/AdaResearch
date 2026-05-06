# ===========================================================================
# NOC Example 3.8: Static Wave — Elevated
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated features:
#   - Wave superposition: two independent waves combine in real time
#   - Constructive/destructive interference with color-coded regions
#   - 2D wave equation grid (finite difference PDE with boundary reflection)
#   - Boundary reflection visualization with damping
#   - Full apply_grid_config() integration with VR slider controls
#
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

var RackTpl = load("res://commons/audio/rack_templates/RackTemplates.gd")

# --- Configurable parameters ---
@export var wavelength_a: float = 0.12
@export var wavelength_b: float = 0.18
@export var amplitude_a: float = 0.08
@export var amplitude_b: float = 0.06
@export var wave_speed: float = 0.3
@export var damping: float = 0.003
@export var grid_res: int = 40
@export var membrane_size: float = 0.55

# --- Internal state ---
var _time: float = 0.0

# 2D wave equation state (finite difference)
var _u: PackedFloat32Array        # current displacement
var _u_prev: PackedFloat32Array   # previous timestep
var _dx: float = 0.0
var _dt: float = 1.0 / 60.0
var _courant: float = 0.0

# Scene nodes
var _sim_root: Node3D
var _wave_1d_mesh: MeshInstance3D
var _wave_a_mesh: MeshInstance3D
var _wave_b_mesh: MeshInstance3D
var _interference_mesh: MeshInstance3D
var _membrane_mesh: MeshInstance3D
var _boundary_mesh: MeshInstance3D
var _title_label: Label3D
var _status_label: Label3D
var _mode_label: Label3D
var _control_panel: Node3D

# Materials
var _mat_unshaded: StandardMaterial3D

# Colors
const COL_WAVE_A := Color(0.3, 0.65, 1.0)
const COL_WAVE_B := Color(1.0, 0.5, 0.3)
const COL_SUPER := Color(0.95, 0.9, 0.5)
const COL_CONSTRUCTIVE := Color(0.2, 1.0, 0.4)
const COL_DESTRUCTIVE := Color(1.0, 0.15, 0.25)
const COL_MEMBRANE_POS := Color(0.15, 0.4, 1.0)
const COL_MEMBRANE_NEG := Color(1.0, 0.2, 0.15)
const COL_MEMBRANE_ZERO := Color(0.06, 0.06, 0.12)

# Layout
const WAVE_1D_Y := 0.62
const MEMBRANE_OFFSET := Vector3(0, 0.15, -0.35)
const HEIGHT_SCALE := 0.12


func _ready() -> void:
	_create_materials()
	_setup_scene()
	_setup_labels()
	_setup_vr_controls()
	_init_membrane()
	call_deferred("_apply_standard_presentation")
	set_process(true)


func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED


func _setup_scene() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	# 1D wave meshes: individual waves + superposition
	_wave_a_mesh = MeshInstance3D.new()
	_wave_a_mesh.material_override = _mat_unshaded
	_wave_a_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_wave_a_mesh)

	_wave_b_mesh = MeshInstance3D.new()
	_wave_b_mesh.material_override = _mat_unshaded
	_wave_b_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_wave_b_mesh)

	_wave_1d_mesh = MeshInstance3D.new()
	_wave_1d_mesh.material_override = _mat_unshaded
	_wave_1d_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_wave_1d_mesh)

	# Interference region coloring
	_interference_mesh = MeshInstance3D.new()
	_interference_mesh.material_override = _mat_unshaded
	_interference_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_interference_mesh)

	# 2D membrane
	_membrane_mesh = MeshInstance3D.new()
	_membrane_mesh.material_override = _mat_unshaded
	_membrane_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_membrane_mesh)

	# Boundary frame for membrane
	_boundary_mesh = MeshInstance3D.new()
	_boundary_mesh.material_override = _mat_unshaded
	_boundary_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_boundary_mesh)


func _setup_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "WAVE SUPERPOSITION"
	_title_label.font_size = 20
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, WAVE_1D_Y + 0.18, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.95, 0.85, 0.7)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sim_root.add_child(_title_label)

	_status_label = Label3D.new()
	_status_label.font_size = 14
	_status_label.pixel_size = 0.001
	_status_label.position = Vector3(0, WAVE_1D_Y + 0.12, 0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.modulate = Color(0.85, 0.85, 0.9)
	_status_label.outline_size = 3
	_status_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sim_root.add_child(_status_label)

	_mode_label = Label3D.new()
	_mode_label.font_size = 12
	_mode_label.pixel_size = 0.001
	_mode_label.position = MEMBRANE_OFFSET + Vector3(0, membrane_size * 0.5 + 0.06, 0)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.modulate = Color(0.75, 0.85, 0.95)
	_mode_label.outline_size = 3
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sim_root.add_child(_mode_label)


func _setup_vr_controls() -> void:
	_control_panel = RackTpl.create_panel("WAVE CONTROLS", [
		[{"type": "slider_h", "label": "λ WAVE A", "default": (wavelength_a - 0.04) / 0.36}],
		[{"type": "slider_h", "label": "λ WAVE B", "default": (wavelength_b - 0.04) / 0.36}],
		[{"type": "slider_h", "label": "SPEED", "default": wave_speed / 0.8}],
		[{"type": "slider_h", "label": "DAMPING", "default": damping / 0.02}],
		[{"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0.48, 0.35, 0.18)
	_control_panel.rotation_degrees = Vector3(-20, -25, 0)
	add_child(_control_panel)

	var wl_a_slider = _control_panel.find_child("Param_0", true, false)
	if wl_a_slider and wl_a_slider.has_signal("slider_moved"):
		wl_a_slider.slider_moved.connect(func(_n: String) -> void:
			wavelength_a = 0.04 + wl_a_slider.get_normalized_value() * 0.36
		)

	var wl_b_slider = _control_panel.find_child("Param_1", true, false)
	if wl_b_slider and wl_b_slider.has_signal("slider_moved"):
		wl_b_slider.slider_moved.connect(func(_n: String) -> void:
			wavelength_b = 0.04 + wl_b_slider.get_normalized_value() * 0.36
		)

	var speed_slider = _control_panel.find_child("Param_2", true, false)
	if speed_slider and speed_slider.has_signal("slider_moved"):
		speed_slider.slider_moved.connect(func(_n: String) -> void:
			wave_speed = speed_slider.get_normalized_value() * 0.8
		)

	var damp_slider = _control_panel.find_child("Param_3", true, false)
	if damp_slider and damp_slider.has_signal("slider_moved"):
		damp_slider.slider_moved.connect(func(_n: String) -> void:
			damping = damp_slider.get_normalized_value() * 0.02
		)

	var reset_btn = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b: bool) -> void: _reset_all())


# ---- 2D Wave Equation (finite difference PDE) ----

func _init_membrane() -> void:
	var n := grid_res
	var total := n * n
	_u = PackedFloat32Array()
	_u.resize(total)
	_u_prev = PackedFloat32Array()
	_u_prev.resize(total)
	_dx = membrane_size / float(n - 1)

	# Gaussian pulse at center
	var cx := n / 2
	var cy := n / 2
	var sigma := 3.0
	for row in range(n):
		for col in range(n):
			var dist_sq := float((row - cy) * (row - cy) + (col - cx) * (col - cx))
			var val := exp(-dist_sq / (2.0 * sigma * sigma))
			_u[row * n + col] = val
			_u_prev[row * n + col] = val

	_courant = wave_speed * _dt / _dx


func _step_membrane() -> void:
	var n := grid_res
	_courant = wave_speed * _dt / _dx
	# Clamp courant for stability: c*dt/dx < 1/sqrt(2)
	var c2 := minf(_courant * _courant, 0.45)
	var damp_factor := 1.0 / (1.0 + damping)

	var u_next := PackedFloat32Array()
	u_next.resize(n * n)

	for row in range(1, n - 1):
		for col in range(1, n - 1):
			var idx := row * n + col
			var laplacian := (
				_u[idx - 1] + _u[idx + 1] +
				_u[idx - n] + _u[idx + n] -
				4.0 * _u[idx]
			)
			u_next[idx] = damp_factor * (2.0 * _u[idx] - _u_prev[idx] + c2 * laplacian)

	# Fixed boundary (u = 0 at edges) — reflection happens naturally
	_u_prev = _u
	_u = u_next


func _reset_all() -> void:
	_time = 0.0
	_init_membrane()


# ---- Process ----

func _process(delta: float) -> void:
	_time += delta

	# Step 2D PDE
	_step_membrane()

	# Draw everything
	_draw_1d_waves()
	_draw_interference_fill()
	_draw_membrane()
	_draw_boundary_frame()
	_update_labels()


# ---- 1D Wave Superposition ----

func _eval_wave_a(x: float) -> float:
	var k := TAU / maxf(wavelength_a, 0.01)
	var omega := k * wave_speed
	return amplitude_a * sin(k * x - omega * _time)


func _eval_wave_b(x: float) -> float:
	var k := TAU / maxf(wavelength_b, 0.01)
	var omega := k * wave_speed
	return amplitude_b * sin(k * x + omega * _time)  # traveling opposite direction


func _draw_1d_waves() -> void:
	var im_a := ImmediateMesh.new()
	var im_b := ImmediateMesh.new()
	var im_super := ImmediateMesh.new()

	var num_pts := 120
	var x_min := -0.4
	var x_max := 0.4

	# Wave A (blue, traveling right)
	im_a.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(num_pts):
		var x := lerpf(x_min, x_max, float(i) / (num_pts - 1))
		var y := _eval_wave_a(x)
		im_a.surface_set_color(Color(COL_WAVE_A, 0.6))
		im_a.surface_add_vertex(Vector3(x, WAVE_1D_Y + y, 0))
	im_a.surface_end()

	# Wave B (orange, traveling left)
	im_b.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(num_pts):
		var x := lerpf(x_min, x_max, float(i) / (num_pts - 1))
		var y := _eval_wave_b(x)
		im_b.surface_set_color(Color(COL_WAVE_B, 0.6))
		im_b.surface_add_vertex(Vector3(x, WAVE_1D_Y + y, 0))
	im_b.surface_end()

	# Superposition (bright yellow, thick via dual lines)
	im_super.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(num_pts):
		var x := lerpf(x_min, x_max, float(i) / (num_pts - 1))
		var y := _eval_wave_a(x) + _eval_wave_b(x)
		var ratio := absf(y) / maxf(amplitude_a + amplitude_b, 0.001)
		var col := COL_CONSTRUCTIVE.lerp(COL_DESTRUCTIVE, 1.0 - ratio)
		col.a = 0.95
		im_super.surface_set_color(col)
		im_super.surface_add_vertex(Vector3(x, WAVE_1D_Y + y, 0.005))
	im_super.surface_end()

	_wave_a_mesh.mesh = im_a
	_wave_b_mesh.mesh = im_b
	_wave_1d_mesh.mesh = im_super


func _draw_interference_fill() -> void:
	# Shaded vertical bars showing constructive (green) / destructive (red) regions
	var im := ImmediateMesh.new()
	var num_bars := 60
	var x_min := -0.4
	var x_max := 0.4
	var bar_w := (x_max - x_min) / num_bars

	for i in range(num_bars):
		var x := lerpf(x_min, x_max, (float(i) + 0.5) / num_bars)
		var ya := _eval_wave_a(x)
		var yb := _eval_wave_b(x)
		var y_sum := ya + yb
		var max_amp := amplitude_a + amplitude_b
		if max_amp < 0.001:
			continue

		# Interference metric: |sum| / max possible
		var interference := absf(y_sum) / max_amp
		var col: Color
		if absf(y_sum) > (absf(ya) + absf(yb)) * 0.5:
			col = Color(COL_CONSTRUCTIVE, interference * 0.2)
		else:
			col = Color(COL_DESTRUCTIVE, (1.0 - interference) * 0.15)

		var hw := bar_w * 0.4
		var base_y := WAVE_1D_Y
		var top_y := WAVE_1D_Y + y_sum

		if absf(top_y - base_y) < 0.001:
			continue

		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var p0 := Vector3(x - hw, base_y, -0.005)
		var p1 := Vector3(x + hw, base_y, -0.005)
		var p2 := Vector3(x + hw, top_y, -0.005)
		var p3 := Vector3(x - hw, top_y, -0.005)
		im.surface_set_color(col)
		im.surface_add_vertex(p0)
		im.surface_set_color(col)
		im.surface_add_vertex(p1)
		im.surface_set_color(col)
		im.surface_add_vertex(p2)
		im.surface_set_color(col)
		im.surface_add_vertex(p0)
		im.surface_set_color(col)
		im.surface_add_vertex(p2)
		im.surface_set_color(col)
		im.surface_add_vertex(p3)
		im.surface_end()

	_interference_mesh.mesh = im


# ---- 2D Membrane Visualization ----

func _draw_membrane() -> void:
	var im := ImmediateMesh.new()
	var n := grid_res
	var half := membrane_size * 0.5
	var max_u := 0.001

	# Find max displacement for normalization
	for idx in range(n * n):
		var abs_val := absf(_u[idx])
		if abs_val > max_u:
			max_u = abs_val

	# Draw as triangle grid
	for row in range(n - 1):
		for col in range(n - 1):
			var i00 := row * n + col
			var i10 := row * n + col + 1
			var i01 := (row + 1) * n + col
			var i11 := (row + 1) * n + col + 1

			var x0 := -half + col * _dx + MEMBRANE_OFFSET.x
			var x1 := x0 + _dx
			var z0 := -half + row * _dx + MEMBRANE_OFFSET.z
			var z1 := z0 + _dx

			var y00 := _u[i00] * HEIGHT_SCALE + MEMBRANE_OFFSET.y
			var y10 := _u[i10] * HEIGHT_SCALE + MEMBRANE_OFFSET.y
			var y01 := _u[i01] * HEIGHT_SCALE + MEMBRANE_OFFSET.y
			var y11 := _u[i11] * HEIGHT_SCALE + MEMBRANE_OFFSET.y

			var c00 := _displacement_color(_u[i00], max_u)
			var c10 := _displacement_color(_u[i10], max_u)
			var c01 := _displacement_color(_u[i01], max_u)
			var c11 := _displacement_color(_u[i11], max_u)

			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			# Triangle 1
			im.surface_set_color(c00)
			im.surface_add_vertex(Vector3(x0, y00, z0))
			im.surface_set_color(c10)
			im.surface_add_vertex(Vector3(x1, y10, z0))
			im.surface_set_color(c11)
			im.surface_add_vertex(Vector3(x1, y11, z1))
			# Triangle 2
			im.surface_set_color(c00)
			im.surface_add_vertex(Vector3(x0, y00, z0))
			im.surface_set_color(c11)
			im.surface_add_vertex(Vector3(x1, y11, z1))
			im.surface_set_color(c01)
			im.surface_add_vertex(Vector3(x0, y01, z1))
			im.surface_end()

	_membrane_mesh.mesh = im


func _displacement_color(val: float, max_val: float) -> Color:
	var norm := clampf(val / maxf(max_val, 0.001), -1.0, 1.0)
	if norm >= 0.0:
		return COL_MEMBRANE_ZERO.lerp(COL_MEMBRANE_POS, norm)
	else:
		return COL_MEMBRANE_ZERO.lerp(COL_MEMBRANE_NEG, -norm)


func _draw_boundary_frame() -> void:
	# Draw clamped boundary frame around membrane
	var im := ImmediateMesh.new()
	var half := membrane_size * 0.5
	var y := MEMBRANE_OFFSET.y
	var col := Color(0.4, 0.5, 0.6, 0.5)

	var corners := [
		Vector3(-half + MEMBRANE_OFFSET.x, y, -half + MEMBRANE_OFFSET.z),
		Vector3(half + MEMBRANE_OFFSET.x, y, -half + MEMBRANE_OFFSET.z),
		Vector3(half + MEMBRANE_OFFSET.x, y, half + MEMBRANE_OFFSET.z),
		Vector3(-half + MEMBRANE_OFFSET.x, y, half + MEMBRANE_OFFSET.z),
	]

	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for c in corners:
		im.surface_set_color(col)
		im.surface_add_vertex(c)
	im.surface_set_color(col)
	im.surface_add_vertex(corners[0])
	im.surface_end()

	# Draw "FIXED" labels at midpoints
	_boundary_mesh.mesh = im


func _update_labels() -> void:
	var freq_a := wave_speed / maxf(wavelength_a, 0.01)
	var freq_b := wave_speed / maxf(wavelength_b, 0.01)
	var ratio := wavelength_a / maxf(wavelength_b, 0.01)

	var pattern := "MIXED"
	if absf(ratio - 1.0) < 0.05:
		pattern = "STANDING WAVE"
	elif absf(ratio - roundf(ratio)) < 0.1 and ratio > 0.3:
		pattern = "HARMONIC"

	_status_label.text = "λA=%.2f  λB=%.2f  |  %s  |  c=%.2f" % [wavelength_a, wavelength_b, pattern, wave_speed]

	# Membrane info
	var max_u := 0.0
	for idx in range(grid_res * grid_res):
		if absf(_u[idx]) > max_u:
			max_u = absf(_u[idx])
	_mode_label.text = "2D WAVE  %dx%d  |  peak=%.3f  damp=%.4f" % [grid_res, grid_res, max_u, damping]


func _apply_standard_presentation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("wavelength_a"):
		wavelength_a = float(config_data["wavelength_a"])
	if config_data.has("wavelength") or config_data.has("wavelength_a"):
		wavelength_a = float(config_data.get("wavelength_a", config_data.get("wavelength", wavelength_a)))
	if config_data.has("wavelength_b"):
		wavelength_b = float(config_data["wavelength_b"])
	if config_data.has("amplitude_a"):
		amplitude_a = float(config_data["amplitude_a"])
	if config_data.has("amplitude") or config_data.has("amplitude_a"):
		amplitude_a = float(config_data.get("amplitude_a", config_data.get("amplitude", amplitude_a)))
	if config_data.has("amplitude_b"):
		amplitude_b = float(config_data["amplitude_b"])
	if config_data.has("wave_speed"):
		wave_speed = float(config_data["wave_speed"])
	if config_data.has("damping"):
		damping = float(config_data["damping"])
	if config_data.has("grid_res"):
		grid_res = int(config_data["grid_res"])
	if config_data.has("membrane_size"):
		membrane_size = float(config_data["membrane_size"])

	_reset_all()


