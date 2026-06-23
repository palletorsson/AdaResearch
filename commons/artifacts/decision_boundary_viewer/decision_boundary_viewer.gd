extends Node3D
class_name DecisionBoundaryViewer

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Decision Boundary Viewer — 2D classification with live decision boundary.
## Generates two clusters of points (class A and class B) on a 128x128 floor quad.
## A linear classifier (w1*x + w2*y + bias > 0) separates them. Background is
## colored by classification region (light blue vs light red). VR sliders control
## w1, w2, and bias. Label3D shows live accuracy %.

# @identity
# essence: a floor plot scattered with two clusters of dots — class A and class B
#   — divided by a single straight line you steer with three sliders. The line is
#   w1*x + w2*y + bias = 0; everything on one side is called blue, the other red,
#   and the accuracy label tells you how many dots the line got right. It is the
#   LINEAR CLASSIFIER laid bare: learning reduced to placing one cut.
# desire: to demystify "the model decides" by letting you BE the model. The
#   viewer wants to show that a classifier is nothing but a boundary, that
#   training is just moving that boundary to reduce error, and that some clusters
#   simply cannot be split by a line — making the need for non-linear models felt,
#   not asserted.
# critical_parameter: the weight vector (w1, w2) and bias together — w1 and w2
#   set the line's ANGLE (its normal direction), bias sets its OFFSET from origin.
#   These three numbers ARE the model; everything the classifier knows lives in
#   them, and dragging a slider is gradient descent done by hand.
# triggers: slider callbacks update w1/w2/bias and recompute the region texture,
#   reclassify every point, and refresh the accuracy label; _ready seeds the two
#   clusters and builds the plot quad
# emerges: a well-placed line reads SEPARATED / HIGH-ACCURACY; a bad angle reads
#   CONFUSED / CHANCE; overlapping clusters read NOT-LINEARLY-SEPARABLE no matter
#   the line. Same dots, the three weights ARE the decision
# relationships: sibling to other machinelearning artifacts (all make a learned
#   function visible); cousin to graph_coloring (both partition a set under a
#   rule, here a geometric cut instead of a conflict constraint); peer to any
#   threshold or boundary artifact where a single parameter divides a continuum
# truth: a linear classifier is the rule that two classes are separated by a
#   hyperplane defined by a weight vector and a bias, and classification is just
#   the sign of w·x + b. This viewer shows the rule's reach and its limit at once:
#   when the dots interleave, no line is right, and accuracy below 100% is not the
#   model failing — it is the data refusing to be linear.

# --- Configuration ---

@export var plot_size: float = 0.7
@export var plot_resolution: int = 128
@export var num_points_per_class: int = 30

# --- Colors ---

var color_region_a: Color = Color(0.15, 0.22, 0.42)   # Dark blue region (class 0)
var color_region_b: Color = Color(0.42, 0.15, 0.15)    # Dark red region (class 1)
var color_dot_a: Color = Color(0.3, 0.6, 1.0)          # Bright blue dots
var color_dot_b: Color = Color(1.0, 0.35, 0.25)        # Bright red dots
var color_boundary: Color = Color(1.0, 1.0, 0.3)       # Yellow boundary line
var color_misclassified: Color = Color(1.0, 1.0, 1.0)  # White ring for errors

# --- Classifier state ---

var w1: float = 1.0
var w2: float = -0.8
var bias: float = 0.0

# --- Sliders ---

var _w1_slider
var _w2_slider
var _bias_slider

# --- Internal ---

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _data_points: Array = []  # [{pos: Vector2, true_class: int}]
var _plot_mesh: MeshInstance3D
var _plot_material: StandardMaterial3D
var _accuracy_label: Label3D
var _title_label: Label3D
var _formula_label: Label3D


func _ready() -> void:
	_rng.seed = 77
	_generate_data_points()
	_build_plot()
	_build_labels()
	_setup_sliders()
	_update_plot()


# --- Data generation: two Gaussian clusters ---

func _generate_data_points() -> void:
	_data_points.clear()
	# Cluster A: centered around (-0.45, -0.35)
	var center_a = Vector2(-0.45, -0.35)
	for i in range(num_points_per_class):
		var x = center_a.x + _rng.randfn(0.0, 0.25)
		var y = center_a.y + _rng.randfn(0.0, 0.25)
		x = clampf(x, -0.95, 0.95)
		y = clampf(y, -0.95, 0.95)
		_data_points.append({"pos": Vector2(x, y), "true_class": 0})

	# Cluster B: centered around (0.45, 0.35)
	var center_b = Vector2(0.45, 0.35)
	for i in range(num_points_per_class):
		var x = center_b.x + _rng.randfn(0.0, 0.25)
		var y = center_b.y + _rng.randfn(0.0, 0.25)
		x = clampf(x, -0.95, 0.95)
		y = clampf(y, -0.95, 0.95)
		_data_points.append({"pos": Vector2(x, y), "true_class": 1})


# --- Floor quad with procedural texture ---

func _build_plot() -> void:
	_plot_mesh = MeshInstance3D.new()
	_plot_mesh.name = "PlotMesh"
	var quad = QuadMesh.new()
	quad.size = Vector2(plot_size, plot_size)
	_plot_mesh.mesh = quad

	# Floor-lying
	_plot_mesh.rotation_degrees.x = -90
	_plot_mesh.position.y = 0.005

	_plot_material = StandardMaterial3D.new()
	_plot_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_plot_material.roughness = 0.85
	_plot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_plot_mesh.material_override = _plot_material
	add_child(_plot_mesh)


func _update_plot() -> void:
	var img = Image.create(plot_resolution, plot_resolution, false, Image.FORMAT_RGBA8)

	# Paint classification regions
	for py in range(plot_resolution):
		for px in range(plot_resolution):
			var nx = remap(float(px), 0, plot_resolution - 1, -1.0, 1.0)
			var ny = remap(float(py), 0, plot_resolution - 1, 1.0, -1.0)
			var activation = w1 * nx + w2 * ny + bias

			# Base region color
			var base: Color
			if activation >= 0:
				base = color_region_b
			else:
				base = color_region_a

			# Subtle grid lines
			if px == plot_resolution / 2 or py == plot_resolution / 2:
				base = base.lightened(0.12)

			img.set_pixel(px, py, base)

	# Draw decision boundary (yellow band where activation ~ 0)
	for py in range(plot_resolution):
		for px in range(plot_resolution):
			var nx = remap(float(px), 0, plot_resolution - 1, -1.0, 1.0)
			var ny = remap(float(py), 0, plot_resolution - 1, 1.0, -1.0)
			var activation = w1 * nx + w2 * ny + bias
			var dist = absf(activation)
			if dist < 0.08:
				var t = 1.0 - dist / 0.08
				var boundary_col = Color(
					color_boundary.r * t * 0.5,
					color_boundary.g * t * 0.5,
					color_boundary.b * t * 0.15,
					1.0
				)
				var existing = img.get_pixel(px, py)
				img.set_pixel(px, py, existing + boundary_col)

	# Draw data points as 3x3 dots
	var correct = 0
	for point in _data_points:
		var px_f = remap(point["pos"].x, -1.0, 1.0, 0, plot_resolution - 1)
		var py_f = remap(point["pos"].y, -1.0, 1.0, plot_resolution - 1, 0)
		var px_i = clampi(int(px_f), 1, plot_resolution - 2)
		var py_i = clampi(int(py_f), 1, plot_resolution - 2)

		var predicted = 1 if (w1 * point["pos"].x + w2 * point["pos"].y + bias) >= 0 else 0
		if predicted == point["true_class"]:
			correct += 1

		# Color by TRUE class so clusters are visually consistent
		var dot_color = color_dot_b if point["true_class"] == 1 else color_dot_a
		var misclassified = predicted != point["true_class"]

		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var cx = clampi(px_i + dx, 0, plot_resolution - 1)
				var cy = clampi(py_i + dy, 0, plot_resolution - 1)
				if misclassified and (abs(dx) + abs(dy) == 2):
					img.set_pixel(cx, cy, color_misclassified)
				else:
					img.set_pixel(cx, cy, dot_color)

	var texture = ImageTexture.create_from_image(img)
	_plot_material.albedo_texture = texture

	# Update accuracy label
	var accuracy = float(correct) / max(1, _data_points.size()) * 100.0
	if _accuracy_label:
		_accuracy_label.text = "Accuracy: %.0f%% (%d/%d)" % [accuracy, correct, _data_points.size()]
	if _formula_label:
		_formula_label.text = "%.2f*x + %.2f*y + %.2f = 0" % [w1, w2, bias]


# --- Labels ---

func _build_labels() -> void:
	# Title — a framed 2D-in-3D sign on a STALK standing up at the back edge (mounted, not flat text).
	var title := HangarKit.signage("DECISION BOUNDARY", [], Vector2(plot_size * 0.55, 0.12), 0.22, Vector3(0, 1, 0))
	title.position = Vector3(0, 0.0, -plot_size * 0.5 - 0.05)
	add_child(title)

	_formula_label = Label3D.new()
	_formula_label.name = "FormulaLabel"
	_formula_label.text = "%.2f*x + %.2f*y + %.2f = 0" % [w1, w2, bias]
	_formula_label.font_size = 14
	_formula_label.pixel_size = 0.001
	_formula_label.position = Vector3(0, 0.005, -plot_size * 0.5 - 0.07)
	_formula_label.rotation_degrees.x = -90
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.modulate = Color(0.75, 0.75, 0.55)
	_formula_label.outline_size = 2
	_formula_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_formula_label)

	_accuracy_label = Label3D.new()
	_accuracy_label.name = "AccuracyLabel"
	_accuracy_label.text = "Accuracy: --"
	_accuracy_label.font_size = 18
	_accuracy_label.pixel_size = 0.001
	_accuracy_label.position = Vector3(0, 0.005, plot_size * 0.5 + 0.04)
	_accuracy_label.rotation_degrees.x = -90
	_accuracy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accuracy_label.modulate = Color(0.5, 0.9, 0.55)
	_accuracy_label.outline_size = 3
	_accuracy_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_accuracy_label)


# --- Slider setup ---

func _setup_sliders() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("CLASSIFIER WEIGHTS", [
		[{"type": "slider_h", "label": "W1", "default": remap(w1, -3.0, 3.0, 0.0, 1.0)}],
		[{"type": "slider_h", "label": "W2", "default": remap(w2, -3.0, 3.0, 0.0, 1.0)}],
		[{"type": "slider_h", "label": "BIAS", "default": remap(bias, -2.0, 2.0, 0.0, 1.0)}],
	])
	panel.position = Vector3(plot_size * 0.5 + 0.15, 0.0, 0.0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	_w1_slider = panel.find_child("Param_0", true, false)
	_w2_slider = panel.find_child("Param_1", true, false)
	_bias_slider = panel.find_child("Param_2", true, false)

	if _w1_slider and _w1_slider.has_signal("slider_moved"):
		_w1_slider.slider_moved.connect(_on_w1_changed)
	if _w2_slider and _w2_slider.has_signal("slider_moved"):
		_w2_slider.slider_moved.connect(_on_w2_changed)
	if _bias_slider and _bias_slider.has_signal("slider_moved"):
		_bias_slider.slider_moved.connect(_on_bias_changed)


# --- Slider callbacks ---

func _on_w1_changed(_value) -> void:
	if _w1_slider:
		w1 = lerp(-3.0, 3.0, _w1_slider.get_normalized_value())
		_update_plot()

func _on_w2_changed(_value) -> void:
	if _w2_slider:
		w2 = lerp(-3.0, 3.0, _w2_slider.get_normalized_value())
		_update_plot()

func _on_bias_changed(_value) -> void:
	if _bias_slider:
		bias = lerp(-2.0, 2.0, _bias_slider.get_normalized_value())
		_update_plot()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("w1"):
		w1 = float(config_data["w1"])
	if config_data.has("w2"):
		w2 = float(config_data["w2"])
	if config_data.has("bias"):
		bias = float(config_data["bias"])
	if config_data.has("num_points_per_class"):
		num_points_per_class = int(config_data["num_points_per_class"])
		_generate_data_points()
	_update_plot()
