extends Node3D

## Pattern Control Plate — the Dieter Rams control surface for the pattern machines.
##
## A light matte back-board. Every interactive element sits FLUSH on the board front
## (z = 0) inside a raised frame — the "box" each control lives in (the interactable_demo
## convention: frames are proud, elements are flush, nothing pokes through the board).
## Four functional sliders (GROUP / MOTIF / PALETTE / SPEED) in a 2x2 grid, a cube button
## (RANDOM) sunk in a socket, and a flush inset monitor showing the live selection.
##
## Emits `changed(key, value)` on a slider move and `randomized()` on the cube. The host
## machine wires these to its pattern engine; the plate manages its own readout.

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
const WELL_DARK := Color(0.30, 0.29, 0.30)
const DISPLAY_DARK := Color(0.11, 0.11, 0.125)
const TEXT_DARK := Color(0.17, 0.17, 0.19)
const TEXT_DISPLAY := Color(0.90, 0.89, 0.85)
const ACCENT := Color(0.86, 0.34, 0.11)

# board geometry — front face sits at z = 0; everything else is referenced off that
const BOARD_W := 1.44
const BOARD_H := 1.30
const BOARD_CY := 0.65
const FRONT := 0.0
const RIM_Z := 0.012      # raised frame rims
const FLUSH_Z := 0.004    # flush inset surfaces (screen, well floor)
const CTRL_Z := 0.05      # interactables stand proud, inside their frame
const TEXT_Z := 0.016

@export var group_index: int = 10
@export var motif_index: int = 2
@export var period_index: int = 4
@export var fill_speed: float = 2.2

var _monitor: Label3D = null
var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	_built = true

	# --- the back-board (front face at z = 0) -----------------------------------
	add_child(_box(Vector3(0.0, BOARD_CY, -0.035), Vector3(BOARD_W, BOARD_H, 0.07), _mat(PANEL_LIGHT, 0.82)))
	add_child(_box(Vector3(0.0, BOARD_CY, -0.052), Vector3(BOARD_W + 0.04, BOARD_H + 0.04, 0.03), _mat(PANEL_TRIM, 0.85)))
	# one thin warm accent line near the top — the single Braun gesture
	add_child(_box(Vector3(0.0, BOARD_CY + BOARD_H * 0.5 - 0.07, 0.006), Vector3(BOARD_W - 0.10, 0.012, 0.008), _emat(ACCENT, 0.2)))
	_text(0.0, BOARD_CY + BOARD_H * 0.5 - 0.13, "PATTERN  CONTROL", 24, TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)

	# --- top row: inset monitor (left) + cube socket (right) --------------------
	_build_monitor(Vector3(-0.31, 0.90, 0.0), 0.74, 0.34)
	_build_cube_socket(Vector3(0.50, 0.90, 0.0), 0.30)

	# --- 2x2 slider grid, each control framed -----------------------------------
	var grid := [
		{"key": "group",  "label": "GROUP",   "count": GROUPS.size(),  "idx": group_index,  "x": -0.34, "y": 0.50},
		{"key": "motif",  "label": "MOTIF",   "count": MOTIFS.size(),  "idx": motif_index,  "x":  0.34, "y": 0.50},
		{"key": "period", "label": "PALETTE", "count": PERIODS.size(), "idx": period_index, "x": -0.34, "y": 0.18},
		{"key": "speed",  "label": "SPEED",   "count": 0,              "idx": 0,            "x":  0.34, "y": 0.18},
	]
	for r in grid:
		_build_slider_box(r)

	_update_monitor()


# ── elements ──────────────────────────────────────────────────────────────────

func _build_monitor(c: Vector3, w: float, h: float) -> void:
	add_child(_box(Vector3(c.x, c.y, FLUSH_Z), Vector3(w, h, 0.006), _emat(DISPLAY_DARK, 0.0)))   # flush dark screen
	_frame(c.x, c.y, w + 0.03, h + 0.03)                                                          # raised bezel
	_monitor = _text(c.x - w * 0.5 + 0.03, c.y, "", 22, TEXT_DISPLAY, HORIZONTAL_ALIGNMENT_LEFT)
	_monitor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_cube_socket(c: Vector3, s: float) -> void:
	add_child(_box(Vector3(c.x, c.y, FLUSH_Z), Vector3(s, s, 0.008), _mat(WELL_DARK, 0.7)))        # recessed well floor
	_frame(c.x, c.y, s + 0.02, s + 0.02)                                                           # raised socket rim
	_text(c.x, c.y - s * 0.5 - 0.03, "RANDOM", 16, TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	if ResourceLoader.exists(CUBE_SCENE):
		var cube: Node = load(CUBE_SCENE).instantiate()
		cube.name = "RandomCube"
		cube.set("show_plate", false)       # the socket IS its box
		cube.set("label", "")
		cube.set("cube_size", 0.07)
		add_child(cube)
		(cube as Node3D).position = Vector3(c.x, c.y, 0.03)   # sits low on the board, inside the socket
		if cube.has_signal("pressed"):
			cube.connect("pressed", func(): randomized.emit())


func _build_slider_box(r: Dictionary) -> void:
	var cx: float = r["x"]
	var cy: float = r["y"]
	var bw := 0.64
	var bh := 0.24
	_frame(cx, cy, bw, bh)                                                                          # the control's box
	# label INSIDE the box, top-left
	_text(cx - bw * 0.5 + 0.04, cy + bh * 0.5 - 0.045, String(r["label"]), 22, TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT)
	if not ResourceLoader.exists(SLIDER_SCENE):
		return
	var s: Node = load(SLIDER_SCENE).instantiate()
	var key: String = r["key"]
	s.name = "Slider_%s" % key
	add_child(s)
	# the slider FILLS the lower half of its box, sitting low on the board
	(s as Node3D).position = Vector3(cx, cy - 0.05, 0.02)
	(s as Node3D).scale = Vector3.ONE * 1.7
	if s.has_method("set_param_name"):
		s.call("set_param_name", "")
	var count: int = int(r["count"])
	var init_norm: float = 0.5
	if count > 1:
		init_norm = float(int(r["idx"])) / float(count - 1)
	elif key == "speed":
		init_norm = clampf((fill_speed - 0.5) / 7.5, 0.0, 1.0)
	if s.has_method("set_normalized_value"):
		s.call("set_normalized_value", init_norm)
	if s.has_signal("slider_moved"):
		s.connect("slider_moved", func(_v): _on_slider(key, s))


func _on_slider(key: String, s: Node) -> void:
	if not s.has_method("get_normalized_value"):
		return
	var norm: float = clampf(s.call("get_normalized_value"), 0.0, 1.0)
	var value: float = 0.0
	match key:
		"group":  group_index = _idx(norm, GROUPS.size());  value = group_index
		"motif":  motif_index = _idx(norm, MOTIFS.size());  value = motif_index
		"period": period_index = _idx(norm, PERIODS.size()); value = period_index
		"speed":  fill_speed = lerpf(0.5, 8.0, norm);        value = fill_speed
	_update_monitor()
	changed.emit(key, value)


func _idx(norm: float, count: int) -> int:
	return clampi(roundi(norm * float(count - 1)), 0, count - 1)


func _update_monitor() -> void:
	if _monitor == null:
		return
	_monitor.text = "GROUP    %s\nMOTIF    %s\nPALETTE  %s\nSPEED    %.1f" % [
		GROUPS[group_index], MOTIFS[motif_index], PERIODS[period_index], fill_speed]


# ── builders ──────────────────────────────────────────────────────────────────

## A raised outline frame (4 bars) — the "box" an element sits inside.
func _frame(cx: float, cy: float, w: float, h: float, thick: float = 0.012) -> void:
	var mat := _mat(FRAME_GREY, 0.55)
	var hw := w * 0.5
	var hh := h * 0.5
	add_child(_box(Vector3(cx, cy + hh, RIM_Z), Vector3(w + thick, thick, 0.014), mat))   # top
	add_child(_box(Vector3(cx, cy - hh, RIM_Z), Vector3(w + thick, thick, 0.014), mat))   # bottom
	add_child(_box(Vector3(cx - hw, cy, RIM_Z), Vector3(thick, h, 0.014), mat))           # left
	add_child(_box(Vector3(cx + hw, cy, RIM_Z), Vector3(thick, h, 0.014), mat))           # right


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
