extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MorphoMenagerie

## @identity
## lineage: the room rung of the CA -> DNA morphogenesis bridge — one genome lineage, many coats.
## essence: a row of specimens, each grown by reaction-diffusion from the SAME genome with one gene varied
##   (pattern_type swept 0..1). The spotted-to-striped continuum is a single allele moving. Crossover and
##   mutation of the markings, made standable. Morphogenesis is a family, not a fixed thing.
## truth: the leopard and the zebra are two settings of one knob; the coat is the genome, run forward.
##
## PERF: each specimen is one MultiMesh field, RD pre-run once in _build (then mostly static); _process
## steps ONE specimen one tick per frame (round-robin) for subtle life — never a per-frame full rebuild.

const COLS := 18
const ROWS := 22
const N := 5
@export var seed_value: int = 11
@export var cell_size: float = 0.05
@export var prerun: int = 230
var _specs: Array = []
var _rr: int = 0
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_specs.clear()
	_build()


func _make_field(holder: Node3D) -> MultiMeshInstance3D:
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
			mm.set_instance_color(i, Color(0.05, 0.05, 0.06))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.14 if emissive else 0.0
	holder.add_child(mi)
	return mi


func _seed(spec: Dictionary, idx: int) -> void:
	var n := COLS * ROWS
	var u := PackedFloat32Array(); u.resize(n)
	var v := PackedFloat32Array(); v.resize(n)
	for i in range(n):
		u[i] = 1.0; v[i] = 0.0
	var lrng := RandomNumberGenerator.new(); lrng.seed = seed_value * 131 + idx
	for _k in range(14):
		var cx := lrng.randi_range(2, COLS - 3)
		var cy := lrng.randi_range(2, ROWS - 3)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var i := (cy + dy) * COLS + (cx + dx)
				if i >= 0 and i < n:
					v[i] = 0.9; u[i] = 0.2
	spec["u"] = u; spec["v"] = v


func _rd_step(spec: Dictionary) -> void:
	var u: PackedFloat32Array = spec["u"]
	var v: PackedFloat32Array = spec["v"]
	var F: float = spec["F"]
	var K: float = spec["K"]
	var nu := u.duplicate()
	var nv := v.duplicate()
	for y in range(ROWS):
		var yu := (y - 1 + ROWS) % ROWS
		var yd := (y + 1) % ROWS
		for x in range(COLS):
			var i := y * COLS + x
			var xl := (x - 1 + COLS) % COLS
			var xr := (x + 1) % COLS
			var uu: float = u[i]
			var vv: float = v[i]
			var lu: float = u[y * COLS + xl] * 0.2 + u[y * COLS + xr] * 0.2 + u[yu * COLS + x] * 0.2 + u[yd * COLS + x] * 0.2 + u[yu * COLS + xl] * 0.05 + u[yu * COLS + xr] * 0.05 + u[yd * COLS + xl] * 0.05 + u[yd * COLS + xr] * 0.05 - uu
			var lv: float = v[y * COLS + xl] * 0.2 + v[y * COLS + xr] * 0.2 + v[yu * COLS + x] * 0.2 + v[yd * COLS + x] * 0.2 + v[yu * COLS + xl] * 0.05 + v[yu * COLS + xr] * 0.05 + v[yd * COLS + xl] * 0.05 + v[yd * COLS + xr] * 0.05 - vv
			var uvv: float = uu * vv * vv
			nu[i] = clampf(uu + 0.16 * lu - uvv + F * (1.0 - uu), 0.0, 1.0)
			nv[i] = clampf(vv + 0.08 * lv + uvv - (F + K) * vv, 0.0, 1.0)
	spec["u"] = nu; spec["v"] = nv


func _paint(spec: Dictionary) -> void:
	var mm: MultiMesh = spec["field"].multimesh
	var v: PackedFloat32Array = spec["v"]
	var spot: Color = spec["spot"]
	var skin: Color = spec["skin"]
	for i in range(COLS * ROWS):
		mm.set_instance_color(i, skin.lerp(spot, smoothstep(0.12, 0.4, v[i])))


func _build() -> void:
	var dna: CritterDNA = CritterDNA.random(seed_value)   # the lineage's base genome
	var spot: Color = dna.primary_color.darkened(0.45)
	var skin: Color = dna.secondary_color.lerp(Color(0.96, 0.93, 0.86), 0.45)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(9, 0.1, 5), _matte_mat(Color(0.15, 0.16, 0.19), 0.9)))
	add_child(_billboard_label("ONE GENOME, MANY COATS\nmorphogenesis is a single allele moving", Vector3(0, 3.5, 0), 28, spot.lerp(Color.WHITE, 0.4)))
	var w := COLS * cell_size
	for idx in range(N):
		var pt: float = float(idx) / float(N - 1)            # sweep the pattern gene across the lineage
		var holder := Node3D.new()
		holder.position = Vector3((float(idx) - (N - 1) * 0.5) * 1.7 - w * 0.5, 1.3, 0.0)
		add_child(holder)
		add_child(_box(Vector3((float(idx) - (N - 1) * 0.5) * 1.7, 0.6, 0.3), Vector3(0.25, 1.2, 0.25), _steel_mat(Color(0.3, 0.32, 0.36))))
		var spec := {
			"field": _make_field(holder), "F": lerpf(0.022, 0.054, pt), "K": lerpf(0.051, 0.062, pt),
			"spot": spot, "skin": skin,
		}
		_seed(spec, idx)
		for _s in range(prerun):
			_rd_step(spec)
		_paint(spec)
		_specs.append(spec)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _specs.is_empty():
		return
	_t += delta
	if _t >= 0.1:
		_t = 0.0
		var spec: Dictionary = _specs[_rr % _specs.size()]   # round-robin: one specimen ticks per frame
		_rd_step(spec)
		_paint(spec)
		_rr += 1
