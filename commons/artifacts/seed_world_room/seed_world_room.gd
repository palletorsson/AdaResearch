extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SeedWorldRoom

## @identity
## name: "Seed -> world"
## tier: large
## lineage: the generated landscape — a place you stand in that no one drew, only specified
## essence: A room-scale world grown from one number. The seed sets the noise; the noise lifts the
##   land into hills and valleys; a sea fills the low ground; forests scatter across the green
##   slopes; a few towers and huts stand on the dry high spots. You walk beside terrain, water and
##   settlement that were never authored cell by cell — only the rule was, and the seed.
## truth: "NO ARCHITECT DREW THIS; THE SEED DID" — one seed becomes a world; the seed picks the
##   noise, the noise the terrain, the terrain the structures, the structures the life; design
##   without a designer.
## applications: open-world generation, level streaming, infinite landscapes — ship the seed and the rule.

@export var world_seed: int = 1337
@export var grid: int = 28
@export var world_span: float = 6.6
@export var height_gain: float = 2.4
@export var water_level: float = 0.34
@export var floor_y: float = -0.05
@export var tree_density: float = 0.34
@export var deep_col: Color = Color(0.04, 0.14, 0.34)
@export var sand_col: Color = Color(0.80, 0.74, 0.50)
@export var grass_col: Color = Color(0.24, 0.54, 0.26)
@export var forest_col: Color = Color(0.12, 0.34, 0.17)
@export var rock_col: Color = Color(0.46, 0.43, 0.42)
@export var snow_col: Color = Color(0.93, 0.95, 0.97)
@export var water_col: Color = Color(0.16, 0.44, 0.70)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _world: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(false)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("world_seed"):
		world_seed = int(config["world_seed"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 16, 40)
	if config.has("world_span"):
		world_span = float(config["world_span"])
	if config.has("water_level"):
		water_level = clampf(float(config["water_level"]), 0.0, 0.9)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_world = null
	_build()


func _band_color(h: float) -> Color:
	if h < water_level - 0.07:
		return deep_col
	if h < water_level:
		return deep_col.lerp(sand_col, (h - (water_level - 0.07)) / 0.07)
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
	return h >= 0.56 and h < 0.76


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
	mat.emission_energy_multiplier = 0.14 if emissive else 0.0
	mi.material_override = mat
	return mi


func _height_at(n: FastNoiseLite, u: float, v: float) -> float:
	return n.get_noise_2d(u * 100.0, v * 100.0) * 0.5 + 0.5


func _build() -> void:
	var world := Node3D.new()
	world.name = "World"
	world.position = Vector3(0.0, floor_y, 0.0)
	add_child(world)
	_world = world

	# one seed -> one noise -> the whole place.
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08
	noise.fractal_octaves = 4

	# TERRAIN — ONE MultiMesh of NxN boxes across the floor.
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
			var hh: float = maxf(h * height_gain, 0.02)
			var px: float = (u - 0.5) * world_span
			var pz: float = (v - 0.5) * world_span
			terrain.multimesh.set_instance_transform(idx, Transform3D(
				Basis().scaled(Vector3(cell * 0.98, hh, cell * 0.98)),
				Vector3(px, hh * 0.5, pz)
			))
			terrain.multimesh.set_instance_color(idx, _band_color(h))
			idx += 1

	# WATER — a translucent sea slab at sea level across the whole patch.
	var wy: float = water_level * height_gain
	world.add_child(_box(Vector3(0.0, wy * 0.5, 0.0), Vector3(world_span, maxf(wy, 0.02), world_span), _glass_mat(water_col, 0.40)))

	# LIFE — forests: a second + third MultiMesh (trunks, canopies), seeded scatter.
	var r := RandomNumberGenerator.new()
	r.seed = world_seed
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 1.0
	trunk_mesh.bottom_radius = 1.0
	trunk_mesh.height = 1.0
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 1.0
	canopy_mesh.height = 2.0
	var cap: int = grid * grid
	var trunks := _field(trunk_mesh, cap)
	var canopies := _field(canopy_mesh, cap)
	world.add_child(trunks)
	world.add_child(canopies)
	var bark: Color = Color(0.32, 0.21, 0.12)
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
			var rad: float = cell * r.randf_range(0.20, 0.32)
			var trunk_h: float = rad * r.randf_range(2.8, 4.2)
			trunks.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(rad * 0.35, trunk_h, rad * 0.35)),
				Vector3(px2, base_y + trunk_h * 0.5, pz2)
			))
			trunks.multimesh.set_instance_color(tcount, bark)
			canopies.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(rad, rad * 1.3, rad)),
				Vector3(px2, base_y + trunk_h + rad * 0.7, pz2)
			))
			canopies.multimesh.set_instance_color(tcount, forest_col.lerp(grass_col, r.randf()))
			tcount += 1
	trunks.multimesh.visible_instance_count = tcount
	canopies.multimesh.visible_instance_count = tcount

	# STRUCTURES — a few grammar-built towers/huts on seeded dry-high spots.
	_place_structures(noise, r, world, cell)

	# Overhead title.
	add_child(_billboard_label("DESIGN WITHOUT A DESIGNER", Vector3(0.0, 3.6, 0.0), 34, label_col))
	add_child(_billboard_label("seed %d  —  no architect drew this; the seed did" % world_seed, Vector3(0.0, 3.2, 0.0), 18, label_col))


func _place_structures(noise: FastNoiseLite, r: RandomNumberGenerator, world: Node3D, cell: float) -> void:
	var wall := _matte_mat(Color(0.66, 0.62, 0.55), 0.7)
	var roof := _matte_mat(Color(0.55, 0.22, 0.18), 0.7)
	var built: int = 0
	var want: int = r.randi_range(3, 4)
	for _try in range(60):
		if built >= want:
			break
		var gx: int = r.randi_range(2, grid - 3)
		var gz: int = r.randi_range(2, grid - 3)
		var u: float = float(gx) / float(grid - 1)
		var v: float = float(gz) / float(grid - 1)
		var h: float = _height_at(noise, u, v)
		if not _is_dry_high(h):
			continue
		var px: float = (u - 0.5) * world_span
		var pz: float = (v - 0.5) * world_span
		var y: float = h * height_gain
		var w: float = cell * r.randf_range(1.4, 2.0)
		# grammar: stacked shrinking boxes, then a cap.
		var storeys: int = r.randi_range(2, 5)
		for s in range(storeys):
			var sw: float = w * (1.0 - 0.15 * float(s))
			var sh: float = w * 0.8
			world.add_child(_box(Vector3(px, y + sh * 0.5, pz), Vector3(sw, sh, sw), wall))
			y += sh
		# pyramidal cap (a small shrunk box) so towers read as roofed.
		world.add_child(_box(Vector3(px, y + w * 0.25, pz), Vector3(w * 0.55, w * 0.5, w * 0.55), roof))
		built += 1


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
