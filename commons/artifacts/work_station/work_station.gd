extends Node3D
class_name WorkStation

# @identity
# essence: a lab / maker WORKBENCH — industrial maker vocabulary. A metal-framed bench: a flat brushed-steel WORKTOP at standing height with a couple of small inset controls and sockets on its front edge, a curved overhead HANDLE/GANTRY bar arching over the worktop, a tan CORKBOARD / pegboard BACK PANEL standing behind the surface (with a few pinned notes), side CABINETS flanking it — one dark, one white — a lower section with TWO front DRAWERS (tubular handles) and a base plinth. The architectural form of A PLACE PREPARED FOR WORK
# desire: every act of making wants a dedicated surface — a horizontal plane at the height of the hands, with tools at arm's reach above it and storage beneath it. The work station wants to be the architectural form of READINESS — the bench that says "bring the problem here, everything you need is within one turn of the body"
# critical_parameter: drawer_count — 0 reads as A DISPLAY SURFACE (no storage, a clean demonstration top). 2 reads as A WORKING BENCH (the everyday maker's station, tools stowed below). More reads as A HEAVY FABRICATION STATION (deep storage, a permanent installation). Same frame, three intensities of COMMITMENT-TO-THE-CRAFT
# triggers: _ready() builds plinth + lower cabinet + drawer_count drawer fronts + worktop slab + corkboard back panel + back frame + overhead gantry handle + two side panels + small edge controls; apply_grid_config rebuilds
# emerges: corkboard on + notes = "this bench is lived-in, ideas pinned where the hands can see them". corkboard off = "a fresh install, nothing decided yet". The gantry handle = "tools want to hang here, in the air above the work". Same script, several narratives of a maker's habitation
# needs: a base plinth box [present]; a lower cabinet with two drawer fronts + tubular handles [present]; a worktop slab at standing height [present]; a tan corkboard back panel with pinned notes [present]; a thin metal back frame [present]; a curved overhead gantry handle bar [present]; one dark + one white side panel flanking the worktop [present]; small edge controls + an emissive indicator [present]
# relationships: peer to large_table (the table is the bare horizontal substrate; the work station is the table EQUIPPED — storage, back panel, overhead reach). Sibling to clamp_stand (the stand suspends work in mid-air above a bench; the work station IS the bench that the stand stands on). Cousin to dna_workstation + fume_hood (all three are PLACES-OF-PROCEDURE — a surface, a back wall of information, a frame that says WORK HAPPENS HERE). The lab's confession that thinking has a posture and a height
# truth: a work station is the architectural form of THE HAND'S HORIZON. The worktop sets the height of attention; the corkboard sets the wall of memory; the drawers set the depth of preparation; the gantry sets the ceiling of reach. Together they draw a small room of WORK around a single standing body — the smallest complete world a maker needs

## A lab / maker workbench, built procedurally from DNA exports.
##
## Origin is at the FLOOR, centred on the bench footprint. Width runs along
## X, depth along Z (+Z is the front, where drawers and edge controls face),
## height runs up +Y. The worktop slab sits at `worktop_height`. The corkboard
## back panel stands at the -Z (back) edge. The overhead gantry handle arches
## over the worktop in +Y. Two side panels flank the worktop in ±X — the -X
## side is the dark cabinet, the +X side is the white cabinet.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Size")
## Overall bench footprint and standing-work height (metres).
@export var size: Vector3 = Vector3(1.4, 1.3, 0.6)
## Height of the top face of the worktop slab off the floor.
@export var worktop_height: float = 0.9

@export_group("Drawers")
## How many drawer fronts in the lower cabinet (0-4).
@export_range(0, 4) var drawer_count: int = 2

@export_group("Corkboard")
## When true, render the tan corkboard back panel with pinned notes.
@export var show_corkboard: bool = true

@export_group("Colors")
@export var steel_color: Color = Color(0.74, 0.76, 0.78)
@export var white_color: Color = Color(0.90, 0.91, 0.92)
@export var dark_color: Color = Color(0.16, 0.17, 0.19)
@export var cork_color: Color = Color(0.78, 0.62, 0.40)
@export var indicator_color: Color = Color(0.30, 0.95, 0.55)

# ── Constants ─────────────────────────────────────────────────────────

const WORKTOP_THICKNESS: float = 0.04
const PLINTH_HEIGHT: float = 0.06
const PLINTH_INSET: float = 0.04                 # plinth narrower than footprint per side
const SIDE_PANEL_THICKNESS: float = 0.03
const BACK_FRAME_THICKNESS: float = 0.02
const CORKBOARD_THICKNESS: float = 0.015
const CORKBOARD_HEIGHT: float = 0.40             # how tall the back panel rises above the worktop
const CORKBOARD_INSET: float = 0.06              # cork narrower than bench width per side
const DRAWER_GAP: float = 0.012                  # gap between/around drawer fronts
const DRAWER_FRONT_DEPTH: float = 0.02
const DRAWER_HANDLE_RADIUS: float = 0.008
const DRAWER_HANDLE_INSET: float = 0.10          # handle length inset from drawer edges
const GANTRY_RADIUS: float = 0.018
const GANTRY_CLEARANCE: float = 0.42             # how high the gantry arches over the worktop
const GANTRY_LEG_INSET: float = 0.12             # gantry legs inset from bench ends in X
const NOTE_SIZE: float = 0.07
const EDGE_CONTROL_SIZE: float = 0.035
const INDICATOR_SIZE: float = 0.018

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# Shared materials (built once per build pass).
var _steel_mat: StandardMaterial3D = null
var _white_mat: StandardMaterial3D = null
var _dark_mat: StandardMaterial3D = null
var _cork_mat: StandardMaterial3D = null
var _indicator_mat: StandardMaterial3D = null
var _note_mat: StandardMaterial3D = null

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_work_station()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_work_station()


func _read_metadata_overrides() -> void:
	if has_meta("config_size"):
		size = _parse_vec3(str(get_meta("config_size")), size)
	if has_meta("config_worktop_height"):
		worktop_height = float(str(get_meta("config_worktop_height")))
	if has_meta("config_drawer_count"):
		drawer_count = int(str(get_meta("config_drawer_count")))
	if has_meta("config_show_corkboard"):
		var c := str(get_meta("config_show_corkboard")).to_lower()
		show_corkboard = c in ["true", "1", "yes", "on"]
	if has_meta("config_steel_color"):
		steel_color = _parse_color(str(get_meta("config_steel_color")), steel_color)
	if has_meta("config_white_color"):
		white_color = _parse_color(str(get_meta("config_white_color")), white_color)
	if has_meta("config_dark_color"):
		dark_color = _parse_color(str(get_meta("config_dark_color")), dark_color)
	if has_meta("config_cork_color"):
		cork_color = _parse_color(str(get_meta("config_cork_color")), cork_color)
	if has_meta("config_indicator_color"):
		indicator_color = _parse_color(str(get_meta("config_indicator_color")), indicator_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Materials ─────────────────────────────────────────────────────────

func _build_materials() -> void:
	_steel_mat = StandardMaterial3D.new()
	_steel_mat.albedo_color = steel_color
	_steel_mat.metallic = 0.7
	_steel_mat.roughness = 0.4

	_white_mat = StandardMaterial3D.new()
	_white_mat.albedo_color = white_color
	_white_mat.metallic = 0.1
	_white_mat.roughness = 0.55

	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = dark_color
	_dark_mat.metallic = 0.35
	_dark_mat.roughness = 0.5

	_cork_mat = StandardMaterial3D.new()
	_cork_mat.albedo_color = cork_color
	_cork_mat.metallic = 0.0
	_cork_mat.roughness = 0.95

	_note_mat = StandardMaterial3D.new()
	_note_mat.albedo_color = Color(0.96, 0.95, 0.88)
	_note_mat.metallic = 0.0
	_note_mat.roughness = 0.85

	_indicator_mat = StandardMaterial3D.new()
	_indicator_mat.albedo_color = indicator_color
	_indicator_mat.emission_enabled = true
	_indicator_mat.emission = indicator_color
	_indicator_mat.emission_energy_multiplier = 1.8
	_indicator_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL


# ── Build ─────────────────────────────────────────────────────────────

func _build_work_station() -> void:
	_built = true
	_build_materials()
	_build_plinth()
	_build_lower_cabinet()
	_build_drawers()
	_build_worktop()
	_build_side_panels()
	_build_back_frame()
	if show_corkboard:
		_build_corkboard()
	_build_gantry()
	_build_edge_controls()


func _box(node_name: String, dims: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dims
	mi.mesh = mesh
	if mat != null:
		mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _build_plinth() -> void:
	var w: float = size.x - PLINTH_INSET * 2.0
	var d: float = size.z - PLINTH_INSET * 2.0
	_box("Plinth", Vector3(w, PLINTH_HEIGHT, d), Vector3(0.0, PLINTH_HEIGHT * 0.5, 0.0), _dark_mat)


func _build_lower_cabinet() -> void:
	# The cabinet box rises from the top of the plinth to just below the worktop.
	var cab_top: float = worktop_height - WORKTOP_THICKNESS
	var cab_height: float = cab_top - PLINTH_HEIGHT
	if cab_height <= 0.0:
		cab_height = 0.1
	var w: float = size.x
	var d: float = size.z
	var cy: float = PLINTH_HEIGHT + cab_height * 0.5
	_box("LowerCabinet", Vector3(w, cab_height, d), Vector3(0.0, cy, 0.0), _steel_mat)


func _build_drawers() -> void:
	if drawer_count <= 0:
		return
	var cab_top: float = worktop_height - WORKTOP_THICKNESS
	var cab_bottom: float = PLINTH_HEIGHT
	var stack_height: float = cab_top - cab_bottom
	if stack_height <= 0.0:
		return
	# Drawers occupy the central front face; leave a margin at each side.
	var front_w: float = size.x * 0.62
	var front_z: float = size.z * 0.5 + DRAWER_FRONT_DEPTH * 0.5
	var slot_h: float = (stack_height - DRAWER_GAP * float(drawer_count + 1)) / float(drawer_count)
	if slot_h <= 0.0:
		slot_h = stack_height / float(drawer_count)
	for i in range(drawer_count):
		var slot_bottom: float = cab_bottom + DRAWER_GAP * float(i + 1) + slot_h * float(i)
		var cy: float = slot_bottom + slot_h * 0.5
		var front := _box(
			"DrawerFront_%d" % i,
			Vector3(front_w, slot_h, DRAWER_FRONT_DEPTH),
			Vector3(0.0, cy, front_z),
			_white_mat
		)
		front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Tubular horizontal handle across the front of this drawer.
		var handle := MeshInstance3D.new()
		handle.name = "DrawerHandle_%d" % i
		var hmesh := CylinderMesh.new()
		hmesh.top_radius = DRAWER_HANDLE_RADIUS
		hmesh.bottom_radius = DRAWER_HANDLE_RADIUS
		hmesh.height = front_w - DRAWER_HANDLE_INSET * 2.0
		handle.mesh = hmesh
		handle.material_override = _steel_mat
		# Rotate the cylinder so its axis lies along X (default axis is Y).
		handle.rotation = Vector3(0.0, 0.0, PI * 0.5)
		handle.position = Vector3(
			0.0,
			cy + slot_h * 0.25,
			front_z + DRAWER_FRONT_DEPTH * 0.5 + DRAWER_HANDLE_RADIUS * 1.5
		)
		add_child(handle)


func _build_worktop() -> void:
	var cy: float = worktop_height - WORKTOP_THICKNESS * 0.5
	# Worktop slightly overhangs the cabinet front and ends.
	var w: float = size.x + 0.04
	var d: float = size.z + 0.04
	_box("Worktop", Vector3(w, WORKTOP_THICKNESS, d), Vector3(0.0, cy, 0.0), _steel_mat)


func _build_side_panels() -> void:
	# Two upright cabinets flanking the worktop: -X dark, +X white.
	# They rise from the worktop top to roughly the corkboard top.
	var panel_bottom: float = worktop_height
	var panel_height: float = CORKBOARD_HEIGHT * 0.92
	var cy: float = panel_bottom + panel_height * 0.5
	var d: float = size.z * 0.55
	var x_off: float = size.x * 0.5 - SIDE_PANEL_THICKNESS * 0.5
	# Side cabinets sit toward the back so the worktop stays open at the front.
	var z_off: float = -size.z * 0.5 + d * 0.5
	_box(
		"SidePanelDark",
		Vector3(SIDE_PANEL_THICKNESS, panel_height, d),
		Vector3(-x_off, cy, z_off),
		_dark_mat
	)
	_box(
		"SidePanelWhite",
		Vector3(SIDE_PANEL_THICKNESS, panel_height, d),
		Vector3(x_off, cy, z_off),
		_white_mat
	)


func _build_back_frame() -> void:
	# Thin vertical metal frame along the back edge, behind the corkboard.
	var frame_height: float = CORKBOARD_HEIGHT + 0.04
	var cy: float = worktop_height + frame_height * 0.5
	var z: float = -size.z * 0.5 + BACK_FRAME_THICKNESS * 0.5
	_box(
		"BackFrame",
		Vector3(size.x, frame_height, BACK_FRAME_THICKNESS),
		Vector3(0.0, cy, z),
		_steel_mat
	)


func _build_corkboard() -> void:
	var board_w: float = size.x - CORKBOARD_INSET * 2.0
	var cy: float = worktop_height + CORKBOARD_HEIGHT * 0.5
	# Cork sits just in front of the back frame (toward +Z).
	var z: float = -size.z * 0.5 + BACK_FRAME_THICKNESS + CORKBOARD_THICKNESS * 0.5
	_box(
		"Corkboard",
		Vector3(board_w, CORKBOARD_HEIGHT, CORKBOARD_THICKNESS),
		Vector3(0.0, cy, z),
		_cork_mat
	)
	# A few small pinned notes scattered across the board.
	var note_z: float = z + CORKBOARD_THICKNESS * 0.5 + 0.003
	var note_positions := [
		Vector2(-0.28, 0.10),
		Vector2(0.05, 0.14),
		Vector2(0.30, -0.06),
		Vector2(-0.10, -0.10),
	]
	for i in range(note_positions.size()):
		var p: Vector2 = note_positions[i]
		var nx: float = p.x
		# Keep notes inside the board bounds.
		if abs(nx) > board_w * 0.5 - NOTE_SIZE:
			nx = sign(nx) * (board_w * 0.5 - NOTE_SIZE)
		var ny: float = cy + p.y
		var note := _box(
			"Note_%d" % i,
			Vector3(NOTE_SIZE, NOTE_SIZE, 0.004),
			Vector3(nx, ny, note_z),
			_note_mat
		)
		note.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_gantry() -> void:
	# A curved overhead handle/gantry arching over the worktop: two short legs
	# rising from the worktop near each end, joined by a horizontal bar, with a
	# torus-arc bowing the centre upward for the "curved" read.
	var leg_top: float = worktop_height + GANTRY_CLEARANCE
	var leg_height: float = GANTRY_CLEARANCE - GANTRY_RADIUS
	if leg_height <= 0.0:
		leg_height = 0.1
	var leg_x: float = size.x * 0.5 - GANTRY_LEG_INSET
	var leg_z: float = -size.z * 0.5 + size.z * 0.30
	var leg_cy: float = worktop_height + leg_height * 0.5
	var leg_xs := [-leg_x, leg_x]
	for i in range(2):
		var leg := MeshInstance3D.new()
		leg.name = "GantryLeg_%d" % i
		var lmesh := CylinderMesh.new()
		lmesh.top_radius = GANTRY_RADIUS
		lmesh.bottom_radius = GANTRY_RADIUS
		lmesh.height = leg_height
		leg.mesh = lmesh
		leg.material_override = _steel_mat
		leg.position = Vector3(leg_xs[i], leg_cy, leg_z)
		add_child(leg)

	# Straight cross bar joining the leg tops, axis along X.
	var bar := MeshInstance3D.new()
	bar.name = "GantryBar"
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = GANTRY_RADIUS
	bmesh.bottom_radius = GANTRY_RADIUS
	bmesh.height = leg_x * 2.0
	bar.mesh = bmesh
	bar.material_override = _steel_mat
	bar.rotation = Vector3(0.0, 0.0, PI * 0.5)
	bar.position = Vector3(0.0, leg_top, leg_z)
	add_child(bar)

	# Torus arc bowing upward over the centre — the curved gantry read.
	var arc := MeshInstance3D.new()
	arc.name = "GantryArc"
	var tmesh := TorusMesh.new()
	tmesh.inner_radius = leg_x * 0.78
	tmesh.outer_radius = leg_x * 0.78 + GANTRY_RADIUS * 2.0
	arc.mesh = tmesh
	arc.material_override = _steel_mat
	# Default torus lies in the XZ plane; rotate it into the XY plane so the
	# ring stands up and its top edge arches over the worktop.
	arc.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	arc.position = Vector3(0.0, leg_top - leg_x * 0.78, leg_z)
	add_child(arc)


func _build_edge_controls() -> void:
	# A couple of small inset controls/sockets on the front edge of the worktop,
	# plus one emissive indicator.
	var top_y: float = worktop_height + EDGE_CONTROL_SIZE * 0.3
	var front_z: float = size.z * 0.5 - EDGE_CONTROL_SIZE * 0.6
	var ctrl_positions := [-size.x * 0.32, -size.x * 0.20]
	for i in range(ctrl_positions.size()):
		_box(
			"EdgeControl_%d" % i,
			Vector3(EDGE_CONTROL_SIZE, EDGE_CONTROL_SIZE * 0.4, EDGE_CONTROL_SIZE),
			Vector3(ctrl_positions[i], top_y, front_z),
			_dark_mat
		)
	# Emissive indicator beside the controls.
	var ind := _box(
		"Indicator",
		Vector3(INDICATOR_SIZE, INDICATOR_SIZE * 0.5, INDICATOR_SIZE),
		Vector3(-size.x * 0.08, top_y, front_z),
		_indicator_mat
	)
	ind.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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


func _parse_vec3(s: String, fallback: Vector3) -> Vector3:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
