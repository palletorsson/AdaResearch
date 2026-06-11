extends Node3D
class_name ComputerConsole

# @identity
# essence: an angled industrial computer terminal — the lab's READING STATION, where the room's data becomes a face you can stand in front of. A vertical grey concrete-and-metal cabinet sits on the floor with a single front door (slim vertical handle), and on top the housing tilts a bezelled monitor back ~20° so a standing body meets it at the eyes. The screen glows with a data-visualisation: a few line-graph bars and a colourful spectrogram block in blue/teal/orange. Below the glass, a pull-out keyboard tray holds a grid of tiny keys. A thick black cable loops lazily out the right side and droops to the floor. The lab's admission that data is not abstract — it has a posture, a pedestal, a place where you go to LOOK.
# desire: every instrumented lab wants its readout to be ARCHITECTURE — not a panel bolted to a wall but a body-scaled station you approach, lean toward, and read. The console wants to feel like the room is showing you its vital signs. The tilt is not styling; it is the machine angling its face up to meet yours. The state of the glass IS the state of what the console is reporting.
# critical_parameter: screen_content — "diagram" reads as "all nominal, here is the data, come look" (teal/blue line graphs + a colourful spectrogram, the living reference); "alert" reads as "something is wrong, attend NOW" (a red wash, red bars, an ! ALERT legend); "off" reads as "this station is dark — powered down, unwatched, the room is not reporting" (a flat grey dead screen, no emission, no graphics, only the cable still hanging as proof the thing exists). Same cabinet, three completely different rooms: one is monitored, one is in crisis, one is abandoned.
# triggers: _ready() builds cabinet + front door (slim handle) + tilted bezel housing + emissive monitor (graphics chosen by screen_content) + pull-out keyboard tray with a key grid + a drooping right-side cable from exports; apply_grid_config rebuilds
# emerges: screen_content="diagram" + tray out = "an active workstation, mid-session"; screen_content="alert" = "the lab just tripped a threshold, the red is calling someone"; screen_on=false = "decommissioned terminal, the cable is the only remaining infrastructure"; remove the cable and the console becomes a sealed kiosk; widen the cabinet and it becomes a server pedestal. The glass + cable combination tells the player whether the room is BEING WATCHED.
# needs: floor-standing vertical cabinet with a flat base (origin at base center on the floor) [present]; single front door with a slim vertical pull handle [present]; top housing that tilts the screen back ~20° toward a standing reader [present]; bezel framing an emissive monitor [present]; data-viz on the glass — line-graph bars + a multi-stripe spectrogram block [present]; alert variant — red wash + ! ALERT legend baked onto the screen surface (self-glowing, unshaded quad) [present]; off variant — dark non-emissive glass [present]; pull-out keyboard tray under the screen holding a grid of small keys [present]; thick black cable looping out the +X side and drooping to the floor [present]
# relationships: sibling to electrical_panel (both are the lab's INTERFACES, but the panel is where you DECIDE what is on and the console is where you READ what is happening — decision vs witness); cousin to control_board (both are operated standing, but the control_board acts ON the experiment and the console only REPORTS it); peer to the cable_tray and the breaker (a console with no cable is a screenshot, not a machine — the cable is its umbilical to the room's power and signal)
# truth: a computer console is not a screen. It is the place a room PUTS ITS FACE so a body can read it — the architecture of attention. The cabinet raises the glass to eye height, the tilt angles it toward you, the keyboard tray invites your hands, and the cable confesses that all of this only works because it is plugged into something larger. The console makes the room's interior state STANDABLE-IN-FRONT-OF, and that posture — the going-to-look — is the lab's true confession that data only matters when somebody is watching.

## An angled industrial computer terminal / reading kiosk.
##
## Built procedurally from DNA exports. Origin is at the BASE CENTER on the
## FLOOR — y=0 is the cabinet bottom, centred in X/Z. The prop extends up +Y;
## the cabinet rises, the screen housing tilts back over the cabinet, the
## keyboard tray pulls out toward +Z, and the cable loops out the +X side and
## droops to the floor. Screen, keyboard, and door all face +Z.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var console_width: float = 0.55
@export var console_height: float = 1.1
@export var console_depth: float = 0.55

@export_group("Color")
@export var body_color: Color = Color(0.62, 0.63, 0.65)
@export var handle_color: Color = Color(0.35, 0.36, 0.38)

@export_group("Screen")
@export var screen_on: bool = true
@export var screen_content: String = "diagram"   # "diagram" | "alert" | "off"
@export var screen_color: Color = Color(0.22, 0.55, 0.72)
@export var screen_tilt_degrees: float = 20.0

@export_group("Keyboard")
@export var has_keyboard_tray: bool = true

@export_group("Cable")
@export var cable_visible: bool = true
@export var cable_color: Color = Color(0.07, 0.07, 0.08)

# ── External helpers ──────────────────────────────────────────────────

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# ── Constants ─────────────────────────────────────────────────────────

const CABINET_FRACTION: float = 0.64       # cabinet height as fraction of total
const DOOR_INSET: float = 0.02             # door inset from cabinet front edges
const DOOR_DEPTH: float = 0.014            # door slab thickness (proud of front)
const HANDLE_SIZE: Vector3 = Vector3(0.016, 0.22, 0.02)
const BEZEL_DEPTH: float = 0.05            # bezel slab thickness
const BEZEL_MARGIN: float = 0.04           # bezel frame around the glass
const SCREEN_DEPTH: float = 0.006          # emissive glass thickness
const SCREEN_INSET_Z: float = 0.004        # glass set into the bezel
const GRAPH_DEPTH: float = 0.004           # graphic quads proud of the glass
const TRAY_DEPTH_FRAC: float = 0.55        # tray length (Z) as fraction of cabinet depth
const TRAY_THICKNESS: float = 0.018
const KEY_COLS: int = 10
const KEY_ROWS: int = 4
const KEY_GAP: float = 0.004
const CABLE_RADIUS: float = 0.018
const CABLE_SEGMENTS: int = 10             # short cylinders forming the droop loop

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_console()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_console()


func _read_metadata_overrides() -> void:
	if has_meta("config_console_width"):
		console_width = float(str(get_meta("config_console_width")))
	if has_meta("config_console_height"):
		console_height = float(str(get_meta("config_console_height")))
	if has_meta("config_console_depth"):
		console_depth = float(str(get_meta("config_console_depth")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_handle_color"):
		handle_color = _parse_color(str(get_meta("config_handle_color")), handle_color)
	if has_meta("config_screen_on"):
		var sv := str(get_meta("config_screen_on")).to_lower()
		screen_on = sv in ["true", "1", "yes", "on"]
	if has_meta("config_screen_content"):
		screen_content = str(get_meta("config_screen_content"))
	if has_meta("config_screen_color"):
		screen_color = _parse_color(str(get_meta("config_screen_color")), screen_color)
	if has_meta("config_screen_tilt_degrees"):
		screen_tilt_degrees = float(str(get_meta("config_screen_tilt_degrees")))
	if has_meta("config_has_keyboard_tray"):
		var kv := str(get_meta("config_has_keyboard_tray")).to_lower()
		has_keyboard_tray = kv in ["true", "1", "yes", "on"]
	if has_meta("config_cable_visible"):
		var cv := str(get_meta("config_cable_visible")).to_lower()
		cable_visible = cv in ["true", "1", "yes", "on"]
	if has_meta("config_cable_color"):
		cable_color = _parse_color(str(get_meta("config_cable_color")), cable_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_console() -> void:
	_built = true
	_build_cabinet()
	_build_door()
	_build_screen_housing()
	if has_keyboard_tray:
		_build_keyboard_tray()
	if cable_visible:
		_build_cable()


func _cabinet_height() -> float:
	return console_height * CABINET_FRACTION


func _cabinet_top_z_front() -> float:
	# Front face of the cabinet in local space (cabinet centred on X/Z origin).
	return console_depth * 0.5


func _body_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.62
	mat.metallic = 0.30
	return mat


func _build_cabinet() -> void:
	# Vertical lower cabinet — base on the floor, centred X/Z.
	var ch: float = _cabinet_height()
	var box := MeshInstance3D.new()
	box.name = "Cabinet"
	var bm := BoxMesh.new()
	bm.size = Vector3(console_width, ch, console_depth)
	box.mesh = bm
	box.material_override = _body_material()
	box.position = Vector3(0.0, ch * 0.5, 0.0)
	add_child(box)


func _build_door() -> void:
	# Single front door inset into the cabinet face, with a slim vertical handle.
	var ch: float = _cabinet_height()
	var door_w: float = console_width - DOOR_INSET * 2.0
	var door_h: float = ch - DOOR_INSET * 2.0
	var z: float = _cabinet_top_z_front() + DOOR_DEPTH * 0.5

	var door := MeshInstance3D.new()
	door.name = "Door"
	var dm := BoxMesh.new()
	dm.size = Vector3(door_w, door_h, DOOR_DEPTH)
	door.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color.darkened(0.12)
	mat.roughness = 0.55
	mat.metallic = 0.35
	door.material_override = mat
	door.position = Vector3(0.0, ch * 0.5, z)
	add_child(door)

	# Slim vertical pull handle on the right side of the door.
	var handle := MeshInstance3D.new()
	handle.name = "DoorHandle"
	var hm := BoxMesh.new()
	hm.size = HANDLE_SIZE
	handle.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = handle_color
	hmat.roughness = 0.3
	hmat.metallic = 0.85
	handle.material_override = hmat
	var hx: float = door_w * 0.5 - HANDLE_SIZE.x * 1.6
	handle.position = Vector3(hx, ch * 0.5, z + DOOR_DEPTH * 0.5 + HANDLE_SIZE.z * 0.5)
	add_child(handle)


func _build_screen_housing() -> void:
	# Top housing tilts the bezel + monitor back by screen_tilt_degrees.
	# A pivot sits at the back-top edge of the cabinet front and rotates the
	# housing back (top leans away toward -Z), so the glass faces up-and-toward
	# a standing reader at +Z.
	var ch: float = _cabinet_height()
	var pivot := Node3D.new()
	pivot.name = "ScreenPivot"
	# Pivot near the top of the cabinet, at the front face.
	pivot.position = Vector3(0.0, ch, _cabinet_top_z_front())
	# Negative X-rotation leans the top of the housing back toward -Z.
	pivot.rotation = Vector3(deg_to_rad(-screen_tilt_degrees), 0.0, 0.0)
	add_child(pivot)

	var bezel_w: float = console_width * 0.96
	var bezel_h: float = (console_height - ch) * 1.18
	var glass_w: float = bezel_w - BEZEL_MARGIN * 2.0
	var glass_h: float = bezel_h - BEZEL_MARGIN * 2.0

	# Bezel slab. Centred above the pivot in the tilted frame; back face near z=0.
	var bezel := MeshInstance3D.new()
	bezel.name = "Bezel"
	var bm := BoxMesh.new()
	bm.size = Vector3(bezel_w, bezel_h, BEZEL_DEPTH)
	bezel.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = body_color.darkened(0.55)
	bmat.roughness = 0.5
	bmat.metallic = 0.4
	bezel.material_override = bmat
	bezel.position = Vector3(0.0, bezel_h * 0.5, BEZEL_DEPTH * 0.5)
	pivot.add_child(bezel)

	# Determine screen mode.
	var mode: String = screen_content.to_lower()
	if not screen_on:
		mode = "off"

	# Emissive monitor glass, set into the front of the bezel.
	var glass := MeshInstance3D.new()
	glass.name = "Screen"
	var gm := BoxMesh.new()
	gm.size = Vector3(glass_w, glass_h, SCREEN_DEPTH)
	glass.mesh = gm
	var smat := StandardMaterial3D.new()
	if mode == "off":
		smat.albedo_color = Color(0.10, 0.11, 0.12)
		smat.roughness = 0.25
		smat.metallic = 0.0
	elif mode == "alert":
		smat.albedo_color = Color(0.30, 0.03, 0.03)
		smat.emission_enabled = true
		smat.emission = Color(0.85, 0.10, 0.08)
		smat.emission_energy_multiplier = 2.0
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	else: # diagram
		smat.albedo_color = screen_color.darkened(0.35)
		smat.emission_enabled = true
		smat.emission = screen_color
		smat.emission_energy_multiplier = 1.6
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	glass.material_override = smat
	var glass_z: float = BEZEL_DEPTH - SCREEN_INSET_Z
	glass.position = Vector3(0.0, bezel_h * 0.5, glass_z)
	pivot.add_child(glass)

	# Graphics on the glass (only when lit).
	var graph_z: float = glass_z + SCREEN_DEPTH * 0.5 + GRAPH_DEPTH * 0.5
	if mode == "diagram":
		_build_diagram_graphics(pivot, bezel_h * 0.5, glass_w, glass_h, graph_z)
	elif mode == "alert":
		_build_alert_graphics(pivot, bezel_h * 0.5, glass_w, glass_h, graph_z)


func _make_emissive_quad(parent: Node3D, name_str: String, size: Vector2, pos: Vector3, col: Color, energy: float) -> void:
	var q := MeshInstance3D.new()
	q.name = name_str
	var qm := BoxMesh.new()
	qm.size = Vector3(size.x, size.y, GRAPH_DEPTH)
	q.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.position = pos
	parent.add_child(q)


func _build_diagram_graphics(parent: Node3D, cy: float, gw: float, gh: float, z: float) -> void:
	# Layout in the glass's local plane (X across, Y up, centre at y=cy).
	var left: float = -gw * 0.5
	var top: float = cy + gh * 0.5
	var bottom: float = cy - gh * 0.5
	var inset: float = gw * 0.06

	# Two line-graph bars (bright thin horizontal-ish rectangles) in the upper area.
	var bar_w: float = gw * 0.5
	var bar_h: float = gh * 0.05
	_make_emissive_quad(parent, "GraphBar0",
		Vector2(bar_w, bar_h),
		Vector3(left + inset + bar_w * 0.5, top - gh * 0.16, z),
		Color(0.55, 0.92, 0.95), 2.4)
	_make_emissive_quad(parent, "GraphBar1",
		Vector2(bar_w * 0.74, bar_h),
		Vector3(left + inset + bar_w * 0.37, top - gh * 0.30, z),
		Color(0.40, 0.80, 0.95), 2.4)
	# A small graph block (filled rect) upper-right.
	_make_emissive_quad(parent, "GraphBlock",
		Vector2(gw * 0.30, gh * 0.22),
		Vector3(left + gw * 0.78, top - gh * 0.22, z),
		Color(0.30, 0.70, 0.92), 1.9)

	# Spectrogram block — a row of side-by-side emissive bars (blue/teal/orange)
	# in the lower portion of the screen.
	var spec_cols: int = 8
	var spec_w_total: float = gw * 0.84
	var spec_x0: float = -spec_w_total * 0.5
	var col_w: float = spec_w_total / float(spec_cols)
	var base_y: float = bottom + gh * 0.10
	var palette := [
		Color(0.20, 0.45, 0.95),  # blue
		Color(0.20, 0.75, 0.85),  # teal
		Color(0.30, 0.85, 0.70),  # green-teal
		Color(0.95, 0.70, 0.20),  # orange
		Color(0.98, 0.55, 0.15),  # deep orange
		Color(0.25, 0.65, 0.90),  # blue 2
		Color(0.20, 0.80, 0.80),  # teal 2
		Color(0.95, 0.62, 0.18),  # orange 2
	]
	var heights := [0.34, 0.22, 0.40, 0.18, 0.30, 0.26, 0.38, 0.20]
	for i in range(spec_cols):
		var bh: float = gh * heights[i]
		var bx: float = spec_x0 + col_w * (float(i) + 0.5)
		_make_emissive_quad(parent, "Spec_%d" % i,
			Vector2(col_w * 0.78, bh),
			Vector3(bx, base_y + bh * 0.5, z),
			palette[i], 2.6)


func _build_alert_graphics(parent: Node3D, cy: float, gw: float, gh: float, z: float) -> void:
	# A couple of red bars plus an "! ALERT" legend.
	var red := Color(0.98, 0.18, 0.12)
	_make_emissive_quad(parent, "AlertBar0",
		Vector2(gw * 0.72, gh * 0.10),
		Vector3(0.0, cy + gh * 0.10, z),
		red, 2.8)
	_make_emissive_quad(parent, "AlertBar1",
		Vector2(gw * 0.52, gh * 0.08),
		Vector3(0.0, cy - gh * 0.04, z),
		red, 2.8)

	# "! ALERT" baked onto the screen surface — unshaded so it self-glows with
	# the screen (the fire_extinguisher principle, via BakedText.make_label_mesh).
	# Parented under the same tilted pivot the Label3D used, at the same local
	# position, so it tilts with the screen housing. world_size matches the old
	# Label3D footprint on the glass.
	var quad := BakedText.make_label_mesh(
		"! ALERT", Color(1.0, 0.92, 0.90),
		Vector2(gw * 0.60, gh * 0.14), 1400, true)
	if quad:
		quad.name = "AlertLabel"
		# Place proud of the glass face, same Y as the old Label3D.
		quad.position = Vector3(0.0, cy - gh * 0.22, z + 0.004)
		parent.add_child(quad)


func _build_keyboard_tray() -> void:
	# Horizontal pull-out tray just below the screen housing, holding a key grid.
	var ch: float = _cabinet_height()
	var tray_w: float = console_width * 0.92
	var tray_len: float = console_depth * TRAY_DEPTH_FRAC
	var tray_y: float = ch + 0.01
	# Tray extends forward from the cabinet front toward +Z.
	var tray_front_z: float = _cabinet_top_z_front()
	var tray_center_z: float = tray_front_z + tray_len * 0.5

	var root := Node3D.new()
	root.name = "KeyboardTray"
	add_child(root)

	# Tray plate.
	var tray := MeshInstance3D.new()
	tray.name = "TrayPlate"
	var tm := BoxMesh.new()
	tm.size = Vector3(tray_w, TRAY_THICKNESS, tray_len)
	tray.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = body_color.darkened(0.25)
	tmat.roughness = 0.55
	tmat.metallic = 0.4
	tray.material_override = tmat
	tray.position = Vector3(0.0, tray_y, tray_center_z)
	root.add_child(tray)

	# Keyboard base plate (slightly inset, dark) sitting on the tray.
	var kb_w: float = tray_w * 0.86
	var kb_len: float = tray_len * 0.78
	var kb := MeshInstance3D.new()
	kb.name = "KeyboardBase"
	var km := BoxMesh.new()
	km.size = Vector3(kb_w, 0.01, kb_len)
	kb.mesh = km
	var kmat := StandardMaterial3D.new()
	kmat.albedo_color = Color(0.10, 0.10, 0.12)
	kmat.roughness = 0.5
	kmat.metallic = 0.2
	kb.material_override = kmat
	var kb_y: float = tray_y + TRAY_THICKNESS * 0.5 + 0.005
	kb.position = Vector3(0.0, kb_y, tray_center_z)
	root.add_child(kb)

	# Key grid as a single MultiMesh of tiny boxes.
	var count: int = KEY_COLS * KEY_ROWS
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var key_mesh := BoxMesh.new()
	var area_w: float = kb_w * 0.92
	var area_len: float = kb_len * 0.86
	var cell_w: float = area_w / float(KEY_COLS)
	var cell_l: float = area_len / float(KEY_ROWS)
	var key_sx: float = cell_w - KEY_GAP
	var key_sz: float = cell_l - KEY_GAP
	key_mesh.size = Vector3(key_sx, 0.008, key_sz)
	mm.mesh = key_mesh
	mm.instance_count = count
	var x0: float = -area_w * 0.5 + cell_w * 0.5
	var z0: float = tray_center_z - area_len * 0.5 + cell_l * 0.5
	var keys_top_y: float = kb_y + 0.005 + 0.004
	var idx: int = 0
	for r in range(KEY_ROWS):
		for c in range(KEY_COLS):
			var kx: float = x0 + cell_w * float(c)
			var kz: float = z0 + cell_l * float(r)
			mm.set_instance_transform(idx, Transform3D(Basis(), Vector3(kx, keys_top_y, kz)))
			idx += 1

	var keys := MultiMeshInstance3D.new()
	keys.name = "Keys"
	keys.multimesh = mm
	var key_mat := StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.22, 0.22, 0.24)
	key_mat.roughness = 0.45
	key_mat.metallic = 0.15
	keys.material_override = key_mat
	root.add_child(keys)


func _build_cable() -> void:
	# Thick black cable looping out of the RIGHT side (+X) and drooping to the
	# floor. Built as a chain of short cylinder segments tracing a catenary-like
	# droop curve from the cabinet side down to the floor.
	var ch: float = _cabinet_height()
	var root := Node3D.new()
	root.name = "Cable"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = cable_color
	mat.roughness = 0.6
	mat.metallic = 0.1

	# Exit point: right side of the cabinet, partway up, slightly forward.
	var exit := Vector3(console_width * 0.5, ch * 0.45, console_depth * 0.12)
	# End point: on the floor, out to +X and forward.
	var floor_end := Vector3(console_width * 0.5 + 0.30, CABLE_RADIUS, console_depth * 0.30)
	# Mid sag point pulls the curve outward and down (the droop loop belly).
	var sag := Vector3(console_width * 0.5 + 0.42, ch * 0.16, console_depth * 0.22)

	# Build sample points along a quadratic Bezier (exit -> sag -> floor_end).
	var pts: Array = []
	for s in range(CABLE_SEGMENTS + 1):
		var t: float = float(s) / float(CABLE_SEGMENTS)
		var omt: float = 1.0 - t
		var p: Vector3 = exit * (omt * omt) + sag * (2.0 * omt * t) + floor_end * (t * t)
		pts.append(p)

	# Connect consecutive points with cylinder segments.
	for i in range(CABLE_SEGMENTS):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg := MeshInstance3D.new()
		seg.name = "CableSeg_%d" % i
		var dir: Vector3 = b - a
		var length: float = dir.length()
		if length < 0.0001:
			continue
		var cm := CylinderMesh.new()
		cm.top_radius = CABLE_RADIUS
		cm.bottom_radius = CABLE_RADIUS
		cm.height = length
		seg.mesh = cm
		seg.material_override = mat
		# Cylinder default axis is +Y; orient it along dir, position at midpoint.
		var mid: Vector3 = (a + b) * 0.5
		var up := Vector3.UP
		var ndir: Vector3 = dir.normalized()
		var t3: Transform3D = Transform3D()
		if abs(ndir.dot(up)) > 0.999:
			t3.basis = Basis()
		else:
			var axis: Vector3 = up.cross(ndir).normalized()
			var angle: float = acos(clamp(up.dot(ndir), -1.0, 1.0))
			t3.basis = Basis(axis, angle)
		t3.origin = mid
		seg.transform = t3
		root.add_child(seg)

	# A small connector boss where the cable exits the cabinet.
	var boss := MeshInstance3D.new()
	boss.name = "CableBoss"
	var bm := CylinderMesh.new()
	bm.top_radius = CABLE_RADIUS * 1.6
	bm.bottom_radius = CABLE_RADIUS * 1.6
	bm.height = 0.03
	boss.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = cable_color.lightened(0.1)
	bmat.roughness = 0.5
	bmat.metallic = 0.4
	boss.material_override = bmat
	# Lay the boss along +X so its face caps the cabinet side.
	boss.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	boss.position = exit
	root.add_child(boss)


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
