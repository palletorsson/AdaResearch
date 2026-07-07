extends Node3D
class_name IndustrialRobotArm

# @identity
# essence: a classic orange 6-axis factory robot — KUKA/ABB vocabulary, the arm everyone has seen welding car bodies in a thousand promotional films. A hazard-striped base plate bolted to the floor, a rotating yaw housing, a shoulder, a long lower arm leaning back, an elbow, a forearm reaching out and slightly down, a gray wrist flange, and a gripper holding nothing yet. Black cables loop and sag along the links. The robot is the lab's confession that LABOUR here is mechanised — that the hand at the bench was replaced by a hand that never tires, never flinches, never asks why.
# desire: every factory arm wants to be caught MID-REACH — frozen in a pose, not parked. Parked is honest about being a machine; reaching is honest about being a worker. The robot wants its gripper out in front of it, at chest height, as if it just put something down or is about to pick something up. It wants you to read intention into a thing that has none. The orange is not decoration — orange is the colour of "I move on my own, stand back".
# critical_parameter: shoulder_deg / elbow_deg — the reaching pose. Shoulder leaning back and elbow folded forward puts the gripper out in +Z at working height (a robot AT WORK); both near zero stand it bolt upright (a robot PARKED, between shifts). arm_color says which manufacturer's myth it borrows (KUKA orange vs the generic safety-orange of the cell). gripper present = a tool ready to grasp; absent = a flange waiting for an end-effector to be bolted on.
# triggers: _ready() builds base plate + hazard stripe + yaw + shoulder + lower arm + elbow + forearm + wrist + gripper + cable sags from exports through a nested joint hierarchy; apply_grid_config rebuilds when the DNA changes.
# emerges: a single arm in a corner reads as AUTOMATION ARRIVED — the lab has crossed from hand-work to machine-work. The hazard stripes around the base say KEEP CLEAR, this thing has a reach you cannot see. The reaching pose makes a still object feel paused rather than dead. The gripper, holding nothing, reads as EXPECTANT — the work is not finished, only interrupted.
# needs: hazard-striped base plate on the floor [present]; rotating yaw housing [present]; shoulder box [present]; long lower arm leaning back [present]; elbow housing + forearm reaching forward [present]; gray wrist flange [present]; gripper fingers [present]; black cables sagging along the arm [present]
# relationships: peer to crate (both confess the supply chain — the crate is what ARRIVED, the robot is what UNPACKED and went to work); cousin to fire_extinguisher (both are NAMED-DANGER infrastructure — the extinguisher says fire is anticipated, the hazard stripes say the moving arm is anticipated); structural sibling to large_table (both are furniture-of-work, but the table waits for hands and the robot IS the hand).
# truth: the industrial robot arm is the architectural form of REPLACED LABOUR. By placing it, the lab confesses that the work once done by a person is now done by a servo loop. It is not a tool a worker holds; it is the worker, rebuilt as a machine. The reaching pose is the lie that makes it bearable — it looks like it WANTS to work, when in truth it only executes. Every orange arm is a small monument to the hand that used to be there.

## A classic orange 6-axis industrial robot arm in a reaching pose.
##
## Built procedurally from DNA exports through a nested joint hierarchy:
## base -> yaw pivot -> shoulder -> lower-arm pivot -> elbow -> forearm
## pivot -> wrist -> gripper. Origin is at the BOTTOM CENTRE of the base
## plate (floor-friendly). The arm reaches toward +Z. Total reach is
## roughly 1.4m tall.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Side length of the square base plate (metres).
@export var base_size: float = 0.6

@export_group("Pose")
## Shoulder pitch (J2) — negative leans the lower arm back from vertical.
@export var shoulder_deg: float = -22.0
## Elbow pitch (J3) — positive folds the forearm forward toward +Z.
@export var elbow_deg: float = 60.0

@export_group("Hardware")
## Show the gripper fingers at the wrist tip. Off = bare flange.
@export var gripper: bool = true
## Show the black cables sagging along the arm.
@export var show_cables: bool = true
## Show the yellow/black hazard stripe around the base plate edge.
@export var hazard_base: bool = true

@export_group("Material")
## Robot orange — the canonical industrial-arm body colour.
@export var arm_color: Color = Color(0.92, 0.45, 0.10)
## Dark gray for the wrist housing and tool flange.
@export var tool_color: Color = Color(0.55, 0.56, 0.58)
## Near-black for the cables.
@export var cable_color: Color = Color(0.06, 0.06, 0.07)
## Hazard yellow for the base stripe.
@export var hazard_yellow: Color = Color(0.95, 0.78, 0.05)
## Hazard black for the base stripe.
@export var hazard_black: Color = Color(0.08, 0.08, 0.09)

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
	if has_meta("config_base_size"):
		base_size = float(str(get_meta("config_base_size")))
	if has_meta("config_shoulder_deg"):
		shoulder_deg = float(str(get_meta("config_shoulder_deg")))
	if has_meta("config_elbow_deg"):
		elbow_deg = float(str(get_meta("config_elbow_deg")))
	if has_meta("config_gripper"):
		var g: String = str(get_meta("config_gripper")).to_lower()
		gripper = g == "true" or g == "1" or g == "yes" or g == "on"
	if has_meta("config_show_cables"):
		var s: String = str(get_meta("config_show_cables")).to_lower()
		show_cables = s == "true" or s == "1" or s == "yes" or s == "on"
	if has_meta("config_hazard_base"):
		var h: String = str(get_meta("config_hazard_base")).to_lower()
		hazard_base = h == "true" or h == "1" or h == "yes" or h == "on"
	if has_meta("config_arm_color"):
		arm_color = _parse_color(str(get_meta("config_arm_color")), arm_color)
	if has_meta("config_tool_color"):
		tool_color = _parse_color(str(get_meta("config_tool_color")), tool_color)
	if has_meta("config_cable_color"):
		cable_color = _parse_color(str(get_meta("config_cable_color")), cable_color)
	if has_meta("config_hazard_yellow"):
		hazard_yellow = _parse_color(str(get_meta("config_hazard_yellow")), hazard_yellow)
	if has_meta("config_hazard_black"):
		hazard_black = _parse_color(str(get_meta("config_hazard_black")), hazard_black)


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
	var orange_mat := _make_mat(arm_color, 0.5, 0.2)
	var tool_mat := _make_mat(tool_color, 0.45, 0.5)
	var cable_mat := _make_mat(cable_color, 0.6, 0.0)

	var plate_h: float = 0.06
	var hb: float = base_size * 0.5

	# ── 1. Base plate on the floor ───────────────────────────────────
	var plate := MeshInstance3D.new()
	plate.name = "BasePlate"
	var pm := BoxMesh.new()
	pm.size = Vector3(base_size, plate_h, base_size)
	plate.mesh = pm
	plate.material_override = _make_mat(Color(0.22, 0.22, 0.24), 0.55, 0.4)
	plate.position = Vector3(0.0, plate_h * 0.5, 0.0)
	add_child(plate)

	# ── 2. Hazard-striped edge around the plate perimeter ────────────
	if hazard_base:
		_build_hazard_edge(hb, plate_h)

	# ── 3. Rotating base / yaw housing (J1) ──────────────────────────
	# Everything above the plate hangs off the yaw pivot at plate top.
	var yaw := Node3D.new()
	yaw.name = "YawPivot"
	yaw.position = Vector3(0.0, plate_h, 0.0)
	add_child(yaw)

	var yaw_h: float = 0.16
	var yaw_r: float = base_size * 0.32
	var yaw_housing := MeshInstance3D.new()
	yaw_housing.name = "YawHousing"
	var ym := CylinderMesh.new()
	ym.top_radius = yaw_r * 0.85
	ym.bottom_radius = yaw_r
	ym.height = yaw_h
	yaw_housing.mesh = ym
	yaw_housing.material_override = orange_mat
	yaw_housing.position = Vector3(0.0, yaw_h * 0.5, 0.0)
	yaw.add_child(yaw_housing)

	# ── 4. Shoulder housing atop the yaw ─────────────────────────────
	var shoulder := Node3D.new()
	shoulder.name = "Shoulder"
	shoulder.position = Vector3(0.0, yaw_h, 0.0)
	yaw.add_child(shoulder)

	var sh_w: float = base_size * 0.42
	var sh_h: float = 0.20
	var sh_box := MeshInstance3D.new()
	sh_box.name = "ShoulderHousing"
	var sbm := BoxMesh.new()
	sbm.size = Vector3(sh_w, sh_h, sh_w * 0.8)
	sh_box.mesh = sbm
	sh_box.material_override = orange_mat
	sh_box.position = Vector3(0.0, sh_h * 0.5, 0.0)
	shoulder.add_child(sh_box)

	# ── 5. Lower-arm pivot (J2 pitch) — leans back from vertical ─────
	var lower_pivot := Node3D.new()
	lower_pivot.name = "LowerArmPivot"
	lower_pivot.position = Vector3(0.0, sh_h, 0.0)
	# Negative shoulder_deg leans the link back (toward -Z) about the X axis.
	lower_pivot.rotation = Vector3(deg_to_rad(shoulder_deg), 0.0, 0.0)
	shoulder.add_child(lower_pivot)

	var lower_len: float = 0.50
	var lower_w: float = base_size * 0.24
	# Long, slightly tapered link rising from the pivot.
	var lower_arm := MeshInstance3D.new()
	lower_arm.name = "LowerArm"
	var lam := BoxMesh.new()
	lam.size = Vector3(lower_w, lower_len, lower_w * 0.85)
	lower_arm.mesh = lam
	lower_arm.material_override = orange_mat
	lower_arm.position = Vector3(0.0, lower_len * 0.5, 0.0)
	lower_pivot.add_child(lower_arm)

	# ── 6. Elbow housing at the lower-arm top ────────────────────────
	var elbow := Node3D.new()
	elbow.name = "Elbow"
	elbow.position = Vector3(0.0, lower_len, 0.0)
	lower_pivot.add_child(elbow)

	var elbow_r: float = lower_w * 0.62
	var elbow_box := MeshInstance3D.new()
	elbow_box.name = "ElbowHousing"
	var ebm := CylinderMesh.new()
	ebm.top_radius = elbow_r
	ebm.bottom_radius = elbow_r
	ebm.height = lower_w * 1.05
	elbow_box.mesh = ebm
	elbow_box.material_override = orange_mat
	# Lay the cylinder along the X axis so it reads as a hinge barrel.
	elbow_box.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	elbow_box.position = Vector3.ZERO
	elbow.add_child(elbow_box)

	# ── 7. Forearm pivot (J3 pitch) — folds forward toward +Z ────────
	var fore_pivot := Node3D.new()
	fore_pivot.name = "ForearmPivot"
	fore_pivot.position = Vector3.ZERO
	# Positive elbow_deg folds the forearm forward (toward +Z) about X.
	fore_pivot.rotation = Vector3(deg_to_rad(elbow_deg), 0.0, 0.0)
	elbow.add_child(fore_pivot)

	var fore_len: float = 0.44
	var fore_w: float = lower_w * 0.82
	var forearm := MeshInstance3D.new()
	forearm.name = "Forearm"
	var fam := BoxMesh.new()
	fam.size = Vector3(fore_w, fore_len, fore_w * 0.85)
	forearm.mesh = fam
	forearm.material_override = orange_mat
	forearm.position = Vector3(0.0, fore_len * 0.5, 0.0)
	fore_pivot.add_child(forearm)

	# ── 8. Wrist housing + flange (J5/J6) ────────────────────────────
	var wrist := Node3D.new()
	wrist.name = "Wrist"
	wrist.position = Vector3(0.0, fore_len, 0.0)
	fore_pivot.add_child(wrist)

	var wrist_r: float = fore_w * 0.55
	var wrist_housing := MeshInstance3D.new()
	wrist_housing.name = "WristHousing"
	var whm := CylinderMesh.new()
	whm.top_radius = wrist_r
	whm.bottom_radius = wrist_r * 1.1
	whm.height = fore_w * 0.9
	wrist_housing.mesh = whm
	wrist_housing.material_override = tool_mat
	wrist_housing.position = Vector3(0.0, fore_w * 0.45, 0.0)
	wrist.add_child(wrist_housing)

	# Flange disc at the very end of the wrist.
	var flange := MeshInstance3D.new()
	flange.name = "Flange"
	var flm := CylinderMesh.new()
	flm.top_radius = wrist_r * 0.75
	flm.bottom_radius = wrist_r * 0.9
	flm.height = 0.04
	flange.mesh = flm
	flange.material_override = tool_mat
	flange.position = Vector3(0.0, fore_w * 0.9 + 0.02, 0.0)
	wrist.add_child(flange)

	# ── 9. Gripper at the wrist tip ──────────────────────────────────
	if gripper:
		_build_gripper(wrist, Vector3(0.0, fore_w * 0.9 + 0.04, 0.0),
			wrist_r, tool_mat)

	# ── 10. Cables sagging along the arm ─────────────────────────────
	if show_cables:
		_build_cables(yaw, cable_mat, yaw_h, sh_h, lower_len, lower_w)


# ── Helpers ───────────────────────────────────────────────────────────

func _make_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


# Alternating yellow/black short boxes ringing the plate perimeter.
func _build_hazard_edge(hb: float, plate_h: float) -> void:
	var edge := Node3D.new()
	edge.name = "HazardEdge"
	add_child(edge)

	var yellow_mat := _make_mat(hazard_yellow, 0.55, 0.05)
	var black_mat := _make_mat(hazard_black, 0.55, 0.05)

	var strip_h: float = 0.03
	var strip_t: float = 0.02         # how far it juts out from the plate face
	var seg_count: int = 8
	var seg_len: float = base_size / float(seg_count)
	var y: float = plate_h - strip_h * 0.5
	var out: float = hb + strip_t * 0.5

	# Four sides, each a run of alternating segments.
	for side in range(4):
		for i in range(seg_count):
			var seg := MeshInstance3D.new()
			seg.name = "HazardSeg_%d_%d" % [side, i]
			var bm := BoxMesh.new()
			var mat: StandardMaterial3D = yellow_mat if i % 2 == 0 else black_mat
			var center: float = -hb + seg_len * (i + 0.5)
			match side:
				0:   # +Z face, segments run along X
					bm.size = Vector3(seg_len * 0.96, strip_h, strip_t)
					seg.position = Vector3(center, y, out)
				1:   # -Z face
					bm.size = Vector3(seg_len * 0.96, strip_h, strip_t)
					seg.position = Vector3(center, y, -out)
				2:   # +X face, segments run along Z
					bm.size = Vector3(strip_t, strip_h, seg_len * 0.96)
					seg.position = Vector3(out, y, center)
				3:   # -X face
					bm.size = Vector3(strip_t, strip_h, seg_len * 0.96)
					seg.position = Vector3(-out, y, center)
			seg.mesh = bm
			seg.material_override = mat
			edge.add_child(seg)


# Two or three small fingers at the wrist tip.
func _build_gripper(parent: Node3D, base_pos: Vector3,
		wrist_r: float, mat: StandardMaterial3D) -> void:
	var grip := Node3D.new()
	grip.name = "Gripper"
	grip.position = base_pos
	parent.add_child(grip)

	# Mounting palm.
	var palm := MeshInstance3D.new()
	palm.name = "GripperPalm"
	var palm_m := BoxMesh.new()
	palm_m.size = Vector3(wrist_r * 1.4, 0.03, wrist_r * 1.0)
	palm.mesh = palm_m
	palm.material_override = mat
	palm.position = Vector3(0.0, 0.015, 0.0)
	grip.add_child(palm)

	var finger_len: float = 0.10
	var finger_w: float = wrist_r * 0.32
	var spread: float = wrist_r * 0.55
	# Two opposing fingers along X, angled slightly inward (a parallel grip
	# that is almost closed).
	var offsets := [-spread, spread]
	for i in range(offsets.size()):
		var finger := MeshInstance3D.new()
		finger.name = "Finger_%d" % i
		var fm := BoxMesh.new()
		fm.size = Vector3(finger_w, finger_len, finger_w * 1.3)
		finger.mesh = fm
		finger.material_override = mat
		# Tilt each finger slightly toward the centre line.
		var tilt: float = deg_to_rad(8.0) * (1.0 if offsets[i] < 0.0 else -1.0)
		finger.rotation = Vector3(0.0, 0.0, tilt)
		finger.position = Vector3(offsets[i], 0.03 + finger_len * 0.5, 0.0)
		grip.add_child(finger)


# Black cables: short angled cylinder segments forming a sag. One loops
# from the base up over the shoulder; one runs along the lower arm.
func _build_cables(yaw: Node3D, mat: StandardMaterial3D,
		yaw_h: float, sh_h: float, lower_len: float, lower_w: float) -> void:
	var cables := Node3D.new()
	cables.name = "Cables"
	yaw.add_child(cables)

	# Cable A — droops from near the yaw base up over the shoulder.
	var a_pts := [
		Vector3(-base_size * 0.18, yaw_h * 0.3, base_size * 0.18),
		Vector3(-base_size * 0.22, yaw_h * 0.2, base_size * 0.05),
		Vector3(-base_size * 0.16, yaw_h + sh_h * 0.6, -base_size * 0.04),
	]
	_run_cable(cables, "CableA", a_pts, mat)

	# Cable B — runs up the side of the lower arm with a small sag.
	var lz: float = lower_w * 0.6
	var b_pts := [
		Vector3(base_size * 0.16, yaw_h + sh_h * 0.5, lz),
		Vector3(base_size * 0.10, yaw_h + sh_h + lower_len * 0.35, lz * 0.9),
		Vector3(base_size * 0.05, yaw_h + sh_h + lower_len * 0.75, lz * 0.7),
	]
	_run_cable(cables, "CableB", b_pts, mat)


# Connect a list of points with thin cylinder segments (a polyline cable).
func _run_cable(parent: Node3D, cable_name: String,
		pts: Array, mat: StandardMaterial3D) -> void:
	var radius: float = 0.012
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg := MeshInstance3D.new()
		seg.name = "%s_seg_%d" % [cable_name, i]
		var cm := CylinderMesh.new()
		cm.top_radius = radius
		cm.bottom_radius = radius
		var seg_len: float = a.distance_to(b)
		cm.height = seg_len
		seg.mesh = cm
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Orient local +Y from a -> b.
		var up: Vector3 = (b - a).normalized()
		var ref: Vector3 = Vector3(0.0, 0.0, 1.0)
		if abs(up.dot(ref)) > 0.95:
			ref = Vector3(1.0, 0.0, 0.0)
		var side: Vector3 = up.cross(ref).normalized()
		var fwd: Vector3 = side.cross(up).normalized()
		seg.transform.basis = Basis(side, up, fwd)
		seg.position = (a + b) * 0.5
		parent.add_child(seg)
