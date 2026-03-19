extends Node3D

# @identity
# essence: blue_noise = dart_throwing — place points rejecting any candidate closer than min_dist to existing points, so emptiness is forbidden
# desire: to feel the difference between fairness and freedom — blue noise is crowded rooms with social distancing, white noise is a mosh pit
# critical_parameter: blue_noise_min_dist — the exclusion radius that turns white noise into structured randomness
# triggers: switching DistributionType between UNIFORM/GAUSSIAN/BLUE_NOISE reveals three fundamentally different relationships with space
# emerges: the packing limit — blue noise runs out of room before placing all requested points, which becomes visible as a teaching moment about density
# needs: DistributionType selector [missing]; num_points slider [missing]; area_size control [missing]; all selection is export-only, no VR interaction
# relationships: contrasts with randompoint (single white noise); prepares for perlin noise (structured randomness with continuity); connects to blue_noise sequence artifact
# truth: structured randomness is not less random — it is randomness with a constraint, the way jazz improvisation is constrained by harmony

enum DistributionType {
	UNIFORM,
	GAUSSIAN,
	BLUE_NOISE,
}

@export var distribution_type: DistributionType = DistributionType.BLUE_NOISE
@export var num_points: int = 30
@export var area_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var gaussian_std_fraction: float = 0.25
@export var blue_noise_min_dist: float = 0.25 # Minimum distance for Blue Noise

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_color_with_text.tscn")

func _ready() -> void:
	# Auto-detect type from node name if generic script is used
	var n = name.to_lower()
	if "gaussian" in n:
		distribution_type = DistributionType.GAUSSIAN
	elif "uniform" in n:
		distribution_type = DistributionType.UNIFORM
	elif "randompoints" == n or "blue" in n:
		# Default 'randompoints' is Blue Noise (structured randomness)
		distribution_type = DistributionType.BLUE_NOISE
		
	randomize()
	spawn_points()

func spawn_points() -> void:
	var points = []
	var half_extents = area_size * 0.5
	
	match distribution_type:
		DistributionType.UNIFORM:
			points = _generate_uniform(num_points, half_extents)
		DistributionType.GAUSSIAN:
			points = _generate_gaussian(num_points, half_extents)
		DistributionType.BLUE_NOISE:
			points = _generate_blue_noise(num_points, half_extents)
	
	print("RandomPoints: Generated %d points using %s distribution" % [points.size(), DistributionType.keys()[distribution_type]])
	
	for i in range(points.size()):
		var p = point_scene.instantiate()
		p.name = "Point_%d" % i
		add_child(p)
		p.position = points[i]

func _generate_uniform(count: int, extents: Vector3) -> Array:
	var pts = []
	for i in range(count):
		var pos = Vector3(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y),
			randf_range(-extents.z, extents.z)
		)
		pts.append(pos)
	return pts

func _generate_gaussian(count: int, extents: Vector3) -> Array:
	var pts = []
	var sx = extents.x * gaussian_std_fraction
	var sy = extents.y * gaussian_std_fraction
	var sz = extents.z * gaussian_std_fraction
	
	for i in range(count):
		var pos = Vector3(
			clamp(_randn(0.0, sx), -extents.x, extents.x),
			clamp(_randn(0.0, sy), -extents.y, extents.y),
			clamp(_randn(0.0, sz), -extents.z, extents.z)
		)
		pts.append(pos)
	return pts

func _generate_blue_noise(count: int, extents: Vector3) -> Array:
	var pts: Array[Vector3] = []
	var max_attempts = 100
	
	# Attempt to place 'count' points with Dart Throwing
	for i in range(count):
		var placed = false
		
		for attempt in range(max_attempts):
			var candidate = Vector3(
				randf_range(-extents.x, extents.x),
				randf_range(-extents.y, extents.y),
				randf_range(-extents.z, extents.z)
			)
			
			var min_dist = INF
			if pts.is_empty():
				min_dist = INF
			else:
				for existing in pts:
					var d = candidate.distance_to(existing)
					if d < min_dist:
						min_dist = d
			
			# Enforce minimum distance
			if min_dist >= blue_noise_min_dist:
				pts.append(candidate)
				placed = true
				break
		
		if not placed:
			# Relax constraint slightly if we fail? 
			# For now, just don't place the point (returns fewer points than requested)
			# This is characteristic of Blue Noise (packing limit)
			pass
			
	return pts

func _randn(mean: float, std: float) -> float:
	var u1 = clamp(randf(), 1e-6, 1.0 - 1e-6)
	var u2 = randf()
	var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + std * z

func apply_grid_config(config: Dictionary) -> void:
	pass
