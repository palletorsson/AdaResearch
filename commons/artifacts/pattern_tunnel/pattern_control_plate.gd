extends Node3D

## Pattern Control Plate — the shared Dieter Rams control surface for the pattern machines.
##
## A light matte back-board. Every interactive element sits FLUSH on the board front (z=0)
## inside a raised frame (the box). A configurable list of sliders in a 2-column grid, a
## cube button (RANDOM), and a flush inset monitor showing the live selection.
##
## CONFIGURABLE: call configure(title, specs) before adding to the tree, where each spec is
##   {"key": String, "label": String, "names": Array, "init": int|float}
## names empty => a continuous 0..1 control (the value is shown as a float). The plate emits
## `changed(key, value)` (value = chosen index for named controls, or the float) and
## `randomized()` on the cube. Default config = the tunnel's four controls.

signal changed(key: String, value: float)
signal randomized()

const SLIDER_SCENE := "res://commons/interactables/slider_horizontal.tscn"
const CUBE_SCENE := "res://commons/interactables/cube_button.tscn"

const GROUPS := ["P1","P2","PM","PG","PMM","PMG","PGG","CM","CMM","P4","P4M","P4G","P3","P3M1","P31M","P6","P6M"]
const MOTIFS := ["Checkerboard","Greek Key","Hex Rosette","Eight-Point Star"]
const PERIODS := ["Republican","Imperial","Cosmatesque","Renaissance","Baroque"]

# Braun / Dieter Rams palette
const PANEL_LIGHT := Color(0.81, 0.79, 0.75)
const PANEL_TRIM := Color(0.69, 0.67, 0.63)
const FRAME_GREY := Color(0.55, 0.53, 0.50)
const DISPLAY_DARK := Color(0.11, 0.11, 0.125)
const TEXT_DARK := Color(0.17, 0.17, 0.19)
const TEXT_DISPLAY := Color(0.90, 0.89, 0.85)
const ACCENT := Color(0.86, 0.34, 0.11)

# fixed anchors (chosen so a 4-control config matches the tunnel's tuned look)
const GRID_TOP := 0.50
const ROW_SP := 0.345
const MON_Y := 0.90
const BOARD_TOP := 1.31
const RIM_Z := 0.012
const FLUSH_Z := 0.004
const TEXT_Z := 0.016

var title: String = "PATTERN CONTROL"
var _specs: Array = []
var _values: Dictionary = {}
var _monitor: Label3D = null
var _built := false


func _ready() -> void:
	if not _built:
		_build()


## Set the title + control list. Call before the node enters the tree (or it rebuilds).
func configure(p_title: String, specs: Array) -> void:
	title = p_title
	_specs = specs
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _default_specs() -> Array:
	return [
		{"key": "group",  "label": "GROUP",   "names": GROUPS,  "init": 10},
		{"key": "motif",  "label": "MOTIF",   "names": MOTIFS,  "init": 2},
		{"key": "period", "label": "PALETTE", "names": PERIODS, "init": 4},
		{"key": "speed",  "label": "SPEED",   "names": [],      "init": 2.2},
	]


func _build() -> void:
	_built = true
	if _specs.is_empty():
		_specs = _default_specs()
	_values.clear()
	for spec in _specs:
		_values[spec["key"]] = spec.get("init", 0)

	var n: int = _specs.size()
	var rows: int = int(ceil(float(n) / 2.0))
	var last_row_y: float = GRID_TOP - float(rows - 1) * ROW_SP
	var board_bottom: float = last_row_y - 0.20
	var board_h: float = BOARD_TOP - board_bottom
	var board_cy: float = (BOARD_TOP + board_bottom) * 0.5

	# --- back-board (front face at z = 0) ---------------------------------------
	add_child(_box(Vector3(0.0, board_cy, -0.035), Vector3(1.44, board_h, 0.07), _mat(PANEL_LIGHT, 0.82)))
	add_child(_box(Vector3(0.0, board_cy, -0.052), Vector3(1.48, board_h + 0.04, 0.03), _mat(PANEL_TRIM, 0.85)))
	add_child(_box(Vector3(0.0, BOARD_TOP - 0.07, 0.006), Vector3(1.34, 0.012, 0.008), _emat(ACCENT, 0.2)))
	_text(0.0, BOARD_TOP - 0.135, title, 34, TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)

	# --- top row: inset monitor (left) + cube socket (right) --------------------
	_build_monitor(Vector3(-0.31, MON_Y, 0.0), 0.74, 0.34)
	_build_cube(Vector3(0.50, MON_Y, 0.0))

	# --- the slider grid (2 columns) --------------------------------------------
	for i in range(n):
		var col: int = i % 2
		var row: int = int(i / 2)
		var x: float = -0.34 if col == 0 else 0.34
		var y: float = GRID_TOP - float(row) * ROW_SP
		_build_slider_box(_specs[i], x, y)

	_update_monitor()


func _build_monitor(c: Vector3, w: float, h: float) -> void:
	add_child(_box(Vector3(c.x, c.y, FLUSH_Z), Vector3(w, h, 0.006), _emat(DISPLAY_DARK, 0.0)))
	_frame(c.x, c.y, w + 0.03, h + 0.03)
	_monitor = _text(c.x - w * 0.5 + 0.03, c.y, "", 22, TEXT_DISPLAY, HORIZONTAL_ALIGNMENT_LEFT)
	_monitor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_cube(c: Vector3) -> void:
	_text(c.x, c.y + 0.135, "RANDOM", 24, TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	if not ResourceLoader.exists(CUBE_SCENE):
		return
	var cube: Node = load(CUBE_SCENE).instantiate()
	cube.name = "RandomCube"
	cube.set("show_plate", true)
	cube.set("label", "")
	cube.set("cube_size", 0.08)
	add_child(cube)
	(cube as Node3D).position = Vector3(c.x, c.y, 0.014)
	if cube.has_signal("pressed"):
		cube.connect("pressed", func(): randomized.emit())


func _build_slider_box(spec: Dictionary, cx: float, cy: float) -> void:
	# a thin frame outline with an even gutter; the label sits above
	_frame(cx, cy, 0.46, 0.22)
	_text(cx, cy + 0.155, String(spec["label"]), 24, TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	if not ResourceLoader.exists(SLIDER_SCENE):
		return
	var s: Node = load(SLIDER_SCENE).instantiate()
	var key: String = spec["key"]
	s.name = "Slider_%s" % key
	add_child(s)
	(s as Node3D).position = Vector3(cx, cy, 0.02)
	(s as Node3D).scale = Vector3.ONE * 1.5
	if s.has_method("set_param_name"):
		s.call("set_param_name", "")
	var names: Array = spec.get("names", [])
	var count: int = names.size()
	var init_norm: float = 0.5
	if count > 1:
		init_norm = float(int(spec.get("init", 0))) / float(count - 1)
	else:
		init_norm = clampf((float(spec.get("init", 0.5)) - 0.5) / 7.5, 0.0, 1.0)  # continuous 0.5..8
	if s.has_method("set_normalized_value"):
		s.call("set_normalized_value", init_norm)
	if s.has_signal("slider_moved"):
		s.connect("slider_moved", func(_v): _on_slider(key, s, names))


func _on_slider(key: String, s: Node, names: Array) -> void:
	if not s.has_method("get_normalized_value"):
		return
	var norm: float = clampf(s.call("get_normalized_value"), 0.0, 1.0)
	var value: float
	if names.size() > 1:
		value = float(clampi(roundi(norm * float(names.size() - 1)), 0, names.size() - 1))
	else:
		value = lerpf(0.5, 8.0, norm)
	_values[key] = value
	_update_monitor()
	changed.emit(key, value)


func _update_monitor() -> void:
	if _monitor == null:
		return
	var lines: PackedStringArray = []
	for spec in _specs:
		var v: float = float(_values.get(spec["key"], 0))
		var names: Array = spec.get("names", [])
		var disp: String
		if names.size() > 0:
			disp = String(names[clampi(int(v), 0, names.size() - 1)])
		else:
			disp = "%.1f" % v
		lines.append("%s   %s" % [String(spec["label"]).rpad(8), disp])
	_monitor.text = "\n".join(lines)


# ── builders ──────────────────────────────────────────────────────────────────

func _frame(cx: float, cy: float, w: float, h: float, thick: float = 0.012) -> void:
	var mat := _mat(FRAME_GREY, 0.55)
	var hw := w * 0.5
	var hh := h * 0.5
	add_child(_box(Vector3(cx, cy + hh, RIM_Z), Vector3(w + thick, thick, 0.014), mat))
	add_child(_box(Vector3(cx, cy - hh, RIM_Z), Vector3(w + thick, thick, 0.014), mat))
	add_child(_box(Vector3(cx - hw, cy, RIM_Z), Vector3(thick, h, 0.014), mat))
	add_child(_box(Vector3(cx + hw, cy, RIM_Z), Vector3(thick, h, 0.014), mat))


func _box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	return mi


func _text(x: float, y: float, t: String, font: int, col: Color, align: int) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = font
	l.pixel_size = 0.0011
	l.modulate = col
	l.horizontal_alignment = align
	l.position = Vector3(x, y, TEXT_Z)
	add_child(l)
	return l


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = rough
	return m


func _emat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	m.roughness = 0.5
	return m
