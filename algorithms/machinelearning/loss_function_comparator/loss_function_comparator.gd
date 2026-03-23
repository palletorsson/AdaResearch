# loss_function_comparator.gd
# Same dataset, three different loss functions applied simultaneously.
# Left: MSE loss landscape (smooth bowl, single minimum).
# Center: Huber loss (robust to outliers, flat bottom).
# Right: Custom adversarial loss (multiple minima, deceptive valleys).
# A gradient descent ball rolls on each surface.
# The point: the "answer" depends entirely on which loss function you chose.
#
# @identity
#   essence: three landscapes from one dataset — the loss function is the author
#   desire: players see that optimization answers depend on the question you formalize
#   critical_parameter: outlier_fraction — how many data points are outliers
#   triggers: instantiation, dataset perturbation slider
#   emerges: the insight that loss functions are not discovered but designed
#   needs: [implemented] 3 terrain meshes, gradient descent balls, Label3D equations, controls
#   relationships: gradient_descent_landscape (single loss), optimization_algorithms (optimizer comparison)
#   truth: the landscape is not given — it is authored

extends Node3D
class_name LossFunctionComparator

# --- Configuration ---
@export var terrain_resolution: int = 32
@export var terrain_size: float = 0.5
@export var terrain_height_scale: float = 0.15
@export var ball_radius: float = 0.012
@export var learning_rate: float = 0.02
@export var spacing: float = 0.6
@export var outlier_fraction: float = 0.15

# --- Internal ---
var _terrains: Array[MeshInstance3D] = []
var _terrain_materials: Array[StandardMaterial3D] = []
var _balls: Array[MeshInstance3D] = []
var _ball_positions: Array[Vector2] = []  # param space (x, z)
var _trail_points: Array[Array] = [[], [], []]
var _trail_meshes: Array[MeshInstance3D] = []
var _labels: Array[Label3D] = []
var _equation_labels: Array[Label3D] = []
var _title_label: Label3D
var _subtitle_label: Label3D

var _loss_names: Array[String] = ["MSE Loss", "Huber Loss", "Adversarial Loss"]
var _loss_equations: Array[String] = [
	"L = (1/n) sum (y - y_hat)^2",
	"L = Huber(delta=1.0)",
	"L = sum sin(3*e) + 0.5*e^2"
]
var _loss_colors: Array[Color] = [
	Color(0.3, 0.6, 0.9),   # Blue — MSE
	Color(0.4, 0.8, 0.45),  # Green — Huber
	Color(0.9, 0.35, 0.35), # Red — Adversarial
]

# Dataset
var _data_x: Array[float] = []
var _data_y: Array[float] = []
var _rng := RandomNumberGenerator.new()

var _controls: Node
var _running: bool = true
var _step_timer: float = 0.0
var _step_interval: float = 0.08


func _ready() -> void:
	_rng.seed = 123
	_generate_dataset()
	_create_terrains()
	_create_balls()
	_create_labels()
	_create_title()
	_create_controls()


func apply_grid_config(config: Dictionary) -> void:
	pass


# ------------------------------------------------------------------
# Dataset generation
# ------------------------------------------------------------------

func _generate_dataset() -> void:
	_data_x.clear()
	_data_y.clear()
	var n := 20
	for i in range(n):
		var x := float(i) / (n - 1) * 2.0 - 1.0
		_data_x.append(x)
		# True relationship: y = 0.5x + noise
		var noise := _rng.randf_range(-0.2, 0.2)
		if _rng.randf() < outlier_fraction:
			noise = _rng.randf_range(1.5, 3.0) * (1 if _rng.randf() > 0.5 else -1)
		_data_y.append(0.5 * x + noise)


# ------------------------------------------------------------------
# Loss functions over 2D parameter space (w, b) for y = w*x + b
# ------------------------------------------------------------------

func _mse_loss(w: float, b: float) -> float:
	var total := 0.0
	for i in range(_data_x.size()):
		var e: float = _data_y[i] - (w * _data_x[i] + b)
		total += e * e
	return total / _data_x.size()


func _huber_loss(w: float, b: float) -> float:
	var total := 0.0
	var delta := 1.0
	for i in range(_data_x.size()):
		var e: float = absf(_data_y[i] - (w * _data_x[i] + b))
		if e <= delta:
			total += 0.5 * e * e
		else:
			total += delta * (e - 0.5 * delta)
	return total / _data_x.size()


func _adversarial_loss(w: float, b: float) -> float:
	var total := 0.0
	for i in range(_data_x.size()):
		var e: float = _data_y[i] - (w * _data_x[i] + b)
		total += sin(3.0 * e) + 0.5 * e * e
	return total / _data_x.size()


func _eval_loss(loss_idx: int, w: float, b: float) -> float:
	match loss_idx:
		0: return _mse_loss(w, b)
		1: return _huber_loss(w, b)
		2: return _adversarial_loss(w, b)
	return 0.0


# ------------------------------------------------------------------
# Terrain meshes
# ------------------------------------------------------------------

func _create_terrains() -> void:
	for t in range(3):
		var mesh := _build_terrain_mesh(t)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh

		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_terrain_materials.append(mat)
		mi.material_override = mat

		mi.position = Vector3((t - 1) * spacing, 0, 0)
		add_child(mi)
		_terrains.append(mi)


func _build_terrain_mesh(loss_idx: int) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var res := terrain_resolution
	var half := terrain_size * 0.5

	# Parameter ranges: w in [-2, 2], b in [-2, 2]
	var param_min := -2.0
	var param_max := 2.0
	var param_range := param_max - param_min

	# Find min/max loss for color normalization
	var min_loss := INF
	var max_loss := -INF
	var loss_grid: Array = []
	loss_grid.resize(res + 1)

	for ix in range(res + 1):
		loss_grid[ix] = []
		loss_grid[ix].resize(res + 1)
		for iz in range(res + 1):
			var w := param_min + (float(ix) / res) * param_range
			var b := param_min + (float(iz) / res) * param_range
			var loss := _eval_loss(loss_idx, w, b)
			loss_grid[ix][iz] = loss
			min_loss = minf(min_loss, loss)
			max_loss = maxf(max_loss, loss)

	var loss_range := max_loss - min_loss
	if loss_range < 0.001:
		loss_range = 1.0

	# Build mesh
	for ix in range(res):
		for iz in range(res):
			# Quad: two triangles
			for tri in range(2):
				var offsets: Array
				if tri == 0:
					offsets = [[0, 0], [1, 0], [1, 1]]
				else:
					offsets = [[0, 0], [1, 1], [0, 1]]

				for off in offsets:
					var gx: int = ix + off[0]
					var gz: int = iz + off[1]
					var norm_loss: float = (loss_grid[gx][gz] - min_loss) / loss_range
					var height := norm_loss * terrain_height_scale

					var px := -half + (float(gx) / res) * terrain_size
					var pz := -half + (float(gz) / res) * terrain_size

					# Color: green at minima, red at peaks
					var base_color: Color = _loss_colors[loss_idx]
					var col := base_color.lerp(Color(0.15, 0.12, 0.1), norm_loss * 0.7)
					col = col.lerp(Color(1, 1, 1), (1.0 - norm_loss) * 0.3)

					st.set_color(col)
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(px, height, pz))

	st.generate_normals()
	return st.commit()


# ------------------------------------------------------------------
# Gradient descent balls
# ------------------------------------------------------------------

func _create_balls() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = ball_radius
	mesh.height = ball_radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6

	for t in range(3):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1)
		mat.emission_enabled = true
		mat.emission = _loss_colors[t]
		mat.emission_energy_multiplier = 1.5
		mi.material_override = mat
		add_child(mi)
		_balls.append(mi)

		# Start at a random-ish position in param space
		_ball_positions.append(Vector2(1.5, 1.0))

		# Trail mesh placeholder
		var trail_mi := MeshInstance3D.new()
		add_child(trail_mi)
		_trail_meshes.append(trail_mi)

	_update_ball_visuals()


func _update_ball_visuals() -> void:
	var half := terrain_size * 0.5
	var param_min := -2.0
	var param_range := 4.0

	for t in range(3):
		var bp: Vector2 = _ball_positions[t]
		var norm_x := (bp.x - param_min) / param_range
		var norm_z := (bp.y - param_min) / param_range
		var px := -half + norm_x * terrain_size
		var pz := -half + norm_z * terrain_size
		var loss := _eval_loss(t, bp.x, bp.y)
		var min_l := _eval_loss(t, 0.5, 0.0)  # rough estimate
		var max_l := _eval_loss(t, 2.0, 2.0)
		var norm_loss := clampf((loss - min_l) / maxf(max_l - min_l, 0.001), 0.0, 1.0)
		var height := norm_loss * terrain_height_scale + ball_radius

		_balls[t].position = Vector3(
			(t - 1) * spacing + px,
			height,
			pz
		)


# ------------------------------------------------------------------
# Gradient descent step (numerical gradient)
# ------------------------------------------------------------------

func _gradient_step(loss_idx: int) -> void:
	var bp: Vector2 = _ball_positions[loss_idx]
	var eps := 0.01
	var loss_center := _eval_loss(loss_idx, bp.x, bp.y)
	var dw := (_eval_loss(loss_idx, bp.x + eps, bp.y) - loss_center) / eps
	var db := (_eval_loss(loss_idx, bp.x, bp.y + eps) - loss_center) / eps

	bp.x -= learning_rate * dw
	bp.y -= learning_rate * db

	# Clamp to param space
	bp.x = clampf(bp.x, -2.0, 2.0)
	bp.y = clampf(bp.y, -2.0, 2.0)

	_ball_positions[loss_idx] = bp
	_trail_points[loss_idx].append(bp)


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	for t in range(3):
		var lbl := Label3D.new()
		lbl.text = _loss_names[t]
		lbl.font_size = 16
		lbl.modulate = _loss_colors[t]
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3((t - 1) * spacing, terrain_height_scale + 0.08, 0)
		lbl.pixel_size = 0.001
		add_child(lbl)
		_labels.append(lbl)

		var eq_lbl := Label3D.new()
		eq_lbl.text = _loss_equations[t]
		eq_lbl.font_size = 11
		eq_lbl.modulate = _loss_colors[t].lerp(Color.WHITE, 0.3)
		eq_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		eq_lbl.position = Vector3((t - 1) * spacing, terrain_height_scale + 0.04, 0)
		eq_lbl.pixel_size = 0.001
		add_child(eq_lbl)
		_equation_labels.append(eq_lbl)


func _create_title() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Loss Function Comparator"
	_title_label.font_size = 22
	_title_label.modulate = Color(1, 1, 1, 0.9)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 0.4, 0)
	_title_label.pixel_size = 0.001
	add_child(_title_label)

	_subtitle_label = Label3D.new()
	_subtitle_label.text = "Same data. Three loss functions. Three different answers."
	_subtitle_label.font_size = 14
	_subtitle_label.modulate = Color(0.8, 0.75, 0.7, 0.8)
	_subtitle_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_subtitle_label.position = Vector3(0, 0.35, 0)
	_subtitle_label.pixel_size = 0.001
	add_child(_subtitle_label)


# ------------------------------------------------------------------
# Controls
# ------------------------------------------------------------------

func _create_controls() -> void:
	var slider_scene = load("res://commons/interactables/slider_horizontal.tscn")
	if slider_scene == null:
		return

	_controls = Node3D.new()
	_controls.name = "ArtifactControls"
	add_child(_controls)

	# Outlier fraction slider
	var slider := slider_scene.instantiate()
	slider.position = Vector3(0, 0.02, terrain_size * 0.5 + 0.15)
	slider.rotation_degrees.y = 180
	_controls.add_child(slider)

	var label_node = slider.get_node_or_null("Frame/LabelName")
	if label_node:
		label_node.text = "Outliers"
	slider.set_param_name("Outliers")
	slider.set_normalized_value(outlier_fraction / 0.5)  # 0-0.5 range
	slider.slider_moved.connect(_on_outlier_changed)

	# Reset button
	var btn_scene = load("res://commons/interactables/push_button.tscn")
	if btn_scene:
		var btn := btn_scene.instantiate()
		btn.position = Vector3(0.2, 0.02, terrain_size * 0.5 + 0.15)
		_controls.add_child(btn)
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_reset_pressed)


func _on_outlier_changed(value: float) -> void:
	outlier_fraction = value * 0.5
	_regenerate()


func _on_reset_pressed() -> void:
	_regenerate()


func _regenerate() -> void:
	_generate_dataset()
	# Rebuild terrain meshes
	for t in range(3):
		_terrains[t].mesh = _build_terrain_mesh(t)
	# Reset balls
	for t in range(3):
		_ball_positions[t] = Vector2(1.5, 1.0)
		_trail_points[t].clear()
	_update_ball_visuals()


# ------------------------------------------------------------------
# Process
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _running:
		return

	_step_timer += delta
	if _step_timer >= _step_interval:
		_step_timer = 0.0
		for t in range(3):
			_gradient_step(t)
		_update_ball_visuals()
