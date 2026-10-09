extends Node3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION — pendulum_slap, 2026-08-12. ONE AXIS.
#
#   anvil    WHAT THE BLOW LANDS ON
#            none · slab · cushion · curtain          (default: none)
#
# THE SLAP TEST HAD NOTHING TO SLAP. This file built an anchor, two capsules, two
# PinJoint3Ds and a paddle, and stopped. `setup_scene()` and `setup_soft_body()` were
# both commented out in _ready(), and `soft_body_pressure` is read by nothing in the
# file — six placements in SoftBodies_Obsticals_Part1 of an arm hitting air, in the
# sequence whose truth line is that form emerges from the material's own dynamics.
# `anvil` is the artifact's own README ("impulsive force meeting compliance") made
# buildable: one load, four compliances, four different resting pictures.
#
#   none     The shipped void. Nothing in the path; the arm rests wherever gravity and
#            the lean leave it.
#   slab     A rigid StaticBody3D box. Undentable, so the whole deflection is in the
#            ARM: it is stopped short of its own rest angle and presses there.
#   cushion  A compliant SoftBody3D pad stretched in a rigid frame, with a backing
#            plate half a paddle-width behind it. The arm sinks into a crater and the
#            deflection is SHARED between arm and target.
#   curtain  A SoftBody3D sheet hung from a rail, pinned along its top row only. The
#            arm barely deflects — cloth has no resistance to give, only travel — and
#            the sheet wraps the paddle and bellies out behind it.
#
# NOT `assay` (jelly_cube, softmill, revolving_joy_ride, softbody_gallery_part2): that
# word names the APPARATUS ARRANGED AROUND a specimen, and the anvil is half the
# physics — it is what the arm collides with, not what is watching it. NOT `substance`
# (breathing_room): that axis is the material a body is MADE OF; this one names what is
# standing in the arm's path at all. NOT `support` (code_display) — nothing here stands
# on anything. NOT `suspension` (cloth_straps, spring_system) — nothing here hangs.
#
# THE DEFAULT IS A SHORT-CIRCUIT. _build_anvil() returns on its first line when
# anvil == "none", before a single Node is constructed, so the tree is what it always
# was: anchor, upper arm, joint1, lower arm, joint2 — with the paddle mesh and its
# collider under the lower arm, in that order. All SIX placements are the bare token
# `pendulum_slap` in ONE map (SoftBodies_Obsticals_Part1, interactables rows 2, 6 and
# 10): no rotation suffix, no y_offset, no #key:value. GridInteractablesComponent only
# calls apply_grid_config when merged_config is non-empty, and this entry carries no
# default_params and no delegate — so none of the six ever reaches the new code.
#
# ── DETERMINISM IS THE DELIVERABLE, AND AS SHIPPED THERE WAS NONE ────────────
#
# Both RigidBody3Ds carry zero linear_damp and zero angular_damp, so the pendulum never
# rests; the opening impulse arrives on a deferred idle call whose offset from the
# physics tick varies; and a driven double pendulum is chaotic, so two runs at the same
# impulse are not two photographs of the same thing. At the sweep's ~1.45 s the arm is
# somewhere in its second swing and where is a coin toss.
#
# Three new exports replace that transient with an ATTRACTOR. All three are strict
# no-ops at their defaults:
#   initial_impulse  50.0  the literal from apply_initial_impulse(). The deferred kick
#                          is only scheduled when it is non-zero.
#   settle_damp       0.0  guards its whole branch; at 0 neither body is touched.
#   lean_force        0.0  guards its whole branch; at 0 no constant_force is set.
# At the fixture's (0.0, 6.0, 26.0) the arm is never kicked, is damped, and is pushed by a
# CONSTANT force toward the anvil, so it has an attracting fixed point instead of a swing.
#
# THAT WAS NOT ENOUGH, AND THE ARITHMETIC IS WHY. A damping figure of 6.0 is a rate on
# VELOCITY; it is not the settling time constant, and here the two differ by 6.5x. The
# rig is overdamped (zeta 1.386), so it settles on its SLOW pole at -0.922 /s — tau 1.08 s
# — and from plumb the paddle first touches the anvil at t = 1.319 s. The sweep shoots the
# render instance after ONE settle of 1.1 s (the 0.35 s pre-pass is a separate probe, freed
# again), so the paddle was 5.8 cm short of the anvil IN EVERY TILE: four photographs of
# the same untouched arm with different scenery behind it. See _pose_lean(), which builds
# each value at its own rest state instead of waiting for one.
#
# The lean is `RigidBody3D.constant_force`, not an apply_central_force() called from
# _physics_process. Same physics, applied by the engine inside the step, so the result
# does not depend on how many render frames the headless bench fitted between two
# physics ticks. _physics_process stays the no-op it already was.
#
# WHERE THE ANVIL STANDS IS DERIVED, NOT TYPED. An anvil placed further out than the
# arm's own driven rest angle is never reached, and four values then photograph one
# picture. So _anvil_lean() computes the arm's resting angle from lean_force and the
# lower arm's mass — atan(F / m g) — and stands the anvil at 0.6 of it, which is the
# only way to guarantee the arm arrives PRESSING rather than merely arriving. At the
# fixture that is 8.9 degrees off plumb against a free rest of 14.9 degrees.
#
# THE SOFT SURFACES ARE GENERATED HERE, NOT TAKEN FROM PlaneMesh. SoftBody3D's point
# indices are the physics solver's WELDED vertex order — an engine internal — so
# set_point_pinned() against a PlaneMesh is a guess that has to be verified by printing
# the array back. _sheet_mesh() emits a grid with no duplicate vertices at all, in a
# stated order, so vertex(row, col) == row * (cols + 1) + col is a fact about this file.
#
# NOT PROMOTED, AND WHY. `slap_force` (20.0) and `initial_impulse` (50.0) — how hard the
# arm is kicked. A kick is exactly what this artifact cannot photograph: no damping
# means it never comes to rest, the number of physics ticks between the kick and the
# shutter is a fact about the machine, and a driven double pendulum is chaotic.
# Sweeping it would produce confidently different tiles and a bite number that is pure
# frame clock. Also declined as AXES: `pendulum_height` and `arm_length` are scale, and
# the sweep's union-AABB camera divides scale straight back out. They stay plain exports
# (the fixture shrinks the rig with them), and `paddle_size` joins them holding the 1.5
# that was hard-coded in two places, so the rig can shrink without the paddle ending up
# larger than the arm.
#
# NO RNG ANYWHERE IN THIS FILE — zero randf/randi calls — so there is no seed to set.
# `soft_body_pressure` is left exactly as it was: still exported, still read by nothing.
# The pad is a stretched membrane rather than a closed volume, so a pressure coefficient
# would have nothing to act on; wiring it would be a second promotion wearing this one's
# clothes.
# ─────────────────────────────────────────────────────────────────────────────

# Configuration
@export var pendulum_height: float = 8.0
@export var arm_length: float = 3.5
@export var soft_body_pressure: float = 2.5
@export var slap_force: float = 20.0

## AXIS — what the blow lands on. `none` is the shipped void.
@export_enum("none", "slab", "cushion", "curtain") var anvil: String = "none"

## The opening kick, in newton-seconds along +Z. 50.0 is the literal that shipped in
## apply_initial_impulse(). 0.0 schedules no deferred call at all, which is what the
## capture bench needs: a kick is a transient and the shutter cannot photograph one.
@export var initial_impulse: float = 50.0

## linear_damp and angular_damp (DAMP_MODE_REPLACE) on both arm bodies. 0.0 = as
## shipped, which is no damping and therefore no rest state.
@export var settle_damp: float = 0.0

## A constant force along -Z on the lower arm — the artifact's own "forward", the
## direction slap_force pushes. Turns a strike into a LOAD and a transient into an
## attractor. 0.0 = as shipped.
@export var lean_force: float = 0.0

## The paddle's width and height. Was the bare literal 1.5 in two places. Its depth is
## a third of it, which is the shipped 0.5 — see _paddle_extent(), which short-circuits
## to the exact shipped Vector3 at the default.
@export var paddle_size: float = 1.5

## The allow-list a map token is checked against. An unknown word keeps the shipped
## void rather than stranding a placement with a body nobody declared.
const ANVILS: PackedStringArray = ["none", "slab", "cushion", "curtain"]

## The shipped literals, named so a short-circuit can return them rather than re-derive
## them, and so the lean arithmetic can read the mass it actually depends on.
const LOWER_ARM_MASS: float = 10.0
const UPPER_ARM_MASS: float = 2.0
const PADDLE_LITERAL := Vector3(1.5, 1.5, 0.5)

## Where the anvil stands, as an angle off plumb measured at the paddle.
## ANVIL_LEAN_FRACTION is of the arm's OWN driven rest angle: below 1.0 the arm is
## stopped short and presses; at or above 1.0 it drifts to a stop just touching, or
## never touches, and the axis dies quietly. ANVIL_LEAN_IDLE is the fallback when
## nothing drives the arm (lean_force 0 — every in-game placement), where the anvil has
## to stand somewhere the swinging arm will strike it.
const ANVIL_LEAN_IDLE: float = 0.35
const ANVIL_LEAN_FRACTION: float = 0.6

## One grey for everything rigid and one off-white for everything compliant, so the
## axis is read as SHAPE and a sweep cannot mistake a repaint for a structural
## difference. The two soft values deliberately share a colour: they are the predicted
## closest pair and nothing here should flatter them.
const RIGID_COLOR := Color(0.55, 0.56, 0.58)
const SOFT_COLOR := Color(0.86, 0.84, 0.78)

var lower_arm: RigidBody3D

## LAW 6. Only what this script built is this script's to free. The old _exit_tree()
## freed every child without an owner, which includes anything the grid attached to the
## artifact after spawn.
var _owned: Array[Node] = []
var _built: bool = false
var _config_sig: String = ""

func _ready() -> void:
	# setup_scene()
	# setup_soft_body()   <- what _build_anvil() finally is
	_build()
	if initial_impulse != 0.0:
		call_deferred("apply_initial_impulse")
	_built = true
	_config_sig = _signature()

## Everything the artifact is, built synchronously. Called from _ready() and from
## apply_grid_config() after a real change; nothing here is deferred.
func _build() -> void:
	setup_pendulum()
	_build_anvil()

func apply_initial_impulse() -> void:
	if lower_arm:
		# Swing it back first so it hits forward
		lower_arm.apply_central_impulse(Vector3(0, 0, initial_impulse))


func setup_pendulum() -> void:
	# Anchor
	var anchor = StaticBody3D.new()
	anchor.position = Vector3(0, pendulum_height, 0)
	add_child(anchor)
	_owned.append(anchor)

	# Upper Arm
	var upper_arm: RigidBody3D = create_link(Vector3(0, pendulum_height - arm_length/2.0, 0), Color.RED)
	add_child(upper_arm)
	_owned.append(upper_arm)

	# Joint 1
	var joint1 = PinJoint3D.new()
	joint1.node_a = anchor.get_path()
	joint1.node_b = upper_arm.get_path()
	joint1.position = anchor.position
	# Allow swinging in Z axis (slapping forward/back)
	# PinJoint3D aligns with Z axis by default? No, it pins A and B.
	# We want it to swing like a pendulum.
	add_child(joint1)
	_owned.append(joint1)

	# Lower Arm (The Slapper)
	lower_arm = create_link(Vector3(0, pendulum_height - arm_length - arm_length/2.0, 0), Color.BLUE)
	# Make it heavier to slap hard
	lower_arm.mass = LOWER_ARM_MASS
	add_child(lower_arm)
	_owned.append(lower_arm)

	# Joint 2
	var joint2 = PinJoint3D.new()
	joint2.node_a = upper_arm.get_path()
	joint2.node_b = lower_arm.get_path()
	joint2.position = Vector3(0, pendulum_height - arm_length, 0)
	add_child(joint2)
	_owned.append(joint2)

	# Add a "Hand" or "Paddle" to the end of lower arm
	var extent: Vector3 = _paddle_extent()
	var paddle = MeshInstance3D.new()
	paddle.mesh = BoxMesh.new()
	(paddle.mesh as BoxMesh).size = extent
	paddle.position = Vector3(0, -arm_length/2.0, 0)
	lower_arm.add_child(paddle)

	var paddle_col = CollisionShape3D.new()
	paddle_col.shape = BoxShape3D.new()
	(paddle_col.shape as BoxShape3D).size = extent
	paddle_col.position = Vector3(0, -arm_length/2.0, 0)
	lower_arm.add_child(paddle_col)

	# Both guarded, both no-ops at the shipped defaults, both after the tree is built so
	# the child order above is untouched.
	_damp(upper_arm)
	_damp(lower_arm)
	if lean_force != 0.0:
		lower_arm.constant_force = Vector3(0.0, 0.0, -lean_force)
		_pose_lean(upper_arm, joint2, lower_arm)

func create_link(pos: Vector3, color: Color) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = UPPER_ARM_MASS

	var mesh = CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = arm_length
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var shape = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	(shape.shape as CapsuleShape3D).radius = 0.3
	(shape.shape as CapsuleShape3D).height = arm_length
	body.add_child(shape)

	return body


## The paddle box. At the default this returns the exact literal the two hard-coded
## lines used to build, with no arithmetic in the path at all.
func _paddle_extent() -> Vector3:
	if paddle_size == 1.5:
		return PADDLE_LITERAL
	return Vector3(paddle_size, paddle_size, paddle_size / 3.0)


## Damping, and only when asked. At settle_damp 0.0 neither body is touched, so both
## keep Godot's defaults exactly as they shipped.
func _damp(body: RigidBody3D) -> void:
	if settle_damp <= 0.0:
		return
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.linear_damp = settle_damp
	body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.angular_damp = settle_damp


## The angle off plumb at which the anvil is met, in radians.
##
## THIS IS THE NUMBER THE WHOLE AXIS HANGS ON. Under a constant lean_force the lower arm
## comes to rest at atan(F / m g). An anvil standing at a LARGER angle than that is
## never touched, and slab, cushion and curtain then differ from each other only by
## which unused object is parked behind the arm. Standing it at 0.6 of the rest angle
## guarantees contact with a third of the travel to spare.
func _anvil_lean() -> float:
	if lean_force <= 0.0:
		# Nothing drives the arm: it is either plumb or swinging from the opening
		# impulse. A fixed angle it can reach on a swing is the only meaningful choice.
		return ANVIL_LEAN_IDLE
	var g: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var free_lean: float = atan(lean_force / maxf(LOWER_ARM_MASS * maxf(g, 0.001), 0.001))
	return clampf(free_lean * ANVIL_LEAN_FRACTION, 0.05, ANVIL_LEAN_IDLE)


## A point `dist` from the anchor down an arm leaning by `lean`. Rotation about +X
## carries (0, -d, 0) to (0, -d cos, -d sin), which is why every anvil is at NEGATIVE z.
func _arc(dist: float, lean: float) -> Vector3:
	return Vector3(0.0, pendulum_height - dist * cos(lean), -dist * sin(lean))


## Where the paddle's centre sits when the rig leans by _anvil_lean(). _pose_lean() below
## BUILDS the rig at exactly this angle for every anvil value, so this is not an
## approximation of a pose the arm might reach — it is the pose the arm is placed in.
func _contact_point() -> Vector3:
	return _arc(arm_length * 2.0, _anvil_lean())


## The two links' true resting angles under the lean, with nothing in the way. They are
## NOT equal: the upper link carries the lower one's weight as well as its own, so it
## hangs closer to plumb. Torque balance about each joint gives
##   lower: tan t2 = F / (m_low g)                     — the same number _anvil_lean() uses
##   upper: tan t1 = F / ((m_low + m_up/2) g)
## which is 13.56 deg against 14.86 deg at the fixture.
func _free_leans() -> Vector2:
	if lean_force <= 0.0:
		return Vector2.ZERO
	var g: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	g = maxf(g, 0.001)
	var t2: float = atan(lean_force / maxf(LOWER_ARM_MASS * g, 0.001))
	var t1: float = atan(lean_force / maxf((LOWER_ARM_MASS + UPPER_ARM_MASS * 0.5) * g, 0.001))
	return Vector2(t1, t2)


## THE ARM IS BUILT WHERE IT ENDS UP, NOT WHERE IT STARTS. This is the pose-pinning the
## wave asks for, and it is here because the arithmetic said the waiting version does not
## work — MEASURED, not assumed:
##
##   With settle_damp 6.0 the rig is OVERDAMPED, and an overdamped system's approach is
##   governed by its SLOW pole, not by the damping rate. About the anchor the merged arm
##   has I = 51.75 kg m^2 and restoring stiffness k = 242.4 N m/rad, so wn = 2.164 rad/s
##   and zeta = 1.386; the slow pole is -wn(zeta - sqrt(zeta^2-1)) = -0.922 /s, a settling
##   time constant of 1.08 s — SIX AND A HALF TIMES the 1/6 s that the damping figure of
##   6.0 suggests, and the two are not the same quantity.
##
##   Starting from plumb the paddle first touches the anvil at t = 1.319 s.
##   capture_config_sweep photographs the render instance after ONE settle of 1.1 s: its
##   0.35 s pre-pass is a separate probe that is freed again (line 285), so the two do not
##   add. At the shutter the paddle is 5.8 cm SHORT of the anvil face in every tile.
##
## That is not a slow axis, it is a false one. slab, cushion and curtain would each have
## photographed a different piece of scenery standing behind an arm in the identical
## untouched pose, and the axis would have scored a confident bite made entirely of
## furniture — the operations_gallery failure, where every gate stays green and the
## number is about something nobody is arguing.
##
## Neither knob in the fixture rescues it. Raising lean_force does nothing, because
## _anvil_lean() scales the anvil's angle WITH the force: the fraction of travel before
## contact is invariant and so is the time. Raising settle_damp makes it WORSE, the slow
## pole going as k/(I d). So the pose is pinned rather than waited for.
##
## Each value is built at ITS OWN rest state, which is the only version of this that is
## still at frame 0:
##   none                     the true free equilibrium, both links at _free_leans().
##                            Zero net torque, zero velocity, nothing to settle.
##   slab/cushion/curtain     both links at _anvil_lean(), which puts the paddle's front
##                            face exactly on the anvil plane with the lean still pressing
##                            it there (free rest is 14.86 deg against this 8.92, so a
##                            third of the travel is blocked and the arm is loaded).
## What is left to settle is the contact itself and the small internal rearrangement
## between the two links — both governed by the FAST pole at 5.08 /s (tau 0.20 s), gone
## inside 0.6 s of the 1.1 s budget.
func _pose_lean(upper: RigidBody3D, joint2: PinJoint3D, lower: RigidBody3D) -> void:
	var t1: float = _anvil_lean()
	var t2: float = t1
	if anvil == "none":
		# Nothing to press on, so the resting pose is the free one — and its two links
		# rest at DIFFERENT angles, which a single arc cannot express.
		var free: Vector2 = _free_leans()
		t1 = free.x
		t2 = free.y
	var half: float = arm_length * 0.5
	upper.position = _arc(half, t1)
	upper.rotation.x = t1
	var elbow: Vector3 = _arc(arm_length, t1)
	joint2.position = elbow
	lower.position = elbow + Vector3(0.0, -half * cos(t2), -half * sin(t2))
	lower.rotation.x = t2


## THE SHORT-CIRCUIT. At "none" this returns before a single Node is constructed.
func _build_anvil() -> void:
	if anvil == "none":
		return
	var extent: Vector3 = _paddle_extent()
	var contact: Vector3 = _contact_point()
	# The plane the paddle's front face reaches. Every value puts its working surface
	# here, so what differs between the tiles is compliance and not distance.
	var face_z: float = contact.z - extent.z * 0.5

	var root := Node3D.new()
	root.name = "Anvil"
	add_child(root)
	_owned.append(root)

	match anvil:
		"slab":
			_anvil_slab(root, extent, contact, face_z)
		"cushion":
			_anvil_cushion(root, extent, contact, face_z)
		"curtain":
			_anvil_curtain(root, extent, contact, face_z)
		_:
			# An unknown word keeps the void: remove the empty root again so the tree
			# is byte-identical to "none" rather than carrying a stray Node3D.
			root.get_parent().remove_child(root)
			_owned.erase(root)
			root.queue_free()


## A rigid box standing on the floor, its front face on the contact plane. Undentable,
## so the arm stops at _anvil_lean() and every degree of deflection is in the arm.
func _anvil_slab(root: Node3D, extent: Vector3, contact: Vector3, face_z: float) -> void:
	var w: float = extent.x * 2.4
	var top: float = contact.y + extent.y * 0.75
	var depth: float = extent.x * 0.6
	var body := StaticBody3D.new()
	body.name = "Slab"
	root.add_child(body)
	_box(body, Vector3(w, top, depth), Vector3(0.0, top * 0.5, face_z - depth * 0.5),
		RIGID_COLOR, false, true)


## A membrane stretched in a rigid frame, with a backing plate half a paddle-width
## behind it. The frame and the plate are what make this a REST rather than a race: if
## the membrane holds, the arm stops in a crater; if it does not, the arm stops on the
## plate with the cloth wrapped around the paddle. Either way the shutter finds it still.
func _anvil_cushion(root: Node3D, extent: Vector3, contact: Vector3, face_z: float) -> void:
	var w: float = extent.x * 2.0
	var h: float = extent.y * 1.2
	var crater: float = extent.y * 0.5
	var bar: float = extent.x * 0.16
	var top: float = contact.y + h * 0.5 + bar

	var frame := StaticBody3D.new()
	frame.name = "Pad"
	root.add_child(frame)
	# Two posts to the floor, a head bar across them, and the backing plate.
	var post_z: float = face_z - crater * 0.5
	_box(frame, Vector3(bar, top, bar), Vector3(-(w * 0.5 + bar * 0.5), top * 0.5, post_z),
		RIGID_COLOR, false, true)
	_box(frame, Vector3(bar, top, bar), Vector3(w * 0.5 + bar * 0.5, top * 0.5, post_z),
		RIGID_COLOR, false, true)
	_box(frame, Vector3(w + bar * 2.0, bar, bar), Vector3(0.0, top, post_z),
		RIGID_COLOR, false, true)
	_box(frame, Vector3(w, h, bar), Vector3(0.0, contact.y, face_z - crater - bar * 0.5),
		RIGID_COLOR, false, true)

	var pad := SoftBody3D.new()
	pad.name = "PadFace"
	pad.mesh = _sheet_mesh(w, h, 8, 8)
	pad.material_override = _material(SOFT_COLOR, true)
	pad.position = Vector3(0.0, contact.y, face_z)
	pad.simulation_precision = 8
	pad.total_mass = 2.0
	pad.linear_stiffness = 0.25
	pad.damping_coefficient = 0.9
	pad.drag_coefficient = 0.1
	root.add_child(pad)
	_pin_border(pad, 8, 8)


## A sheet hung from a rail, pinned along its top row only. No backing, no tension: the
## arm passes almost as far as it would with nothing there, and the difference in the
## frame is the cloth wrapping the paddle and bellying out behind it.
func _anvil_curtain(root: Node3D, extent: Vector3, contact: Vector3, face_z: float) -> void:
	var w: float = extent.x * 3.0
	var bar: float = extent.x * 0.16
	var rail_y: float = contact.y + extent.y * 1.1

	var rig := StaticBody3D.new()
	rig.name = "Rail"
	root.add_child(rig)
	var rail_z: float = face_z - bar * 0.5
	_box(rig, Vector3(bar, rail_y, bar), Vector3(-(w * 0.5 + bar * 0.5), rail_y * 0.5, rail_z),
		RIGID_COLOR, false, true)
	_box(rig, Vector3(bar, rail_y, bar), Vector3(w * 0.5 + bar * 0.5, rail_y * 0.5, rail_z),
		RIGID_COLOR, false, true)
	_box(rig, Vector3(w + bar * 2.0, bar, bar), Vector3(0.0, rail_y, rail_z),
		RIGID_COLOR, false, true)

	var h: float = rail_y - bar * 0.5
	var sheet := SoftBody3D.new()
	sheet.name = "Sheet"
	sheet.mesh = _sheet_mesh(w, h, 10, 12)
	sheet.material_override = _material(SOFT_COLOR, true)
	sheet.position = Vector3(0.0, (rail_y - bar * 0.5) - h * 0.5, face_z)
	sheet.simulation_precision = 6
	sheet.total_mass = 1.5
	sheet.linear_stiffness = 0.6
	sheet.damping_coefficient = 0.7
	sheet.drag_coefficient = 0.35
	root.add_child(sheet)
	_pin_top(sheet, 10)


## A rectangular grid with NO duplicate vertices, so the index of every point is known
## by arithmetic: vertex(row, col) == row * (cols + 1) + col, row 0 the top edge.
##
## This is the whole reason the soft surfaces are not PlaneMesh. SoftBody3D's point
## indices are the physics server's welded vertex order — an engine internal that has to
## be verified by printing ARRAY_VERTEX back — and a pin aimed at the wrong index is a
## sheet that falls on the floor while every gate stays green.
func _sheet_mesh(w: float, h: float, cols: int, rows: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for r in range(rows + 1):
		var fy: float = float(r) / float(rows)
		for c in range(cols + 1):
			var fx: float = float(c) / float(cols)
			verts.append(Vector3((fx - 0.5) * w, (0.5 - fy) * h, 0.0))
			norms.append(Vector3(0.0, 0.0, 1.0))
			uvs.append(Vector2(fx, fy))
	for r in range(rows):
		for c in range(cols):
			var a: int = r * (cols + 1) + c
			var b: int = a + 1
			var d: int = a + cols + 1
			var e: int = d + 1
			idx.append(a)
			idx.append(d)
			idx.append(b)
			idx.append(b)
			idx.append(d)
			idx.append(e)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Pin the top row. Called AFTER add_child: SoftBody3D hands its mesh to the physics
## server on ENTER_TREE, and a pin set before that has nothing to pin.
func _pin_top(body: SoftBody3D, cols: int) -> void:
	for c in range(cols + 1):
		body.set_point_pinned(c, true)


## Pin the whole border, which is what makes the pad a stretched membrane rather than a
## flag. An empty attachment path pins in WORLD space at the point's built position, so
## no backing node is needed to hold it up.
func _pin_border(body: SoftBody3D, cols: int, rows: int) -> void:
	for c in range(cols + 1):
		body.set_point_pinned(c, true)
		body.set_point_pinned(rows * (cols + 1) + c, true)
	for r in range(1, rows):
		body.set_point_pinned(r * (cols + 1), true)
		body.set_point_pinned(r * (cols + 1) + cols, true)


func _material(color: Color, two_sided: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if two_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color,
		two_sided: bool, collide: bool) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = _material(color, two_sided)
	parent.add_child(mesh_inst)
	if collide:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		col.position = pos
		parent.add_child(col)


func _physics_process(_delta):
	# Add some periodic force to keep the pendulum swinging if needed
	# Or just let it swing from gravity if we start it offset
	# The lean is RigidBody3D.constant_force, set once in setup_pendulum(): the engine
	# applies it inside the physics step, so the rest pose does not depend on how many
	# frames the renderer fitted between two ticks.
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if lower_arm:
			# Slap!
			lower_arm.apply_central_impulse(Vector3(0, 0, -slap_force))

func _exit_tree() -> void:
	# WAS: every child without an owner — which includes anything the grid attached to
	# this artifact after spawn. Only what this script built is this script's to free.
	for node in _owned:
		if is_instance_valid(node):
			node.queue_free()
	_owned.clear()


## Every value the build reads, in one string. apply_grid_config compares this and
## returns early when nothing changed, so a repeated config never respawns a live rig.
func _signature() -> String:
	return "%s|%.6f|%.6f|%.6f|%.6f|%.6f|%.6f" % [anvil, pendulum_height, arm_length,
		paddle_size, initial_impulse, settle_damp, lean_force]


func _cfg_float(config: Dictionary, key: String, current: float) -> float:
	if not config.has(key):
		return current
	var raw = config[key]
	if raw is float or raw is int:
		return float(raw)
	if raw is String and (raw as String).is_valid_float():
		return float(raw)
	return current


func apply_grid_config(config: Dictionary) -> void:
	var want_anvil: String = anvil
	if config.has("anvil"):
		var raw: String = str(config["anvil"]).strip_edges().to_lower()
		# A typo must never publish a silent variant.
		if ANVILS.has(raw):
			want_anvil = raw
	var want_height: float = _cfg_float(config, "pendulum_height", pendulum_height)
	var want_arm: float = _cfg_float(config, "arm_length", arm_length)
	var want_paddle: float = _cfg_float(config, "paddle_size", paddle_size)
	var want_impulse: float = _cfg_float(config, "initial_impulse", initial_impulse)
	var want_damp: float = _cfg_float(config, "settle_damp", settle_damp)
	var want_lean: float = _cfg_float(config, "lean_force", lean_force)

	anvil = want_anvil
	pendulum_height = want_height
	arm_length = want_arm
	paddle_size = want_paddle
	initial_impulse = want_impulse
	settle_damp = want_damp
	lean_force = want_lean
	var after: String = _signature()
	# THE EARLY RETURN. _ready() records the built signature, so a config that repeats
	# the values already standing in the room rebuilds nothing.
	if after == _config_sig:
		return
	_config_sig = after
	if not _built:
		# _ready() has not run yet; it will build with these values on its own.
		return
	_rebuild()


func _rebuild() -> void:
	for node in _owned:
		if is_instance_valid(node):
			# Detach BEFORE freeing: queue_free() defers to the end of the frame, so a
			# replacement added first would collide with the old node's name.
			var parent: Node = node.get_parent()
			if parent != null:
				parent.remove_child(node)
			node.queue_free()
	_owned.clear()
	lower_arm = null
	_build()
	if initial_impulse != 0.0:
		call_deferred("apply_initial_impulse")
