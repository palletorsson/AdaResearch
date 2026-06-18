extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LeniaAquarium

## @identity
## lineage: Lenia as an aquarium — the continuous CA framed as a living exhibit, a
##   glass tank of soft drifting orbium kept like fish.
## essence: An applied display (~1m). A glass tank holds a small Lenia field; soft
##   glowing creatures drift, bounce gently off the walls, and recede. A readout
##   counts the population.
## truth: Life at the edge, made smooth — and put behind glass so you can watch it.
##   An applied ecosystem: the same edge-of-chaos continuum, curated. Each creature a
##   contingent biology drifting in its kernel; the run is the deep, the tank its frame.

@export var cols: int = 22
@export var rows: int = 18
@export var cell_size: float = 0.05
@export var creatures: int = 4
@export var step_interval: float = 0.09
@export var glow_color: Color = Color(0.40, 0.90, 1.0)
@export var core_color: Color = Color(0.85, 1.0, 0.95)
@export var glass_color: Color = Color(0.45, 0.75, 0.85)

var _field: MultiMeshInstance3D
var _blobs: Array = []
var _accum: float = 0.0
var _readout: Label3D


func _make_field(_cols: int, _rows: int, cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(cell * 0.88, cell * 0.88, cell * 0.88)
	mm.mesh = bm
	mm.instance_count = _cols * _rows
	for r in range(_rows):
		for c in range(_cols):
			var i: int = r * _cols + c
			var pos := Vector3(c * cell, r * cell, 0.0) if plane_xy else Vector3(c * cell, 0.0, r * cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, Color(0.05, 0.05, 0.07, 1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cols"):
		cols = int(config["cols"])
	if config.has("rows"):
		rows = int(config["rows"])
	if config.has("creatures"):
		creatures = int(config["creatures"])
	if config.has("step_interval"):
		step_interval = float(config["step_interval"])
	if config.has("glow_color"):
		glow_color = _parse_color(config["glow_color"], glow_color)
	for ch in get_children():
		ch.queue_free()
	_build()


func _seed_blobs() -> void:
	_blobs = []
	var n: int = maxi(creatures, 1)
	for b in range(n):
		var ang: float = _rng.randf() * TAU
		var spd: float = _rng.randf_range(0.12, 0.32)
		_blobs.append({
			"pos": Vector2(_rng.randf_range(3.0, cols - 3.0), _rng.randf_range(3.0, rows - 3.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"r": _rng.randf_range(1.8, 2.8),
			"amp": _rng.randf_range(0.75, 1.0),
		})


func _advect(dt: float) -> void:
	for blob: Dictionary in _blobs:
		var pos: Vector2 = blob["pos"]
		var vel: Vector2 = blob["vel"]
		pos += vel * (dt * 6.0)
		# bounce gently off the tank walls (kept, not toroidal — it's an aquarium)
		var margin: float = 2.0
		if pos.x < margin:
			pos.x = margin; vel.x = absf(vel.x)
		elif pos.x > cols - margin:
			pos.x = cols - margin; vel.x = -absf(vel.x)
		if pos.y < margin:
			pos.y = margin; vel.y = absf(vel.y)
		elif pos.y > rows - margin:
			pos.y = rows - margin; vel.y = -absf(vel.y)
		blob["pos"] = pos
		blob["vel"] = vel


func _sample(cx: float, cy: float) -> float:
	var v: float = 0.0
	for blob: Dictionary in _blobs:
		var bp: Vector2 = blob["pos"]
		var dx: float = cx - bp.x
		var dy: float = cy - bp.y
		var r: float = float(blob["r"])
		var d2: float = dx * dx + dy * dy
		var g: float = exp(-d2 / (2.0 * r * r))
		var ring: float = exp(-pow(sqrt(d2) - r * 0.7, 2.0) / (0.55 * r))
		v += float(blob["amp"]) * (g * 0.5 + ring * 0.8)
	return clampf(v, 0.0, 1.0)


func _paint() -> void:
	var mm: MultiMesh = _field.multimesh
	for y in range(rows):
		for x in range(cols):
			var i: int = y * cols + x
			var val: float = _sample(float(x) + 0.5, float(y) + 0.5)
			var c: Color
			if val < 0.02:
				c = Color(0.03, 0.05, 0.08, 1)
			else:
				c = glow_color.lerp(core_color, clampf((val - 0.3) / 0.7, 0.0, 1.0))
				c = c * (0.25 + val * 0.95)
				c.a = 1.0
			mm.set_instance_color(i, c)


func _build() -> void:
	_seed_blobs()

	# applied: a glass tank (~1m) on a short stand, field suspended inside.
	var span_x: float = cols * cell_size
	var span_y: float = rows * cell_size
	var tank_w: float = span_x + 0.18
	var tank_h: float = span_y + 0.16
	var tank_d: float = 0.30
	var cx: float = 0.0
	var cy: float = 0.85  # field centre height

	# stand
	add_child(_box(Vector3(0.0, 0.06, 0.0), Vector3(tank_w + 0.1, 0.12, tank_d + 0.1), _matte_mat(Color(0.12, 0.13, 0.15))))
	add_child(_box(Vector3(0.0, (cy - tank_h * 0.5 + 0.12) * 0.5, 0.0), Vector3(0.12, cy - tank_h * 0.5 - 0.12, 0.12), _steel_mat(Color(0.4, 0.42, 0.46))))

	# glass tank shell (six thin faces via boxes with glass material)
	var gmat: StandardMaterial3D = _glass_mat(glass_color, 0.18)
	var t: float = 0.012
	# front / back
	add_child(_box(Vector3(cx, cy, tank_d * 0.5), Vector3(tank_w, tank_h, t), gmat))
	add_child(_box(Vector3(cx, cy, -tank_d * 0.5), Vector3(tank_w, tank_h, t), gmat))
	# left / right
	add_child(_box(Vector3(cx - tank_w * 0.5, cy, 0.0), Vector3(t, tank_h, tank_d), gmat))
	add_child(_box(Vector3(cx + tank_w * 0.5, cy, 0.0), Vector3(t, tank_h, tank_d), gmat))
	# top / bottom rims (slightly steel so the tank reads as built)
	var rim: StandardMaterial3D = _steel_mat(Color(0.5, 0.52, 0.55))
	add_child(_box(Vector3(cx, cy + tank_h * 0.5, 0.0), Vector3(tank_w, 0.02, tank_d), rim))
	add_child(_box(Vector3(cx, cy - tank_h * 0.5, 0.0), Vector3(tank_w, 0.02, tank_d), rim))

	_field = _make_field(cols, rows, cell_size, true)
	_field.position = Vector3(-span_x * 0.5, cy - span_y * 0.5, 0.0)
	add_child(_field)
	_paint()  # pre-run: creatures already drifting

	add_child(_billboard_label("LENIA TANK", Vector3(0.0, cy + tank_h * 0.5 + 0.18, 0.0), 22, glow_color))
	_readout = _billboard_label("creatures: %d" % _blobs.size(), Vector3(0.0, cy - tank_h * 0.5 - 0.10, tank_d * 0.5 + 0.02), 14, core_color)
	add_child(_readout)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_interval:
		return
	var dt: float = _accum
	_accum = 0.0
	_advect(dt)
	_paint()
	if _readout:
		_readout.text = "creatures: %d" % _blobs.size()
