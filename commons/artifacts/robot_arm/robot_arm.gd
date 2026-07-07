extends Node3D
class_name RobotArm

# @identity
# essence: an articulated lab arm on an industrial pedestal — Aperture / Boston-Dynamics vocabulary for "the lab moves things without hands". Round steel base disc, a vertical yaw joint, a chain of 2-4 box-and-sphere segments stacked with per-joint X-axis pitch angles (so the arm bends in the XZ plane), and an optional two-jaw parallel gripper at the end. Each joint wears an accent stripe. The arm is FROZEN in a programmed pose — a static glyph of motion.
# desire: the robot arm wants to be the room's PROXY HAND. Not the experimenter, not the specimen, but the manipulator between them. It wants to LOOK MID-ACTION even when stationary — bent at the elbow, pointing somewhere, ready to converge on a target it cannot see.
# critical_parameter: pose_angles_degrees — the same skeleton, articulated differently, becomes a completely different prop. [0,0,0,0] reads "calibrating, neutral, idle"; [0,-35,70,-45] reads "reaching, working, mid-process"; [0,-80,-30,90] reads "retracted, parked, off-shift". The arm is a sentence whose meaning is set by its joints.
# triggers: _ready() builds base disc + yaw joint + segments (each with joint sphere + arm box + accent stripe, rotated by pose_angles_degrees[i]) + optional gripper from exports; apply_grid_config rebuilds
# emerges: arm_segment_count=2 = "compact pick-and-place"; count=4 = "long-reach industrial"; gripper_visible=false = "calibration stub, no end-effector"; all angles 0 = "powered down, vertical"; mixed angles = "frozen mid-task, ominous"
# needs: round base disc CylinderMesh [present]; vertical yaw joint CylinderMesh [present]; chain of arm segment boxes with joint spheres [present]; per-joint X-axis pitch rotation from pose_angles_degrees [present]; optional two-jaw parallel gripper [present]; accent stripes at each joint [present]
# relationships: sibling to conveyor_belt (one MOVES things sideways, the other PICKS things up — together they form an assembly line); cousin to specimen_jar (the arm is what PUT the specimen in the jar, originally); peer to control_board (one is the brain, the other is the body — the board sends signals the arm obeys without question)
# truth: a robot arm is not just a mechanism. It is the lab's acknowledgement that some experiments are TOO HOT, TOO COLD, TOO SMALL, TOO DANGEROUS for human hands. The arm is the experimenter's CONSENT to be at arm's length. It is delegated touching.

## An articulated lab robot arm on a pedestal.
##
## Built procedurally from DNA. Origin is at the bottom center of the
## base disc. The arm rises from origin. The first joint above the base
## rotates around Y (yaw); subsequent joints rotate around X (pitch),
## so the arm articulates in the XZ plane.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Base")
@export var base_radius: float = 0.18
@export var base_height: float = 0.10

@export_group("Arm")
## How many articulated segments stack above the yaw joint (2-4).
@export_range(2, 4, 1) var arm_segment_count: int = 3
@export var segment_length: float = 0.32

@export_group("Color")
@export var body_color: Color = Color(0.86, 0.86, 0.88)
@export var joint_color: Color = Color(0.18, 0.18, 0.22)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Gripper")
@export var gripper_visible: bool = true

@export_group("Pose")
## Joint angles in degrees, bottom-up. Index 0 = base yaw (around Y),
## index 1..N = pitch (around X). Padded with 0.0 / truncated to
## arm_segment_count + 1.
@export var pose_angles_degrees: PackedFloat32Array = PackedFloat32Array([0.0, -35.0, 70.0, -45.0])

# ── Constants ─────────────────────────────────────────────────────────

const SEGMENT_THICKNESS: float = 0.06
const JOINT_RADIUS: float = 0.05
const YAW_JOINT_HEIGHT: float = 0.05
const YAW_JOINT_RADIUS: float = 0.06
const ACCENT_STRIPE_THICKNESS: float = 0.004
const GRIPPER_JAW_WIDTH: float = 0.012
const GRIPPER_JAW_HEIGHT: float = 0.06
const GRIPPER_JAW_DEPTH: float = 0.018
const GRIPPER_GAP: float = 0.05
const GRIPPER_PLATE_RADIUS: float = 0.035
const GRIPPER_PLATE_HEIGHT: float = 0.012

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_arm()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_arm()


func _read_metadata_overrides() -> void:
	if has_meta("config_base_radius"):
		base_radius = float(str(get_meta("config_base_radius")))
	if has_meta("config_base_height"):
		base_height = float(str(get_meta("config_base_height")))
	if has_meta("config_arm_segment_count"):
		arm_segment_count = int(str(get_meta("config_arm_segment_count")))
	if has_meta("config_segment_length"):
		segment_length = float(str(get_meta("config_segment_length")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_joint_color"):
		joint_color = _parse_color(str(get_meta("config_joint_color")), joint_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_gripper_visible"):
		var v := str(get_meta("config_gripper_visible")).to_lower()
		gripper_visible = v in ["true", "1", "yes", "on"]
	if has_meta("config_pose_angles_degrees"):
		var raw := str(get_meta("config_pose_angles_degrees"))
		var parts := raw.split(",")
		var arr := PackedFloat32Array()
		for p in parts:
			arr.append(float(p.strip_edges()))
		if arr.size() > 0:
			pose_angles_degrees = arr


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_arm() -> void:
	_built = true
	# Clamp arm_segment_count.
	var segs: int = clamp(arm_segment_count, 2, 4)
	# Pad pose_angles_degrees to segs+1 entries.
	var angles: PackedFloat32Array = _normalized_angles(segs + 1)

	_build_base()

	# Yaw joint disc sits on top of the base.
	var yaw_root := Node3D.new()
	yaw_root.name = "Yaw"
	yaw_root.position = Vector3(0.0, base_height, 0.0)
	yaw_root.rotation = Vector3(0.0, deg_to_rad(angles[0]), 0.0)
	add_child(yaw_root)

	_build_yaw_joint(yaw_root)

	# Stack segments above the yaw disc. Each segment is its own Node3D
	# pivoting at its base around X by angles[i+1].
	var current_parent: Node3D = yaw_root
	var attach_y: float = YAW_JOINT_HEIGHT
	for i in range(segs):
		var pivot := Node3D.new()
		pivot.name = "Segment_%d_Pivot" % i
		pivot.position = Vector3(0.0, attach_y, 0.0)
		pivot.rotation = Vector3(deg_to_rad(angles[i + 1]), 0.0, 0.0)
		current_parent.add_child(pivot)

		_build_joint_sphere(pivot)
		_build_arm_segment(pivot)
		# After this segment, the next segment attaches at the TOP of this
		# segment in its local frame.
		current_parent = pivot
		attach_y = JOINT_RADIUS + segment_length

	# Gripper at the end of the last segment (in current_parent's local frame
	# at attach_y).
	if gripper_visible:
		var gripper_root := Node3D.new()
		gripper_root.name = "Gripper"
		gripper_root.position = Vector3(0.0, attach_y, 0.0)
		current_parent.add_child(gripper_root)
		_build_gripper(gripper_root)


func _normalized_angles(target_size: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in range(target_size):
		var val: float = 0.0
		if i < pose_angles_degrees.size():
			val = pose_angles_degrees[i]
		out.append(val)
	return out


func _build_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var mesh := CylinderMesh.new()
	mesh.top_radius = base_radius
	mesh.bottom_radius = base_radius * 1.05
	mesh.height = base_height
	base.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = joint_color
	mat.roughness = 0.45
	mat.metallic = 0.65
	base.material_override = mat
	base.position = Vector3(0.0, base_height * 0.5, 0.0)
	add_child(base)

	# Accent ring around the base waist.
	var ring := MeshInstance3D.new()
	ring.name = "BaseAccent"
	var rm := CylinderMesh.new()
	rm.top_radius = base_radius * 1.02
	rm.bottom_radius = base_radius * 1.02
	rm.height = ACCENT_STRIPE_THICKNESS * 2.0
	ring.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = accent_color
	rmat.emission_enabled = true
	rmat.emission = accent_color
	rmat.emission_energy_multiplier = 1.5
	ring.material_override = rmat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0.0, base_height * 0.4, 0.0)
	add_child(ring)


func _build_yaw_joint(parent: Node3D) -> void:
	var joint := MeshInstance3D.new()
	joint.name = "YawJoint"
	var mesh := CylinderMesh.new()
	mesh.top_radius = YAW_JOINT_RADIUS
	mesh.bottom_radius = YAW_JOINT_RADIUS
	mesh.height = YAW_JOINT_HEIGHT
	joint.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = joint_color
	mat.roughness = 0.4
	mat.metallic = 0.7
	joint.material_override = mat
	joint.position = Vector3(0.0, YAW_JOINT_HEIGHT * 0.5, 0.0)
	parent.add_child(joint)

	# Accent stripe ring around the yaw joint.
	var stripe := MeshInstance3D.new()
	stripe.name = "YawStripe"
	var sm := CylinderMesh.new()
	sm.top_radius = YAW_JOINT_RADIUS * 1.04
	sm.bottom_radius = YAW_JOINT_RADIUS * 1.04
	sm.height = ACCENT_STRIPE_THICKNESS * 2.0
	stripe.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent_color
	smat.emission_enabled = true
	smat.emission = accent_color
	smat.emission_energy_multiplier = 1.4
	stripe.material_override = smat
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stripe.position = Vector3(0.0, YAW_JOINT_HEIGHT * 0.5, 0.0)
	parent.add_child(stripe)


func _build_joint_sphere(parent: Node3D) -> void:
	# Sphere at the BASE of the segment (the pitch joint).
	var sphere := MeshInstance3D.new()
	sphere.name = "JointSphere"
	var mesh := SphereMesh.new()
	mesh.radius = JOINT_RADIUS
	mesh.height = JOINT_RADIUS * 2.0
	sphere.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = joint_color
	mat.roughness = 0.35
	mat.metallic = 0.75
	sphere.material_override = mat
	sphere.position = Vector3.ZERO
	parent.add_child(sphere)

	# Accent ring around the equator of the joint sphere (a thin torus).
	var stripe := MeshInstance3D.new()
	stripe.name = "JointStripe"
	var tm := TorusMesh.new()
	tm.inner_radius = JOINT_RADIUS * 0.95
	tm.outer_radius = JOINT_RADIUS * 1.04
	stripe.mesh = tm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent_color
	smat.emission_enabled = true
	smat.emission = accent_color
	smat.emission_energy_multiplier = 1.6
	stripe.material_override = smat
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# TorusMesh by default has its axis along Y — for an equatorial ring
	# around the sphere in this pitch frame we want it lying flat (axis Y).
	stripe.position = Vector3.ZERO
	parent.add_child(stripe)


func _build_arm_segment(parent: Node3D) -> void:
	# Box arm rising from joint origin to top of segment.
	var arm := MeshInstance3D.new()
	arm.name = "ArmBox"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(SEGMENT_THICKNESS, segment_length, SEGMENT_THICKNESS)
	arm.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.35
	mat.metallic = 0.4
	arm.material_override = mat
	# Place segment above the joint sphere; sphere has radius JOINT_RADIUS.
	var y: float = JOINT_RADIUS + segment_length * 0.5
	arm.position = Vector3(0.0, y, 0.0)
	parent.add_child(arm)


func _build_gripper(parent: Node3D) -> void:
	# Mount plate (small disc) behind the jaws + two parallel jaw boxes.
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var pm := CylinderMesh.new()
	pm.top_radius = GRIPPER_PLATE_RADIUS
	pm.bottom_radius = GRIPPER_PLATE_RADIUS
	pm.height = GRIPPER_PLATE_HEIGHT
	plate.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = joint_color
	pmat.roughness = 0.4
	pmat.metallic = 0.7
	plate.material_override = pmat
	plate.position = Vector3(0.0, GRIPPER_PLATE_HEIGHT * 0.5, 0.0)
	parent.add_child(plate)

	# Accent ring around the plate.
	var ring := MeshInstance3D.new()
	ring.name = "PlateAccent"
	var rm := TorusMesh.new()
	rm.inner_radius = GRIPPER_PLATE_RADIUS * 0.85
	rm.outer_radius = GRIPPER_PLATE_RADIUS * 1.02
	ring.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = accent_color
	rmat.emission_enabled = true
	rmat.emission = accent_color
	rmat.emission_energy_multiplier = 1.4
	ring.material_override = rmat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0.0, GRIPPER_PLATE_HEIGHT * 0.5, 0.0)
	parent.add_child(ring)

	# Two parallel jaw boxes, extended above the plate.
	var jaw_mat := StandardMaterial3D.new()
	jaw_mat.albedo_color = body_color
	jaw_mat.roughness = 0.3
	jaw_mat.metallic = 0.6

	for i in range(2):
		var jaw := MeshInstance3D.new()
		jaw.name = "Jaw_%d" % i
		var jm := BoxMesh.new()
		jm.size = Vector3(GRIPPER_JAW_WIDTH, GRIPPER_JAW_HEIGHT, GRIPPER_JAW_DEPTH)
		jaw.mesh = jm
		jaw.material_override = jaw_mat
		var side: float = -1.0 if i == 0 else 1.0
		var jx: float = side * (GRIPPER_GAP * 0.5 + GRIPPER_JAW_WIDTH * 0.5)
		var jy: float = GRIPPER_PLATE_HEIGHT + GRIPPER_JAW_HEIGHT * 0.5
		jaw.position = Vector3(jx, jy, 0.0)
		parent.add_child(jaw)


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
