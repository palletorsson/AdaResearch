# TreeWalker.gd — Makes trees walk when mobility > 0.2
#
# Attaches to a tree CritterEntity after morphology builds.
# Finds root tip meshes (tagged by TreeMorphology), uses them as feet,
# and runs a hexapod-style stepping gait. The tree wanders autonomously.
#
# Gait algorithm adapted from six_leg_critter.gd but simplified:
# no IK chains, no skeletons — just moves the root tip meshes directly.
#
# Usage:
#   var walker := TreeWalker.new()
#   walker.setup(dna, entity)
#   entity.add_child(walker)

class_name TreeWalker
extends Node3D


# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Gait parameters
var step_threshold: float = 0.6    ## Distance from home before stepping
var step_duration: float = 0.35    ## Seconds per step
var step_height: float = 0.12     ## Arc height during step
var step_overshoot: float = 0.2   ## How far past home to plant

## Wandering
var wander_speed: float = 0.3     ## Base movement speed (scaled by mobility)
var wander_radius: float = 8.0    ## Max distance from spawn point
var wander_change_interval: float = 8.0  ## Seconds between direction changes

## Body bob
var bob_amplitude: float = 0.02   ## Vertical bob during walking
var bob_speed: float = 3.0        ## Bob frequency


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _root_tips: Array[MeshInstance3D] = []   ## Root tip mesh nodes
var _root_bases: Array[Vector3] = []         ## Root base positions (shoulders)
var _root_rest: Array[Vector3] = []          ## Root rest positions (home)

var _foot_planted: Array[Vector3] = []       ## World pos where each foot is planted
var _foot_stepping: Array[bool] = []         ## Is this root mid-step?
var _foot_step_from: Array[Vector3] = []
var _foot_step_to: Array[Vector3] = []
var _foot_step_time: Array[float] = []
var _foot_original_pos: Array[Vector3] = []  ## Original local positions (for reset)

var _entity: Node3D = null
var _spawn_position: Vector3 = Vector3.ZERO
var _wander_direction: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _mobility: float = 0.3
var _rng: RandomNumberGenerator = null
var _active: bool = false
var _time: float = 0.0


# ═══════════════════════════════════════════════════════════════
# SETUP
# ═══════════════════════════════════════════════════════════════

## Initialize the walker from DNA and the parent entity.
## Call after morphology is built (roots exist in scene tree).
func setup(dna: CritterDNA, entity: Node3D) -> void:
	_entity = entity
	_mobility = dna.mobility
	_spawn_position = entity.global_position

	wander_speed = dna.mobility * 0.3
	step_threshold = dna.part_length * dna.scale * 0.3
	step_height = dna.part_length * dna.scale * 0.08

	_rng = RandomNumberGenerator.new()
	_rng.seed = entity.get_instance_id()

	# Find root tip meshes (tagged by TreeMorphology._build_roots)
	_find_root_tips(entity)

	if _root_tips.is_empty():
		push_warning("[TreeWalker] No root tips found — tree won't walk")
		return

	# Initialize foot state
	for i in _root_tips.size():
		var tip: MeshInstance3D = _root_tips[i]
		var world_pos: Vector3 = tip.global_position
		_foot_planted.append(world_pos)
		_foot_stepping.append(false)
		_foot_step_from.append(world_pos)
		_foot_step_to.append(world_pos)
		_foot_step_time.append(0.0)
		_foot_original_pos.append(tip.position)

	# Pick initial wander direction
	_pick_new_direction()
	_active = true

	print("[TreeWalker] Walking tree with %d roots, speed=%.2f" % [
		_root_tips.size(), wander_speed
	])


## Recursively find root tip meshes tagged by TreeMorphology.
func _find_root_tips(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.has_meta("root_tip"):
			_root_tips.append(child as MeshInstance3D)
			_root_bases.append(child.get_meta("root_base", Vector3.ZERO))
			_root_rest.append(child.get_meta("root_end", child.position))
		if child is Node3D:
			_find_root_tips(child)


# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if not _active or _root_tips.is_empty() or not _entity:
		return

	_time += delta

	# 1. Wander — move the entity
	_update_wander(delta)

	# 2. Gait — step roots to follow
	_update_gait(delta)

	# 3. Body bob
	_update_bob()


# ═══════════════════════════════════════════════════════════════
# WANDERING
# ═══════════════════════════════════════════════════════════════

func _update_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_new_direction()

	# Move entity
	var move: Vector3 = _wander_direction * wander_speed * delta
	_entity.global_position += move

	# Rotate entity to face movement direction (slowly)
	if _wander_direction.length() > 0.01:
		var target_angle: float = atan2(_wander_direction.x, _wander_direction.z)
		var current_angle: float = _entity.rotation.y
		_entity.rotation.y = lerpf(current_angle, target_angle, delta * 1.5)

	# Boundary check — stay near spawn
	var dist_from_spawn: float = _entity.global_position.distance_to(_spawn_position)
	if dist_from_spawn > wander_radius:
		# Turn back toward spawn
		_wander_direction = (_spawn_position - _entity.global_position).normalized()
		_wander_direction.y = 0.0


func _pick_new_direction() -> void:
	var angle: float = _rng.randf_range(0, TAU)
	_wander_direction = Vector3(cos(angle), 0.0, sin(angle))
	_wander_timer = _rng.randf_range(wander_change_interval * 0.5, wander_change_interval * 1.5)


# ═══════════════════════════════════════════════════════════════
# GAIT — Hexapod-style sequential stepping
# ═══════════════════════════════════════════════════════════════

func _update_gait(delta: float) -> void:
	var root_count: int = _root_tips.size()

	# Update stepping roots
	for i in root_count:
		if _foot_stepping[i]:
			_foot_step_time[i] += delta / step_duration
			if _foot_step_time[i] >= 1.0:
				# Step complete — plant foot
				_foot_stepping[i] = false
				_foot_planted[i] = _foot_step_to[i]
				_foot_step_time[i] = 1.0

	# Find root that needs to step most urgently
	var worst_idx: int = -1
	var worst_dist: float = step_threshold
	var any_stepping: bool = false

	for i in root_count:
		if _foot_stepping[i]:
			any_stepping = true
			continue

		# Home position = where this root SHOULD be relative to entity
		var home: Vector3 = _entity.global_transform * _root_rest[i]
		home.y = 0.0  # Ground level

		var dist: float = _foot_planted[i].distance_to(home)
		if dist > worst_dist:
			worst_dist = dist
			worst_idx = i

	# Start stepping the worst offender (only one at a time)
	if worst_idx >= 0 and not any_stepping:
		_begin_step(worst_idx)

	# Position all root tips
	for i in root_count:
		_position_foot(i)


func _begin_step(idx: int) -> void:
	_foot_stepping[idx] = true
	_foot_step_time[idx] = 0.0
	_foot_step_from[idx] = _foot_planted[idx]

	# Step target: home position + overshoot in movement direction
	var home: Vector3 = _entity.global_transform * _root_rest[idx]
	home.y = 0.0
	_foot_step_to[idx] = home + _wander_direction * step_overshoot


func _position_foot(idx: int) -> void:
	var tip: MeshInstance3D = _root_tips[idx]
	if not is_instance_valid(tip):
		return

	var target_world: Vector3

	if _foot_stepping[idx]:
		# Interpolate from → to with parabolic arc
		var t: float = _foot_step_time[idx]
		# Smooth cubic interpolation
		var smooth_t: float = t * t * (3.0 - 2.0 * t)
		target_world = _foot_step_from[idx].lerp(_foot_step_to[idx], smooth_t)
		# Parabolic lift
		target_world.y += 4.0 * t * (1.0 - t) * step_height
	else:
		target_world = _foot_planted[idx]

	# Convert world position to local position relative to entity
	var local_pos: Vector3 = _entity.global_transform.affine_inverse() * target_world
	tip.position = local_pos


# ═══════════════════════════════════════════════════════════════
# BODY BOB — subtle vertical oscillation while walking
# ═══════════════════════════════════════════════════════════════

func _update_bob() -> void:
	if not _entity:
		return
	# Subtle bob based on how many feet are stepping
	var stepping_count: int = 0
	for s in _foot_stepping:
		if s:
			stepping_count += 1
	if stepping_count > 0:
		var bob: float = sin(_time * bob_speed) * bob_amplitude
		# Apply bob only to mesh children, not the entity position
		# (entity position is controlled by wander)
