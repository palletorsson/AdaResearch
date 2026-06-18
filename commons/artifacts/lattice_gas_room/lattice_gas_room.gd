extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LatticeGasRoom

## @identity
## lineage: HPP 1973 -> FHP lattice gas -> lattice-Boltzmann CFD.
## essence: a room-sized fluid living on the floor. Particles stream and collide cell to cell;
##   the eye reads a current that parts around a pillar and closes behind it. No fluid was
##   stored anywhere — only booleans, only the rule.
## truth: physics is a cellular automaton you can walk inside. The RULE is local and cheap;
##   the RUN is the whole of fluid mechanics. The flow around the obstacle is the alive
##   middle — neither frozen nor turbulent-to-noise, the contingent settling of momentum.

@export var cols: int = 40
@export var rows: int = 40
@export var cell: float = 0.16
@export var color_low: Color = Color(0.03, 0.04, 0.10, 1.0)
@export var color_high: Color = Color(0.25, 0.65, 1.0, 1.0)
@export var color_hot: Color = Color(1.0, 0.80, 0.30, 1.0)

const DX: Array = [1, -1, 0, 0]
const DY: Array = [0, 0, 1, -1]
const OPP: Array = [1, 0, 3, 2]

var _field: MultiMeshInstance3D
var _state: PackedByteArray
var _solid: PackedByteArray
var _accum: float = 0.0


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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# room floor
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(Color(0.08, 0.09, 0.11))))

	add_child(_billboard_label("LATTICE GAS FLOW", Vector3(0.0, 3.6, 0.0), 44, color_high))

	var n: int = cols * rows
	_state = PackedByteArray()
	_state.resize(n)
	_solid = PackedByteArray()
	_solid.resize(n)
	_seed_gas()

	# field laid on the floor (plane_xz)
	_field = _make_field(cols, rows, cell, false)
	var span_x: float = float(cols - 1) * cell
	var span_z: float = float(rows - 1) * cell
	_field.position = Vector3(-span_x * 0.5, 0.06, -span_z * 0.5)
	add_child(_field)

	# a visible pillar marking the obstacle the flow parts around
	var ox: int = cols / 3
	var oy: int = rows / 2
	var px: float = float(ox) * cell - span_x * 0.5
	var pz: float = float(oy) * cell - span_z * 0.5
	add_child(_cylinder(Vector3(px, 0.55, pz), float(rows) * 0.13 * cell * 0.7, 1.0, _steel_mat(Color(0.4, 0.42, 0.48))))

	for _i: int in range(60):
		_step()
	_paint()


func _seed_gas() -> void:
	var n: int = cols * rows
	for i: int in range(n):
		_solid[i] = 0
		_state[i] = 0
	for x: int in range(cols):
		_solid[x] = 1
		_solid[(rows - 1) * cols + x] = 1
	var ox: int = cols / 3
	var oy: int = rows / 2
	var orad: float = float(rows) * 0.13
	for y: int in range(rows):
		for x: int in range(cols):
			var dx: float = float(x - ox)
			var dy: float = float(y - oy)
			if dx * dx + dy * dy <= orad * orad:
				_solid[y * cols + x] = 1
	for y: int in range(rows):
		for x: int in range(cols):
			var i: int = y * cols + x
			if _solid[i] == 1:
				continue
			var b: int = 0
			if _rng.randf() < 0.70:
				b |= 1
			if _rng.randf() < 0.08:
				b |= 2
			if _rng.randf() < 0.16:
				b |= 4
			if _rng.randf() < 0.16:
				b |= 8
			_state[i] = b


func _inject_left() -> void:
	for y: int in range(1, rows - 1):
		var i: int = y * cols + 1
		if _solid[i] == 1:
			continue
		_state[i] = _state[i] | 1


func _collide() -> void:
	var n: int = cols * rows
	for i: int in range(n):
		if _solid[i] == 1:
			continue
		var s: int = _state[i]
		var has_xpair: bool = (s & 1) != 0 and (s & 2) != 0
		var has_ypair: bool = (s & 4) != 0 and (s & 8) != 0
		if has_xpair and not has_ypair:
			s = (s & ~3) | 12
		elif has_ypair and not has_xpair:
			s = (s & ~12) | 3
		_state[i] = s


func _bounce_and_stream() -> void:
	var n: int = cols * rows
	var nxt := PackedByteArray()
	nxt.resize(n)
	for i: int in range(n):
		nxt[i] = 0
	for y: int in range(rows):
		for x: int in range(cols):
			var i: int = y * cols + x
			if _solid[i] == 1:
				continue
			var s: int = _state[i]
			for d: int in range(4):
				if (s & (1 << d)) == 0:
					continue
				var nx: int = x + int(DX[d])
				var ny: int = y + int(DY[d])
				if nx < 0:
					nx = cols - 1
				elif nx >= cols:
					nx = 0
				if ny < 0 or ny >= rows:
					nxt[i] = nxt[i] | (1 << int(OPP[d]))
					continue
				var ni: int = ny * cols + nx
				if _solid[ni] == 1:
					nxt[i] = nxt[i] | (1 << int(OPP[d]))
				else:
					nxt[ni] = nxt[ni] | (1 << d)
	_state = nxt


func _step() -> void:
	_inject_left()
	_collide()
	_bounce_and_stream()


func _paint() -> void:
	if _field == null:
		return
	var mm: MultiMesh = _field.multimesh
	var n: int = cols * rows
	for i: int in range(n):
		if _solid[i] == 1:
			mm.set_instance_color(i, Color(0.40, 0.42, 0.48, 1.0))
			continue
		var s: int = _state[i]
		var dens: int = (s & 1) + ((s >> 1) & 1) + ((s >> 2) & 1) + ((s >> 3) & 1)
		var t: float = float(dens) / 4.0
		var net_x: float = float(s & 1) - float((s >> 1) & 1)
		var base: Color = color_low.lerp(color_high, t)
		if net_x > 0.5 and dens >= 1:
			base = base.lerp(color_hot, 0.30 * t)
		mm.set_instance_color(i, base)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < 0.12:
		return
	_accum = 0.0
	for _k: int in range(2):
		_step()
	_paint()
