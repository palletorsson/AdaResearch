extends Node3D
class_name PerceptronPlayground

## Perceptron Playground — single neuron with adjustable weights (w1, w2, bias).
## Draws a 2D scatter plot of two classes on a QuadMesh, with a decision boundary
## line (w1*x + w2*y + bias = 0) that updates in real-time as sliders change.
## ImmediateMesh neuron diagram shows inputs, weights, and output.

# --- Configuration ---

@export var w1_slider_path: NodePath = "ControlPanel/W1Slider"
@export var w2_slider_path: NodePath = "ControlPanel/W2Slider"
@export var bias_slider_path: NodePath = "ControlPanel/BiasSlider"

@export var plot_size: float = 0.5
@export var plot_resolution: int = 128
@export var num_points: int = 60

# --- Colors ---

var color_class_a: Color = Color(0.2, 0.6, 1.0)    # Blue — class 0
var color_class_b: Color = Color(1.0, 0.35, 0.2)    # Red — class 1
var color_boundary: Color = Color(1.0, 1.0, 0.3)    # Yellow — decision boundary
var color_bg: Color = Color(0.08, 0.08, 0.12)       # Dark background
var color_neuron: Color = Color(0.9, 0.95, 1.0)     # White neuron circle
var color_input: Color = Color(0.5, 0.7, 1.0)       # Input lines
var color_output: Color = Color(0.3, 1.0, 0.4)      # Output arrow

# --- Sliders ---

var w1_slider
var w2_slider
var bias_slider

# --- State ---

var w1: float = 1.0
var w2: float = -1.0
var bias: float = 0.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _data_points: Array = []  # [{pos: Vector2, true_class: int}]

# --- Internal nodes ---

var _plot_mesh: MeshInstance3D
var _plot_material: StandardMaterial3D
var _diagram_mesh: MeshInstance3D
var _boundary_mesh: MeshInstance3D
var _w1_label: Label3D
var _w2_label: Label3D
var _bias_label: Label3D
var _output_label: Label3D
var _title_label: Label3D
var _formula_label: Label3D


func _ready() -> void:
	_rng.seed = 42
	_generate_data_points()
	_build_scatter_plot()
	_build_neuron_diagram()
	_build_boundary()
	_build_labels()
	_setup_sliders()
	_update_plot()


# --- Data generation ---

func _generate_data_points() -> void:
	_data_points.clear()
	for i in range(num_points):
		var x = _rng.randf_range(-1.0, 1.0)
		var y = _rng.randf_range(-1.0, 1.0)
		# True separation: class 1 if x + y > 0.1 (with some noise)
		var true_class = 1 if (x + y + _rng.randf_range(-0.3, 0.3)) > 0.1 else 0
		_data_points.append({"pos": Vector2(x, y), "true_class": true_class})


# --- Scatter plot (floor/wall quad with procedural texture) ---

func _build_scatter_plot() -> void:
	_plot_mesh = MeshInstance3D.new()
	_plot_mesh.name = "ScatterPlot"
	var quad = QuadMesh.new()
	quad.size = Vector2(plot_size, plot_size)
	_plot_mesh.mesh = quad
	_plot_mesh.position = Vector3(0, 0, 0.001)

	_plot_material = StandardMaterial3D.new()
	_plot_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_plot_material.roughness = 0.9
	_plot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_plot_mesh.material_override = _plot_material
	add_child(_plot_mesh)


func _update_plot() -> void:
	var img = Image.create(plot_resolution, plot_resolution, false, Image.FORMAT_RGBA8)

	# Fill background with subtle grid
	for py in range(plot_resolution):
		for px in range(plot_resolution):
			var bg = color_bg
			# Subtle grid lines at center
			if px == plot_resolution / 2 or py == plot_resolution / 2:
				bg = Color(0.15, 0.15, 0.2)
			img.set_pixel(px, py, bg)

	# Draw decision boundary region (soft shading)
	for py in range(plot_resolution):
		for px in range(plot_resolution):
			var nx = remap(float(px), 0, plot_resolution - 1, -1.0, 1.0)
			var ny = remap(float(py), 0, plot_resolution - 1, 1.0, -1.0)
			var activation = w1 * nx + w2 * ny + bias
			# Soft shading near boundary
			var dist = absf(activation)
			if dist < 0.15:
				var t = 1.0 - dist / 0.15
				var boundary_shade = Color(
					color_boundary.r * t * 0.25,
					color_boundary.g * t * 0.25,
					color_boundary.b * t * 0.15,
					1.0
				)
				var existing = img.get_pixel(px, py)
				img.set_pixel(px, py, existing + boundary_shade)

	# Draw data points
	for point in _data_points:
		var px_f = remap(point["pos"].x, -1.0, 1.0, 0, plot_resolution - 1)
		var py_f = remap(point["pos"].y, -1.0, 1.0, plot_resolution - 1, 0)
		var px_i = clampi(int(px_f), 1, plot_resolution - 2)
		var py_i = clampi(int(py_f), 1, plot_resolution - 2)

		# Classify with current weights
		var activation = w1 * point["pos"].x + w2 * point["pos"].y + bias
		var predicted_class = 1 if activation >= 0 else 0

		# Color based on predicted class (not true class) so user sees effect
		var color: Color
		if predicted_class == 1:
			color = color_class_b
		else:
			color = color_class_a

		# Outline ring if prediction differs from truth (misclassified)
		var misclassified = predicted_class != point["true_class"]

		# Draw a 3x3 dot
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var cx = clampi(px_i + dx, 0, plot_resolution - 1)
				var cy = clampi(py_i + dy, 0, plot_resolution - 1)
				if misclassified and (abs(dx) + abs(dy) == 2):
					img.set_pixel(cx, cy, Color.WHITE)
				else:
					img.set_pixel(cx, cy, color)

	var texture = ImageTexture.create_from_image(img)
	_plot_material.albedo_texture = texture


# --- Decision boundary line (ImmediateMesh) ---

func _build_boundary() -> void:
	_boundary_mesh = MeshInstance3D.new()
	_boundary_mesh.name = "BoundaryLine"
	_boundary_mesh.position.z = 0.002
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_boundary_mesh.material_override = mat
	add_child(_boundary_mesh)
	_update_boundary()


func _update_boundary() -> void:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Decision boundary: w1*x + w2*y + bias = 0
	# Find intersections with the [-1,1] x [-1,1] domain
	var half = plot_size * 0.5
	var intersections: Array = []

	# Check each edge of the plot
	if absf(w2) > 0.001:
		# y at x = -1 and x = 1
		var y_at_left = -(w1 * -1.0 + bias) / w2
		var y_at_right = -(w1 * 1.0 + bias) / w2
		if y_at_left >= -1.0 and y_at_left <= 1.0:
			intersections.append(Vector2(-1.0, y_at_left))
		if y_at_right >= -1.0 and y_at_right <= 1.0:
			intersections.append(Vector2(1.0, y_at_right))

	if absf(w1) > 0.001:
		# x at y = -1 and y = 1
		var x_at_bottom = -(w2 * -1.0 + bias) / w1
		var x_at_top = -(w2 * 1.0 + bias) / w1
		if x_at_bottom >= -1.0 and x_at_bottom <= 1.0:
			intersections.append(Vector2(x_at_bottom, -1.0))
		if x_at_top >= -1.0 and x_at_top <= 1.0:
			intersections.append(Vector2(x_at_top, 1.0))

	# Remove duplicates (corners)
	var unique: Array = []
	for pt in intersections:
		var is_dup = false
		for u in unique:
			if pt.distance_to(u) < 0.01:
				is_dup = true
				break
		if not is_dup:
			unique.append(pt)

	if unique.size() >= 2:
		# Map from [-1,1] to plot coordinates
		var p0 = Vector3(unique[0].x * half, unique[0].y * half, 0)
		var p1 = Vector3(unique[1].x * half, unique[1].y * half, 0)
		mesh.surface_set_color(color_boundary)
		mesh.surface_add_vertex(p0)
		mesh.surface_set_color(color_boundary)
		mesh.surface_add_vertex(p1)

	mesh.surface_end()
	_boundary_mesh.mesh = mesh


# --- Neuron diagram (ImmediateMesh) ---

func _build_neuron_diagram() -> void:
	_diagram_mesh = MeshInstance3D.new()
	_diagram_mesh.name = "NeuronDiagram"
	_diagram_mesh.position = Vector3(0.45, 0.0, 0.001)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_diagram_mesh.material_override = mat
	add_child(_diagram_mesh)
	_update_diagram()


func _update_diagram() -> void:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Neuron body — circle at center
	var neuron_center = Vector3.ZERO
	var neuron_r = 0.06
	var circle_segs = 24
	for i in range(circle_segs):
		var a0 = TAU * float(i) / circle_segs
		var a1 = TAU * float(i + 1) / circle_segs
		mesh.surface_set_color(color_neuron)
		mesh.surface_add_vertex(neuron_center + Vector3(cos(a0), sin(a0), 0) * neuron_r)
		mesh.surface_set_color(color_neuron)
		mesh.surface_add_vertex(neuron_center + Vector3(cos(a1), sin(a1), 0) * neuron_r)

	# Input lines from left
	var input_x = -0.18
	var in1_pos = Vector3(input_x, 0.08, 0)
	var in2_pos = Vector3(input_x, -0.08, 0)
	var bias_pos = Vector3(0, -0.15, 0)

	# Input 1 line (w1)
	var w1_color = _weight_color(w1)
	mesh.surface_set_color(w1_color)
	mesh.surface_add_vertex(in1_pos)
	mesh.surface_set_color(w1_color)
	mesh.surface_add_vertex(neuron_center + Vector3(-neuron_r * 0.7, neuron_r * 0.4, 0))

	# Input 2 line (w2)
	var w2_color = _weight_color(w2)
	mesh.surface_set_color(w2_color)
	mesh.surface_add_vertex(in2_pos)
	mesh.surface_set_color(w2_color)
	mesh.surface_add_vertex(neuron_center + Vector3(-neuron_r * 0.7, -neuron_r * 0.4, 0))

	# Bias line
	var bias_color = _weight_color(bias)
	mesh.surface_set_color(bias_color)
	mesh.surface_add_vertex(bias_pos)
	mesh.surface_set_color(bias_color)
	mesh.surface_add_vertex(neuron_center + Vector3(0, -neuron_r, 0))

	# Output arrow to the right
	var out_start = neuron_center + Vector3(neuron_r, 0, 0)
	var out_end = Vector3(0.18, 0, 0)
	mesh.surface_set_color(color_output)
	mesh.surface_add_vertex(out_start)
	mesh.surface_set_color(color_output)
	mesh.surface_add_vertex(out_end)

	# Arrowhead
	var arrow_len = 0.025
	var arrow_w = 0.012
	mesh.surface_set_color(color_output)
	mesh.surface_add_vertex(out_end)
	mesh.surface_set_color(color_output)
	mesh.surface_add_vertex(out_end + Vector3(-arrow_len, arrow_w, 0))
	mesh.surface_set_color(color_output)
	mesh.surface_add_vertex(out_end)
	mesh.surface_set_color(color_output)
	mesh.surface_add_vertex(out_end + Vector3(-arrow_len, -arrow_w, 0))

	mesh.surface_end()
	_diagram_mesh.mesh = mesh


func _weight_color(w: float) -> Color:
	# Positive = blue, negative = red, zero = gray
	var intensity = clampf(absf(w) / 3.0, 0.0, 1.0)
	if w >= 0:
		return color_input.lerp(Color(0.3, 0.5, 1.0), intensity)
	else:
		return Color(0.5, 0.5, 0.5).lerp(Color(1.0, 0.3, 0.3), intensity)


# --- Labels ---

func _build_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "PERCEPTRON"
	_title_label.font_size = 28
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0.15, 0.35, 0.001)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 5
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	# Formula
	_formula_label = Label3D.new()
	_formula_label.name = "FormulaLabel"
	_formula_label.text = "y = step(w1*x1 + w2*x2 + b)"
	_formula_label.font_size = 14
	_formula_label.pixel_size = 0.001
	_formula_label.position = Vector3(0.15, 0.31, 0.001)
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.modulate = Color(0.65, 0.7, 0.8, 0.85)
	_formula_label.outline_size = 2
	_formula_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_formula_label)

	# Weight labels near neuron diagram
	_w1_label = Label3D.new()
	_w1_label.name = "W1Label"
	_w1_label.font_size = 14
	_w1_label.pixel_size = 0.001
	_w1_label.position = Vector3(0.32, 0.1, 0.001)
	_w1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_w1_label.modulate = Color(0.5, 0.7, 1.0)
	_w1_label.outline_size = 2
	_w1_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_w1_label)

	_w2_label = Label3D.new()
	_w2_label.name = "W2Label"
	_w2_label.font_size = 14
	_w2_label.pixel_size = 0.001
	_w2_label.position = Vector3(0.32, -0.06, 0.001)
	_w2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_w2_label.modulate = Color(0.5, 0.7, 1.0)
	_w2_label.outline_size = 2
	_w2_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_w2_label)

	_bias_label = Label3D.new()
	_bias_label.name = "BiasLabel"
	_bias_label.font_size = 14
	_bias_label.pixel_size = 0.001
	_bias_label.position = Vector3(0.45, -0.18, 0.001)
	_bias_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bias_label.modulate = Color(0.8, 0.7, 0.5)
	_bias_label.outline_size = 2
	_bias_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_bias_label)

	# Output / accuracy label
	_output_label = Label3D.new()
	_output_label.name = "OutputLabel"
	_output_label.font_size = 14
	_output_label.pixel_size = 0.001
	_output_label.position = Vector3(0.15, -0.32, 0.001)
	_output_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_output_label.modulate = Color(0.6, 0.9, 0.65)
	_output_label.outline_size = 2
	_output_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_output_label)

	_update_labels()


func _update_labels() -> void:
	if _w1_label:
		_w1_label.text = "x1  w1=%.2f" % w1
	if _w2_label:
		_w2_label.text = "x2  w2=%.2f" % w2
	if _bias_label:
		_bias_label.text = "bias=%.2f" % bias

	# Calculate accuracy
	var correct = 0
	for point in _data_points:
		var activation = w1 * point["pos"].x + w2 * point["pos"].y + bias
		var predicted = 1 if activation >= 0 else 0
		if predicted == point["true_class"]:
			correct += 1
	var accuracy = float(correct) / max(1, _data_points.size()) * 100.0

	if _output_label:
		_output_label.text = "Accuracy: %.0f%% (%d/%d)" % [accuracy, correct, _data_points.size()]

	# Legend
	if _formula_label:
		_formula_label.text = "y = step(%.2f*x1 + %.2f*x2 + %.2f)" % [w1, w2, bias]


# --- Slider setup ---

func _setup_sliders() -> void:
	w1_slider = get_node_or_null(w1_slider_path)
	if w1_slider:
		w1_slider.set_range(-3.0, 3.0)
		w1_slider.set_param_name("w1")
		w1_slider.set_normalized_value(remap(w1, -3.0, 3.0, 0.0, 1.0))
		w1_slider.slider_moved.connect(_on_w1_changed)

	w2_slider = get_node_or_null(w2_slider_path)
	if w2_slider:
		w2_slider.set_range(-3.0, 3.0)
		w2_slider.set_param_name("w2")
		w2_slider.set_normalized_value(remap(w2, -3.0, 3.0, 0.0, 1.0))
		w2_slider.slider_moved.connect(_on_w2_changed)

	bias_slider = get_node_or_null(bias_slider_path)
	if bias_slider:
		bias_slider.set_range(-2.0, 2.0)
		bias_slider.set_param_name("BIAS")
		bias_slider.set_normalized_value(remap(bias, -2.0, 2.0, 0.0, 1.0))
		bias_slider.slider_moved.connect(_on_bias_changed)


# --- Slider callbacks ---

func _on_w1_changed(_value) -> void:
	if w1_slider:
		w1 = lerp(-3.0, 3.0, w1_slider.get_normalized_value())
		_refresh()

func _on_w2_changed(_value) -> void:
	if w2_slider:
		w2 = lerp(-3.0, 3.0, w2_slider.get_normalized_value())
		_refresh()

func _on_bias_changed(_value) -> void:
	if bias_slider:
		bias = lerp(-2.0, 2.0, bias_slider.get_normalized_value())
		_refresh()


func _refresh() -> void:
	_update_plot()
	_update_boundary()
	_update_diagram()
	_update_labels()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("w1"):
		w1 = float(config_data["w1"])
	if config_data.has("w2"):
		w2 = float(config_data["w2"])
	if config_data.has("bias"):
		bias = float(config_data["bias"])
	if config_data.has("num_points"):
		num_points = int(config_data["num_points"])
		_generate_data_points()
	_refresh()
