extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WireworldToy

## @identity
## lineage: Brian Silverman's Wireworld → CA as logic substrate, electrons on wire
## essence: a small held wire loop — empty / wire / electron-head / electron-tail — electrons chasing around
## truth: a physics built from four states can compute; the run is the deep, each electron alive at the wire's edge

@export var cols: int = 16
@export var rows: int = 16
@export var cell: float = 0.024
@export var step_time: float = 0.16
@export var empty_color: Color = Color(0.04, 0.04, 0.05, 1.0)
@export var wire_color: Color = Color(0.55, 0.42, 0.12, 1.0)
@export var head_color: Color = Color(0.5, 0.85, 1.0, 1.0)
@export var tail_color: Color = Color(1.0, 0.35, 0.3, 1.0)

# states: 0 = empty, 1 = wire, 2 = head, 3 = tail
var _grid: Array = []
var _next: Array = []
var _field: MultiMeshInstance3D
var _accum: float = 0.0


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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
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


func _seed() -> void:
	_grid = _blank()
	# rectangular wire loop just inside the borders
	var x0 := 2
	var x1 := cols - 3
	var y0 := 2
	var y1 := rows - 3
	for x in range(x0, x1 + 1):
		_set_cell(x, y0, 1)
		_set_cell(x, y1, 1)
	for y in range(y0, y1 + 1):
		_set_cell(x0, y, 1)
		_set_cell(x1, y, 1)
	# inject two electrons (head + tail behind it) on the top edge so they circulate
	_set_cell(x0 + 3, y0, 2)
	_set_cell(x0 + 2, y0, 3)
	_set_cell(x1 - 2, y1, 2)
	_set_cell(x1 - 1, y1, 3)


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


func _step() -> void:
	for r in range(rows):
		for c in range(cols):
			var s: int = _grid[r][c]
			match s:
				0:
					_next[r][c] = 0
				2:
					_next[r][c] = 3  # head -> tail
				3:
					_next[r][c] = 1  # tail -> wire
				_:
					var hn := _head_neighbors(c, r)
					_next[r][c] = 2 if (hn == 1 or hn == 2) else 1  # wire -> head iff 1 or 2 head neighbours
	var tmp := _grid
	_grid = _next
	_next = tmp


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
	# small held field near origin, no table — centre it about origin, lifted to hand height
	_field = _make_field(cols, rows, cell, true)
	var w := cols * cell
	var h := rows * cell
	_field.position = Vector3(-w * 0.5, 1.1 - h * 0.5, 0.0)
	add_child(_field)

	add_child(_billboard_label("WIREWORLD", Vector3(0, 1.1 + h * 0.5 + 0.12, 0.0), 18, head_color))

	_seed()
	_next = _blank()
	for _i in range(2):
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
