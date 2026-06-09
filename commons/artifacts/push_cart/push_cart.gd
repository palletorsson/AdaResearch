extends Node3D
class_name PushCart

# @identity
# essence: a stainless-steel 2-tier medical / lab utility cart. Two flat rectangular shelves (top + bottom) joined by 4 vertical tubular posts, a thin guard rail bent into a U around each shelf, a single drawer slung under the top shelf, a curved push handle rising off one short end, and 4 swivel caster wheels at the feet. The architectural form of WORK THAT MOVES
# desire: every lab and every ward wants its tools to follow it — sutures to the bedside, beakers to the bench, instruments to the table. The cart wants to be the horizontal surface that does not stay put, the shelf with wheels, the bench that obeys a push. It wants to carry the in-between
# critical_parameter: show_drawer — true reads as A STOCKED, IN-USE CART (something is stored, the cart has a job). false reads as A BARE TRANSPORT FRAME (two open shelves, awaiting load). Same skeleton, two intensities of READINESS
# triggers: _ready() builds two shelves + 4 posts + guard rails + optional drawer + push handle + 4 casters; apply_grid_config rebuilds from metadata overrides
# emerges: drawer on = "this cart belongs to someone, it carries their kit". drawer off = "a clean transport frame, ready for whatever is next". Same script, two narratives of occupancy
# needs: top shelf slab + bottom shelf slab [present]; 4 vertical corner posts [present]; U-shaped guard rail per shelf [present]; drawer box + tube handle under top shelf [present]; curved push handle on one end [present]; 4 swivel casters (fork + rubber tyre) at the feet [present]
# relationships: peer to large_table (the table is the bench that stays; the cart is the bench that travels — both are HORIZONTAL SURFACES FOR WORK). Cousin to iv_stand (both roll to the patient; the stand holds the drip, the cart holds the kit). Sibling to crate (both carry — the crate stacks and stores, the cart wheels and serves). The lab's admission that work happens wherever the body goes
# truth: a push cart is the architectural form of THE MOBILE SHELF. Without it, every tool waits at its station and the body walks back and forth. WITH it, the surface follows the work — the cart is the lab's refusal to make the hands return to the bench

## A stainless-steel 2-tier medical / lab utility cart.
##
## Built procedurally. Origin is at the floor, centered under the frame —
## the caster tyres touch y=0, the frame extends in +Y. The cart's long
## axis is X, its short axis (and depth) is Z; the push handle rises off
## the -X short end. Two flat shelves are joined by 4 vertical corner
## posts; each shelf wears a thin U-shaped guard rail open toward the
## handle end; a drawer hangs under the top shelf when show_drawer is
## true; 4 swivel casters sit under the bottom shelf corners.

# -- DNA -----------------------------------------------------------------

@export_group("Frame")
## Overall length along X (long axis), in meters.
@export var cart_length: float = 0.80
## Overall width / depth along Z (short axis), in meters.
@export var cart_width: float = 0.45
## Height of the TOP shelf surface above the floor, in meters.
@export var top_shelf_height: float = 0.75
## Height of the BOTTOM shelf surface above the floor, in meters.
@export var bottom_shelf_height: float = 0.18

@export_group("Shelves")
@export var shelf_thickness: float = 0.022
@export var steel_color: Color = Color(0.78, 0.80, 0.83)

@export_group("Drawer")
## When true, render a drawer slung under the top shelf.
@export var show_drawer: bool = true
@export var drawer_color: Color = Color(0.70, 0.72, 0.76)

@export_group("Handle")
## Height of the push-handle crossbar above the floor, in meters.
@export var handle_height: float = 0.95

@export_group("Wheels")
@export var tyre_color: Color = Color(0.10, 0.10, 0.12)

# -- Constants -----------------------------------------------------------

const POST_RADIUS: float = 0.010
const RAIL_RADIUS: float = 0.006
const RAIL_LIFT: float = 0.045              # rail height above the shelf surface
const RAIL_INSET: float = 0.020             # rail inset from the shelf edge
const SEG_CYL: int = 12                     # radial segments for tubes/posts
const SEG_TYRE: int = 14

const DRAWER_HEIGHT: float = 0.10
const DRAWER_INSET: float = 0.035           # drawer inset from shelf footprint
const DRAWER_FACE_THICKNESS: float = 0.012
const DRAWER_HANDLE_RADIUS: float = 0.006
const DRAWER_HANDLE_SPAN_FACTOR: float = 0.45   # vs drawer length

const HANDLE_POST_RADIUS: float = 0.009
const HANDLE_CROSSBAR_RADIUS: float = 0.010
const HANDLE_REACH: float = 0.06            # how far the handle extends past the -X end

const CASTER_FORK_HEIGHT: float = 0.045
const CASTER_FORK_RADIUS: float = 0.009
const TYRE_RADIUS: float = 0.035
const TYRE_THICKNESS: float = 0.022
const CASTER_INSET: float = 0.06            # caster inset from the cart footprint corner

# -- Internal state ------------------------------------------------------

var _built: bool = false
var _steel_mat: StandardMaterial3D = null
var _drawer_mat: StandardMaterial3D = null
var _tyre_mat: StandardMaterial3D = null

# -- Lifecycle -----------------------------------------------------------

func _ready() -> void:
	_read_metadata_overrides()
	_build_cart()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_cart()


func _read_metadata_overrides() -> void:
	if has_meta("config_cart_length"):
		cart_length = float(str(get_meta("config_cart_length")))
	if has_meta("config_cart_width"):
		cart_width = float(str(get_meta("config_cart_width")))
	if has_meta("config_top_shelf_height"):
		top_shelf_height = float(str(get_meta("config_top_shelf_height")))
	if has_meta("config_bottom_shelf_height"):
		bottom_shelf_height = float(str(get_meta("config_bottom_shelf_height")))
	if has_meta("config_shelf_thickness"):
		shelf_thickness = float(str(get_meta("config_shelf_thickness")))
	if has_meta("config_steel_color"):
		steel_color = _parse_color(str(get_meta("config_steel_color")), steel_color)
	if has_meta("config_drawer_color"):
		drawer_color = _parse_color(str(get_meta("config_drawer_color")), drawer_color)
	if has_meta("config_tyre_color"):
		tyre_color = _parse_color(str(get_meta("config_tyre_color")), tyre_color)
	if has_meta("config_handle_height"):
		handle_height = float(str(get_meta("config_handle_height")))
	if has_meta("config_show_drawer"):
		var d: String = str(get_meta("config_show_drawer")).to_lower()
		show_drawer = d in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# -- Build ---------------------------------------------------------------

func _build_cart() -> void:
	_built = true
	_make_materials()

	# Clamp the two shelf heights so the bottom is always below the top,
	# both above the floor, with room for casters underneath.
	var caster_clear: float = CASTER_FORK_HEIGHT + TYRE_RADIUS * 2.0
	var bottom_y: float = max(bottom_shelf_height, caster_clear + shelf_thickness)
	var top_y: float = max(top_shelf_height, bottom_y + 0.15)

	_build_shelf(top_y, "TopShelf")
	_build_shelf(bottom_y, "BottomShelf")
	_build_posts(bottom_y, top_y)
	_build_guard_rail(top_y)
	_build_guard_rail(bottom_y)
	if show_drawer:
		_build_drawer(top_y)
	_build_push_handle(top_y)
	_build_casters(bottom_y)


func _make_materials() -> void:
	_steel_mat = StandardMaterial3D.new()
	_steel_mat.albedo_color = steel_color
	_steel_mat.metallic = 0.80
	_steel_mat.roughness = 0.35

	_drawer_mat = StandardMaterial3D.new()
	_drawer_mat.albedo_color = drawer_color
	_drawer_mat.metallic = 0.70
	_drawer_mat.roughness = 0.42

	_tyre_mat = StandardMaterial3D.new()
	_tyre_mat.albedo_color = tyre_color
	_tyre_mat.metallic = 0.05
	_tyre_mat.roughness = 0.85


# A flat rectangular shelf slab, centered on the cart footprint at height y
# (y is the TOP surface of the slab).
func _build_shelf(y: float, node_name: String) -> void:
	var shelf := MeshInstance3D.new()
	shelf.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cart_length, shelf_thickness, cart_width)
	shelf.mesh = mesh
	shelf.material_override = _steel_mat
	shelf.position = Vector3(0.0, y - shelf_thickness * 0.5, 0.0)
	add_child(shelf)


# 4 vertical tubular posts at the inset corners, spanning bottom->top shelf.
func _build_posts(bottom_y: float, top_y: float) -> void:
	var px: float = cart_length * 0.5 - RAIL_INSET - POST_RADIUS
	var pz: float = cart_width * 0.5 - RAIL_INSET - POST_RADIUS
	var span: float = top_y - (bottom_y - shelf_thickness)
	if span <= 0.0:
		return
	var center_y: float = (bottom_y - shelf_thickness) + span * 0.5
	var corners := [
		Vector2(px, pz), Vector2(-px, pz),
		Vector2(px, -pz), Vector2(-px, -pz),
	]
	for i in range(corners.size()):
		var post := MeshInstance3D.new()
		post.name = "Post_%d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = POST_RADIUS
		mesh.bottom_radius = POST_RADIUS
		mesh.height = span
		mesh.radial_segments = SEG_CYL
		post.mesh = mesh
		post.material_override = _steel_mat
		post.position = Vector3(corners[i].x, center_y, corners[i].y)
		add_child(post)


# A thin U-shaped guard rail around a shelf at surface height shelf_y.
# The rail sits RAIL_LIFT above the surface and wraps 3 sides, leaving the
# -X (handle) end open. Built from 3 straight tube segments + 2 corner posts.
func _build_guard_rail(shelf_y: float) -> void:
	var rail_y: float = shelf_y + RAIL_LIFT
	var hx: float = cart_length * 0.5 - RAIL_INSET
	var hz: float = cart_width * 0.5 - RAIL_INSET
	var rail_root := Node3D.new()
	rail_root.name = "GuardRail"
	rail_root.position = Vector3(0.0, rail_y, 0.0)
	add_child(rail_root)

	# +Z side rail (runs along X, open end excluded -> spans from -hx to +hx).
	_add_rail_tube(rail_root, Vector3(0.0, 0.0, hz), Vector3(1.0, 0.0, 0.0), cart_length - RAIL_INSET * 2.0)
	# -Z side rail.
	_add_rail_tube(rail_root, Vector3(0.0, 0.0, -hz), Vector3(1.0, 0.0, 0.0), cart_length - RAIL_INSET * 2.0)
	# +X end rail (the far short end, runs along Z).
	_add_rail_tube(rail_root, Vector3(hx, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), cart_width - RAIL_INSET * 2.0)

	# Two short vertical stubs connecting the rail down to the shelf surface
	# at the open (-X) end corners, so the U reads as a rail not a floating bar.
	for sz in [hz, -hz]:
		var stub := MeshInstance3D.new()
		stub.name = "RailStub"
		var smesh := CylinderMesh.new()
		smesh.top_radius = RAIL_RADIUS
		smesh.bottom_radius = RAIL_RADIUS
		smesh.height = RAIL_LIFT
		smesh.radial_segments = SEG_CYL
		stub.mesh = smesh
		stub.material_override = _steel_mat
		stub.position = Vector3(-hx, -RAIL_LIFT * 0.5, sz)
		rail_root.add_child(stub)


# Add one horizontal rail tube of given length, centered at local_pos,
# running along the given axis (X or Z). Axis is a normalized direction.
func _add_rail_tube(parent: Node3D, local_pos: Vector3, axis: Vector3, length: float) -> void:
	var tube := MeshInstance3D.new()
	tube.name = "Rail"
	var mesh := CylinderMesh.new()
	mesh.top_radius = RAIL_RADIUS
	mesh.bottom_radius = RAIL_RADIUS
	mesh.height = length
	mesh.radial_segments = SEG_CYL
	tube.mesh = mesh
	tube.material_override = _steel_mat
	tube.position = local_pos
	# CylinderMesh runs along local +Y. Rotate to align with the wanted axis.
	if axis.x > 0.5:
		tube.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))   # +Y -> +X
	elif axis.z > 0.5:
		tube.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)   # +Y -> +Z
	parent.add_child(tube)


# A drawer box slung under the top shelf: a body + a front face + a tube handle.
func _build_drawer(top_y: float) -> void:
	var drawer_root := Node3D.new()
	drawer_root.name = "Drawer"
	add_child(drawer_root)

	var dl: float = cart_length - DRAWER_INSET * 2.0
	var dw: float = cart_width - DRAWER_INSET * 2.0
	var top_of_drawer: float = top_y - shelf_thickness
	var center_y: float = top_of_drawer - DRAWER_HEIGHT * 0.5

	# Drawer body.
	var body := MeshInstance3D.new()
	body.name = "DrawerBody"
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(dl, DRAWER_HEIGHT, dw)
	body.mesh = bmesh
	body.material_override = _drawer_mat
	body.position = Vector3(0.0, center_y, 0.0)
	drawer_root.add_child(body)

	# Front face (the +X short end of the cart reads as the drawer front).
	var face := MeshInstance3D.new()
	face.name = "DrawerFace"
	var fmesh := BoxMesh.new()
	fmesh.size = Vector3(DRAWER_FACE_THICKNESS, DRAWER_HEIGHT * 1.04, dw * 1.02)
	face.mesh = fmesh
	face.material_override = _steel_mat
	var face_x: float = dl * 0.5 + DRAWER_FACE_THICKNESS * 0.5
	face.position = Vector3(face_x, center_y, 0.0)
	drawer_root.add_child(face)

	# Tube handle on the drawer front (runs along Z), held off the face by 2 stubs.
	var handle_span: float = dw * DRAWER_HANDLE_SPAN_FACTOR
	var handle_x: float = face_x + DRAWER_FACE_THICKNESS * 0.5 + 0.018
	var bar := MeshInstance3D.new()
	bar.name = "DrawerHandleBar"
	var hmesh := CylinderMesh.new()
	hmesh.top_radius = DRAWER_HANDLE_RADIUS
	hmesh.bottom_radius = DRAWER_HANDLE_RADIUS
	hmesh.height = handle_span
	hmesh.radial_segments = SEG_CYL
	bar.mesh = hmesh
	bar.material_override = _steel_mat
	bar.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)   # align along Z
	bar.position = Vector3(handle_x, center_y, 0.0)
	drawer_root.add_child(bar)

	for sz in [handle_span * 0.5, -handle_span * 0.5]:
		var stub := MeshInstance3D.new()
		stub.name = "DrawerHandleStub"
		var smesh := CylinderMesh.new()
		smesh.top_radius = DRAWER_HANDLE_RADIUS * 0.8
		smesh.bottom_radius = DRAWER_HANDLE_RADIUS * 0.8
		smesh.height = 0.018
		smesh.radial_segments = SEG_CYL
		stub.mesh = smesh
		stub.material_override = _steel_mat
		stub.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))   # align along X
		stub.position = Vector3(face_x + DRAWER_FACE_THICKNESS * 0.5 + 0.009, center_y, sz)
		drawer_root.add_child(stub)


# A curved tubular push handle rising off the -X short end: two vertical
# posts up from the top shelf, joined by a crossbar, with two quarter-arc
# corner pieces approximated by short angled tubes for a curved look.
func _build_push_handle(top_y: float) -> void:
	var handle_root := Node3D.new()
	handle_root.name = "PushHandle"
	add_child(handle_root)

	var base_x: float = -cart_length * 0.5 + RAIL_INSET
	var reach_x: float = base_x - HANDLE_REACH
	var hz: float = cart_width * 0.5 - RAIL_INSET
	var crossbar_y: float = handle_height
	var post_bottom: float = top_y
	var post_span: float = crossbar_y - post_bottom
	if post_span <= 0.0:
		post_span = 0.02
	var post_center_y: float = post_bottom + post_span * 0.5

	# Two vertical posts.
	for sz in [hz, -hz]:
		var post := MeshInstance3D.new()
		post.name = "HandlePost"
		var pmesh := CylinderMesh.new()
		pmesh.top_radius = HANDLE_POST_RADIUS
		pmesh.bottom_radius = HANDLE_POST_RADIUS
		pmesh.height = post_span
		pmesh.radial_segments = SEG_CYL
		post.mesh = pmesh
		post.material_override = _steel_mat
		post.position = Vector3(reach_x, post_center_y, sz)
		handle_root.add_child(post)

	# Top crossbar joining the two posts (runs along Z).
	var bar := MeshInstance3D.new()
	bar.name = "HandleCrossbar"
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = HANDLE_CROSSBAR_RADIUS
	bmesh.bottom_radius = HANDLE_CROSSBAR_RADIUS
	bmesh.height = cart_width - RAIL_INSET * 2.0
	bmesh.radial_segments = SEG_CYL
	bar.mesh = bmesh
	bar.material_override = _steel_mat
	bar.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	bar.position = Vector3(reach_x, crossbar_y, 0.0)
	handle_root.add_child(bar)

	# Two short angled tubes giving the handle a curved (swept-back) corner
	# where each post meets the crossbar.
	for sz in [hz, -hz]:
		var arc := MeshInstance3D.new()
		arc.name = "HandleArc"
		var amesh := CylinderMesh.new()
		amesh.top_radius = HANDLE_POST_RADIUS
		amesh.bottom_radius = HANDLE_POST_RADIUS
		amesh.height = HANDLE_REACH * 1.2
		amesh.radial_segments = SEG_CYL
		arc.mesh = amesh
		arc.material_override = _steel_mat
		# Diagonal bridging the gap between the top-shelf base and the reach post.
		arc.position = Vector3((base_x + reach_x) * 0.5, post_bottom + 0.01, sz)
		arc.rotation = Vector3(0.0, 0.0, deg_to_rad(50.0))
		handle_root.add_child(arc)


# 4 swivel casters under the bottom shelf corners: a fork bracket (vertical
# stub) + a dark rubber tyre. Tyres touch the floor (y=0).
func _build_casters(bottom_y: float) -> void:
	var cx: float = cart_length * 0.5 - CASTER_INSET
	var cz: float = cart_width * 0.5 - CASTER_INSET
	var corners := [
		Vector2(cx, cz), Vector2(-cx, cz),
		Vector2(cx, -cz), Vector2(-cx, -cz),
	]
	var underside: float = bottom_y - shelf_thickness
	var tyre_center_y: float = TYRE_RADIUS
	var fork_bottom: float = tyre_center_y + TYRE_RADIUS
	var fork_span: float = max(underside - fork_bottom, 0.01)
	var fork_center_y: float = fork_bottom + fork_span * 0.5

	for i in range(corners.size()):
		var caster_root := Node3D.new()
		caster_root.name = "Caster_%d" % i
		caster_root.position = Vector3(corners[i].x, 0.0, corners[i].y)
		add_child(caster_root)

		# Fork bracket — a vertical steel stub from the shelf underside down.
		var fork := MeshInstance3D.new()
		fork.name = "Fork"
		var fmesh := CylinderMesh.new()
		fmesh.top_radius = CASTER_FORK_RADIUS
		fmesh.bottom_radius = CASTER_FORK_RADIUS
		fmesh.height = fork_span
		fmesh.radial_segments = SEG_CYL
		fork.mesh = fmesh
		fork.material_override = _steel_mat
		fork.position = Vector3(0.0, fork_center_y, 0.0)
		caster_root.add_child(fork)

		# Tyre — a dark rubber cylinder lying on its side (axis along Z).
		var tyre := MeshInstance3D.new()
		tyre.name = "Tyre"
		var tmesh := CylinderMesh.new()
		tmesh.top_radius = TYRE_RADIUS
		tmesh.bottom_radius = TYRE_RADIUS
		tmesh.height = TYRE_THICKNESS
		tmesh.radial_segments = SEG_TYRE
		tyre.mesh = tmesh
		tyre.material_override = _tyre_mat
		tyre.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		tyre.position = Vector3(0.0, tyre_center_y, 0.0)
		caster_root.add_child(tyre)


# -- Helpers -------------------------------------------------------------

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
