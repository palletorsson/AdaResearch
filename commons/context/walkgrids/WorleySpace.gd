# WorleySpace.gd - Worley noise (cellular noise) as walkable terrain
# Distance to nearest random point creates cracked-earth, cell-wall,
# dried-mud terrain. The dual of Voronoi — where VoronoiSpace gives
# flat plateaus, Worley gives ridges at the boundaries between cells.
#
# "Every crack is a border. Every border is a negotiation."

extends TopologySpace
class_name WorleySpace

@export var num_points: int = 30
@export var distance_metric: DistanceMetric = DistanceMetric.EUCLIDEAN
@export var combination: DistanceCombination = DistanceCombination.F1
@export var invert: bool = false           # Invert for ridges vs valleys
@export var jitter: float = 1.0            # How random the points are (0 = grid, 1 = full random)
@export var seed_value: int = 42

# Which distance to use for height
enum DistanceCombination {
	F1,            # Distance to closest point (smooth cells)
	F2,            # Distance to 2nd closest (star patterns)
	F2_MINUS_F1,   # F2-F1 = ridge lines between cells (cracked earth)
	F1_PLUS_F2,    # F1+F2 = rounded cells
	F1_TIMES_F2,   # F1*F2 = organic bubbles
}

enum DistanceMetric {
	EUCLIDEAN,     # Round cells
	MANHATTAN,     # Diamond-shaped cells
	CHEBYSHEV,     # Square cells
	MINKOWSKI_P3,  # Between euclidean and chebyshev
}

var points: Array[Vector2] = []
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_generate_points()
	super._ready()

func _generate_points():
	points.clear()
	if jitter < 1.0:
		# Grid-based with jitter
		var grid_count = int(sqrt(float(num_points)))
		var cell_w = space_size.x / float(grid_count)
		var cell_h = space_size.y / float(grid_count)
		for gz in range(grid_count):
			for gx in range(grid_count):
				var base = Vector2(
					(gx + 0.5) * cell_w - space_size.x / 2.0,
					(gz + 0.5) * cell_h - space_size.y / 2.0
				)
				var offset = Vector2(
					rng.randf_range(-0.5, 0.5) * cell_w * jitter,
					rng.randf_range(-0.5, 0.5) * cell_h * jitter
				)
				points.append(base + offset)
	else:
		for _i in range(num_points):
			points.append(Vector2(
				rng.randf_range(-space_size.x / 2.0, space_size.x / 2.0),
				rng.randf_range(-space_size.y / 2.0, space_size.y / 2.0)
			))

func _distance(a: Vector2, b: Vector2) -> float:
	match distance_metric:
		DistanceMetric.EUCLIDEAN:
			return a.distance_to(b)
		DistanceMetric.MANHATTAN:
			return abs(a.x - b.x) + abs(a.y - b.y)
		DistanceMetric.CHEBYSHEV:
			return maxf(abs(a.x - b.x), abs(a.y - b.y))
		DistanceMetric.MINKOWSKI_P3:
			var dx = abs(a.x - b.x)
			var dy = abs(a.y - b.y)
			return pow(pow(dx, 3.0) + pow(dy, 3.0), 1.0 / 3.0)
	return a.distance_to(b)

func generate_space():
	var heights: Array = []
	var gs = resolution + 1
	var max_height = 0.0

	for z in range(gs):
		for x in range(gs):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var world_z = (z / float(resolution)) * space_size.y - space_size.y / 2.0
			var pos = Vector2(world_x, world_z)

			# Find distances to all points, sort
			var distances: Array[float] = []
			for p in points:
				distances.append(_distance(pos, p))
			distances.sort()

			var f1 = distances[0] if distances.size() > 0 else 0.0
			var f2 = distances[1] if distances.size() > 1 else f1

			var h = 0.0
			match combination:
				DistanceCombination.F1:
					h = f1
				DistanceCombination.F2:
					h = f2
				DistanceCombination.F2_MINUS_F1:
					h = f2 - f1
				DistanceCombination.F1_PLUS_F2:
					h = (f1 + f2) * 0.5
				DistanceCombination.F1_TIMES_F2:
					h = f1 * f2 * 0.1

			if invert:
				h = -h

			heights.append(h)
			max_height = maxf(max_height, abs(h))

	# Normalize heights
	if max_height > 0.0:
		for i in range(heights.size()):
			heights[i] = (heights[i] / max_height) * height_scale

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.55, 0.4)  # Dried earth / terracotta
	material.roughness = 0.9
	material.metallic = 0.05
	mesh_instance.material_override = material

# Public API
func set_combination(combo: DistanceCombination):
	combination = combo
	generate_space()

func set_metric(metric: DistanceMetric):
	distance_metric = metric
	generate_space()

func regenerate():
	rng.seed = randi()
	_generate_points()
	generate_space()
