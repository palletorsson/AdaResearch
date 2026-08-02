extends Node3D
class_name SlidingDoor

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: a two-panel pneumatic sliding door — Portal 2 / Half-Life airlock vocabulary. Dark metal frame, two near-white panels meeting in the middle with a visible seam, a thin Portal-orange accent stripe across each panel at chest height. Static by default; panels_open_amount drives a clean slide.
# desire: every threshold between two rooms gets a door that LOOKS like it opens — frame, panels, seam, accent — even if no animation plays yet. The visual artifact carries the affordance.
# critical_parameter: panels_open_amount — 0 = closed (panels meet, room is sealed), 1 = open (panels at the frame edges, threshold is open). A single scalar that turns the artifact from "wall" into "passage".
# triggers: _ready() builds frame + panels + accent stripes from exports; apply_grid_config rebuilds (useful for door state changes from grid events)
# emerges: closed door = boundary, half-open = invitation, fully open = corridor. Same script, three different narrative beats.
# needs: frame as 4 BoxMeshes [present]; 2 panel BoxMeshes positioned by panels_open_amount [present]; accent_color emissive stripe at chest height [present]
# relationships: peer to exit_sign (the sign NAMES the door; the door IS the named passage); sibling to lab_room (a door joins two rooms — the chamber's seal); the slot the bracelet can never quite fit through; cousin to the catalyst_chamber's threshold
# truth: a door is the place where one room ends and another begins. Closed, it is wall. Open, it is corridor. Half-open, it is invitation. The seam between the panels is where the building admits its own jointedness.

## A two-panel sliding door — Portal/Half-Life pneumatic vocabulary.
##
## Built procedurally from DNA exports. The door faces +Z by default
## (player approaches from +Z, walks through to -Z). The frame is the
## border, the panels slide in ±X to open.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Full opening width when both panels are closed.
@export var door_width: float = 1.8
@export var door_height: float = 2.4
@export var frame_thickness: float = 0.08

@export_group("Color")
@export var frame_color: Color = Color(0.12, 0.12, 0.14)
@export var panel_color: Color = Color(0.94, 0.94, 0.96)
## Portal-orange accent stripe across each panel.
@export var accent_color: Color = Color(0.95, 0.55, 0.0)

@export_group("Behavior")
## Visible seam between the two panels when closed.
@export var gap_width: float = 0.04
## 0 = fully closed (panels meet), 1.0 = fully open (panels at frame edges).
@export_range(0.0, 1.0) var panels_open_amount: float = 0.0

@export_group("DNA")
## AXIS — WHAT THE DOOR CONCEDES ABOUT THE ROOM BEHIND IT. Not how open it is:
## `panels_open_amount` already says that, and a slid-open door is just a corridor.
## This is the prior question — before you touch it, how much has the threshold
## already told you, and does it read as an invitation or as a boundary?
##
##   slab     nothing said — the legacy lineage, byte for byte. Two blank leaves and
##            one accent stripe. The room behind it could be anything, and the door
##            takes no position; the boundary is mute.
##   pane     the room shows itself — a glazed vision light across both leaves at head
##            height, mullioned, with light leaking through the top of the glass and a
##            kick rail low. You can see whether anyone is in there before you knock.
##   caution  you are warned off — a full-width hazard band across the lower leaf, a
##            second band under the accent stripe, RESTRICTED / NO ENTRY printed across
##            the closed seam, and dust at the foot. It tells you WHY, and the why is bad.
##   bolt     you are excluded, with no reason offered — a heavy meeting stile down each
##            closing edge, a locking bar bolted across the face, a red interlock lamp and
##            a keypad you have no code for. The door is not sealed; it is refusing YOU.
##   plate    you are addressed — the door as an address: a bolted name patch on the left
##            leaf, a framed room readout on the right, an authorised-persons line low.
##            An invitation, but only to the person the plate is talking to.
##
## The two leaves carry the dressing (never the frame), so every value still reads
## correctly at any `panels_open_amount` — the claim slides open with the door.
@export_enum("slab", "pane", "caution", "bolt", "plate") var welcome: String = "slab"
const WELCOMES: PackedStringArray = ["slab", "pane", "caution", "bolt", "plate"]
## Room name printed on the left leaf under `welcome = "plate"`.
@export var plate_text: String = "SPECIMEN PREP"
## Door/room number shown as the readout header on the right leaf under "plate".
@export var plate_code: String = "LAB-04"

# ── Constants ─────────────────────────────────────────────────────────

const PANEL_THICKNESS: float = 0.05
const ACCENT_STRIP_THICKNESS: float = 0.012
const ACCENT_STRIP_HEIGHT_FRAC: float = 0.55  # chest height fraction of door

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
# The two leaves of the CURRENT build, held by reference rather than found by path.
# apply_grid_config queue_frees the old children and rebuilds in the same frame, so the
# dying "Panels" node is still in the tree when the new one is added and Godot renames
# the newcomer — a get_node("Panels/PanelLeft") would hand back the corpse.
var _panel_left: Node3D = null
var _panel_right: Node3D = null

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_door()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_door()


func _read_metadata_overrides() -> void:
	if has_meta("config_door_width"):
		door_width = float(str(get_meta("config_door_width")))
	if has_meta("config_door_height"):
		door_height = float(str(get_meta("config_door_height")))
	if has_meta("config_frame_thickness"):
		frame_thickness = float(str(get_meta("config_frame_thickness")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_panel_color"):
		panel_color = _parse_color(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_gap_width"):
		gap_width = float(str(get_meta("config_gap_width")))
	if has_meta("config_panels_open_amount"):
		panels_open_amount = clampf(float(str(get_meta("config_panels_open_amount"))), 0.0, 1.0)
	if has_meta("config_welcome"):
		var _w: String = str(get_meta("config_welcome")).strip_edges().to_lower()
		welcome = _w if WELCOMES.has(_w) else welcome
	if has_meta("config_plate_text"):
		plate_text = str(get_meta("config_plate_text"))
	if has_meta("config_plate_code"):
		plate_code = str(get_meta("config_plate_code"))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_door() -> void:
	_built = true
	_build_frame()
	_build_panels()
	# WELCOME dressing, appended LAST so every node built above keeps its index and
	# position on the legacy path. "slab" falls through and adds nothing at all.
	_build_welcome()


func _build_frame() -> void:
	# Frame is 4 BoxMesh pieces forming a rectangular border around the
	# door opening. Frame OUTER dimensions = door_width + 2*ft × door_height + 2*ft.
	var frame_root := Node3D.new()
	frame_root.name = "Frame"
	add_child(frame_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.4
	mat.metallic = 0.7

	var ft := frame_thickness
	var w := door_width
	var h := door_height
	# Depth of the frame in Z so it reads as a doorway, not a flat sticker.
	var frame_depth := ft * 1.4

	# Top
	var top_frame := MeshInstance3D.new()
	top_frame.name = "FrameTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(w + ft * 2.0, ft, frame_depth)
	top_frame.mesh = tm
	top_frame.material_override = mat
	top_frame.position = Vector3(0.0, h + ft * 0.5, 0.0)
	frame_root.add_child(top_frame)

	# Bottom (sill)
	var bot_frame := MeshInstance3D.new()
	bot_frame.name = "FrameBottom"
	var bm := BoxMesh.new()
	bm.size = Vector3(w + ft * 2.0, ft, frame_depth)
	bot_frame.mesh = bm
	bot_frame.material_override = mat
	bot_frame.position = Vector3(0.0, -ft * 0.5, 0.0)
	frame_root.add_child(bot_frame)

	# Left
	var left_frame := MeshInstance3D.new()
	left_frame.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(ft, h, frame_depth)
	left_frame.mesh = lm
	left_frame.material_override = mat
	left_frame.position = Vector3(-(w * 0.5 + ft * 0.5), h * 0.5, 0.0)
	frame_root.add_child(left_frame)

	# Right
	var right_frame := MeshInstance3D.new()
	right_frame.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(ft, h, frame_depth)
	right_frame.mesh = rm
	right_frame.material_override = mat
	right_frame.position = Vector3(w * 0.5 + ft * 0.5, h * 0.5, 0.0)
	frame_root.add_child(right_frame)


func _build_panels() -> void:
	# Two panels. Each is (door_width/2 - gap_width/2) wide. At
	# panels_open_amount=0 they meet at center (separated by gap_width).
	# At panels_open_amount=1 they sit fully retracted at the frame edges.
	var panels_root := Node3D.new()
	panels_root.name = "Panels"
	add_child(panels_root)

	var panel_w := (door_width - gap_width) * 0.5
	var panel_h := door_height
	# Travel = distance each panel moves from closed to open.
	# When fully open, the panel's inner edge sits at the frame edge,
	# i.e. inner edge at ±door_width/2. Closed inner edge at ±gap_width/2.
	var travel := door_width * 0.5 - gap_width * 0.5
	var slide := travel * panels_open_amount

	# Left panel
	_panel_left = _make_panel(
		panels_root,
		"PanelLeft",
		panel_w,
		panel_h,
		-(panel_w * 0.5 + gap_width * 0.5) - slide
	)
	# Right panel
	_panel_right = _make_panel(
		panels_root,
		"PanelRight",
		panel_w,
		panel_h,
		(panel_w * 0.5 + gap_width * 0.5) + slide
	)


func _make_panel(parent: Node3D, panel_name: String, w: float, h: float, x: float) -> Node3D:
	var panel_node := Node3D.new()
	panel_node.name = panel_name
	panel_node.position = Vector3(x, h * 0.5, 0.0)
	parent.add_child(panel_node)

	# Panel body
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, PANEL_THICKNESS)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.roughness = 0.5
	mat.metallic = 0.2
	body.material_override = mat
	panel_node.add_child(body)

	# Accent stripe — thin emissive line at chest height across the panel face.
	var stripe := MeshInstance3D.new()
	stripe.name = "AccentStripe"
	var sm := BoxMesh.new()
	# Stripe sits on the +Z face of the panel.
	sm.size = Vector3(w * 0.94, ACCENT_STRIP_THICKNESS, 0.004)
	stripe.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent_color
	smat.emission_enabled = true
	smat.emission = accent_color
	smat.emission_energy_multiplier = 1.6
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	stripe.material_override = smat
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var y_local := h * (ACCENT_STRIP_HEIGHT_FRAC - 0.5)  # relative to panel center
	var z_face := PANEL_THICKNESS * 0.5 + 0.002
	stripe.position = Vector3(0.0, y_local, z_face)
	panel_node.add_child(stripe)

	# Same stripe on -Z face so the door reads from both sides.
	var stripe_back := MeshInstance3D.new()
	stripe_back.name = "AccentStripeBack"
	var smb := BoxMesh.new()
	smb.size = Vector3(w * 0.94, ACCENT_STRIP_THICKNESS, 0.004)
	stripe_back.mesh = smb
	stripe_back.material_override = smat
	stripe_back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stripe_back.position = Vector3(0.0, y_local, -z_face)
	panel_node.add_child(stripe_back)

	# Handed back so _build_welcome can hang its dressing on the LEAF (never the frame),
	# which is what keeps a dressed door correct at any panels_open_amount.
	return panel_node


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)


# ── WELCOME ──────────────────────────────────────────────────────────────────
# One axis, five claims about the room on the other side. Everything here is built
# from HangarKit (worn_metal, painted_metal, striped_mat, stencil, brand_patch,
# bolts, readout, three_color_bar) so the door stays inside the cabinet grammar
# shared with station_wall and the rest of the hangar family.
#
# Every piece is parented to a LEAF, never to the frame, so a dressed door still
# reads correctly at any panels_open_amount: the claim slides away with the panel.

func _build_welcome() -> void:
	var left: Node3D = _panel_left
	var right: Node3D = _panel_right
	if left == null or right == null:
		return
	var pw: float = (door_width - gap_width) * 0.5
	match welcome:
		"pane":
			_welcome_pane(left, pw)
			_welcome_pane(right, pw)
		"caution":
			_welcome_caution(left, pw, "RESTRICTED")
			_welcome_caution(right, pw, "NO ENTRY")
		"bolt":
			_welcome_bolt(left, pw, 1.0)
			_welcome_bolt(right, pw, -1.0)
		"plate":
			_welcome_plate_name(left, pw)
			_welcome_plate_readout(right, pw)
		_:
			pass                                  # "slab" — the legacy lineage


## PANE — the room shows itself. A glazed vision light across both leaves at head
## height: dark glass held in a worn-metal mullion frame with a centre astragal, a
## sliver of room light leaking through the head of the glazing, and a kick rail low
## on the leaf. The threshold stops being opaque; you can see who is in there.
func _welcome_pane(panel: Node3D, pw: float) -> void:
	var h: float = door_height
	var win_w: float = pw * 0.78
	var win_h: float = h * 0.30
	var cy: float = h * 0.18                      # head height on the leaf
	var zf: float = PANEL_THICKNESS * 0.5 + 0.004
	var t: float = 0.045
	var mull: StandardMaterial3D = HangarKit.worn_metal(frame_color.lightened(0.34))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.14, 0.19, 0.24, 0.55)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.06
	glass.metallic = 0.25
	# The leaf is a solid opaque slab, so the light has to sit PROUD of its face — a
	# glazed panel modelled inside the slab is a window nobody can see through.
	for s in [1.0, -1.0]:
		var sf: float = s
		# the glazed light, just off the face
		_wbox(panel, Vector3(0.0, cy, sf * (zf + 0.002)), Vector3(win_w, win_h, 0.012), glass)
		# room light leaking through the head of the glazing — the room admits it is lit
		_wbox(panel, Vector3(0.0, cy + win_h * 0.33, sf * (zf + 0.006)),
			Vector3(win_w * 0.95, win_h * 0.16, 0.008),
			HangarKit.emissive(Color(0.62, 0.74, 0.82), 0.9))
		# mullion frame + centre astragal, standing proud of the glass
		var mz: float = sf * (zf + 0.010)
		_wbox(panel, Vector3(0.0, cy + win_h * 0.5, mz), Vector3(win_w + t * 2.0, t, 0.03), mull)
		_wbox(panel, Vector3(0.0, cy - win_h * 0.5, mz), Vector3(win_w + t * 2.0, t, 0.03), mull)
		_wbox(panel, Vector3(-win_w * 0.5 - t * 0.5, cy, mz), Vector3(t, win_h, 0.03), mull)
		_wbox(panel, Vector3(win_w * 0.5 + t * 0.5, cy, mz), Vector3(t, win_h, 0.03), mull)
		_wbox(panel, Vector3(0.0, cy, mz), Vector3(0.028, win_h, 0.026), mull)
		# kick rail — the working lower half of a door that carries a light
		_wbox(panel, Vector3(0.0, -h * 0.22, sf * (zf + 0.008)),
			Vector3(pw * 0.94, 0.10, 0.024), mull)


## CAUTION — you are warned off, and told why. A full-width hazard band across the
## lower leaf plus a second band under the existing accent stripe, a printed legend
## that completes itself across the closed seam (RESTRICTED | NO ENTRY), and a dust
## band at the foot: this door has been shut for a long time.
func _welcome_caution(panel: Node3D, pw: float, legend: String) -> void:
	var h: float = door_height
	var zf: float = PANEL_THICKNESS * 0.5 + 0.004
	for s in [1.0, -1.0]:
		var sf: float = s
		_wbox(panel, Vector3(0.0, -h * 0.24, sf * zf),
			Vector3(pw * 0.98, h * 0.22, 0.014), HangarKit.striped_mat())
		_wbox(panel, Vector3(0.0, h * 0.02, sf * zf),
			Vector3(pw * 0.98, 0.055, 0.012), HangarKit.striped_mat())
	# The legend is printed on the approach face only — a door is read from one side.
	var q: MeshInstance3D = HangarKit.brand_patch(legend, Vector2(pw * 0.82, h * 0.10),
		Color(0.10, 0.10, 0.12), Color(0.95, 0.78, 0.10))
	if q:
		q.position = Vector3(0.0, h * 0.26, zf + 0.006)
		panel.add_child(q)
	var g: MeshInstance3D = HangarKit.grime_band(pw * 0.96, 0.16, zf + 0.003, panel_color)
	if g:
		g.position.y = -h * 0.5
		panel.add_child(g)


## BOLT — you are excluded, and no reason is offered. A heavy meeting stile runs down
## each closing edge so the seam grows a jaw, a locking bar is bolted across the face,
## a red interlock lamp burns on both leaves and a keypad sits on one of them. Nothing
## here says what the room is; it only says the door is not for you.
## `inner` is +1 when the leaf's closing edge is at +X (the left leaf), -1 for the right.
func _welcome_bolt(panel: Node3D, pw: float, inner: float) -> void:
	var h: float = door_height
	var zf: float = PANEL_THICKNESS * 0.5 + 0.004
	var steel: StandardMaterial3D = HangarKit.worn_metal(frame_color.lightened(0.36))
	var dark: StandardMaterial3D = HangarKit.painted_metal(frame_color.lightened(0.10), 0.5)
	var bx: float = inner * (pw * 0.5 - 0.055)
	for s in [1.0, -1.0]:
		var sf: float = s
		_wbox(panel, Vector3(bx, 0.0, sf * zf), Vector3(0.11, h * 0.96, 0.03), steel)
		_wbox(panel, Vector3(inner * pw * 0.10, h * 0.04, sf * (zf + 0.02)),
			Vector3(pw * 0.72, 0.13, 0.05), dark)
	panel.add_child(HangarKit.bolts(Vector3(bx, -h * 0.40, zf + 0.022),
		Vector3(bx, h * 0.40, zf + 0.022), 7, 0.017,
		HangarKit.worn_metal(frame_color.lightened(0.20))))
	# One red interlock lamp per leaf, seated on the bar — the only thing the door tells you.
	_wbox(panel, Vector3(-inner * pw * 0.18, h * 0.04, zf + 0.052),
		Vector3(0.06, 0.06, 0.02), HangarKit.emissive(Color(0.92, 0.16, 0.10), 2.2))
	if inner >= 0.0:
		return
	# The keypad lives on ONE leaf — an interlock has one, not two.
	var pad_x: float = -inner * pw * 0.28
	var pad_y: float = -h * 0.13
	_wbox(panel, Vector3(pad_x, pad_y, zf + 0.018), Vector3(0.18, 0.25, 0.035), dark)
	_wbox(panel, Vector3(pad_x, pad_y + 0.088, zf + 0.038),
		Vector3(0.13, 0.035, 0.008), HangarKit.emissive(Color(0.24, 0.30, 0.26), 0.7))
	var key: StandardMaterial3D = HangarKit.worn_metal(frame_color.lightened(0.46))
	for r in range(4):
		for c in range(3):
			_wbox(panel, Vector3(pad_x + (float(c) - 1.0) * 0.045,
				pad_y + 0.036 - float(r) * 0.038, zf + 0.038),
				Vector3(0.032, 0.026, 0.008), key)


## PLATE — you are addressed. The door as an address: a bolted name patch on a raised
## backing plate, and a stencilled authorisation line low. An invitation, but a narrow
## one — it is talking to whoever the plate names, and to nobody else.
func _welcome_plate_name(panel: Node3D, pw: float) -> void:
	var h: float = door_height
	var zf: float = PANEL_THICKNESS * 0.5 + 0.004
	var back: StandardMaterial3D = HangarKit.worn_metal(panel_color.darkened(0.06))
	var w: float = pw * 0.86
	_wbox(panel, Vector3(0.0, h * 0.20, zf + 0.008),
		Vector3(w + 0.055, h * 0.15 + 0.055, 0.018), back)
	var q: MeshInstance3D = HangarKit.brand_patch(plate_text, Vector2(w, h * 0.15),
		Color(0.11, 0.12, 0.15), Color(0.90, 0.92, 0.96))
	if q:
		q.position = Vector3(0.0, h * 0.20, zf + 0.019)
		panel.add_child(q)
	panel.add_child(HangarKit.bolts(Vector3(-w * 0.5 - 0.014, h * 0.20, zf + 0.024),
		Vector3(w * 0.5 + 0.014, h * 0.20, zf + 0.024), 2, 0.016, back))
	# Half of a sentence — the other half is on the right leaf, so the line only
	# completes itself when the door is shut.
	var code: MeshInstance3D = HangarKit.stencil("AUTHORISED",
		Vector2(pw * 0.60, h * 0.05), Color(0.34, 0.35, 0.39))
	if code:
		code.position = Vector3(pw * 0.10, -h * 0.30, zf + 0.005)
		panel.add_child(code)


## PLATE, right leaf — the room's paperwork: a framed 2D-in-3D readout naming the room
## number and its occupancy, over a three-colour Rams bar. The door is not just named,
## it is administered.
func _welcome_plate_readout(panel: Node3D, pw: float) -> void:
	var h: float = door_height
	var zf: float = PANEL_THICKNESS * 0.5 + 0.004
	var sw: float = pw * 0.78
	var screen: Node3D = HangarKit.readout(plate_code, ["ACCESS   OPEN", "OCCUPANCY   6"],
		Vector2(sw, sw * 0.54), Color(0.88, 0.86, 0.80),
		Color(0.09, 0.09, 0.11), Color(0.09, 0.09, 0.11))
	if screen:
		screen.position = Vector3(0.0, h * 0.20, zf + 0.03)
		panel.add_child(screen)
	var bar: Node3D = HangarKit.three_color_bar(pw * 0.68, 0.045,
		[accent_color, HangarKit.DISPLAY_DARK, panel_color.darkened(0.22)])
	bar.position = Vector3(0.0, -h * 0.03, zf + 0.022)
	panel.add_child(bar)
	var code: MeshInstance3D = HangarKit.stencil("PERSONS ONLY",
		Vector2(pw * 0.66, h * 0.05), Color(0.34, 0.35, 0.39))
	if code:
		code.position = Vector3(-pw * 0.08, -h * 0.30, zf + 0.005)
		panel.add_child(code)


func _wbox(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi
