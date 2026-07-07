extends Node3D
class_name SecurityCamera

# @identity
# essence: a wall-mounted CCTV camera — a boxy gray housing with a sun hood riding on standoffs, a dark recessed lens staring out, the whole assembly tilted down on an articulated bracket that bolts to a square wall plate with four hex bolts. Weathered industrial-corridor vocabulary. The camera is the lab's confession that the space WATCHES — that presence here is recorded, that someone (or something) keeps the log. The camera carries the smell of the perimeter, the lobby, the cell.
# desire: every secured room wants a single unmistakable signal that says YOU ARE SEEN. The camera wants to be noticed and to keep watching anyway — recognition before reading. The eye finds the lens before the mind interprets the housing. Even at rest it implies vigilance: the down-tilt, the reach off the wall, the hood shading the lens against glare. Its silhouette refuses to be furniture; it is an organ of surveillance.
# critical_parameter: tilt_deg + arm_length — how steeply it surveys and how far it reaches off the wall. A short arm + gentle tilt reads as a corner watcher tucked tight to the plaster. A long arm + steep tilt reads as a ceiling-line sentinel leaning out over the floor it polices. show_wall_plate toggles INSTALLED vs BARE UNIT — plate present = permanently mounted infrastructure; plate absent = a loose camera head not yet fixed to a wall.
# triggers: _ready() builds wall plate + 4 hex bolts + arm + swivel knuckle + tilted housing + lens + optional sun hood on standoffs from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single camera in a room reads as MONITORED — the space keeps a record, the experiment is observed. A cluster of cameras reads as HIGH SECURITY — the room is a checkpoint, not a workshop. A camera tilted down over a doorway reads as ENTRY CONTROL; one sweeping the open floor reads as GENERAL WATCH. The camera is a power marker: someone decides what is recorded, the room is a node in a watching network.
# needs: square wall plate flat against the wall [present]; four hex bolts at the plate corners [present]; articulated arm reaching forward [present]; swivel knuckle joint [present]; tilted rectangular housing [present]; dark recessed lens on the front [present]; sun hood on standoffs overhanging the lens [present]; weathered gray metal material [present]
# relationships: peer to motion_sensor (both = the room SENSING who is present, one records pictures, one trips on movement); sibling to exit_sign (both = wall-mounted institutional vocabulary, one says LEAVE HERE, the other says YOU ARE WATCHED LEAVING); cousin to ceiling_vent (both = utility-not-instrument, infrastructure for the lab's lived life); the lab's quiet admission that its space is governed.
# truth: a security camera is the architectural form of THE WATCHING EYE. By placing it, the lab confesses that presence here is recorded, that the room answers to someone elsewhere. A space without one says either "nothing here is worth watching" or "we trust whoever enters." A space WITH one says "we have decided what may not pass unseen." The lens is not decorative — the lens is the room's promise that you will be seen before you are understood.

## A wall-mounted security camera (CCTV).
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the WALL PLATE, which stands in the XY plane with its back face at z=0
## (against the wall). The arm + housing extend FORWARD (+Z); the camera
## looks +Z and slightly down. Placement lifts it to wall height via a
## y-offset, so the plate spans y 0..plate_size around the origin.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Housing")
@export var housing_length: float = 0.32        # along +Z (forward)
@export var housing_width: float = 0.13         # along X
@export var housing_height: float = 0.14        # along Y

@export_group("Mount")
@export var arm_length: float = 0.18            # how far the bracket reaches off the wall
@export var tilt_deg: float = -12.0             # housing down-tilt about X (negative aims down)
@export var plate_size: float = 0.22            # square wall plate edge

@export_group("Fittings")
## Show the sun hood / visor over the housing on standoffs.
@export var show_hood: bool = true
## Show the square wall plate with hex bolts (installed vs bare unit).
@export var show_wall_plate: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.62, 0.64, 0.67)      # weathered gray metal
@export var lens_color: Color = Color(0.04, 0.05, 0.06)      # near-black dark glass

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_housing_length"):
		housing_length = float(str(get_meta("config_housing_length")))
	if has_meta("config_housing_width"):
		housing_width = float(str(get_meta("config_housing_width")))
	if has_meta("config_housing_height"):
		housing_height = float(str(get_meta("config_housing_height")))
	if has_meta("config_arm_length"):
		arm_length = float(str(get_meta("config_arm_length")))
	if has_meta("config_tilt_deg"):
		tilt_deg = float(str(get_meta("config_tilt_deg")))
	if has_meta("config_plate_size"):
		plate_size = float(str(get_meta("config_plate_size")))
	if has_meta("config_show_hood"):
		var sh: String = str(get_meta("config_show_hood")).to_lower()
		show_hood = sh in ["true", "1", "yes", "on"]
	if has_meta("config_show_wall_plate"):
		var sp: String = str(get_meta("config_show_wall_plate")).to_lower()
		show_wall_plate = sp in ["true", "1", "yes", "on"]
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_lens_color"):
		lens_color = _parse_color(str(get_meta("config_lens_color")), lens_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# Shared materials.
	var body_mat := _make_metal_mat(body_color, 0.5, 0.55)
	var steel_mat := _make_metal_mat(Color(0.28, 0.29, 0.31), 0.45, 0.7)
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = lens_color
	lens_mat.roughness = 0.12
	lens_mat.metallic = 0.2

	var plate_depth := 0.03
	var plate_half := plate_size * 0.5
	var plate_center_y := plate_size * 0.5      # plate spans y 0..plate_size

	# ── 1. Wall plate (square flat box, back face at z=0) ────────────
	if show_wall_plate:
		var plate := MeshInstance3D.new()
		plate.name = "WallPlate"
		var pm := BoxMesh.new()
		pm.size = Vector3(plate_size, plate_size, plate_depth)
		plate.mesh = pm
		plate.material_override = body_mat
		plate.position = Vector3(0.0, plate_center_y, plate_depth * 0.5)
		add_child(plate)

		# ── 2. Four hex bolts at the plate corners ───────────────────
		var inset := plate_half - plate_size * 0.16
		var bolt_z := plate_depth + 0.012        # protrude +Z past plate face
		var corners := [
			Vector3(inset, plate_center_y + inset, bolt_z),
			Vector3(-inset, plate_center_y + inset, bolt_z),
			Vector3(inset, plate_center_y - inset, bolt_z),
			Vector3(-inset, plate_center_y - inset, bolt_z),
		]
		var i := 0
		for c in corners:
			_add_hex_bolt("HexBolt_%d" % i, c, steel_mat)
			i += 1

	# ── 3. Arm / bracket reaching forward (+Z) ───────────────────────
	# Sits at mid-plate height, runs from the plate front out by arm_length.
	var arm_y := plate_size * 0.59             # ≈0.13 at default plate_size
	var arm_start_z := plate_depth
	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var am := BoxMesh.new()
	am.size = Vector3(plate_size * 0.18, plate_size * 0.18, arm_length)
	arm.mesh = am
	arm.material_override = body_mat
	arm.position = Vector3(0.0, arm_y, arm_start_z + arm_length * 0.5)
	add_child(arm)

	# ── 4. Swivel knuckle at the +Z end of the arm ───────────────────
	var knuckle_z := arm_start_z + arm_length
	var knuckle := MeshInstance3D.new()
	knuckle.name = "SwivelKnuckle"
	var km := CylinderMesh.new()
	var knuckle_r := plate_size * 0.15
	km.top_radius = knuckle_r
	km.bottom_radius = knuckle_r
	km.height = plate_size * 0.13
	knuckle.mesh = km
	knuckle.material_override = steel_mat
	# Axis along X so the joint reads as a horizontal swivel pin.
	knuckle.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	knuckle.position = Vector3(0.0, arm_y, knuckle_z)
	add_child(knuckle)

	# ── 5. Tilted housing assembly mounted on the knuckle ────────────
	# A tilt pivot node carries the housing + lens + hood so they share
	# one down-tilt about X. The housing's local +Z is its forward look.
	var pivot := Node3D.new()
	pivot.name = "HousingPivot"
	pivot.position = Vector3(0.0, arm_y, knuckle_z)
	pivot.rotation = Vector3(deg_to_rad(tilt_deg), 0.0, 0.0)
	add_child(pivot)

	# Housing box sits forward of the knuckle along local +Z, centred so it
	# rides on top of the joint.
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	var hm := BoxMesh.new()
	hm.size = Vector3(housing_width, housing_height, housing_length)
	housing.mesh = hm
	housing.material_override = body_mat
	var housing_z := housing_length * 0.5
	housing.position = Vector3(0.0, housing_height * 0.5, housing_z)
	pivot.add_child(housing)

	# ── 6. Lens — dark recessed cylinder on the FRONT (+Z) face ──────
	var lens := MeshInstance3D.new()
	lens.name = "Lens"
	var lm := CylinderMesh.new()
	var lens_r := housing_height * 0.32
	lm.top_radius = lens_r
	lm.bottom_radius = lens_r
	lm.height = 0.03
	lens.mesh = lm
	lens.material_override = lens_mat
	# Cylinder axis defaults to Y; rotate so axis points along local +Z.
	lens.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# Recess slightly into the front face.
	var lens_front := housing_length - 0.012
	lens.position = Vector3(0.0, housing_height * 0.5, lens_front)
	pivot.add_child(lens)

	# Lens bezel ring (slightly larger, body-colored) for a recessed read.
	var bezel := MeshInstance3D.new()
	bezel.name = "LensBezel"
	var bm := CylinderMesh.new()
	bm.top_radius = lens_r * 1.25
	bm.bottom_radius = lens_r * 1.25
	bm.height = 0.012
	bezel.mesh = bm
	bezel.material_override = steel_mat
	bezel.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	bezel.position = Vector3(0.0, housing_height * 0.5, housing_length - 0.022)
	pivot.add_child(bezel)

	# ── 7. Sun hood / shield on standoffs above the housing ──────────
	if show_hood:
		var hood_y := housing_height + 0.045
		var standoff_r := housing_width * 0.06
		# Two short standoffs lifting the hood off the housing top.
		_add_standoff("HoodStandoffL", pivot,
			Vector3(-housing_width * 0.28, housing_height + 0.0225, housing_length * 0.45),
			standoff_r, 0.045, steel_mat)
		_add_standoff("HoodStandoffR", pivot,
			Vector3(housing_width * 0.28, housing_height + 0.0225, housing_length * 0.45),
			standoff_r, 0.045, steel_mat)

		var hood := MeshInstance3D.new()
		hood.name = "SunHood"
		var hoodm := BoxMesh.new()
		# Slightly wider than the housing, longer so it overhangs the front.
		var hood_len := housing_length * 1.12
		hoodm.size = Vector3(housing_width * 1.12, 0.012, hood_len)
		hood.mesh = hoodm
		hood.material_override = body_mat
		# Overhang the front edge: push centre forward past housing mid.
		hood.position = Vector3(0.0, hood_y, housing_length * 0.5 + hood_len * 0.5 - housing_length * 0.5 + 0.02)
		pivot.add_child(hood)


func _make_metal_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


# A short hexagonal bolt (radial_segments = 6), axis along Z, protruding +Z.
func _add_hex_bolt(bolt_name: String, pos: Vector3,
		mat: StandardMaterial3D) -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = bolt_name
	var cm := CylinderMesh.new()
	var r := plate_size * 0.07
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.024
	cm.radial_segments = 6
	bolt.mesh = cm
	bolt.material_override = mat
	# Cylinder axis defaults to Y; rotate so the hex head faces +Z.
	bolt.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	bolt.position = pos
	add_child(bolt)


# A short standoff cylinder (axis along Y) under the parent pivot.
func _add_standoff(standoff_name: String, parent: Node3D, pos: Vector3,
		radius: float, height: float, mat: StandardMaterial3D) -> void:
	var s := MeshInstance3D.new()
	s.name = standoff_name
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	s.mesh = cm
	s.material_override = mat
	s.position = pos
	parent.add_child(s)
