extends Node3D
class_name WaveEquationSolver

## 2D wave equation on a membrane — drum simulation with visible ripples.
## Finite difference PDE: u_tt = c²(u_xx + u_yy) with fixed boundary u=0
## and viscous damping. Starts with a Gaussian pulse that propagates and
## reflects off the clamped edges like a struck drumhead.

# --- Configuration ---

@export var membrane_size: float = 0.8
@export var grid_res: int = 48
@export var height_scale: float = 0.15
@export var wave_speed: float = 2.0
@export var damping: float = 0.002
@export var initial_amplitude: float = 1.0
@export var initial_sigma: float = 0.08

# --- Colors ---

var color_positive: Color = Color(0.15, 0.4, 1.0)    # Blue for positive displacement
var color_negative: Color = Color(1.0, 0.2, 0.15)     # Red for negative displacement
var color_zero: Color = Color(0.06, 0.06, 0.1)        # Dark for zero

# --- State ---

var _u: PackedFloat32Array          # Current displacement
var _u_prev: PackedFloat32Array     # Previous timestep
var _time: float = 0.0
var _dx: float = 0.0
var _dt: float = 1.0 / 60.0        # Fixed physics timestep
var _courant: float = 0.0          # c*dt/dx — must stay < 1/sqrt(2) for stability
var _max_displacement: float = 0.0

# --- Nodes ---

var _surface_mesh: MeshInstance3D
var _surface_mat: StandardMaterial3D
var _frame_node: Node3D
var _title_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D
var _damping_slider: Node
var _speed_slider: Node

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


func _ready() -> void:
	_dx = membrane_size / float(grid_res - 1)
	_init_grids()
	_apply_gaussian_pulse(0.5, 0.5, initial_amplitude, initial_sigma)
	_create_frame()
	_create_surface()
	_create_labels()
	_create_vr_controls()
	_update_courant()


# --- Grid initialisation ---

func _init_grids() -> void:
	var count: int = grid_res * grid_res
	_u = PackedFloat32Array()
	_u.resize(count)
	_u_prev = PackedFloat32Array()
	_u_prev.resize(count)
	for k in range(count):
		_u[k] = 0.0
		_u_prev[k] = 0.0


func _apply_gaussian_pulse(cx: float, cy: float, amp: float, sigma: float) -> void:
	for j in range(grid_res):
		for i in range(grid_res):
			var nx: float = float(i) / float(grid_res - 1)
			var ny: float = float(j) / float(grid_res - 1)
			var dx_val: float = nx - cx
			var dy_val: float = ny - cy
			var r2: float = dx_val * dx_val + dy_val * dy_val
			var val: float = amp * exp(-r2 / (2.0 * sigma * sigma))
			var idx: int = j * grid_res + i
			_u[idx] = val
			_u_prev[idx] = val  # Zero initial velocity


# --- Wave equation integration (finite differences) ---

func _step_wave() -> void:
	var c2: float = wave_speed * wave_speed
	var dt2: float = _dt * _dt
	var dx2: float = _dx * _dx
	var factor: float = c2 * dt2 / dx2
	var damp: float = 1.0 - damping

	var u_new: PackedFloat32Array = PackedFloat32Array()
	u_new.resize(grid_res * grid_res)

	# Interior points — fixed boundary means edge stays 0
	for j in range(1, grid_res - 1):
		for i in range(1, grid_res - 1):
			var idx: int = j * grid_res + i
			var laplacian: float = (
				_u[idx + 1] + _u[idx - 1]
				+ _u[idx + grid_res] + _u[idx - grid_res]
				- 4.0 * _u[idx]
			)
			u_new[idx] = damp * (2.0 * _u[idx] - _u_prev[idx] + factor * laplacian)

	# Boundary stays at zero (already initialized to 0)

	_u_prev = _u
	_u = u_new


func _update_courant() -> void:
	_courant = wave_speed * _dt / _dx


# --- Frame (clamped boundary visual) ---

func _create_frame() -> void:
	_frame_node = Node3D.new()
	_frame_node.name = "Frame"
	add_child(_frame_node)

	var half: float = membrane_size / 2.0
	var bar_thickness: float = 0.008
	var bar_height: float = 0.015

	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.35, 0.25, 0.18)
	frame_mat.roughness = 0.9

	# Four sides of the rectangular frame
	var sides: Array = [
		[Vector3(0, 0, -half), Vector3(membrane_size + bar_thickness * 2, bar_height, bar_thickness)],
		[Vector3(0, 0, half), Vector3(membrane_size + bar_thickness * 2, bar_height, bar_thickness)],
		[Vector3(-half, 0, 0), Vector3(bar_thickness, bar_height, membrane_size)],
		[Vector3(half, 0, 0), Vector3(bar_thickness, bar_height, membrane_size)],
	]

	for side in sides:
		var bar: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = side[1]
		bar.mesh = box
		bar.material_override = frame_mat
		bar.position = side[0]
		_frame_node.add_child(bar)


# --- Surface mesh ---

func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "MembraneSurface"
	add_child(_surface_mesh)

	_surface_mat = StandardMaterial3D.new()
	_surface_mat.vertex_color_use_as_albedo = true
	_surface_mat.emission_enabled = true
	_surface_mat.emission_energy_multiplier = 0.2
	_surface_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = _surface_mat

	_build_surface()


func _build_surface() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = membrane_size / 2.0
	var cell: float = membrane_size / float(grid_res - 1)

	_max_displacement = 0.0

	for j in range(grid_res - 1):
		for i in range(grid_res - 1):
			var idx00: int = j * grid_res + i
			var idx10: int = j * grid_res + i + 1
			var idx01: int = (j + 1) * grid_res + i
			var idx11: int = (j + 1) * grid_res + i + 1

			var h00: float = _u[idx00]
			var h10: float = _u[idx10]
			var h01: float = _u[idx01]
			var h11: float = _u[idx11]

			_max_displacement = maxf(_max_displacement, maxf(absf(h00), maxf(absf(h10), maxf(absf(h01), absf(h11)))))

			var x0: float = -half + i * cell
			var x1: float = -half + (i + 1) * cell
			var z0: float = -half + j * cell
			var z1: float = -half + (j + 1) * cell

			var v00: Vector3 = Vector3(x0, h00 * height_scale, z0)
			var v10: Vector3 = Vector3(x1, h10 * height_scale, z0)
			var v01: Vector3 = Vector3(x0, h01 * height_scale, z1)
			var v11: Vector3 = Vector3(x1, h11 * height_scale, z1)

			var c00: Color = _displacement_color(h00)
			var c10: Color = _displacement_color(h10)
			var c01: Color = _displacement_color(h01)
			var c11: Color = _displacement_color(h11)

			# Triangle 1
			im.surface_set_color(c00)
			im.surface_add_vertex(v00)
			im.surface_set_color(c10)
			im.surface_add_vertex(v10)
			im.surface_set_color(c11)
			im.surface_add_vertex(v11)

			# Triangle 2
			im.surface_set_color(c00)
			im.surface_add_vertex(v00)
			im.surface_set_color(c11)
			im.surface_add_vertex(v11)
			im.surface_set_color(c01)
			im.surface_add_vertex(v01)

	im.surface_end()
	_surface_mesh.mesh = im


func _displacement_color(h: float) -> Color:
	# Normalise to roughly [-1, 1] using initial amplitude
	var t: float = clampf(h / maxf(initial_amplitude, 0.001), -1.0, 1.0)
	if t > 0.0:
		return color_zero.lerp(color_positive, t)
	else:
		return color_zero.lerp(color_negative, -t)


# --- Labels ---

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "2D WAVE EQUATION"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, height_scale * initial_amplitude + 0.08, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, height_scale * initial_amplitude + 0.04, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)
	_update_info()


# --- VR Controls ---

func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.02, membrane_size / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel backing
	var panel_back: MeshInstance3D = MeshInstance3D.new()
	var panel_mesh: BoxMesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.16, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat: StandardMaterial3D = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Damping slider
	_damping_slider = SLIDER_HORIZONTAL.instantiate()
	_damping_slider.name = "DampingSlider"
	_damping_slider.position = Vector3(-0.1, 0.04, 0)
	_damping_slider.rotation_degrees.x = -30
	_damping_slider.scale = Vector3(0.8, 0.8, 0.8)
	var damp_label = _damping_slider.get_node_or_null("Frame/LabelName")
	if damp_label:
		damp_label.text = "DAMP"
	_control_panel.add_child(_damping_slider)
	_damping_slider.slider_moved.connect(_on_damping_changed)

	# Wave speed slider
	_speed_slider = SLIDER_HORIZONTAL.instantiate()
	_speed_slider.name = "SpeedSlider"
	_speed_slider.position = Vector3(0.1, 0.04, 0)
	_speed_slider.rotation_degrees.x = -30
	_speed_slider.scale = Vector3(0.8, 0.8, 0.8)
	var speed_label = _speed_slider.get_node_or_null("Frame/LabelName")
	if speed_label:
		speed_label.text = "SPEED"
	_control_panel.add_child(_speed_slider)
	_speed_slider.slider_moved.connect(_on_speed_changed)

	# Strike / reset buttons
	var buttons_data: Array = [
		["STRIKE", "_on_strike"],
		["RESET", "_on_reset"],
	]

	for idx in range(buttons_data.size()):
		var btn: Node = PUSH_BUTTON.instantiate()
		btn.name = buttons_data[idx][0]
		btn.position = Vector3(-0.08 + idx * 0.16, -0.035, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, buttons_data[idx][0])

		var callback: String = buttons_data[idx][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(Callable(self, callback))

	call_deferred("_sync_sliders")


func _add_button_label(btn: Node, text: String) -> void:
	var lbl: Label3D = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)


func _sync_sliders() -> void:
	if _damping_slider and _damping_slider.has_method("set_normalized_value"):
		# Damping range: 0.0 — 0.02
		_damping_slider.set_normalized_value(damping / 0.02)
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		# Speed range: 0.5 — 5.0
		_speed_slider.set_normalized_value((wave_speed - 0.5) / 4.5)


func _on_damping_changed(_pos) -> void:
	if _damping_slider and _damping_slider.has_method("get_normalized_value"):
		damping = _damping_slider.get_normalized_value() * 0.02


func _on_speed_changed(_pos) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		wave_speed = 0.5 + _speed_slider.get_normalized_value() * 4.5
		_update_courant()


func _on_strike(_b = null) -> void:
	# Apply a new Gaussian pulse at a slightly offset position
	var cx: float = 0.35 + randf() * 0.3
	var cy: float = 0.35 + randf() * 0.3
	_apply_gaussian_pulse(cx, cy, initial_amplitude * 0.6, initial_sigma)


func _on_reset(_b = null) -> void:
	_init_grids()
	_apply_gaussian_pulse(0.5, 0.5, initial_amplitude, initial_sigma)
	_time = 0.0


# --- Per-frame update ---

func _process(delta: float) -> void:
	_time += delta

	# Sub-step for stability — run multiple small steps per frame
	var sub_steps: int = 3
	_dt = delta / float(sub_steps)
	_update_courant()

	for _s in range(sub_steps):
		# Clamp courant for stability: c*dt/dx must be < 1/sqrt(2) ≈ 0.707
		if _courant < 0.707:
			_step_wave()

	_build_surface()
	_update_info()


func _update_info() -> void:
	if _info_label:
		_info_label.text = "u_tt = c²∇²u  ·  c=%.1f  damp=%.3f  peak=%.3f" % [
			wave_speed, damping, _max_displacement
		]


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("wave_speed"):
		wave_speed = float(config_data["wave_speed"])
	if config_data.has("damping"):
		damping = float(config_data["damping"])
	if config_data.has("height_scale"):
		height_scale = float(config_data["height_scale"])
	if config_data.has("initial_amplitude"):
		initial_amplitude = float(config_data["initial_amplitude"])
