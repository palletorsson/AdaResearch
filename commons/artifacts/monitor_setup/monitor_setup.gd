extends Node3D
class_name MonitorSetup

# @identity
# essence: a CONFIGURABLE INFO BOARD — a clamp-pole rig of screens rising from a dark
#   metal desk with a vented tower + keyboard, where EACH screen has its own size,
#   position, angle and CONTENT (title + body + type). The default board tells a small
#   coherent story; an author swaps the content to tell their own. Blade Runner
#   street-vendor energy meets a briefing wall: some screens carry real readable text
#   (info), some keep the old neon-poster look (poster), some show a procedural readout
#   (data). Cables drape between the screens and the base.
# desire: a lab needs a corner that BROADCASTS A NARRATIVE — not a single nameplate
#   (info_screen does that) but a CLUSTER of competing, authorable signals. A wall where
#   the content is data, so a map/registry/delegate can pour a story into the rig.
# critical_parameter: the `screens` array — the rig is defined by what its screens SAY,
#   what TYPE each is, and how hard they glow (screen_emission). Swap the array, swap the
#   whole story; the rig vocabulary (desk/tower/keyboard/pole/cables) stays constant.
# triggers: _ready() builds the desk/tower/keyboard, the clamp-pole sized to span the
#   configured screens, and one panel per `screens` entry (info=Label3D text, poster=neon
#   texture, data=graph texture), plus draping cables. apply_grid_config() reads a whole
#   `screens` array (CONTENT INPUT) + theme/scale/screen_count and rebuilds.
# emerges: the room gains a watcher that can TELL. The player reads a sequence across the
#   panels — a small narrative staged in light. Mediated presence as an authorable stack.
# needs: a floor to stand on (origin at the desk base, rig grows +Y); a viewer roughly on
#   +Z to read the screens; emissive rendering on so the glow lands. An author to supply
#   `screens` content (else the default story shows).
# relationships: cousin to info_screen (one labeled screen vs. a configurable wall of
#   them); sibling to surreal_lab (dense sci-fi clusters); pairs with any briefing/booth map.
# truth: a single screen informs; a CONFIGURED STACK of screens narrates. This rig is the
#   structural form of the BRIEFING WALL — many panels, one story, poured in as data.

## A CONFIGURABLE INFO BOARD built as a cyberpunk screen-rig. A clamp-pole of panels
## rises from a desk with a vented tower + keyboard; EACH panel's size, position, angle
## and CONTENT (title + body + type) is data-driven via the `screens` array, so an author
## can make the board tell a story. Panel types: "info" (Label3D title+body), "poster"
## (procedural neon texture), "data" (procedural graph texture). Cables drape to the base.
##
## All procedural. Origin sits at the desk base; the rig grows upward in +Y and the
## panels face roughly +Z. Re-entrant: apply_grid_config() rebuilds from scratch.

# ── DNA: toggles ──────────────────────────────────────────────────────

@export_group("Toggles")
@export var show_cables: bool = true
@export var screen_glow: bool = true

@export_group("Glow")
@export_range(0.0, 4.0) var screen_emission: float = 1.3

@export_group("Board")
## Uniform scale applied to the whole rig (desk + pole + every screen offset/size).
@export_range(0.25, 4.0) var board_scale: float = 1.0
## Theme accent tint mixed lightly into bezels/metal; Color.BLACK = no tint.
@export var theme_color: Color = Color(0, 0, 0)

# ── The configurable screen board ─────────────────────────────────────
# Each entry is a Dictionary describing ONE screen:
#   {
#     "title":     String,            # big headline (info type), short
#     "body":      String,            # multi-line body; "\n"-separated lines
#     "type":      "info"|"poster"|"data",
#     "size":      Vector2,           # panel face size in metres (w × h)
#     "pos":       Vector3,           # local offset on the rig (metres)
#     "angle_deg": float,             # yaw around Y
#     "pitch_deg": float,             # pitch around X
#     "color":     Color,             # accent / background theme for this panel
#     "mount":     "pole"|"base",     # clamp arm to the pole, or stand on the base
#   }
# Missing fields fall back to safe defaults (see _coerce_screen).
#
# DEFAULT STORY — "NIGHT SHIFT AT BLOCK 9": a small coherent sequence an author would
# replace. Five panels read top-to-bottom / left-to-right as a tiny narrative: a station
# announces itself, logs a quiet night, raises an anomaly, telemetry spikes, then the
# breach poster watches from below. Override this entire array via apply_grid_config()
# or the inspector to tell your own story.
@export var screens: Array = [
	{
		"title": "BLOCK 9",
		"body": "NIGHT WATCH STATION\nshift 03 — operator on duty\nall systems nominal",
		"type": "info",
		"size": Vector2(0.54, 0.36),
		"pos": Vector3(0.02, 1.84, 0.0),
		"angle_deg": 8.0,
		"pitch_deg": -10.0,
		"color": Color(0.05, 0.85, 0.95),
		"mount": "pole",
	},
	{
		"title": "LOG",
		"body": "02:14 corridor C quiet\n02:51 door 7 cycled\n03:06 nothing moves\n03:09 still nothing",
		"type": "info",
		"size": Vector2(0.42, 0.32),
		"pos": Vector3(-0.36, 1.5, -0.02),
		"angle_deg": 28.0,
		"pitch_deg": -4.0,
		"color": Color(0.6, 0.95, 0.4),
		"mount": "pole",
	},
	{
		"title": "ANOMALY",
		"body": "heat bloom — sector 4\nunlisted signature\nholding for confirm",
		"type": "info",
		"size": Vector2(0.42, 0.3),
		"pos": Vector3(0.36, 1.52, -0.02),
		"angle_deg": -26.0,
		"pitch_deg": -4.0,
		"color": Color(0.98, 0.7, 0.1),
		"mount": "pole",
	},
	{
		"title": "TELEMETRY",
		"body": "live signal — sector 4",
		"type": "data",
		"size": Vector2(0.46, 0.28),
		"pos": Vector3(-0.32, 1.18, 0.02),
		"angle_deg": 18.0,
		"pitch_deg": 2.0,
		"color": Color(0.2, 1.0, 0.5),
		"mount": "pole",
	},
	{
		"title": "SECURITY BREACH",
		"body": "INTRUDER — BLOCK 9\nlockdown engaged",
		"type": "poster",
		"size": Vector2(0.5, 0.32),
		"pos": Vector3(0.42, 1.17, 0.14),
		"angle_deg": -12.0,
		"pitch_deg": 4.0,
		"color": Color(0.95, 0.12, 0.1),
		"mount": "base",
	},
]

# ── Constants ─────────────────────────────────────────────────────────

const TEX_W: int = 256
const TEX_H: int = 180

const DESK_W: float = 1.4
const DESK_D: float = 0.7
const DESK_H: float = 0.08
const DESK_TOP_Y: float = 0.9          # desktop surface height

const POLE_RADIUS: float = 0.035
const POLE_MIN_TOP_Y: float = 2.0      # pole reaches at least ~2m
const POLE_X: float = -0.1
const POLE_Z: float = -0.18

const TEXT_PIXEL_SIZE: float = 0.0012  # Label3D world scale (mirrors info_screen)

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _metal_mat: StandardMaterial3D
var _dark_mat: StandardMaterial3D
var _cable_mat: StandardMaterial3D

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	# CONTENT INPUT: an author / map / registry / delegate supplies the board here.
	_read_simple_overrides(config_data)
	_read_screens_override(config_data)
	if _built:
		_clear_built_children()
		_built = false
		_build_all()


func _read_simple_overrides(config_data: Dictionary) -> void:
	if config_data.has("show_cables"):
		show_cables = _to_bool(config_data["show_cables"], show_cables)
	if config_data.has("screen_glow"):
		screen_glow = _to_bool(config_data["screen_glow"], screen_glow)
	if config_data.has("screen_emission"):
		screen_emission = _to_float(config_data["screen_emission"], screen_emission)
	# "scale" is the documented author key; "board_scale" also accepted.
	if config_data.has("scale"):
		board_scale = _to_float(config_data["scale"], board_scale)
	if config_data.has("board_scale"):
		board_scale = _to_float(config_data["board_scale"], board_scale)
	if config_data.has("theme"):
		theme_color = _to_color(config_data["theme"], theme_color)
	if config_data.has("theme_color"):
		theme_color = _to_color(config_data["theme_color"], theme_color)


func _read_screens_override(config_data: Dictionary) -> void:
	# Whole-board content input. Accepts an Array of Dictionaries; each Dictionary is
	# coerced defensively so JSON-sourced data (Arrays for Vector2/Vector3) is handled.
	if config_data.has("screens"):
		var raw = config_data["screens"]
		if raw is Array and raw.size() > 0:
			var rebuilt: Array = []
			for entry in raw:
				if entry is Dictionary:
					rebuilt.append(_coerce_screen(entry))
			if rebuilt.size() > 0:
				screens = rebuilt
	# Optional truncation/padding to a requested count.
	if config_data.has("screen_count"):
		var want: int = int(_to_float(config_data["screen_count"], float(screens.size())))
		want = clampi(want, 0, screens.size())
		if want >= 0 and want < screens.size():
			screens = screens.slice(0, want)


# ── Defensive coercion helpers ────────────────────────────────────────

func _to_bool(value, fallback: bool) -> bool:
	if value is bool:
		return value
	var s: String = str(value).strip_edges().to_lower()
	if s == "true" or s == "1" or s == "yes" or s == "on":
		return true
	if s == "false" or s == "0" or s == "no" or s == "off":
		return false
	return fallback


func _to_float(value, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var s: String = str(value).strip_edges()
	if s.is_valid_float():
		return s.to_float()
	return fallback


func _to_vec2(value, fallback: Vector2) -> Vector2:
	# Accept Vector2, or an Array/PackedArray of [w, h] (JSON path).
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(_to_float(value[0], fallback.x), _to_float(value[1], fallback.y))
	if value is PackedFloat32Array and value.size() >= 2:
		return Vector2(value[0], value[1])
	return fallback


func _to_vec3(value, fallback: Vector3) -> Vector3:
	# Accept Vector3, or an Array/PackedArray of [x, y, z] (JSON path).
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(
			_to_float(value[0], fallback.x),
			_to_float(value[1], fallback.y),
			_to_float(value[2], fallback.z))
	if value is PackedFloat32Array and value.size() >= 3:
		return Vector3(value[0], value[1], value[2])
	return fallback


func _to_color(value, fallback: Color) -> Color:
	# Accept Color, an Array [r,g,b(,a)], or a string "r,g,b" / "#rrggbb".
	if value is Color:
		return value
	if value is Array and value.size() >= 3:
		var a: float = 1.0
		if value.size() >= 4:
			a = _to_float(value[3], 1.0)
		return Color(
			_to_float(value[0], fallback.r),
			_to_float(value[1], fallback.g),
			_to_float(value[2], fallback.b), a)
	if value is String:
		var s: String = (value as String).strip_edges()
		if s.begins_with("#") and s.length() >= 7:
			return Color.html(s)
		var parts: PackedStringArray = s.split(",")
		if parts.size() >= 3:
			return Color(
				_to_float(parts[0], fallback.r),
				_to_float(parts[1], fallback.g),
				_to_float(parts[2], fallback.b))
	return fallback


func _coerce_screen(entry: Dictionary) -> Dictionary:
	# Build a fully-typed, fully-populated screen dict from a (possibly partial,
	# possibly JSON-shaped) author entry.
	var out: Dictionary = {}
	out["title"] = str(entry.get("title", ""))
	out["body"] = str(entry.get("body", ""))
	var t: String = str(entry.get("type", "info")).strip_edges().to_lower()
	if t != "poster" and t != "data" and t != "info":
		t = "info"
	out["type"] = t
	out["size"] = _to_vec2(entry.get("size", null), Vector2(0.45, 0.3))
	out["pos"] = _to_vec3(entry.get("pos", null), Vector3(0.0, 1.5, 0.0))
	out["angle_deg"] = _to_float(entry.get("angle_deg", 0.0), 0.0)
	out["pitch_deg"] = _to_float(entry.get("pitch_deg", 0.0), 0.0)
	out["color"] = _to_color(entry.get("color", null), Color(0.1, 0.8, 0.95))
	var m: String = str(entry.get("mount", "pole")).strip_edges().to_lower()
	if m != "base" and m != "pole":
		m = "pole"
	out["mount"] = m
	return out


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build orchestration ───────────────────────────────────────────────

func _build_all() -> void:
	_built = true
	_build_shared_materials()
	_build_desk_base()
	_build_tower()
	_build_keyboard()
	_build_device()
	_build_pole()
	_build_screens()
	if show_cables:
		_build_cables()
	if board_scale != 1.0:
		scale = Vector3(board_scale, board_scale, board_scale)


func _build_shared_materials() -> void:
	# Optional theme tint mixed lightly into the metal/bezel so a board can take a hue.
	var metal_base: Color = Color(0.22, 0.23, 0.27)
	var dark_base: Color = Color(0.07, 0.07, 0.09)
	if theme_color != Color(0, 0, 0):
		metal_base = metal_base.lerp(theme_color, 0.18)
		dark_base = dark_base.lerp(theme_color, 0.12)

	_metal_mat = StandardMaterial3D.new()
	_metal_mat.albedo_color = metal_base
	_metal_mat.metallic = 0.85
	_metal_mat.roughness = 0.35

	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = dark_base
	_dark_mat.metallic = 0.4
	_dark_mat.roughness = 0.6

	_cable_mat = StandardMaterial3D.new()
	_cable_mat.albedo_color = Color(0.04, 0.04, 0.05)
	_cable_mat.metallic = 0.1
	_cable_mat.roughness = 0.85


# ── Desk base ─────────────────────────────────────────────────────────

func _build_desk_base() -> void:
	# Desktop slab
	var top := MeshInstance3D.new()
	top.name = "DeskTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(DESK_W, DESK_H, DESK_D)
	top.mesh = tm
	top.material_override = _dark_mat
	top.position = Vector3(0.0, DESK_TOP_Y - DESK_H * 0.5, 0.0)
	add_child(top)

	# Two leg slabs (left, right)
	var leg_h: float = DESK_TOP_Y - DESK_H
	var leg_x: float = DESK_W * 0.5 - 0.08
	for i in 2:
		var leg := MeshInstance3D.new()
		leg.name = "DeskLeg_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(0.1, leg_h, DESK_D - 0.1)
		leg.mesh = lm
		leg.material_override = _metal_mat
		var sx: float = leg_x
		if i == 0:
			sx = -leg_x
		leg.position = Vector3(sx, leg_h * 0.5, 0.0)
		add_child(leg)


# ── Computer tower (vented front) ─────────────────────────────────────

func _build_tower() -> void:
	var tower_w: float = 0.26
	var tower_h: float = 0.5
	var tower_d: float = 0.42
	var base_x: float = -DESK_W * 0.5 + tower_w * 0.5 + 0.05
	var base_y: float = DESK_TOP_Y + tower_h * 0.5

	var tower := MeshInstance3D.new()
	tower.name = "Tower"
	var bm := BoxMesh.new()
	bm.size = Vector3(tower_w, tower_h, tower_d)
	tower.mesh = bm
	tower.material_override = _metal_mat
	tower.position = Vector3(base_x, base_y, 0.0)
	add_child(tower)

	# Vent slats on the front face (+Z), drawn as thin dark inset bars
	var vent_mat := StandardMaterial3D.new()
	vent_mat.albedo_color = Color(0.02, 0.02, 0.03)
	vent_mat.roughness = 0.95
	var front_z: float = tower_d * 0.5 + 0.002
	for i in 5:
		var vent := MeshInstance3D.new()
		vent.name = "TowerVent_%d" % i
		var vm := BoxMesh.new()
		vm.size = Vector3(tower_w * 0.62, 0.018, 0.01)
		vent.mesh = vm
		vent.material_override = vent_mat
		var vy: float = base_y + 0.14 - float(i) * 0.04
		vent.position = Vector3(base_x, vy, front_z)
		add_child(vent)

	# Power LED — small emissive dot
	var led := MeshInstance3D.new()
	led.name = "TowerLED"
	var lm := BoxMesh.new()
	lm.size = Vector3(0.02, 0.02, 0.01)
	led.mesh = lm
	led.material_override = _make_emissive_mat(Color(0.2, 1.0, 0.4), 2.0)
	led.position = Vector3(base_x, base_y - 0.18, front_z)
	add_child(led)


# ── Keyboard slab ─────────────────────────────────────────────────────

func _build_keyboard() -> void:
	var kb := MeshInstance3D.new()
	kb.name = "Keyboard"
	var km := BoxMesh.new()
	km.size = Vector3(0.4, 0.02, 0.16)
	kb.mesh = km
	var kb_mat := StandardMaterial3D.new()
	kb_mat.albedo_color = Color(0.12, 0.12, 0.14)
	kb_mat.metallic = 0.3
	kb_mat.roughness = 0.7
	kb.material_override = kb_mat
	kb.position = Vector3(0.18, DESK_TOP_Y + 0.02, DESK_D * 0.5 - 0.14)
	kb.rotation = Vector3(0.0, deg_to_rad(-6.0), 0.0)
	add_child(kb)

	# A faint grid of key bumps suggested with a few small boxes
	var key_mat := StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.18, 0.18, 0.2)
	key_mat.roughness = 0.6
	for r in 2:
		for c in 6:
			var key := MeshInstance3D.new()
			key.name = "Key_%d_%d" % [r, c]
			var keym := BoxMesh.new()
			keym.size = Vector3(0.045, 0.012, 0.04)
			key.mesh = keym
			key.material_override = key_mat
			var kx: float = 0.18 - 0.13 + float(c) * 0.052
			var kz: float = DESK_D * 0.5 - 0.18 + float(r) * 0.05
			key.position = Vector3(kx, DESK_TOP_Y + 0.035, kz)
			add_child(key)


# ── Small glowing device ──────────────────────────────────────────────

func _build_device() -> void:
	var body := MeshInstance3D.new()
	body.name = "Device"
	var dm := BoxMesh.new()
	dm.size = Vector3(0.12, 0.06, 0.1)
	body.mesh = dm
	body.material_override = _dark_mat
	var dev_x: float = DESK_W * 0.5 - 0.16
	var dev_y: float = DESK_TOP_Y + 0.03
	var dev_z: float = -0.05
	body.position = Vector3(dev_x, dev_y, dev_z)
	add_child(body)

	# Emissive readout on top of the device using its own little texture
	var readout := MeshInstance3D.new()
	readout.name = "DeviceReadout"
	var rm := QuadMesh.new()
	rm.size = Vector2(0.09, 0.05)
	readout.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_texture = _make_device_texture()
	rmat.emission_enabled = true
	rmat.emission_texture = rmat.albedo_texture
	rmat.emission_energy_multiplier = _glow_energy() * 1.1
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	readout.material_override = rmat
	readout.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	readout.position = Vector3(dev_x, dev_y + 0.031, dev_z)
	add_child(readout)


# ── Vertical clamp-pole + collar rings (sized to span the screens) ─────

func _build_pole() -> void:
	# Pole reaches at least POLE_MIN_TOP_Y, or above the highest pole-mounted screen.
	var top_y: float = POLE_MIN_TOP_Y
	for s in screens:
		if str(s.get("mount", "pole")) != "base":
			var sy: float = _to_vec3(s.get("pos", null), Vector3.ZERO).y
			var half_h: float = _to_vec2(s.get("size", null), Vector2(0.45, 0.3)).y * 0.5
			top_y = maxf(top_y, sy + half_h + 0.1)

	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var cm := CylinderMesh.new()
	var pole_len: float = top_y - DESK_TOP_Y
	cm.top_radius = POLE_RADIUS
	cm.bottom_radius = POLE_RADIUS
	cm.height = pole_len
	pole.mesh = cm
	pole.material_override = _metal_mat
	pole.position = Vector3(POLE_X, DESK_TOP_Y + pole_len * 0.5, POLE_Z)
	add_child(pole)

	# Collar / clamp rings — one near each pole-mounted screen height, spread along pole.
	var collar_ys: Array = []
	for s in screens:
		if str(s.get("mount", "pole")) != "base":
			collar_ys.append(_to_vec3(s.get("pos", null), Vector3.ZERO).y)
	if collar_ys.is_empty():
		collar_ys = [DESK_TOP_Y + pole_len * 0.4, DESK_TOP_Y + pole_len * 0.8]

	for i in collar_ys.size():
		var collar := MeshInstance3D.new()
		collar.name = "Collar_%d" % i
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = POLE_RADIUS * 2.0
		cmesh.bottom_radius = POLE_RADIUS * 2.0
		cmesh.height = 0.05
		collar.mesh = cmesh
		var collar_mat := StandardMaterial3D.new()
		collar_mat.albedo_color = Color(0.3, 0.31, 0.34)
		collar_mat.metallic = 0.9
		collar_mat.roughness = 0.3
		collar.material_override = collar_mat
		collar.position = Vector3(POLE_X, float(collar_ys[i]), POLE_Z)
		add_child(collar)


# ── Screens: one configurable panel per `screens` entry ────────────────

func _build_screens() -> void:
	for i in screens.size():
		var raw = screens[i]
		if not (raw is Dictionary):
			continue
		# Coerce again at build time so inspector-authored entries (which may carry
		# Arrays) are normalised too. Idempotent for already-typed dicts.
		var s: Dictionary = _coerce_screen(raw)
		_build_one_screen(i, s)


func _build_one_screen(index: int, s: Dictionary) -> void:
	var size: Vector2 = s["size"]
	var pos: Vector3 = s["pos"]
	var yaw_deg: float = s["angle_deg"]
	var pitch_deg: float = s["pitch_deg"]
	var accent: Color = s["color"]
	var stype: String = s["type"]
	var mount: String = s["mount"]

	var root := Node3D.new()
	root.name = "Screen_%d" % index
	# Anchor a base-mounted panel relative to the desk top if its y is near zero.
	root.position = pos
	root.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)
	add_child(root)

	# Backing panel: thin box + slightly larger bezel behind it.
	var bezel := MeshInstance3D.new()
	bezel.name = "Bezel"
	var bzm := BoxMesh.new()
	bzm.size = Vector3(size.x + 0.05, size.y + 0.05, 0.035)
	bezel.mesh = bzm
	bezel.material_override = _dark_mat
	bezel.position = Vector3(0.0, 0.0, -0.012)
	root.add_child(bezel)

	var back := MeshInstance3D.new()
	back.name = "Backing"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x + 0.02, size.y + 0.02, 0.02)
	back.mesh = bm
	back.material_override = _make_panel_back_mat(accent, stype)
	root.add_child(back)

	# Content face by type.
	if stype == "poster":
		_build_face_textured(root, size, _make_poster_texture(accent, s["title"]))
	elif stype == "data":
		_build_face_textured(root, size, _make_data_texture(accent))
	else:
		_build_face_info(root, size, s["title"], s["body"], accent)

	# Mount hardware: clamp arm to the pole, or a stand neck to the base.
	if mount == "base":
		_build_stand_neck(root, size)
	else:
		_build_clamp_arm(root, pos)


func _build_face_info(root: Node3D, size: Vector2, title: String, body: String, accent: Color) -> void:
	# Emissive backing colour (the info-board glow) PLUS real readable Label3D text.
	var face := MeshInstance3D.new()
	face.name = "Face"
	var qm := QuadMesh.new()
	qm.size = size
	face.mesh = qm
	# Dark, slightly accent-tinted backing so light text reads on it.
	var bg: Color = Color(0.04, 0.05, 0.07).lerp(accent, 0.18)
	face.material_override = _make_emissive_color_mat(bg, _glow_energy() * 0.5)
	face.position = Vector3(0.0, 0.0, 0.013)
	root.add_child(face)

	# Text sits just in front of the panel face; billboard OFF so it stays planar.
	var text_root := Node3D.new()
	text_root.name = "Text"
	text_root.position = Vector3(0.0, 0.0, 0.018)
	root.add_child(text_root)

	# Body lines from "\n"-separated body string.
	var lines: PackedStringArray = body.split("\n", false)
	var has_title: bool = title.strip_edges() != ""

	# Font sizing scaled to panel height so text fits varied sizes.
	var title_font: int = maxi(9, int(round(size.y * 150.0)))
	var body_font: int = maxi(7, int(round(size.y * 78.0)))
	var title_step: float = float(title_font) * TEXT_PIXEL_SIZE * 1.5
	var body_step: float = float(body_font) * TEXT_PIXEL_SIZE * 1.45

	var total_h: float = 0.0
	if has_title:
		total_h += title_step
	total_h += body_step * float(lines.size())
	var cursor_y: float = total_h * 0.5

	# Title accent: bright accent; body: soft near-white tinted by accent.
	var title_col: Color = accent.lerp(Color(1, 1, 1), 0.25)
	var body_col: Color = Color(0.92, 0.95, 0.98).lerp(accent, 0.15)

	if has_title:
		var head := Label3D.new()
		head.name = "Title"
		head.text = title
		head.font_size = title_font
		head.outline_size = 2
		head.pixel_size = TEXT_PIXEL_SIZE
		head.modulate = title_col
		head.outline_modulate = Color(0, 0, 0, 0.9)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		head.no_depth_test = true
		head.width = int(maxf(120.0, size.x / TEXT_PIXEL_SIZE))
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head.position = Vector3(0.0, cursor_y - title_step * 0.5, 0.0)
		text_root.add_child(head)
		cursor_y -= title_step

	for i in lines.size():
		var line := Label3D.new()
		line.name = "Body%d" % i
		line.text = str(lines[i])
		line.font_size = body_font
		line.outline_size = 1
		line.pixel_size = TEXT_PIXEL_SIZE
		line.modulate = body_col
		line.outline_modulate = Color(0, 0, 0, 0.9)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		line.no_depth_test = true
		line.width = int(maxf(120.0, size.x / TEXT_PIXEL_SIZE))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.position = Vector3(0.0, cursor_y - body_step * 0.5, 0.0)
		text_root.add_child(line)
		cursor_y -= body_step


func _build_face_textured(root: Node3D, size: Vector2, tex: ImageTexture) -> void:
	var face := MeshInstance3D.new()
	face.name = "Face"
	var qm := QuadMesh.new()
	qm.size = size
	face.mesh = qm
	face.material_override = _make_screen_material(tex)
	face.position = Vector3(0.0, 0.0, 0.013)
	root.add_child(face)


func _build_clamp_arm(root: Node3D, pos: Vector3) -> void:
	# Short arm reaching back toward the pole line (so it reads as clamped to the pole).
	var arm := MeshInstance3D.new()
	arm.name = "ClampArm"
	var am := BoxMesh.new()
	am.size = Vector3(0.025, 0.025, 0.18)
	arm.mesh = am
	arm.material_override = _metal_mat
	arm.position = Vector3(0.0, 0.0, -0.1)
	root.add_child(arm)


func _build_stand_neck(root: Node3D, size: Vector2) -> void:
	var neck := MeshInstance3D.new()
	neck.name = "MonitorNeck"
	var nm := BoxMesh.new()
	nm.size = Vector3(0.04, 0.18, 0.03)
	neck.mesh = nm
	neck.material_override = _metal_mat
	neck.position = Vector3(0.0, -size.y * 0.5 - 0.09, -0.02)
	root.add_child(neck)


# ── Cables: draping tubes spanning the screens to the base ─────────────

func _build_cables() -> void:
	# One cable from each of the first few pole-mounted screens down to the base,
	# so the drape spans the configured board rather than fixed positions.
	var anchored: int = 0
	for i in screens.size():
		if anchored >= 3:
			break
		var raw = screens[i]
		if not (raw is Dictionary):
			continue
		var mount: String = str(raw.get("mount", "pole")).strip_edges().to_lower()
		if mount == "base":
			continue
		var p: Vector3 = _to_vec3(raw.get("pos", null), Vector3(0.0, 1.5, 0.0))
		# Drape from the screen's lower-back toward the tower / desk surface.
		var from_pt: Vector3 = Vector3(p.x * 0.5, p.y - 0.05, -0.04)
		var target_x: float = -0.45
		if anchored % 2 == 1:
			target_x = 0.45
		var to_pt: Vector3 = Vector3(target_x, DESK_TOP_Y + 0.04, 0.0)
		var radius: float = 0.016
		if anchored == 1:
			radius = 0.013
		_add_cable(from_pt, to_pt, radius)
		anchored += 1

	# Always leave one cable draping to the base if nothing was anchored above.
	if anchored == 0:
		_add_cable(Vector3(-0.08, 1.5, -0.02), Vector3(-0.45, DESK_TOP_Y + 0.05, 0.05), 0.016)


func _add_cable(p_from: Vector3, p_to: Vector3, radius: float) -> void:
	# Draping cable approximated as a chain of short cylinder segments along a
	# sagging arc (a simple downward-bowed quadratic between the two endpoints).
	var root := Node3D.new()
	root.name = "Cable"
	add_child(root)

	var segments: int = 8
	var sag: float = 0.18
	var prev: Vector3 = p_from
	for i in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = p_from.lerp(p_to, t)
		# Parabolic sag: max at t=0.5, zero at the ends
		point.y -= sag * (4.0 * t * (1.0 - t))
		_add_cable_segment(root, prev, point, radius)
		prev = point


func _add_cable_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
	var seg := MeshInstance3D.new()
	seg.name = "Seg"
	var mid: Vector3 = (a + b) * 0.5
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.0001:
		return
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	seg.mesh = cm
	seg.material_override = _cable_mat
	seg.position = mid
	# Orient the cylinder (default +Y axis) along dir
	var up := Vector3(0.0, 1.0, 0.0)
	var ndir: Vector3 = dir.normalized()
	var dot: float = up.dot(ndir)
	if dot < -0.9999:
		seg.rotation = Vector3(PI, 0.0, 0.0)
	elif dot < 0.9999:
		var axis: Vector3 = up.cross(ndir).normalized()
		var angle: float = acos(clampf(dot, -1.0, 1.0))
		seg.transform.basis = Basis(axis, angle)
	parent.add_child(seg)


# ── Material helpers ──────────────────────────────────────────────────

func _glow_energy() -> float:
	if screen_glow:
		return screen_emission
	return 0.0


func _make_emissive_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.6
	return mat


func _make_emissive_color_mat(color: Color, energy: float) -> StandardMaterial3D:
	# Flat emissive colour (no texture) for info-panel backings.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _make_panel_back_mat(accent: Color, stype: String) -> StandardMaterial3D:
	# Thin backing box tinted by the panel accent so the rig carries colour even from behind.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.08).lerp(accent, 0.2)
	mat.metallic = 0.3
	mat.roughness = 0.6
	return mat


func _make_screen_material(tex: ImageTexture) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = _glow_energy()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


# ── Procedural screen textures ────────────────────────────────────────
# Drawing helpers operate on an Image. Faux text = small filled bars.

func _new_image(bg: Color) -> Image:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	return img


func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var x0: int = clampi(x, 0, TEX_W)
	var y0: int = clampi(y, 0, TEX_H)
	var x1: int = clampi(x + w, 0, TEX_W)
	var y1: int = clampi(y + h, 0, TEX_H)
	for py in range(y0, y1):
		for px in range(x0, x1):
			img.set_pixel(px, py, color)


# A row of short bars to read as a line of text.
func _text_bars(img: Image, x: int, y: int, count: int, bar_w: int, bar_h: int, gap: int, color: Color) -> void:
	for i in count:
		var bx: int = x + i * (bar_w + gap)
		# Vary bar width a touch so it reads as words, not a comb
		var w: int = bar_w
		if i % 3 == 0:
			w = bar_w + 2
		if i % 5 == 4:
			w = maxi(2, bar_w - 2)
		_fill_rect(img, bx, y, w, bar_h, color)


func _radial_burst(img: Image, cx: int, cy: int, inner: Color, outer: Color) -> void:
	var max_d: float = sqrt(float(TEX_W * TEX_W + TEX_H * TEX_H)) * 0.5
	for py in TEX_H:
		for px in TEX_W:
			var dx: float = float(px - cx)
			var dy: float = float(py - cy)
			var d: float = sqrt(dx * dx + dy * dy) / max_d
			var t: float = clampf(d, 0.0, 1.0)
			img.set_pixel(px, py, inner.lerp(outer, t))


# ── "poster" type — the old neon-poster look, now accent-tinted ────────
# Reproduces the original SECURITY-BREACH style poster (radial burst + hooded
# blob + warning bars), themed by the panel's accent colour so any poster screen
# keeps that cool cyberpunk look.
func _make_poster_texture(accent: Color, _title: String) -> ImageTexture:
	var deep: Color = accent.darkened(0.7)
	var img := _new_image(deep)
	var hot: Color = accent.lerp(Color(1, 1, 1), 0.25)
	_radial_burst(img, TEX_W / 2, TEX_H / 2 + 10, hot, deep)
	var dark := Color(0.02, 0.0, 0.02)
	# Hooded figure: hood arc (block) + body
	_fill_rect(img, 100, 44, 56, 44, dark)       # hood top
	_fill_rect(img, 92, 80, 72, 64, dark)        # cloak body
	# Dark face void inside hood
	_fill_rect(img, 114, 60, 28, 24, Color(0.0, 0.0, 0.0))
	# Warning bar across the top
	_fill_rect(img, 0, 6, TEX_W, 22, Color(0.0, 0.0, 0.0, 0.85))
	_text_bars(img, 14, 11, 14, 11, 12, 3, hot)
	# Bottom scan bar
	_fill_rect(img, 0, TEX_H - 14, TEX_W, 10, Color(0.0, 0.0, 0.0, 0.7))
	_text_bars(img, 12, TEX_H - 12, 12, 10, 6, 4, hot)
	return ImageTexture.create_from_image(img)


# ── "data" type — procedural graph/readout (bars + baseline) ───────────
func _make_data_texture(accent: Color) -> ImageTexture:
	var img := _new_image(Color(0.02, 0.04, 0.06))
	var line: Color = accent.lerp(Color(1, 1, 1), 0.2)
	# Baseline
	_fill_rect(img, 8, TEX_H - 40, TEX_W - 16, 2, line * 0.5)
	# A jagged "signal" as a row of vertical bars of varied height
	var heights := [30, 70, 45, 90, 55, 110, 60, 80, 40, 95, 50, 75]
	for i in heights.size():
		var bx: int = 14 + i * 19
		var bh: int = int(heights[i])
		_fill_rect(img, bx, TEX_H - 40 - bh, 10, bh, line)
	# A few horizontal gridlines for a readout feel
	for g in 3:
		var gy: int = 30 + g * 30
		_fill_rect(img, 8, gy, TEX_W - 16, 1, line * 0.3)
	# Status text bars top
	_text_bars(img, 12, 14, 8, 12, 9, 5, line)
	return ImageTexture.create_from_image(img)


# (small device readout — tiny graph + status bars, kept for the desk device)
func _make_device_texture() -> ImageTexture:
	var img := _new_image(Color(0.02, 0.04, 0.06))
	var green := Color(0.2, 1.0, 0.5)
	# Baseline
	_fill_rect(img, 8, TEX_H - 40, TEX_W - 16, 2, green * 0.5)
	# A jagged "signal" as a row of vertical bars of varied height
	var heights := [30, 70, 45, 90, 55, 110, 60, 80, 40, 95, 50, 75]
	for i in heights.size():
		var bx: int = 14 + i * 19
		var bh: int = int(heights[i])
		_fill_rect(img, bx, TEX_H - 40 - bh, 10, bh, green)
	# Status text bars top
	_text_bars(img, 12, 14, 8, 12, 9, 5, green)
	return ImageTexture.create_from_image(img)
