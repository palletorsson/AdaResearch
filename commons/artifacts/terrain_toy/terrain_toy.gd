extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TerrainToy

## @identity
## name: "Fractal terrain & clouds"
## tier: small
## lineage: fractional Brownian motion — Mandelbrot's recipe for mountains: noise plus noise plus noise
## essence: A held tile of fractal terrain, ~0.4m across. Stack a few octaves of noise — each
##   half the amplitude, twice the frequency — and the sum is a landscape: broad hills carry
##   medium ridges that carry fine bumps. The same wrinkle at every scale.
## truth: "NOISE AT EVERY SCALE = A MOUNTAIN" — roughness, layered, is a mountain
## applications: game worlds, clouds, coastlines — cheap geography from summed noise.

@export var grid: int = 24
@export var tile_span: float = 0.40
@export var octaves: int = 4
@export var height_gain: float = 0.16
@export var low_col: Color = Color(0.20, 0.55, 0.30)
@export var high_col: Color = Color(0.92, 0.94, 0.96)
@export var seed_val: int = 7

var _t: float = 0.0
var _sway: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 8, 48)
	if config.has("octaves"):
		octaves = clampi(int(config["octaves"]), 1, 6)
	if config.has("tile_span"):
		tile_span = float(config["tile_span"])
	if config.has("seed_val"):
		seed_val = int(config["seed_val"])
	if config.has("low_col"):
		low_col = _parse_color(config["low_col"], low_col)
	if config.has("high_col"):
		high_col = _parse_color(config["high_col"], high_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_build()


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _fbm(n: FastNoiseLite, x: float, y: float) -> float:
	var sum: float = 0.0
	var amp: float = 1.0
	var freq: float = 1.0
	var norm: float = 0.0
	for _o in range(octaves):
		sum += n.get_noise_2d(x * freq, y * freq) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return sum / maxf(norm, 0.001)


func _build() -> void:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.seed = seed_val
	n.frequency = 2.2

	var sway := Node3D.new()
	sway.name = "TerrainSway"
	add_child(sway)
	_sway = sway

	var count: int = grid * grid
	var field := _field(count, true)
	var cell: float = tile_span / float(grid)
	var box_mesh := field.multimesh.mesh as BoxMesh
	box_mesh.size = Vector3.ONE

	var idx: int = 0
	for gz in range(grid):
		for gx in range(grid):
			var u: float = float(gx) / float(grid - 1)
			var v: float = float(gz) / float(grid - 1)
			var h: float = (_fbm(n, u * 3.0, v * 3.0) * 0.5 + 0.5)
			var hh: float = h * height_gain
			var px: float = (u - 0.5) * tile_span
			var pz: float = (v - 0.5) * tile_span
			var xf := Transform3D(
				Basis().scaled(Vector3(cell * 0.95, maxf(hh, 0.004), cell * 0.95)),
				Vector3(px, hh * 0.5, pz)
			)
			field.multimesh.set_instance_transform(idx, xf)
			field.multimesh.set_instance_color(idx, low_col.lerp(high_col, h))
			idx += 1
	sway.add_child(field)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.4) * 0.12
