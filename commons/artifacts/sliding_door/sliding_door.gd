extends Node3D
class_name SlidingDoor

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

# ── Constants ─────────────────────────────────────────────────────────

const PANEL_THICKNESS: float = 0.05
const ACCENT_STRIP_THICKNESS: float = 0.012
const ACCENT_STRIP_HEIGHT_FRAC: float = 0.55  # chest height fraction of door

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

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


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_door() -> void:
	_built = true
	_build_frame()
	_build_panels()


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
	_make_panel(
		panels_root,
		"PanelLeft",
		panel_w,
		panel_h,
		-(panel_w * 0.5 + gap_width * 0.5) - slide
	)
	# Right panel
	_make_panel(
		panels_root,
		"PanelRight",
		panel_w,
		panel_h,
		(panel_w * 0.5 + gap_width * 0.5) + slide
	)


func _make_panel(parent: Node3D, panel_name: String, w: float, h: float, x: float) -> void:
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
