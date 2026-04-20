# @identity
# essence: a 3D loss surface colored green (low) through yellow to red (high), with a white ball descending step by step along the negative gradient and leaving a blue trail of breadcrumbs
# desire: to make the invisible landscape of optimization tangible — the learner sees the ball get trapped in a local minimum and understands that optimization finds AN answer, not THE answer
# critical_parameter: learning_rate (0.08, range 0.005–0.3) — too large and the ball overshoots and oscillates; too small and convergence takes forever; the live slider makes this relationship visible immediately
# triggers: _ready builds surface (ImmediateMesh per frame), ball (SphereMesh), trail (capped array of breadcrumb spheres), VR control panel; _process() steps gradient descent every step_interval seconds
# emerges: when the ball converges, the frozen trail reveals the full descent path — starting position determines which local minimum is found; hitting reset with the same learning rate often finds a different minimum
# needs: VR learning rate slider [has via RackTemplates]; VR reset button [has]; apply_grid_config with explicit start_x/start_y [has]
# relationships: pairs with gradient_descent_visualization (simpler 2D version placed in ML_Gradient_Landscape); appears in machinelearning gallery; echoes loss_function_comparator (shows three loss functions side by side vs one animated descent)
# truth: gradient descent finds a nearby valley, not the deepest one — the starting point and learning rate determine which minimum you land in, making optimization an act of situated exploration rather than guaranteed discovery

extends Node3D
class_name GradientDescentLandscape

## 3D loss surface with a ball rolling down to the minimum via gradient descent.
## ImmediateMesh triangulated surface colored by height (green=low, red=high).
## SphereMesh ball steps along the negative gradient, leaving a trail of breadcrumbs.

# --- Configuration ---

@export var surface_size: float = 0.7
@export var grid_resolution: int = 32
@export var learning_rate: float = 0.08:
	set(value):
		learning_rate = clampf(value, 0.005, 0.3)
		_sync_lr_slider()

@export var step_interval: float = 0.12  # seconds between gradient steps

# --- Colors ---

var color_low: Color = Color(0.15, 0.75, 0.3)   # Green — minimum (good)
var color_mid: Color = Color(0.95, 0.85, 0.2)    # Yellow — mid
var color_high: Color = Color(0.95, 0.2, 0.15)   # Red — high (bad)
var color_ball: Color = Color(1.0, 1.0, 1.0)     # White ball
var color_trail: Color = Color(0.3, 0.6, 1.0)    # Blue trail breadcrumbs

# --- Internal state ---

var _time: float = 0.0
var _step_timer: float = 0.0
var _ball_pos: Vector2 = Vector2(1.5, 1.2)  # Position in function space
var _trail: Array[Vector2] = []
var _max_trail: int = 120
var _converged: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- Heights cache ---

var _height_min: float = 0.0
var _height_max: float = 1.0

# --- Nodes ---

var _surface_mesh: MeshInstance3D
var _ball_mesh: MeshInstance3D
var _trail_parent: Node3D
var _trail_spheres: Array[MeshInstance3D] = []
var _title_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D
var _lr_slider: Node



func _ready() -> void:
	_rng.seed = 77
	_compute_height_range()
	_create_surface()
	_create_ball()
	_create_trail_parent()
	_create_labels()
	_create_vr_controls()
	_reset_ball()
	_update_surface()


# --- Loss function ---
# f(x,y) = x^2 + y^2 with Gaussian bumps creating local minima
# Domain: roughly [-2, 2] x [-2, 2]

func _loss(x: float, y: float) -> float:
	var bowl = 0.15 * (x * x + y * y)
	# Local minimum bumps (Gaussian dips)
	var bump1 = -0.6 * exp(-((x - 1.0) * (x - 1.0) + (y - 0.8) * (y - 0.8)) / 0.3)
	var bump2 = -0.4 * exp(-((x + 0.7) * (x + 0.7) + (y - 1.1) * (y - 1.1)) / 0.25)
	var bump3 = -0.35 * exp(-((x + 0.3) * (x + 0.3) + (y + 0.9) * (y + 0.9)) / 0.2)
	# Saddle ridge for visual interest
	var ridge = 0.08 * sin(x * 2.0) * cos(y * 1.5)
	return bowl + bump1 + bump2 + bump3 + ridge


func _gradient(x: float, y: float) -> Vector2:
	var eps = 0.001
	var dx = (_loss(x + eps, y) - _loss(x - eps, y)) / (2.0 * eps)
	var dy = (_loss(x, y + eps) - _loss(x, y - eps)) / (2.0 * eps)
	return Vector2(dx, dy)


func _compute_height_range() -> void:
	_height_min = INF
	_height_max = -INF
	var domain = 2.0
	for j in range(grid_resolution):
		for i in range(grid_resolution):
			var fx = remap(float(i), 0, grid_resolution - 1, -domain, domain)
			var fy = remap(float(j), 0, grid_resolution - 1, -domain, domain)
			var h = _loss(fx, fy)
			_height_min = minf(_height_min, h)
			_height_max = maxf(_height_max, h)


# --- Surface mesh (ImmediateMesh PRIMITIVE_TRIANGLES) ---

func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "LossSurface"
	add_child(_surface_mesh)


func _update_surface() -> void:
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = surface_size / 2.0
	var domain = 2.0
	var cell = surface_size / float(grid_resolution)
	var height_scale = 0.25  # Vertical exaggeration

	for j in range(grid_resolution - 1):
		for i in range(grid_resolution - 1):
			# Function-space coordinates
			var fx0 = remap(float(i), 0, grid_resolution - 1, -domain, domain)
			var fx1 = remap(float(i + 1), 0, grid_resolution - 1, -domain, domain)
			var fy0 = remap(float(j), 0, grid_resolution - 1, -domain, domain)
			var fy1 = remap(float(j + 1), 0, grid_resolution - 1, -domain, domain)

			var h00 = _loss(fx0, fy0)
			var h10 = _loss(fx1, fy0)
			var h01 = _loss(fx0, fy1)
			var h11 = _loss(fx1, fy1)

			# World-space positions
			var x0 = -half + i * cell
			var x1 = -half + (i + 1) * cell
			var z0 = -half + j * cell
			var z1 = -half + (j + 1) * cell

			var v00 = Vector3(x0, h00 * height_scale, z0)
			var v10 = Vector3(x1, h10 * height_scale, z0)
			var v01 = Vector3(x0, h01 * height_scale, z1)
			var v11 = Vector3(x1, h11 * height_scale, z1)

			var c00 = _height_color(h00)
			var c10 = _height_color(h10)
			var c01 = _height_color(h01)
			var c11 = _height_color(h11)

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

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = mat


func _height_color(h: float) -> Color:
	var t = clampf(remap(h, _height_min, _height_max, 0.0, 1.0), 0.0, 1.0)
	if t < 0.5:
		return color_low.lerp(color_mid, t * 2.0)
	else:
		return color_mid.lerp(color_high, (t - 0.5) * 2.0)


# --- Ball ---

func _create_ball() -> void:
	_ball_mesh = MeshInstance3D.new()
	_ball_mesh.name = "GDBall"
	var sphere = SphereMesh.new()
	sphere.radius = 0.018
	sphere.height = 0.036
	sphere.radial_segments = 12
	sphere.rings = 6
	_ball_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_ball
	mat.emission_enabled = true
	mat.emission = color_ball
	mat.emission_energy_multiplier = 1.5
	_ball_mesh.material_override = mat
	add_child(_ball_mesh)


func _update_ball_visual() -> void:
	var world_pos = _func_to_world(_ball_pos)
	_ball_mesh.position = world_pos + Vector3(0, 0.02, 0)  # Float above surface


func _func_to_world(fpos: Vector2) -> Vector3:
	var half = surface_size / 2.0
	var domain = 2.0
	var height_scale = 0.25
	var wx = remap(fpos.x, -domain, domain, -half, half)
	var wz = remap(fpos.y, -domain, domain, -half, half)
	var wy = _loss(fpos.x, fpos.y) * height_scale
	return Vector3(wx, wy, wz)


# --- Trail ---

func _create_trail_parent() -> void:
	_trail_parent = Node3D.new()
	_trail_parent.name = "Trail"
	add_child(_trail_parent)


func _add_trail_point() -> void:
	_trail.append(_ball_pos)

	var sphere_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.006
	sphere.height = 0.012
	sphere.radial_segments = 6
	sphere.rings = 3
	sphere_inst.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_trail
	mat.emission_enabled = true
	mat.emission = color_trail
	mat.emission_energy_multiplier = 0.8
	sphere_inst.material_override = mat

	var world_pos = _func_to_world(_ball_pos)
	sphere_inst.position = world_pos + Vector3(0, 0.015, 0)
	_trail_parent.add_child(sphere_inst)
	_trail_spheres.append(sphere_inst)

	# Cap trail length
	if _trail.size() > _max_trail:
		_trail.pop_front()
		var old = _trail_spheres.pop_front()
		old.queue_free()


func _clear_trail() -> void:
	_trail.clear()
	for s in _trail_spheres:
		s.queue_free()
	_trail_spheres.clear()


# --- Labels ---

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "GRADIENT DESCENT"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.28, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, 0.23, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)
	_update_info()


func _update_info() -> void:
	if not _info_label:
		return
	var loss_val = _loss(_ball_pos.x, _ball_pos.y)
	var grad = _gradient(_ball_pos.x, _ball_pos.y)
	var grad_mag = grad.length()
	var status = "CONVERGED" if _converged else "DESCENDING"
	_info_label.text = "lr=%.3f  loss=%.3f  |grad|=%.3f  [%s]  steps=%d" % [
		learning_rate, loss_val, grad_mag, status, _trail.size()
	]


# --- VR Controls ---

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_parameter_panel(
		1, ["LEARNING RATE"],
		[(learning_rate - 0.005) / 0.295]
	)
	_control_panel.position = Vector3(0, 0.02, surface_size / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_lr_slider = _control_panel.get_node_or_null("Param_0")
	if _lr_slider and _lr_slider.has_signal("slider_moved"):
		_lr_slider.slider_moved.connect(_on_lr_changed)

	var reset_btn: Node = _control_panel.get_node_or_null("ResetButton")
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_ball())


func _sync_lr_slider() -> void:
	if _lr_slider and _lr_slider.has_method("set_normalized_value"):
		_lr_slider.set_normalized_value((learning_rate - 0.005) / 0.295)

func _on_lr_changed(_pos) -> void:
	if _lr_slider and _lr_slider.has_method("get_normalized_value"):
		learning_rate = 0.005 + _lr_slider.get_normalized_value() * 0.295


# --- Simulation ---

func _reset_ball() -> void:
	# Random starting position in outer region of domain
	var angle = _rng.randf() * TAU
	var radius = _rng.randf_range(1.0, 1.8)
	_ball_pos = Vector2(cos(angle) * radius, sin(angle) * radius)
	_converged = false
	_clear_trail()
	_add_trail_point()
	_update_ball_visual()
	_update_info()


func _process(delta: float) -> void:
	if _converged:
		return

	_step_timer += delta
	if _step_timer < step_interval:
		return
	_step_timer -= step_interval

	# Gradient descent step
	var grad = _gradient(_ball_pos.x, _ball_pos.y)
	var grad_mag = grad.length()

	# Convergence check
	if grad_mag < 0.005:
		_converged = true
		_update_info()
		return

	# Clamp gradient to avoid huge jumps
	if grad_mag > 5.0:
		grad = grad.normalized() * 5.0

	_ball_pos -= learning_rate * grad

	# Keep within domain
	_ball_pos.x = clampf(_ball_pos.x, -2.0, 2.0)
	_ball_pos.y = clampf(_ball_pos.y, -2.0, 2.0)

	_add_trail_point()
	_update_ball_visual()
	_update_info()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("learning_rate"):
		learning_rate = float(config_data["learning_rate"])
	if config_data.has("step_interval"):
		step_interval = float(config_data["step_interval"])
	if config_data.has("start_x") and config_data.has("start_y"):
		_ball_pos = Vector2(float(config_data["start_x"]), float(config_data["start_y"]))
		_converged = false
		_clear_trail()
		_add_trail_point()
		_update_ball_visual()
		_update_info()
