extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PoissonScatterBench

## @identity
## name: "Poisson-disk & scatter"
## tier: medium
## lineage: Bridson's blue-noise sampler — dart-throwing with a minimum-distance rejection
## essence: Two trays, the same number of points on each. The left is sown by pure random
##   chance and you watch it clump — knots of dots beside bare bald patches. The right is sown
##   by Poisson-disk rejection: every dot keeps its neighbours an arm's length away, so the
##   same count spreads even and calm. Same numbers, two different textures.
## truth: "SAME COUNT, DIFFERENT TEXTURE" — uniform random clumps and leaves gaps; blue noise
##   spreads evenly because each point survives only by respecting its neighbours' distance.
## applications: object scattering (trees, grass, rocks), stippling, sampling, anti-aliasing,
##   texture placement — anywhere "random" needs to look natural instead of patchy.

@export var point_seed: int = 11
@export var min_distance: float = 0.07
@export var target_count: int = 120
@export var tray_size: float = 0.46
@export var tray_gap: float = 0.10
@export var point_radius: float = 0.012
@export var random_col: Color = Color(0.92, 0.36, 0.26)
@export var poisson_col: Color = Color(0.30, 0.82, 0.92)
@export var tray_col: Color = Color(0.10, 0.11, 0.14)
@export var label_col: Color = Color(0.84, 0.90, 0.97)
@export var max_attempts: int = 30


func _ready() -> void:
	_rng.randomize()
	_build()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("point_seed"):
		point_seed = int(config["point_seed"])
	if config.has("min_distance"):
		min_distance = float(config["min_distance"])
	if config.has("target_count"):
		target_count = maxi(4, int(config["target_count"]))
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# --- multimesh point-field factory ------------------------------------------

func _field(n: int, color: Color) -> MultiMeshInstance3D:
	var dot := SphereMesh.new()
	dot.radius = point_radius
	dot.height = point_radius * 2.0
	dot.radial_segments = 8
	dot.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = dot
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


# --- samplers ---------------------------------------------------------------
# Both return points in tray-local [0,1]x[0,1]. We place them at tray centre.

func _uniform_points(r: RandomNumberGenerator, n: int) -> Array:
	var pts: Array = []
	for _i in range(n):
		pts.append(Vector2(r.randf(), r.randf()))
	return pts


# Bridson's algorithm on the unit square. Returns up to target_count points,
# evenly spread at least min_distance / tray_size apart in normalized space.
func _poisson_points(r: RandomNumberGenerator, n: int) -> Array:
	var rad: float = min_distance / tray_size  # normalized exclusion radius
	rad = clampf(rad, 0.001, 0.5)
	var cell: float = rad / sqrt(2.0)
	var gw: int = maxi(1, int(ceil(1.0 / cell)))
	var grid: Array = []
	grid.resize(gw * gw)
	for i in range(gw * gw):
		grid[i] = -1

	var pts: Array = []
	var active: Array = []

	var first := Vector2(r.randf(), r.randf())
	pts.append(first)
	active.append(0)
	grid[_grid_idx(first, cell, gw)] = 0

	var guard: int = 0
	var guard_cap: int = n * (max_attempts + 4) + 1024
	while active.size() > 0 and pts.size() < n and guard < guard_cap:
		guard += 1
		var ai: int = r.randi_range(0, active.size() - 1)
		var base: Vector2 = pts[active[ai]]
		var placed := false
		for _attempt in range(max_attempts):
			var ang: float = r.randf() * TAU
			var dist: float = rad * (1.0 + r.randf())
			var cand := base + Vector2(cos(ang), sin(ang)) * dist
			if cand.x < 0.0 or cand.x >= 1.0 or cand.y < 0.0 or cand.y >= 1.0:
				continue
			if _far_enough(cand, pts, grid, cell, gw, rad):
				pts.append(cand)
				active.append(pts.size() - 1)
				grid[_grid_idx(cand, cell, gw)] = pts.size() - 1
				placed = true
				break
		if not placed:
			active.remove_at(ai)
	return pts


func _grid_idx(p: Vector2, cell: float, gw: int) -> int:
	var gx: int = clampi(int(p.x / cell), 0, gw - 1)
	var gy: int = clampi(int(p.y / cell), 0, gw - 1)
	return gy * gw + gx


func _far_enough(p: Vector2, pts: Array, grid: Array, cell: float, gw: int, rad: float) -> bool:
	var gx: int = clampi(int(p.x / cell), 0, gw - 1)
	var gy: int = clampi(int(p.y / cell), 0, gw - 1)
	for oy in range(-2, 3):
		for ox in range(-2, 3):
			var nx: int = gx + ox
			var ny: int = gy + oy
			if nx < 0 or ny < 0 or nx >= gw or ny >= gw:
				continue
			var idx: int = grid[ny * gw + nx]
			if idx >= 0:
				if p.distance_to(pts[idx]) < rad:
					return false
	return true


# --- build ------------------------------------------------------------------

func _build() -> void:
	var n: int = maxi(4, target_count)
	var half: float = tray_size * 0.5
	var off: float = (tray_size + tray_gap) * 0.5

	# Deterministic RNGs from the seed (one each so trays don't share a stream).
	var rl := RandomNumberGenerator.new()
	rl.seed = point_seed
	var rr := RandomNumberGenerator.new()
	rr.seed = point_seed

	# Two trays as thin slabs.
	var tray_mat := _matte_mat(tray_col, 0.85)
	var slab := Vector3(tray_size, 0.012, tray_size)
	add_child(_box(Vector3(-off, 0.0, 0.0), slab, tray_mat))
	add_child(_box(Vector3(off, 0.0, 0.0), slab, tray_mat))

	var top_y: float = 0.012

	# LEFT: uniform random — fixed count, clumps and leaves gaps.
	var left_pts: Array = _uniform_points(rl, n)
	var left := _field(left_pts.size(), random_col)
	add_child(left)
	for i in range(left_pts.size()):
		var p: Vector2 = left_pts[i]
		var pos := Vector3(-off + (p.x - 0.5) * tray_size, top_y, (p.y - 0.5) * tray_size)
		left.multimesh.set_instance_transform(i, Transform3D(Basis(), pos))
		left.multimesh.set_instance_color(i, random_col)

	# RIGHT: Poisson-disk — same target count; renders whatever it fits.
	var right_pts: Array = _poisson_points(rr, n)
	var right := _field(right_pts.size(), poisson_col)
	add_child(right)
	for j in range(right_pts.size()):
		var q: Vector2 = right_pts[j]
		var rpos := Vector3(off + (q.x - 0.5) * tray_size, top_y, (q.y - 0.5) * tray_size)
		right.multimesh.set_instance_transform(j, Transform3D(Basis(), rpos))
		right.multimesh.set_instance_color(j, poisson_col)

	# Captions under each tray.
	var cap_y: float = 0.02
	var cap_z: float = half + 0.06
	add_child(_billboard_label("UNIFORM RANDOM — IT CLUMPS", Vector3(-off, cap_y, cap_z), 12, random_col))
	add_child(_billboard_label("POISSON — EVENLY SPREAD", Vector3(off, cap_y, cap_z), 12, poisson_col))

	# Top title.
	add_child(_billboard_label("SAME COUNT, DIFFERENT TEXTURE", Vector3(0.0, half + 0.16, 0.0), 15, label_col))
