extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MorphogenesisBench

## @identity
## lineage: the bench rung of the CA -> DNA morphogenesis bridge — scrub the pattern gene, the coat re-grows.
## essence: CritterDNA's pattern_type drives the Gray-Scott (F,K); as it drifts, the reaction-diffusion coat
##   morphs spots -> stripes -> maze. The gene-bars on the panel ARE the genome; the markings are downstream.
## truth: the same chemistry, two numbers apart, is a leopard or a zebra — the coat is the genome, run.
##
## PERF: one MultiMesh field; RD pre-run in _build; _process drifts F/K slightly and steps a few RD ticks,
## updating colours only (Gray-Scott adapts to the moving parameters without a reseed). Laplacian inlined.

const COLS := 32
const ROWS := 24
const BASE_Y := 0.86
@export var seed_value: int = 3
@export var cell_size: float = 0.017
@export var prerun: int = 460
@export var drift_speed: float = 0.018
var _u: PackedFloat32Array
var _v: PackedFloat32Array
var _field: MultiMeshInstance3D
var _panel: Node3D
var _pt: float = 0.5
var _density: float = 0.5
var _pscale: float = 1.0
var _F: float = 0.037
var _K: float = 0.06
var _spot: Color = Color(0.12, 0.09, 0.06)
var _skin: Color = Color(0.85, 0.75, 0.5)
var _t: float = 0.0
var _drift_dir: float = 1.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed_value"): seed_value = int(config["seed_value"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _fk_from_pt() -> void:
	_F = lerpf(0.022, 0.054, _pt)
	_K = lerpf(0.051, 0.062, _pt)


func _make_field() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(cell_size * 0.92, cell_size * 0.92, cell_size * 0.5)
	mm.mesh = bm
	mm.instance_count = COLS * ROWS
	for y in range(ROWS):
		for x in range(COLS):
			var i := y * COLS + x
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x * cell_size, y * cell_size, 0.0)))
			mm.set_instance_color(i, _skin)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.12 if emissive else 0.0
	mi.material_override = mat
	return mi


func _seed_rd() -> void:
	var n := COLS * ROWS
	_u.resize(n); _v.resize(n)
	var lrng := RandomNumberGenerator.new(); lrng.seed = seed_value
	for i in range(n):
		_u[i] = 1.0; _v[i] = 0.0
	var nuclei := int(lerpf(8.0, 26.0, _density))
	for _k in range(nuclei):
		var cx := lrng.randi_range(2, COLS - 3)
		var cy := lrng.randi_range(2, ROWS - 3)
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
		mm.set_instance_color(i, _skin.lerp(_spot, smoothstep(0.12, 0.4, _v[i])))


func _draw_panel() -> void:
	for c in _panel.get_children():
		_panel.remove_child(c); c.queue_free()
	var genes := [["type", _pt, _spot], ["density", _density, _skin.lerp(Color.WHITE, 0.3)], ["scale", _pscale / 3.0, _spot.lerp(Color.WHITE, 0.4)]]
	for i in range(genes.size()):
		var h: float = clampf(float(genes[i][1]), 0.05, 1.0) * 0.24
		_panel.add_child(_box(Vector3(float(i) * 0.08 - 0.08, h * 0.5 - 0.12, 0.0), Vector3(0.055, h, 0.02), _glow_mat(genes[i][2], 0.6)))


func _build() -> void:
	var dna: CritterDNA = CritterDNA.random(seed_value)
	_pt = dna.pattern_type; _density = dna.pattern_density; _pscale = dna.pattern_scale
	_spot = dna.primary_color.darkened(0.45)
	_skin = dna.secondary_color.lerp(Color(0.96, 0.93, 0.86), 0.45)
	_fk_from_pt()
	# bench
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(1.2, 0.18, 0.7), _matte_mat(Color(0.16, 0.17, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0, (BASE_Y - 0.2) * 0.5, 0), 0.07, BASE_Y - 0.2, _steel_mat(Color(0.32, 0.34, 0.4))))
	add_child(_billboard_label("MORPHOGENESIS\nthe genome paints the coat (Turing)", Vector3(0, BASE_Y + 0.95, 0), 17, _spot.lerp(Color.WHITE, 0.4)))
	# the coat field, standing on the bench
	_field = _make_field()
	var w := COLS * cell_size
	_field.position = Vector3(-w * 0.5 - 0.12, BASE_Y + 0.06, -0.02)
	add_child(_field)
	# gene-bar panel
	_panel = Node3D.new(); _panel.position = Vector3(0.42, BASE_Y + 0.34, -0.2); add_child(_panel)
	_seed_rd()
	_step_rd(prerun)
	_paint()
	_draw_panel()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _t >= 0.09:
		_t = 0.0
		_pt += drift_speed * _drift_dir * 0.1   # the pattern gene drifts; the coat follows
		if _pt > 0.92 or _pt < 0.08:
			_drift_dir = -_drift_dir
			_pt = clampf(_pt, 0.08, 0.92)
		_fk_from_pt()
		_step_rd(2)
		_paint()
		_draw_panel()
