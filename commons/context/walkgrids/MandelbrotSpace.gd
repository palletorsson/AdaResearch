# MandelbrotSpace.gd - The Mandelbrot set as walkable terrain
# Iteration count becomes elevation. The boundary of the set —
# where computation struggles to decide in/out — becomes the
# highest ridges. Walk along the edge of decidability itself.
#
# "The border between convergence and divergence is infinitely complex."

extends TopologySpace
class_name MandelbrotSpace

@export var center_real: float = -0.5     # Real center of view
@export var center_imag: float = 0.0      # Imaginary center of view
@export var zoom: float = 1.5             # Zoom level (smaller = more zoomed in)
@export var max_iterations: int = 100     # Computation depth
@export var escape_radius: float = 4.0    # Bailout radius squared
@export var interior_height: float = 0.0  # Height for points inside the set
@export var boundary_exaggeration: float = 1.5  # Amplify boundary ridges
@export var smooth_coloring: bool = true  # Smooth iteration count
@export var seed_value: int = 42

# Interesting locations to explore
@export var preset_location: PresetLocation = PresetLocation.FULL_SET

enum PresetLocation {
	FULL_SET,          # The classic view
	SEAHORSE_VALLEY,   # Between main cardioid and period-2 bulb
	ELEPHANT_VALLEY,   # Mini-brots in the antenna
	SPIRAL,            # Double spiral near -0.75
	MINI_BROT,         # A miniature copy of the whole set
	LIGHTNING,         # Filamentary structures
	CUSTOM             # Use manual center/zoom
}

var base_heights: Array = []

func _ready():
	_apply_preset()
	super._ready()

func _apply_preset():
	match preset_location:
		PresetLocation.FULL_SET:
			center_real = -0.5; center_imag = 0.0; zoom = 1.5
		PresetLocation.SEAHORSE_VALLEY:
			center_real = -0.75; center_imag = 0.1; zoom = 0.05
		PresetLocation.ELEPHANT_VALLEY:
			center_real = 0.28; center_imag = 0.008; zoom = 0.015
		PresetLocation.SPIRAL:
			center_real = -0.7463; center_imag = 0.1102; zoom = 0.005
		PresetLocation.MINI_BROT:
			center_real = -1.768; center_imag = 0.001; zoom = 0.02
		PresetLocation.LIGHTNING:
			center_real = -0.170337; center_imag = 1.06506; zoom = 0.006
		PresetLocation.CUSTOM:
			pass

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			# Map grid position to complex plane
			var u = (x / float(resolution) - 0.5) * 2.0 * zoom + center_real
			var v = (z / float(resolution) - 0.5) * 2.0 * zoom + center_imag

			var h = _mandelbrot_height(u, v)
			heights.append(h * height_scale)

	base_heights = heights.duplicate()

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _mandelbrot_height(cr: float, ci: float) -> float:
	"""Calculate normalized iteration count for point (cr, ci)"""
	var zr = 0.0
	var zi = 0.0
	var zr2 = 0.0
	var zi2 = 0.0
	var iter = 0

	while zr2 + zi2 <= escape_radius and iter < max_iterations:
		zi = 2.0 * zr * zi + ci
		zr = zr2 - zi2 + cr
		zr2 = zr * zr
		zi2 = zi * zi
		iter += 1

	if iter == max_iterations:
		# Inside the set
		return interior_height

	# Smooth iteration count (avoids banding)
	var smooth_iter = float(iter)
	if smooth_coloring and iter > 0:
		var log_zn = log(zr2 + zi2) / 2.0
		var nu = log(log_zn / log(2.0)) / log(2.0)
		smooth_iter = float(iter) + 1.0 - nu

	# Normalize to 0-1, then apply boundary exaggeration
	var normalized = smooth_iter / float(max_iterations)

	# The boundary (middle iteration counts) gets exaggerated
	# This creates the dramatic ridges at the set boundary
	var boundary_factor = sin(normalized * PI) * boundary_exaggeration
	return normalized + boundary_factor * normalized

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.1, 0.25)  # Deep purple-black
	material.roughness = 0.4
	material.metallic = 0.6
	material.emission_enabled = true
	material.emission = Color(0.3, 0.15, 0.5) * 0.4
	mesh_instance.material_override = material

# Public API
func set_location(preset: PresetLocation):
	preset_location = preset
	_apply_preset()
	generate_space()

func zoom_in(factor: float = 0.5):
	zoom *= factor
	generate_space()

func zoom_out(factor: float = 2.0):
	zoom *= factor
	generate_space()

func pan(dr: float, di: float):
	center_real += dr * zoom
	center_imag += di * zoom
	generate_space()

func set_iterations(iters: int):
	max_iterations = clampi(iters, 10, 1000)
	generate_space()
