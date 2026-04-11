# @identity
# essence: joint_type(limb_i) = {hinge, ball, slider, revolute, prismatic, fixed} -- 6 limbs, 6 constraints
# desire: central body with 6 limbs, each demonstrating a different joint constraint as locomotion
# critical_parameter: joint type per limb -- hinge restricts to 1 axis, ball allows 3, slider translates
# triggers: continuous locomotion cycle; each limb moves per its joint constraint; proximity triggers attack
# emerges: physics constraints as morphology -- the joint type IS the movement vocabulary
# needs: HazardCreatureBase [has]; 6 joint type implementations [has]; limb mesh [has]; VR interaction [missing]
# relationships: embodies joints sequence; pairs with spring_mass_bouncer (constraints vs elasticity)
# truth: six limbs, six joint types -- the constraint vocabulary of all articulated motion.

extends HazardCreatureBase
class_name JointArticulator
## Central body with 6 limbs, each demonstrating a different joint type.
## HINGE (swing one axis), BALL (rotate freely), SLIDER (extend/retract),
## REVOLUTE (spin), PRISMATIC (telescope), FIXED (rigid).
## Walks on bottom 2 limbs (hinge + ball). Joint-constrained attacks on CHASE.

enum JointType { HINGE, BALL, SLIDER, REVOLUTE, PRISMATIC, FIXED }

@export_group("Joints")
@export var arm_length: float = 0.3
@export var arm_radius: float = 0.02
@export var joint_marker_radius: float = 0.04
@export var body_size: float = 0.2
@export var slider_extend_speed: float = 1.5
@export var revolute_spin_speed: float = 5.0

# ── Limb data ────────────────────────────────────────────────────────────

const JOINT_NAMES: Array[String] = [
	"HINGE", "BALL", "SLIDER", "REVOLUTE", "PRISMATIC", "FIXED"
]

const JOINT_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.2),   # HINGE - red-orange
	Color(0.2, 0.7, 0.9),   # BALL - cyan
	Color(0.2, 0.9, 0.3),   # SLIDER - green
	Color(0.9, 0.9, 0.2),   # REVOLUTE - yellow
	Color(0.7, 0.2, 0.9),   # PRISMATIC - purple
	Color(0.5, 0.5, 0.5),   # FIXED - gray
]

# Limb attachment directions (unit vectors from center)
const LIMB_DIRS: Array[Vector3] = [
	Vector3(1, 0, 0),     # HINGE - right (leg 1)
	Vector3(-1, 0, 0),    # BALL  - left (leg 2)
	Vector3(0, 1, 0),     # SLIDER - top
	Vector3(0, -1, 0),    # REVOLUTE - bottom (but body is raised)
	Vector3(0, 0, 1),     # PRISMATIC - front
	Vector3(0, 0, -1),    # FIXED - back
]

# ── Visual refs ──────────────────────────────────────────────────────────

var _body_mi: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _limb_roots: Array[Node3D] = []
var _arm_meshes: Array[MeshInstance3D] = []
var _joint_meshes: Array[MeshInstance3D] = []
var _joint_materials: Array[StandardMaterial3D] = []

# Animation state
var _time: float = 0.0
var _slider_extension: float = 0.0
var _slider_direction: float = 1.0
var _prismatic_extension: float = 0.0
var _prismatic_direction: float = 1.0
var _walk_phase: float = 0.0
var _attack_time: float = 0.0


func _on_ready() -> void:
	max_health = 90.0
	_health = max_health
	chase_speed = 2.5
	patrol_speed = 1.0
	contact_damage = 12.0


func _create_materials() -> void:
	_body_mat = _make_material(Color(0.25, 0.25, 0.3), Color(0.05, 0.05, 0.1))
	_joint_materials.clear()
	for i in range(6):
		var mat := _make_material(JOINT_COLORS[i], JOINT_COLORS[i] * 0.5)
		_joint_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(body_size * 2.0, body_size * 2.0, body_size * 2.0)
	col.shape = shape
	col.position.y = body_size + arm_length * 0.5
	add_child(col)


func _build_mesh() -> void:
	# Raise mesh root so creature walks on its lower limbs
	_mesh_root.position.y = body_size + arm_length * 0.6

	# Central body
	var box := BoxMesh.new()
	box.size = Vector3(body_size, body_size, body_size)
	_body_mi = _add_mesh(box, _body_mat)

	# Build 6 limbs
	for i in range(6):
		_build_limb(i)


func _build_limb(index: int) -> void:
	var root := Node3D.new()
	root.name = "Limb_%s" % JOINT_NAMES[index]
	root.position = LIMB_DIRS[index] * (body_size * 0.5)
	_mesh_root.add_child(root)
	_limb_roots.append(root)

	# Joint marker sphere at the base
	var joint_sphere := SphereMesh.new()
	joint_sphere.radius = joint_marker_radius
	joint_sphere.height = joint_marker_radius * 2.0
	var joint_mi := MeshInstance3D.new()
	joint_mi.mesh = joint_sphere
	joint_mi.set_surface_override_material(0, _joint_materials[index])
	root.add_child(joint_mi)
	_joint_meshes.append(joint_mi)

	# Arm cylinder extending outward from joint
	var cyl := CylinderMesh.new()
	cyl.height = arm_length
	cyl.top_radius = arm_radius
	cyl.bottom_radius = arm_radius
	var arm_mi := MeshInstance3D.new()
	arm_mi.mesh = cyl
	var arm_mat := _make_material(JOINT_COLORS[index] * 0.7, Color.BLACK)
	arm_mi.set_surface_override_material(0, arm_mat)

	# Position arm so it extends outward from the joint
	var dir := LIMB_DIRS[index]
	arm_mi.position = dir * (arm_length * 0.5)

	# Rotate cylinder to align with limb direction
	if abs(dir.y) < 0.9:
		arm_mi.look_at_from_position(arm_mi.position, arm_mi.position + dir, Vector3.UP)
		arm_mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	elif dir.y < 0:
		# pointing down - default cylinder orientation is fine
		pass
	# else pointing up - also fine

	root.add_child(arm_mi)
	_arm_meshes.append(arm_mi)


func _process_visual(delta: float) -> void:
	_time += delta

	# Walk phase (legs are limbs 0=HINGE and 1=BALL)
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 3.0
		_animate_walk()

	# Animate each joint type
	_animate_hinge(delta)
	_animate_ball(delta)
	_animate_slider(delta)
	_animate_revolute(delta)
	_animate_prismatic(delta)
	# FIXED: no animation (intentionally rigid)


func _animate_walk() -> void:
	# Hinge leg (index 0) - swing in Z axis
	if _limb_roots.size() > 0:
		_limb_roots[0].rotation.z = sin(_walk_phase) * 0.4
	# Ball leg (index 1) - swing with slight twist
	if _limb_roots.size() > 1:
		_limb_roots[1].rotation.z = sin(_walk_phase + PI) * 0.4
		_limb_roots[1].rotation.x = sin(_walk_phase * 0.5) * 0.1


func _animate_hinge(delta: float) -> void:
	# Hinge: swing in one axis only
	if _limb_roots.size() > 0:
		if _state != BaseState.PATROL and _state != BaseState.CHASE:
			_limb_roots[0].rotation.z = sin(_time * 2.0) * 0.6


func _animate_ball(delta: float) -> void:
	# Ball: free rotation on multiple axes
	if _limb_roots.size() > 1:
		if _state != BaseState.PATROL and _state != BaseState.CHASE:
			_limb_roots[1].rotation.x = sin(_time * 1.5) * 0.4
			_limb_roots[1].rotation.z = cos(_time * 1.8) * 0.3


func _animate_slider(delta: float) -> void:
	# Slider: extend/retract along its axis
	if _limb_roots.size() > 2:
		_slider_extension += delta * slider_extend_speed * _slider_direction
		if _slider_extension > 1.0:
			_slider_extension = 1.0
			_slider_direction = -1.0
		elif _slider_extension < 0.0:
			_slider_extension = 0.0
			_slider_direction = 1.0
		if _arm_meshes.size() > 2:
			var base_pos := LIMB_DIRS[2] * (arm_length * 0.5)
			_arm_meshes[2].position = base_pos + LIMB_DIRS[2] * (_slider_extension * arm_length * 0.5)


func _animate_revolute(delta: float) -> void:
	# Revolute: continuous spin around the arm axis
	if _limb_roots.size() > 3:
		_limb_roots[3].rotation.y += delta * revolute_spin_speed


func _animate_prismatic(delta: float) -> void:
	# Prismatic: telescoping (scale the arm length)
	if _limb_roots.size() > 4:
		_prismatic_extension += delta * 0.8 * _prismatic_direction
		if _prismatic_extension > 1.0:
			_prismatic_extension = 1.0
			_prismatic_direction = -1.0
		elif _prismatic_extension < 0.0:
			_prismatic_extension = 0.0
			_prismatic_direction = 1.0
		if _arm_meshes.size() > 4:
			var scale_factor: float = 1.0 + _prismatic_extension * 0.8
			_arm_meshes[4].scale.y = scale_factor


func _process_chase(delta: float) -> void:
	var dist := _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	_attack_time += delta
	_walk_phase += delta * 4.0
	_animate_walk()

	# Move toward player
	if is_instance_valid(_player_node):
		var dir := _get_player_direction()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		velocity.y = 0.0
		_face_direction(dir, delta * 5.0)
	else:
		velocity = Vector3.ZERO

	# Joint-constrained attacks when close
	if dist < 1.5:
		_attack_with_joints(delta)


func _attack_with_joints(delta: float) -> void:
	# Hinge: fast swipe
	if _limb_roots.size() > 0:
		_limb_roots[0].rotation.z = sin(_attack_time * 8.0) * 1.0

	# Ball: reach around toward player
	if _limb_roots.size() > 1:
		var dir := _get_player_direction()
		_limb_roots[1].rotation.x = dir.z * 0.8
		_limb_roots[1].rotation.z = -dir.x * 0.8

	# Slider: punch outward
	if _limb_roots.size() > 2 and _arm_meshes.size() > 2:
		var punch: float = absf(sin(_attack_time * 6.0))
		_arm_meshes[2].position = LIMB_DIRS[2] * (arm_length * 0.5 + punch * arm_length)

	# Revolute: spin fast as weapon
	if _limb_roots.size() > 3:
		_limb_roots[3].rotation.y += delta * revolute_spin_speed * 3.0


func _on_damaged(_amount: float) -> void:
	# Briefly freeze all joints
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_attack_time = 0.0
