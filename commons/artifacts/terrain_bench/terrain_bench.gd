extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TerrainBench

## @identity
## name: "Fractal terrain & clouds"
## tier: medium
## lineage: fBm landscape — Mandelbrot/Fournier (1982), the first fake mountains in graphics
## essence: A fractal landscape on a bench, with an octaves dial beside it. One octave is a
##   smooth swell; add the next and ridges appear; add the next and the ridges grow crags.
##   Turn the dial and watch detail arrive scale by scale. The mountain is just roughness,
##   summed.
## truth: "NOISE AT EVERY SCALE = A MOUNTAIN" — terrain is self-similar wrinkle
## applications: procedural worlds, heightmaps, terrain LOD — geography you never have to author.

@export var grid: int = 36
@export var land_span: float = 0.78
@export var octaves: int = 4
@export var height_gain: float = 0.34
@export var top_y: float = 0.86
@export var bench_color: Color = Color(0.18, 0.19, 0.22)
@export var low_col: Color = Color(0.18, 0.52, 0.28)
@export var mid_col: Color = Color(0.55, 0.50, 0.34)
@export var high_col: Color = Color(0.94, 0.95, 0.97)
@export var label_col: Color = Color(0.80, 0.86, 0.94)
@export var seed_val: int = 11

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
		grid = clampi(int(config["grid"]), 12, 56)
	if config.has("octaves"):
		octaves = clampi(int(config["octaves"]), 1, 6)
	if config.has("land_span"):
		land_span = float(config["land_span"])
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


func _ramp(h: float) -> Color:
	if h < 0.5:
		return low_col.lerp(mid_col, h / 0.5)
	return mid_col.lerp(high_col, (h - 0.5) / 0.5)


func _build() -> void:
	# Bench base + top
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.12, 0.04, 0.72), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))
	add_child(_cylinder(Vector3(0.0, 0.20, 0.0), 0.05, 0.40, _steel_mat(Color(0.35, 0.37, 0.4))))

	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.seed = seed_val
	n.frequency = 2.0

	var sway := Node3D.new()
	sway.name = "TerrainSway"
	add_child(sway)
	_sway = sway

	var count: int = grid * grid
	var field := _field(count, true)
	var cell: float = land_span / float(grid)
	var box_mesh := field.multimesh.mesh as BoxMesh
	box_mesh.size = Vector3.ONE
	field.position = Vector3(0.0, top_y + 0.02, 0.0)

	var idx: int = 0
	for gz in range(grid):
		for gx in range(grid):
			var u: float = float(gx) / float(grid - 1)
			var v: float = float(gz) / float(grid - 1)
			var h: float = (_fbm(n, u * 3.0, v * 3.0) * 0.5 + 0.5)
			var hh: float = h * height_gain
			var px: float = (u - 0.5) * land_span
			var pz: float = (v - 0.5) * land_span
			var xf := Transform3D(
				Basis().scaled(Vector3(cell * 0.95, maxf(hh, 0.005), cell * 0.95)),
				Vector3(px, hh * 0.5, pz)
			)
			field.multimesh.set_instance_transform(idx, xf)
			field.multimesh.set_instance_color(idx, _ramp(h))
			idx += 1
	sway.add_child(field)

	# Octaves dial — a small knob with a marker pointing at the octave count.
	var dial_base := Vector3(0.52, top_y + 0.02, 0.0)
	add_child(_cylinder(dial_base, 0.06, 0.04, _matte_mat(Color(0.12, 0.13, 0.15), 0.5)))
	var ang: float = (float(octaves) / 6.0) * TAU
	var marker := dial_base + Vector3(cos(ang) * 0.05, 0.03, sin(ang) * 0.05)
	add_child(_sphere(marker, 0.012, _glow_mat(high_col, 1.6)))
	add_child(_billboard_label("OCT %d" % octaves, dial_base + Vector3(0.0, 0.12, 0.0), 14, label_col))

	add_child(_billboard_label("NOISE AT EVERY SCALE = A MOUNTAIN", Vector3(0.0, 1.6, 0.0), 26, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.3) * 0.06
