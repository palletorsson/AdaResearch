# TorusSpace.gd - Toroidal topology as walkable terrain
# A torus unwrapped onto a flat plane — but the height field preserves
# the curvature information. Walk across and feel the inner ring
# (compressed, tall) vs outer ring (stretched, flat). Periodic
# boundary conditions mean walking off one edge brings you back.
#
# "A donut is just a coffee cup that forgot what it was."

extends TopologySpace
class_name TorusSpace

@export var major_radius: float = 6.0     # Distance from center to tube center
@export var minor_radius: float = 2.0     # Tube radius
@export var height_mode: TorusHeightMode = TorusHeightMode.GAUSSIAN_CURVATURE

enum TorusHeightMode {
	GAUSSIAN_CURVATURE,  # Height = local curvature (positive inner, negative outer)
	ELEVATION,           # Z-coordinate of the torus surface (saddle-like)
	MERIDIAN_WAVES,      # Sine waves along meridians
	PARALLEL_WAVES,      # Sine waves along parallels
	VILLARCEAU_CIRCLES,  # Oblique cross-sections create linked circles
	FLAT_TORUS,          # Clifford torus — intrinsically flat (height from embedding)
}

# Detail parameters
@export var wave_frequency: float = 3.0
@export var wave_amplitude: float = 0.5

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			# Map grid to torus parameters
			# u = angle around the tube (0 to 2PI)
			# v = angle around the ring (0 to 2PI)
			var u = (x / float(resolution)) * TAU
			var v = (z / float(resolution)) * TAU

			var h = _compute_torus_height(u, v)
			heights.append(h * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _compute_torus_height(u: float, v: float) -> float:
	match height_mode:
		TorusHeightMode.GAUSSIAN_CURVATURE:
			return _gaussian_curvature(u, v)
		TorusHeightMode.ELEVATION:
			return _elevation(u, v)
		TorusHeightMode.MERIDIAN_WAVES:
			return _meridian_waves(u, v)
		TorusHeightMode.PARALLEL_WAVES:
			return _parallel_waves(u, v)
		TorusHeightMode.VILLARCEAU_CIRCLES:
			return _villarceau(u, v)
		TorusHeightMode.FLAT_TORUS:
			return _flat_torus(u, v)
	return 0.0

func _gaussian_curvature(u: float, v: float) -> float:
	"""Gaussian curvature K = cos(u) / (R * (R + r*cos(u)))"""
	var R = major_radius
	var r = minor_radius
	var K = cos(u) / (R * (R + r * cos(u)))
	# Normalize to reasonable height
	return K * R * r * 2.0

func _elevation(u: float, v: float) -> float:
	"""Z-coordinate of the torus surface point"""
	# Torus: z = r * sin(u)
	return minor_radius * sin(u)

func _meridian_waves(u: float, v: float) -> float:
	"""Waves along meridians (small circles)"""
	var base = _gaussian_curvature(u, v) * 0.5
	var wave = sin(u * wave_frequency) * wave_amplitude
	return base + wave

func _parallel_waves(u: float, v: float) -> float:
	"""Waves along parallels (large circles)"""
	var base = _gaussian_curvature(u, v) * 0.5
	var wave = sin(v * wave_frequency) * wave_amplitude
	return base + wave

func _villarceau(u: float, v: float) -> float:
	"""Villarceau circles — oblique sections of the torus"""
	# These are circles that aren't meridians or parallels
	# They create a linked-ring pattern
	var angle = u + v  # Oblique direction
	var h = sin(angle * 2.0) * 0.5
	h += sin(u - v) * 0.3  # Cross pattern
	return h * wave_amplitude

func _flat_torus(u: float, v: float) -> float:
	"""Clifford torus — intrinsically flat, curvature from embedding"""
	# The flat torus has zero intrinsic curvature but extrinsic curvature
	# from being embedded in 3D. Show this as gentle undulations.
	var embedding_curvature = cos(u) * 0.3 + cos(v) * 0.3
	return embedding_curvature

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.6, 0.45)  # Sage green
	material.roughness = 0.6
	material.metallic = 0.2
	material.emission_enabled = true
	material.emission = Color(0.3, 0.35, 0.25) * 0.2
	mesh_instance.material_override = material

# Public API
func set_height_mode(mode: TorusHeightMode):
	height_mode = mode
	generate_space()

func set_radii(major: float, minor: float):
	major_radius = major
	minor_radius = minor
	generate_space()
