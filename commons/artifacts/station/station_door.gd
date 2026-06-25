extends Node3D
class_name StationDoor

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedTextAlbedo := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the CLOSEABLE LEAF the station kit never had — a Dieter-Rams / ARC-Raiders painted-metal sliding door that drops INSIDE a [[station_frame]] aperture and seals it. A header track runs over the top, one or two panelled leaves hang from it and part along X, an accent stripe crosses each leaf at chest height, a vision slit can cut through it, and a caution-striped threshold + a downlit sill band print the floor line. Origin at the floor centre of the aperture, leaf facing +Z; 1 cell = 1 m. open_amount 0=sealed..1=fully retracted into the jambs.
# desire: to give the station family a way to CLOSE — to turn station_frame's honest "door you do not close" into a door you can. To make a threshold readable as boundary / invitation / corridor from a single scalar, in the SAME light matte body + one warm accent as the rest of the kit, so a sealed bay still looks like the bay.
# critical_parameter: open_amount × leaf_mode — how far the leaf has slid (0 sealed → 1 stowed) and whether it is one slab sliding aside (single) or two halves parting from the centreline (bi_parting). width × height set it to the host frame's clear aperture so it nests, not overhangs.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new size / open_amount / mode (drive it from grid events to seal or open a bay).
# emerges: closed = wall, the bay is sealed; mid-slide = invitation, a gap of light; fully open = corridor, leaves stowed in the jambs; a lit vision slit reads "occupied / look through"; the caution threshold + sill glow read "automatic door, mind the gap, this is plant".
# needs: a header track + end caps over the aperture [present]; one or two panelled leaves positioned by open_amount [present]; a chest-height accent stripe per leaf, both faces [present]; an optional vision slit [optional]; an optional lit threshold band on the floor [optional]; bolts + a Rams three-colour bar + a wear pass [present].
# relationships: SEALS the aperture of [[station_frame]] (sized to its clear span — the leaf is the door the frame deliberately omits); the light-Rams cousin of the dark Portal-palette [[sliding_door]] (same open/close idea, this family's paint); a moving sibling to the static [[station_wall]] (a wall that parts); placed by [[curation_station]] across a bay mouth; shares the HangarKit weathered painted-metal family look.
# truth: a frame is a claim made by absence; a door is the claim taken back. The same opening becomes wall, invitation, or corridor depending on one number — and the most honest seal is one that still shows the seam it closes on.

@export_group("Dimensions")
## Clear leaf width (X) in metres — set to the host frame's clear aperture (frame_width - post). Default nests station_frame's 2.0-wide / 0.16-post opening.
@export var width: float = 1.84
## Clear leaf height (Y) in metres — floor to under the header. Default nests station_frame's 2.2 opening.
@export var height: float = 2.12
## Leaf thickness (Z).
@export var leaf_depth: float = 0.07

@export_group("Behavior")
## 0 = sealed (leaves meet / slab covers the aperture), 1 = fully open (leaves stowed in the jambs).
@export_range(0.0, 1.0) var open_amount: float = 0.0
## "single" (one slab slides aside to -X) | "bi_parting" (two halves part from the centreline).
@export var leaf_mode: String = "bi_parting"
## Visible seam between the two leaves / the slab edge when sealed.
@export var seam_gap: float = 0.03

@export_group("Header")
## A header track box spanning the top, that the leaves hang from.
@export var with_header: bool = true
## Header track vertical thickness (m).
@export var header_depth: float = 0.18

@export_group("Fittings")
## A horizontal vision slit cut across the leaf at eye height (a lit window strip).
@export var with_window: bool = true
## A caution-striped + downlit threshold band printed on the floor across the sill.
@export var with_threshold_light: bool = true
## Recessed panel cells routed into each leaf face (the panelled-door read).
@export var panel_cells: int = 2
## Bolt rows on the header end caps + leaf rails.
@export var bolts: bool = true
## A Dieter-Rams three-colour accent bar on the header front.
@export var three_bar: bool = true

@export_group("Surface")
## A chest-height emissive accent stripe across each leaf (both faces).
@export var accent_stripe: bool = true
@export var stencil_text: String = ""
@export var wear: float = 0.10
@export var grime: bool = true
## "rams" (light Braun default) | "terminal" (dark charcoal console finish).
@export var finish: String = "rams"

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const ACCENT_HEIGHT_FRAC := 0.56   # chest-height fraction of leaf
const WINDOW_HEIGHT_FRAC := 0.72   # eye-height fraction of leaf

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
	if has_meta("config_leaf_depth"): leaf_depth = float(str(get_meta("config_leaf_depth")))
	if has_meta("config_open_amount"): open_amount = clampf(float(str(get_meta("config_open_amount"))), 0.0, 1.0)
	if has_meta("config_leaf_mode"): leaf_mode = str(get_meta("config_leaf_mode")).to_lower()
	if has_meta("config_seam_gap"): seam_gap = float(str(get_meta("config_seam_gap")))
	if has_meta("config_with_header"): with_header = _b(get_meta("config_with_header"))
	if has_meta("config_header_depth"): header_depth = float(str(get_meta("config_header_depth")))
	if has_meta("config_with_window"): with_window = _b(get_meta("config_with_window"))
	if has_meta("config_with_threshold_light"): with_threshold_light = _b(get_meta("config_with_threshold_light"))
	if has_meta("config_panel_cells"): panel_cells = int(str(get_meta("config_panel_cells")))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_accent_stripe"): accent_stripe = _b(get_meta("config_accent_stripe"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var w: float = maxf(width, 0.5)
	var h: float = maxf(height, 0.8)
	var ld: float = clampf(leaf_depth, 0.03, 0.3)
	var gap: float = clampf(seam_gap, 0.0, 0.2)
	var bi: bool = leaf_mode != "single"

	# Finish drives the family palette; explicit colours still win if set away from default.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else pal["body"]
	var pcol: Color = panel_color if not is_terminal else pal["panel"]
	var acol: Color = accent_color if not is_terminal else pal["accent"]
	var ewear: float = maxf(wear, float(pal.get("wear", wear)))

	var body_mat := _mat(bcol, ewear)
	var rail_mat := HangarKit.worn_metal(pcol)

	# ── Header track over the aperture ──
	if with_header:
		var hd: float = clampf(header_depth, 0.06, 0.4)
		var header_y: float = h + hd * 0.5
		var header_w: float = w + 0.12
		add_child(_box(Vector3(0, header_y, 0), Vector3(header_w, hd, ld + 0.10), body_mat))
		# A darker recessed channel under the header (the track the leaves ride).
		add_child(_box(Vector3(0, h - 0.02, 0), Vector3(header_w, 0.06, ld + 0.04), rail_mat))
		# End caps + bolts at each jamb where the leaves stow.
		for sx in [-1.0, 1.0]:
			add_child(_box(Vector3(sx * (header_w * 0.5 + 0.03), header_y, 0), Vector3(0.10, hd * 1.06, ld + 0.14), rail_mat))
			if bolts:
				add_child(HangarKit.bolts(
					Vector3(sx * (header_w * 0.5 + 0.03), header_y + hd * 0.22, ld * 0.5 + 0.09),
					Vector3(sx * (header_w * 0.5 + 0.03), header_y - hd * 0.22, ld * 0.5 + 0.09),
					2, 0.016, rail_mat))
		# Rams three-colour accent bar on the header front.
		if three_bar:
			var bar: Node3D = HangarKit.three_color_bar(minf(header_w * 0.5, 1.0), 0.034, [acol, HangarKit.DISPLAY_DARK, pcol])
			if bar != null:
				bar.position = Vector3(0, header_y, ld * 0.5 + 0.07)
				add_child(bar)
		# Stencil printed on the header front.
		if stencil_text.strip_edges() != "":
			var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(header_w * 0.5, 0.9), hd * 0.5))
			if q:
				q.position = Vector3(0, header_y, ld * 0.5 + 0.072)
				add_child(q)

	# ── Leaves ──
	# Each leaf travels along X. Closed: inner edges meet (separated by gap). Open: inner
	# edge retracts to the aperture edge (±w/2), stowing the leaf past the jamb.
	if bi:
		var leaf_w: float = (w - gap) * 0.5
		var travel: float = w * 0.5 - gap * 0.5
		var slide: float = travel * open_amount
		var inner: float = leaf_w * 0.5 + gap * 0.5
		_build_leaf(-(inner) - slide, leaf_w, h, ld, bcol, pcol, acol, ewear, true)
		_build_leaf((inner) + slide, leaf_w, h, ld, bcol, pcol, acol, ewear, false)
	else:
		# Single slab covers the whole aperture; slides to -X to open.
		var leaf_w2: float = w
		var travel2: float = w
		var slide2: float = travel2 * open_amount
		_build_leaf(-slide2, leaf_w2, h, ld, bcol, pcol, acol, ewear, true)

	# ── Caution-striped + downlit threshold band on the floor ──
	if with_threshold_light:
		var smat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		add_child(_box(Vector3(0, 0.006, ld * 0.5 + 0.10), Vector3(w + 0.10, 0.012, 0.14), smat))
		add_child(_box(Vector3(0, 0.006, -(ld * 0.5 + 0.10)), Vector3(w + 0.10, 0.012, 0.14), smat))
		# A thin warm downlight strip right under the sill seam.
		add_child(_box(Vector3(0, 0.004, 0), Vector3(w * 0.96, 0.008, 0.05), _emi(acol, 0.9)))


# A single panelled leaf at x: body slab + recessed panel cells + accent stripe (+ optional
# vision slit) + side rail. cx is the X centre of the leaf; lead = the inner (meeting) leaf.
func _build_leaf(cx: float, lw: float, h: float, ld: float, bcol: Color, pcol: Color, acol: Color, ewear: float, lead: bool) -> void:
	var body_mat := _mat(bcol, ewear)
	var cy: float = h * 0.5

	# Body slab.
	add_child(_box(Vector3(cx, cy, 0), Vector3(lw, h, ld), body_mat))

	# A side rail down the leading edge (reads as the meeting stile / the slab edge).
	var rail_mat := HangarKit.worn_metal(pcol.darkened(0.05))
	var edge_sign: float = 1.0 if lead else -1.0
	add_child(_box(Vector3(cx + edge_sign * (lw * 0.5 - 0.03), cy, 0), Vector3(0.06, h * 0.98, ld + 0.012), rail_mat))

	# Recessed panel cells on both faces (the panelled-door read).
	var cells: int = clampi(panel_cells, 0, 5)
	if cells > 0:
		var pmat := _mat(pcol, ewear)
		var t := 0.018
		var win_y: float = h * WINDOW_HEIGHT_FRAC
		var cell_h: float = (h * 0.86) / float(cells)
		for sz in [1.0, -1.0]:
			var pz: float = sz * (ld * 0.5 + t * 0.5)
			for i in range(cells):
				var py: float = h * 0.07 + (float(i) + 0.5) * cell_h
				# skip the cell the window occupies so the slit isn't covered by a panel
				if with_window and absf(py - win_y) < cell_h * 0.5:
					continue
				add_child(_box(Vector3(cx, py, pz), Vector3(lw * 0.74, cell_h * 0.78, t), pmat))

	# Chest-height accent stripe, both faces.
	if accent_stripe:
		var smat := _emi(acol, 1.5)
		var sy: float = h * ACCENT_HEIGHT_FRAC
		for sz in [1.0, -1.0]:
			var s := _box(Vector3(cx, sy, sz * (ld * 0.5 + 0.004)), Vector3(lw * 0.9, 0.014, 0.005), smat)
			s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(s)

	# Vision slit — a lit window strip across the leaf at eye height.
	if with_window:
		var win_y2: float = h * WINDOW_HEIGHT_FRAC
		var win_w: float = lw * 0.66
		var win_h: float = minf(h * 0.13, 0.26)
		# dark recessed glass core, lit from within
		add_child(_box(Vector3(cx, win_y2, 0), Vector3(win_w, win_h, ld * 0.5), _emi(HangarKit.DISPLAY_DARK.lerp(acol, 0.12), 0.5)))
		# a worn-metal bezel ring around it, both faces
		var bez := HangarKit.worn_metal(pcol.darkened(0.1))
		var bt := 0.03
		for sz in [1.0, -1.0]:
			var bz: float = sz * (ld * 0.5 + 0.002)
			add_child(_box(Vector3(cx, win_y2 + win_h * 0.5 + bt * 0.5, bz), Vector3(win_w + bt * 2.0, bt, 0.01), bez))
			add_child(_box(Vector3(cx, win_y2 - win_h * 0.5 - bt * 0.5, bz), Vector3(win_w + bt * 2.0, bt, 0.01), bez))
			add_child(_box(Vector3(cx - win_w * 0.5 - bt * 0.5, win_y2, bz), Vector3(bt, win_h, 0.01), bez))
			add_child(_box(Vector3(cx + win_w * 0.5 + bt * 0.5, win_y2, bz), Vector3(bt, win_h, 0.01), bez))

	# Bolt row low on the leaf face.
	if bolts:
		add_child(HangarKit.bolts(
			Vector3(cx - lw * 0.3, h * 0.16, ld * 0.5 + 0.006),
			Vector3(cx + lw * 0.3, h * 0.16, ld * 0.5 + 0.006),
			3, 0.012, rail_mat))

	# A faint grime band along the base of the leaf.
	if grime:
		var g := HangarKit.grime_band(lw * 0.92, 0.05, ld * 0.5 + 0.005, bcol)
		g.position.x = cx
		add_child(g)


# ── helpers ──
func _mat(c: Color, w: float) -> StandardMaterial3D:
	return HangarKit.finish_body(finish, c, w)


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


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


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
