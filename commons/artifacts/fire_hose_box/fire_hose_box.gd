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

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27) — SHARED VOCABULARY WITH fire_extinguisher.
# 439 placements here, 302 there, and between them exactly one look each. These
# two are the same institution's safety equipment; they are promoted together and
# they answer to THE SAME TWO TOKENS with THE SAME VALUE NAMES. If you add a value
# to one file, add it to the other in the same commit or the family forks.
#
# The axis comes out of both identity blocks, which say the same thing twice:
# "VISIBLE and FINDABLE", "the window makes the promise auditable" here; "visible
# from across the room", "you will see me before you need me" there. Both are
# about how LEGIBLE the promise is made — and safety equipment is the one class of
# object in a building whose appearance is written down in law rather than chosen.
# So the question the axis asks is: what did this building DO with that law?
#
#   station   HOW IT IS HELD        bracket · cabinet · stand
#   statute   WHAT THE BUILDING     issue · notice · joinery · lapse
#             DID WITH THE LAW
#
# `station` is body and mass: bolted flat to the wall (legacy), swallowed into a
# full-height fire-point cabinet with a glazed niche below for the extinguisher
# that ought to be beside it, or lifted onto a free-standing weighted stand — the
# temporary site fire point, safety as something wheeled in rather than built in.
#
# `statute` is register. `issue` is the object exactly as delivered: red, lettered,
# and nothing added — the building met the code in the equipment's own body and
# stopped there. `notice` is full submission: the white backing board with its red
# border, the mandatory sign above, a double-sided flag projecting into the
# corridor, a keep-clear zone painted on the floor. `joinery` is absorption: the
# architect won, the red is retinted into the building's own cabinetwork and the
# shouting is reduced to one small engraved plate. `lapse` is the promise left to
# rot — chalked paint, rust weeping from the fixings, a service tag whose date has
# gone by. The identity says "the answer to the worst day is already waiting";
# `lapse` is the variant where it is not.
#
# station=bracket and statute=issue are the legacy lineage, exactly: _build_station()
# and _build_statute() return on the first line for those values, and _lv()/_ink()
# are pure identity functions unless the statute entry carries a tint. All 439
# existing placements — none of which sets a single config token today — are
# untouched.
#
# Deliberately NOT retinted by `statute`: the statutory sign red on the notice
# board, the flag and the stand's topper. Following exhibit_furniture's carve-out —
# a building's legal obligations do not follow its decorator. Under `joinery` that
# leaves one red mark the building could not repaint, which is the joke.
#
# What it cost: the four red/white literals in _build_cabinet, _build_door,
# _build_label and _build_side_pictogram are now funnelled through _lv()/_ink(),
# so a reader has to hop to STATUTES to know what the box looks like.
# ─────────────────────────────────────────────────────────────────────────────

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

@export_group("Family")
## AXIS 1 — how the building HOLDS the equipment. Shared verbatim with
## fire_extinguisher: bracket (legacy default, bolted flat to the wall) |
## cabinet (a full-height fire point, glazed niche below) | stand (a weighted
## free-standing post, safety wheeled in rather than built in).
@export var station: String = "bracket"
## AXIS 2 — what the building did with the law that specifies this object's
## appearance. Shared verbatim with fire_extinguisher: issue (legacy default,
## as delivered, nothing added) | notice (full submission — backing board, sign,
## projecting flag, painted floor zone) | joinery (absorbed into the building's
## cabinetwork, retinted, one small engraved plate) | lapse (the promise left to
## rot — chalked paint, rust, an expired tag).
@export var statute: String = "issue"

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

# ── Family axes ───────────────────────────────────────────────────────

## The statute's own colours. NOT routed through `statute` — a sign is the law
## speaking, and the law is not the building's decorator (same carve-out
## exhibit_furniture makes for EXIT green and FIRE red).
const SIGN_RED: Color = Color(0.70, 0.09, 0.10)
const BOARD_WHITE: Color = Color(0.93, 0.93, 0.91)

## How `statute` treats the equipment's own skin. `issue` and `notice` carry NO
## "tint"/"rough"/"metal"/"ink" keys, so _lv()/_ink() hand the legacy colours
## straight back — the default path is an identity function, not a lookup that
## happens to match. An unknown value degrades the same way.
const STATUTES: Dictionary = {
	"issue": {},
	"notice": {},
	# The architect's grey-green cabinetwork. Red 0.78/0.10 lands near
	# (0.33, 0.27, 0.24) — a dark taupe. The object stops being red, which is
	# the single loudest read in the family and, in most jurisdictions, illegal.
	"joinery": {"tint": Color(0.27, 0.29, 0.26), "amt": 0.88, "rough": 0.90,
			"metal": 0.06, "ink": Color(0.44, 0.46, 0.42), "ink_amt": 1.0},
	# Twenty years of corridor light. Red chalks up toward (0.69, 0.28, 0.27),
	# a washed brick pink, and goes flat — no metallic sheen left to catch a lamp.
	"lapse": {"tint": Color(0.60, 0.45, 0.42), "amt": 0.58, "rough": 0.95,
			"metal": 0.03, "ink": Color(0.56, 0.53, 0.48), "ink_amt": 0.85},
}

const STAND_DROP: float = 0.85     # leg length below the box: auto-grounding then lands the reel centre at ~1.15 m
const CAB_MARGIN: float = 0.055    # fire-point cabinet clearance either side of the hose box
const CAB_NICHE: float = 0.72      # height of the empty lower niche — the extinguisher's absent place

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
	if has_meta("config_station"):
		station = str(get_meta("config_station"))
	if has_meta("config_statute"):
		statute = str(get_meta("config_statute"))


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
	# Both return on their first line for the legacy values — see the promotion
	# note at the top. station=bracket + statute=issue adds not one mesh.
	_build_station()
	_build_statute()


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
	mat.albedo_color = _lv(box_color)
	mat.roughness = _lv_rough(0.5)
	mat.metallic = _lv_metal(0.45)

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
	mat.albedo_color = _lv(box_color)
	mat.roughness = _lv_rough(0.45)
	mat.metallic = _lv_metal(0.5)

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
	var quad := BakedText.make_label_mesh(label_text, _ink(label_color), Vector2(w, h))
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
	mat.albedo_color = _ink(Color(0.96, 0.96, 0.96))
	mat.roughness = 0.6
	mat.metallic = 0.0
	mat.emission_enabled = true
	# Inked too, so the pictogram stops self-lighting when the statute is spent —
	# the energy stays 0.4, it is the colour that goes dark.
	mat.emission = _ink(Color(0.9, 0.9, 0.9))
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
	var cap := BakedText.make_label_mesh(label_text, _ink(Color(0.96, 0.96, 0.96)),
			Vector2(cap_w, cap_h))
	if cap:
		cap.name = "PictoCaption"
		# Rotate the quad so its +Z normal points toward +X (face the side panel).
		cap.rotation = Vector3(0.0, PI * 0.5, 0.0)
		cap.position = Vector3(0.006, -picto_r - 0.05, 0.0)
		root.add_child(cap)


# ── Family: livery ────────────────────────────────────────────────────

## The red skin under the current statute. `issue` and `notice` carry no "tint",
## so this hands `c` straight back — not a lookup that happens to match, an
## identity return. Never mutates box_color: a rebuild via apply_grid_config must
## not compound the fade, and an explicit #box_color: override must still be the
## thing that gets faded.
func _lv(c: Color) -> Color:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("tint"):
		return c
	var tint: Color = e["tint"]
	return c.lerp(tint, float(e.get("amt", 0.5)))


func _lv_rough(base: float) -> float:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("rough"):
		return base
	return float(e["rough"])


func _lv_metal(base: float) -> float:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("metal"):
		return base
	return float(e["metal"])


## The white signage — the lettering, the pictogram, the caption. Goes quiet
## under joinery (the building would rather not say it) and washed under lapse
## (nobody has repainted it).
func _ink(c: Color) -> Color:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("ink"):
		return c
	var ink: Color = e["ink"]
	return c.lerp(ink, float(e.get("ink_amt", 1.0)))


# ── Family: shared build helpers ──────────────────────────────────────

func _surface(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _slab(size: Vector3, pos: Vector3, mat: StandardMaterial3D, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if parent == null:
		add_child(mi)
	else:
		parent.add_child(mi)
	return mi


## Local Y of the floor this assembly stands on. For `bracket` that is the box's
## own bottom edge, which is what auto-grounding already puts on the floor — so
## nothing built at this height can shift the artifact. `cabinet` and `stand`
## deliberately reach BELOW it: auto-grounding then lifts the whole assembly and
## the reel arrives at working height, which is the point of both.
func _ground_y() -> float:
	match station:
		"cabinet":
			return -box_height * 0.5 - CAB_NICHE - 0.06
		"stand":
			return -box_height * 0.5 - STAND_DROP
		_:
			return -box_height * 0.5


# ── Family axis 1: station — how the building holds it ────────────────

func _build_station() -> void:
	match station:
		"cabinet":
			_station_cabinet()
		"stand":
			_station_stand()
		_:
			pass                       # "bracket" — the legacy lineage, bolted flat, nothing added


## THE FIRE POINT. The hose box becomes the upper half of a full-height surround
## and a glazed empty niche opens below it — the place where the extinguisher
## ought to be. The identity says a hose box with no extinguisher nearby is half
## a promise; this variant builds the other half as a hole.
func _station_cabinet() -> void:
	var shell: StandardMaterial3D = _surface(_lv(box_color), _lv_rough(0.5), _lv_metal(0.42))
	var w: float = box_width + CAB_MARGIN * 2.0
	var d: float = box_depth + 0.045
	var top: float = box_height * 0.5 + 0.115
	var bot: float = _ground_y()
	var h: float = top - bot
	var cz: float = d * 0.5
	var t: float = 0.03
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(t, h, d), Vector3(s * (w * 0.5 - t * 0.5), bot + h * 0.5, cz), shell)
	_slab(Vector3(w, t, d), Vector3(0.0, top - t * 0.5, cz), shell)              # crown
	_slab(Vector3(w, t, d), Vector3(0.0, bot + t * 0.5, cz), shell)              # floor
	# the shelf that separates water (above) from the absent extinguisher (below)
	var shelf_y: float = -box_height * 0.5 - 0.03
	_slab(Vector3(w - t * 2.0, 0.022, d), Vector3(0.0, shelf_y, cz), shell)
	var niche_h: float = shelf_y - (bot + t)
	var niche_y: float = (bot + t + shelf_y) * 0.5
	_slab(Vector3(w - t * 2.0, niche_h, 0.02), Vector3(0.0, niche_y, 0.012),
			_surface(_lv(box_color).darkened(0.4), 0.85, 0.05))
	var pane: MeshInstance3D = _slab(Vector3(w - t * 2.2, niche_h - 0.05, 0.012),
			Vector3(0.0, niche_y, d - 0.018), _surface(Color(0.15, 0.18, 0.20, 0.25), 0.1, 0.0))
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a header valance across the front, tucked under the roof plate, and the name
	# of the whole point printed on it
	var hdr_h: float = 0.105
	var hdr_y: float = top - t - hdr_h * 0.5
	_slab(Vector3(w, hdr_h, 0.026), Vector3(0.0, hdr_y, d - 0.013), shell)
	var crown: MeshInstance3D = BakedText.make_panel_mesh("FIRE POINT",
			_lv(box_color).darkened(0.25), _ink(Color(0.96, 0.96, 0.95)),
			Vector2(w * 0.84, 0.075))
	if crown:
		crown.position = Vector3(0.0, hdr_y, d + 0.002)
		crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(crown)


## THE TEMPORARY POINT. Two steel legs off a hazard-rimmed base plate carry the
## reel at working height, a double-sided sign on a short mast above it. Safety
## wheeled in rather than built in — the site hut, the marquee, the works.
func _station_stand() -> void:
	var steel: StandardMaterial3D = _surface(Color(0.20, 0.21, 0.23), 0.5, 0.7)
	var hazard: StandardMaterial3D = _surface(Color(0.82, 0.68, 0.08), 0.7, 0.1)
	var g: float = _ground_y()
	var bw: float = box_width * 0.86
	var bd: float = box_depth + 0.28
	var bz: float = box_depth * 0.5 + 0.02
	_slab(Vector3(bw + 0.09, 0.014, bd + 0.09), Vector3(0.0, g + 0.007, bz), hazard)
	_slab(Vector3(bw, 0.036, bd), Vector3(0.0, g + 0.032, bz), steel)
	var leg_h: float = -box_height * 0.5 - (g + 0.05)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(0.055, leg_h, 0.055),
				Vector3(s * box_width * 0.33, g + 0.05 + leg_h * 0.5, box_depth * 0.35), steel)
	_slab(Vector3(box_width * 0.78, 0.032, 0.032),
			Vector3(0.0, g + 0.05 + leg_h * 0.34, box_depth * 0.35), steel)
	_slab(Vector3(0.035, 0.26, 0.035),
			Vector3(0.0, box_height * 0.5 + 0.13, box_depth * 0.35), steel)
	for face in [0.0, 180.0]:
		var deg: float = face
		var p: MeshInstance3D = BakedText.make_panel_mesh(label_text, SIGN_RED,
				Color(0.95, 0.95, 0.94), Vector2(0.46, 0.18))
		if p:
			# clear of the mast's own 35 mm thickness, or the post occludes the
			# middle of its own sign
			var off: float = 0.0215
			if deg > 90.0:
				off = -0.0215
			p.rotation_degrees = Vector3(0.0, deg, 0.0)
			p.position = Vector3(0.0, box_height * 0.5 + 0.34, box_depth * 0.35 + off)
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(p)


# ── Family axis 2: statute — what the building did with the law ───────

func _build_statute() -> void:
	match statute:
		"notice":
			_statute_notice()
		"joinery":
			_statute_joinery()
		"lapse":
			_statute_lapse()
		_:
			pass                       # "issue" — as delivered; the building added nothing


## FULL SUBMISSION. The backing board with its red border, the mandatory sign
## above the equipment, a double-sided flag projecting into the corridor so the
## promise is findable from down the hall, and a keep-clear zone painted on the
## floor. Everything here is bottom-flush with the box so auto-grounding does not
## move the reel.
func _statute_notice() -> void:
	var bot: float = -box_height * 0.5
	var bw: float = box_width + 0.30
	var bh: float = box_height + 0.56
	var bord: float = 0.055
	# Both plates live INSIDE the cabinet back wall's z span (0 .. 0.02) and share
	# no face plane with it — a coplanar back face would flicker on the rear
	# capture angle.
	_slab(Vector3(bw + bord, bh + bord, 0.008), Vector3(0.0, bot + (bh + bord) * 0.5, 0.005),
			_surface(SIGN_RED, 0.6, 0.0))
	_slab(Vector3(bw, bh, 0.008), Vector3(0.0, bot + bh * 0.5, 0.011),
			_surface(BOARD_WHITE, 0.68, 0.0))
	var sign: MeshInstance3D = BakedText.make_panel_mesh(label_text, SIGN_RED, BOARD_WHITE,
			Vector2(bw * 0.62, 0.22))
	if sign:
		sign.position = Vector3(0.0, box_height * 0.5 + 0.22, 0.017)
		sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sign)
	# the projecting flag — the one part of the apparatus aimed at someone who is
	# not yet standing here
	var bracket_mat: StandardMaterial3D = _surface(Color(0.55, 0.56, 0.58), 0.4, 0.8)
	var fx: float = box_width * 0.5 + 0.13
	var fy: float = box_height * 0.5 + 0.30
	var fz: float = 0.30
	_slab(Vector3(0.028, 0.028, fz), Vector3(fx, fy + 0.115, fz * 0.5 + 0.012), bracket_mat)
	_slab(Vector3(0.028, 0.13, 0.028), Vector3(fx, fy + 0.05, fz - 0.02), bracket_mat)
	for side in [90.0, -90.0]:
		var deg: float = side
		var f: MeshInstance3D = BakedText.make_panel_mesh(label_text, SIGN_RED, BOARD_WHITE,
				Vector2(0.34, 0.15))
		if f:
			var off: float = 0.008
			if deg < 0.0:
				off = -0.008
			f.rotation_degrees = Vector3(0.0, deg, 0.0)
			f.position = Vector3(fx + off, fy, fz)
			f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(f)
	_keep_clear(bw)


## The painted outline on the floor: a rectangle you are not allowed to fill.
## Sits 10 mm above _ground_y() so it can never become the assembly's lowest
## point and re-trigger auto-grounding.
func _keep_clear(w: float) -> void:
	var paint: StandardMaterial3D = _surface(Color(0.84, 0.70, 0.09), 0.85, 0.0)
	var y: float = _ground_y() + 0.010
	var z0: float = box_depth + 0.06
	var dz: float = 0.62
	var t: float = 0.055
	_slab(Vector3(w, 0.012, t), Vector3(0.0, y, z0), paint)
	_slab(Vector3(w, 0.012, t), Vector3(0.0, y, z0 + dz), paint)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(t, 0.012, dz), Vector3(s * (w * 0.5 - t * 0.5), y, z0 + dz * 0.5), paint)


## ABSORPTION. A flush matte panel matched to the building's own cabinetwork with
## a shadow-gap reveal at its head, the equipment retinted into it by _lv(), and
## one small brushed plate where the shouting used to be. The statute is met on
## paper and nowhere else.
func _statute_joinery() -> void:
	var bot: float = -box_height * 0.5
	var pw: float = box_width + 0.52
	var ph: float = box_height + 0.34
	# 18 mm thick and seated at z 0.001..0.019, i.e. wholly inside the cabinet
	# back wall's span with no shared face plane — the panel must not surface in
	# front of the box's own interior, which reads through the window.
	_slab(Vector3(pw, ph, 0.018), Vector3(0.0, bot + ph * 0.5, 0.010),
			_surface(Color(0.35, 0.36, 0.33), 0.92, 0.0))
	_slab(Vector3(pw, 0.012, 0.030), Vector3(0.0, bot + ph - 0.022, 0.016),
			_surface(Color(0.09, 0.09, 0.09), 0.95, 0.0))
	var plate: MeshInstance3D = BakedText.make_panel_mesh(label_text,
			Color(0.60, 0.61, 0.62), Color(0.19, 0.20, 0.19), Vector2(0.20, 0.052))
	if plate:
		plate.position = Vector3(box_width * 0.5 + 0.15, box_height * 0.22, 0.021)
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plate)


## THE PROMISE LEFT TO ROT. Chalked paint (via _lv), rust weeping from the
## fixings down both flanks and the closed door, a grime line where the floor's
## dirt has climbed the box, and a service tag whose date has gone by. The
## identity claims the answer to the worst day is already waiting; here it isn't.
func _statute_lapse() -> void:
	var rust: StandardMaterial3D = _surface(Color(0.33, 0.17, 0.08), 1.0, 0.0)
	var grime: StandardMaterial3D = _surface(Color(0.20, 0.17, 0.14), 0.98, 0.0)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		for i in 3:
			var zz: float = box_depth * (0.22 + 0.26 * float(i))
			var hh: float = box_height * (0.34 + 0.16 * float(i % 2))
			_slab(Vector3(0.004, hh, 0.016),
					Vector3(s * (box_width * 0.5 + 0.003), box_height * 0.5 - hh * 0.5, zz), rust)
	# and down the door face, where a closed door still shows the years
	if not door_open:
		var pivot := get_node_or_null("DoorPivot")
		if pivot != null and pivot is Node3D:
			var dp: Node3D = pivot
			for i in 4:
				var hx: float = -box_width * (0.14 + 0.24 * float(i))
				var hh2: float = box_height * (0.30 + 0.18 * float(i % 2))
				_slab(Vector3(0.014, hh2, 0.004),
						Vector3(hx, box_height * 0.5 - hh2 * 0.5, DOOR_DEPTH + 0.004), rust, dp)
	# Kept below the door's bottom frame bar and above the box's own lowest face,
	# so it neither shows through the window nor becomes the new ground point.
	_slab(Vector3(box_width + 0.004, 0.048, box_depth * 0.96),
			Vector3(0.0, -box_height * 0.5 + 0.025, box_depth * 0.5), grime)
	# the tag
	var wire: StandardMaterial3D = _surface(Color(0.42, 0.42, 0.44), 0.5, 0.7)
	var tx: float = -box_width * 0.5 + 0.055
	_slab(Vector3(0.004, 0.05, 0.004), Vector3(tx, -0.055, _front_z() + 0.030), wire)
	var tag: MeshInstance3D = BakedText.make_panel_mesh("2019",
			Color(0.83, 0.79, 0.58), Color(0.31, 0.27, 0.18), Vector2(0.085, 0.055))
	if tag:
		tag.position = Vector3(tx, -0.108, _front_z() + 0.032)
		tag.rotation_degrees = Vector3(0.0, 0.0, -9.0)
		tag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tag)


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
