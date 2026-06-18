extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BriansBrainBench

## @identity
## lineage: Brian Silverman's Brain → multi-state cellular automata, refractory dynamics
## essence: a three-state field on a bench — ON, DYING, OFF — that never settles, always shimmering
## truth: the dying state is memory the rule cannot erase; the run is the deep, the edge perpetually alive

@export var cols: int = 28
@export var rows: int = 28
@export var cell: float = 0.022
@export var step_time: float = 0.12
@export var off_color: Color = Color(0.05, 0.05, 0.07, 1.0)
@export var on_color: Color = Color(0.5, 0.95, 1.0, 1.0)
@export var dying_color: Color = Color(0.7, 0.25, 0.45, 1.0)

# states: 0 = OFF, 1 = ON, 2 = DYING
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
			mm.set_instance_color(i, off_color)
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


func _seed() -> void:
	_grid = _blank()
	for _i in range(70):
		var x := _rng.randi_range(0, cols - 1)
		var y := _rng.randi_range(0, rows - 1)
		_grid[y][x] = 1


func _on_neighbors(c: int, r: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := (c + dx + cols) % cols
			var y := (r + dy + rows) % rows
			if _grid[y][x] == 1:
				n += 1
	return n


func _step() -> void:
	for r in range(rows):
		for c in range(cols):
			var s: int = _grid[r][c]
			if s == 1:
				_next[r][c] = 2  # ON -> DYING
			elif s == 2:
				_next[r][c] = 0  # DYING -> OFF
			else:
				_next[r][c] = 1 if _on_neighbors(c, r) == 2 else 0  # OFF -> ON iff exactly 2 ON neighbours
	var tmp := _grid
	_grid = _next
	_next = tmp


func _paint() -> void:
	var mm := _field.multimesh
	for r in range(rows):
		for c in range(cols):
			var i := r * cols + c
			var s: int = _grid[r][c]
			var col := off_color
			if s == 1:
				col = on_color
			elif s == 2:
				col = dying_color
			mm.set_instance_color(i, col)


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

	add_child(_billboard_label("BRIAN'S BRAIN\non, fading, off", Vector3(0, 1.6, 0.05), 28, on_color))

	_seed()
	_next = _blank()
	for _i in range(6):
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
