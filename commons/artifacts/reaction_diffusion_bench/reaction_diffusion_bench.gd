extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ReactionDiffusionBench

## @identity
## lineage: Turing 1952 morphogenesis -> Gray-Scott reaction-diffusion -> Pearson's parameter zoo
## essence: two chemicals, two numbers (feed F, kill K). Diffuse, react, and the plane
##   grows spots, then stripes, then a maze — all from local arithmetic, no painter.
## truth: a continuous cellular automaton. The RULE is fixed; the RUN is the deep thing.
##   Spots vs stripes vs maze is not in the equation, it is in the trajectory — the slow,
##   irreversible settling. Each (F,K) pair is a contingent universe; the alive middle is
##   the narrow band where pattern neither dies flat nor boils to noise.

@export var cols: int = 28
@export var rows: int = 28
@export var cell: float = 0.022
@export var feed: float = 0.0367
@export var kill: float = 0.0649
@export var diff_u: float = 0.16
@export var diff_v: float = 0.08
@export var reseed_seconds: float = 22.0
@export var color_low: Color = Color(0.04, 0.05, 0.10, 1.0)
@export var color_high: Color = Color(0.20, 0.95, 0.80, 1.0)

var _field: MultiMeshInstance3D
var _u: PackedFloat32Array
var _v: PackedFloat32Array
var _u2: PackedFloat32Array
var _v2: PackedFloat32Array
var _readout: Label3D
var _accum: float = 0.0
var _life: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("feed"):
		feed = float(config["feed"])
	if config.has("kill"):
		kill = float(config["kill"])
	if config.has("cols"):
		cols = int(config["cols"])
	if config.has("rows"):
		rows = int(config["rows"])
	for child in get_children():
		child.queue_free()
	_build()


func _make_field(field_cols: int, field_rows: int, field_cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(field_cell * 0.88, field_cell * 0.88, field_cell * 0.88)
	mm.mesh = bm
	mm.instance_count = field_cols * field_rows
	for r: int in range(field_rows):
		for c: int in range(field_cols):
			var i: int = r * field_cols + c
			var pos := Vector3(c * field_cell, r * field_cell, 0.0) if plane_xy else Vector3(c * field_cell, 0.0, r * field_cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, Color(0.05, 0.05, 0.07, 1.0))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# --- bench housing ---
	var top_mat := _matte_mat(Color(0.16, 0.17, 0.20))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.04, 0.6), top_mat))
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.0, 0.82, 0.5), _matte_mat(Color(0.10, 0.11, 0.13))))
	var pillar_mat := _steel_mat(Color(0.35, 0.36, 0.40))
	add_child(_cylinder(Vector3(0.0, 0.95, -0.18), 0.02, 0.18, pillar_mat))

	# --- label ---
	add_child(_billboard_label("REACTION-DIFFUSION\ntwo numbers paint every coat", Vector3(0.0, 1.6, 0.0), 30, color_high))

	# --- chemistry state ---
	var n: int = cols * rows
	_u = PackedFloat32Array()
	_v = PackedFloat32Array()
	_u.resize(n)
	_v.resize(n)
	_u2 = PackedFloat32Array()
	_v2 = PackedFloat32Array()
	_u2.resize(n)
	_v2.resize(n)
	_seed_chemistry()

	# --- field: VERTICAL on top, facing +Z ---
	_field = _make_field(cols, rows, cell, true)
	var span_x: float = float(cols - 1) * cell
	var span_y: float = float(rows - 1) * cell
	_field.position = Vector3(-span_x * 0.5, 0.87 + 0.30, 0.30)
	add_child(_field)

	# --- F/K readout ---
	_readout = _billboard_label(_fk_text(), Vector3(0.42, 1.18, 0.30), 18, Color(0.85, 0.90, 1.0))
	add_child(_readout)

	# pre-run so the first frame already shows pattern
	for _i: int in range(160):
		_step()
	_paint()
	_life = 0.0


func _seed_chemistry() -> void:
	var n: int = cols * rows
	for i: int in range(n):
		_u[i] = 1.0
		_v[i] = 0.0
	# a few random V blobs to break symmetry
	var blobs: int = 5
	for _b: int in range(blobs):
		var cx: int = _rng.randi_range(4, cols - 5)
		var cy: int = _rng.randi_range(4, rows - 5)
		for dy: int in range(-2, 3):
			for dx: int in range(-2, 3):
				var x: int = cx + dx
				var y: int = cy + dy
				if x >= 0 and x < cols and y >= 0 and y < rows:
					var idx: int = y * cols + x
					_v[idx] = 1.0
					_u[idx] = 0.5


func _step() -> void:
	var n: int = cols * rows
	for y: int in range(rows):
		for x: int in range(cols):
			var i: int = y * cols + x
			# 3x3 laplacian with wrap
			var xm: int = (x - 1 + cols) % cols
			var xp: int = (x + 1) % cols
			var ym: int = (y - 1 + rows) % rows
			var yp: int = (y + 1) % rows
			var i_l: int = y * cols + xm
			var i_r: int = y * cols + xp
			var i_u: int = ym * cols + x
			var i_d: int = yp * cols + x
			var i_ul: int = ym * cols + xm
			var i_ur: int = ym * cols + xp
			var i_dl: int = yp * cols + xm
			var i_dr: int = yp * cols + xp
			var lap_u: float = (_u[i_l] + _u[i_r] + _u[i_u] + _u[i_d]) * 0.2 \
				+ (_u[i_ul] + _u[i_ur] + _u[i_dl] + _u[i_dr]) * 0.05 - _u[i]
			var lap_v: float = (_v[i_l] + _v[i_r] + _v[i_u] + _v[i_d]) * 0.2 \
				+ (_v[i_ul] + _v[i_ur] + _v[i_dl] + _v[i_dr]) * 0.05 - _v[i]
			var uvv: float = _u[i] * _v[i] * _v[i]
			var nu: float = _u[i] + (diff_u * lap_u - uvv + feed * (1.0 - _u[i]))
			var nv: float = _v[i] + (diff_v * lap_v + uvv - (kill + feed) * _v[i])
			_u2[i] = clampf(nu, 0.0, 1.0)
			_v2[i] = clampf(nv, 0.0, 1.0)
	var tmp_u: PackedFloat32Array = _u
	_u = _u2
	_u2 = tmp_u
	var tmp_v: PackedFloat32Array = _v
	_v = _v2
	_v2 = tmp_v


func _paint() -> void:
	if _field == null:
		return
	var mm: MultiMesh = _field.multimesh
	var n: int = cols * rows
	for i: int in range(n):
		var t: float = clampf(_v[i] * 1.6, 0.0, 1.0)
		mm.set_instance_color(i, color_low.lerp(color_high, t))


func _fk_text() -> String:
	return "F %0.4f\nK %0.4f" % [feed, kill]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	_life += delta
	if _accum < 0.12:
		return
	_accum = 0.0
	# several solver iterations per visual step (Gray-Scott is slow per tick)
	for _k: int in range(6):
		_step()
	_paint()
	if _life >= reseed_seconds:
		_life = 0.0
		# drift to a new (F,K) universe within the interesting band, then reseed
		feed = clampf(feed + _rng.randf_range(-0.006, 0.006), 0.022, 0.050)
		kill = clampf(kill + _rng.randf_range(-0.004, 0.004), 0.055, 0.068)
		_seed_chemistry()
		for _i: int in range(120):
			_step()
		if _readout != null:
			_readout.text = _fk_text()
