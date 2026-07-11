extends CharacterBody3D
class_name HazardCreatureBase
## Shared base class for all mobile hazard creatures.
## Provides state machine, player detection, damage interface,
## patrol/chase AI, and virtual stubs for geometry and behavior.
## Each creature extends this and overrides _build_mesh() and state processors.

signal enemy_destroyed(enemy: Node3D)

enum BaseState { IDLE, PATROL, DETECT, CHASE, ATTACK, STUNNED, DEAD }

# Personality arc — each catalyst dose walks the creature ONE step.
# Mirrors the constant in catalyst_foe; promoted to the base class so
# every HazardCreatureBase child can be advanced by the catalyst orb's
# receive_catalyst_field(). String values match _apply_personality cases.
const PERSONALITY_ARC: Array[String] = [
	"foe", "wary", "neutral", "curious", "friend",
]

# ── Exports ──────────────────────────────────────────────────────────────

@export_group("Combat")
@export var max_health: float = 60.0
@export var patrol_speed: float = 1.8
@export var chase_speed: float = 3.2
@export var detection_radius: float = 7.0
@export var disengage_radius: float = 12.0
@export var contact_damage: float = 15.0
@export var contact_cooldown: float = 0.8

@export_group("Patrol")
@export var patrol_width: float = 3.0
@export var patrol_depth: float = 2.0

# ── Personality (from HazardManager) ─────────────────────────────────────

## Personality determines high-level behavior: foe attacks, friend follows.
## Set by ProximitySpawner or configure(). Defaults to "foe" (legacy behavior).
var _personality: String = "foe"

# ── Catalyst field reception ────────────────────────────────────────────
# Replaces the projectile-hit path. CatalystOrb's cone calls
# receive_catalyst_field(dt, mode) per-frame while this creature is
# inside the cone. Accumulates a dose; at threshold, advances personality
# one step along PERSONALITY_ARC. Auto-resets if the creature has been
# out of any field for catalyst_dose_idle_reset seconds.
@export_group("Catalyst field")
@export var catalyst_dose_window: float = 0.6
@export var catalyst_dose_idle_reset: float = 0.4

var _catalyst_dose: float = 0.0
var _catalyst_last_tick: float = -999.0
var _catalyst_last_mode: String = ""

# Personality-derived behavior params (set in _apply_personality)
var _can_chase: bool = true
var _can_damage: bool = true
var _flee_from_player: bool = false
var _orbit_player: bool = false
var _follow_player: bool = false
var _approach_speed_factor: float = 1.0

# ── Decoy (chaos-lineage friend power) ──────────────────────────────────
# A FOE that would chase the player first looks for a chaos-lineage FRIEND
# within its detection radius and chases THAT node instead. Re-evaluated at
# most every 0.5s to stay cheap; falls back to the player when none in range.
var _decoy_target: Node3D = null
var _decoy_retarget_timer: float = 0.0

# ── State ────────────────────────────────────────────────────────────────

var _health: float = 0.0
var _state: BaseState = BaseState.PATROL
var _state_time: float = 0.0
var _contact_timer: float = 0.0
var _player_node: Node3D = null
var _patrol_origin: Vector3 = Vector3.ZERO
var _patrol_index: int = 0
var _patrol_corners: Array[Vector3] = []

# Visual root — subclasses attach mesh children here
var _mesh_root: Node3D = null


func _ready() -> void:
	_health = max_health
	_patrol_origin = global_position
	_build_patrol_corners()

	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)

	_create_materials()
	_build_collision()
	_build_mesh()
	_find_player()
	add_to_group("enemy")
	call_deferred("_query_hazard_manager")
	_on_ready()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_contact_timer = max(0.0, _contact_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	# Timed calmer slow restore (set by waveform-lineage friends via metas).
	# Lives here so the slow can never become permanent even if the friend
	# that applied it is freed mid-effect.
	if has_meta("calmer_slow_until"):
		var slow_until: float = float(get_meta("calmer_slow_until"))
		if float(Time.get_ticks_msec()) * 0.001 >= slow_until:
			if has_meta("calmer_base_speed"):
				chase_speed = float(get_meta("calmer_base_speed"))
				remove_meta("calmer_base_speed")
			remove_meta("calmer_slow_until")

	match _state:
		BaseState.IDLE:
			_process_idle(delta)
		BaseState.PATROL:
			_process_patrol(delta)
		BaseState.DETECT:
			_process_detect(delta)
		BaseState.CHASE:
			_process_chase(delta)
		BaseState.ATTACK:
			_process_attack(delta)
		BaseState.STUNNED:
			_process_stunned(delta)
		BaseState.DEAD:
			_process_dead(delta)

	_process_visual(delta)

	if _state != BaseState.DEAD:
		move_and_slide()
		_handle_contact_damage()


# ── Virtual stubs — override in subclasses ───────────────────────────────

## Called at end of _ready() for subclass-specific setup.
func _on_ready() -> void:
	pass

## Create materials for the creature's visual appearance.
func _create_materials() -> void:
	pass

## Build the collision shape. Default: 0.4m sphere.
func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	add_child(col)

## Build the creature's procedural mesh geometry on _mesh_root.
func _build_mesh() -> void:
	pass

## Per-frame visual update (animations, mesh rebuilds, etc).
func _process_visual(_delta: float) -> void:
	pass


# ── State Processing (override these for custom behavior) ───────────────

func _process_idle(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)
	if _get_player_distance() <= detection_radius:
		if _follow_player:
			_set_state(BaseState.CHASE)  # Repurposed as "follow"
		elif _orbit_player:
			_set_state(BaseState.CHASE)  # Repurposed as "orbit"
		elif _flee_from_player:
			_set_state(BaseState.CHASE)  # Repurposed as "flee"
		elif _can_chase:
			_set_state(BaseState.DETECT)


func _process_patrol(delta: float) -> void:
	if _patrol_corners.is_empty():
		return

	var target: Vector3 = _patrol_corners[_patrol_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	if dist < 0.3:
		_patrol_index = (_patrol_index + 1) % _patrol_corners.size()
		target = _patrol_corners[_patrol_index]
		to_target = target - global_position
		to_target.y = 0.0

	if to_target.length() > 0.01:
		var move_dir: Vector3 = to_target.normalized()
		velocity.x = move_dir.x * patrol_speed
		velocity.z = move_dir.z * patrol_speed
		_face_direction(move_dir, delta * 3.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0

	if _get_player_distance() <= detection_radius:
		if _flee_from_player:
			_set_state(BaseState.CHASE)
		elif _follow_player or _orbit_player:
			_set_state(BaseState.CHASE)
		elif _can_chase:
			_set_state(BaseState.DETECT)


func _process_detect(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.2)
	if _state_time >= 0.4:
		if _can_chase:
			_set_state(BaseState.CHASE)
		else:
			_set_state(BaseState.PATROL)


func _process_chase(delta: float) -> void:
	var dist: float = _get_player_distance()

	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	if not is_instance_valid(_player_node):
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = 0.0
		return

	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0

	# DECOY (chaos-lineage friend power): a chasing FOE re-evaluates its
	# target at most every 0.5s — a chaos-lineage FRIEND within detection
	# radius draws the chase away from the player.
	if _personality == "foe" and not _flee_from_player \
			and not _orbit_player and not _follow_player:
		_decoy_retarget_timer -= delta
		if _decoy_retarget_timer <= 0.0:
			_decoy_retarget_timer = 0.5
			_decoy_target = _find_decoy_target()
	else:
		_decoy_target = null

	# Personality-aware movement
	if _flee_from_player:
		# Wary: flee away from player
		if to_player.length() > 0.1:
			var flee_dir: Vector3 = -to_player.normalized()
			var flee_speed: float = chase_speed * _approach_speed_factor
			velocity.x = flee_dir.x * flee_speed
			velocity.z = flee_dir.z * flee_speed
			_face_direction(flee_dir, delta * 3.0)
		if dist > detection_radius * 1.5:
			_set_state(BaseState.PATROL)
	elif _orbit_player:
		# Curious: orbit at a safe distance (3-5m)
		var orbit_dist := 4.0
		var orbit_speed: float = patrol_speed * _approach_speed_factor
		if dist > orbit_dist + 1.0:
			# Move toward orbit radius
			var move_dir := to_player.normalized()
			velocity.x = move_dir.x * orbit_speed
			velocity.z = move_dir.z * orbit_speed
			_face_direction(move_dir, delta * 3.0)
		elif dist < orbit_dist - 1.0:
			# Too close, back off
			var away_dir := -to_player.normalized()
			velocity.x = away_dir.x * orbit_speed * 0.5
			velocity.z = away_dir.z * orbit_speed * 0.5
		else:
			# Orbit: perpendicular movement
			var perp := Vector3(-to_player.normalized().z, 0, to_player.normalized().x)
			velocity.x = perp.x * orbit_speed
			velocity.z = perp.z * orbit_speed
			_face_direction(to_player.normalized(), delta * 2.0)
	elif _follow_player:
		# Friend: follow at comfortable distance (2-3m)
		var follow_dist := 2.5
		if dist > follow_dist + 0.5:
			var move_dir := to_player.normalized()
			var follow_speed: float = chase_speed * _approach_speed_factor
			velocity.x = move_dir.x * follow_speed
			velocity.z = move_dir.z * follow_speed
			_face_direction(move_dir, delta * 3.0)
		else:
			# Close enough, slow down
			velocity.x = velocity.x * 0.85
			velocity.z = velocity.z * 0.85
			_face_direction(to_player.normalized(), delta * 1.0)
	else:
		# Foe: standard aggressive chase — a live decoy overrides the player
		# as the chase target (same movement code, different target).
		var chase_pos: Vector3 = _player_node.global_position
		if is_instance_valid(_decoy_target):
			chase_pos = _decoy_target.global_position
		var to_target: Vector3 = chase_pos - global_position
		to_target.y = 0.0
		if to_target.length() > 0.1:
			var move_dir: Vector3 = to_target.normalized()
			velocity.x = move_dir.x * chase_speed
			velocity.z = move_dir.z * chase_speed
			_face_direction(move_dir, delta * 5.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	velocity.y = 0.0


func _process_attack(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)


func _process_stunned(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)
	if _state_time >= 1.5:
		_set_state(BaseState.PATROL)


func _process_dead(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.1)
	if _state_time >= 3.0:
		queue_free()


# ── State Management ────────────────────────────────────────────────────

func _set_state(new_state: BaseState) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0
	_on_state_changed(new_state)

## Called when state changes — override for transition effects.
func _on_state_changed(_new_state: BaseState) -> void:
	pass


# ── Player Detection ────────────────────────────────────────────────────

func _find_player() -> void:
	# Group lookup first — it works even when current_scene is null
	# (headless --script runs, mid-transition frames).
	var by_group: Node = get_tree().get_first_node_in_group("player")
	if by_group is Node3D:
		_player_node = by_group
		return
	var scene: Node = get_tree().current_scene
	if not scene:
		_player_node = null
		return
	for candidate in [
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return
	_player_node = null


## Nearest chaos-lineage FRIEND within detection radius, or null.
## Fully defensive — only trusts nodes exposing _personality/_locked_mode_id.
func _find_decoy_target() -> Node3D:
	var best: Node3D = null
	var best_d: float = detection_radius
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		if n == self or not (n is Node3D):
			continue
		if not ("_personality" in n) or not ("_locked_mode_id" in n):
			continue
		if str(n.get("_personality")) != "friend":
			continue
		if str(n.get("_locked_mode_id")) != "chaos":
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d <= best_d:
			best_d = d
			best = n
	return best


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


func _get_player_direction() -> Vector3:
	if not is_instance_valid(_player_node):
		return Vector3.FORWARD
	var dir: Vector3 = _player_node.global_position - global_position
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD


# ── Damage Interface ────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == BaseState.DEAD:
		return
	_health -= max(0.0, amount)
	if _health <= 0.0:
		_set_state(BaseState.DEAD)
		enemy_destroyed.emit(self)
	else:
		_on_damaged(amount)

## Called when damaged but not dead — override for custom reactions.
func _on_damaged(_amount: float) -> void:
	_set_state(BaseState.STUNNED)


# ── Contact Damage ──────────────────────────────────────────────────────

func _handle_contact_damage() -> void:
	if _contact_timer > 0.0 or contact_damage <= 0.0 or not _can_damage:
		return
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if _try_damage_target(collider):
			_contact_timer = contact_cooldown
			break

func _try_damage_target(target: Object) -> bool:
	if target == null:
		return false
	if target.has_method("apply_health_damage"):
		target.apply_health_damage(contact_damage)
		return true
	if target is Node and target.is_in_group("player"):
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("apply_health_damage"):
			gm.apply_health_damage(contact_damage)
			return true
	return false


# ── Patrol ──────────────────────────────────────────────────────────────

func _build_patrol_corners() -> void:
	var hw: float = patrol_width * 0.5
	var hd: float = patrol_depth * 0.5
	_patrol_corners = [
		_patrol_origin + Vector3(-hw, 0, -hd),
		_patrol_origin + Vector3(hw, 0, -hd),
		_patrol_origin + Vector3(hw, 0, hd),
		_patrol_origin + Vector3(-hw, 0, hd),
	]


# ── Facing ──────────────────────────────────────────────────────────────

func _face_direction(dir: Vector3, weight: float = 0.1) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_angle: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, clamp(weight, 0.0, 1.0))


# ── Personality ─────────────────────────────────────────────────────────

func set_personality(personality: String) -> void:
	_personality = personality
	_apply_personality()

func get_personality() -> String:
	return _personality

func _apply_personality() -> void:
	match _personality:
		"foe":
			_can_chase = true
			_can_damage = true
			_flee_from_player = false
			_orbit_player = false
			_follow_player = false
			_approach_speed_factor = 1.0
		"wary":
			_can_chase = false
			_can_damage = true
			_flee_from_player = true
			_orbit_player = false
			_follow_player = false
			_approach_speed_factor = 1.2
			contact_damage *= 0.5
		"neutral":
			_can_chase = false
			_can_damage = false
			_flee_from_player = false
			_orbit_player = false
			_follow_player = false
			_approach_speed_factor = 0.0
			contact_damage = 0.0
		"curious":
			_can_chase = false
			_can_damage = false
			_flee_from_player = false
			_orbit_player = true
			_follow_player = false
			_approach_speed_factor = 0.4
			contact_damage = 0.0
		"friend":
			_can_chase = false
			_can_damage = false
			_flee_from_player = false
			_orbit_player = false
			_follow_player = true
			_approach_speed_factor = 0.6
			contact_damage = 0.0

# ── Catalyst field reception ────────────────────────────────────────────

func receive_catalyst_field(dt: float, mode: String) -> void:
	# Already at the friend pole — nothing more to advance to.
	if _personality == "friend":
		return
	if dt <= 0.0:
		return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	# If the dose has gone stale (creature stepped out of any cone),
	# reset before accumulating new contact.
	if now - _catalyst_last_tick > catalyst_dose_idle_reset:
		_catalyst_dose = 0.0
	_catalyst_last_tick = now
	_catalyst_last_mode = mode
	_catalyst_dose += dt
	if _catalyst_dose >= catalyst_dose_window:
		_catalyst_dose = 0.0
		_advance_catalyst_personality(mode)


func _advance_catalyst_personality(mode: String) -> void:
	# Subclass override: catalyst_foe routes through hit_by_catalyst_mode
	# to do mode-locking + visual pop. For other creatures, advance one
	# personality step along the arc using the base machinery.
	if has_method("hit_by_catalyst_mode"):
		# Use a neutral catalyst hue if the subclass needs a colour arg.
		call("hit_by_catalyst_mode", Color(0.9, 0.95, 1.0), mode)
		return
	var idx: int = PERSONALITY_ARC.find(_personality)
	if idx < 0:
		idx = 0
	var next_p: String = PERSONALITY_ARC[min(idx + 1, PERSONALITY_ARC.size() - 1)]
	if next_p != _personality:
		set_personality(next_p)
		# Reaching FRIEND is the moment of alignment — report it so the
		# capability manager can grant the mode's lasting player power.
		if next_p == "friend":
			var mgr: Node = get_node_or_null("/root/CatalystCapabilityManager")
			if mgr != null and mgr.has_method("grant_friend_power"):
				mgr.grant_friend_power(mode)


func _query_hazard_manager() -> void:
	var hm = get_node_or_null("/root/HazardManager")
	if not hm:
		return
	# Derive hazard_type from scene filename or class
	var hazard_type := _get_hazard_type()
	if hazard_type.is_empty():
		return
	var personality: String = hm.get_hazard_personality(hazard_type)
	if personality != _personality:
		set_personality(personality)

func _get_hazard_type() -> String:
	# Derive from scene file path: res://commons/hazards/miura_crawler/... -> miura_crawler
	var path := scene_file_path
	if path.is_empty() and owner:
		path = owner.scene_file_path
	if path.is_empty():
		return ""
	var parts := path.split("/")
	for i in range(parts.size() - 1, -1, -1):
		if parts[i].ends_with(".tscn") or parts[i].ends_with(".gd"):
			continue
		if parts[i] != "commons" and parts[i] != "hazards":
			return parts[i]
	return name.to_snake_case()

# ── Configuration ───────────────────────────────────────────────────────

func configure(config: Dictionary) -> void:
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		patrol_speed = float(config["speed"])
	if config.has("chase_speed"):
		chase_speed = float(config["chase_speed"])
	if config.has("damage"):
		contact_damage = float(config["damage"])
	if config.has("detection_radius"):
		detection_radius = float(config["detection_radius"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)


# ── Helpers ─────────────────────────────────────────────────────────────

## Create a StandardMaterial3D with emission.
func _make_material(color: Color, emission: Color = Color.BLACK, alpha: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 1.5
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

## Add a MeshInstance3D child to _mesh_root.
func _add_mesh(mesh: Mesh, material: StandardMaterial3D = null, local_pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if material:
		mi.set_surface_override_material(0, material)
	mi.position = local_pos
	_mesh_root.add_child(mi)
	return mi
