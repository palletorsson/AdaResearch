extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MorphoEgg

## @identity
## lineage: the held end of the CA -> DNA morphogenesis bridge — a genome paints a coat by reaction-diffusion.
##   The CA twin of the randomness seed->form bridge: there a genome grew a body, here it grows the skin.
## essence: CritterDNA's pattern genes (pattern_type/density) set the Gray-Scott parameters; the reaction-
##   diffusion CA grows the markings on the egg. Same genome -> same coat. Turing 1952: how a uniform egg
##   becomes a striped thing. Form by L-system, pattern by reaction-diffusion — one DNA, two grammars.
## truth: the skin is the genome run forward by chemistry; the markings were never drawn, only grown.
##
## PERF: one MultiMesh field; RD pre-run in _build so frame 1 shows a coat; _process steps a few RD ticks and
## updates colours only — never a geometry rebuild. Laplacian inlined (no per-cell function call).

const COLS := 26
const ROWS := 30
@export var seed_value: int = 7
@export var cell_size: float = 0.013
@export var prerun: int = 480
var _u: PackedFloat32Array
var _v: PackedFloat32Array
var _mask: PackedByteArray
var _field: MultiMeshInstance3D
var _F: float = 0.037
var _K: float = 0.06
var _spot: Color = Color(0.1, 0.08, 0.06)
var _skin: Color = Color(0.85, 0.75, 0.5)
var _nuclei: int = 14
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


# CritterDNA's pattern genes -> Gray-Scott (F,K) + nucleus count + coat colours.
func _derive_from_dna() -> void:
	var dna: CritterDNA = CritterDNA.random(seed_value)
	var pt: float = dna.pattern_type
	_F = lerpf(0.022, 0.054, pt)          # pattern_type sweeps the Gray-Scott zoo: stripes/maze -> spots/holes
	_K = lerpf(0.051, 0.062, pt)
	_nuclei = int(lerpf(6.0, 22.0, dna.pattern_density))
	_spot = dna.primary_color.darkened(0.45)                       # dark markings
	_skin = dna.secondary_color.lerp(Color(0.96, 0.93, 0.86), 0.45) # light coat — guarantees contrast


func _make_field() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(cell_size * 0.92, cell_size * 0.92, cell_size * 0.45)
	mm.mesh = bm
	mm.instance_count = COLS * ROWS
	for y in range(ROWS):
		for x in range(COLS):
			var i := y * COLS + x
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x * cell_size, y * cell_size, 0.0)))
			mm.set_instance_color(i, Color(0.03, 0.03, 0.04))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.12 if emissive else 0.0
	mi.material_override = mat
	return mi


func _egg_inside(x: int, y: int) -> bool:
	var dx: float = (float(x) - COLS * 0.5) / (COLS * 0.42)
	var dy: float = (float(y) - ROWS * 0.52) / (ROWS * 0.46)
	return dx * dx + dy * dy <= 1.0


func _seed_rd() -> void:
	var n := COLS * ROWS
	_u.resize(n); _v.resize(n); _mask.resize(n)
	var lrng := RandomNumberGenerator.new(); lrng.seed = seed_value
	for y in range(ROWS):
		for x in range(COLS):
			var i := y * COLS + x
			_u[i] = 1.0; _v[i] = 0.0
			_mask[i] = 1 if _egg_inside(x, y) else 0
	for _k in range(_nuclei):
		var cx := lrng.randi_range(3, COLS - 4)
		var cy := lrng.randi_range(3, ROWS - 4)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var i := (cy + dy) * COLS + (cx + dx)
				if i >= 0 and i < n:
					_v[i] = 0.9; _u[i] = 0.2


func _step_rd(steps: int) -> void:
	for _s in range(steps):
		var nu := _u.duplicate()
		var nv := _v.duplicate()
		for y in range(ROWS):
			var yu := (y - 1 + ROWS) % ROWS
			var yd := (y + 1) % ROWS
			for x in range(COLS):
				var i := y * COLS + x
				var xl := (x - 1 + COLS) % COLS
				var xr := (x + 1) % COLS
				var u: float = _u[i]
				var v: float = _v[i]
				var lu: float = _u[y * COLS + xl] * 0.2 + _u[y * COLS + xr] * 0.2 + _u[yu * COLS + x] * 0.2 + _u[yd * COLS + x] * 0.2 + _u[yu * COLS + xl] * 0.05 + _u[yu * COLS + xr] * 0.05 + _u[yd * COLS + xl] * 0.05 + _u[yd * COLS + xr] * 0.05 - u
				var lv: float = _v[y * COLS + xl] * 0.2 + _v[y * COLS + xr] * 0.2 + _v[yu * COLS + x] * 0.2 + _v[yd * COLS + x] * 0.2 + _v[yu * COLS + xl] * 0.05 + _v[yu * COLS + xr] * 0.05 + _v[yd * COLS + xl] * 0.05 + _v[yd * COLS + xr] * 0.05 - v
				var uvv: float = u * v * v
				nu[i] = clampf(u + 0.16 * lu - uvv + _F * (1.0 - u), 0.0, 1.0)
				nv[i] = clampf(v + 0.08 * lv + uvv - (_F + _K) * v, 0.0, 1.0)
		_u = nu; _v = nv


func _paint() -> void:
	var mm := _field.multimesh
	for i in range(COLS * ROWS):
		if _mask[i] == 0:
			mm.set_instance_color(i, Color(0.03, 0.03, 0.04))
		else:
			mm.set_instance_color(i, _skin.lerp(_spot, smoothstep(0.12, 0.4, _v[i])))


func _build() -> void:
	_derive_from_dna()
	_field = _make_field()
	var w := COLS * cell_size
	var h := ROWS * cell_size
	_field.position = Vector3(-w * 0.5, 1.0 - h * 0.5, 0.0)
	add_child(_field)
	add_child(_billboard_label("DNA -> coat   seed %d\nsame genome, same skin" % seed_value, Vector3(0.0, 1.0 + h * 0.5 + 0.1, 0.0), 15, _spot.lerp(Color.WHITE, 0.4)))
	_seed_rd()
	_step_rd(prerun)   # pre-run so the coat is already grown on the first captured frame
	_paint()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _t >= 0.09:
		_t = 0.0
		_step_rd(2)
		_paint()
