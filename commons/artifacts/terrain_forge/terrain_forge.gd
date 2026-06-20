extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TerrainForge

## @identity
## name: "Fractal terrain & clouds"
## tier: applied
## lineage: the seed press — change one integer and a whole world appears, costs nothing to retry
## essence: A terrain-forge device. A stamp emits a fresh fBm landscape patch, then re-stamps a
##   new seed every couple of seconds. Each press is a different mountain from the same recipe:
##   the geography is not stored, it is regenerated on demand from a number.
## truth: "NOISE AT EVERY SCALE = A MOUNTAIN" — a seed and a rule out-make any stored map
## applications: infinite worlds, on-the-fly content, streaming terrain — store the seed, not the land.

@export var grid: int = 28
@export var land_span: float = 0.80
@export var octaves: int = 4
@export var height_gain: float = 0.30
@export var restamp_secs: float = 2.0
@export var body_col: Color = Color(0.21, 0.22, 0.26)
@export var low_col: Color = Color(0.18, 0.52, 0.28)
@export var mid_col: Color = Color(0.55, 0.50, 0.34)
@export var high_col: Color = Color(0.94, 0.95, 0.97)
@export var label_col: Color = Color(0.82, 0.88, 0.96)

var _t: float = 0.0
var _since_stamp: float = 0.0
var _seed: int = 1
var _field_node: MultiMeshInstance3D = null
var _stamp_head: Node3D = null
var _seed_label: Label3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 12, 48)
	if config.has("octaves"):
		octaves = clampi(int(config["octaves"]), 1, 6)
	if config.has("restamp_secs"):
		restamp_secs = float(config["restamp_secs"])
	if config.has("low_col"):
		low_col = _parse_color(config["low_col"], low_col)
	if config.has("high_col"):
		high_col = _parse_color(config["high_col"], high_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_field_node = null
	_stamp_head = null
	_seed_label = null
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


func _stamp(new_seed: int) -> void:
	_seed = new_seed
	if _field_node == null:
		return
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.seed = _seed
	n.frequency = 2.0
	var cell: float = land_span / float(grid)
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
			_field_node.multimesh.set_instance_transform(idx, xf)
			_field_node.multimesh.set_instance_color(idx, _ramp(h))
			idx += 1
	if _seed_label != null:
		_seed_label.text = "SEED %d" % _seed


func _build() -> void:
	# Forge body + a recessed bed where the patch is stamped.
	add_child(_box(Vector3(0.0, 0.28, 0.0), Vector3(1.0, 0.56, 0.9), _matte_mat(body_col, 0.6, 0.2)))
	add_child(_box(Vector3(0.0, 0.57, 0.0), Vector3(land_span + 0.1, 0.02, land_span + 0.1), _matte_mat(Color(0.10, 0.11, 0.13), 0.5)))

	# The stamp head — a press above the bed that drops to "stamp".
	var head := Node3D.new()
	head.name = "StampHead"
	head.position = Vector3(0.0, 0.95, 0.0)
	add_child(head)
	_stamp_head = head
	head.add_child(_box(Vector3.ZERO, Vector3(land_span * 0.5, 0.06, land_span * 0.5), _steel_mat(Color(0.5, 0.52, 0.56))))
	head.add_child(_cylinder(Vector3(0.0, 0.14, 0.0), 0.03, 0.22, _steel_mat(Color(0.4, 0.42, 0.46))))

	# Terrain field sitting in the bed.
	var count: int = grid * grid
	_field_node = _field(count, true)
	(_field_node.multimesh.mesh as BoxMesh).size = Vector3.ONE
	_field_node.position = Vector3(0.0, 0.59, 0.0)
	add_child(_field_node)

	_seed_label = _billboard_label("SEED %d" % _seed, Vector3(0.0, 1.18, 0.0), 16, high_col)
	add_child(_seed_label)
	add_child(_billboard_label("TERRAIN FORGE", Vector3(0.0, 1.42, 0.0), 22, label_col))

	# First stamp.
	_stamp(int(_rng.randi_range(1, 99999)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_since_stamp += delta
	# Press animation: bob the head, and on the timer drop fully + re-stamp.
	if _stamp_head != null:
		var phase: float = clampf(_since_stamp / maxf(restamp_secs, 0.1), 0.0, 1.0)
		# ease down toward the end of the cycle, snap back at restamp
		var drop: float = 0.0
		if phase > 0.85:
			drop = (phase - 0.85) / 0.15 * 0.30
		_stamp_head.position.y = 0.95 - drop
	if _since_stamp >= restamp_secs:
		_since_stamp = 0.0
		_stamp(int(_rng.randi_range(1, 99999)))
