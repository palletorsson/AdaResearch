extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LeniaRoom

## @identity
## lineage: Lenia (Bert Chan, 2018) — a continuous cellular automaton where cells
##   hold real values 0..1 and update by smooth kernels, growing soft gliding
##   creatures ("orbium") instead of pixel blocks.
## essence: A room-scale field laid on the FLOOR, ~40x40, with glowing orbium
##   drifting across it. The field is read as a brightness gradient; the creatures
##   are summed soft gaussians advecting over the plane.
## truth: Life at the edge, made smooth. Conway's binary edge of chaos, dissolved
##   into a continuum — the same liminal aliveness with no hard line between living
##   and dead. The run is the deep; the edge is alive, literally. Each kernel a
##   contingent biology, and the neighbourhood here is a soft halo, a politics of degree.

@export var cols: int = 40
@export var rows: int = 40
@export var cell_size: float = 0.16
@export var creatures: int = 6
@export var step_interval: float = 0.10
@export var glow_color: Color = Color(0.35, 0.95, 0.85)
@export var core_color: Color = Color(0.95, 1.0, 0.85)

var _field: MultiMeshInstance3D
var _blobs: Array = []          # each: {pos:Vector2(cell space), vel:Vector2, r:float, amp:float, spin:float}
var _accum: float = 0.0
var _t: float = 0.0


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
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.18 if emissive else 0.0
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
		var spd: float = _rng.randf_range(0.20, 0.55)
		_blobs.append({
			"pos": Vector2(_rng.randf_range(4.0, cols - 4.0), _rng.randf_range(4.0, rows - 4.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"r": _rng.randf_range(2.6, 4.2),
			"amp": _rng.randf_range(0.75, 1.0),
			"spin": _rng.randf_range(-0.6, 0.6),
		})


func _advect(dt: float) -> void:
	_t += dt
	for blob: Dictionary in _blobs:
		var vel: Vector2 = blob["vel"]
		# gentle curving so they glide like orbium, not straight lines
		var sp: float = float(blob["spin"])
		vel = vel.rotated(sp * dt)
		var pos: Vector2 = blob["pos"] + vel * (dt * 6.0)
		# wrap toroidally so creatures glide off one edge and back on the other
		pos.x = wrapf(pos.x, 0.0, float(cols))
		pos.y = wrapf(pos.y, 0.0, float(rows))
		blob["pos"] = pos
		blob["vel"] = vel


func _sample(cx: float, cy: float) -> float:
	# summed soft gaussians, toroidal distance
	var v: float = 0.0
	for blob: Dictionary in _blobs:
		var bp: Vector2 = blob["pos"]
		var dx: float = absf(cx - bp.x); dx = minf(dx, float(cols) - dx)
		var dy: float = absf(cy - bp.y); dy = minf(dy, float(rows) - dy)
		var r: float = float(blob["r"])
		var d2: float = dx * dx + dy * dy
		# orbium-ish: bright ring around a slightly dim core (Mexican-hat read)
		var g: float = exp(-d2 / (2.0 * r * r))
		var ring: float = exp(-pow(sqrt(d2) - r * 0.7, 2.0) / (0.6 * r))
		v += float(blob["amp"]) * (g * 0.55 + ring * 0.75)
	return clampf(v, 0.0, 1.0)


func _paint() -> void:
	var mm: MultiMesh = _field.multimesh
	for y in range(rows):
		for x in range(cols):
			var i: int = y * cols + x
			var val: float = _sample(float(x) + 0.5, float(y) + 0.5)
			var c: Color
			if val < 0.02:
				c = Color(0.04, 0.05, 0.07, 1)
			else:
				c = glow_color.lerp(core_color, clampf((val - 0.3) / 0.7, 0.0, 1.0))
				c = c * (0.25 + val * 0.95)
				c.a = 1.0
			mm.set_instance_color(i, c)


func _build() -> void:
	_seed_blobs()

	# room: floor slab + the field laid flat on it.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(Color(0.10, 0.11, 0.13))))

	_field = _make_field(cols, rows, cell_size, false)
	var span_x: float = cols * cell_size
	var span_z: float = rows * cell_size
	_field.position = Vector3(-span_x * 0.5, 0.02, -span_z * 0.5)
	add_child(_field)
	_paint()  # pre-run: blobs already placed, so first frame shows gliding life

	add_child(_billboard_label("LENIA\nlife at the edge, made smooth", Vector3(0.0, 3.6, 0.0), 30, glow_color))


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
