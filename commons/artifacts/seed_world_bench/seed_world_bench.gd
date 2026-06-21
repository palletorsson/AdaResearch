extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SeedWorldBench

## @identity
## name: "Seed -> world"
## tier: medium
## lineage: the heightmap bench — a noise field read as land, the oldest trick in procedural worlds
## essence: A world patch laid out on a bench top. The seed is fed to the noise; the noise is read
##   as height; the height is cut into bands of water, sand, grass, forest, rock and snow; trees
##   land on the green and a small structure on the dry high ground. The whole patch is a readout
##   of one number, printed on the billboard above it.
## truth: "THE SEED PICKS THE NOISE, THE NOISE PICKS THE TERRAIN" — one seed becomes a world; the
##   seed picks the noise, the noise the terrain, the terrain the structures, the structures the
##   life; design without a designer.
## applications: procedural maps, biome generation, terrain prototyping — author the rule, not the land.

@export var world_seed: int = 1337
@export var grid: int = 18
@export var world_span: float = 0.92
@export var height_gain: float = 0.34
@export var water_level: float = 0.32
@export var top_y: float = 0.85
@export var tree_density: float = 0.30
@export var bench_color: Color = Color(0.18, 0.19, 0.22)
@export var deep_col: Color = Color(0.05, 0.16, 0.38)
@export var sand_col: Color = Color(0.80, 0.74, 0.50)
@export var grass_col: Color = Color(0.24, 0.54, 0.26)
@export var forest_col: Color = Color(0.13, 0.36, 0.18)
@export var rock_col: Color = Color(0.46, 0.43, 0.42)
@export var snow_col: Color = Color(0.93, 0.95, 0.97)
@export var water_col: Color = Color(0.18, 0.46, 0.72)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _sway: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("world_seed"):
		world_seed = int(config["world_seed"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 12, 28)
	if config.has("world_span"):
		world_span = float(config["world_span"])
	if config.has("water_level"):
		water_level = clampf(float(config["water_level"]), 0.0, 0.9)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_build()


func _band_color(h: float) -> Color:
	if h < water_level - 0.06:
		return deep_col
	if h < water_level:
		return deep_col.lerp(sand_col, (h - (water_level - 0.06)) / 0.06)
	if h < water_level + 0.05:
		return sand_col
	if h < 0.52:
		return grass_col
	if h < 0.64:
		return forest_col
	if h < 0.74:
		return rock_col
	return snow_col


func _is_life_band(h: float) -> bool:
	return h >= water_level + 0.05 and h < 0.64


func _is_dry_high(h: float) -> bool:
	return h >= 0.56 and h < 0.74


func _field(mesh: Mesh, n: int) -> MultiMeshInstance3D:
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


func _height_at(n: FastNoiseLite, u: float, v: float) -> float:
	return n.get_noise_2d(u * 100.0, v * 100.0) * 0.5 + 0.5


func _build() -> void:
	# Bench base + top.
	add_child(_box(Vector3(0.0, top_y * 0.5, 0.0), Vector3(world_span + 0.16, top_y, world_span + 0.16), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(world_span + 0.10, 0.03, world_span + 0.10), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))

	# The patch swivels gently so the player can read the whole map.
	var sway := Node3D.new()
	sway.name = "PatchSway"
	sway.position = Vector3(0.0, top_y + 0.02, 0.0)
	add_child(sway)
	_sway = sway

	# noise from seed.
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	noise.fractal_octaves = 4

	# TERRAIN.
	var cell: float = world_span / float(grid)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var terrain := _field(box, grid * grid)
	sway.add_child(terrain)
	var idx: int = 0
	for gz in range(grid):
		for gx in range(grid):
			var u: float = float(gx) / float(grid - 1)
			var v: float = float(gz) / float(grid - 1)
			var h: float = _height_at(noise, u, v)
			var hh: float = maxf(h * height_gain, 0.005)
			var px: float = (u - 0.5) * world_span
			var pz: float = (v - 0.5) * world_span
			terrain.multimesh.set_instance_transform(idx, Transform3D(
				Basis().scaled(Vector3(cell * 0.96, hh, cell * 0.96)),
				Vector3(px, hh * 0.5, pz)
			))
			terrain.multimesh.set_instance_color(idx, _band_color(h))
			idx += 1

	# WATER.
	var wy: float = water_level * height_gain
	sway.add_child(_box(Vector3(0.0, wy * 0.5, 0.0), Vector3(world_span, maxf(wy, 0.005), world_span), _glass_mat(water_col, 0.42)))

	# LIFE — seeded scatter of trees (trunk + colored blob, packed into 2 MultiMeshes).
	var r := RandomNumberGenerator.new()
	r.seed = world_seed
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 1.0
	trunk_mesh.bottom_radius = 1.0
	trunk_mesh.height = 1.0
	var blob_mesh := SphereMesh.new()
	blob_mesh.radius = 1.0
	blob_mesh.height = 2.0
	var cap: int = grid * grid
	var trunks := _field(trunk_mesh, cap)
	var blobs := _field(blob_mesh, cap)
	sway.add_child(trunks)
	sway.add_child(blobs)
	var bark: Color = Color(0.34, 0.22, 0.13)
	var tcount: int = 0
	for gz2 in range(grid):
		for gx2 in range(grid):
			if r.randf() > tree_density:
				continue
			var u2: float = float(gx2) / float(grid - 1)
			var v2: float = float(gz2) / float(grid - 1)
			var h2: float = _height_at(noise, u2, v2)
			if not _is_life_band(h2):
				continue
			var px2: float = (u2 - 0.5) * world_span + (r.randf() - 0.5) * cell * 0.6
			var pz2: float = (v2 - 0.5) * world_span + (r.randf() - 0.5) * cell * 0.6
			var base_y: float = h2 * height_gain
			var rad: float = cell * r.randf_range(0.22, 0.34)
			var trunk_h: float = rad * r.randf_range(2.5, 3.5)
			trunks.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(rad * 0.4, trunk_h, rad * 0.4)),
				Vector3(px2, base_y + trunk_h * 0.5, pz2)
			))
			trunks.multimesh.set_instance_color(tcount, bark)
			blobs.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(rad, rad * 1.2, rad)),
				Vector3(px2, base_y + trunk_h + rad * 0.6, pz2)
			))
			blobs.multimesh.set_instance_color(tcount, forest_col.lerp(grass_col, r.randf()))
			tcount += 1
	trunks.multimesh.visible_instance_count = tcount
	blobs.multimesh.visible_instance_count = tcount

	# STRUCTURE — one small grammar tower on a seeded dry-high spot.
	_place_structure(noise, r, sway, cell)

	# Seed readout.
	add_child(_billboard_label("SEED %d" % world_seed, Vector3(0.0, top_y + height_gain + 0.22, 0.0), 18, label_col))
	add_child(_billboard_label("THE SEED PICKS THE NOISE, THE NOISE PICKS THE TERRAIN", Vector3(0.0, top_y + height_gain + 0.44, 0.0), 22, label_col))


func _place_structure(noise: FastNoiseLite, r: RandomNumberGenerator, parent: Node3D, cell: float) -> void:
	# stacked shrinking boxes — the simplest grammar: each storey is smaller than the last.
	var wall := _matte_mat(Color(0.66, 0.62, 0.55), 0.7)
	for _try in range(28):
		var gx: int = r.randi_range(1, grid - 2)
		var gz: int = r.randi_range(1, grid - 2)
		var u: float = float(gx) / float(grid - 1)
		var v: float = float(gz) / float(grid - 1)
		var h: float = _height_at(noise, u, v)
		if not _is_dry_high(h):
			continue
		var px: float = (u - 0.5) * world_span
		var pz: float = (v - 0.5) * world_span
		var y: float = h * height_gain
		var w: float = cell * 1.6
		var storeys: int = r.randi_range(2, 4)
		for s in range(storeys):
			var sw: float = w * (1.0 - 0.16 * float(s))
			var sh: float = w * 0.7
			parent.add_child(_box(Vector3(px, y + sh * 0.5, pz), Vector3(sw, sh, sw), wall))
			y += sh
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.25) * 0.10
