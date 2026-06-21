extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TerrainWorldGenerator

## @identity
## name: Terrain World Generator
## tier: applied
## concept: Generated worlds
## truth: a world meshed live from a few numbers.

@export var grid_n: int = 20               # heightfield resolution (grid_n x grid_n)
@export var world_extent: float = 0.9      # half-width of the terrain patch in metres
@export var height_scale: float = 0.45     # max terrain height above platform
@export var regen_seconds: float = 3.0
@export var platform_y: float = 0.85

var _mm_instance: MultiMeshInstance3D = null
var _noise: FastNoiseLite = null
var _readout: Label3D = null
var _seed_n: int = 0
var _accum: float = 0.0
var _band_colors: Array[Color] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_accum = 0.0

	# Device platform (the terrain sits on top of it)
	var base_mat := _steel_mat(Color(0.16, 0.18, 0.22))
	add_child(_box(Vector3(0.0, platform_y * 0.5, 0.0), Vector3(world_extent * 2.0 + 0.2, platform_y, world_extent * 2.0 + 0.2), base_mat))

	# Label
	add_child(_billboard_label("TERRAIN WORLD", Vector3(0.0, platform_y + height_scale + 0.7, 0.0), 22, Color(0.8, 0.95, 0.85)))

	# Height-band palette (water -> sand -> grass -> rock -> snow)
	_band_colors = [
		Color(0.2, 0.4, 0.75),    # water
		Color(0.85, 0.78, 0.5),   # sand
		Color(0.3, 0.6, 0.3),     # grass
		Color(0.45, 0.42, 0.4),   # rock
		Color(0.95, 0.96, 1.0),   # snow
	]

	# Noise
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.12
	_noise.fractal_octaves = 4

	# MultiMesh of height-banded boxes
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	var cell: float = (world_extent * 2.0) / float(max(grid_n, 1))
	box.size = Vector3(cell, 1.0, cell)   # y scaled per-instance via transform
	mm.mesh = box
	mm.instance_count = grid_n * grid_n

	_mm_instance = MultiMeshInstance3D.new()
	_mm_instance.name = "Terrain"
	_mm_instance.multimesh = mm
	# vertex-colored material that respects per-instance colors
	var terrain_mat := _matte_mat(Color(1, 1, 1), 0.85)
	terrain_mat.vertex_color_use_as_albedo = true
	_mm_instance.material_override = terrain_mat
	add_child(_mm_instance)

	# Readout
	_readout = _billboard_label("SEED: 0", Vector3(0.0, platform_y + height_scale + 0.5, 0.0), 18, Color(0.9, 0.95, 1.0))
	add_child(_readout)

	_regenerate()


func _regenerate() -> void:
	_seed_n = _rng.randi_range(1, 99999)
	_noise.seed = _seed_n

	var mm: MultiMesh = _mm_instance.multimesh
	var n: int = grid_n
	var cell: float = (world_extent * 2.0) / float(max(n, 1))
	var origin: float = -world_extent + cell * 0.5
	var water_level: float = 0.18    # normalized height threshold for water

	var idx: int = 0
	for gx in range(n):
		for gz in range(n):
			var wx: float = origin + float(gx) * cell
			var wz: float = origin + float(gz) * cell
			# normalized noise 0..1
			var raw: float = _noise.get_noise_2d(float(gx), float(gz)) * 0.5 + 0.5
			raw = clampf(raw, 0.0, 1.0)
			# height: water cells flatten to a sea plane
			var h_norm: float = raw
			if h_norm < water_level:
				h_norm = water_level
			var col_h: float = h_norm * height_scale
			# column center sits on the platform top
			var top: float = platform_y
			var cy: float = top + col_h * 0.5

			var band: int = _band_for(raw, water_level)
			var col: Color = _band_colors[band]

			var xf := Transform3D(Basis().scaled(Vector3(1.0, maxf(col_h, 0.02), 1.0)), Vector3(wx, cy, wz))
			mm.set_instance_transform(idx, xf)
			mm.set_instance_color(idx, col)
			idx += 1

	if _readout != null:
		_readout.text = "SEED: %d" % _seed_n


func _band_for(raw: float, water_level: float) -> int:
	if raw < water_level:
		return 0   # water
	if raw < water_level + 0.08:
		return 1   # sand
	if raw < 0.55:
		return 2   # grass
	if raw < 0.78:
		return 3   # rock
	return 4       # snow


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < regen_seconds:
		return
	_accum = 0.0
	_regenerate()
