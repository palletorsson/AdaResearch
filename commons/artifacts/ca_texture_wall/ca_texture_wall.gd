extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CaTextureWall

## @identity
## lineage: cellular automata as material generator / symmetric textile / Persian rug
## essence: a wall-scale CA-grown tapestry — a CA run in one quadrant and mirrored
##          four ways, settling into a Persian-rug-like symmetric pattern, 3-5m tall.
## truth: the rug is an algorithm that forgot it was running. Every knot is a cell
##        that reached its fixed point; the symmetry is the rule's signature; the
##        border is where the process met the loom and stopped. Texture is dead motion.

@export var cols: int = 40
@export var rows: int = 40
@export var cell: float = 0.12
@export var step_seconds: float = 0.14
@export var freeze_after: int = 36
@export var warmup_steps: int = 60
@export var palette_a: Color = Color(0.65, 0.12, 0.12)   # rug red
@export var palette_b: Color = Color(0.10, 0.18, 0.45)   # indigo
@export var palette_bg: Color = Color(0.05, 0.04, 0.03)  # dark warp

var _quad: Array = []          # quadrant CA state, ceil(cols/2) x ceil(rows/2)
var _next: Array = []
var _qc: int = 0
var _qr: int = 0
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
	if config.has("palette_a"):
		palette_a = _parse_color(config["palette_a"], palette_a)
	if config.has("palette_b"):
		palette_b = _parse_color(config["palette_b"], palette_b)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_init_state()
	var fw: float = cols * cell
	var fh: float = rows * cell
	# backing wall slab behind the tapestry
	var wall_mat := _matte_mat(Color(0.06, 0.05, 0.05), 0.95, 0.0)
	add_child(_box(Vector3(0.0, fh * 0.5, -cell * 0.9), Vector3(fw + 0.5, fh + 0.5, cell * 0.4), wall_mat))
	# field VERTICAL as a wall, centred on X, sitting just above floor
	_mi = _make_field(cols, rows, cell, true)
	_mi.position = Vector3(-fw * 0.5, 0.1, 0.0)
	add_child(_mi)
	# overhead label
	_label = _billboard_label("THE RUG IS AN ALGORITHM\nTHAT FORGOT IT WAS RUNNING", Vector3(0.0, fh + 0.6, 0.0), 44, Color(0.92, 0.85, 0.65))
	add_child(_label)
	# PRE-RUN to a settled symmetric pattern
	for i in range(warmup_steps):
		_step()
	_paint()


func _init_state() -> void:
	_qc = (cols + 1) / 2
	_qr = (rows + 1) / 2
	_quad = []
	_next = []
	for r in range(_qr):
		var row: Array = []
		var nrow: Array = []
		for c in range(_qc):
			row.append(1 if _rng.randf() < 0.5 else 0)
			nrow.append(0)
		_quad.append(row)
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
	# Maze rule on the quadrant → stable corridors; mirrored → rug medallions
	for r in range(_qr):
		var nrow: Array = _next[r]
		for c in range(_qc):
			var n: int = _neighbours(c, r)
			var alive: int = int(_quad[r][c])
			if alive == 1:
				nrow[c] = 1 if (n >= 1 and n <= 5) else 0
			else:
				nrow[c] = 1 if n == 3 else 0
	var tmp: Array = _quad
	_quad = _next
	_next = tmp
	_steps += 1
	if _steps >= freeze_after:
		_frozen = true
		if _label:
			_label.text = "THE RUG IS AN ALGORITHM\nTHAT FORGOT IT WAS RUNNING — WOVEN"


func _neighbours(cx: int, cy: int) -> int:
	var n: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x: int = cx + dx
			var y: int = cy + dy
			if x < 0 or x >= _qc or y < 0 or y >= _qr:
				continue
			n += int(_quad[y][x])
	return n


func _quad_value(c: int, r: int) -> int:
	# mirror full grid coords into the quadrant
	var qx: int = c if c < _qc else (cols - 1 - c)
	var qy: int = r if r < _qr else (rows - 1 - r)
	qx = clampi(qx, 0, _qc - 1)
	qy = clampi(qy, 0, _qr - 1)
	return int(_quad[qy][qx])


func _paint() -> void:
	var mm := _mi.multimesh
	for r in range(rows):
		for c in range(cols):
			var i: int = r * cols + c
			var on: int = _quad_value(c, r)
			var col: Color
			if on == 1:
				# alternate the two thread colours by a coarse checker for rug feel
				var band: bool = ((c / 4) + (r / 4)) % 2 == 0
				col = palette_a if band else palette_b
				if _frozen:
					col = col * 1.15
			else:
				col = palette_bg
			# border frame
			if c <= 1 or c >= cols - 2 or r <= 1 or r >= rows - 2:
				col = palette_a * 0.8
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
