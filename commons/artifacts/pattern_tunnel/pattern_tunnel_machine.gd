extends Node3D
class_name PatternTunnelMachine

## Pattern Tunnel Machine — the tunnel + the large console at its mouth.
##
## You stand at the beginning of the tunnel; a control console sits to the right of the
## entrance. Its sliders are the pattern-maker possibilities — GROUP (the 17 wallpaper
## symmetry groups), MOTIF (the source pattern), PERIOD (the palette), SPEED (how fast
## the tunnel paints). Touch any of them and the whole tube re-skins and the fill front
## surges forward (boost). The tunnel itself (pattern_tunnel) does the painting; this
## node wires its controls into a reachable VR interface.

const TunnelScene := preload("res://commons/artifacts/pattern_tunnel/pattern_tunnel.tscn")
const SLIDER_SCENE := "res://commons/interactables/slider_horizontal.tscn"

const GROUPS := ["P1","P2","PM","PG","PMM","PMG","PGG","CM","CMM","P4","P4M","P4G","P3","P3M1","P31M","P6","P6M"]
const MOTIF_NAMES := ["Checkerboard","Greek Key","Hex Rosette","Eight-Point Star"]
const PERIOD_NAMES := ["Republican","Imperial","Cosmatesque","Renaissance","Baroque"]

@export var group_index: int = 10
@export var motif_index: int = 2
@export var period_index: int = 4
@export var fill_speed: float = 2.2
@export var tunnel_length: int = 14      # rings down -Z (shorten to fit a busy map)
@export_range(0.0, 1.0, 0.01) var start_reveal: float = 0.0   # >0 for captures / a pre-painted start

var _tunnel: Node = null
var _monitor: Label3D = null
var _sliders: Dictionary = {}    # key -> slider node
var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	_built = true
	for c in get_children():
		c.queue_free()

	# the tunnel itself, extending down -Z from the mouth
	_tunnel = TunnelScene.instantiate()
	_tunnel.name = "Tunnel"
	_tunnel.set("tunnel_length", tunnel_length)
	_tunnel.set("group_index", group_index)
	_tunnel.set("motif_index", motif_index)
	_tunnel.set("period_index", period_index)
	_tunnel.set("fill_speed", fill_speed)
	_tunnel.set("reveal", start_reveal)   # 0 = start all white; it paints itself
	_tunnel.set("auto_run", true)
	add_child(_tunnel)

	_build_console()


# ── the console ──────────────────────────────────────────────────────────────

func _build_console() -> void:
	var root := Node3D.new()
	root.name = "Console"
	# to the right of the mouth, angled toward the player standing at the entrance
	root.position = Vector3(2.05, 0.0, 0.9)
	root.rotation_degrees = Vector3(0.0, -64.0, 0.0)
	add_child(root)

	# backing panel (a large ticket-machine console)
	root.add_child(_box(Vector3(0.0, 0.95, -0.06), Vector3(1.25, 1.9, 0.10), _panel(Color(0.12, 0.13, 0.16))))
	root.add_child(_box(Vector3(0.0, 0.95, -0.02), Vector3(1.18, 1.83, 0.04), _panel(Color(0.16, 0.17, 0.21))))
	root.add_child(_box(Vector3(0.0, 1.86, 0.0), Vector3(1.2, 0.04, 0.08), _accent(Color(0.75, 0.38, 0.13))))  # copper top
	# a stand
	root.add_child(_box(Vector3(0.0, 0.18, -0.04), Vector3(0.4, 0.36, 0.3), _panel(Color(0.10, 0.10, 0.12))))

	# title
	root.add_child(_text("PATTERN  TUNNEL", Vector3(0.0, 1.72, 0.03), 30, Color(0.85, 0.88, 0.95), HORIZONTAL_ALIGNMENT_CENTER))

	# monitor — current selection
	root.add_child(_box(Vector3(0.0, 1.42, 0.02), Vector3(1.0, 0.4, 0.012), _screen()))
	_monitor = _text("", Vector3(-0.46, 1.56, 0.03), 26, Color(0.55, 0.95, 0.8), HORIZONTAL_ALIGNMENT_LEFT)
	root.add_child(_monitor)

	# four sliders
	var rows := [
		{"key": "group", "label": "GROUP", "count": GROUPS.size(), "idx": group_index},
		{"key": "motif", "label": "MOTIF", "count": MOTIF_NAMES.size(), "idx": motif_index},
		{"key": "period", "label": "PALETTE", "count": PERIOD_NAMES.size(), "idx": period_index},
		{"key": "speed", "label": "SPEED", "count": 0, "idx": 0},
	]
	var y := 1.02
	for r in rows:
		_add_slider(root, r, y)
		y -= 0.27

	_update_monitor()


func _add_slider(root: Node3D, r: Dictionary, y: float) -> void:
	root.add_child(_text(String(r["label"]), Vector3(-0.52, y + 0.07, 0.03), 20, Color(0.7, 0.76, 0.86), HORIZONTAL_ALIGNMENT_LEFT))
	if not ResourceLoader.exists(SLIDER_SCENE):
		return
	var s: Node = load(SLIDER_SCENE).instantiate()
	s.name = "Slider_%s" % r["key"]
	root.add_child(s)
	(s as Node3D).position = Vector3(0.05, y, 0.05)
	(s as Node3D).scale = Vector3.ONE * 1.05
	var key: String = r["key"]
	var count: int = int(r["count"])
	var init_norm: float = 0.5
	if count > 1:
		init_norm = float(int(r["idx"])) / float(count - 1)
	elif key == "speed":
		init_norm = clampf((fill_speed - 0.5) / 7.5, 0.0, 1.0)
	if s.has_method("set_normalized_value"):
		s.call("set_normalized_value", init_norm)
	if s.has_signal("slider_moved"):
		s.connect("slider_moved", func(_v): _on_slider(key))
	_sliders[key] = s


func _on_slider(key: String) -> void:
	var s: Node = _sliders.get(key)
	if s == null or not s.has_method("get_normalized_value"):
		return
	var norm: float = clampf(s.call("get_normalized_value"), 0.0, 1.0)
	match key:
		"group":
			group_index = _idx(norm, GROUPS.size())
			if _tunnel: _tunnel.call("reskin", group_index, -1, -1)
		"motif":
			motif_index = _idx(norm, MOTIF_NAMES.size())
			if _tunnel: _tunnel.call("reskin", -1, motif_index, -1)
		"period":
			period_index = _idx(norm, PERIOD_NAMES.size())
			if _tunnel: _tunnel.call("reskin", -1, -1, period_index)
		"speed":
			fill_speed = lerpf(0.5, 8.0, norm)
			if _tunnel:
				_tunnel.set("fill_speed", fill_speed)
				_tunnel.call("boost")
	_update_monitor()


func _idx(norm: float, count: int) -> int:
	return clampi(roundi(norm * float(count - 1)), 0, count - 1)


func _update_monitor() -> void:
	if _monitor == null:
		return
	_monitor.text = "GROUP   %s\nMOTIF   %s\nPALETTE %s\nSPEED   %.1f" % [
		GROUPS[group_index], MOTIF_NAMES[motif_index], PERIOD_NAMES[period_index], fill_speed]


# ── little builders ──────────────────────────────────────────────────────────

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
	l.outline_size = 6
	l.horizontal_alignment = align
	l.position = pos
	return l


func _panel(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.2
	m.roughness = 0.8
	return m


func _screen() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.05, 0.05)
	m.emission_enabled = true
	m.emission = Color(0.05, 0.16, 0.13)
	m.emission_energy_multiplier = 0.7
	return m


func _accent(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.6
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.2
	return m


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("group_index"): group_index = int(config_data["group_index"])
	if config_data.has("motif_index"): motif_index = int(config_data["motif_index"])
	if config_data.has("period_index"): period_index = int(config_data["period_index"])
	if config_data.has("fill_speed"): fill_speed = float(config_data["fill_speed"])
	if config_data.has("tunnel_length"): tunnel_length = int(config_data["tunnel_length"])
	_built = false
	_build()
