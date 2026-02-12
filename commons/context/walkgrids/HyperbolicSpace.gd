# HyperbolicSpace.gd - Non-Euclidean geometry as walkable terrain
# The Poincaré disk model projected as a height field. Near the center
# the terrain is flat and normal. Near the edges, space compresses —
# height changes accelerate exponentially. You can walk forever
# and never reach the boundary.
#
# "In hyperbolic space, there's always more room than you think."

extends TopologySpace
class_name HyperbolicSpace

@export var curvature: float = 1.0         # Negative curvature strength
@export var tessellation: TessellationType = TessellationType.NONE
@export var disk_radius: float = 0.95      # How close to the boundary we render (< 1.0)
@export var height_mode: HeightMode = HeightMode.HYPERBOLIC_DISTANCE

enum HeightMode {
	HYPERBOLIC_DISTANCE,  # Height = hyperbolic distance from center (exponential growth)
	GAUSSIAN_CURVATURE,   # Height shows local curvature
	GEODESIC_GRID,        # Height from hyperbolic geodesic tiling
	PSEUDOSPHERE,         # Tractricoid profile
}

enum TessellationType {
	NONE,              # Smooth surface
	POINCARE_TILING,   # {5,4} or similar hyperbolic tiling as height ridges
	GEODESIC_CIRCLES,  # Concentric hyperbolic circles
}

# Tiling parameters
@export var tiling_p: int = 5  # Polygon sides (for Poincaré tiling)
@export var tiling_q: int = 4  # Polygons meeting at vertex
@export var ridge_sharpness: float = 0.5

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			# Map to unit disk
			var u = (x / float(resolution)) * 2.0 - 1.0  # -1 to 1
			var v = (z / float(resolution)) * 2.0 - 1.0
			var r = sqrt(u * u + v * v)

			var h = 0.0
			if r < disk_radius:
				h = _compute_height(u, v, r)
			else:
				# Outside disk — sharp drop
				h = -abs(r - disk_radius) * 5.0

			heights.append(h * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _compute_height(u: float, v: float, r: float) -> float:
	var base = 0.0

	match height_mode:
		HeightMode.HYPERBOLIC_DISTANCE:
			# Hyperbolic distance from origin in Poincaré disk
			# d = 2 * arctanh(r) = log((1+r)/(1-r))
			var d = log((1.0 + r) / maxf(1.0 - r, 0.001))
			base = d * curvature * 0.3

		HeightMode.GAUSSIAN_CURVATURE:
			# Curvature increases toward boundary
			var denom = maxf((1.0 - r * r), 0.001)
			base = -curvature / (denom * denom) * 0.01
			base = clampf(base, -3.0, 3.0)

		HeightMode.GEODESIC_GRID:
			# Create a grid that warps hyperbolically
			var d = log((1.0 + r) / maxf(1.0 - r, 0.001))
			var theta = atan2(v, u)
			var grid_val = sin(d * 3.0) * sin(theta * 6.0)
			base = grid_val * curvature * 0.3

		HeightMode.PSEUDOSPHERE:
			# Tractricoid: surface of constant negative curvature
			# Height decreases as sech(d)
			var d = log((1.0 + r) / maxf(1.0 - r, 0.001))
			base = 1.0 / cosh(d * curvature) * 2.0

	# Add tessellation overlay
	match tessellation:
		TessellationType.POINCARE_TILING:
			base += _poincare_tiling_height(u, v, r) * ridge_sharpness
		TessellationType.GEODESIC_CIRCLES:
			base += _geodesic_circles_height(u, v, r) * ridge_sharpness

	return base

func _poincare_tiling_height(u: float, v: float, r: float) -> float:
	"""Approximate hyperbolic tiling as height ridges"""
	# Use the angle and hyperbolic distance to create a tiling-like pattern
	var theta = atan2(v, u)
	var d = log((1.0 + r) / maxf(1.0 - r, 0.001))

	# Create polygon-like pattern
	var angular = abs(sin(theta * float(tiling_p) / 2.0))
	var radial = abs(sin(d * float(tiling_q)))

	# Combine to create cell boundaries
	var boundary = minf(angular, radial)
	return (1.0 - boundary) * 0.3

func _geodesic_circles_height(u: float, v: float, r: float) -> float:
	"""Concentric hyperbolic circles as height rings"""
	var d = log((1.0 + r) / maxf(1.0 - r, 0.001))
	return sin(d * 4.0) * 0.3

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.2, 0.35)  # Deep indigo
	material.roughness = 0.5
	material.metallic = 0.3
	material.emission_enabled = true
	material.emission = Color(0.15, 0.1, 0.3) * 0.4
	mesh_instance.material_override = material

# Public API
func set_height_mode(mode: HeightMode):
	height_mode = mode
	generate_space()

func set_curvature(k: float):
	curvature = k
	generate_space()

func set_tessellation(tess: TessellationType):
	tessellation = tess
	generate_space()
