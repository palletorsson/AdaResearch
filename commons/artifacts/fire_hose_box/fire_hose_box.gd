extends Node3D
class_name FireHoseBox

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall-mounted fire-hose cabinet — corridor / emergency-infrastructure vocabulary for "this building knows it can burn, and somebody pre-decided where the water lives". A deep fire-red metal box bolted to the wall, a hinged door with a square glass window through which a flat-coiled hose and its brass nozzle wait, FIRE HOSE in white capitals across the door's foot, a small latch on the left edge, hinges on the right, and a white reel pictogram on the side panel. The building's standing promise that the moment of fire has already been answered, here, behind this red door.
# desire: every occupied building wants its means-of-rescue to be VISIBLE and FINDABLE — a single red architectural object that says "if it burns, the water is HERE, reach through this window, take this nozzle". The box wants to read as DORMANT-READINESS: not in use, but never neutral. Its whole posture is "in case", and "in case" is the most political stance a wall can take.
# critical_parameter: door_open — false reads as "sealed / ready / do not disturb" (the coiled hose seen calmly through the square window, the building at rest, the promise intact and untouched), true reads as "engaged / emergency / the hose is being reached for" (door swung wide on its right-edge hinge, the full reel and nozzle exposed, the dormant promise now an active grab). Same red box, two utterly different rooms: one is a corridor on an ordinary day, the other is a corridor on fire.
# triggers: _ready() builds the red wall box + interior coiled hose (concentric rings) + central nozzle + door (a closed window-frame OR a solid slab, pivoted shut OR swung ~100° on its right edge) + left-edge latch + FIRE HOSE label + side reel pictogram from exports; apply_grid_config rebuilds
# emerges: door_open=false + has_window=true = "the reference, the everyday corridor, the promise visible and intact"; door_open=true = "someone has reached in, the emergency is now"; has_window=false + door_open=false = "a blind sealed cabinet, the hose present but hidden, trust without sight". The window + door-state combination tells the player whether the building is RESTING, ACTING, or merely ASSERTING its readiness.
# needs: wall-mountable deep red box with back-flush mounting (origin on back face) [present]; interior flat-coiled hose of concentric rings always present so it shows through the window and when open [present]; central brass nozzle resting in the coil [present]; hinged door covering the front, a square window cut-out (4-bar frame) when has_window, rotating ~100° about its RIGHT edge when open [present]; small latch/handle on the LEFT edge of the door [present]; FIRE HOSE baked-text quad along the door's bottom, facing +Z (text painted onto the red surface, no floating Label3D) [present]; white reel pictogram + baked-text caption on the +X side panel [present]; hinges on the right edge [present]
# relationships: sibling to emergency_button (both are the corridor's PRE-COMMITMENTS to disaster — the e-stop says "halt the machine NOW", the hose box says "fight the fire HERE, with this"); cousin to electrical_panel (both are red/utility cabinets with a door that is closed-in-production and open-in-crisis, both make an invisible system decidable by hand); peer to the exit sign and extinguisher (a hose box with no extinguisher nearby is half a promise — emergency hardware presumes its companions along the same wall)
# truth: a fire-hose box is not just a coil behind glass. It is the building's STANDING APOLOGY for its own flammability — a red admission, mounted at eye level, that fire was always possible and so the water was placed in advance. The window makes the promise auditable: you can see, on any ordinary day, that the coil is there, that the nozzle is there, that the answer to the worst day is already waiting. The door's state is the difference between a promise kept in reserve and a promise being spent.

## A wall-mounted fire-hose cabinet.
##
## Built procedurally from DNA exports. Origin is at the CENTER OF THE
## BOX BACK FACE — back faces -Z, front faces +Z. When mounted flush
## against a wall (wall at -Z behind origin), the box sits with its back
## on the wall. The door, when closed, covers the front; when door_open
## is true it pivots ~100° around its RIGHT EDGE so it stands open. The
## interior coiled hose + nozzle are always built so they read through the
## square window when closed and fully when open.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var box_width: float = 0.6
@export var box_height: float = 0.6
@export var box_depth: float = 0.25

@export_group("Color")
@export var box_color: Color = Color(0.72, 0.10, 0.10)
@export var hose_color: Color = Color(0.55, 0.12, 0.12)
@export var nozzle_color: Color = Color(0.72, 0.62, 0.34)
@export var label_color: Color = Color(0.96, 0.96, 0.96)

@export_group("Door")
@export var door_open: bool = false
@export var has_window: bool = true

@export_group("Signage")
@export var label_text: String = "FIRE HOSE"
@export var show_pictogram: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const DOOR_DEPTH: float = 0.016        # thickness of the door slab / frame bars
const FRAME_BAR_WIDTH: float = 0.06    # width of each window-frame bar
const WINDOW_INSET: float = 0.07       # window opening inset from box edges (x/y)
const DOOR_OPEN_DEG: float = 100.0     # how far the door swings when open
const HOSE_RING_COUNT: int = 6         # concentric rings in the coil
const HOSE_TUBE_RADIUS: float = 0.018  # cross-section radius of the hose tube
const HOSE_RING_GAP: float = 0.024     # radial gap between successive rings
const HOSE_INNER_RADIUS: float = 0.05  # radius of the innermost ring
const NOZZLE_LENGTH: float = 0.12
const NOZZLE_RADIUS: float = 0.018
const LATCH_SIZE: Vector3 = Vector3(0.022, 0.07, 0.022)
const HINGE_SIZE: Vector3 = Vector3(0.018, 0.05, 0.02)
const LABEL_PIXEL_SIZE: float = 0.0030
const LABEL_FONT_SIZE: int = 32
const PICTO_PIXEL_SIZE: float = 0.0016
const PICTO_FONT_SIZE: int = 24

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_box()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_box()


func _read_metadata_overrides() -> void:
	if has_meta("config_box_width"):
		box_width = float(str(get_meta("config_box_width")))
	if has_meta("config_box_height"):
		box_height = float(str(get_meta("config_box_height")))
	if has_meta("config_box_depth"):
		box_depth = float(str(get_meta("config_box_depth")))
	if has_meta("config_box_color"):
		box_color = _parse_color(str(get_meta("config_box_color")), box_color)
	if has_meta("config_hose_color"):
		hose_color = _parse_color(str(get_meta("config_hose_color")), hose_color)
	if has_meta("config_nozzle_color"):
		nozzle_color = _parse_color(str(get_meta("config_nozzle_color")), nozzle_color)
	if has_meta("config_label_color"):
		label_color = _parse_color(str(get_meta("config_label_color")), label_color)
	if has_meta("config_door_open"):
		var dv := str(get_meta("config_door_open")).to_lower()
		door_open = dv in ["true", "1", "yes", "on"]
	if has_meta("config_has_window"):
		var wv := str(get_meta("config_has_window")).to_lower()
		has_window = wv in ["true", "1", "yes", "on"]
	if has_meta("config_label_text"):
		label_text = str(get_meta("config_label_text"))
	if has_meta("config_show_pictogram"):
		var pv := str(get_meta("config_show_pictogram")).to_lower()
		show_pictogram = pv in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_box() -> void:
	_built = true
	_build_cabinet()
	_build_hose_reel()
	_build_door()
	_build_label()
	_build_side_pictogram()


func _front_z() -> float:
	# Front face of the cabinet box in this Node's local space.
	return box_depth


func _build_cabinet() -> void:
	# Deep fire-red box — back at z=0, front at z=box_depth. Built as 5 thin
	# walls (back + 4 sides) leaving the front open so the interior hose reel
	# reads through the window / open door.
	var root := Node3D.new()
	root.name = "Cabinet"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = box_color
	mat.roughness = 0.5
	mat.metallic = 0.45

	var wall_t: float = 0.02

	# Back wall (against the mounting wall).
	var back := MeshInstance3D.new()
	back.name = "Back"
	var bm := BoxMesh.new()
	bm.size = Vector3(box_width, box_height, wall_t)
	back.mesh = bm
	back.material_override = mat
	back.position = Vector3(0.0, 0.0, wall_t * 0.5)
	root.add_child(back)

	# Top + bottom walls.
	for sy in [1.0, -1.0]:
		var hw := MeshInstance3D.new()
		hw.name = "WallH_%d" % int(sy)
		var hm := BoxMesh.new()
		hm.size = Vector3(box_width, wall_t, box_depth)
		hw.mesh = hm
		hw.material_override = mat
		hw.position = Vector3(0.0, sy * (box_height * 0.5 - wall_t * 0.5), box_depth * 0.5)
		root.add_child(hw)

	# Left + right walls.
	for sx in [1.0, -1.0]:
		var vw := MeshInstance3D.new()
		vw.name = "WallV_%d" % int(sx)
		var vm := BoxMesh.new()
		vm.size = Vector3(wall_t, box_height - wall_t * 2.0, box_depth)
		vw.mesh = vm
		vw.material_override = mat
		vw.position = Vector3(sx * (box_width * 0.5 - wall_t * 0.5), 0.0, box_depth * 0.5)
		root.add_child(vw)


func _build_hose_reel() -> void:
	# Flat coiled hose — concentric TorusMesh rings lying in the X/Y plane,
	# facing forward, set deep in the box so they read through the window.
	# A brass nozzle rests across the center of the coil.
	var root := Node3D.new()
	root.name = "HoseReel"
	add_child(root)

	var hose_mat := StandardMaterial3D.new()
	hose_mat.albedo_color = hose_color
	hose_mat.roughness = 0.7
	hose_mat.metallic = 0.05

	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = hose_color.darkened(0.45)
	dark_mat.roughness = 0.75
	dark_mat.metallic = 0.05

	# Coil sits a little behind the front opening (closer to the back wall).
	var coil_z: float = _front_z() - box_depth * 0.45

	for i in range(HOSE_RING_COUNT):
		var ring := MeshInstance3D.new()
		ring.name = "HoseRing_%d" % i
		var tm := TorusMesh.new()
		var r: float = HOSE_INNER_RADIUS + float(i) * HOSE_RING_GAP
		tm.inner_radius = r - HOSE_TUBE_RADIUS
		tm.outer_radius = r + HOSE_TUBE_RADIUS
		tm.rings = 6
		tm.ring_segments = 18
		ring.mesh = tm
		# Alternate ring shading for a coiled red/dark read.
		ring.material_override = dark_mat if (i % 2 == 1) else hose_mat
		# TorusMesh lies in the X/Z plane by default; rotate so it faces +Z.
		ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		ring.position = Vector3(0.0, 0.0, coil_z)
		root.add_child(ring)

	# Brass nozzle resting across the middle of the coil (slightly forward).
	var nozzle := MeshInstance3D.new()
	nozzle.name = "Nozzle"
	var nm := CylinderMesh.new()
	nm.top_radius = NOZZLE_RADIUS * 0.55
	nm.bottom_radius = NOZZLE_RADIUS
	nm.height = NOZZLE_LENGTH
	nozzle.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = nozzle_color
	nmat.roughness = 0.25
	nmat.metallic = 0.9
	nozzle.material_override = nmat
	# Lay the nozzle horizontally across the coil center, tipped toward +Z.
	nozzle.rotation = Vector3(0.0, 0.0, PI * 0.5)
	nozzle.position = Vector3(0.0, 0.0, coil_z + HOSE_TUBE_RADIUS + NOZZLE_RADIUS)
	root.add_child(nozzle)


func _build_door() -> void:
	# Door covering the front of the box. It hinges on its RIGHT edge (+X side).
	# When closed it sits flush against the front face. When open it rotates
	# ~100° around its right edge so it swings outward. With has_window the door
	# is a 4-bar frame around a square opening; otherwise it is a solid slab.
	var pivot := Node3D.new()
	pivot.name = "DoorPivot"
	add_child(pivot)
	# Pivot at the door's right edge on the front face.
	pivot.position = Vector3(box_width * 0.5, 0.0, _front_z())
	if door_open:
		# Right-edge hinge → swing outward means rotating about +Y by +angle.
		pivot.rotation = Vector3(0.0, deg_to_rad(DOOR_OPEN_DEG), 0.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = box_color
	mat.roughness = 0.45
	mat.metallic = 0.5

	if has_window:
		_build_window_door(pivot, mat)
	else:
		_build_solid_door(pivot, mat)

	# Latch / handle on the LEFT edge of the door (far from the right-edge hinge).
	var latch := MeshInstance3D.new()
	latch.name = "Latch"
	var lm := BoxMesh.new()
	lm.size = LATCH_SIZE
	latch.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.62, 0.62, 0.64)
	lmat.roughness = 0.3
	lmat.metallic = 0.85
	latch.material_override = lmat
	# Door lives in pivot space along -X (left edge ends at x=-box_width).
	latch.position = Vector3(-box_width + 0.05, 0.0, DOOR_DEPTH + LATCH_SIZE.z * 0.5)
	pivot.add_child(latch)

	# Hinges on the right edge (at the pivot axis, on the door's outer face).
	var hinge_mat := StandardMaterial3D.new()
	hinge_mat.albedo_color = Color(0.55, 0.55, 0.57)
	hinge_mat.roughness = 0.35
	hinge_mat.metallic = 0.85
	for hy in [box_height * 0.32, -box_height * 0.32]:
		var hinge := MeshInstance3D.new()
		hinge.name = "Hinge_%d" % int(hy * 100.0)
		var hm := BoxMesh.new()
		hm.size = HINGE_SIZE
		hinge.mesh = hm
		hinge.material_override = hinge_mat
		hinge.position = Vector3(HINGE_SIZE.x * 0.4, hy, DOOR_DEPTH * 0.5)
		pivot.add_child(hinge)


func _build_solid_door(pivot: Node3D, mat: StandardMaterial3D) -> void:
	# Full red slab covering the front. Door center offset from pivot: -X by
	# half-width so the right edge sits at the pivot axis.
	var door := MeshInstance3D.new()
	door.name = "DoorSlab"
	var dm := BoxMesh.new()
	dm.size = Vector3(box_width, box_height, DOOR_DEPTH)
	door.mesh = dm
	door.material_override = mat
	door.position = Vector3(-box_width * 0.5, 0.0, DOOR_DEPTH * 0.5)
	pivot.add_child(door)


func _build_window_door(pivot: Node3D, mat: StandardMaterial3D) -> void:
	# Door built as a frame of 4 thin bars around a central square opening, so
	# the coiled hose reads through the window. Bars live in pivot space; the
	# door spans x in [-box_width, 0], y in [-box_height/2, box_height/2].
	var root := Node3D.new()
	root.name = "DoorFrame"
	pivot.add_child(root)

	var cx: float = -box_width * 0.5   # door center x in pivot space
	var open_w: float = box_width - WINDOW_INSET * 2.0
	var open_h: float = box_height - WINDOW_INSET * 2.0
	var z: float = DOOR_DEPTH * 0.5

	# Top + bottom bars (full door width, FRAME_BAR_WIDTH tall).
	for sy in [1.0, -1.0]:
		var bar := MeshInstance3D.new()
		bar.name = "FrameBarH_%d" % int(sy)
		var bm := BoxMesh.new()
		bm.size = Vector3(box_width, FRAME_BAR_WIDTH, DOOR_DEPTH)
		bar.mesh = bm
		bar.material_override = mat
		bar.position = Vector3(cx, sy * (box_height * 0.5 - FRAME_BAR_WIDTH * 0.5), z)
		root.add_child(bar)

	# Left + right bars (only spanning the window height between the H bars).
	var v_h: float = open_h
	for sx in [1.0, -1.0]:
		var bar := MeshInstance3D.new()
		bar.name = "FrameBarV_%d" % int(sx)
		var bm := BoxMesh.new()
		bm.size = Vector3(FRAME_BAR_WIDTH, v_h, DOOR_DEPTH)
		bar.mesh = bm
		bar.material_override = mat
		bar.position = Vector3(cx + sx * (box_width * 0.5 - FRAME_BAR_WIDTH * 0.5), 0.0, z)
		root.add_child(bar)

	# Thin dark glass pane filling the opening (semi-transparent so the hose
	# is still visible through it).
	var pane := MeshInstance3D.new()
	pane.name = "WindowPane"
	var pm := BoxMesh.new()
	pm.size = Vector3(open_w, open_h, DOOR_DEPTH * 0.25)
	pane.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.15, 0.18, 0.20, 0.25)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.roughness = 0.1
	pmat.metallic = 0.0
	pane.material_override = pmat
	pane.position = Vector3(cx, 0.0, z)
	root.add_child(pane)


func _build_label() -> void:
	# FIRE HOSE baked onto the BOTTOM bar of the door, facing +Z.
	# Replaces a Label3D with a BakedText quad painted onto the red surface.
	if label_text == "":
		return
	var pivot := get_node_or_null("DoorPivot")
	if pivot == null:
		return
	# world_size: full door width × bottom-bar height (matching the old Label3D footprint).
	var w: float = box_width
	var h: float = FRAME_BAR_WIDTH if has_window else 0.06
	var quad := BakedText.make_label_mesh(label_text, label_color, Vector2(w, h))
	if quad:
		quad.name = "Label"
		# Same position as the old Label3D: bottom-bar centre, proud of door face.
		var cx: float = -box_width * 0.5
		var y: float = -box_height * 0.5 + h * 0.5
		var z: float = DOOR_DEPTH + 0.004
		quad.position = Vector3(cx, y, z)
		pivot.add_child(quad)


func _build_side_pictogram() -> void:
	# White fire-hose-reel pictogram on the RIGHT side panel (+X face): a thin
	# ring + a short handle bar, plus a small FIRE HOSE caption. Built as its
	# own root oriented so its flat faces look out along +X.
	if not show_pictogram:
		return
	var root := Node3D.new()
	root.name = "SidePictogram"
	add_child(root)
	# Place on the +X outer face, centered in depth and height.
	var x: float = box_width * 0.5 + 0.002
	root.position = Vector3(x, 0.03, box_depth * 0.5)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.96)
	mat.roughness = 0.6
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.9)
	mat.emission_energy_multiplier = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var picto_r: float = 0.06

	# Reel ring — a torus standing up on the side face (flat face along +X).
	var ring := MeshInstance3D.new()
	ring.name = "PictoRing"
	var tm := TorusMesh.new()
	tm.inner_radius = picto_r - 0.01
	tm.outer_radius = picto_r + 0.005
	tm.rings = 6
	tm.ring_segments = 20
	ring.mesh = tm
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# TorusMesh lies in X/Z; rotate about Z so its disc faces +X.
	ring.rotation = Vector3(0.0, 0.0, PI * 0.5)
	root.add_child(ring)

	# Hub dot in the center of the reel.
	var hub := MeshInstance3D.new()
	hub.name = "PictoHub"
	var hm := CylinderMesh.new()
	hm.top_radius = 0.012
	hm.bottom_radius = 0.012
	hm.height = 0.006
	hub.mesh = hm
	hub.material_override = mat
	hub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hub.rotation = Vector3(0.0, 0.0, PI * 0.5)
	root.add_child(hub)

	# Handle bar reaching off the reel (a short box tangent to the ring).
	var handle := MeshInstance3D.new()
	handle.name = "PictoHandle"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.006, 0.05, 0.012)
	handle.mesh = bm
	handle.material_override = mat
	handle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	handle.position = Vector3(0.005, picto_r + 0.025, 0.0)
	root.add_child(handle)

	# Small FIRE HOSE caption below the pictogram — baked quad facing +X.
	# Replaces a Label3D with a BakedText quad rotated to face the +X side panel.
	var cap_w: float = float(label_text.length()) * PICTO_FONT_SIZE * PICTO_PIXEL_SIZE * 0.6
	var cap_h: float = PICTO_FONT_SIZE * PICTO_PIXEL_SIZE * 1.3
	var cap := BakedText.make_label_mesh(label_text, Color(0.96, 0.96, 0.96),
			Vector2(cap_w, cap_h))
	if cap:
		cap.name = "PictoCaption"
		# Rotate the quad so its +Z normal points toward +X (face the side panel).
		cap.rotation = Vector3(0.0, PI * 0.5, 0.0)
		cap.position = Vector3(0.006, -picto_r - 0.05, 0.0)
		root.add_child(cap)


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
