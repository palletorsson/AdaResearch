extends Node3D
class_name MetalStorageCabinet

# @identity
# essence: a tall two-door metal storage cabinet — the institutional / lab-supply vocabulary for "everything this room needs is INSIDE, behind these doors, and the doors are CLOSED by default". A WHITE-faced double-door carcass on a darker GREY steel body, a slim recessed top lip, two small grey loop handles meeting at the centre seam, and a column of hinge dots running down each outer vertical edge. The room's quiet confession that supplies are FINITE, ORGANISED, and PUT AWAY — order made architectural.
# desire: every working room wants its consumables, reagents, tools and binders to have a SINGLE PLACE that is shut, labelled by silhouette, and stackable against a wall. The cabinet wants to read as CONTAINED-CAPACITY — a vertical volume whose whole job is to be openable. The state it expresses is the room's posture toward STORED vs IN-USE: doors flat-white = stocked and tidy, doors swung wide = mid-task, shelves exposed, somebody is reaching in.
# critical_parameter: doors_open_amount — 0.0 reads as "stocked / secured / nothing to see" (a flat white face, two handles, the reference), rising toward 1.0 each door swings outward on its OUTER vertical-edge hinge until the interior shelves are revealed and the cabinet becomes a depth instead of a wall. Same object, two rooms: one is a tidy supply station, the other is a workbench annex with its guts on display.
# triggers: _ready() builds the grey carcass (back + sides + top + bottom + slim top lip) + interior shelves + door(s) (flat closed OR swung outward on the outer edge by doors_open_amount) + centre-seam handles + hinge dot columns from exports; apply_grid_config rebuilds
# emerges: doors_open_amount 0 = "fully stocked, leave it"; doors_open_amount ~0.9 + shelf_count 4 = "deep inventory, actively rifled through"; door_count 1 = a tall single-door LOCKER, personal not communal; body_color and door_color both grey = a hard institutional locker bank; more shelves = finer-grained storage, fewer = bulky equipment. The width / height / door_count combination tells the player what KIND of stuff the room hoards.
# needs: a freestanding rectangular carcass sitting on the floor (origin at base centre) [present]; grey body — sides, top, bottom, back — distinct from the white door face [present]; a slim recessed top lip across the top front [present]; interior horizontal shelves visible when open [present]; one or two doors meeting at a centre vertical seam, each hinged on its OUTER edge and swinging outward by doors_open_amount [present]; small grey loop handles at the centre seam (one per door) [present]; hinge dot columns down the outer vertical edges [present]
# relationships: sibling to crate (both are CONTAINERS, but the crate is one-shot and stackable cargo while the cabinet is fixed, refillable room-furniture); cousin to fume_hood and glove_box (all three are lab carcasses with a front that opens, but the cabinet STORES where they ENCLOSE A PROCESS); peer to clamp_stand and abacus (the small tools the cabinet keeps when they are not on the bench — it presumes a room full of things that get put away)
# truth: a storage cabinet is not just a box with doors. It is the room's INVENTORY MADE VERTICAL — every shelf is a decision about what deserves to be kept and within reach, every closed door is the claim that the room is in order, and the act of opening it is the room admitting it is mid-use. The cabinet makes capacity decidable: not everything fits, so somebody chose what stays inside.

## A tall freestanding two-door metal storage / office cabinet.
##
## Built procedurally from DNA exports. Origin is the BASE CENTER on the
## floor — y=0 at the cabinet bottom, centred in X and Z. Front doors and
## handles face +Z; the grey body (sides/top/bottom/back) wraps a hollow
## front housing horizontal shelves. With door_count=2 two half-width
## doors meet at the centre seam and each hinges on its OUTER vertical
## edge, swinging outward by doors_open_amount (left door negative, right
## door positive). With door_count=1 a single full-width door hinges on
## the left edge. doors_open_amount=0 is the closed reference look.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var cabinet_width: float = 0.9
@export var cabinet_height: float = 1.8
@export var cabinet_depth: float = 0.45

@export_group("Doors")
@export_range(1, 2, 1) var door_count: int = 2
@export_range(0.0, 1.0, 0.01) var doors_open_amount: float = 0.0

@export_group("Color")
@export var body_color: Color = Color(0.42, 0.45, 0.49)
@export var door_color: Color = Color(0.90, 0.91, 0.92)
@export var handle_color: Color = Color(0.55, 0.57, 0.60)

@export_group("Interior")
@export_range(0, 8, 1) var shelf_count: int = 3

@export_group("Detail")
@export var show_hinges: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const WALL_THICKNESS: float = 0.02       # thickness of body panels (sides/top/bottom/back)
const DOOR_THICKNESS: float = 0.018      # thickness of a door slab
const DOOR_GAP: float = 0.004            # tiny gap so doors clear the carcass front
const SEAM_GAP: float = 0.004            # gap at the centre seam between the two doors
const TOP_LIP_HEIGHT: float = 0.045      # height of the slim recessed top lip
const TOP_LIP_INSET: float = 0.012       # how far the top lip is recessed from the front
const SHELF_THICKNESS: float = 0.015     # interior shelf slab thickness
const SHELF_MARGIN_Y: float = 0.06       # keep shelves off the very top/bottom
const DOOR_OPEN_MAX_DEG: float = 100.0   # how far a door swings at doors_open_amount = 1
const HANDLE_LOOP_HEIGHT: float = 0.11   # vertical span of the loop handle
const HANDLE_LOOP_WIDTH: float = 0.035   # how far the loop stands off the door
const HANDLE_BAR_THICKNESS: float = 0.012
const HINGE_DOT_RADIUS: float = 0.012
const HINGE_DOT_LENGTH: float = 0.02
const HINGE_DOT_COUNT: int = 3           # hinge dots per outer edge

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_cabinet()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_cabinet()


func _read_metadata_overrides() -> void:
	if has_meta("config_cabinet_width"):
		cabinet_width = float(str(get_meta("config_cabinet_width")))
	if has_meta("config_cabinet_height"):
		cabinet_height = float(str(get_meta("config_cabinet_height")))
	if has_meta("config_cabinet_depth"):
		cabinet_depth = float(str(get_meta("config_cabinet_depth")))
	if has_meta("config_door_count"):
		door_count = int(str(get_meta("config_door_count")))
	if has_meta("config_doors_open_amount"):
		doors_open_amount = float(str(get_meta("config_doors_open_amount")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_door_color"):
		door_color = _parse_color(str(get_meta("config_door_color")), door_color)
	if has_meta("config_handle_color"):
		handle_color = _parse_color(str(get_meta("config_handle_color")), handle_color)
	if has_meta("config_shelf_count"):
		shelf_count = int(str(get_meta("config_shelf_count")))
	if has_meta("config_show_hinges"):
		var sv := str(get_meta("config_show_hinges")).to_lower()
		show_hinges = sv in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_cabinet() -> void:
	_built = true
	_build_carcass()
	_build_top_lip()
	_build_shelves()
	_build_doors()
	_build_hinges()


func _body_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.5
	mat.metallic = 0.55
	return mat


func _front_z() -> float:
	# Front plane of the carcass in local space (origin centred in Z).
	return cabinet_depth * 0.5


func _build_carcass() -> void:
	# Grey body: back + two sides + top + bottom, leaving a hollow front for
	# the doors and shelves. Origin is base-centre on the floor, so the body
	# spans y in [0, cabinet_height], x in [-w/2, w/2], z in [-d/2, d/2].
	var root := Node3D.new()
	root.name = "Carcass"
	add_child(root)
	var mat := _body_material()

	var half_h: float = cabinet_height * 0.5

	# Back panel (faces +Z, sits at the rear).
	var back := MeshInstance3D.new()
	back.name = "Back"
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(cabinet_width, cabinet_height, WALL_THICKNESS)
	back.mesh = back_mesh
	back.material_override = mat
	back.position = Vector3(0.0, half_h, -cabinet_depth * 0.5 + WALL_THICKNESS * 0.5)
	root.add_child(back)

	# Left side panel.
	var left := MeshInstance3D.new()
	left.name = "SideLeft"
	var left_mesh := BoxMesh.new()
	left_mesh.size = Vector3(WALL_THICKNESS, cabinet_height, cabinet_depth)
	left.mesh = left_mesh
	left.material_override = mat
	left.position = Vector3(-cabinet_width * 0.5 + WALL_THICKNESS * 0.5, half_h, 0.0)
	root.add_child(left)

	# Right side panel.
	var right := MeshInstance3D.new()
	right.name = "SideRight"
	var right_mesh := BoxMesh.new()
	right_mesh.size = Vector3(WALL_THICKNESS, cabinet_height, cabinet_depth)
	right.mesh = right_mesh
	right.material_override = mat
	right.position = Vector3(cabinet_width * 0.5 - WALL_THICKNESS * 0.5, half_h, 0.0)
	root.add_child(right)

	# Top panel.
	var top := MeshInstance3D.new()
	top.name = "Top"
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(cabinet_width, WALL_THICKNESS, cabinet_depth)
	top.mesh = top_mesh
	top.material_override = mat
	top.position = Vector3(0.0, cabinet_height - WALL_THICKNESS * 0.5, 0.0)
	root.add_child(top)

	# Bottom panel.
	var bottom := MeshInstance3D.new()
	bottom.name = "Bottom"
	var bottom_mesh := BoxMesh.new()
	bottom_mesh.size = Vector3(cabinet_width, WALL_THICKNESS, cabinet_depth)
	bottom.mesh = bottom_mesh
	bottom.material_override = mat
	bottom.position = Vector3(0.0, WALL_THICKNESS * 0.5, 0.0)
	root.add_child(bottom)


func _build_top_lip() -> void:
	# Slim recessed lip across the top front of the cabinet — a thin grey band
	# set just below the top, inset from the front face.
	var lip := MeshInstance3D.new()
	lip.name = "TopLip"
	var lm := BoxMesh.new()
	lm.size = Vector3(cabinet_width - WALL_THICKNESS * 2.0, TOP_LIP_HEIGHT, WALL_THICKNESS)
	lip.mesh = lm
	var mat := _body_material()
	mat.metallic = 0.4
	lip.material_override = mat
	var y: float = cabinet_height - WALL_THICKNESS - TOP_LIP_HEIGHT * 0.5
	var z: float = _front_z() - TOP_LIP_INSET - WALL_THICKNESS * 0.5
	lip.position = Vector3(0.0, y, z)
	add_child(lip)


func _build_shelves() -> void:
	# Interior horizontal shelves, evenly spaced between top and bottom. They
	# live inside the carcass and become visible when the doors swing open.
	if shelf_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Shelves"
	add_child(root)

	var mat := _body_material()
	mat.metallic = 0.35

	var inner_w: float = cabinet_width - WALL_THICKNESS * 2.0
	var inner_d: float = cabinet_depth - WALL_THICKNESS * 2.0
	var low_y: float = WALL_THICKNESS + SHELF_MARGIN_Y
	var high_y: float = cabinet_height - WALL_THICKNESS - SHELF_MARGIN_Y
	var span: float = high_y - low_y
	var pitch: float = span / float(shelf_count + 1)

	for i in range(shelf_count):
		var shelf := MeshInstance3D.new()
		shelf.name = "Shelf_%d" % i
		var sm := BoxMesh.new()
		sm.size = Vector3(inner_w, SHELF_THICKNESS, inner_d)
		shelf.mesh = sm
		shelf.material_override = mat
		var y: float = low_y + pitch * float(i + 1)
		shelf.position = Vector3(0.0, y, 0.0)
		root.add_child(shelf)


func _build_doors() -> void:
	# Front door(s). For door_count == 2 two half-width doors meet at the centre
	# seam, each hinged on its OUTER vertical edge; the left door swings to -Z/+X
	# outward (negative angle) and the right door swings outward (positive angle).
	# For door_count == 1 a single full-width door hinges on the left edge.
	var root := Node3D.new()
	root.name = "Doors"
	add_child(root)

	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = door_color
	door_mat.roughness = 0.45
	door_mat.metallic = 0.4

	var front_z: float = _front_z() + DOOR_GAP
	var open_rad: float = deg_to_rad(DOOR_OPEN_MAX_DEG) * clamp(doors_open_amount, 0.0, 1.0)

	if door_count <= 1:
		# Single full-width door hinged on the LEFT outer edge.
		var door_w: float = cabinet_width - DOOR_GAP * 2.0
		_make_door_leaf(root, "DoorSingle", door_mat,
			Vector3(-cabinet_width * 0.5 + DOOR_GAP, cabinet_height * 0.5, front_z),
			door_w, -open_rad, true)
	else:
		# Two half-width doors meeting at the centre seam.
		var leaf_w: float = (cabinet_width - DOOR_GAP * 2.0 - SEAM_GAP) * 0.5
		# Left door — hinged on the LEFT outer edge, opens outward (negative angle).
		_make_door_leaf(root, "DoorLeft", door_mat,
			Vector3(-cabinet_width * 0.5 + DOOR_GAP, cabinet_height * 0.5, front_z),
			leaf_w, -open_rad, true)
		# Right door — hinged on the RIGHT outer edge, opens outward (positive angle).
		_make_door_leaf(root, "DoorRight", door_mat,
			Vector3(cabinet_width * 0.5 - DOOR_GAP, cabinet_height * 0.5, front_z),
			leaf_w, open_rad, false)


func _make_door_leaf(parent: Node3D, leaf_name: String, door_mat: StandardMaterial3D, hinge_pos: Vector3, leaf_w: float, angle: float, hinge_on_left: bool) -> void:
	# Build one door leaf as a pivot at its hinge axis plus a slab + handle.
	# hinge_on_left == true  → pivot at left edge, slab extends in +X.
	# hinge_on_left == false → pivot at right edge, slab extends in -X.
	var pivot := Node3D.new()
	pivot.name = "%sPivot" % leaf_name
	pivot.position = hinge_pos
	pivot.rotation = Vector3(0.0, angle, 0.0)
	parent.add_child(pivot)

	var dir: float = 1.0 if hinge_on_left else -1.0

	var door := MeshInstance3D.new()
	door.name = leaf_name
	var dm := BoxMesh.new()
	dm.size = Vector3(leaf_w, cabinet_height - DOOR_GAP * 2.0, DOOR_THICKNESS)
	door.mesh = dm
	door.material_override = door_mat
	# Slab centre offset from the hinge edge by half its width (toward the seam).
	door.position = Vector3(dir * leaf_w * 0.5, 0.0, DOOR_THICKNESS * 0.5)
	pivot.add_child(door)

	# Loop handle near the seam edge of this leaf (the edge opposite the hinge).
	var handle_x: float = dir * (leaf_w - 0.045)
	_make_loop_handle(pivot, "%sHandle" % leaf_name, Vector3(handle_x, 0.0, DOOR_THICKNESS))


func _make_loop_handle(parent: Node3D, handle_name: String, base_pos: Vector3) -> void:
	# A small grey U / loop handle standing off the door face in +Z. Built from
	# three thin bars: top arm, bottom arm, and the outer grab bar joining them.
	var root := Node3D.new()
	root.name = handle_name
	root.position = base_pos
	parent.add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = handle_color
	mat.roughness = 0.3
	mat.metallic = 0.85

	var half_span: float = HANDLE_LOOP_HEIGHT * 0.5
	var stand: float = HANDLE_LOOP_WIDTH

	# Top arm (runs in +Z from the door).
	var top_arm := MeshInstance3D.new()
	top_arm.name = "TopArm"
	var tm := BoxMesh.new()
	tm.size = Vector3(HANDLE_BAR_THICKNESS, HANDLE_BAR_THICKNESS, stand)
	top_arm.mesh = tm
	top_arm.material_override = mat
	top_arm.position = Vector3(0.0, half_span, stand * 0.5)
	root.add_child(top_arm)

	# Bottom arm.
	var bottom_arm := MeshInstance3D.new()
	bottom_arm.name = "BottomArm"
	var bm := BoxMesh.new()
	bm.size = Vector3(HANDLE_BAR_THICKNESS, HANDLE_BAR_THICKNESS, stand)
	bottom_arm.mesh = bm
	bottom_arm.material_override = mat
	bottom_arm.position = Vector3(0.0, -half_span, stand * 0.5)
	root.add_child(bottom_arm)

	# Outer grab bar joining the two arms (vertical, at the standoff distance).
	var grab := MeshInstance3D.new()
	grab.name = "GrabBar"
	var gm := BoxMesh.new()
	gm.size = Vector3(HANDLE_BAR_THICKNESS, HANDLE_LOOP_HEIGHT, HANDLE_BAR_THICKNESS)
	grab.mesh = gm
	grab.material_override = mat
	grab.position = Vector3(0.0, 0.0, stand)
	root.add_child(grab)


func _build_hinges() -> void:
	# Small grey hinge dots running down each OUTER vertical edge of the front.
	if not show_hinges:
		return
	var root := Node3D.new()
	root.name = "Hinges"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = handle_color
	mat.roughness = 0.4
	mat.metallic = 0.7

	var low_y: float = SHELF_MARGIN_Y * 1.5
	var high_y: float = cabinet_height - SHELF_MARGIN_Y * 1.5
	var z: float = _front_z() + HINGE_DOT_RADIUS * 0.5

	# Outer edge x positions: left edge always; right edge always (both doors and
	# the single locker hinge on outer edges, so dots read on both verticals).
	var edges: Array = [-cabinet_width * 0.5 + WALL_THICKNESS * 0.5, cabinet_width * 0.5 - WALL_THICKNESS * 0.5]

	var idx: int = 0
	for ex in edges:
		for i in range(HINGE_DOT_COUNT):
			var dot := MeshInstance3D.new()
			dot.name = "Hinge_%d" % idx
			idx += 1
			var cm := CylinderMesh.new()
			cm.top_radius = HINGE_DOT_RADIUS
			cm.bottom_radius = HINGE_DOT_RADIUS
			cm.height = HINGE_DOT_LENGTH
			dot.mesh = cm
			dot.material_override = mat
			dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Cylinder default axis = +Y; lay along +Z so the dot pokes forward.
			dot.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			var t: float = 0.0 if HINGE_DOT_COUNT <= 1 else float(i) / float(HINGE_DOT_COUNT - 1)
			var y: float = lerp(low_y, high_y, t)
			dot.position = Vector3(ex, y, z)
			root.add_child(dot)


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
