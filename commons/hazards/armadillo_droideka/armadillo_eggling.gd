# @identity
# essence: roll(v) + contact_damage · δ(collision) — pure kinetic threat with no ranged capability
# desire: a small armored egg that rolls toward you, dealing 9 damage on contact — the simplest predator
# critical_parameter: contact_damage (9.0) — the only weapon; balanced by 0.74 scale making it hard to hit
# triggers: inherited state machine from armadillo_droideka; no fire capability (can_deploy_fire = false)
# emerges: egglings in groups create emergent flanking patterns despite having zero coordination logic
# needs: inherited armadillo_droideka visual rig [has]; scute shell animation [has]
# relationships: depends on armadillo_droideka base class; contrasts with origami_droideka (no ranged vs full combat)
# truth: The simplest enemy teaches the most — contact damage is threat reduced to pure proximity.

extends "res://commons/hazards/armadillo_droideka/armadillo_droideka.gd"
class_name ArmadilloEggling

# --- DNA (promoted 2026-07-29, stage 2) ------------------------------------------------
# The eggling was the base droideka with every weapon switched off: no shots, no detection
# radius, contact damage only. That left two hard-coded design decisions carrying the whole
# argument, both invisible as knobs.
#
# posture — the shell never opens (can_deploy_fire = false pins _fold_amount at 0). "ball"
#   is the compressed threat; "walker" holds the same body deployed — legs down, scutes fanned,
#   core raised — and still has no gun. Opening it says the deployment was never the weapon.
# pursuit — the ROLL state homes on the player every frame. "chase" is a threat that is an
#   agent; "patrol" is a threat that is terrain (it holds a heading and turns at walls, never
#   at you); "flee" inverts predator and prey (you have to catch the thing that hurts you).
#
# Defaults posture=ball + pursuit=chase delegate straight to super._process_roll_state(),
# so the 11 maps that already place an eggling are byte-identical.
@export_enum("ball", "walker") var posture: String = "ball"
@export_enum("chase", "patrol", "flee") var pursuit: String = "chase"

var _wander_heading: float = 0.0
var _eggling_built: bool = false

func _ready() -> void:
	max_health = 26.0
	roll_speed = 4.3
	strafe_speed = 0.0
	turn_speed = 8.5
	detection_radius = 0.0
	disengage_radius = 0.0
	can_deploy_fire = false
	shots_per_burst = 0
	fire_interval = 0.8
	fire_speed = 0.0
	fire_damage = 0.0
	contact_damage = 9.0
	contact_damage_cooldown = 0.45

	scute_count = 10
	shell_radius = 0.5
	shell_height = 0.86
	shell_thickness = 0.07
	scute_open_degrees = 35.0
	scute_wave_degrees = 4.0
	ring_open_degrees = 16.0
	core_raise_height = 0.16
	leg_upper_length = 0.3
	leg_lower_length = 0.26

	scale = Vector3.ONE * 0.74
	super._ready()
	add_to_group("eggling")

	_wander_heading = rotation.y
	_eggling_built = true
	if posture == "walker":
		# Open on the first frame instead of unfolding over deploy_duration — a walker that
		# is briefly a ball reads as a bug, and stills would catch it half-folded.
		_fold_amount = 1.0
		_apply_fold_pose(1.0)


func _process_roll_state(delta: float) -> void:
	# The default genome is the pre-promotion body, unchanged, straight from the base class.
	if posture == "ball" and pursuit == "chase":
		super._process_roll_state(delta)
		return
	_roll_eggling(delta)


func _roll_eggling(delta: float) -> void:
	if posture == "walker":
		_fold_amount = move_toward(_fold_amount, 1.0, delta / max(deploy_duration, 0.01))
	else:
		_fold_amount = move_toward(_fold_amount, 0.0, delta / max(retract_duration, 0.01))

	var move_dir: Vector3 = Vector3.ZERO
	match pursuit:
		"patrol":
			if is_on_wall():
				_wander_heading += PI * 0.5 + _rng.randf() * 0.6
			move_dir = Vector3(sin(_wander_heading), 0.0, cos(_wander_heading))
		"flee":
			if is_instance_valid(_player_node):
				var away: Vector3 = global_position - _player_node.global_position
				away.y = 0.0
				if away.length() > 0.001:
					move_dir = away.normalized()
		_:
			if is_instance_valid(_player_node):
				var toward: Vector3 = _player_node.global_position - global_position
				toward.y = 0.0
				if toward.length() > 0.001:
					move_dir = toward.normalized()

	if move_dir.length_squared() > 0.0001:
		_face_direction(move_dir, delta, turn_speed)

	velocity.x = move_dir.x * roll_speed
	velocity.z = move_dir.z * roll_speed
	velocity.y = 0.0

	if posture == "ball":
		var planar_speed: float = Vector2(velocity.x, velocity.z).length()
		_roll_spin += planar_speed * delta / max(shell_radius, 0.1)
		if _shell_root:
			_shell_root.rotation.x = _roll_spin
	elif _shell_root:
		# A deployed body walks; it does not tumble. Settle the spin the shell already carries.
		_shell_root.rotation.x = lerp_angle(_shell_root.rotation.x, 0.0, clamp(delta * 4.0, 0.0, 1.0))


func apply_grid_config(config_data: Dictionary) -> void:
	# The base handles the numeric combat keys (roll_speed, health, contact, ...).
	super.apply_grid_config(config_data)
	if config_data.is_empty():
		return

	if config_data.has("posture"):
		var want_posture: String = str(config_data["posture"]).strip_edges().to_lower()
		if want_posture in ["ball", "walker"] and want_posture != posture:
			posture = want_posture
			# Guarded: only re-pose an already-built rig, and only because a value changed.
			# Nothing is rebuilt — the same hinges are moved, so placements stay valid.
			if _eggling_built:
				_fold_amount = 1.0 if posture == "walker" else 0.0
				_apply_fold_pose(_fold_amount)

	if config_data.has("pursuit"):
		var want_pursuit: String = str(config_data["pursuit"]).strip_edges().to_lower()
		if want_pursuit in ["chase", "patrol", "flee"] and want_pursuit != pursuit:
			pursuit = want_pursuit
			_wander_heading = rotation.y
