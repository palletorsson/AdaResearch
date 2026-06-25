extends Node3D
class_name StationConsoleDesk

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the freestanding sci-fi OPERATOR TERMINAL of the curation-station family — a wedge/trapezoid painted-metal BODY (wide at the floor, a recessed knee-hole at the front-bottom so you can sit/stand to it), an angled DESK surface near the top carrying a SCREEN readout + a ridged KEYBOARD block, and a SWITCHBOARD PANEL rising above the desk: a grid of small lit indicator caps (rows x cols of amber/grey boxes). A tall side wears louver VENTS. Weathered white painted-metal, one warm accent, a printed label. Human-scale (~1.4 m tall, ~1.2 m wide). Origin at the floor centre; the operator stands at +Z.
# desire: to be the place a person OPERATES from — to turn a bay from a thing you look at into a thing you work, giving the room a console that reports and a surface a hand reaches for. It wants to read as staffed, monitored, in-use.
# critical_parameter: switchboard_cols x switchboard_rows — the density of the lit indicator grid is what reads "control panel" vs "empty desk"; width sets how much console there is to face.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config sets meta + rebuilds.
# emerges: a plain wedge reads "desk"; a lit screen + ridged keys read "a station you type at"; a dense lit switchboard reads "control room, many things watched"; louver vents read "this runs warm, it is powered"; a printed label reads "this terminal has a name".
# needs: a wedge body with a knee-hole [present]; an angled desk top [present]; a screen readout [present]; a keyboard block [optional, with_keyboard]; a switchboard cell grid [present]; louver vents on a tall side [optional, vent_side]; a printed label + caution stripe [present].
# relationships: the WORKING sibling of [[station_cabinet]] (watch THAT, type at THIS) and [[station_plinth]]; staged on [[station_stage]], framed by [[station_pillar]]; assembled into a bay by [[curation_station]]; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal look (light matte body, one warm accent, caution stripes, baked screens).
# truth: a console is the room admitting a person belongs in it. The knee-hole is the honesty of the form — it says: come close, sit, this is yours to drive.

@export_group("Dimensions")
## Console width along X (m).
@export var width: float = 1.2
## Console height to the top of the switchboard (m).
@export var height: float = 1.4
## Console depth along Z (m).
@export var depth: float = 0.7

@export_group("Switchboard")
## Rows of lit indicator cells above the desk.
@export var switchboard_rows: int = 3
## Columns of lit indicator cells above the desk.
@export var switchboard_cols: int = 10

@export_group("Desk")
## Build the ridged keyboard block on the desk surface.
@export var with_keyboard: bool = true
## Readout lines shown on the angled screen.
@export var screen_lines: PackedStringArray = PackedStringArray(["SYS ONLINE", "BAY 07", "RDY"])

@export_group("Vents")
## Which tall side wears louver vents: "left" | "right" | "none".
@export var vent_side: String = "right"

@export_group("Surface")
## Printed label across the front skirt (blank = none).
@export var label_text: String = "OPERATOR"
@export var wear: float = 0.1
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const DESK_THICK := 0.05
const TOP_PLATE := 0.04

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_width"): width = float(str(get_meta("config_width")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_depth"): depth = float(str(get_meta("config_depth")))
	if has_meta("config_switchboard_rows"): switchboard_rows = int(str(get_meta("config_switchboard_rows")))
	if has_meta("config_switchboard_cols"): switchboard_cols = int(str(get_meta("config_switchboard_cols")))
	if has_meta("config_with_keyboard"): with_keyboard = _b(get_meta("config_with_keyboard"))
	if has_meta("config_screen_lines"): screen_lines = _lines(get_meta("config_screen_lines"))
	if has_meta("config_vent_side"): vent_side = str(get_meta("config_vent_side")).to_lower()
	if has_meta("config_label_text"): label_text = str(get_meta("config_label_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var w: float = clampf(width, 0.9, 1.6)
	var h: float = clampf(height, 1.2, 1.8)
	var d: float = clampf(depth, 0.45, 0.95)
	var body_mat := _mat(body_color)
	var panel_mat := _mat(panel_color)

	# ── Vertical proportions ──────────────────────────────────────────
	# desk_y = top of the angled desk surface at the back; the switchboard
	# rises above it to h. The knee-hole opens at the front-bottom.
	var desk_y: float = h * 0.58
	var board_h: float = h - desk_y
	var knee_h: float = desk_y * 0.52          # height of the recessed knee opening
	var knee_w: float = w * 0.64               # width of the knee opening
	var leg_w: float = (w - knee_w) * 0.5      # the two side legs flanking the knee-hole

	# ── Wedge body: two side legs + a sloped front skirt above the knee ─
	# Side legs (full depth, floor to desk) — these carry the desk.
	for sx in [-1.0, 1.0]:
		var lx: float = sx * (w * 0.5 - leg_w * 0.5)
		add_child(_box(Vector3(lx, desk_y * 0.5, 0.0), Vector3(leg_w, desk_y, d), body_mat))

	# Back wall of the body (full width, floor to desk) — closes the wedge behind the knee.
	add_child(_box(Vector3(0.0, desk_y * 0.5, -d * 0.5 + 0.06), Vector3(w, desk_y, 0.12), body_mat))

	# Sloped front skirt ABOVE the knee-hole: a slab spanning the knee width,
	# from the top of the knee opening up to the desk, angled back (the wedge face).
	var skirt_h: float = desk_y - knee_h
	if skirt_h > 0.04:
		var skirt_cy: float = knee_h + skirt_h * 0.5
		var skirt := _box(Vector3(0.0, skirt_cy, d * 0.5 - 0.10), Vector3(knee_w, skirt_h, 0.10), panel_mat)
		skirt.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
		add_child(skirt)
		# A thin sill at the lip of the knee-hole (reads as the recessed opening edge).
		add_child(_box(Vector3(0.0, knee_h, d * 0.5 - 0.02), Vector3(knee_w, 0.025, 0.05), _mat(panel_color.darkened(0.12))))

	# Printed label + caution stripe across one front leg skirt.
	if label_text.strip_edges() != "":
		var lbl: MeshInstance3D = HangarKit.stencil(label_text, Vector2(minf(leg_w * 0.9, 0.42), 0.1))
		if lbl:
			lbl.position = Vector3(-w * 0.5 + leg_w * 0.5, desk_y * 0.5, d * 0.5 + 0.01)
			add_child(lbl)
	# Caution stripe along the bottom front of the right leg.
	add_child(_box(Vector3(w * 0.5 - leg_w * 0.5, 0.06, d * 0.5 + 0.005), Vector3(leg_w * 0.9, 0.08, 0.02), HangarKit.striped_mat()))

	# ── Angled desk top surface ───────────────────────────────────────
	var desk := _box(Vector3(0.0, desk_y + DESK_THICK * 0.5, 0.04), Vector3(w, DESK_THICK, d * 0.86), _mat(body_color.lightened(0.04)))
	desk.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	add_child(desk)
	# Front lip of the desk (the edge a hand rests on).
	add_child(_box(Vector3(0.0, desk_y + 0.01, d * 0.5 - 0.02), Vector3(w, 0.04, 0.04), _mat(panel_color.darkened(0.06))))

	# ── Screen readout on the desk (set back, tilted to face the operator) ─
	var scr_w: float = minf(w * 0.5, 0.62)
	var scr_h: float = scr_w * 0.6
	var screen: Node3D = HangarKit.readout("TERMINAL", _line_array(), Vector2(scr_w, scr_h))
	if screen:
		screen.position = Vector3(-w * 0.16, desk_y + 0.06 + scr_h * 0.5, -d * 0.18)
		screen.rotation_degrees = Vector3(-58.0, 0.0, 0.0)
		add_child(screen)

	# ── Ridged keyboard block (front portion of the desk) ─────────────
	if with_keyboard:
		_build_keyboard(w, d, desk_y)

	# ── Switchboard panel: grid of small lit indicator cells ──────────
	_build_switchboard(w, desk_y, board_h, d)

	# ── Louver vents on a tall side ───────────────────────────────────
	if vent_side == "left" or vent_side == "right":
		var sgn: float = -1.0 if vent_side == "left" else 1.0
		_build_vents(sgn * (w * 0.5 + 0.005), desk_y, d)

	# ── Finishing: a Dieter-Rams accent bar + grime ───────────────────
	var bar: Node3D = HangarKit.three_color_bar(knee_w * 0.7, 0.035, [accent_color, panel_color.darkened(0.2), body_color])
	bar.position = Vector3(0.0, desk_y - 0.05, d * 0.5 + 0.015)
	add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(w, 0.06, d * 0.5 + 0.006, body_color))


func _build_keyboard(w: float, d: float, desk_y: float) -> void:
	var kb_w: float = w * 0.42
	var kb_d: float = d * 0.3
	var base_mat := _mat(panel_color.darkened(0.05))
	var key_mat := _mat(body_color.darkened(0.02))
	# Keyboard base tray, slightly toward the operator, following the desk tilt.
	var base := _box(Vector3(w * 0.2, desk_y + 0.05, d * 0.22), Vector3(kb_w, 0.03, kb_d), base_mat)
	base.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	add_child(base)
	# Ridged keys: short rows of small caps.
	var rows := 3
	var cols := 8
	var gx: float = kb_w * 0.84 / float(cols)
	var gz: float = kb_d * 0.74 / float(rows)
	for r in range(rows):
		for c in range(cols):
			var kx: float = w * 0.2 - kb_w * 0.42 + (float(c) + 0.5) * gx
			var kz: float = d * 0.22 - kb_d * 0.37 + (float(r) + 0.5) * gz
			var key := _box(Vector3(kx, desk_y + 0.08, kz), Vector3(gx * 0.72, 0.018, gz * 0.7), key_mat)
			key.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
			add_child(key)


func _build_switchboard(w: float, desk_y: float, board_h: float, d: float) -> void:
	var rows: int = clampi(switchboard_rows, 1, 6)
	var cols: int = clampi(switchboard_cols, 2, 18)
	var bz: float = -d * 0.22                      # the board sits at the back of the desk
	# Backing panel for the switchboard (the recessed face the caps sit in).
	var back := _box(Vector3(0.0, desk_y + board_h * 0.5, bz - 0.02), Vector3(w * 0.92, board_h, 0.05), _mat(panel_color.darkened(0.1)))
	back.rotation_degrees = Vector3(6.0, 0.0, 0.0)
	add_child(back)
	# Top cap of the console.
	add_child(_box(Vector3(0.0, desk_y + board_h + TOP_PLATE * 0.5, bz - 0.02), Vector3(w * 0.94, TOP_PLATE, 0.12), _mat(body_color.lightened(0.03))))

	# The grid of small lit indicator caps.
	var grid_w: float = w * 0.82
	var grid_h: float = board_h * 0.74
	var x0: float = -grid_w * 0.5
	var y0: float = desk_y + board_h * 0.5 - grid_h * 0.5
	var gx: float = grid_w / float(cols)
	var gy: float = grid_h / float(rows)
	var cap_w: float = gx * 0.66
	var cap_h: float = gy * 0.6
	var grey_mat := _mat(panel_color.darkened(0.18))
	var lit_mat := HangarKit.emissive(accent_color, 0.9)
	var lit_dim := HangarKit.emissive(accent_color.darkened(0.35), 0.4)
	for r in range(rows):
		for c in range(cols):
			var cx: float = x0 + (float(c) + 0.5) * gx
			var cy: float = y0 + (float(r) + 0.5) * gy
			# Deterministic pattern: a fraction of caps lit (amber), the rest grey.
			var seed_v: int = (r * 31 + c * 17) % 7
			var m: Material
			if seed_v == 0:
				m = lit_mat
			elif seed_v == 3:
				m = lit_dim
			else:
				m = grey_mat
			var cap := _box(Vector3(cx, cy, bz + 0.012), Vector3(cap_w, cap_h, 0.022), m)
			cap.rotation_degrees = Vector3(6.0, 0.0, 0.0)
			add_child(cap)


func _build_vents(side_x: float, desk_y: float, d: float) -> void:
	var vent_mat := HangarKit.worn_metal(panel_color)
	var louvers: int = maxi(int(desk_y / 0.1), 4)
	var span: float = desk_y * 0.72
	var z0: float = -d * 0.28
	var z1: float = d * 0.28
	for i in range(louvers):
		var ly: float = desk_y * 0.16 + span * (float(i) / float(louvers - 1))
		# A thin angled slat on the side face.
		var slat := _box(Vector3(side_x, ly, (z0 + z1) * 0.5), Vector3(0.025, 0.022, z1 - z0), vent_mat)
		slat.rotation_degrees = Vector3(0.0, 0.0, 22.0)
		add_child(slat)


func _line_array() -> Array:
	var out: Array = []
	for s in screen_lines:
		out.append(str(s))
	if out.is_empty():
		out = ["SYS ONLINE"]
	return out


func _mat(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _lines(v) -> PackedStringArray:
	if v is PackedStringArray:
		return v
	if v is Array:
		var out := PackedStringArray()
		for e in v:
			out.append(str(e))
		return out
	# A delimited string: split on "|" then newline then comma.
	var s := str(v)
	for sep in ["|", "\n", ","]:
		if s.find(sep) != -1:
			var parts := s.split(sep, false)
			var out2 := PackedStringArray()
			for p in parts:
				out2.append(str(p).strip_edges())
			return out2
	return PackedStringArray([s])


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
