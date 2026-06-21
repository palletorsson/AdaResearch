extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SeedWorldToy

## @identity
## name: "Seed -> world"
## tier: small
## lineage: the demoscene seed — a whole scene packed into one integer, unpacked by a rule
## essence: A whole little world held in the hand. From one number a heightfield is grown, a
##   sea poured to a level, a few trees scattered where it is green, and one hut stood on dry
##   high ground. Nothing here was drawn; it was all read out of the seed.
## truth: "A WORLD IN YOUR HAND, GROWN FROM ONE NUMBER" — one seed becomes a world; the seed
##   picks the noise, the noise the terrain, the terrain the structures, the structures the
##   life; design without a designer.
## applications: procedural sandboxes, seed-share worlds, tiny generators — store the number, grow the place.

@export var world_seed: int = 1337
@export var grid: int = 12
@export var world_span: float = 0.40
@export var height_gain: float = 0.12
@export var water_level: float = 0.30
@export var center_y: float = 0.5
@export var deep_col: Color = Color(0.06, 0.18, 0.40)
@export var sand_col: Color = Color(0.80, 0.74, 0.50)
@export var grass_col: Color = Color(0.24, 0.54, 0.26)
@export var forest_col: Color = Color(0.13, 0.36, 0.18)
@export var rock_col: Color = Color(0.46, 0.43, 0.42)
@export var snow_col: Color = Color(0.93, 0.95, 0.97)
@export var water_col: Color = Color(0.18, 0.46, 0.72)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _world: Node3D = null


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
		grid = clampi(int(config["grid"]), 8, 18)
	if config.has("world_span"):
		world_span = float(config["world_span"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_world = null
	_build()


# --- height -> band ----------------------------------------------------------
# bands by normalized height h in [0,1]:
#   < water_level         deep / shallow water bed
#   sand   just above water
#   grass / forest        the living band
#   rock                  high and bare
#   snow   > 0.70

func _band_color(h: float) -> Color:
	if h < water_level - 0.06:
		return deep_col
	if h < water_level:
		return deep_col.lerp(sand_col, (h - (water_level - 0.06)) / 0.06)
	if h < water_level + 0.06:
		return sand_col
	if h < 0.52:
		return grass_col
	if h < 0.64:
		return forest_col
	if h < 0.74:
		return rock_col
	return snow_col


func _is_life_band(h: float) -> bool:
	return h >= water_level + 0.06 and h < 0.64


func _is_dry_high(h: float) -> bool:
	return h >= 0.58 and h < 0.74


# --- multimesh field factory -------------------------------------------------

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
	# A hand-sized world, floating near origin.
	var world := Node3D.new()
	world.name = "World"
	world.position = Vector3(0.0, center_y, 0.0)
	add_child(world)
	_world = world

	# noise from the seed -> the whole pipeline downstream is determined.
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	noise.fractal_octaves = 4

	# 1+2) HEIGHTFIELD -> terrain, ONE MultiMesh of boxes colored by band.
	var cell: float = world_span / float(grid)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var terrain := _field(box, grid * grid)
	world.add_child(terrain)

	var idx: int = 0
	for gz in range(grid):
		for gx in range(grid):
			var u: float = float(gx) / float(grid - 1)
			var v: float = float(gz) / float(grid - 1)
			var h: float = _height_at(noise, u, v)
			var hh: float = maxf(h * height_gain, 0.004)
			var px: float = (u - 0.5) * world_span
			var pz: float = (v - 0.5) * world_span
			# box top sits at the cell height: top = hh, so center = hh/2, scale.y = hh
			var xf := Transform3D(
				Basis().scaled(Vector3(cell * 0.96, hh, cell * 0.96)),
				Vector3(px, hh * 0.5, pz)
			)
			terrain.multimesh.set_instance_transform(idx, xf)
			terrain.multimesh.set_instance_color(idx, _band_color(h))
			idx += 1

	# 3) WATER — one translucent slab at sea level.
	var wy: float = water_level * height_gain
	world.add_child(_box(Vector3(0.0, wy * 0.5, 0.0), Vector3(world_span, maxf(wy, 0.004), world_span), _glass_mat(water_col, 0.45)))

	# 4) LIFE — a SECOND MultiMesh of little trees on the green band. Seeded local RNG.
	var r := RandomNumberGenerator.new()
	r.seed = world_seed
	var tree_mesh := SphereMesh.new()
	tree_mesh.radius = 1.0
	tree_mesh.height = 2.0
	var max_trees: int = grid * grid
	var trees := _field(tree_mesh, max_trees)
	world.add_child(trees)
	var tcount: int = 0
	for gz2 in range(grid):
		for gx2 in range(grid):
			if r.randf() > 0.28:
				continue
			var u2: float = float(gx2) / float(grid - 1)
			var v2: float = float(gz2) / float(grid - 1)
			var h2: float = _height_at(noise, u2, v2)
			if not _is_life_band(h2):
				continue
			var jx: float = (r.randf() - 0.5) * cell * 0.6
			var jz: float = (r.randf() - 0.5) * cell * 0.6
			var px2: float = (u2 - 0.5) * world_span + jx
			var pz2: float = (v2 - 0.5) * world_span + jz
			var hh2: float = h2 * height_gain
			var blob: float = cell * r.randf_range(0.5, 0.85)
			trees.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(blob, blob * 1.4, blob)),
				Vector3(px2, hh2 + blob * 0.9, pz2)
			))
			var leaf: Color = forest_col.lerp(grass_col, r.randf())
			trees.multimesh.set_instance_color(tcount, leaf)
			tcount += 1
	trees.multimesh.visible_instance_count = tcount

	# 5) STRUCTURE — one little hut on a seeded dry-high spot (stacked shrinking boxes).
	_place_one_hut(noise, r, world, cell)

	add_child(_billboard_label("seed %d" % world_seed, Vector3(0.0, center_y + world_span * 0.55 + 0.10, 0.0), 13, label_col))


func _place_one_hut(noise: FastNoiseLite, r: RandomNumberGenerator, world: Node3D, cell: float) -> void:
	# scan a handful of seeded candidates, take the first dry-high one.
	var wood := _matte_mat(Color(0.42, 0.28, 0.16), 0.8)
	var roof := _matte_mat(Color(0.62, 0.20, 0.16), 0.7)
	for _try in range(24):
		var gx: int = r.randi_range(1, grid - 2)
		var gz: int = r.randi_range(1, grid - 2)
		var u: float = float(gx) / float(grid - 1)
		var v: float = float(gz) / float(grid - 1)
		var h: float = _height_at(noise, u, v)
		if not _is_dry_high(h):
			continue
		var px: float = (u - 0.5) * world_span
		var pz: float = (v - 0.5) * world_span
		var base_y: float = h * height_gain
		var w: float = cell * 1.4
		world.add_child(_box(Vector3(px, base_y + w * 0.5, pz), Vector3(w, w, w), wood))
		world.add_child(_box(Vector3(px, base_y + w * 1.15, pz), Vector3(w * 0.7, w * 0.5, w * 0.7), roof))
		return


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _world != null:
		_world.rotation.y = _t * 0.25
