extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FourClassesBench

## @identity
## lineage: Wolfram 1983 elementary CA -> the four-class taxonomy -> "A New Kind of Science".
## essence: the four class exemplars stood up as four panels on a bench. Class 1 freezes,
##   Class 2 ticks, Class 3 boils, Class 4 weaves — and only the fourth panel glows, because
##   only the edge between order and chaos is alive.
## truth: one law-shape (8 bits), four contingent universes. The RULE does not predict the
##   class; the RUN does. Class 4 is the alive middle — short to seed, costly and irreversible
##   to unfold, the deep that no shortcut around the run will give you.

@export var width: int = 24
@export var history: int = 24
@export var cell: float = 0.018
@export var class4_tint: Color = Color(0.30, 1.0, 0.65, 1.0)
@export var on_color: Color = Color(0.82, 0.90, 1.0, 1.0)
@export var off_color: Color = Color(0.04, 0.05, 0.09, 1.0)
@export var reseed_seconds: float = 18.0

const RULES: Array = [250, 108, 30, 110]
const PANEL_TITLE: Array = ["CLASS 1\nfrozen", "CLASS 2\nperiodic", "CLASS 3\nchaotic", "CLASS 4\ncomplex / edge"]

var _fields: Array = []
var _rows: Array = []
var _gen: Array = []
var _accum: float = 0.0
var _life: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("width"):
		width = int(config["width"])
	if config.has("history"):
		history = int(config["history"])
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
	_fields = []
	_rows = []
	_gen = []

	# bench
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.04, 0.6), _matte_mat(Color(0.16, 0.17, 0.20))))
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.0, 0.82, 0.5), _matte_mat(Color(0.10, 0.11, 0.13))))

	add_child(_billboard_label("WOLFRAM'S FOUR WEATHERS\nonly the fourth is alive", Vector3(0.0, 1.6, 0.0), 28, class4_tint))

	var strip_w: float = float(width) * cell
	var strip_h: float = float(history) * cell
	var pitch: float = strip_w + 0.05
	var total_w: float = 4.0 * strip_w + 3.0 * 0.05
	var base_y: float = 0.87 + 0.10
	var base_z: float = 0.30

	for s: int in range(4):
		var x0: float = -total_w * 0.5 + float(s) * pitch
		# panel backing
		var back_mat: StandardMaterial3D = _glow_mat(class4_tint, 0.6) if s == 3 else _matte_mat(Color(0.07, 0.08, 0.11))
		add_child(_box(Vector3(x0 + strip_w * 0.5, base_y + strip_h * 0.5, base_z - 0.012), Vector3(strip_w + 0.02, strip_h + 0.02, 0.012), back_mat))

		var f: MultiMeshInstance3D = _make_field(width, history, cell, true)
		f.position = Vector3(x0, base_y, base_z)
		if s == 3 and f.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = f.material_override
			m.emission = class4_tint
			m.emission_energy_multiplier = (1.0 if emissive else 0.0)
		add_child(f)
		_fields.append(f)

		add_child(_billboard_label(PANEL_TITLE[s], Vector3(x0 + strip_w * 0.5, base_y + strip_h + 0.07, base_z), 14, (class4_tint if s == 3 else on_color)))
		_rows.append(PackedByteArray())
		_gen.append(0)

	_reset_all()
	for _i: int in range(history):
		_advance_all()
	_life = 0.0


func _reset_all() -> void:
	for s: int in range(4):
		var row := PackedByteArray()
		row.resize(width)
		for x: int in range(width):
			row[x] = 0
		if RULES[s] == 250 or RULES[s] == 108:
			for x: int in range(width):
				row[x] = 1 if _rng.randf() < 0.42 else 0
		else:
			row[width / 2] = 1
		_rows[s] = row
		_gen[s] = 0
		var mm: MultiMesh = _fields[s].multimesh
		for i: int in range(width * history):
			mm.set_instance_color(i, off_color)
		_write_row(s)


func _apply_rule(rule: int, row: PackedByteArray) -> PackedByteArray:
	var nxt := PackedByteArray()
	nxt.resize(width)
	for x: int in range(width):
		var l: int = int(row[(x - 1 + width) % width])
		var c: int = int(row[x])
		var r: int = int(row[(x + 1) % width])
		var idx: int = (l << 2) | (c << 1) | r
		nxt[x] = 1 if ((rule >> idx) & 1) == 1 else 0
	return nxt


func _write_row(s: int) -> void:
	var mm: MultiMesh = _fields[s].multimesh
	var g: int = int(_gen[s])
	var r: int = (history - 1) - g
	if r < 0:
		return
	var row: PackedByteArray = _rows[s]
	for x: int in range(width):
		var i: int = r * width + x
		if int(row[x]) == 1:
			mm.set_instance_color(i, class4_tint if s == 3 else on_color)
		else:
			mm.set_instance_color(i, off_color)


func _scroll_field(s: int) -> void:
	var mm: MultiMesh = _fields[s].multimesh
	for r: int in range(0, history - 1):
		for x: int in range(width):
			var src: int = (r + 1) * width + x
			var dst: int = r * width + x
			mm.set_instance_color(dst, mm.get_instance_color(src))


func _advance_all() -> void:
	for s: int in range(4):
		if _gen[s] < history:
			_gen[s] = int(_gen[s]) + 1
			_rows[s] = _apply_rule(int(RULES[s]), _rows[s])
			_write_row(s)
		else:
			_scroll_field(s)
			_rows[s] = _apply_rule(int(RULES[s]), _rows[s])
			var mm: MultiMesh = _fields[s].multimesh
			var row: PackedByteArray = _rows[s]
			for x: int in range(width):
				var i: int = (history - 1) * width + x
				mm.set_instance_color(i, (class4_tint if s == 3 else on_color) if int(row[x]) == 1 else off_color)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	_life += delta
	if _accum < 0.12:
		return
	_accum = 0.0
	_advance_all()
	if _life >= reseed_seconds:
		_life = 0.0
		_reset_all()
