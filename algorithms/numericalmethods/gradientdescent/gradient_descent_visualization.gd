extends Node3D

# @identity
# essence: θ(t+1) = θ(t) - η∇f(θ) — follow the negative gradient downhill; four variants racing on the same surface
# desire: watch SGD, Momentum, Nesterov, and Adam race down a loss landscape, each with its own strategy
# critical_parameter: learning_rate (η) — too small creeps, too large oscillates, just right converges
# triggers: mode button switches between optimizer race, convergence analysis, and Hessian eigenvalue display; function button cycles loss surfaces
# emerges: Adam's adaptive superiority on most surfaces; saddle points that trap SGD; Nesterov's look-ahead advantage
# needs: VR push button for mode [has], sliders for learning rate, momentum, speed [has]
# relationships: unlocks neural_network_visualization (gradient descent IS the training loop); contrasts 9_3_smart_rockets_vr (gradient-free vs gradient-based optimization)
# truth: learning is descending a landscape you cannot fully see — the gradient is the only local truth available

# Gradient Descent — Optimizer Variants & Convergence Analysis
# Compares SGD, Momentum, Nesterov, Adam on 3D loss surfaces
# Shows convergence behavior, learning rate sensitivity, Hessian structure

enum Mode { OPTIMIZERS, CONVERGENCE, HESSIAN }

# ── constants ──────────────────────────────────────────────────────────
const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")

const COL_SGD       := Color(0.9, 0.3, 0.3, 1.0)   # red
const COL_MOMENTUM  := Color(0.3, 0.9, 0.3, 1.0)   # green
const COL_NESTEROV  := Color(0.3, 0.5, 0.9, 1.0)   # blue
const COL_ADAM      := Color(0.9, 0.7, 0.1, 1.0)   # gold
const COL_SURFACE   := Color(0.15, 0.12, 0.25, 0.6)
const COL_SURFACE_HI := Color(0.5, 0.3, 0.7, 0.6)
const COL_MINIMUM   := Color(0.2, 0.9, 0.4, 1.0)
const COL_HESSIAN_P := Color(0.1, 0.6, 0.9, 0.9)   # positive eigenvalue
const COL_HESSIAN_N := Color(0.9, 0.2, 0.2, 0.9)   # negative eigenvalue
const COL_GRID      := Color(0.3, 0.3, 0.4, 0.3)
const COL_LR_COLORS : Array = [
	Color(0.9, 0.2, 0.2), Color(0.2, 0.8, 0.3), Color(0.2, 0.5, 0.9),
	Color(0.9, 0.6, 0.1), Color(0.7, 0.2, 0.8),
]

const SURFACE_RES := 40
const TRAIL_MAX   := 200
const ADAM_EPS     := 1e-8

# ── exported params ────────────────────────────────────────────────────
@export var function_preset: int = 0  # 0=Quadratic, 1=Rosenbrock, 2=Himmelblau
@export var learning_rate: float = 0.05
@export var momentum_beta: float = 0.9
@export var adam_beta1: float = 0.9
@export var adam_beta2: float = 0.999
@export var step_speed: float = 2.0

# ── internal state ─────────────────────────────────────────────────────
var _mode: int = Mode.OPTIMIZERS
var _time: float = 0.0
var _stepping: bool = false
var _step_count: int = 0

# surface range
var _x_range := Vector2(-4.0, 4.0)
var _z_range := Vector2(-4.0, 4.0)
var _y_scale := 0.4  # height scaling for function values

# optimizer states (arrays of dicts)
var _optimizers: Array = []  # each: {name, color, pos, vel, m, v, path, converged, value}

# convergence mode
var _conv_runs: Array = []  # array of {lr, paths (array of arrays per optimizer)}

# hessian mode
var _hessian_grid: Array = []  # array of {pos, eigenvalues, eigenvectors}

# ── mesh instances ─────────────────────────────────────────────────────
var _surface_im: ImmediateMesh
var _surface_mi: MeshInstance3D
var _trails_im: ImmediateMesh
var _trails_mi: MeshInstance3D
var _arrows_im: ImmediateMesh
var _arrows_mi: MeshInstance3D
var _hessian_im: ImmediateMesh
var _hessian_mi: MeshInstance3D
var _markers_im: ImmediateMesh
var _markers_mi: MeshInstance3D

var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# ── labels ─────────────────────────────────────────────────────────────
var _title_label: Label3D
var _info_label: Label3D
var _legend_label: Label3D

# ── controls ───────────────────────────────────────────────────────────
var _mode_button: Node3D
var _lr_slider: Node3D
var _beta_slider: Node3D
var _speed_slider: Node3D
var _fn_button: Node3D

# ════════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_controls()
	_init_mode()

func _process(delta: float) -> void:
	_time += delta
	if _stepping:
		var steps_per_frame := int(ceil(step_speed * delta * 30.0))
		for i in steps_per_frame:
			if _step_count >= TRAIL_MAX:
				_stepping = false
				break
			match _mode:
				Mode.OPTIMIZERS:
					_step_optimizers()
				Mode.CONVERGENCE:
					_step_convergence()
			_step_count += 1
	_draw_all()
	_update_labels()

# ════════════════════════════════════════════════════════════════════════
#  MATERIALS & MESH SETUP
# ════════════════════════════════════════════════════════════════════════

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = _mat_unshaded.duplicate()
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _create_mesh_instances() -> void:
	_surface_im = ImmediateMesh.new()
	_surface_mi = MeshInstance3D.new()
	_surface_mi.mesh = _surface_im
	_surface_mi.material_override = _mat_alpha
	add_child(_surface_mi)

	_trails_im = ImmediateMesh.new()
	_trails_mi = MeshInstance3D.new()
	_trails_mi.mesh = _trails_im
	_trails_mi.material_override = _mat_unshaded
	add_child(_trails_mi)

	_arrows_im = ImmediateMesh.new()
	_arrows_mi = MeshInstance3D.new()
	_arrows_mi.mesh = _arrows_im
	_arrows_mi.material_override = _mat_unshaded
	add_child(_arrows_mi)

	_hessian_im = ImmediateMesh.new()
	_hessian_mi = MeshInstance3D.new()
	_hessian_mi.mesh = _hessian_im
	_hessian_mi.material_override = _mat_alpha
	add_child(_hessian_mi)

	_markers_im = ImmediateMesh.new()
	_markers_mi = MeshInstance3D.new()
	_markers_mi.mesh = _markers_im
	_markers_mi.material_override = _mat_unshaded
	add_child(_markers_mi)

# ════════════════════════════════════════════════════════════════════════
#  LABELS
# ════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 3.2, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 18
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 2.8, 0)
	_info_label.modulate = Color(0.8, 0.8, 0.9)
	add_child(_info_label)

	_legend_label = Label3D.new()
	_legend_label.font_size = 16
	_legend_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_legend_label.position = Vector3(0, -1.6, 0)
	_legend_label.modulate = Color(0.7, 0.7, 0.8)
	add_child(_legend_label)

# ════════════════════════════════════════════════════════════════════════
#  CONTROLS
# ════════════════════════════════════════════════════════════════════════

func _create_controls() -> void:
	# Mode button
	_mode_button = BUTTON_SCENE.instantiate()
	_mode_button.position = Vector3(-2.4, -1.0, 0)
	add_child(_mode_button)
	var btn_area = _mode_button.get_node_or_null("InteractableAreaButton")
	if btn_area:
		btn_area.button_pressed.connect(_cycle_mode)
	var btn_label = _mode_button.get_node_or_null("Frame/LabelName")
	if btn_label:
		btn_label.text = "Mode"

	# Function preset button
	_fn_button = BUTTON_SCENE.instantiate()
	_fn_button.position = Vector3(-1.6, -1.0, 0)
	add_child(_fn_button)
	var fn_area = _fn_button.get_node_or_null("InteractableAreaButton")
	if fn_area:
		fn_area.button_pressed.connect(_cycle_function)
	var fn_label = _fn_button.get_node_or_null("Frame/LabelName")
	if fn_label:
		fn_label.text = "Function"

	# Learning rate slider
	_lr_slider = SLIDER_SCENE.instantiate()
	_lr_slider.position = Vector3(-0.4, -1.0, 0)
	add_child(_lr_slider)
	_lr_slider.set_param_name("Learn Rate")
	_lr_slider.set_normalized_value(learning_rate / 0.2)
	_lr_slider.slider_moved.connect(_on_lr_changed)

	# Momentum beta slider
	_beta_slider = SLIDER_SCENE.instantiate()
	_beta_slider.position = Vector3(0.8, -1.0, 0)
	add_child(_beta_slider)
	_beta_slider.set_param_name("Momentum β")
	_beta_slider.set_normalized_value(momentum_beta)
	_beta_slider.slider_moved.connect(_on_beta_changed)

	# Speed slider
	_speed_slider = SLIDER_SCENE.instantiate()
	_speed_slider.position = Vector3(2.0, -1.0, 0)
	add_child(_speed_slider)
	_speed_slider.set_param_name("Speed")
	_speed_slider.set_normalized_value(step_speed / 5.0)
	_speed_slider.slider_moved.connect(_on_speed_changed)

func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()

func _cycle_function() -> void:
	function_preset = (function_preset + 1) % 3
	_init_mode()

func _on_lr_changed(_v: float) -> void:
	learning_rate = clampf(_lr_slider.get_normalized_value() * 0.2, 0.001, 0.2)
	_init_mode()

func _on_beta_changed(_v: float) -> void:
	momentum_beta = clampf(_beta_slider.get_normalized_value(), 0.0, 0.99)
	adam_beta1 = momentum_beta
	_init_mode()

func _on_speed_changed(_v: float) -> void:
	step_speed = clampf(_speed_slider.get_normalized_value() * 5.0, 0.1, 5.0)

# ════════════════════════════════════════════════════════════════════════
#  FUNCTION EVALUATION
# ════════════════════════════════════════════════════════════════════════

func _fn_name() -> String:
	match function_preset:
		0: return "Quadratic Bowl"
		1: return "Rosenbrock Valley"
		2: return "Himmelblau"
		_: return "Quadratic Bowl"

func _eval(p: Vector2) -> float:
	var x := p.x
	var y := p.y
	match function_preset:
		0:  # Quadratic bowl: x² + y²
			return x * x + y * y
		1:  # Rosenbrock: (1-x)² + 100(y-x²)²
			return (1.0 - x) * (1.0 - x) + 100.0 * (y - x * x) * (y - x * x)
		2:  # Himmelblau: (x²+y-11)² + (x+y²-7)²
			return (x*x + y - 11.0) * (x*x + y - 11.0) + (x + y*y - 7.0) * (x + y*y - 7.0)
		_:
			return x * x + y * y

func _gradient(p: Vector2) -> Vector2:
	var eps := 0.0001
	var dx := (_eval(Vector2(p.x + eps, p.y)) - _eval(Vector2(p.x - eps, p.y))) / (2.0 * eps)
	var dy := (_eval(Vector2(p.x, p.y + eps)) - _eval(Vector2(p.x, p.y - eps))) / (2.0 * eps)
	return Vector2(dx, dy)

func _hessian(p: Vector2) -> Array:
	# Returns [fxx, fxy, fyx, fyy] via finite differences
	var eps := 0.001
	var f00 := _eval(p)
	var fxx := (_eval(Vector2(p.x + eps, p.y)) - 2.0 * f00 + _eval(Vector2(p.x - eps, p.y))) / (eps * eps)
	var fyy := (_eval(Vector2(p.x, p.y + eps)) - 2.0 * f00 + _eval(Vector2(p.x, p.y - eps))) / (eps * eps)
	var fxy := (_eval(Vector2(p.x + eps, p.y + eps)) - _eval(Vector2(p.x + eps, p.y - eps))
		- _eval(Vector2(p.x - eps, p.y + eps)) + _eval(Vector2(p.x - eps, p.y - eps))) / (4.0 * eps * eps)
	return [fxx, fxy, fxy, fyy]

func _hessian_eigen(p: Vector2) -> Dictionary:
	# 2x2 eigenvalue decomposition
	var h := _hessian(p)
	var a: float = h[0]
	var b: float = h[1]
	var d: float = h[3]
	var trace := a + d
	var det := a * d - b * b
	var disc := trace * trace - 4.0 * det
	if disc < 0.0:
		disc = 0.0
	var sqrt_disc := sqrt(disc)
	var l1 := (trace + sqrt_disc) / 2.0
	var l2 := (trace - sqrt_disc) / 2.0
	# eigenvectors
	var v1 := Vector2(1, 0)
	var v2 := Vector2(0, 1)
	if abs(b) > 1e-8:
		v1 = Vector2(l1 - d, b).normalized()
		v2 = Vector2(l2 - d, b).normalized()
	elif abs(a - d) > 1e-8:
		v1 = Vector2(1, 0)
		v2 = Vector2(0, 1)
	return {"l1": l1, "l2": l2, "v1": v1, "v2": v2}

func _start_pos() -> Vector2:
	match function_preset:
		0: return Vector2(3.5, 2.5)
		1: return Vector2(-1.5, 1.5)
		2: return Vector2(0.5, 0.5)
		_: return Vector2(3.0, 2.0)

func _y_scale_for_fn() -> float:
	match function_preset:
		0: return 0.15
		1: return 0.0005  # Rosenbrock has huge values
		2: return 0.003
		_: return 0.15

# ════════════════════════════════════════════════════════════════════════
#  MODE INIT
# ════════════════════════════════════════════════════════════════════════

func _init_mode() -> void:
	_stepping = false
	_step_count = 0
	_y_scale = _y_scale_for_fn()

	_surface_mi.visible = true
	_trails_mi.visible = (_mode != Mode.HESSIAN)
	_arrows_mi.visible = (_mode == Mode.OPTIMIZERS)
	_hessian_mi.visible = (_mode == Mode.HESSIAN)
	_markers_mi.visible = true

	match _mode:
		Mode.OPTIMIZERS:
			_init_optimizers()
		Mode.CONVERGENCE:
			_init_convergence()
		Mode.HESSIAN:
			_init_hessian()

	_stepping = true

func _init_optimizers() -> void:
	_optimizers.clear()
	var start := _start_pos()
	var lr := learning_rate

	# SGD (vanilla)
	_optimizers.append({
		"name": "SGD",
		"color": COL_SGD,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "sgd",
	})

	# Momentum
	_optimizers.append({
		"name": "Momentum",
		"color": COL_MOMENTUM,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "momentum",
	})

	# Nesterov
	_optimizers.append({
		"name": "Nesterov",
		"color": COL_NESTEROV,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "nesterov",
	})

	# Adam
	_optimizers.append({
		"name": "Adam",
		"color": COL_ADAM,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "adam",
	})

func _init_convergence() -> void:
	_conv_runs.clear()
	var lrs := [0.001, 0.01, 0.05, 0.1, 0.15]
	var start := _start_pos()
	for i in lrs.size():
		var run := {
			"lr": lrs[i],
			"color": COL_LR_COLORS[i],
			"pos": start,
			"vel": Vector2.ZERO,
			"m": Vector2.ZERO,
			"v_adam": Vector2.ZERO,
			"t": 0,
			"path": [start],
			"values": [_eval(start)],
			"converged": false,
		}
		_conv_runs.append(run)

func _init_hessian() -> void:
	_hessian_grid.clear()
	var res := 8
	var dx := (_x_range.y - _x_range.x) / float(res)
	var dz := (_z_range.y - _z_range.x) / float(res)
	for i in range(res + 1):
		for j in range(res + 1):
			var px := _x_range.x + i * dx
			var pz := _z_range.x + j * dz
			var p := Vector2(px, pz)
			var eigen := _hessian_eigen(p)
			_hessian_grid.append({
				"pos": p,
				"l1": eigen.l1,
				"l2": eigen.l2,
				"v1": eigen.v1,
				"v2": eigen.v2,
			})

# ════════════════════════════════════════════════════════════════════════
#  STEPPING
# ════════════════════════════════════════════════════════════════════════

func _step_optimizers() -> void:
	for opt in _optimizers:
		if opt.converged:
			continue
		var pos: Vector2 = opt.pos
		var grad := _gradient(pos)

		if grad.length() < 0.0005:
			opt.converged = true
			continue

		var new_pos := pos
		match opt.type:
			"sgd":
				new_pos = pos - learning_rate * grad

			"momentum":
				opt.vel = momentum_beta * (opt.vel as Vector2) - learning_rate * grad
				new_pos = pos + (opt.vel as Vector2)

			"nesterov":
				var look_ahead := pos + momentum_beta * (opt.vel as Vector2)
				var look_grad := _gradient(look_ahead)
				opt.vel = momentum_beta * (opt.vel as Vector2) - learning_rate * look_grad
				new_pos = pos + (opt.vel as Vector2)

			"adam":
				opt.t = (opt.t as int) + 1
				var t_f := float(opt.t as int)
				opt.m = adam_beta1 * (opt.m as Vector2) + (1.0 - adam_beta1) * grad
				opt.v_adam = adam_beta2 * (opt.v_adam as Vector2) + (1.0 - adam_beta2) * Vector2(grad.x * grad.x, grad.y * grad.y)
				var m_hat: Vector2 = (opt.m as Vector2) / (1.0 - pow(adam_beta1, t_f))
				var v_hat: Vector2 = (opt.v_adam as Vector2) / (1.0 - pow(adam_beta2, t_f))
				new_pos = pos - learning_rate * Vector2(
					m_hat.x / (sqrt(v_hat.x) + ADAM_EPS),
					m_hat.y / (sqrt(v_hat.y) + ADAM_EPS)
				)

		# Clamp to range
		new_pos.x = clampf(new_pos.x, _x_range.x, _x_range.y)
		new_pos.y = clampf(new_pos.y, _z_range.x, _z_range.y)
		opt.pos = new_pos
		opt.value = _eval(new_pos)
		(opt.path as Array).append(new_pos)

func _step_convergence() -> void:
	for run in _conv_runs:
		if run.converged:
			continue
		var pos: Vector2 = run.pos
		var grad := _gradient(pos)
		if grad.length() < 0.0005:
			run.converged = true
			continue

		# Adam with this run's lr
		run.t = (run.t as int) + 1
		var t_f := float(run.t as int)
		var lr_r: float = run.lr
		run.m = adam_beta1 * (run.m as Vector2) + (1.0 - adam_beta1) * grad
		run.v_adam = adam_beta2 * (run.v_adam as Vector2) + (1.0 - adam_beta2) * Vector2(grad.x * grad.x, grad.y * grad.y)
		var m_hat: Vector2 = (run.m as Vector2) / (1.0 - pow(adam_beta1, t_f))
		var v_hat: Vector2 = (run.v_adam as Vector2) / (1.0 - pow(adam_beta2, t_f))
		var new_pos := pos - lr_r * Vector2(
			m_hat.x / (sqrt(v_hat.x) + ADAM_EPS),
			m_hat.y / (sqrt(v_hat.y) + ADAM_EPS)
		)
		new_pos.x = clampf(new_pos.x, _x_range.x, _x_range.y)
		new_pos.y = clampf(new_pos.y, _z_range.x, _z_range.y)
		run.pos = new_pos
		(run.path as Array).append(new_pos)
		(run.values as Array).append(_eval(new_pos))

# ════════════════════════════════════════════════════════════════════════
#  DRAWING
# ════════════════════════════════════════════════════════════════════════

func _draw_all() -> void:
	_draw_surface()
	match _mode:
		Mode.OPTIMIZERS:
			_draw_optimizer_trails()
			_draw_optimizer_markers()
			_hessian_im.clear_surfaces()
		Mode.CONVERGENCE:
			_draw_convergence_trails()
			_draw_convergence_chart()
			_hessian_im.clear_surfaces()
		Mode.HESSIAN:
			_trails_im.clear_surfaces()
			_arrows_im.clear_surfaces()
			_draw_hessian()
			_draw_hessian_markers()

func _draw_surface() -> void:
	_surface_im.clear_surfaces()
	_surface_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var dx := (_x_range.y - _x_range.x) / float(SURFACE_RES)
	var dz := (_z_range.y - _z_range.x) / float(SURFACE_RES)

	# Find max for normalization
	var max_val := 1.0
	for i in range(SURFACE_RES + 1):
		for j in range(SURFACE_RES + 1):
			var px := _x_range.x + i * dx
			var pz := _z_range.x + j * dz
			var val := _eval(Vector2(px, pz)) * _y_scale
			if val > max_val:
				max_val = val

	for i in range(SURFACE_RES):
		for j in range(SURFACE_RES):
			var x0 := _x_range.x + i * dx
			var x1 := x0 + dx
			var z0 := _z_range.x + j * dz
			var z1 := z0 + dz

			var y00 := _eval(Vector2(x0, z0)) * _y_scale
			var y10 := _eval(Vector2(x1, z0)) * _y_scale
			var y01 := _eval(Vector2(x0, z1)) * _y_scale
			var y11 := _eval(Vector2(x1, z1)) * _y_scale

			# Cap height for visualization
			y00 = minf(y00, 4.0)
			y10 = minf(y10, 4.0)
			y01 = minf(y01, 4.0)
			y11 = minf(y11, 4.0)

			var c00 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y00 / 3.0, 0.0, 1.0))
			var c10 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y10 / 3.0, 0.0, 1.0))
			var c01 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y01 / 3.0, 0.0, 1.0))
			var c11 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y11 / 3.0, 0.0, 1.0))

			var n := Vector3.UP

			# Tri 1
			_surface_im.surface_set_color(c00)
			_surface_im.surface_set_normal(n)
			_surface_im.surface_add_vertex(Vector3(x0, y00, z0))
			_surface_im.surface_set_color(c10)
			_surface_im.surface_set_normal(n)
			_surface_im.surface_add_vertex(Vector3(x1, y10, z0))
			_surface_im.surface_set_color(c01)
			_surface_im.surface_set_normal(n)
			_surface_im.surface_add_vertex(Vector3(x0, y01, z1))

			# Tri 2
			_surface_im.surface_set_color(c10)
			_surface_im.surface_set_normal(n)
			_surface_im.surface_add_vertex(Vector3(x1, y10, z0))
			_surface_im.surface_set_color(c11)
			_surface_im.surface_set_normal(n)
			_surface_im.surface_add_vertex(Vector3(x1, y11, z1))
			_surface_im.surface_set_color(c01)
			_surface_im.surface_set_normal(n)
			_surface_im.surface_add_vertex(Vector3(x0, y01, z1))

	_surface_im.surface_end()

func _draw_optimizer_trails() -> void:
	_trails_im.clear_surfaces()
	_trails_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for opt in _optimizers:
		var path: Array = opt.path
		var col: Color = opt.color
		for k in range(1, path.size()):
			var p0: Vector2 = path[k - 1]
			var p1: Vector2 = path[k]
			var y0 := minf(_eval(p0) * _y_scale + 0.05, 4.05)
			var y1 := minf(_eval(p1) * _y_scale + 0.05, 4.05)
			_im_line_3d(_trails_im, Vector3(p0.x, y0, p0.y), Vector3(p1.x, y1, p1.y), col, 0.03)

	_trails_im.surface_end()

func _draw_optimizer_markers() -> void:
	_arrows_im.clear_surfaces()
	_markers_im.clear_surfaces()
	_markers_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for opt in _optimizers:
		var pos: Vector2 = opt.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		var col: Color = opt.color
		_im_diamond(_markers_im, Vector3(pos.x, y, pos.y), 0.15, col)

	_markers_im.surface_end()

	# Draw gradient arrows at current positions
	_arrows_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for opt in _optimizers:
		if opt.converged:
			continue
		var pos: Vector2 = opt.pos
		var grad := _gradient(pos)
		var dir := -grad.normalized()
		var y := minf(_eval(pos) * _y_scale + 0.15, 4.15)
		var tip := Vector3(pos.x + dir.x * 0.4, y, pos.y + dir.y * 0.4)
		var base := Vector3(pos.x, y, pos.y)
		_im_line_3d(_arrows_im, base, tip, opt.color as Color, 0.02)
	_arrows_im.surface_end()

func _draw_convergence_trails() -> void:
	_trails_im.clear_surfaces()
	_trails_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for run in _conv_runs:
		var path: Array = run.path
		var col: Color = run.color
		for k in range(1, path.size()):
			var p0: Vector2 = path[k - 1]
			var p1: Vector2 = path[k]
			var y0 := minf(_eval(p0) * _y_scale + 0.05, 4.05)
			var y1 := minf(_eval(p1) * _y_scale + 0.05, 4.05)
			_im_line_3d(_trails_im, Vector3(p0.x, y0, p0.y), Vector3(p1.x, y1, p1.y), col, 0.025)

	_trails_im.surface_end()

	# Markers
	_markers_im.clear_surfaces()
	_markers_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for run in _conv_runs:
		var pos: Vector2 = run.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		_im_diamond(_markers_im, Vector3(pos.x, y, pos.y), 0.12, run.color as Color)
	_markers_im.surface_end()

func _draw_convergence_chart() -> void:
	# Draw f(x) over iterations as small chart using arrows mesh
	_arrows_im.clear_surfaces()
	_arrows_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var chart_origin := Vector3(_x_range.y + 1.0, 0.0, _z_range.x)
	var chart_w := 2.5
	var chart_h := 2.5

	# Axes
	_im_line_3d(_arrows_im, chart_origin, chart_origin + Vector3(chart_w, 0, 0), COL_GRID, 0.02)
	_im_line_3d(_arrows_im, chart_origin, chart_origin + Vector3(0, chart_h, 0), COL_GRID, 0.02)

	for run in _conv_runs:
		var vals: Array = run.values
		if vals.size() < 2:
			continue
		var max_v := 0.001
		for v_item in vals:
			var vf: float = v_item
			if vf > max_v:
				max_v = vf
		for k in range(1, vals.size()):
			var x0 := chart_origin.x + (float(k - 1) / float(TRAIL_MAX)) * chart_w
			var x1 := chart_origin.x + (float(k) / float(TRAIL_MAX)) * chart_w
			var y0_val: float = vals[k - 1]
			var y1_val: float = vals[k]
			var y0 := chart_origin.y + clampf(log(y0_val + 1.0) / log(max_v + 1.0), 0.0, 1.0) * chart_h
			var y1 := chart_origin.y + clampf(log(y1_val + 1.0) / log(max_v + 1.0), 0.0, 1.0) * chart_h
			_im_line_3d(_arrows_im, Vector3(x0, y0, chart_origin.z), Vector3(x1, y1, chart_origin.z), run.color as Color, 0.015)

	_arrows_im.surface_end()

func _draw_hessian() -> void:
	_hessian_im.clear_surfaces()
	_hessian_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for h in _hessian_grid:
		var pos: Vector2 = h.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		var center := Vector3(pos.x, y, pos.y)
		var l1: float = h.l1
		var l2: float = h.l2
		var v1: Vector2 = h.v1
		var v2: Vector2 = h.v2

		# Scale eigenvalue visualization
		var scale := 0.3
		var len1 := clampf(abs(l1) * _y_scale * 2.0, 0.05, 0.8) * scale
		var len2 := clampf(abs(l2) * _y_scale * 2.0, 0.05, 0.8) * scale

		var c1 := COL_HESSIAN_P if l1 >= 0 else COL_HESSIAN_N
		var c2 := COL_HESSIAN_P if l2 >= 0 else COL_HESSIAN_N

		# Draw eigenvector 1
		var e1a := center + Vector3(v1.x, 0, v1.y) * len1
		var e1b := center - Vector3(v1.x, 0, v1.y) * len1
		_im_line_3d(_hessian_im, e1a, e1b, c1, 0.025)

		# Draw eigenvector 2
		var e2a := center + Vector3(v2.x, 0, v2.y) * len2
		var e2b := center - Vector3(v2.x, 0, v2.y) * len2
		_im_line_3d(_hessian_im, e2a, e2b, c2, 0.025)

	_hessian_im.surface_end()

func _draw_hessian_markers() -> void:
	_markers_im.clear_surfaces()
	_markers_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for h in _hessian_grid:
		var pos: Vector2 = h.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		var l1: float = h.l1
		var l2: float = h.l2
		# Color by definiteness: both positive = blue, mixed = yellow, both negative = red
		var col: Color
		if l1 >= 0 and l2 >= 0:
			col = COL_HESSIAN_P
		elif l1 < 0 and l2 < 0:
			col = COL_HESSIAN_N
		else:
			col = Color(0.9, 0.8, 0.2, 0.9)  # saddle = yellow
		_im_diamond(_markers_im, Vector3(pos.x, y, pos.y), 0.06, col)

	_markers_im.surface_end()

# ════════════════════════════════════════════════════════════════════════
#  IMMEDIATE MESH HELPERS
# ════════════════════════════════════════════════════════════════════════

func _im_line_3d(im: ImmediateMesh, a: Vector3, b: Vector3, col: Color, w: float) -> void:
	var dir := (b - a)
	if dir.length_squared() < 1e-8:
		return
	dir = dir.normalized()
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.FORWARD
	var side := dir.cross(up).normalized() * w * 0.5
	var u := up.cross(dir).normalized() * w * 0.5

	# Quad 1 (horizontal)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(a - side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(a + side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(b + side)

	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(a - side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(b + side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(b - side)

	# Quad 2 (vertical)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(a - u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(a + u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(b + u)

	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(a - u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(b + u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(b - u)

func _im_diamond(im: ImmediateMesh, center: Vector3, size: float, col: Color) -> void:
	var s := size
	var top := center + Vector3(0, s, 0)
	var bot := center - Vector3(0, s * 0.5, 0)
	var pts := [
		center + Vector3(s, 0, 0),
		center + Vector3(0, 0, s),
		center + Vector3(-s, 0, 0),
		center + Vector3(0, 0, -s),
	]
	for i in 4:
		var next := (i + 1) % 4
		# Upper face
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(top)
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(pts[i])
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(pts[next])
		# Lower face
		im.surface_set_color(col * 0.7)
		im.surface_set_normal(-Vector3.UP)
		im.surface_add_vertex(bot)
		im.surface_set_color(col * 0.7)
		im.surface_set_normal(-Vector3.UP)
		im.surface_add_vertex(pts[next])
		im.surface_set_color(col * 0.7)
		im.surface_set_normal(-Vector3.UP)
		im.surface_add_vertex(pts[i])

# ════════════════════════════════════════════════════════════════════════
#  LABELS
# ════════════════════════════════════════════════════════════════════════

func _update_labels() -> void:
	var mode_names := ["Optimizer Variants", "Convergence Analysis", "Hessian Eigenvalues"]
	_title_label.text = "Gradient Descent — " + mode_names[_mode]

	match _mode:
		Mode.OPTIMIZERS:
			var lines := "f(x,y) = %s  |  lr=%.4f  β=%.2f  step=%d" % [_fn_name(), learning_rate, momentum_beta, _step_count]
			for opt in _optimizers:
				var status := "converged" if opt.converged else "f=%.4f" % [opt.value as float]
				lines += "\n%s: (%.2f, %.2f) %s" % [opt.name, (opt.pos as Vector2).x, (opt.pos as Vector2).y, status]
			_info_label.text = lines
			_legend_label.text = "Red=SGD  Green=Momentum  Blue=Nesterov  Gold=Adam"

		Mode.CONVERGENCE:
			var lines := "Adam on %s  |  β₁=%.2f  β₂=%.3f  step=%d" % [_fn_name(), adam_beta1, adam_beta2, _step_count]
			for run in _conv_runs:
				var val := _eval(run.pos as Vector2)
				lines += "\nlr=%.3f: f=%.4f%s" % [run.lr as float, val, " ✓" if run.converged else ""]
			_info_label.text = lines
			_legend_label.text = "5 learning rates compared — log(f) chart on right"

		Mode.HESSIAN:
			_info_label.text = "f(x,y) = %s  |  Hessian at %d×%d grid points\nBlue=positive definite  Red=negative  Yellow=saddle" % [_fn_name(), 9, 9]
			_legend_label.text = "Line length ~ |eigenvalue|  Direction = eigenvector"

# ════════════════════════════════════════════════════════════════════════
#  GRID CONFIG
# ════════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	if config.has("function_preset"):
		var fp = config["function_preset"]
		if fp is int:
			function_preset = clampi(fp, 0, 2)
		elif fp is String:
			match (fp as String).to_lower():
				"quadratic", "bowl": function_preset = 0
				"rosenbrock": function_preset = 1
				"himmelblau": function_preset = 2

	if config.has("learning_rate"):
		learning_rate = clampf(float(config["learning_rate"]), 0.0001, 0.5)
	if config.has("momentum_beta"):
		momentum_beta = clampf(float(config["momentum_beta"]), 0.0, 0.999)
	if config.has("adam_beta1"):
		adam_beta1 = clampf(float(config["adam_beta1"]), 0.0, 0.999)
	if config.has("adam_beta2"):
		adam_beta2 = clampf(float(config["adam_beta2"]), 0.0, 0.9999)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 10.0)

	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"OPTIMIZERS": _mode = Mode.OPTIMIZERS
			"CONVERGENCE": _mode = Mode.CONVERGENCE
			"HESSIAN": _mode = Mode.HESSIAN

	_init_mode()
