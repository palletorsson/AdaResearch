extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CaTextureToy

## @identity
## lineage: cellular automata as material generator / reaction-diffusion / maze rules
## essence: a small CA run to a stable patterned tile, frozen as a held material swatch.
## truth: a rule run to equilibrium is a texture. The pattern is not painted — it is
##        what the rule settles into and then stops being a process. A frozen swatch
##        is an algorithm that finished and forgot it ever moved.

@export var cols: int = 26
@export var rows: int = 26
@export var cell: float = 0.014
@export var step_seconds: float = 0.16
@export var freeze_after: int = 40       # steps until "frozen" badge
@export var warmup_steps: int = 60

# A two-state maze-like CA (B3/S12345) settles into stable corridors quickly.
var _grid: Array = []          # Array[Array[int]] 0/1
var _next: Array = []
var _mi: MultiMeshInstance3D
var _accum: float = 0.0
var _steps: int = 0
var _frozen: bool = false
var _label: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("freeze_after"):
		freeze_after = int(config["freeze_after"])
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_init_state()
	# held swatch backing plate
	var plate := _matte_mat(Color(0.10, 0.10, 0.13), 0.85, 0.0)
	add_child(_box(Vector3(cols * cell * 0.5, rows * cell * 0.5, -cell * 0.8), Vector3(cols * cell + 0.02, rows * cell + 0.02, cell * 0.4), plate))
	# field (vertical swatch facing +Z)
	_mi = _make_field(cols, rows, cell, true)
	_mi.position = Vector3(0.0, 0.0, 0.0)
	add_child(_mi)
	_label = _billboard_label("CA TEXTURE", Vector3(cols * cell * 0.5, rows * cell + 0.06, 0.0), 20, Color(0.85, 0.95, 1.0))
	add_child(_label)
	# PRE-RUN so a settled pattern shows immediately
	for i in range(warmup_steps):
		_step()
	_paint()


func _init_state() -> void:
	_grid = []
	_next = []
	for r in range(rows):
		var row: Array = []
		var nrow: Array = []
		for c in range(cols):
			row.append(1 if _rng.randf() < 0.5 else 0)
			nrow.append(0)
		_grid.append(row)
		_next.append(nrow)
	_steps = 0
	_frozen = false


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _frozen:
		return
	_accum += delta
	if _accum < step_seconds:
		return
	_accum = 0.0
	_step()
	_paint()


func _step() -> void:
	# Maze rule: born on 3 neighbours, survive on 1..5 — settles into corridors
	for r in range(rows):
		var nrow: Array = _next[r]
		for c in range(cols):
			var n: int = _neighbours(c, r)
			var alive: int = int(_grid[r][c])
			if alive == 1:
				nrow[c] = 1 if (n >= 1 and n <= 5) else 0
			else:
				nrow[c] = 1 if n == 3 else 0
	var tmp: Array = _grid
	_grid = _next
	_next = tmp
	_steps += 1
	if _steps >= freeze_after:
		_frozen = true
		if _label:
			_label.text = "CA TEXTURE — FROZEN"


func _neighbours(cx: int, cy: int) -> int:
	var n: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x: int = cx + dx
			var y: int = cy + dy
			if x < 0 or x >= cols or y < 0 or y >= rows:
				continue
			n += int(_grid[y][x])
	return n


func _paint() -> void:
	var mm := _mi.multimesh
	for r in range(rows):
		var row: Array = _grid[r]
		for c in range(cols):
			var i: int = r * cols + c
			var col := Color(0.18, 0.55, 0.65) if int(row[c]) == 1 else Color(0.05, 0.05, 0.08)
			if _frozen and int(row[c]) == 1:
				col = Color(0.85, 0.70, 0.30)  # frozen swatch warms to gold
			mm.set_instance_color(i, col)


func _make_field(cols_n: int, rows_n: int, cell_s: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(cell_s * 0.88, cell_s * 0.88, cell_s * 0.88)
	mm.mesh = bm
	mm.instance_count = cols_n * rows_n
	for r in range(rows_n):
		for c in range(cols_n):
			var i: int = r * cols_n + c
			var pos := Vector3(c * cell_s, r * cell_s, 0.0) if plane_xy else Vector3(c * cell_s, 0.0, r * cell_s)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, Color(0.05, 0.05, 0.07, 1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi
