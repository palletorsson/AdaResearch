extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name HexCaToy

## @identity
## lineage: Hexagonal cellular automaton — a CA whose lattice is not the square
##   grid everyone defaults to, but the close-packed hex of beehives and basalt.
## essence: A small (~0.4m) field where every other row is offset half a cell, so
##   it reads as hex packing. Each cell has six neighbours; a life-like rule runs.
## truth: The neighbourhood is a politics. Square or hex is a choice, not a given —
##   change who counts as a neighbour and the whole physics changes. Six-fold company
##   grows rounder, gentler shapes than four. Each lattice a contingent universe.

@export var cols: int = 24
@export var rows: int = 24
@export var cell_size: float = 0.016
@export var step_interval: float = 0.12
@export var birth_lo: int = 2
@export var birth_hi: int = 3
@export var survive_lo: int = 3
@export var survive_hi: int = 4
@export var on_color: Color = Color(0.45, 0.95, 0.70)

var _field: MultiMeshInstance3D
var _state: Array = []
var _next: Array = []
var _accum: float = 0.0


func _make_field(_cols: int, _rows: int, cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	# hex variant: offset odd rows by half a cell in x.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(cell * 0.80, cell * 0.80, cell * 0.80)
	mm.mesh = bm
	mm.instance_count = _cols * _rows
	for r in range(_rows):
		for c in range(_cols):
			var i: int = r * _cols + c
			var off: float = (cell * 0.5) if (r % 2 == 1) else 0.0
			var ry: float = cell * 0.87  # row spacing tighter for hex feel
			var pos := Vector3(c * cell + off, r * ry, 0.0) if plane_xy else Vector3(c * cell + off, 0.0, r * ry)
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
	if config.has("step_interval"):
		step_interval = float(config["step_interval"])
	if config.has("on_color"):
		on_color = _parse_color(config["on_color"], on_color)
	for ch in get_children():
		ch.queue_free()
	_build()


func _hex_neighbours(x: int, y: int) -> int:
	# six neighbours on an offset (axial) lattice.
	var n: int = 0
	var deltas: Array
	if y % 2 == 0:
		deltas = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(0, 1)]
	else:
		deltas = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(0, 1), Vector2i(1, 1)]
	for d: Vector2i in deltas:
		var nx: int = wrapi(x + d.x, 0, cols)
		var ny: int = wrapi(y + d.y, 0, rows)
		if _state[ny][nx]:
			n += 1
	return n


func _seed() -> void:
	_state = []
	_next = []
	for y in range(rows):
		var row: Array = []
		var nrow: Array = []
		for x in range(cols):
			row.append(_rng.randf() < 0.34)
			nrow.append(false)
		_state.append(row)
		_next.append(nrow)


func _step() -> void:
	for y in range(rows):
		for x in range(cols):
			var n: int = _hex_neighbours(x, y)
			if _state[y][x]:
				_next[y][x] = (n >= survive_lo and n <= survive_hi)
			else:
				_next[y][x] = (n >= birth_lo and n <= birth_hi)
	var tmp: Array = _state
	_state = _next
	_next = tmp


func _paint() -> void:
	var mm: MultiMesh = _field.multimesh
	for y in range(rows):
		for x in range(cols):
			var i: int = y * cols + x
			if _state[y][x]:
				var n: int = _hex_neighbours(x, y)
				var t: float = clampf(float(n) / 6.0, 0.2, 1.0)
				mm.set_instance_color(i, on_color.lerp(Color(1, 1, 1), t * 0.4) * Color(t, t, t, 1.0) + on_color * (1.0 - t) * 0.3)
			else:
				mm.set_instance_color(i, Color(0.06, 0.06, 0.09, 1))


func _build() -> void:
	_seed()
	for _s in range(6):  # pre-run so a settled pattern shows on frame 1
		_step()

	_field = _make_field(cols, rows, cell_size, true)
	var span_x: float = cols * cell_size
	var span_y: float = rows * cell_size * 0.87
	_field.position = Vector3(-span_x * 0.5, -span_y * 0.5 + 0.05, 0.0)
	add_child(_field)
	_paint()

	add_child(_billboard_label("HEX CA", Vector3(0.0, span_y * 0.5 + 0.16, 0.0), 22, on_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_interval:
		return
	_accum = 0.0
	_step()
	_paint()
