extends Node3D
class_name ArrayVisualizer

# @identity
# essence: a row of boxes whose heights are the stored values, a fixed integer index engraved under each one, and a lit read-head that walks the row on a clock so you watch the pointer move while the contents stand still
# desire: to break the beginner's collapse of index into element — the row is not a list of numbers, it is a list of PLACES, and one of them is being read right now
# critical_parameter: step_period against values.size() — how long the head rests on a cell; slow enough and the readout "i = 3 / a[i] = 8" is two facts, fast enough and it fuses back into one
# triggers: _ready() lays the plinth, mints one cell per value with height proportional to it and a Label3D index beneath; _process advances an accumulator and moves the caret and the highlight to the next cell
# emerges: the array stops being a picture of data and becomes a machine with a position in it — the same mechanism the bar_array sort artifacts run, stripped back until only the addressing is left
# needs: BoxMesh cells and a CylinderMesh caret [Godot built-ins]; Grid.gdshader for the cell skin [present]; Label3D per index and one readout [built-in]; TextScreen PAD plate [present]
# relationships: the primitive underneath bar_array_histogram and bar_array_insertion_sort — they animate the CONTENTS with this same row; this one animates only the pointer, so the row is the constant
# truth: the index is not the element. Every sort, every hash, every off-by-one lives in that gap, and a row of boxes with numbers written under them is the smallest honest place to see it.

## The plain array, at pedestal scale. Same mechanism as the bar_array family —
## a row of boxes and a moving head — with the algorithm removed, so what is left
## on stage is the addressing itself.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

## The stored contents. Fixed, not generated: this artifact is about where the
## values live, not where they came from, and a stable row means the read-head is
## the only thing in the frame that ever moves.
@export var values: PackedInt32Array = PackedInt32Array([3, 7, 1, 8, 2, 6, 4, 5])
@export var step_period: float = 0.75
@export var tool_label: String = "ARRAY"

const PLINTH_W: float = 0.90
const PLINTH_D: float = 0.30
const PLINTH_H: float = 0.10
const CELL_W: float = 0.072
const CELL_D: float = 0.072
const CELL_PITCH: float = 0.095
const HEIGHT_MIN: float = 0.045
const HEIGHT_SPAN: float = 0.30

var _built: bool = false
var _accum: float = 0.0
var _head: int = 0

var _cells: Array[MeshInstance3D] = []
var _cell_mats: Array[Material] = []
var _caret: MeshInstance3D
var _readout: Label3D

## Every node THIS script parented onto itself. A rebuild frees these and nothing
## else — the grid adds label plates, packaging and tags after us.
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


func _build_all() -> void:
	_cells.clear()
	_cell_mats.clear()
	_head = 0
	_accum = 0.0
	_build_plinth()
	_build_cells()
	_build_caret()
	_build_readout()
	_build_label()
	_apply_head()


func _process(delta: float) -> void:
	if not _built or _cells.is_empty():
		return
	_accum += delta
	if _accum < maxf(0.05, step_period):
		return
	_accum = 0.0
	_head = (_head + 1) % _cells.size()
	_apply_head()


# ── geometry ─────────────────────────────────────────────────────────

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _count() -> int:
	return maxi(1, values.size())


func _max_value() -> int:
	var m: int = 1
	for v in values:
		m = maxi(m, int(v))
	return m


## Left-to-right centre of cell i on the plinth top.
func _cell_x(i: int) -> float:
	var n: int = _count()
	var span: float = float(n - 1) * CELL_PITCH
	return -span * 0.5 + float(i) * CELL_PITCH


func _cell_height(i: int) -> float:
	var v: float = float(values[i]) / float(_max_value())
	return HEIGHT_MIN + v * HEIGHT_SPAN


func _build_plinth() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Plinth"
	var box := BoxMesh.new()
	# Wide enough that the row never overhangs, whatever count a map hands us.
	var w: float = maxf(PLINTH_W, float(_count()) * CELL_PITCH + 0.12)
	box.size = Vector3(w, PLINTH_H, PLINTH_D)
	mi.mesh = box
	mi.position = Vector3(0.0, PLINTH_H * 0.5, 0.0)
	mi.material_override = _witness_mat()
	_own(mi)


func _build_cells() -> void:
	for i in range(_count()):
		var h: float = _cell_height(i)
		var mi := MeshInstance3D.new()
		mi.name = "Cell_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(CELL_W, h, CELL_D)
		mi.mesh = box
		mi.position = Vector3(_cell_x(i), PLINTH_H + h * 0.5, 0.0)
		var mat: Material = _cell_mat()
		mi.material_override = mat
		_own(mi)
		_cells.append(mi)
		_cell_mats.append(mat)

		# The index, engraved under its cell on the plinth face. It never moves
		# and never changes — that is the half of the pair the head is not.
		var idx := Label3D.new()
		idx.name = "Index_%d" % i
		idx.text = str(i)
		idx.font_size = 64
		idx.pixel_size = 0.00075
		idx.outline_size = 12
		idx.modulate = Color(0.62, 0.70, 0.82)
		idx.position = Vector3(_cell_x(i), PLINTH_H * 0.5, PLINTH_D * 0.5 + 0.004)
		_own(idx)


## A wedge hanging over the row. It is the only thing in the piece that moves.
func _build_caret() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "ReadHead"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.032
	cone.height = 0.055
	cone.radial_segments = 4
	mi.mesh = cone
	mi.rotation = Vector3(PI, 0.0, 0.0)     # apex down, pointing at the cell
	mi.material_override = _head_mat()
	_own(mi)
	_caret = mi


func _build_readout() -> void:
	var lbl := Label3D.new()
	lbl.name = "Readout"
	lbl.text = "i = 0    a[i] = 0"
	lbl.font_size = 48
	lbl.pixel_size = 0.0011
	lbl.outline_size = 10
	lbl.modulate = Color(1.0, 0.86, 0.42)
	lbl.position = Vector3(0.0, PLINTH_H + HEIGHT_MIN + HEIGHT_SPAN + 0.16, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(lbl)
	_readout = lbl


func _build_label() -> void:
	# Configure BEFORE add_child — TextScreen rebuilds on each setter once in-tree.
	var ts := TextScreenScript.new()
	ts.name = "ToolPlate"
	ts.mode = 2                            # Mode.PAD — reclined plaque
	ts.width_m = 0.30
	ts.position = Vector3(0.0, PLINTH_H + 0.005, -PLINTH_D * 0.5 + 0.02)
	if ts.has_method("set_text"):
		ts.set_text(tool_label, "the index is not the element")
	_created.append(ts)
	add_child(ts)


# ── the head ─────────────────────────────────────────────────────────

## Move the caret, relight one cell, rewrite the readout. Index and element are
## printed as two separate terms on purpose — the readout is the argument.
func _apply_head() -> void:
	if _cells.is_empty():
		return
	var i: int = clampi(_head, 0, _cells.size() - 1)
	for j in range(_cell_mats.size()):
		_set_cell_lit(j, j == i)
	if is_instance_valid(_caret):
		_caret.position = Vector3(_cell_x(i), PLINTH_H + _cell_height(i) + 0.075, 0.0)
	if is_instance_valid(_readout):
		_readout.text = "i = %d    a[i] = %d" % [i, int(values[i])]


func _set_cell_lit(i: int, lit: bool) -> void:
	if i < 0 or i >= _cell_mats.size():
		return
	var mat: Material = _cell_mats[i]
	var shader_mat := mat as ShaderMaterial
	if shader_mat:
		var fill: Color = Color(0.95, 0.72, 0.28) if lit else Color(0.30, 0.42, 0.56)
		var wire: Color = Color(1.0, 0.92, 0.55) if lit else Color(0.45, 0.72, 0.95)
		shader_mat.set_shader_parameter("modelColor", fill)
		shader_mat.set_shader_parameter("wireframeColor", wire)
		shader_mat.set_shader_parameter("emissionColor", wire)
		shader_mat.set_shader_parameter("emission_strength", 4.0 if lit else 1.2)
		return
	var std := mat as StandardMaterial3D
	if std:
		std.albedo_color = Color(0.95, 0.72, 0.28) if lit else Color(0.30, 0.42, 0.56)


# ── material ─────────────────────────────────────────────────────────

func _cell_mat() -> Material:
	return _grid_material(Color(0.30, 0.42, 0.56), Color(0.45, 0.72, 0.95), 1.2)


func _head_mat() -> Material:
	return _grid_material(Color(0.95, 0.72, 0.28), Color(1.0, 0.92, 0.55), 4.0)


func _witness_mat() -> Material:
	return _grid_material(Color(0.26, 0.28, 0.34), Color(0.42, 0.47, 0.57), 0.5)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


# ── config ───────────────────────────────────────────────────────────

## Synchronous and scoped to our own children. Nothing deferred: the grid frames
## labels and grounds the artifact right after add_child, and a deferred rebuild
## would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_caret = null
	_readout = null
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_values: PackedInt32Array = values.duplicate()
	var before_label: String = tool_label

	if config_data.has("values"):
		var raw = config_data["values"]
		var parsed := PackedInt32Array()
		if raw is Array or raw is PackedInt32Array or raw is PackedFloat32Array:
			for v in raw:
				parsed.append(int(v))
		elif raw is String:
			for part in str(raw).split(",", false):
				parsed.append(int(str(part).strip_edges()))
		if parsed.size() >= 2:
			values = parsed
	if config_data.has("step_period"):
		# Speed alone never needs a rebuild — the head reads it every frame.
		step_period = maxf(0.05, float(config_data["step_period"]))
	if config_data.has("label"):
		tool_label = str(config_data["label"])

	if not _built:
		# _ready has not run yet; it will build with the values just resolved.
		return
	if values == before_values and tool_label == before_label:
		# Nothing geometric changed. curation_station hands every artifact it
		# curates {"emissive": false} moments after framing labels — rebuilding
		# here would throw that framing away and never get it back.
		return

	_rebuild_now()
	print("[ArrayVisualizer] Config applied — %d cells, step=%.2fs" % [_count(), step_period])
