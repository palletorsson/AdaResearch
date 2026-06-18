extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LifeBench

## @identity
## lineage: Conway 1970 → cellular automata → emergence on a square grid
## essence: a Life field on a bench, a glider gun firing gliders across the cells
## truth: B3/S23 is one rule among infinitely many — the run is the deep, each rule a contingent universe

@export var cols: int = 28
@export var rows: int = 28
@export var cell: float = 0.022
@export var step_time: float = 0.12
@export var alive_color: Color = Color(0.3, 1.0, 0.55, 1.0)
@export var dead_color: Color = Color(0.05, 0.05, 0.07, 1.0)

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
	if config.has("cols"):
		cols = int(config["cols"])
	if config.has("rows"):
		rows = int(config["rows"])
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
			mm.set_instance_color(i, dead_color)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi


func _blank_grid() -> Array:
	var g: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(0)
		g.append(row)
	return g


func _seed_glider_gun() -> void:
	_grid = _blank_grid()
	# Gosper glider gun (offsets from a base origin), wrapped into the field
	var pts := [
		Vector2i(0, 4), Vector2i(0, 5), Vector2i(1, 4), Vector2i(1, 5),
		Vector2i(10, 4), Vector2i(10, 5), Vector2i(10, 6),
		Vector2i(11, 3), Vector2i(11, 7),
		Vector2i(12, 2), Vector2i(12, 8), Vector2i(13, 2), Vector2i(13, 8),
		Vector2i(14, 5),
		Vector2i(15, 3), Vector2i(15, 7),
		Vector2i(16, 4), Vector2i(16, 5), Vector2i(16, 6),
		Vector2i(17, 5),
		Vector2i(20, 2), Vector2i(20, 3), Vector2i(20, 4),
		Vector2i(21, 2), Vector2i(21, 3), Vector2i(21, 4),
		Vector2i(22, 1), Vector2i(22, 5),
		Vector2i(24, 0), Vector2i(24, 1), Vector2i(24, 5), Vector2i(24, 6),
	]
	var ox := 1
	var oy := 9
	for p: Vector2i in pts:
		var x: int = (p.x + ox) % cols
		var y: int = (p.y + oy) % rows
		_grid[y][x] = 1


func _neighbors(g: Array, c: int, r: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := (c + dx + cols) % cols
			var y := (r + dy + rows) % rows
			n += int(g[y][x])
	return n


func _step() -> void:
	for r in range(rows):
		for c in range(cols):
			var n := _neighbors(_grid, c, r)
			var alive: bool = _grid[r][c] == 1
			if alive:
				_next[r][c] = 1 if (n == 2 or n == 3) else 0
			else:
				_next[r][c] = 1 if n == 3 else 0
	var tmp := _grid
	_grid = _next
	_next = tmp


func _paint() -> void:
	var mm := _field.multimesh
	for r in range(rows):
		for c in range(cols):
			var i := r * cols + c
			mm.set_instance_color(i, alive_color if _grid[r][c] == 1 else dead_color)


func _build() -> void:
	# --- bench housing ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.85)
	var steel := _steel_mat(Color(0.45, 0.47, 0.52))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	add_child(_box(Vector3(0, 0.5, -0.12), Vector3(0.12, 0.62, 0.12), steel))
	add_child(_box(Vector3(0, 0.86, 0), Vector3(1.0, 0.04, 0.6), _steel_mat(Color(0.3, 0.32, 0.36))))

	# --- field standing vertical on the bench top, facing +Z ---
	_field = _make_field(cols, rows, cell, true)
	var w := cols * cell
	var h := rows * cell
	_field.position = Vector3(-w * 0.5, 0.9, 0.04)
	add_child(_field)

	add_child(_billboard_label("GAME OF LIFE\nborn on 3, live on 2 or 3", Vector3(0, 1.6, 0.05), 28, alive_color))

	# --- pre-run so the first frame shows live gliders ---
	_seed_glider_gun()
	_next = _blank_grid()
	for _i in range(40):
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
