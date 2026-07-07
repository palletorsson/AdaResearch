extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PoissonForestScatter

## @identity
## name: "Poisson-disk & scatter"
## tier: applied
## lineage: Bridson's dart-throwing — every random proposal that crowds its neighbor is rejected
## essence: A forest that grew itself. A flat green patch, and trees thrown across it by blue
##   noise — never overlapping, never clumping, no grid. The minimum-distance rule does the
##   work a level designer would: even, breathing, natural cover. Read out of one seed.
## truth: "A FOREST THAT GREW ITSELF — BLUE NOISE PLACES THE TREES" — even, natural spacing
##   is what remains when every too-close proposal is rejected; placement without a placer.
## applications: object placement, level scatter, vegetation/foliage systems, freckles & stars,
##   any time you need things spread evenly but not in a grid.

@export var forest_seed: int = 23
@export var min_spacing: float = 0.085
@export var ground_size: float = 1.10
@export var tree_target: int = 70
@export var max_attempts: int = 30
@export var trunk_col: Color = Color(0.40, 0.27, 0.16)
@export var canopy_col: Color = Color(0.18, 0.46, 0.20)
@export var canopy_hi: Color = Color(0.30, 0.58, 0.28)
@export var ground_col: Color = Color(0.22, 0.40, 0.20)
@export var rock_col: Color = Color(0.46, 0.46, 0.48)
@export var label_col: Color = Color(0.82, 0.92, 0.80)

const GROUND_Y: float = 0.5

var _root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("forest_seed"):
		forest_seed = int(config["forest_seed"])
	if config.has("min_spacing"):
		min_spacing = clampf(float(config["min_spacing"]), 0.04, 0.30)
	if config.has("ground_size"):
		ground_size = clampf(float(config["ground_size"]), 0.5, 2.0)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_root = null
	_build()


# --- multimesh field factory -------------------------------------------------

func _field(mesh: Mesh, n: int, base_col: Color) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = base_col
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = base_col
	mat.emission_energy_multiplier = 0.15 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	var root := Node3D.new()
	root.name = "Forest"
	root.position = Vector3(0.0, GROUND_Y, 0.0)
	add_child(root)
	_root = root

	# 0) GROUND — a flat green patch.
	var ground_mat := _matte_mat(ground_col, 0.95)
	root.add_child(_box(Vector3(0.0, -0.01, 0.0), Vector3(ground_size, 0.02, ground_size), ground_mat))

	# 1) POISSON FIELD — Bridson blue noise, deterministic from forest_seed.
	var rng := RandomNumberGenerator.new()
	rng.seed = forest_seed
	var pts := _poisson_points(rng)

	var n: int = pts.size()
	if n == 0:
		_add_label(root)
		return

	# 2) TRUNKS — ONE MultiMesh of thin cylinders.
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.006
	trunk_mesh.bottom_radius = 0.009
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 6
	var trunks := _field(trunk_mesh, n, trunk_col)
	root.add_child(trunks)

	# 3) CANOPIES — a SECOND MultiMesh of cones.
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.045
	cone_mesh.height = 1.0
	cone_mesh.radial_segments = 7
	var canopies := _field(cone_mesh, n, canopy_col)
	root.add_child(canopies)

	# 4) ROCKS — a THIRD MultiMesh of small grey spheres in the gaps.
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 2.0
	rock_mesh.radial_segments = 6
	rock_mesh.rings = 4
	var rocks := _field(rock_mesh, n, rock_col)
	root.add_child(rocks)
	var rock_count: int = 0

	for i in range(n):
		var p: Vector2 = pts[i]
		# deterministic per-index jitter for life — no global RNG draw, stable per index.
		var j: float = _hash01(i, forest_seed)
		var j2: float = _hash01(i * 7 + 31, forest_seed)
		var trunk_h: float = lerpf(0.07, 0.13, j)
		var canopy_h: float = lerpf(0.10, 0.18, j2)
		var canopy_w: float = lerpf(0.8, 1.25, j)
		var pos := Vector3(p.x, 0.0, p.y)

		# trunk: base at ground, scaled in Y.
		var trunk_xf := Transform3D(
			Basis().scaled(Vector3(1.0, trunk_h, 1.0)),
			pos + Vector3(0.0, trunk_h * 0.5, 0.0)
		)
		trunks.multimesh.set_instance_transform(i, trunk_xf)
		trunks.multimesh.set_instance_color(i, trunk_col)

		# canopy: cone sitting atop the trunk, slight width variation.
		var canopy_xf := Transform3D(
			Basis().scaled(Vector3(canopy_w, canopy_h, canopy_w)),
			pos + Vector3(0.0, trunk_h + canopy_h * 0.5, 0.0)
		)
		canopies.multimesh.set_instance_transform(i, canopy_xf)
		canopies.multimesh.set_instance_color(i, canopy_col.lerp(canopy_hi, j2))

		# rocks: only a sparse few, in deterministic gap slots.
		if (i % 9) == 4:
			var rs: float = lerpf(0.012, 0.022, j2)
			var rock_xf := Transform3D(
				Basis().scaled(Vector3(rs, rs * 0.7, rs)),
				pos + Vector3(0.0, rs * 0.35, 0.0)
			)
			rocks.multimesh.set_instance_transform(rock_count, rock_xf)
			rocks.multimesh.set_instance_color(rock_count, rock_col.darkened(j * 0.2))
			rock_count += 1

	rocks.multimesh.visible_instance_count = rock_count

	_add_label(root)


# --- Bridson Poisson-disk on the 2D ground patch -----------------------------
# Returns points in local XZ space, centered on (0,0), spanning [-half, half].
# Background grid stores point index per cell (cell <= r/sqrt2 => one point max).
func _poisson_points(rng: RandomNumberGenerator) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var half: float = ground_size * 0.5
	var r: float = maxf(min_spacing, 0.02)
	var cell: float = r / sqrt(2.0)
	var cols: int = int(ceil(ground_size / cell)) + 1
	var rows: int = int(ceil(ground_size / cell)) + 1
	var grid: PackedInt32Array = PackedInt32Array()
	grid.resize(cols * rows)
	grid.fill(-1)
	var active: Array[int] = []

	var start := Vector2(rng.randf() * ground_size - half, rng.randf() * ground_size - half)
	_place(start, pts, active, grid, cols, rows, cell, half)

	var safety: int = 0
	var safety_cap: int = tree_target * 60 + 4000
	while active.size() > 0 and pts.size() < tree_target and safety < safety_cap:
		safety += 1
		var ai: int = rng.randi() % active.size()
		var p: Vector2 = pts[active[ai]]
		var found: bool = false
		for _a in range(max_attempts):
			var ang: float = rng.randf() * TAU
			var rad: float = r * (1.0 + rng.randf())
			var cand := p + Vector2(cos(ang), sin(ang)) * rad
			if cand.x < -half or cand.x > half or cand.y < -half or cand.y > half:
				continue
			if _far(cand, pts, grid, cols, rows, cell, half, r):
				_place(cand, pts, active, grid, cols, rows, cell, half)
				found = true
				break
		if not found:
			active.remove_at(ai)
	return pts


func _place(p: Vector2, pts: Array[Vector2], active: Array[int], grid: PackedInt32Array, cols: int, rows: int, cell: float, half: float) -> void:
	var gx: int = clampi(int((p.x + half) / cell), 0, cols - 1)
	var gy: int = clampi(int((p.y + half) / cell), 0, rows - 1)
	grid[gy * cols + gx] = pts.size()
	active.append(pts.size())
	pts.append(p)


func _far(p: Vector2, pts: Array[Vector2], grid: PackedInt32Array, cols: int, rows: int, cell: float, half: float, r: float) -> bool:
	var gx: int = clampi(int((p.x + half) / cell), 0, cols - 1)
	var gy: int = clampi(int((p.y + half) / cell), 0, rows - 1)
	for oy in range(maxi(gy - 2, 0), mini(gy + 3, rows)):
		for ox in range(maxi(gx - 2, 0), mini(gx + 3, cols)):
			var key: int = grid[oy * cols + ox]
			if key >= 0:
				if p.distance_to(pts[key]) < r:
					return false
	return true


# deterministic 0..1 hash from an integer index + seed (no RNG state).
func _hash01(i: int, s: int) -> float:
	var x: int = (i * 374761393 + s * 668265263) & 0x7fffffff
	x = (x ^ (x >> 13)) * 1274126177
	x = x & 0x7fffffff
	return float(x % 100000) / 100000.0


func _add_label(root: Node3D) -> void:
	root.add_child(_billboard_label(
		"A FOREST THAT GREW ITSELF — BLUE NOISE PLACES THE TREES",
		Vector3(0.0, ground_size * 0.30 + 0.18, 0.0),
		13,
		label_col
	))
