extends CharacterBody3D
## A territorial visitor, then a charge source. Eight constrained mechanical legs.
## Charge belongs to the Void visit; museum saves/unlocks are never altered.
const Gait := preload("res://commons/void/spider_gait.gd")
const TechHead := preload("res://commons/void/spider_head.gd")
enum State { REST, WARNING, CHASE, COOLDOWN, RETURN, CALM }
@export var trigger_radius := 3.0
@export var disengage_radius := 5.0
@export var leash_radius := 6.0
@export var chase_speed := 4.5
@export var bite_range := 1.3
@export var bite_damage := 20.0
@export var attack_cooldown := 3.0
@export var warning_seconds := 0.65
@export var heal_radius := 2.0
@export var heal_amount := 10.0
@export var heal_interval := 2.0
var state: State = State.REST
var home := Vector3.ZERO
var attacks := 0
var healing_pulses := 0
var cooldown_left := 0.0
var _warning_left := 0.0
var _heal_clock := 0.0
var _recovery_grace := 0.0
var _home_set := false
var _was_recovering := false
var _health: Node
var _game: Node
var _player: Node3D
var gait: MeshInstance3D
var core: MeshInstance3D
var tech_head: Node3D
var lamp: OmniLight3D
var caption: Label3D
signal calmed()
signal attacked(amount: float)
signal supplied_health(amount: float)

func apply_grid_config(config: Dictionary) -> void:
	# Bounded numeric settings keep pasted/editor instances usable.
	var limits := {"trigger_radius":[1.5,5.0], "disengage_radius":[3.0,8.0],
		"leash_radius":[3.0,10.0], "chase_speed":[1.0,6.0], "bite_damage":[1.0,100.0],
		"attack_cooldown":[1.0,10.0], "heal_amount":[1.0,50.0], "heal_interval":[1.0,10.0]}
	for key in limits:
		if config.has(key) and str(config[key]).is_valid_float():
			set(key, clampf(float(config[key]), limits[key][0], limits[key][1]))
	disengage_radius = maxf(disengage_radius, trigger_radius + 0.5)

func _ready() -> void:
	add_to_group("void_spider")
	collision_layer = 2 # Actual catalyst projectiles already hit this receiver layer.
	collision_mask = 1 # Slide on architecture/props; never push the player rig.
	floor_snap_length = 0.2
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	gait = Gait.new()
	gait.name = "MechanicalOctapod"
	gait.floor_anchor = self
	gait.walker_scale = 3.0 # 1.35 m shoulder height, eight full-size legs.
	add_child(gait)
	gait.step_duration = 0.1
	tech_head = TechHead.new()
	tech_head.name = "TechHead"
	tech_head.position = Vector3(0,1.58,-.45)
	tech_head.scale = Vector3.ONE*1.15
	add_child(tech_head)
	core = tech_head.optic
	lamp = OmniLight3D.new()
	lamp.position.y = 1.4
	lamp.omni_range = 3.0
	lamp.light_energy = 0.5
	lamp.shadow_enabled = false
	add_child(lamp)
	caption = Label3D.new()
	caption.position.y = 2.05
	caption.font_size = 38
	caption.pixel_size = 0.0018
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = false
	add_child(caption)
	_update_feedback()

func _physics_process(delta: float) -> void:
	# Mount transforms are finalized after _ready by both editor and streamer.
	if not _home_set:
		home = global_position
		_home_set = true
	if not is_instance_valid(_health) or not is_instance_valid(_player):
		_health = get_tree().get_first_node_in_group("void_health")
		if is_instance_valid(_health):
			_game = _health.get_parent()
			_player = _game.get("body") as Node3D
	if not is_instance_valid(_player): return # Editor/model export is a quiet specimen.
	var unavailable: bool = _health.suspended or _health.get_health() <= 0 or not _game.ready_for_play or _game.returning
	if unavailable:
		_was_recovering = true
		velocity = Vector3.ZERO
		_heal_clock = 0.0
		if state != State.CALM: _set_state(State.REST)
		return
	if _was_recovering:
		_was_recovering = false
		global_position = home
		_recovery_grace = 2.0
		cooldown_left = attack_cooldown
	cooldown_left = maxf(0.0, cooldown_left - delta)
	_recovery_grace = maxf(0.0, _recovery_grace - delta)
	var offset := _player.global_position - global_position
	var same_floor := absf(offset.y) < 0.65
	offset.y = 0
	var distance := offset.length()
	var visible_player := same_floor and distance <= disengage_radius and _line_of_sight()
	var direction := Vector3.ZERO
	match state:
		State.REST:
			if visible_player and distance <= trigger_radius and _recovery_grace <= 0:
				_warning_left = warning_seconds
				_set_state(State.WARNING)
		State.WARNING:
			_warning_left -= delta
			if not visible_player: _set_state(State.RETURN)
			elif _warning_left <= 0: _set_state(State.CHASE)
		State.CHASE:
			if not visible_player or _horizontal_distance(home) > leash_radius:
				_set_state(State.RETURN)
			elif distance <= bite_range:
				if cooldown_left <= 0:
					# Set state/timer BEFORE damage: depletion may start recovery now.
					cooldown_left = attack_cooldown
					_set_state(State.COOLDOWN)
					attacks += 1
					tech_head.bite()
					_health.apply_bite_damage(bite_damage)
					attacked.emit(bite_damage)
			else: direction = offset.normalized()
		State.COOLDOWN:
			# A real pause, not repeated damage from overlap every physics tick.
			if cooldown_left <= 0:
				if visible_player and distance <= trigger_radius:
					_warning_left = warning_seconds
					_set_state(State.WARNING)
				else: _set_state(State.RETURN)
		State.RETURN:
			if _horizontal_distance(home) < 0.15: _set_state(State.REST)
			else: direction = (home - global_position).slide(Vector3.UP).normalized()
		State.CALM:
			if visible_player and distance <= heal_radius and _health.get_health() < _health.max_player_health:
				_heal_clock += delta
				if _heal_clock >= heal_interval:
					_heal_clock = 0.0
					var before: float = _health.get_health()
					_health.set_health(before + heal_amount)
					healing_pulses += 1
					supplied_health.emit(_health.get_health() - before)
			else: _heal_clock = 0.0
	if not direction.is_zero_approx() and not _supported_ahead(direction): direction = Vector3.ZERO
	var speed := chase_speed if state == State.CHASE else 1.5
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18.0 * delta
	if not direction.is_zero_approx(): global_rotation.y = lerp_angle(global_rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 10))
	move_and_slide()
	# A removed support or editor placement over a void cannot lose the creature.
	if global_position.y < home.y - 1.5:
		global_position = home
		velocity = Vector3.ZERO
		if state != State.CALM: _set_state(State.REST)

func _horizontal_distance(point: Vector3) -> float:
	return (point - global_position).slide(Vector3.UP).length()

func _line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, _player.global_position + Vector3.UP, 1)
	var excluded: Array[RID] = [get_rid()]
	if _player is CollisionObject3D: excluded.append(_player.get_rid())
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _supported_ahead(direction: Vector3) -> bool:
	var ahead := global_position + direction * 0.8
	var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.35, ahead - Vector3.UP * 0.35, 1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.normal.y > 0.7

func hit_by_catalyst_mode(_color: Color, _mode: String) -> void:
	if state == State.CALM: return # Further hits cannot restart the health clock.
	velocity = Vector3.ZERO
	_heal_clock = 0.0
	_set_state(State.CALM)
	calmed.emit()

func hit_by_projectile(color: Color) -> void:
	hit_by_catalyst_mode(color, "primitives")

func _set_state(next: State) -> void:
	if next == state: return
	state = next
	_update_feedback()

func _update_feedback() -> void:
	if not is_instance_valid(core): return
	var color := Color("b599ff")
	var words := "KEEP DISTANCE\nCatalyst calms me"
	match state:
		State.WARNING, State.CHASE:
			color = Color("ff463e")
			words = "TOO CLOSE"
		State.COOLDOWN:
			color = Color("ffb64f")
			words = "RECOVERING"
		State.CALM:
			color = Color("8affbd")
			words = "POWER SOURCE\nStay close to recharge"
	core.material_override.albedo_color = color
	core.material_override.emission = color
	lamp.light_color = color
	caption.text = words
