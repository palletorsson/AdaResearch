extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WorldForge

## @identity
## name: "Seed -> world"
## tier: applied
## lineage: the seed press — turn the dial, get a different world, at no cost; the place is never
##   stored, only its number and the rule that unfolds it
## essence: A world-forge. A seed dial counts up; every few seconds it lands on the next number and
##   a wholly new world appears on the platform — terrain, sea, forests and a tower or two — grown
##   from that seed alone. Nothing is saved between worlds; each is regenerated on demand. The
##   readout shows the live seed and the pipeline it runs: SEED -> NOISE -> TERRAIN -> LIFE.
## truth: "TURN THE DIAL, GET A NEW WORLD" — one seed becomes a world; the seed picks the noise, the
##   noise the terrain, the terrain the structures, the structures the life; design without a
##   designer, on tap.
## applications: streaming worlds, daily-seed games, on-demand content — store the seed, forge the world.

@export var world_seed: int = 1337
@export var grid: int = 16
@export var world_span: float = 0.82
@export var height_gain: float = 0.30
@export var water_level: float = 0.32
@export var regen_secs: float = 3.0
@export var seed_step: int = 1
@export var tree_density: float = 0.30
@export var body_col: Color = Color(0.20, 0.21, 0.25)
@export var deep_col: Color = Color(0.05, 0.16, 0.38)
@export var sand_col: Color = Color(0.80, 0.74, 0.50)
@export var grass_col: Color = Color(0.24, 0.54, 0.26)
@export var forest_col: Color = Color(0.13, 0.36, 0.18)
@export var rock_col: Color = Color(0.46, 0.43, 0.42)
@export var snow_col: Color = Color(0.93, 0.95, 0.97)
@export var water_col: Color = Color(0.18, 0.46, 0.72)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _since_regen: float = 0.0
var _platform: Node3D = null
var _world: Node3D = null
var _dial: Node3D = null
var _seed_label: Label3D = null
var _platform_y: float = 0.60


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
		grid = clampi(int(config["grid"]), 12, 24)
	if config.has("regen_secs"):
		regen_secs = maxf(float(config["regen_secs"]), 0.5)
	if config.has("world_span"):
		world_span = float(config["world_span"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_platform = null
	_world = null
	_dial = null
	_seed_label = null
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


# Regenerate the whole world from a seed: clear the world container, rebuild terrain,
# water, life and structures. Same seed -> same world, every time.
func _generate(use_seed: int) -> void:
	world_seed = use_seed
	if _world == null:
		return
	for c in _world.get_children():
		_world.remove_child(c)
		c.queue_free()

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
	_world.add_child(terrain)
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
	_world.add_child(_box(Vector3(0.0, wy * 0.5, 0.0), Vector3(world_span, maxf(wy, 0.005), world_span), _glass_mat(water_col, 0.42)))

	# LIFE — seeded scatter (trunks + canopies).
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
	_world.add_child(trunks)
	_world.add_child(canopies)
	var bark: Color = Color(0.33, 0.21, 0.13)
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
			var trunk_h: float = rad * r.randf_range(2.5, 3.6)
			trunks.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(rad * 0.38, trunk_h, rad * 0.38)),
				Vector3(px2, base_y + trunk_h * 0.5, pz2)
			))
			trunks.multimesh.set_instance_color(tcount, bark)
			canopies.multimesh.set_instance_transform(tcount, Transform3D(
				Basis().scaled(Vector3(rad, rad * 1.25, rad)),
				Vector3(px2, base_y + trunk_h + rad * 0.65, pz2)
			))
			canopies.multimesh.set_instance_color(tcount, forest_col.lerp(grass_col, r.randf()))
			tcount += 1
	trunks.multimesh.visible_instance_count = tcount
	canopies.multimesh.visible_instance_count = tcount

	# STRUCTURES — 1-2 grammar towers on seeded dry-high spots.
	var wall := _matte_mat(Color(0.66, 0.62, 0.55), 0.7)
	var roof := _matte_mat(Color(0.55, 0.22, 0.18), 0.7)
	var built: int = 0
	var want: int = r.randi_range(1, 2)
	for _try in range(40):
		if built >= want:
			break
		var sx: int = r.randi_range(1, grid - 2)
		var sz: int = r.randi_range(1, grid - 2)
		var su: float = float(sx) / float(grid - 1)
		var sv: float = float(sz) / float(grid - 1)
		var sh_norm: float = _height_at(noise, su, sv)
		if not _is_dry_high(sh_norm):
			continue
		var spx: float = (su - 0.5) * world_span
		var spz: float = (sv - 0.5) * world_span
		var y: float = sh_norm * height_gain
		var w: float = cell * 1.6
		var storeys: int = r.randi_range(2, 4)
		for s in range(storeys):
			var sw: float = w * (1.0 - 0.16 * float(s))
			var sh: float = w * 0.8
			_world.add_child(_box(Vector3(spx, y + sh * 0.5, spz), Vector3(sw, sh, sw), wall))
			y += sh
		_world.add_child(_box(Vector3(spx, y + w * 0.22, spz), Vector3(w * 0.5, w * 0.45, w * 0.5), roof))
		built += 1

	if _seed_label != null:
		_seed_label.text = "SEED %d" % world_seed


func _build() -> void:
	# Forge body + a recessed platform where the world is forged.
	add_child(_box(Vector3(0.0, 0.29, 0.0), Vector3(1.0, 0.58, 0.92), _matte_mat(body_col, 0.6, 0.2)))
	var plat := Node3D.new()
	plat.name = "Platform"
	plat.position = Vector3(0.0, _platform_y, 0.0)
	add_child(plat)
	_platform = plat
	plat.add_child(_box(Vector3(0.0, -0.015, 0.0), Vector3(world_span + 0.10, 0.03, world_span + 0.10), _matte_mat(Color(0.10, 0.11, 0.13), 0.5)))

	# World container — cleared and refilled on every regen.
	var world := Node3D.new()
	world.name = "World"
	plat.add_child(world)
	_world = world

	# SEED dial — a knob on the front face whose marker sweeps as the seed cycles.
	var dial := Node3D.new()
	dial.name = "SeedDial"
	dial.position = Vector3(0.40, 0.20, 0.48)
	add_child(dial)
	_dial = dial
	dial.add_child(_cylinder(Vector3.ZERO, 0.09, 0.04, _matte_mat(Color(0.13, 0.14, 0.16), 0.5)))
	dial.add_child(_box(Vector3(0.0, 0.03, 0.06), Vector3(0.02, 0.02, 0.07), _glow_mat(label_col, 1.8)))

	# Readouts.
	_seed_label = _billboard_label("SEED %d" % world_seed, Vector3(0.0, _platform_y + height_gain + 0.20, 0.0), 20, label_col)
	add_child(_seed_label)
	add_child(_billboard_label("SEED -> NOISE -> TERRAIN -> LIFE", Vector3(0.0, _platform_y + height_gain + 0.40, 0.0), 18, label_col))
	add_child(_billboard_label("WORLD FORGE", Vector3(0.0, _platform_y + height_gain + 0.60, 0.0), 24, label_col))

	# First world.
	_generate(world_seed)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_since_regen += delta
	# Dial sweeps continuously; world swivels so the player reads all sides.
	if _dial != null:
		_dial.rotation.y = _t * 1.6
	if _world != null:
		_world.rotation.y = _t * 0.4
	if _since_regen >= regen_secs:
		_since_regen = 0.0
		_generate(world_seed + seed_step)
