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

# --- live pattern preview (the "pattern rect") ------------------------------
const WallpaperGroups = preload("res://commons/primitives/arrays/wallpaper_groups.gd")
const MOTIF_GRIDS := [
	{"size": 2, "data": [[0,1],[1,0]]},
	{"size": 8, "data": [[1,1,1,1,1,1,1,0],[0,0,0,0,0,0,1,0],[0,1,1,1,1,0,1,0],[0,1,0,0,1,0,1,0],[0,1,0,1,1,0,1,0],[0,1,0,0,0,0,1,0],[0,1,1,1,1,1,1,0],[0,0,0,0,0,0,0,0]]},
	{"size": 8, "data": [[0,0,0,1,1,0,0,0],[0,0,1,2,2,1,0,0],[0,1,2,1,1,2,1,0],[1,2,1,0,0,1,2,1],[1,2,1,0,0,1,2,1],[0,1,2,1,1,2,1,0],[0,0,1,2,2,1,0,0],[0,0,0,1,1,0,0,0]]},
	{"size": 8, "data": [[0,0,0,1,1,0,0,0],[0,0,1,1,1,1,0,0],[0,1,1,0,0,1,1,0],[1,1,0,0,0,0,1,1],[1,1,0,0,0,0,1,1],[0,1,1,0,0,1,1,0],[0,0,1,1,1,1,0,0],[0,0,0,1,1,0,0,0]]},
]
const PREVIEW_PAL := [
	Color(0.95, 0.93, 0.88), Color(0.85, 0.20, 0.28), Color(0.13, 0.45, 0.78),
	Color(0.97, 0.78, 0.18), Color(0.20, 0.62, 0.45), Color(0.10, 0.10, 0.13),
]

# Braun / Dieter Rams palette
const PANEL_LIGHT := Color(0.81, 0.79, 0.75)
const PANEL_TRIM := Color(0.69, 0.67, 0.63)
const FRAME_GREY := Color(0.55, 0.53, 0.50)
const DISPLAY_DARK := Color(0.11, 0.11, 0.125)
const TEXT_DARK := Color(0.17, 0.17, 0.19)
const TEXT_MUTED := Color(0.42, 0.40, 0.40)     # secondary labels (param names) — recede behind the value
const TEXT_DISPLAY := Color(0.95, 0.94, 0.90)   # monitor value text — high contrast on dark glass
const TEXT_DISPLAY_DIM := Color(0.58, 0.62, 0.66)  # monitor row labels — dimmer than the value
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
var control_scale: float = 1.0   # counter-scale for the XR sliders/cube so they stay world-1.0 when the plate is scaled
var _specs: Array = []
var _values: Dictionary = {}
var _monitor: Label3D = null          # bright value column (the live readout)
var _monitor_labels: Label3D = null   # dim param-name column to its left
var _preview_mat: StandardMaterial3D = null
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

	# --- top row: text monitor (left) + pattern rect (centre) + cube (right) ----
	_build_monitor(Vector3(-0.50, MON_Y, 0.0), 0.40, 0.34)
	_build_preview(Vector3(0.06, MON_Y, 0.0), 0.42, 0.34)
	_build_cube(Vector3(0.58, MON_Y, 0.0))

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
	# header strip, dimmer + smaller, so the live readout below is what the eye lands on
	_text(c.x, c.y + h * 0.5 + 0.038, "SELECTION", 14, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	# two columns: dim param names (left) + bright values (right). Values are the readout.
	_monitor_labels = _text(c.x - w * 0.5 + 0.028, c.y, "", 16, TEXT_DISPLAY_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	_monitor_labels.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_monitor_labels.line_spacing = 8.0
	_monitor = _text(c.x - w * 0.5 + 0.165, c.y, "", 21, TEXT_DISPLAY, HORIZONTAL_ALIGNMENT_LEFT)
	_monitor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_monitor.line_spacing = 8.0


## The live "pattern rect" — a wallpaper swatch of the current group + motif.
func _build_preview(c: Vector3, w: float, h: float) -> void:
	_preview_mat = StandardMaterial3D.new()
	_preview_mat.roughness = 0.85
	_preview_mat.metallic = 0.0
	_preview_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_preview_mat.albedo_color = Color.WHITE
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	q.mesh = qm
	q.material_override = _preview_mat
	q.position = Vector3(c.x, c.y, FLUSH_Z + 0.002)
	add_child(q)
	_frame(c.x, c.y, w + 0.03, h + 0.03)
	_text(c.x, c.y + h * 0.5 + 0.03, "PATTERN", 18, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_regen_preview()


func _regen_preview() -> void:
	if _preview_mat == null:
		return
	var gi: int = clampi(int(_values.get("group", 10)), 0, 16)
	var mi: int = clampi(int(_values.get("motif", 0)), 0, MOTIF_GRIDS.size() - 1)
	var m: Dictionary = MOTIF_GRIDS[mi]
	var grid: Array = m["data"]
	var gs: int = int(m["size"])
	var n: int = 4 * gs
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for py in range(n):
		for px in range(n):
			var ci: int = WallpaperGroups.get_symmetric_color(px, py, gs, grid, gi)
			img.set_pixel(px, py, PREVIEW_PAL[ci % PREVIEW_PAL.size()])
	_preview_mat.albedo_texture = ImageTexture.create_from_image(img)


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
	(cube as Node3D).scale = Vector3.ONE * control_scale
	if cube.has_signal("pressed"):
		cube.connect("pressed", func(): randomized.emit())


func _build_slider_box(spec: Dictionary, cx: float, cy: float) -> void:
	# a thin frame outline hugging the slider; the param label sits above (secondary),
	# the chosen NAME (primary) is rendered big on the slider's own value label.
	_frame(cx, cy, 0.34, 0.16)
	_text(cx, cy + 0.118, String(spec["label"]), 17, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	if not ResourceLoader.exists(SLIDER_SCENE):
		return
	var s: Node = load(SLIDER_SCENE).instantiate()
	var key: String = spec["key"]
	s.name = "Slider_%s" % key
	add_child(s)
	# XR-Tools sliders break under parent scale (grab math multiplies by basis incl. scale);
	# control_scale counters the plate's own scale so the slider ends at world-scale 1.0.
	(s as Node3D).position = Vector3(cx, cy - 0.012, 0.02)
	(s as Node3D).scale = Vector3.ONE * control_scale
	# Make the chosen NAME the most legible thing on the panel: enlarge the slider's
	# own value label (a Label3D — touching its text props only, NOT the slider scale).
	_boost_value_label(s)
	var names: Array = spec.get("names", [])
	var count: int = names.size()
	if count > 1 and s.has_method("set_choices"):
		s.call("set_choices", names)             # discrete chooser: one detent per choice, shows names
	elif s.has_method("set_param_name"):
		s.call("set_param_name", "")
	var mn: float = float(spec.get("min", 0.5))
	var mx: float = float(spec.get("max", 8.0))
	var init_norm: float = 0.5
	if count > 1:
		init_norm = float(int(spec.get("init", 0))) / float(count - 1)
	elif mx > mn:
		init_norm = clampf((float(spec.get("init", mn)) - mn) / (mx - mn), 0.0, 1.0)
	if s.has_method("set_normalized_value"):
		s.call("set_normalized_value", init_norm)
	if s.has_signal("slider_moved"):
		s.connect("slider_moved", func(_v): _on_slider(spec, s))


func _on_slider(spec: Dictionary, s: Node) -> void:
	if not s.has_method("get_normalized_value"):
		return
	var norm: float = clampf(s.call("get_normalized_value"), 0.0, 1.0)
	var names: Array = spec.get("names", [])
	var value: float
	if names.size() > 1:
		value = float(clampi(roundi(norm * float(names.size() - 1)), 0, names.size() - 1))
	else:
		value = lerpf(float(spec.get("min", 0.5)), float(spec.get("max", 8.0)), norm)
	_values[spec["key"]] = value
	_update_monitor()
	changed.emit(spec["key"], value)


func _update_monitor() -> void:
	if _monitor == null:
		return
	var label_lines: PackedStringArray = []
	var value_lines: PackedStringArray = []
	for spec in _specs:
		var v: float = float(_values.get(spec["key"], 0))
		var names: Array = spec.get("names", [])
		var disp: String
		if names.size() > 0:
			disp = String(names[clampi(int(v), 0, names.size() - 1)])
		else:
			disp = "%.1f" % v
		label_lines.append(String(spec["label"]))
		value_lines.append(disp)
	if _monitor_labels != null:
		_monitor_labels.text = "\n".join(label_lines)
	_monitor.text = "\n".join(value_lines)
	_regen_preview()


# ── builders ──────────────────────────────────────────────────────────────────

## The chosen NAME is the single most important thing the operator reads. The slider
## scene ships it tiny (font 14, pixel_size 0.0008). We enlarge ONLY that Label3D's
## text properties — never the slider node's scale (which would break XR-Tools grab math).
func _boost_value_label(s: Node) -> void:
	var lbl := s.get_node_or_null("Frame/Label3DValue") as Label3D
	if lbl == null:
		return
	lbl.font_size = 30
	lbl.pixel_size = 0.0016
	lbl.modulate = TEXT_DARK
	lbl.outline_size = 10
	lbl.outline_modulate = Color(PANEL_LIGHT.r, PANEL_LIGHT.g, PANEL_LIGHT.b, 1.0)
	# lift it clear of the track so the bigger glyphs read against the board, not the groove
	lbl.position = Vector3(lbl.position.x, 0.052, 0.012)


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
