extends Node3D
class_name RejectionSamplingDemo

## Rejection Sampling Demo — visual scatter plot of the accept/reject method.
## Generates ~2000 uniform random (x,y) points inside a bounding rectangle.
## A target distribution curve (Gaussian bell curve) is drawn across the plot.
## Points below the curve are accepted (green), points above are rejected (red).
## Label3D shows acceptance ratio and distribution name.

# --- Configuration ---

@export var plot_size: Vector2 = Vector2(0.8, 0.8)
@export var plot_resolution: int = 256
@export var num_samples: int = 2000
@export var seed_value: int = 42

# Target distribution: Gaussian bell curve
# f(x) = amplitude * exp(-0.5 * ((x - mu) / sigma)^2)
var _mu: float = 0.0
var _sigma: float = 0.25
var _amplitude: float = 0.85  # Peak height in normalized [0,1] y-space

# --- Colors ---

const BG_COLOR: Color = Color(0.04, 0.04, 0.08)
const CURVE_COLOR: Color = Color(0.95, 0.85, 0.3)
const ACCEPTED_COLOR: Color = Color(0.15, 0.85, 0.3)
const REJECTED_COLOR: Color = Color(0.85, 0.15, 0.15)
const AXIS_COLOR: Color = Color(0.2, 0.2, 0.25)
const GRID_COLOR: Color = Color(0.08, 0.08, 0.12)

# --- Internal ---

var _rng: RandomNumberGenerator
var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _stats_label: Label3D
var _title_label: Label3D
var _dist_label: Label3D


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_build_floor_quad()
	_build_labels()
	_generate_plot()


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "PlotMesh"
	var quad := QuadMesh.new()
	quad.size = plot_size
	_mesh_inst.mesh = quad
	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.85
	_material.metallic = 0.0
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)


func _build_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "REJECTION SAMPLING"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.005, -plot_size.y * 0.5 - 0.04)
	_title_label.rotation_degrees.x = -90
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_dist_label = Label3D.new()
	_dist_label.name = "DistLabel"
	_dist_label.text = "Target: Gaussian (mu=0, sigma=0.25)"
	_dist_label.font_size = 14
	_dist_label.pixel_size = 0.001
	_dist_label.position = Vector3(0, 0.005, -plot_size.y * 0.5 - 0.07)
	_dist_label.rotation_degrees.x = -90
	_dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dist_label.modulate = Color(0.75, 0.75, 0.55)
	_dist_label.outline_size = 2
	_dist_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_dist_label)

	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Sampling..."
	_stats_label.font_size = 18
	_stats_label.pixel_size = 0.001
	_stats_label.position = Vector3(0, 0.005, plot_size.y * 0.5 + 0.04)
	_stats_label.rotation_degrees.x = -90
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.modulate = Color(0.5, 0.9, 0.55)
	_stats_label.outline_size = 3
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_stats_label)


## Evaluate the target distribution (normalized Gaussian) at x in [-1, 1]
## Returns a value in [0, 1] where 1 = peak of the distribution.
func _target_pdf(x: float) -> float:
	var z := (x - _mu) / _sigma
	return _amplitude * exp(-0.5 * z * z)


func _generate_plot() -> void:
	var img := Image.create(plot_resolution, plot_resolution, false, Image.FORMAT_RGBA8)
	img.fill(BG_COLOR)

	var res := plot_resolution

	# Draw subtle grid lines
	var grid_step := res / 8
	for i in range(1, 8):
		var coord := i * grid_step
		for j in range(res):
			img.set_pixel(coord, j, GRID_COLOR)
			img.set_pixel(j, coord, GRID_COLOR)

	# Draw axes (center horizontal and vertical)
	var mid_x := res / 2
	var bottom_y := res - 1
	# Vertical center axis
	for py in range(res):
		img.set_pixel(mid_x, py, AXIS_COLOR)
	# Horizontal bottom axis (y=0 line at bottom of plot)
	for px in range(res):
		img.set_pixel(px, bottom_y, AXIS_COLOR)

	# Draw the target distribution curve (2px thick)
	for px in range(res):
		var nx := remap(float(px), 0, res - 1, -1.0, 1.0)
		var pdf_val := _target_pdf(nx)
		# Map pdf_val [0, 1] to pixel y: 1.0 -> top, 0.0 -> bottom
		var py_f := remap(pdf_val, 0.0, 1.0, float(res - 1), 0.0)
		var py_i := clampi(int(py_f), 0, res - 1)
		# Draw 2px wide curve
		for dy in range(-1, 2):
			var cy := clampi(py_i + dy, 0, res - 1)
			img.set_pixel(px, cy, CURVE_COLOR)

	# Fill the area under the curve with a faint color
	for px in range(res):
		var nx := remap(float(px), 0, res - 1, -1.0, 1.0)
		var pdf_val := _target_pdf(nx)
		var py_curve := int(remap(pdf_val, 0.0, 1.0, float(res - 1), 0.0))
		for py in range(py_curve + 2, res):
			var existing := img.get_pixel(px, py)
			# Slight tint under the curve
			var tint := Color(0.06, 0.12, 0.06)
			img.set_pixel(px, py, existing + tint)

	# Generate rejection samples and plot them
	var accepted := 0
	var total := num_samples

	for i in range(total):
		# Uniform random x in [-1, 1], y in [0, 1]
		var rx := _rng.randf() * 2.0 - 1.0
		var ry := _rng.randf()

		var pdf_val := _target_pdf(rx)
		var is_accepted := ry < pdf_val

		if is_accepted:
			accepted += 1

		# Map to pixel coordinates
		var px_f := remap(rx, -1.0, 1.0, 0, res - 1)
		var py_f := remap(ry, 0.0, 1.0, float(res - 1), 0.0)
		var px_i := clampi(int(px_f), 0, res - 1)
		var py_i := clampi(int(py_f), 0, res - 1)

		var dot_color: Color
		if is_accepted:
			dot_color = ACCEPTED_COLOR
		else:
			dot_color = REJECTED_COLOR

		# Draw single-pixel dot (dense scatter at 256x256 with 2000 points)
		img.set_pixel(px_i, py_i, dot_color)

	var texture := ImageTexture.create_from_image(img)
	_material.albedo_texture = texture

	# Update stats
	var ratio := float(accepted) / max(1, total) * 100.0
	if _stats_label:
		_stats_label.text = "Accepted: %d/%d (%.1f%%)" % [accepted, total, ratio]


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_samples"):
		num_samples = int(config_data["num_samples"])
	if config_data.has("seed"):
		seed_value = int(config_data["seed"])
		_rng.seed = seed_value
	if config_data.has("sigma"):
		_sigma = float(config_data["sigma"])
	if config_data.has("amplitude"):
		_amplitude = float(config_data["amplitude"])
	_generate_plot()
