# @identity
# essence: spring-damped fold_amount drives a layered pose pipeline — one variable, many body states
# desire: creatures that compress, deploy, misfold, and heal through intelligent geometry
# critical_parameter: fold_amount — 0 is maximally folded, 1 is fully deployed
# triggers: three-axis state model (affect/fold_state/activity) with spring dynamics and energy gating
# emerges: personality expressed through body geometry; tension builds toward misfold; care heals
# needs: FoldRig [has]; FoldSolver subclasses [has]; segment Node3D children [runtime]; player detection [has]
# relationships: extends to FoldDemoCritter, future fold creatures; wraps existing personality system; consumed by FoldingZoo
# truth: Separate what the creature wants to be, how it moves there, and how it was born — then connect them with one spring.

class_name FoldCritter
extends CharacterBody3D
## Runtime controller for foldable creatures.
## Manages a three-axis state model (affect, fold_state, activity),
## a spring-damped fold simulation, energy gating, misfold detection,
## and a layered pose pipeline driven by a FoldRig + FoldSolver.

# ── Signals ──────────────────────────────────────────────────────────────────

signal fold_state_changed(old_state: FoldState, new_state: FoldState)
signal misfold_triggered(amount: float)
signal fold_energy_depleted()

# ── Fold State Enum ──────────────────────────────────────────────────────────

enum FoldState {
	EGG,
	HATCHING,
	FOLDED,
	UNFOLDING,
	DEPLOYED,
	DEFENSIVE,
	REFOLDING,
	MISFOLDED,
	DORMANT,
}

# ── Exports ──────────────────────────────────────────────────────────────────

@export var fold_rig: FoldRig = null

@export_group("Detection")
@export var player_detect_radius: float = 3.0
@export var threat_detect_radius: float = 1.5

# ── Three Independent Axes ───────────────────────────────────────────────────

## Personality affect towards player: "foe", "wary", "neutral", "curious", "friend"
var affect: String = "neutral"

## Current fold state machine position.
var fold_state: FoldState = FoldState.EGG

## Current activity label (idle, wander, inspect, flee, sleep, etc.)
var activity: StringName = &"idle"

# ── Runtime Fold Variables ───────────────────────────────────────────────────

var fold_amount: float = 0.0     ## Current fold openness 0 (closed) .. 1 (open).
var target_fold: float = 0.0     ## Spring target set by state machine.
var fold_velocity: float = 0.0   ## Spring velocity for damped motion.
var fold_tension: float = 0.0    ## Accumulated mechanical tension (stress).
var fold_energy: float = 1.0     ## Energy reservoir; depleted by unfolding.
var misfold_amount: float = 0.0  ## Structural error accumulator.
var misfold_seed: int = 0        ## Deterministic seed for misfold jitter per creature.

# ── Internal ─────────────────────────────────────────────────────────────────

## Segment name -> Node3D reference, populated by _cache_segment_nodes().
var _segment_nodes: Dictionary = {}

var _player_node: Node3D = null
var _player_distance: float = INF
var _hit_reaction: Dictionary = {}   ## StringName -> Transform3D offset from impacts.
var _misfold_offset: Dictionary = {} ## StringName -> Transform3D offset from misfold.

const _MISFOLD_THRESHOLD: float = 0.5
const _TENSION_DECAY: float = 0.92
const _ENERGY_REGEN_RATE: float = 0.04
const _ENERGY_DEPLOY_COST: float = 0.15
const _HIT_REACTION_DECAY: float = 0.85


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_find_player()
	_cache_segment_nodes()
	_build_fold_mesh()
	_apply_initial_state()


func _physics_process(delta: float) -> void:
	if not fold_rig or not fold_rig.solver:
		return

	# 14-step update order:
	# 1. Sense player distance
	_update_player_distance()
	# 2. Update energy
	_update_energy(delta)
	# 3. Evaluate FSM transitions
	_evaluate_transitions()
	# 4. Set target fold from state
	_update_target_fold()
	# 5. Spring-damped fold integration
	_integrate_fold_spring(delta)
	# 6. Clamp fold amount to rig bounds
	_clamp_fold_amount()
	# 7. Accumulate tension
	_update_tension(delta)
	# 8. Check misfold threshold
	_check_misfold()
	# 9. Solver pass: compute base poses
	var solved: Dictionary = _solve_fold()
	# 10. Apply misfold offset layer
	var with_misfold: Dictionary = _apply_misfold_layer(solved)
	# 11. Apply hit reaction layer
	var with_hits: Dictionary = _apply_hit_reaction_layer(with_misfold)
	# 12. Secondary motion from solver
	var secondary: Dictionary = fold_rig.solver.compute_secondary(delta, activity)
	var final_poses: Dictionary = _merge_secondary(with_hits, secondary)
	# 13. Commit transforms to scene tree
	_commit_poses(final_poses)
	# 14. Decay transient state
	_decay_transients(delta)


# ── Virtual Stubs ────────────────────────────────────────────────────────────

## Override in subclasses to build procedural or instanced geometry.
func _build_fold_mesh() -> void:
	pass


## Override to react to state transitions (play audio, particles, etc.)
func _on_fold_state_changed(_old: FoldState, _new: FoldState) -> void:
	pass


# ── VR Verb API ──────────────────────────────────────────────────────────────

## Player squeezes the creature — push toward folded.
func vr_compress() -> void:
	if fold_state == FoldState.EGG or fold_state == FoldState.DORMANT:
		return
	fold_tension += 0.15
	target_fold = maxf(target_fold - 0.3, fold_rig.min_fold_amount)


## Player fans the creature open — assist unfolding.
func vr_fan_open() -> void:
	if fold_energy < 0.1:
		return
	target_fold = minf(target_fold + 0.3, fold_rig.max_fold_amount)
	fold_energy -= 0.05


## Player tucks a segment — reduce misfold locally.
func vr_tuck() -> void:
	misfold_amount = maxf(misfold_amount - 0.15, 0.0)
	fold_tension = maxf(fold_tension - 0.1, 0.0)


## Player smooths the surface — reduce tension.
func vr_smooth() -> void:
	fold_tension = maxf(fold_tension - 0.2, 0.0)
	misfold_amount = maxf(misfold_amount - 0.05, 0.0)


## Player feeds the creature — restore energy.
func vr_feed() -> void:
	fold_energy = minf(fold_energy + 0.3, fold_rig.max_fold_energy)


# ── FSM ──────────────────────────────────────────────────────────────────────

func _set_fold_state(new_state: FoldState) -> void:
	if new_state == fold_state:
		return
	if not fold_rig.is_state_allowed(new_state):
		return
	var old := fold_state
	fold_state = new_state
	_on_fold_state_changed(old, new_state)
	fold_state_changed.emit(old, new_state)


func _evaluate_transitions() -> void:
	# Global misfold override.
	if fold_state != FoldState.MISFOLDED and fold_rig.supports_misfold:
		if misfold_amount > _MISFOLD_THRESHOLD:
			_set_fold_state(FoldState.MISFOLDED)
			return

	match fold_state:
		FoldState.EGG:
			if fold_energy > 0.5 and fold_rig.is_hatchable:
				_set_fold_state(FoldState.HATCHING)

		FoldState.HATCHING:
			if fold_amount > 0.3:
				_set_fold_state(FoldState.FOLDED)

		FoldState.FOLDED:
			if fold_energy < 0.05:
				_set_fold_state(FoldState.DORMANT)
			elif _player_nearby() and _affect_allows_unfold():
				_set_fold_state(FoldState.UNFOLDING)

		FoldState.UNFOLDING:
			if fold_amount > 0.9:
				_set_fold_state(FoldState.DEPLOYED)

		FoldState.DEPLOYED:
			if _threat_nearby():
				_set_fold_state(FoldState.DEFENSIVE)
			elif fold_energy < 0.1 or activity == &"rest":
				_set_fold_state(FoldState.REFOLDING)

		FoldState.DEFENSIVE:
			if not _threat_nearby():
				_set_fold_state(FoldState.REFOLDING)

		FoldState.REFOLDING:
			if fold_amount < 0.15:
				_set_fold_state(FoldState.FOLDED)

		FoldState.MISFOLDED:
			if misfold_amount < 0.1:
				_set_fold_state(FoldState.REFOLDING)

		FoldState.DORMANT:
			if fold_energy > 0.3:
				_set_fold_state(FoldState.UNFOLDING)


func _update_target_fold() -> void:
	match fold_state:
		FoldState.EGG:
			target_fold = 0.0
		FoldState.HATCHING:
			target_fold = 0.4
		FoldState.FOLDED:
			target_fold = fold_rig.min_fold_amount + 0.05
		FoldState.UNFOLDING:
			target_fold = 1.0
		FoldState.DEPLOYED:
			target_fold = fold_rig.max_fold_amount
		FoldState.DEFENSIVE:
			target_fold = 0.1
		FoldState.REFOLDING:
			target_fold = fold_rig.min_fold_amount
		FoldState.MISFOLDED:
			pass  # Keep current target — don't force movement while misfolded.
		FoldState.DORMANT:
			target_fold = 0.0


# ── Spring Physics ───────────────────────────────────────────────────────────

func _integrate_fold_spring(delta: float) -> void:
	var stiffness: float = fold_rig.base_stiffness
	var damping: float = fold_rig.base_damping
	var error: float = target_fold - fold_amount
	var spring_force: float = error * stiffness
	fold_velocity += spring_force * delta
	fold_velocity *= damping
	fold_amount += fold_velocity * delta


func _clamp_fold_amount() -> void:
	fold_amount = clampf(fold_amount, fold_rig.min_fold_amount, fold_rig.max_fold_amount)


# ── Energy ───────────────────────────────────────────────────────────────────

func _update_energy(delta: float) -> void:
	# Deployed and unfolding cost energy.
	if fold_state == FoldState.DEPLOYED or fold_state == FoldState.UNFOLDING:
		fold_energy -= _ENERGY_DEPLOY_COST * delta
	else:
		# Passive regen when not actively deploying.
		fold_energy += _ENERGY_REGEN_RATE * delta

	fold_energy = clampf(fold_energy, 0.0, fold_rig.max_fold_energy)

	if fold_energy <= 0.0:
		fold_energy_depleted.emit()


# ── Tension & Misfold ───────────────────────────────────────────────────────

func _update_tension(_delta: float) -> void:
	# Rapid fold changes accumulate tension.
	fold_tension += absf(fold_velocity) * 0.1
	fold_tension *= _TENSION_DECAY
	fold_tension = clampf(fold_tension, 0.0, 1.0)

	# Tension feeds misfold when the rig supports it.
	if fold_rig.supports_misfold and fold_tension > 0.6:
		misfold_amount += (fold_tension - 0.6) * 0.02


func _check_misfold() -> void:
	if not fold_rig.supports_misfold:
		misfold_amount = 0.0
		return
	misfold_amount = clampf(misfold_amount, 0.0, 1.0)
	if misfold_amount > _MISFOLD_THRESHOLD and fold_state != FoldState.MISFOLDED:
		misfold_triggered.emit(misfold_amount)


# ── Pose Pipeline ────────────────────────────────────────────────────────────

func _solve_fold() -> Dictionary:
	return fold_rig.solver.compute_fold(
		fold_amount,
		fold_tension,
		fold_rig.segments,
		fold_rig.constraints,
	)


func _apply_misfold_layer(base: Dictionary) -> Dictionary:
	if misfold_amount < 0.01:
		return base
	var result: Dictionary = base.duplicate()
	for seg_name: StringName in result:
		if _misfold_offset.has(seg_name):
			result[seg_name] = result[seg_name] * _misfold_offset[seg_name]
		else:
			# Procedural jitter proportional to misfold (deterministic per creature per segment).
			var jitter := Transform3D.IDENTITY
			var rng := RandomNumberGenerator.new()
			rng.seed = misfold_seed + seg_name.hash()
			var angle: float = misfold_amount * 15.0 * rng.randf_range(-1.0, 1.0)
			var noise_axis := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
			jitter = jitter.rotated(noise_axis, deg_to_rad(angle))
			result[seg_name] = result[seg_name] * jitter
	return result


func _apply_hit_reaction_layer(base: Dictionary) -> Dictionary:
	if _hit_reaction.is_empty():
		return base
	var result: Dictionary = base.duplicate()
	for seg_name: StringName in _hit_reaction:
		if result.has(seg_name):
			result[seg_name] = result[seg_name] * _hit_reaction[seg_name]
	return result


func _merge_secondary(base: Dictionary, secondary: Dictionary) -> Dictionary:
	if secondary.is_empty():
		return base
	var result: Dictionary = base.duplicate()
	for seg_name: StringName in secondary:
		if result.has(seg_name):
			result[seg_name] = result[seg_name] * secondary[seg_name]
	return result


func _commit_poses(poses: Dictionary) -> void:
	for seg_name: StringName in poses:
		if _segment_nodes.has(seg_name):
			var node: Node3D = _segment_nodes[seg_name]
			node.transform = poses[seg_name]


# ── Transient Decay ──────────────────────────────────────────────────────────

func _decay_transients(_delta: float) -> void:
	# Decay hit reactions toward identity.
	var cleared: Array[StringName] = []
	for seg_name: StringName in _hit_reaction:
		var t: Transform3D = _hit_reaction[seg_name]
		t = t.interpolate_with(Transform3D.IDENTITY, 1.0 - _HIT_REACTION_DECAY)
		if t.origin.length_squared() < 0.0001:
			cleared.append(seg_name)
		else:
			_hit_reaction[seg_name] = t
	for seg_name: StringName in cleared:
		_hit_reaction.erase(seg_name)

	# Natural misfold healing (slow).
	if fold_state != FoldState.MISFOLDED:
		misfold_amount = maxf(misfold_amount - 0.002, 0.0)


# ── Player Detection ────────────────────────────────────────────────────────

func _find_player() -> void:
	# Try XROrigin3D first, then fall back to a node named "Player".
	_player_node = _find_node_by_class(&"XROrigin3D", get_tree().root)
	if not _player_node:
		_player_node = get_tree().root.find_child("Player", true, false)


func _find_node_by_class(cls: StringName, root: Node) -> Node:
	if root.is_class(cls):
		return root
	for child in root.get_children():
		var found := _find_node_by_class(cls, child)
		if found:
			return found
	return null


func _update_player_distance() -> void:
	if _player_node:
		_player_distance = global_position.distance_to(_player_node.global_position)
	else:
		_player_distance = INF


func _player_nearby() -> bool:
	return _player_distance < player_detect_radius


func _threat_nearby() -> bool:
	# For now, player counts as a threat when very close and affect is hostile.
	if _player_distance > threat_detect_radius:
		return false
	return affect == "foe" or affect == "wary"


func _affect_allows_unfold() -> bool:
	return affect == "curious" or affect == "friend"


# ── Setup Helpers ────────────────────────────────────────────────────────────

func _cache_segment_nodes() -> void:
	_segment_nodes.clear()
	if not fold_rig:
		return
	for seg: FoldSegmentData in fold_rig.segments:
		var node := find_child(String(seg.segment_name), true, false)
		if node and node is Node3D:
			_segment_nodes[seg.segment_name] = node


func _apply_initial_state() -> void:
	if fold_rig and fold_rig.is_hatchable:
		fold_state = FoldState.EGG
		fold_amount = 0.0
	else:
		fold_state = FoldState.FOLDED
		fold_amount = fold_rig.min_fold_amount + 0.05 if fold_rig else 0.0
	target_fold = fold_amount
	misfold_seed = get_instance_id()


# ── Grid Configuration ──────────────────────────────────────────────────────

func configure(config: Dictionary) -> void:
	if config.has("affect"):
		affect = str(config["affect"])
	if config.has("fold_state"):
		var state_name: String = str(config["fold_state"])
		for i in FoldState.size():
			if FoldState.keys()[i].to_lower() == state_name.to_lower():
				_set_fold_state(i as FoldState)
				break
	if config.has("fold_amount"):
		fold_amount = float(config["fold_amount"])
		target_fold = fold_amount
	if config.has("stiffness") and fold_rig:
		fold_rig.base_stiffness = float(config["stiffness"])
	if config.has("damping") and fold_rig:
		fold_rig.base_damping = float(config["damping"])
	if config.has("energy"):
		fold_energy = float(config["energy"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
