extends Node3D

## Pattern Control Plate — the Dieter Rams control surface for the pattern machines.
##
## A light matte board (the background plate) carrying each interactive element on its
## own recessed sub-plate: four functional sliders (GROUP / MOTIF / PALETTE / SPEED), a
## cube button (RANDOM), and a calm dark monitor showing the current selection. Modeled
## on interactable_demo / pattern_studio_plate — every control is a real interactable.
##
## Emits `changed(key, value)` when a slider moves (key in group/motif/period/speed,
## value = the chosen index or speed) and `randomized()` when the cube is pressed. The
## host machine wires these to its pattern engine; the plate manages its own readout.

signal changed(key: String, value: float)
signal randomized()

const SLIDER_SCENE := "res://commons/interactables/slider_horizontal.tscn"
const CUBE_SCENE := "res://commons/interactables/cube_button.tscn"

const GROUPS := ["P1","P2","PM","PG","PMM","PMG","PGG","CM","CMM","P4","P4M","P4G","P3","P3M1","P31M","P6","P6M"]
const MOTIFS := ["Checkerboard","Greek Key","Hex Rosette","Eight-Point Star"]
const PERIODS := ["Republican","Imperial","Cosmatesque","Renaissance","Baroque"]

# Braun / Dieter Rams palette
const PANEL_LIGHT := Color(0.81, 0.79, 0.75)
const PANEL_TRIM := Color(0.70, 0.68, 0.64)
const SUBPLATE := Color(0.62, 0.60, 0.57)
const DISPLAY_DARK := Color(0.12, 0.12, 0.135)
const TEXT_DARK := Color(0.17, 0.17, 0.19)
const TEXT_DISPLAY := Color(0.90, 0.89, 0.85)
const ACCENT := Color(0.86, 0.34, 0.11)

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

	# --- the background board ---------------------------------------------------
	add_child(_box(Vector3(0.0, 0.62, -0.04), Vector3(1.42, 1.26, 0.07), _mat(PANEL_LIGHT, 0.8)))
	add_child(_box(Vector3(0.0, 0.62, -0.005), Vector3(1.46, 1.30, 0.02), _mat(PANEL_TRIM, 0.85)))
	# one thin warm accent line along the top edge — the single Braun gesture
	add_child(_box(Vector3(0.0, 1.23, 0.01), Vector3(1.4, 0.012, 0.01), _emat(ACCENT, 0.2)))
	add_child(_text("PATTERN  CONTROL", Vector3(0.0, 1.16, 0.02), 26, TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))

	# --- the monitor (top-left) -------------------------------------------------
	var mc := Vector3(-0.30, 0.93, 0.02)
	add_child(_box(mc + Vector3(0, 0, -0.006), Vector3(0.78, 0.34, 0.02), _mat(PANEL_TRIM, 0.85)))   # bezel
	add_child(_box(mc, Vector3(0.72, 0.28, 0.008), _emat(DISPLAY_DARK, 0.0)))                         # dark screen
	_monitor = _text("", mc + Vector3(0.0, 0.0, 0.01), 24, TEXT_DISPLAY, HORIZONTAL_ALIGNMENT_CENTER)
	_monitor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_monitor)

	# --- the cube button (top-right): RANDOM ------------------------------------
	if ResourceLoader.exists(CUBE_SCENE):
		var cube: Node = load(CUBE_SCENE).instantiate()
		cube.name = "RandomCube"
		add_child(cube)
		(cube as Node3D).position = Vector3(0.5, 0.93, 0.06)
		cube.set("label", "RANDOM")
		if cube.has_signal("pressed"):
			cube.connect("pressed", func(): randomized.emit())

	# --- four slider rows, each on its own sub-plate ----------------------------
	var rows := [
		{"key": "group",  "label": "GROUP",   "count": GROUPS.size(),  "idx": group_index},
		{"key": "motif",  "label": "MOTIF",   "count": MOTIFS.size(),  "idx": motif_index},
		{"key": "period", "label": "PALETTE", "count": PERIODS.size(), "idx": period_index},
		{"key": "speed",  "label": "SPEED",   "count": 0,              "idx": 0},
	]
	var y := 0.60
	for r in rows:
		_slider_row(r, y)
		y -= 0.18

	_update_monitor()


func _slider_row(r: Dictionary, y: float) -> void:
	# recessed sub-plate behind the control (the per-element backing plate)
	add_child(_box(Vector3(0.06, y, 0.0), Vector3(1.24, 0.15, 0.012), _mat(SUBPLATE, 0.9)))
	add_child(_text(String(r["label"]), Vector3(-0.55, y + 0.006, 0.02), 21, TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT))
	if not ResourceLoader.exists(SLIDER_SCENE):
		return
	var s: Node = load(SLIDER_SCENE).instantiate()
	var key: String = r["key"]
	s.name = "Slider_%s" % key
	add_child(s)
	(s as Node3D).position = Vector3(0.12, y, 0.05)
	(s as Node3D).scale = Vector3.ONE * 0.95
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
	_monitor.text = "GROUP   %s\nMOTIF   %s\nPALETTE %s\nSPEED   %.1f" % [
		GROUPS[group_index], MOTIFS[motif_index], PERIODS[period_index], fill_speed]


# ── builders ──────────────────────────────────────────────────────────────────

func _box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	return mi


func _text(t: String, pos: Vector3, font: int, col: Color, align: int) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = font
	l.pixel_size = 0.0011
	l.modulate = col
	l.horizontal_alignment = align
	l.position = pos
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
