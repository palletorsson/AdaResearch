extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CaTextureBench

## @identity
## lineage: cellular automata as material generator / reaction-diffusion / textile rules
## essence: a CA running toward equilibrium, settling into a repeating textile/tile
##          pattern, with a live "settling -> frozen" readout.
## truth: a rule run to equilibrium is a texture. We watch the algorithm cool: motion
##        becomes pattern, pattern becomes cloth. The textile is the fixed point of a
##        process that no longer remembers it was ever in motion.

@export var cols: int = 36
@export var rows: int = 36
@export var cell: float = 0.017
@export var step_seconds: float = 0.12
@export var freeze_threshold: int = 4    # settle when changed-cells <= this for a while
@export var warmup_steps: int = 70

var _grid: Array = []
var _next: Array = []
var _mi: MultiMeshInstance3D
var _accum: float = 0.0
var _changed: int = 9999
var _stable_run: int = 0
var _frozen: bool = false
var _label: Label3D
var _readout: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("freeze_threshold"):
		freeze_threshold = int(config["freeze_threshold"])
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_init_state()
	var fw: float = cols * cell
	var fd: float = rows * cell
	# bench base
	var base_mat := _matte_mat(Color(0.12, 0.12, 0.15), 0.85, 0.0)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), base_mat))
	# pillar
	add_child(_cylinder(Vector3(0.0, 0.52, 0.0), 0.05, 0.65, _steel_mat(Color(0.35, 0.37, 0.42))))
	# field VERTICAL on top facing +Z
	_mi = _make_field(cols, rows, cell, true)
	_mi.position = Vector3(-fw * 0.5, 0.85, 0.0)
	add_child(_mi)
	# label + live readout
	_label = _billboard_label("CA TEXTURE\na rule run to equilibrium is a texture", Vector3(0.0, 1.6, 0.0), 28, Color(0.85, 0.95, 1.0))
	add_child(_label)
	_readout = _billboard_label("settling...", Vector3(0.0, 1.38, 0.0), 22, Color(0.6, 0.9, 0.7))
	add_child(_readout)
	# PRE-RUN toward equilibrium
	for i in range(warmup_steps):
		_step()
	_paint()
	_update_readout()


func _init_state() -> void:
	_grid = []
	_next = []
	for r in range(rows):
		var row: Array = []
		var nrow: Array = []
		for c in range(cols):
			row.append(1 if _rng.randf() < 0.48 else 0)
			nrow.append(0)
		_grid.append(row)
		_next.append(nrow)
	_changed = 9999
	_stable_run = 0
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
	_update_readout()


func _step() -> void:
	# "textile" rule (B35678/S5678 — diamoeba-like) settles into woven blocks
	var diff: int = 0
	for r in range(rows):
		var nrow: Array = _next[r]
		for c in range(cols):
			var n: int = _neighbours(c, r)
			var alive: int = int(_grid[r][c])
			var nv: int
			if alive == 1:
				nv = 1 if (n == 5 or n == 6 or n == 7 or n == 8) else 0
			else:
				nv = 1 if (n == 3 or n == 5 or n == 6 or n == 7 or n == 8) else 0
			nrow[c] = nv
			if nv != alive:
				diff += 1
	var tmp: Array = _grid
	_grid = _next
	_next = tmp
	_changed = diff
	if _changed <= freeze_threshold:
		_stable_run += 1
	else:
		_stable_run = 0
	if _stable_run >= 5:
		_frozen = true


func _neighbours(cx: int, cy: int) -> int:
	var n: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			# toroidal wrap → seamless repeating textile
			var x: int = (cx + dx + cols) % cols
			var y: int = (cy + dy + rows) % rows
			n += int(_grid[y][x])
	return n


func _update_readout() -> void:
	if _readout == null:
		return
	if _frozen:
		_readout.text = "FROZEN — texture set"
		_readout.modulate = Color(0.95, 0.8, 0.35)
	else:
		_readout.text = "settling… Δ%d" % _changed
		_readout.modulate = Color(0.6, 0.9, 0.7)


func _paint() -> void:
	var mm := _mi.multimesh
	for r in range(rows):
		var row: Array = _grid[r]
		for c in range(cols):
			var i: int = r * cols + c
			var on: bool = int(row[c]) == 1
			var col: Color
			if _frozen:
				col = Color(0.80, 0.45, 0.55) if on else Color(0.10, 0.06, 0.12)
			else:
				col = Color(0.20, 0.55, 0.70) if on else Color(0.05, 0.05, 0.08)
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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi
