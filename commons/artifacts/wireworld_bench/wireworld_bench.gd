extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WireworldBench

## @identity
## lineage: Wireworld → logic gates from cellular automata, the diode and the XOR junction
## essence: a wireworld logic element on a bench — electron heads and tails streaming through a gate
## truth: a physics made of electronics, computed cell by cell; the run is the deep, each pulse alive at the edge

@export var cols: int = 32
@export var rows: int = 24
@export var cell: float = 0.022
@export var step_time: float = 0.14
@export var empty_color: Color = Color(0.04, 0.04, 0.05, 1.0)
@export var wire_color: Color = Color(0.55, 0.42, 0.12, 1.0)
@export var head_color: Color = Color(0.5, 0.85, 1.0, 1.0)
@export var tail_color: Color = Color(1.0, 0.35, 0.3, 1.0)

# states: 0 = empty, 1 = wire, 2 = head, 3 = tail
var _grid: Array = []
var _next: Array = []
var _field: MultiMeshInstance3D
var _accum: float = 0.0
var _gen: int = 0
# diode injector cells: list of {pos:Vector2i, period:int, phase:int}
var _injectors: Array = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("step_time"):
		step_time = float(config["step_time"])
	for c in get_children():
		c.queue_free()
	_build()


func _make_field(field_cols: int, field_rows: int, field_cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(field_cell * 0.88, field_cell * 0.88, field_cell * 0.88)
	mm.mesh = bm
	mm.instance_count = field_cols * field_rows
	for r in range(field_rows):
		for c in range(field_cols):
			var i := r * field_cols + c
			var pos := Vector3(c * field_cell, r * field_cell, 0.0) if plane_xy else Vector3(c * field_cell, 0.0, r * field_cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, empty_color)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi


func _blank() -> Array:
	var g: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(0)
		g.append(row)
	return g


func _set_cell(x: int, y: int, v: int) -> void:
	if x >= 0 and x < cols and y >= 0 and y < rows:
		_grid[y][x] = v


func _hline(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		_set_cell(x, y, 1)


func _vline(y0: int, y1: int, x: int) -> void:
	for y in range(y0, y1 + 1):
		_set_cell(x, y, 1)


func _seed() -> void:
	# An XOR-style junction: two input wires (top + bottom) merge into one output.
	# Electrons clocked onto each input at different periods so the gate visibly fires.
	_grid = _blank()
	_injectors.clear()

	var midy := rows / 2
	var inya := midy - 5
	var inyb := midy + 5
	var junc_x := cols - 12
	var out_x := cols - 4

	# input A rail (upper)
	_hline(3, junc_x, inya)
	# input B rail (lower)
	_hline(3, junc_x, inyb)
	# diagonal/step feeds from each rail into the junction column
	_vline(inya, midy, junc_x)
	_vline(midy, inyb, junc_x)
	# output rail from junction
	_hline(junc_x, out_x, midy)
	# small output loop so the pulse has somewhere to go and re-trigger
	_vline(midy, midy + 3, out_x)
	_hline(out_x - 2, out_x, midy + 3)
	_vline(midy, midy + 3, out_x - 2)

	# injectors: clock heads onto the two input rail starts
	_injectors.append({"pos": Vector2i(4, inya), "period": 9, "phase": 0})
	_injectors.append({"pos": Vector2i(4, inyb), "period": 13, "phase": 4})


func _head_neighbors(c: int, r: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := c + dx
			var y := r + dy
			if x >= 0 and x < cols and y >= 0 and y < rows:
				if _grid[y][x] == 2:
					n += 1
	return n


func _inject() -> void:
	# fire a head onto wire injector cells on their period (only if the cell is currently wire)
	for inj in _injectors:
		var p: Vector2i = inj["pos"]
		if ((_gen + int(inj["phase"])) % int(inj["period"])) == 0:
			if _grid[p.y][p.x] == 1:
				_grid[p.y][p.x] = 2


func _step() -> void:
	for r in range(rows):
		for c in range(cols):
			var s: int = _grid[r][c]
			match s:
				0:
					_next[r][c] = 0
				2:
					_next[r][c] = 3
				3:
					_next[r][c] = 1
				_:
					var hn := _head_neighbors(c, r)
					_next[r][c] = 2 if (hn == 1 or hn == 2) else 1
	var tmp := _grid
	_grid = _next
	_next = tmp
	_gen += 1
	_inject()


func _color_for(s: int) -> Color:
	match s:
		1:
			return wire_color
		2:
			return head_color
		3:
			return tail_color
		_:
			return empty_color


func _paint() -> void:
	var mm := _field.multimesh
	for r in range(rows):
		for c in range(cols):
			var i := r * cols + c
			mm.set_instance_color(i, _color_for(_grid[r][c]))


func _build() -> void:
	var base_mat := _matte_mat(Color(0.15, 0.16, 0.2), 0.85)
	var steel := _steel_mat(Color(0.45, 0.47, 0.52))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	add_child(_box(Vector3(0, 0.5, -0.12), Vector3(0.12, 0.62, 0.12), steel))
	add_child(_box(Vector3(0, 0.86, 0), Vector3(1.0, 0.04, 0.6), _steel_mat(Color(0.28, 0.3, 0.34))))

	_field = _make_field(cols, rows, cell, true)
	var w := cols * cell
	_field.position = Vector3(-w * 0.5, 0.9, 0.04)
	add_child(_field)

	add_child(_billboard_label("WIREWORLD\na physics made of electronics", Vector3(0, 1.6, 0.05), 26, head_color))

	_seed()
	_next = _blank()
	for _i in range(18):
		_step()
	_paint()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	while _accum >= step_time:
		_accum -= step_time
		_step()
	_paint()
