extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PoissonScatterToy

## @identity
## name: "Poisson-disk & scatter"
## tier: small
## lineage: Bridson's dart-throwing sampler — random points that politely keep their distance
## essence: A hand-sized patch sprinkled with points that look random yet never crowd. Each is
##   thrown blind, then kept only if no neighbour sits inside its exclusion circle. A few of the
##   points wear their circle so you can see the rule: random, but never too close.
## truth: "RANDOM, BUT NEVER TOO CLOSE" — uniform jitter clumps and leaves holes; a single
##   minimum-distance rejection turns noise into even, organic-looking spacing.
## applications: object scatter (grass, trees, rocks), stippling, texture sampling, blue-noise dithering, level decoration.

@export var point_seed: int = 7
@export var min_distance: float = 0.085
@export var patch_size: float = 0.46
@export var target_points: int = 24
@export var patch_col: Color = Color(0.10, 0.12, 0.16)
@export var point_col: Color = Color(0.55, 0.86, 0.62)
@export var ring_col: Color = Color(0.42, 0.78, 0.98)
@export var label_col: Color = Color(0.82, 0.92, 0.88)


func _ready() -> void:
	_rng.randomize()
	_build()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("point_seed"):
		point_seed = int(config["point_seed"])
	if config.has("min_distance"):
		min_distance = clampf(float(config["min_distance"]), 0.04, 0.16)
	if config.has("patch_size"):
		patch_size = clampf(float(config["patch_size"]), 0.30, 0.60)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# --- Bridson Poisson-disk sampler (self-contained, 2D in the XZ plane) --------
# Dart-throwing variant: pick a random seed point, then try to spawn new points
# in the annulus [r, 2r] around active points; reject any candidate that lands
# within min_distance of an already-accepted point. Deterministic from point_seed.

func _sample(r: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = point_seed
	var half: float = patch_size * 0.5
	var lo: float = -half + r * 0.5
	var hi: float = half - r * 0.5
	var k: int = 24  # candidates per active point
	var points: Array = []
	var active: Array = []

	# first seed point near the centre
	var first := Vector2(rng.randf_range(lo, hi), rng.randf_range(lo, hi))
	points.append(first)
	active.append(first)

	var attempts: int = 0
	var attempt_cap: int = 4000  # hard guard against infinite loops
	while active.size() > 0 and points.size() < target_points and attempts < attempt_cap:
		var ai: int = rng.randi_range(0, active.size() - 1)
		var origin: Vector2 = active[ai]
		var found: bool = false
		for _i in range(k):
			attempts += 1
			if attempts >= attempt_cap:
				break
			var ang: float = rng.randf() * TAU
			var rad: float = r * (1.0 + rng.randf())  # annulus [r, 2r]
			var cand := origin + Vector2(cos(ang), sin(ang)) * rad
			if cand.x < lo or cand.x > hi or cand.y < lo or cand.y > hi:
				continue
			if _far_enough(cand, points, r):
				points.append(cand)
				active.append(cand)
				found = true
				break
		if not found:
			active.remove_at(ai)
	return points


func _far_enough(c: Vector2, points: Array, r: float) -> bool:
	for p in points:
		if (c - p).length_squared() < r * r:
			return false
	return true


func _points_field(mesh: Mesh, n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	var r: float = clampf(min_distance, 0.04, patch_size * 0.4)
	var pts: Array = _sample(r)
	var top_y: float = 0.012

	# 1) the flat square patch
	add_child(_box(Vector3(0.0, 0.0, 0.0), Vector3(patch_size, 0.02, patch_size), _matte_mat(patch_col, 0.9)))

	# 2) the sampled points — ONE MultiMesh of small spheres
	var dot := SphereMesh.new()
	dot.radius = 1.0
	dot.height = 2.0
	var field := _points_field(dot, pts.size())
	add_child(field)
	var dot_r: float = 0.012
	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		var xf := Transform3D(
			Basis().scaled(Vector3(dot_r, dot_r, dot_r)),
			Vector3(p.x, top_y + dot_r, p.y)
		)
		field.multimesh.set_instance_transform(i, xf)
		field.multimesh.set_instance_color(i, point_col)

	# 3) exclusion rings around a few points — the teaching: nothing falls inside.
	var ring_mat := _glass_mat(ring_col, 0.22)
	var rings_to_show: int = mini(3, pts.size())
	for j in range(rings_to_show):
		# spread the chosen rings across the point set so they don't overlap
		var pi: int = int(float(j) * float(pts.size()) / float(maxi(rings_to_show, 1)))
		pi = clampi(pi, 0, pts.size() - 1)
		var c: Vector2 = pts[pi]
		# flat thin ring of radius = min_distance (the exclusion circle)
		var ring := _torus(Vector3(c.x, top_y + 0.001, c.y), r, 0.004, ring_mat)
		ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		add_child(ring)

	# 4) the truth label, floating above the patch
	add_child(_billboard_label("RANDOM, BUT NEVER TOO CLOSE", Vector3(0.0, patch_size * 0.5 + 0.06, 0.0), 13, label_col))
