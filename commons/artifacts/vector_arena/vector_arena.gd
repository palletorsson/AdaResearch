# VectorArena.gd
# A "math holodeck" where the player's two hands ARE the endpoints of a vector.
# Pull the LEFT trigger to place point A at your left hand; the RIGHT trigger to
# place point B at your right hand. A glowing arrow A->B draws between them with
# the live math floating beside it (AB = B - A, |AB|, dir). Charge with the RIGHT
# grip, then pull the RIGHT trigger to FIRE a ball from A whose velocity IS the
# vector: wider hands = harder shot. Fired balls reflect off a labeled wall using
# the literal reflection formula r = d - 2(d.n)n, with a live panel showing the
# arithmetic and the |r| = |d| invariant.
#
# @identity
# essence: AB = B - A. dir = AB / |AB|. Fire: v = AB * force_gain. Reflect:
#   r = d - 2(d.n_hat)n_hat. The hands are the vector; the vector is the force.
# desire: To make a vector a thing you hold with two hands and then throw —
#   subtraction you feel as the gap between your palms, magnitude you feel as reach.
# critical_parameter: force_gain — how much of |AB| becomes launch speed. The
#   vector between the hands is scaled by it into the fired ball's velocity.
# triggers: LEFT trigger -> place A; RIGHT trigger -> place B (or FIRE when charged);
#   RIGHT grip -> charge; ball hits wall -> reflect by formula.
# emerges: The realisation that B - A, a direction, a magnitude, and a force are
#   all the same arrow seen from different sides. Reflection preserves length.
# truth: A vector is the difference between two points. Once you can hold both
#   points, you can hold the difference — and once you can hold it, you can throw it.
extends "res://algorithms/vectors/shared/vector_scene_base.gd"
class_name VectorArena

# ── State machine ────────────────────────────────────────────────────────────
enum FireState { PLACING, CHARGED, FIRED }
var _fire_state: int = FireState.PLACING

# ── Tunable configuration (overridable via apply_grid_config) ────────────────
# challenge: 0..2 cosmetic difficulty tier (affects target sizing / labels).
var challenge: int = 1
# force_gain: how many m/s of launch speed per logical unit of |AB|.
var force_gain: float = 4.0
var projectile_lifetime: float = 6.0
var max_live_projectiles: int = 6
var ball_radius: float = 0.09          # logical radius (pre SCENE_SCALE)
var arena_gravity: float = 6.0         # gentle gravity so arcs read clearly

# Arrow geometry (local space, pre SCENE_SCALE — matches catapult conventions)
const ARROW_THICKNESS: float = 0.018

# Colors
var color_a: Color = Color(1.0, 0.45, 0.35, 1.0)        # warm = A
var color_b: Color = Color(0.35, 0.75, 1.0, 1.0)        # cool = B
var color_ab: Color = Color(0.55, 1.0, 0.45, 1.0)       # green = the live vector
var color_ghost: Color = Color(0.55, 1.0, 0.45, 0.35)   # faded green = intent
var color_ball: Color = Color(1.0, 0.85, 0.30, 1.0)     # fired projectile
var color_normal: Color = Color(0.9, 0.5, 1.0, 1.0)     # magenta = wall normal
var color_reflect: Color = Color(1.0, 0.7, 0.4, 1.0)    # orange = reflected ray

# ── Logical geometry (in this node's local space, BEFORE SCENE_SCALE) ────────
# Point A / B positions are stored as logical Vector3 (the values the math uses).
# Visual nodes are placed at logical * SCENE_SCALE.
var _point_a: Vector3 = Vector3(-1.2, 1.2, 0.0)
var _point_b: Vector3 = Vector3(1.2, 1.4, 0.0)

# Wall: a plane through _wall_center with unit normal _wall_normal (logical space).
var _wall_center: Vector3 = Vector3(0.0, 1.2, -2.4)
var _wall_normal: Vector3 = Vector3(0.0, 0.0, 1.0)  # faces +Z toward the player

# ── Node references ──────────────────────────────────────────────────────────
var _ab_arrow: Node3D = null
var _ghost_arrow: Node3D = null
var _normal_arrow: Node3D = null
var _marker_a: MeshInstance3D = null
var _marker_b: MeshInstance3D = null
var _ab_label: Label3D = null            # billboard beside the live arrow
var _a_label: Label3D = null
var _b_label: Label3D = null
var _readout_label: Label3D = null       # big centered billboard
var _info_label: Label = null          # two-column data | formula panel
var _reflect_label: Label = null         # flashes the reflection arithmetic
var _wall_mesh: MeshInstance3D = null
var _projectile_container: Node3D = null

# Material for fired balls (cached once).
var _ball_material: StandardMaterial3D = null

# ── Controller access ────────────────────────────────────────────────────────
var _xr_origin: XROrigin3D = null
var _left_controller: Node3D = null      # XRController3D, typed loose for safety
var _right_controller: Node3D = null
var _controllers_resolved: bool = false
var _have_controllers: bool = false
var _controller_retry: float = 0.0
const CONTROLLER_RETRY_INTERVAL: float = 1.0

# Edge-detection of button state (so trigger meanings stay crisp).
var _left_trigger_held: bool = false
var _right_trigger_held: bool = false
var _right_grip_held: bool = false

# ── Desktop / headless fallback ──────────────────────────────────────────────
# Two slowly-orbiting demo points so the arena always shows live AB math even
# with no controllers, plus a periodic auto-fire for meaningful headless capture.
var _demo_time: float = 0.0
var _auto_fire_cooldown: float = 0.0
const AUTO_FIRE_INTERVAL: float = 2.8

# ── Throttling (mirrors VectorAddition) ──────────────────────────────────────
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

# Brighten the live arrow while charged.
var _charge_glow: float = 0.0

# Flash timer for the reflection panel.
var _reflect_flash: float = 0.0


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Base _ready() creates environment_root / info_root and then calls
	# build_scene() (guarded by _scene_built). We just defer to it.
	super._ready()


func build_scene() -> void:
	# Scaled exhibition presentation (compact at scale_multiplier 1.0,
	# walk-inside at 5.0). base_scale() == 0.5 * scale_multiplier.
	scale = base_scale()

	create_floor(7.0, Color(0.08, 0.09, 0.12, 1.0))
	create_axes(1.5)

	_projectile_container = Node3D.new()
	_projectile_container.name = "Projectiles"
	add_child(_projectile_container)

	# ── The live A->B arrow (the heart of the artifact) ──
	_ab_arrow = _create_arrow("ABArrow", color_ab)
	add_child(_ab_arrow)

	# Ghost of the last fired AB — intent vs result comparison.
	_ghost_arrow = _create_arrow("GhostArrow", color_ghost)
	_ghost_arrow.visible = false
	add_child(_ghost_arrow)

	# Endpoint markers for A and B.
	_marker_a = _make_marker(color_a)
	add_child(_marker_a)
	_marker_b = _make_marker(color_b)
	add_child(_marker_b)

	# Per-endpoint labels.
	_a_label = _make_label("A", color_a, 20)
	add_child(_a_label)
	_b_label = _make_label("B", color_b, 20)
	add_child(_b_label)

	# Live arrow readout (billboard riding beside the AB arrow midpoint).
	_ab_label = _make_label("AB", color_ab, 18)
	add_child(_ab_label)

	# Big centered numeric readout.
	_readout_label = create_readout(Vector3(0.0, 2.6, 0.0), Color(0.7, 1.0, 0.6, 1.0))

	# Two-column info panel: live data | static formula stack.
	_info_label = create_info_panel(
		"Vector Arena",
		Vector3(0.0, 2.9, -1.0),
		Vector2(2.6, 1.1),
		"AB = B - A\ndir = AB / |AB|\nv = AB * gain\nr = d - 2(d.n)n",
		"Two hands = a vector. The vector = a force. Reflect by formula."
	)

	# ── The reflection wall + its visible unit normal ──
	_build_wall()
	_normal_arrow = _create_arrow("NormalArrow", color_normal)
	add_child(_normal_arrow)
	_position_normal_arrow()

	# Reflection arithmetic panel (hidden until a ball reflects).
	_reflect_label = create_info_panel(
		"Reflection",
		Vector3(0.0, 1.7, -2.55),
		Vector2(2.2, 0.95),
		"r = d - 2(d.n)n",
		"|r| = |d|  (reflection preserves length)"
	)
	if _reflect_label:
		_reflect_label.text = "(fire a ball at the wall)"

	# Resolve controllers (deferred so the XR tree is fully attached).
	call_deferred("_resolve_controllers")

	# Place markers + arrow at their initial logical positions.
	_refresh_visuals()


# ═════════════════════════════════════════════════════════════════════════
# CONTROLLER RESOLUTION (graceful degradation)
# ═════════════════════════════════════════════════════════════════════════

## Walk up to the XROrigin3D and grab the two XRController3D children. Mirrors
## capacity_bracelet._get_other_controller() + vector_drone's XR search. Safe on
## desktop/headless: simply leaves _have_controllers false and uses the demo path.
func _resolve_controllers() -> void:
	_controllers_resolved = true
	_xr_origin = _find_xr_origin()
	if _xr_origin == null:
		_have_controllers = false
		return

	var controllers := _xr_origin.find_children("*", "XRController3D", true, false)
	for c in controllers:
		if not is_instance_valid(c):
			continue
		# tracker name is the robust hand discriminator across rigs.
		var hand_name := ""
		if "tracker" in c:
			hand_name = str(c.get("tracker"))
		var n := str(c.name).to_lower()
		if hand_name == "left_hand" or n.find("left") != -1:
			_left_controller = c
		elif hand_name == "right_hand" or n.find("right") != -1:
			_right_controller = c

	# If naming was ambiguous, take the first two we found in order.
	if (_left_controller == null or _right_controller == null) and controllers.size() >= 2:
		if _left_controller == null:
			_left_controller = controllers[0]
		if _right_controller == null:
			for c in controllers:
				if c != _left_controller:
					_right_controller = c
					break

	_have_controllers = _left_controller != null and _right_controller != null


func _find_xr_origin() -> XROrigin3D:
	# Walk up our own parents first (the artifact is placed under the world).
	var node: Node = self
	while node != null:
		if node is XROrigin3D:
			return node as XROrigin3D
		node = node.get_parent()
	# Fall back to a tree-wide search from the root.
	var tree := get_tree()
	if tree == null:
		return null
	if tree.root == null:
		return null
	return _search_xr_origin(tree.root)


func _search_xr_origin(node: Node) -> XROrigin3D:
	if node is XROrigin3D:
		return node as XROrigin3D
	for child in node.get_children():
		var found := _search_xr_origin(child)
		if found != null:
			return found
	return null


## Read a controller's button safely. Returns false if unavailable.
func _controller_button(controller: Node, action: String) -> bool:
	if controller == null or not is_instance_valid(controller):
		return false
	if not controller.has_method("is_button_pressed"):
		return false
	# get_is_active() guards against stale/disconnected trackers.
	if controller.has_method("get_is_active") and not controller.get_is_active():
		return false
	return bool(controller.call("is_button_pressed", action))


## Controller position expressed in THIS node's local (logical) space, i.e. the
## same space _point_a / _point_b live in (before SCENE_SCALE is applied).
func _controller_logical_position(controller: Node) -> Vector3:
	if controller == null or not is_instance_valid(controller) or not (controller is Node3D):
		return Vector3.ZERO
	var world: Vector3 = (controller as Node3D).global_position
	# to_local maps world -> this node's local frame (already includes our scale).
	# Divide out SCENE_SCALE * root scale to land in the logical units the math uses.
	var denom: float = SCENE_SCALE * maxf(scale.x, 0.0001)
	return to_local(world) / denom


# ═════════════════════════════════════════════════════════════════════════
# PER-FRAME UPDATE
# ═════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	# Retry controller resolution periodically until we either find them or time
	# out gracefully (headless never finds them and uses the demo path).
	if _controllers_resolved and not _have_controllers:
		_controller_retry += delta
		if _controller_retry >= CONTROLLER_RETRY_INTERVAL:
			_controller_retry = 0.0
			_resolve_controllers()

	if _have_controllers:
		_update_from_controllers(delta)
	else:
		_update_demo(delta)

	# Charge glow eases toward target (1.0 when CHARGED, else 0.0).
	var target_glow: float = 1.0 if _fire_state == FireState.CHARGED else 0.0
	_charge_glow = lerpf(_charge_glow, target_glow, clampf(delta * 6.0, 0.0, 1.0))
	_apply_charge_glow()

	# Reflection flash decays.
	if _reflect_flash > 0.0:
		_reflect_flash = maxf(_reflect_flash - delta, 0.0)

	_refresh_visuals()

	# Throttled text update (~10 Hz, mirrors VectorAddition).
	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_text()

	# Keep riding velocity arrows on live projectiles oriented.
	_update_projectile_arrows()


# ── CONTROLLER-DRIVEN INPUT ──────────────────────────────────────────────────

func _update_from_controllers(_delta: float) -> void:
	var left_trigger: bool = _controller_button(_left_controller, "trigger")
	var right_trigger: bool = _controller_button(_right_controller, "trigger")
	var right_grip: bool = _controller_button(_right_controller, "grip")

	# A follows the LEFT hand while its trigger is held.
	if left_trigger:
		_point_a = _controller_logical_position(_left_controller)
	# B follows the RIGHT hand while its trigger is held — UNLESS we are charged,
	# in which case the right trigger means FIRE (the two meanings never overlap
	# because grip is what charges).
	if right_trigger and _fire_state != FireState.CHARGED:
		_point_b = _controller_logical_position(_right_controller)

	# Grip charges. Releasing grip while not yet fired drops back to placing.
	if right_grip and not _right_grip_held:
		if _fire_state == FireState.PLACING:
			_fire_state = FireState.CHARGED
	elif not right_grip and _right_grip_held:
		if _fire_state == FireState.CHARGED:
			_fire_state = FireState.PLACING

	# FIRE on the rising edge of the right trigger while charged.
	if right_trigger and not _right_trigger_held and _fire_state == FireState.CHARGED:
		_fire()

	_left_trigger_held = left_trigger
	_right_trigger_held = right_trigger
	_right_grip_held = right_grip


# ── DESKTOP / HEADLESS FALLBACK ──────────────────────────────────────────────

func _update_demo(delta: float) -> void:
	_demo_time += delta
	# A and B orbit slowly on offset circles so |AB| breathes and the live math
	# keeps changing — the whole point of the artifact stays visible headless.
	var t: float = _demo_time
	_point_a = Vector3(
		-1.0 + cos(t * 0.55) * 0.6,
		1.2 + sin(t * 0.4) * 0.35,
		sin(t * 0.3) * 0.4
	)
	_point_b = Vector3(
		1.0 + cos(t * 0.45 + 1.7) * 0.7,
		1.3 + sin(t * 0.6 + 0.5) * 0.4,
		cos(t * 0.35) * 0.4
	)

	# Periodic auto-fire so a headless capture renders projectiles + reflection.
	_auto_fire_cooldown -= delta
	if _auto_fire_cooldown <= 0.0:
		_auto_fire_cooldown = AUTO_FIRE_INTERVAL
		_fire_state = FireState.CHARGED
		_fire()


# ═════════════════════════════════════════════════════════════════════════
# CORE VECTOR MATH
# ═════════════════════════════════════════════════════════════════════════

## AB = B - A (logical space). The defining subtraction.
func _ab_vector() -> Vector3:
	return _point_b - _point_a


## Launch velocity in LOGICAL space: the vector itself, scaled by force_gain.
## v = AB * force_gain  — wider hands => longer AB => faster shot.
func _launch_velocity_logical() -> Vector3:
	return _ab_vector() * force_gain


# ═════════════════════════════════════════════════════════════════════════
# FIRE
# ═════════════════════════════════════════════════════════════════════════

func _fire() -> void:
	var ab: Vector3 = _ab_vector()
	if ab.length() < 0.05:
		# Degenerate vector — nothing meaningful to throw.
		_fire_state = FireState.PLACING
		return

	_prune_projectiles()

	# Snapshot the ghost of the AB we are firing (intent vs result).
	if _ghost_arrow:
		_ghost_arrow.visible = true
		_position_arrow(_ghost_arrow, _point_a * SCENE_SCALE, _point_b * SCENE_SCALE)

	var ball := RigidBody3D.new()
	ball.name = "ArenaBall"
	ball.gravity_scale = arena_gravity / 9.8
	ball.contact_monitor = true
	ball.max_contacts_reported = 6
	ball.can_sleep = false
	ball.collision_layer = 16   # isolated layer; won't fight world cubes
	ball.collision_mask = 1     # collide with the world/floor (layer 1)

	var scaled_radius: float = ball_radius * SCENE_SCALE

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = scaled_radius
	col.shape = shape
	ball.add_child(col)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = scaled_radius
	sphere.height = scaled_radius * 2.0
	mesh.mesh = sphere
	mesh.material_override = _get_ball_material()
	ball.add_child(mesh)

	# A small riding velocity arrow (re-oriented each frame in _update_projectile_arrows).
	var ride_arrow := _create_arrow("BallVel", color_ab)
	ball.add_child(ride_arrow)
	ball.set_meta("vel_arrow", ride_arrow)

	# Spawn at A (in local/container space) and give it the launch velocity in WORLD.
	var spawn_local: Vector3 = _point_a * SCENE_SCALE
	_projectile_container.add_child(ball)
	ball.transform = Transform3D(Basis.IDENTITY, spawn_local)

	# velocity is a free vector: apply only the basis (rotation+scale), not origin.
	var v_logical: Vector3 = _launch_velocity_logical()
	var v_world: Vector3 = global_transform.basis * (v_logical * SCENE_SCALE)
	ball.linear_velocity = v_world

	# Tag so we can compute reflection on contact with the wall.
	ball.set_meta("did_reflect", false)
	# Defer the contact connection so the body is fully inside the tree.
	ball.body_entered.connect(_on_ball_body_entered.bind(ball))

	# Lifetime cleanup.
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = projectile_lifetime
	ball.add_child(timer)
	timer.timeout.connect(ball.queue_free)
	timer.start()

	# Back to placing after a shot leaves the hand.
	_fire_state = FireState.PLACING


## When a ball contacts something, test whether it crossed the wall plane and, if
## so, reflect its velocity by the FORMULA (not engine bounce).
func _on_ball_body_entered(_other: Node, ball: Node) -> void:
	_try_reflect_ball(ball)


func _physics_process(_delta: float) -> void:
	# contact_monitor on the wall is unreliable for a StaticBody-less plane mesh,
	# so we also do a manual plane-crossing test each physics tick. This is the
	# robust path that actually drives the reflection formula.
	if _projectile_container == null:
		return
	for child in _projectile_container.get_children():
		if not (child is RigidBody3D):
			continue
		var ball := child as RigidBody3D
		if ball.get_meta("did_reflect", false):
			continue
		_test_wall_crossing(ball)


## Manual analytic reflection: detect when the ball passes the wall plane moving
## into it, then set velocity to r = d - 2(d.n)n (in world space, using the
## world-space wall normal). This is the literal formula, mirroring
## VectorProjectionReflection's reflection = incident - 2 * (incident.n)n.
func _test_wall_crossing(ball: RigidBody3D) -> void:
	if not is_instance_valid(ball):
		return
	# Work in this node's local (logical) space so the math matches the panels.
	var ball_local: Vector3 = to_local(ball.global_position) / maxf(SCENE_SCALE, 0.0001)
	var n: Vector3 = _wall_normal.normalized()
	# Signed distance from the wall plane along its normal.
	var signed_dist: float = (ball_local - _wall_center).dot(n)
	# Logical velocity of the ball (world velocity -> local -> de-scaled).
	var v_local: Vector3 = (global_transform.basis.inverse() * ball.linear_velocity) / maxf(SCENE_SCALE, 0.0001)
	var approaching: bool = v_local.dot(n) < 0.0
	# Trigger when the ball is within a thin slab in front of/behind the plane
	# and still moving into it. The slab tolerance scales with ball size.
	var tol: float = ball_radius + 0.15
	if signed_dist <= tol and signed_dist >= -tol and approaching:
		_reflect_ball(ball, v_local, n)


func _try_reflect_ball(ball: Node) -> void:
	if not (ball is RigidBody3D):
		return
	var rb := ball as RigidBody3D
	if rb.get_meta("did_reflect", false):
		return
	var n: Vector3 = _wall_normal.normalized()
	var v_local: Vector3 = (global_transform.basis.inverse() * rb.linear_velocity) / maxf(SCENE_SCALE, 0.0001)
	if v_local.dot(n) < 0.0:
		_reflect_ball(rb, v_local, n)


## Apply r = d - 2(d.n_hat)n_hat and flash the live arithmetic panel.
func _reflect_ball(ball: RigidBody3D, d_local: Vector3, n_hat: Vector3) -> void:
	if not is_instance_valid(ball):
		return
	var d_dot_n: float = d_local.dot(n_hat)
	var normal_part: Vector3 = n_hat * (2.0 * d_dot_n)          # 2(d.n)n
	var r_local: Vector3 = d_local - normal_part                # the reflection

	# Convert reflected logical velocity back to world and apply it.
	var r_world: Vector3 = global_transform.basis * (r_local * SCENE_SCALE)
	ball.linear_velocity = r_world
	ball.set_meta("did_reflect", true)

	# Flash the reflection arithmetic.
	_reflect_flash = 2.5
	if _reflect_label:
		var len_ok: String = "OK" if is_equal_approx_loose(d_local.length(), r_local.length()) else "?"
		_reflect_label.text = "d = (%.2f, %.2f, %.2f)\nn = (%.2f, %.2f, %.2f)\nd.n = %.2f\n2(d.n)n = (%.2f, %.2f, %.2f)\nr = (%.2f, %.2f, %.2f)\n|d|=%.2f  |r|=%.2f  [%s]" % [
			d_local.x, d_local.y, d_local.z,
			n_hat.x, n_hat.y, n_hat.z,
			d_dot_n,
			normal_part.x, normal_part.y, normal_part.z,
			r_local.x, r_local.y, r_local.z,
			d_local.length(), r_local.length(), len_ok]


## Lenient equality for the |r| = |d| invariant display.
func is_equal_approx_loose(a: float, b: float) -> bool:
	return absf(a - b) <= 0.05 * maxf(1.0, maxf(absf(a), absf(b)))


# ═════════════════════════════════════════════════════════════════════════
# VISUAL REFRESH
# ═════════════════════════════════════════════════════════════════════════

func _refresh_visuals() -> void:
	# Endpoint markers.
	if _marker_a:
		_marker_a.position = _point_a * SCENE_SCALE
	if _marker_b:
		_marker_b.position = _point_b * SCENE_SCALE

	# The live A->B arrow.
	if _ab_arrow:
		_position_arrow(_ab_arrow, _point_a * SCENE_SCALE, _point_b * SCENE_SCALE)

	# Endpoint labels float just above each marker.
	if _a_label:
		_a_label.position = _point_a * SCENE_SCALE + Vector3(0.0, 0.12, 0.0)
	if _b_label:
		_b_label.position = _point_b * SCENE_SCALE + Vector3(0.0, 0.12, 0.0)

	# The AB billboard rides the arrow midpoint.
	if _ab_label:
		var mid: Vector3 = (_point_a + _point_b) * 0.5
		_ab_label.position = mid * SCENE_SCALE + Vector3(0.0, 0.18, 0.0)


func _apply_charge_glow() -> void:
	# Brighten the live arrow's emission while charged.
	if _ab_arrow == null:
		return
	var shaft := _ab_arrow.get_node_or_null("Shaft") as MeshInstance3D
	var head := _ab_arrow.get_node_or_null("Head") as MeshInstance3D
	var energy: float = 0.5 + _charge_glow * 1.8
	if shaft and shaft.material_override is StandardMaterial3D:
		(shaft.material_override as StandardMaterial3D).emission_energy_multiplier = energy
	if head and head.material_override is StandardMaterial3D:
		(head.material_override as StandardMaterial3D).emission_energy_multiplier = energy


func _update_text() -> void:
	var ab: Vector3 = _ab_vector()
	var mag: float = ab.length()
	var dir: Vector3 = ab.normalized() if mag > 0.0001 else Vector3.ZERO

	var state_names := ["PLACING", "CHARGED", "FIRED"]
	var state_name: String = "?"
	if _fire_state >= 0 and _fire_state < state_names.size():
		state_name = String(state_names[_fire_state])
	var src: String = "hands" if _have_controllers else "demo"

	# Big centered readout.
	if _readout_label:
		_readout_label.text = "AB = B - A = (%.2f, %.2f, %.2f)\n|AB| = %.2f   dir = (%.2f, %.2f, %.2f)" % [
			ab.x, ab.y, ab.z, mag, dir.x, dir.y, dir.z]

	# Beside-the-arrow billboard.
	if _ab_label:
		_ab_label.text = "AB = (%.2f, %.2f, %.2f)\n|AB| = %.2f" % [ab.x, ab.y, ab.z, mag]

	# Endpoint labels with live coordinates.
	if _a_label:
		_a_label.text = "A = (%.2f, %.2f, %.2f)" % [_point_a.x, _point_a.y, _point_a.z]
	if _b_label:
		_b_label.text = "B = (%.2f, %.2f, %.2f)" % [_point_b.x, _point_b.y, _point_b.z]

	# Two-column panel: live data column.
	if _info_label:
		var launch: Vector3 = _launch_velocity_logical()
		_info_label.text = "[%s | %s]\nA = (%.2f, %.2f, %.2f)\nB = (%.2f, %.2f, %.2f)\nAB = (%.2f, %.2f, %.2f)\n|AB| = %.2f\nv = (%.2f, %.2f, %.2f)\n|v| = %.2f" % [
			state_name, src,
			_point_a.x, _point_a.y, _point_a.z,
			_point_b.x, _point_b.y, _point_b.z,
			ab.x, ab.y, ab.z, mag,
			launch.x, launch.y, launch.z, launch.length()]


# ═════════════════════════════════════════════════════════════════════════
# PROJECTILE MAINTENANCE
# ═════════════════════════════════════════════════════════════════════════

func _update_projectile_arrows() -> void:
	if _projectile_container == null:
		return
	for child in _projectile_container.get_children():
		if not (child is RigidBody3D):
			continue
		var ball := child as RigidBody3D
		if not ball.has_meta("vel_arrow"):
			continue
		var arrow = ball.get_meta("vel_arrow")
		if arrow == null or not is_instance_valid(arrow):
			continue
		var v_world: Vector3 = ball.linear_velocity
		if v_world.length() < 0.01:
			arrow.visible = false
			continue
		arrow.visible = true
		# Express velocity direction in ball-local space; cap the arrow length.
		var local_dir: Vector3 = ball.global_transform.basis.inverse() * v_world
		var dir: Vector3 = local_dir.normalized() * clampf(v_world.length() * 0.05, 0.12, 0.5)
		# Recolor based on whether it has reflected yet.
		var did: bool = ball.get_meta("did_reflect", false)
		_recolor_arrow(arrow, color_reflect if did else color_ab)
		_position_arrow(arrow, Vector3.ZERO, dir)


## Remove the oldest live projectiles if we exceed the cap.
func _prune_projectiles() -> void:
	if _projectile_container == null:
		return
	var balls := _projectile_container.get_children()
	while balls.size() >= max_live_projectiles and balls.size() > 0:
		var oldest = balls[0]
		balls.remove_at(0)
		if is_instance_valid(oldest):
			oldest.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# GEOMETRY BUILDERS
# ═════════════════════════════════════════════════════════════════════════

## Build an arrow (shaft cylinder + cone head). Mirrors catapult._create_arrow.
func _create_arrow(arrow_name: String, color: Color) -> Node3D:
	var arrow := Node3D.new()
	arrow.name = arrow_name

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ARROW_THICKNESS
	cylinder.bottom_radius = ARROW_THICKNESS
	cylinder.height = 1.0
	shaft.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	shaft.material_override = mat
	arrow.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_THICKNESS * 2.5
	cone.height = ARROW_THICKNESS * 5.0
	head.mesh = cone
	# Give the head its OWN material instance so glow tweaks don't bleed.
	var head_mat := mat.duplicate() as StandardMaterial3D
	head.material_override = head_mat
	arrow.add_child(head)

	return arrow


## Recolor an arrow built by _create_arrow.
func _recolor_arrow(arrow: Node3D, color: Color) -> void:
	if arrow == null:
		return
	for child_name in ["Shaft", "Head"]:
		var part := arrow.get_node_or_null(child_name) as MeshInstance3D
		if part and part.material_override is StandardMaterial3D:
			var m := part.material_override as StandardMaterial3D
			m.albedo_color = color
			m.emission = color


## Position an arrow from start to end (both in this node's local space, already
## including SCENE_SCALE), scaling shaft and aiming via look_at. Mirrors
## catapult._position_arrow exactly so behaviour is proven.
func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3) -> void:
	var dir := end - start
	var length := dir.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true

	arrow.transform = Transform3D.IDENTITY
	arrow.position = start

	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")

	var shaft_length: float = length - ARROW_THICKNESS * 5.0
	shaft.scale = Vector3(1.0, maxf(shaft_length, 0.01), 1.0)
	shaft.position = dir.normalized() * (shaft_length / 2.0)
	head.position = dir.normalized() * (length - ARROW_THICKNESS * 2.5)

	# look_at() is global; dir is in the arrow's parent (our) local frame, so
	# rotate it by our global basis to get a world direction before aiming.
	var parent := arrow.get_parent() as Node3D
	var world_dir := dir
	if parent:
		world_dir = parent.global_transform.basis * dir
	var up := Vector3.UP
	if world_dir.length() > 0.0001 and absf(world_dir.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	arrow.look_at(arrow.global_position + world_dir, up)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2.0)


func _make_marker(color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var r: float = 0.06 * SCENE_SCALE
	sphere.radius = r
	sphere.height = r * 2.0
	sphere.radial_segments = 16
	sphere.rings = 10
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.7
	mesh.material_override = mat
	return mesh


func _make_label(text: String, color: Color, font_size: int = 18) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = maxi(2, font_size / 6)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0013
	label.no_depth_test = true
	label.render_priority = 100
	return label


func _build_wall() -> void:
	_wall_mesh = MeshInstance3D.new()
	_wall_mesh.name = "ReflectionWall"
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.5, 2.4) * SCENE_SCALE
	_wall_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.30, 0.45, 0.30)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.4, 0.7, 1.0)
	mat.emission_energy_multiplier = 0.35
	mat.double_sided = true
	_wall_mesh.material_override = mat
	# Orient the PlaneMesh (default +Y normal) so its normal aligns with _wall_normal.
	_wall_mesh.transform.basis = _basis_for_plane_normal(_wall_normal.normalized())
	_wall_mesh.position = _wall_center * SCENE_SCALE
	environment_root.add_child(_wall_mesh)

	# A label for the wall.
	var wall_label := _make_label("WALL", color_normal, 18)
	wall_label.position = (_wall_center + Vector3(0.0, 1.0, 0.0)) * SCENE_SCALE
	environment_root.add_child(wall_label)


## A basis whose +Y aligns with the given normal (PlaneMesh normal is +Y).
func _basis_for_plane_normal(n: Vector3) -> Basis:
	var up := n.normalized()
	var reference := Vector3.UP
	if absf(up.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var tangent := reference.cross(up).normalized()
	var bitangent := up.cross(tangent).normalized()
	return Basis(tangent, up, bitangent).orthonormalized()


## Draw the wall's unit normal arrow (length 1.0 logical) from the wall center.
func _position_normal_arrow() -> void:
	if _normal_arrow == null:
		return
	var n: Vector3 = _wall_normal.normalized()
	var start: Vector3 = _wall_center * SCENE_SCALE
	var end: Vector3 = (_wall_center + n) * SCENE_SCALE
	_position_arrow(_normal_arrow, start, end)

	# Label the normal.
	var nlabel := _normal_arrow.get_node_or_null("NormalLabel") as Label3D
	if nlabel == null:
		nlabel = _make_label("n-hat", color_normal, 16)
		nlabel.name = "NormalLabel"
		_normal_arrow.add_child(nlabel)
	# Place the label at the world tip, expressed in the arrow's local frame.
	nlabel.position = _normal_arrow.to_local(to_global(end)) + Vector3(0.0, 0.1, 0.0)


func _get_ball_material() -> StandardMaterial3D:
	if _ball_material == null:
		_ball_material = StandardMaterial3D.new()
		_ball_material.albedo_color = color_ball
		_ball_material.emission_enabled = true
		_ball_material.emission = color_ball
		_ball_material.emission_energy_multiplier = 0.5
		_ball_material.roughness = 0.3
	return _ball_material


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

## Accept overrides from the map/grid system. We extend the base implementation
## (which handles scale_multiplier + rebuild) with our own challenge / force_gain.
func apply_grid_config(config: Dictionary) -> void:
	if config == null:
		return
	if config.has("challenge"):
		challenge = int(config["challenge"])
	if config.has("force_gain"):
		force_gain = float(config["force_gain"])
	if config.has("gravity"):
		arena_gravity = float(config["gravity"])
	if config.has("max_projectiles"):
		max_live_projectiles = int(config["max_projectiles"])
	# Let the base handle scale_multiplier (and rebuild if already built).
	super.apply_grid_config(config)
