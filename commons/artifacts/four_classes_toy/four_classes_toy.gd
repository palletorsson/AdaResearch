extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FourClassesToy

## @identity
## lineage: Wolfram 1983 elementary cellular automata -> the four-class taxonomy ->
##   "A New Kind of Science".
## essence: four tiny 1D rule strips held in the hand. Rule 250 freezes (Class 1), rule 108
##   ticks periodically (Class 2), rule 30 boils into chaos (Class 3), rule 110 weaves
##   structure that neither settles nor dissolves (Class 4). The fourth is tinted as the live one.
## truth: each rule is a contingent little universe sharing one law-shape (8 bits). The RUN
##   makes the class, not the rule's size. Class 4 is the alive middle — the edge where
##   computation lives, the deep that is short to state and costly, irreversibly, to unfold.

@export var width: int = 14            # cells across each 1D strip
@export var history: int = 18          # generations stacked
@export var cell: float = 0.011
@export var gap: float = 0.018         # gap between the four strips
@export var class4_tint: Color = Color(0.30, 1.0, 0.65, 1.0)
@export var on_color: Color = Color(0.85, 0.92, 1.0, 1.0)
@export var off_color: Color = Color(0.05, 0.06, 0.10, 1.0)
@export var reseed_seconds: float = 14.0

# one rule per Wolfram class
const RULES: Array = [250, 108, 30, 110]
const CLASS_LABEL: Array = ["1", "2", "3", "4"]

var _fields: Array = []                # MultiMeshInstance3D per strip
var _rows: Array = []                  # current PackedByteArray row per strip
var _gen: Array = []                   # row index being written per strip
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

	# small held backing plate
	var strip_w: float = float(width) * cell
	var total_w: float = 4.0 * strip_w + 3.0 * gap
	add_child(_box(Vector3(0.0, 0.0, -0.012), Vector3(total_w + 0.05, float(history) * cell + 0.05, 0.012), _matte_mat(Color(0.10, 0.11, 0.14))))

	add_child(_billboard_label("FOUR CLASSES", Vector3(0.0, float(history) * cell * 0.5 + 0.06, 0.0), 14, on_color))

	for s: int in range(4):
		var f: MultiMeshInstance3D = _make_field(width, history, cell, true)
		var x0: float = -total_w * 0.5 + float(s) * (strip_w + gap)
		f.position = Vector3(x0, -float(history) * cell * 0.5, 0.0)
		# tint Class 4 strip's material emission so it reads as the live one
		if s == 3 and f.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = f.material_override
			m.emission = class4_tint
			m.emission_energy_multiplier = (0.9 if emissive else 0.0)
		add_child(f)
		_fields.append(f)
		# per-strip class label underneath
		add_child(_billboard_label(CLASS_LABEL[s], Vector3(x0 + strip_w * 0.5, -float(history) * cell * 0.5 - 0.03, 0.0), 12, (class4_tint if s == 3 else on_color)))
		_rows.append(PackedByteArray())
		_gen.append(0)

	_reset_all()
	# pre-run a full screen so the patterns are visible immediately
	for _i: int in range(history):
		_advance_all()
	_life = 0.0


func _reset_all() -> void:
	for s: int in range(4):
		var row := PackedByteArray()
		row.resize(width)
		for x: int in range(width):
			row[x] = 0
		# rule 30/110 read best from a single seed; 250/108 from a sprinkle
		if RULES[s] == 250 or RULES[s] == 108:
			for x: int in range(width):
				row[x] = 1 if _rng.randf() < 0.4 else 0
		else:
			row[width / 2] = 1
		_rows[s] = row
		_gen[s] = 0
		# clear field
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
	# top of strip is newest: write at row (history-1-g) while scrolling fills downward
	var r: int = (history - 1) - g
	if r < 0:
		return
	var row: PackedByteArray = _rows[s]
	for x: int in range(width):
		var i: int = r * width + x
		var lit: bool = int(row[x]) == 1
		if lit:
			mm.set_instance_color(i, class4_tint if s == 3 else on_color)
		else:
			mm.set_instance_color(i, off_color)


func _scroll_field(s: int) -> void:
	# shift every row down by one so newest stays at top
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
			# steady scroll once the strip is full
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
