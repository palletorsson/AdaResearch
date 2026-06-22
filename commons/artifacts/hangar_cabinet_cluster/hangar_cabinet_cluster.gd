extends Node3D
class_name HangarCabinetCluster

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: a bank of mixed-height utility/server cabinets standing shoulder to shoulder — the equipment wall of a maintenance bay, in the Dieter Rams / Braun key. Light matte off-white boxes with inset trim panels, slatted vents, a calm anthracite status screen, a three-colour accent bar across the row and a stencilled unit ID; restrained dust at the foot, not heavy rust. Origin at the floor; the row's bottom sits at y=0.
# desire: to fill the edge of a room with infrastructure — to read as "this place is run by machines that hum behind these doors", and to give a wall presence and depth without being a single flat panel.
# critical_parameter: unit_count — how much of the wall this bank claims. 2 = a small equipment nook; 4 = a long server bank. Each unit is its own cabinet with its own height, colour, vents and (maybe) screen.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new count/footprint/style.
# emerges: mixed heights + vents read "live equipment"; a lit readout reads "powered, monitored"; uniform clean boxes read "dormant storage"; stencilled U1..Un read "indexed, maintained".
# needs: unit_count cabinet bodies in a row [present]; inset front panel per unit [present]; vent slats on some [optional]; small framed readout on ~1-in-2 [optional]; stencilled unit ID [present]; base lip / feet [present]
# relationships: the wall-filling sibling of [[hangar_podium]] (stand a thing ON that, line the room with these), shares the framed screen of [[artifact_readout_screen]], and the maintenance-bay set of [[hangar_wall_panel]]. The packaging a room asks for when it needs a back wall of infrastructure.
# truth: a wall of equal boxes is scenery; a wall of unequal boxes — one taller, one vented, one lit — is a place that has been worked in.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Cluster")
## How many cabinets stand side by side — THE size decision. 2 = nook, 4 = server bank.
@export var unit_count: int = 3
## Per-unit width along X (metres).
@export var unit_width: float = 0.6
## Cabinet depth along Z (metres).
@export var depth: float = 0.6

@export_group("Height")
## Nominal cabinet height — units vary around this.
@export var base_height: float = 1.6
## Max +/- height swing applied per-unit by a FIXED pattern (deterministic, capture-stable).
@export var height_variation: float = 0.3

@export_group("Detail")
## Some units get a small framed readout (status screen) on the front upper area.
@export var with_screens: bool = true
## Slatted vent panels — a few thin horizontal boxes on some units.
@export var vents: bool = true

@export_group("Style")
## "cool" | "warm" | "mixed" — controls the per-cabinet base tint (all light Braun tints now).
@export var palette: String = "mixed"
## Weathering 0..1 — subtle dust by default (Rams clean), not heavy grime.
@export var wear: float = 0.08

@export_group("Color")
## Dieter Rams / Braun default — light matte trim so the housing recedes.
@export var panel_color: Color = Color(0.70, 0.68, 0.64)   # PANEL_TRIM
## Calm anthracite readout text (Braun "no glow") — warm off-white on the dark screen.
@export var screen_accent: Color = Color(0.90, 0.89, 0.85)  # TEXT_DISPLAY

@export_group("Surface")
## Three-colour Rams accent bar across the front of the bank, proud of the face.
@export var three_bar: bool = true
## Faint dust band at the foot of the row + a few subtle streaks on a couple of faces.
@export var grime: bool = true

# ── Constants ─────────────────────────────────────────────────────────
const GAP := 0.012            # hairline gap between cabinets
const PANEL_INSET := 0.02     # how far the front panel sits proud
const FOOT_H := 0.05          # base lip / feet height
const FOOT_INSET := 0.06      # feet pulled in from the body edge

# Cabinet base palettes — now LIGHT Braun tints (off-white body / light grey trim),
# not dark metal. "cool" leans toward PANEL_TRIM grey, "warm" toward BODY_LIGHT. Wraps per-unit.
const COOL := [Color(0.78, 0.78, 0.77), Color(0.72, 0.71, 0.69), Color(0.80, 0.80, 0.78)]
const WARM := [Color(0.83, 0.80, 0.75), Color(0.81, 0.79, 0.75), Color(0.85, 0.82, 0.76)]

var _built := false

# ── Lifecycle ─────────────────────────────────────────────────────────
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
	if has_meta("config_unit_count"): unit_count = int(float(str(get_meta("config_unit_count"))))
	if has_meta("config_unit_width"): unit_width = float(str(get_meta("config_unit_width")))
	if has_meta("config_depth"): depth = float(str(get_meta("config_depth")))
	if has_meta("config_base_height"): base_height = float(str(get_meta("config_base_height")))
	if has_meta("config_height_variation"): height_variation = float(str(get_meta("config_height_variation")))
	if has_meta("config_with_screens"): with_screens = str(get_meta("config_with_screens")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_vents"): vents = str(get_meta("config_vents")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_palette"): palette = str(get_meta("config_palette")).to_lower()
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_screen_accent"): screen_accent = _pc(str(get_meta("config_screen_accent")), screen_accent)
	if has_meta("config_three_bar"): three_bar = str(get_meta("config_three_bar")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_grime"): grime = str(get_meta("config_grime")).to_lower() in ["true", "1", "yes", "on"]


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var n: int = clampi(unit_count, 1, 8)
	var uw: float = maxf(unit_width, 0.2)
	var dz: float = maxf(depth, 0.2)
	var pitch: float = uw + GAP
	var total_w: float = pitch * float(n) - GAP
	var x0: float = -total_w * 0.5 + uw * 0.5   # centre of the first (leftmost) cabinet

	for i in range(n):
		var cx: float = x0 + pitch * float(i)
		_build_cabinet(i, cx, uw, dz)

	# A single Dieter-Rams three-colour accent bar across the front of the whole bank,
	# proud of the +Z face — the one composed accent the row gets.
	if three_bar:
		_build_bank_three_bar(total_w, dz)

	# Restrained dirt: a faint dust band along the foot of the row + a few subtle streaks
	# on a couple of the cabinet faces (deterministic, barely there).
	if grime:
		_build_bank_grime(n, total_w, x0, pitch, uw, dz)


# One cabinet: body + inset front panel + optional vents + optional readout + stencil ID + feet.
func _build_cabinet(i: int, cx: float, uw: float, dz: float) -> void:
	var h: float = maxf(base_height + _height_offset(i), 0.4)
	var body_mat := _mat(_cabinet_color(i), 0.55, 0.4)

	# Body box — sits on the floor, grows +Y.
	add_child(_box(Vector3(cx, h * 0.5, 0), Vector3(uw, h, dz), body_mat))

	# Inset front panel (slightly proud, on +Z face).
	var pmat := _mat(panel_color, 0.65, 0.25)
	var pw: float = uw * 0.78
	var ph: float = h * 0.82
	var pcy: float = h * 0.5
	add_child(_box(Vector3(cx, pcy, dz * 0.5 + PANEL_INSET * 0.5), Vector3(pw, ph, PANEL_INSET), pmat))

	# Vent slats — a few thin horizontal boxes on the lower panel of some units.
	if vents and (i % 2 == 0):
		_build_vents(cx, dz, pw, h)

	# Small framed readout on ~1-in-2 units, on the upper front area.
	if with_screens and (i % 2 == 1):
		_build_readout(i, cx, dz, uw, h)

	# Stencilled unit ID ("U1","U2",...) low on the front face.
	_build_stencil_id(i, cx, dz, uw, h)

	# Short base lip + small feet.
	_build_feet(cx, uw, dz, body_mat)


# Slatted vent panel: thin horizontal bars on the lower-middle of the front panel.
func _build_vents(cx: float, dz: float, pw: float, h: float) -> void:
	var vmat := _mat(panel_color.darkened(0.35), 0.6, 0.45)
	var slats := 4
	var band_lo: float = h * 0.20
	var band_hi: float = h * 0.42
	var vw: float = pw * 0.72
	for s in range(slats):
		var t: float = float(s) / float(slats - 1)
		var vy: float = lerpf(band_lo, band_hi, t)
		add_child(_box(Vector3(cx, vy, dz * 0.5 + PANEL_INSET + 0.006), Vector3(vw, 0.022, 0.012), vmat))


# A small self-lit framed status screen on the upper front area.
func _build_readout(i: int, cx: float, dz: float, uw: float, h: float) -> void:
	var headers := ["PWR", "TEMP", "I/O", "SYNC"]
	var bodies := [["PWR 30%"], ["TEMP OK"], ["LINK OK"], ["SYNC 12"]]
	var k: int = i % headers.size()
	var sw: float = minf(uw * 0.5, 0.26)
	var sh: float = sw * 0.62
	# Calm anthracite screen + warm off-white text (HangarKit.readout DISPLAY_DARK default,
	# Braun "no glow"); screen_accent supplies the text colour (defaults to TEXT_DISPLAY).
	var rd: Node3D = HangarKit.readout(headers[k], bodies[k], Vector2(sw, sh),
		HangarKit.DISPLAY_DARK, screen_accent)
	if rd:
		rd.position = Vector3(cx, h * 0.74, dz * 0.5 + PANEL_INSET + 0.03)
		add_child(rd)


# Stencilled unit ID painted low on the front face (U1, U2, ...).
func _build_stencil_id(i: int, cx: float, dz: float, uw: float, h: float) -> void:
	var label: String = "U%d" % (i + 1)
	var q: MeshInstance3D = HangarKit.stencil(label, Vector2(uw * 0.34, h * 0.1))
	if q:
		q.position = Vector3(cx, h * 0.1, dz * 0.5 + PANEL_INSET + 0.012)
		add_child(q)


# Short base lip across the whole cabinet + two small feet.
func _build_feet(cx: float, uw: float, dz: float, body_mat: Material) -> void:
	var fmat := _mat(panel_color.darkened(0.2), 0.5, 0.5)
	# Base lip — a slightly inset band sitting on the floor.
	add_child(_box(Vector3(cx, FOOT_H * 0.5, 0), Vector3(uw * 0.94, FOOT_H, dz * 0.94), fmat))
	# Two small feet at the front corners (cosmetic, also floor-anchored).
	var fw: float = uw * 0.12
	var fx: float = uw * 0.5 - FOOT_INSET
	for sx in [-1.0, 1.0]:
		add_child(_box(Vector3(cx + sx * fx, FOOT_H * 0.4, dz * 0.5 - FOOT_INSET), Vector3(fw, FOOT_H * 0.8, fw), fmat))


# One Dieter-Rams three-colour accent bar across the front of the whole bank, low on the
# row and proud of the +Z face — the row's single composed accent (BRAUN_ACCENT / anthracite / trim).
func _build_bank_three_bar(total_w: float, dz: float) -> void:
	var bar: Node3D = HangarKit.three_color_bar(total_w * 0.9, 0.05,
		[HangarKit.BRAUN_ACCENT, HangarKit.DISPLAY_DARK, panel_color])
	bar.position = Vector3(0, FOOT_H + 0.10, dz * 0.5 + PANEL_INSET + 0.02)
	add_child(bar)


# Restrained dirt across the bank: a faint dust band along the foot of the row, plus a few
# subtle vertical streaks on a couple of cabinet faces. Deterministic, low-alpha — barely there.
func _build_bank_grime(n: int, total_w: float, x0: float, pitch: float, uw: float, dz: float) -> void:
	# Dust band hugging the floor along the whole row.
	add_child(HangarKit.grime_band(total_w, 0.06, dz * 0.5 + PANEL_INSET + 0.004, panel_color))
	# Streaks on just a couple of faces (units 1 and, if present, the last one).
	var faces: Array = [1]
	if n >= 4:
		faces.append(n - 1)
	for i in faces:
		if i < 0 or i >= n:
			continue
		var cx: float = x0 + pitch * float(i)
		var h: float = maxf(base_height + _height_offset(i), 0.4)
		var streaks := HangarKit.dust_streaks(uw * 0.7, h * 0.7, dz * 0.5 + PANEL_INSET + 0.014, 4)
		streaks.position = Vector3(cx, h * 0.5, 0)
		add_child(streaks)


# ── Per-index deterministic variation (no randf — captures stay stable) ──
# A fixed sawtooth-ish pattern so neighbouring cabinets differ in height.
func _height_offset(i: int) -> float:
	var pattern := [0.0, 1.0, -0.6, 0.4, -1.0, 0.7]
	return pattern[i % pattern.size()] * height_variation


# Per-unit base colour from the chosen palette (deterministic, wraps).
func _cabinet_color(i: int) -> Color:
	match palette:
		"cool":
			return COOL[i % COOL.size()]
		"warm":
			return WARM[i % WARM.size()]
		_:
			# "mixed": alternate cool / warm, stepping through each set.
			if i % 2 == 0:
				return COOL[(i / 2) % COOL.size()]
			return WARM[(i / 2) % WARM.size()]


# ── Local helpers (delegate to the shared HangarKit for the family look) ──
# Light matte Braun finish — the cabinet housing recedes. (rough/metal ignored: Rams is matte.)
func _mat(c: Color, _rough: float, _metal: float) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
