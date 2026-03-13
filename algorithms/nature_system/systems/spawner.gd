# CritterSpawner.gd — Instantiation pipeline for the Nature System
#
# Takes a CritterDNA and produces a fully realized CritterEntity in the world:
#   DNA → MorphologyRouter → CritterEntity with mesh + material + metadata
#
# Supports single spawning, batch spawning, population seeding, and LOD
# selection based on distance to a reference point (e.g., VR player head).
#
# Usage:
#   @onready var spawner := CritterSpawner.new()
#   spawner.world_root = $NatureRoot
#   var entity: CritterEntity = spawner.spawn(dna, position)
#
#   # Or seed a population:
#   spawner.seed_population(kingdom, count, center, radius)

class_name CritterSpawner
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Parent node for all spawned critters. Must be set before spawning.
var world_root: Node3D = null

## Shared trait mapper (avoids creating one per critter).
var trait_mapper: CritterTraitMapper = null

## Reference point for LOD calculation (e.g., XRCamera3D.global_position).
## If null, LOD defaults to default_lod.
var lod_reference_point: Vector3 = Vector3.ZERO
var use_lod_reference: bool = false

## Default LOD when no reference point is set.
var default_lod: int = 2

## LOD distance thresholds (meters from reference point).
var lod_thresholds: Array[float] = [5.0, 15.0, 30.0]  # LOD 0/1/2/3 cutoffs

## Maximum active critters. spawn() returns null if at capacity.
var max_population: int = 100

## Enable debug prints.
var debug: bool = false

# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## All currently alive critters managed by this spawner.
var _active_critters: Array[CritterEntity] = []

## Spawn counter for unique naming.
var _spawn_counter: int = 0


# ═══════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════

func _init(root: Node3D = null) -> void:
	world_root = root
	trait_mapper = CritterTraitMapper.new()


# ═══════════════════════════════════════════════════════════════
# SINGLE SPAWN
# ═══════════════════════════════════════════════════════════════

## Spawn a single critter from DNA at a world position.
## Returns the CritterEntity, or null if at capacity or missing world_root.
func spawn(dna: CritterDNA, world_position: Vector3 = Vector3.ZERO, lod_override: int = -1) -> CritterEntity:
	if not world_root:
		push_error("[CritterSpawner] Cannot spawn: world_root is null")
		return null

	if _active_critters.size() >= max_population:
		if debug:
			push_warning("[CritterSpawner] At capacity (%d/%d), cannot spawn" % [
				_active_critters.size(), max_population
			])
		return null

	# Create entity
	var entity := CritterEntity.new()
	_spawn_counter += 1
	entity.name = "Critter_%s_%d" % [dna.get_kingdom_name(), _spawn_counter]
	entity.debug_mode = debug

	# Add to scene tree first (CritterEntity._ready needs to fire)
	world_root.add_child(entity)
	entity.global_position = world_position

	# Determine LOD
	var lod: int = lod_override if lod_override >= 0 else _calculate_lod(world_position)

	# Build morphology via router
	var _mesh_root: Node3D = MorphologyRouter.build(dna, entity, trait_mapper, lod)

	# Inject DNA (triggers _on_dna_changed → _apply_visual_traits → _apply_materials)
	entity.init_from_dna(dna)

	# Store LOD on entity for later updates
	entity.set_meta("lod", lod)
	entity.set_meta("spawner_id", _spawn_counter)

	# Track
	_active_critters.append(entity)

	# Connect to tree_exiting for cleanup
	entity.tree_exiting.connect(_on_critter_removed.bind(entity))

	if debug:
		print("[CritterSpawner] Spawned %s at %s (LOD %d, pop: %d/%d)" % [
			entity.name, str(world_position), lod,
			_active_critters.size(), max_population
		])

	return entity


## Spawn from a pre-built DNA with a random offset within a radius.
func spawn_near(dna: CritterDNA, center: Vector3, radius: float) -> CritterEntity:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var offset := Vector3(
		rng.randf_range(-radius, radius),
		0.0,
		rng.randf_range(-radius, radius)
	)
	return spawn(dna, center + offset)


# ═══════════════════════════════════════════════════════════════
# BATCH SPAWN / POPULATION SEEDING
# ═══════════════════════════════════════════════════════════════

## Seed a population of a specific kingdom around a center point.
## Returns the array of spawned entities (may be fewer than count if at capacity).
func seed_population(
	kingdom: int,
	count: int,
	center: Vector3,
	radius: float,
	rng_seed: int = -1
) -> Array[CritterEntity]:
	var spawned: Array[CritterEntity] = []
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	for i in count:
		var dna: CritterDNA = CritterDNA.random_kingdom(kingdom, rng.randi() if rng_seed >= 0 else -1)

		# Distribute in a circle with some randomness
		var angle: float = (float(i) / float(count)) * TAU + rng.randf_range(-0.3, 0.3)
		var dist: float = rng.randf_range(radius * 0.1, radius)
		var pos := center + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

		var entity: CritterEntity = spawn(dna, pos)
		if entity:
			spawned.append(entity)
		else:
			break  # At capacity

	if debug:
		print("[CritterSpawner] Seeded %d/%d %s critters around %s (r=%.1f)" % [
			spawned.size(), count, CritterDNA.new().get_kingdom_name() if kingdom < 0 else MorphologyRouter.kingdom_name(float(kingdom)),
			str(center), radius
		])

	return spawned


## Seed a mixed population of all kingdoms.
func seed_mixed_population(
	count: int,
	center: Vector3,
	radius: float,
	rng_seed: int = -1
) -> Array[CritterEntity]:
	var spawned: Array[CritterEntity] = []
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	for i in count:
		var kingdom: int = rng.randi_range(0, 3)
		var dna: CritterDNA = CritterDNA.random_kingdom(kingdom, rng.randi() if rng_seed >= 0 else -1)

		var angle: float = (float(i) / float(count)) * TAU + rng.randf_range(-0.5, 0.5)
		var dist: float = rng.randf_range(radius * 0.1, radius)
		var pos := center + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

		var entity: CritterEntity = spawn(dna, pos)
		if entity:
			spawned.append(entity)
		else:
			break

	return spawned


## Spawn a child from two parent entities near the parents.
func spawn_offspring(
	parent_a: CritterEntity,
	parent_b: CritterEntity,
	offset: Vector3 = Vector3(0.5, 0.0, 0.0)
) -> CritterEntity:
	if not parent_a or not parent_b:
		push_error("[CritterSpawner] Cannot breed: null parent")
		return null

	var child_dna: CritterDNA = parent_a.breed_with(parent_b)
	if not child_dna:
		return null

	# Spawn between the two parents
	var mid_pos: Vector3 = (parent_a.global_position + parent_b.global_position) * 0.5
	return spawn(child_dna, mid_pos + offset)


# ═══════════════════════════════════════════════════════════════
# REMOVAL / CLEANUP
# ═══════════════════════════════════════════════════════════════

## Remove and free a specific critter.
func despawn(entity: CritterEntity) -> void:
	if not entity:
		return

	_active_critters.erase(entity)
	if entity.is_inside_tree():
		entity.get_parent().remove_child(entity)
	entity.queue_free()

	if debug:
		print("[CritterSpawner] Despawned %s (pop: %d/%d)" % [
			entity.name, _active_critters.size(), max_population
		])


## Remove all managed critters.
func despawn_all() -> void:
	for entity in _active_critters.duplicate():
		if is_instance_valid(entity):
			if entity.is_inside_tree():
				entity.get_parent().remove_child(entity)
			entity.queue_free()

	_active_critters.clear()

	if debug:
		print("[CritterSpawner] Despawned all critters")


## Cleanup callback when a critter is removed from the tree externally.
func _on_critter_removed(entity: CritterEntity) -> void:
	_active_critters.erase(entity)


# ═══════════════════════════════════════════════════════════════
# LOD MANAGEMENT
# ═══════════════════════════════════════════════════════════════

## Calculate LOD level based on distance to reference point.
func _calculate_lod(world_position: Vector3) -> int:
	if not use_lod_reference:
		return default_lod

	var dist: float = world_position.distance_to(lod_reference_point)

	if dist < lod_thresholds[0]:
		return 0
	elif dist < lod_thresholds[1]:
		return 1
	elif dist < lod_thresholds[2]:
		return 2
	else:
		return 3


## Update LOD reference point (call each frame from VR camera).
func update_lod_reference(position: Vector3) -> void:
	lod_reference_point = position
	use_lod_reference = true


## Rebuild all critters that need LOD changes based on current reference.
## Call periodically (not every frame — every 0.5s is fine).
func update_lod_levels() -> void:
	if not use_lod_reference:
		return

	for entity in _active_critters:
		if not is_instance_valid(entity):
			continue

		var current_lod: int = entity.get_meta("lod", default_lod) as int
		var new_lod: int = _calculate_lod(entity.global_position)

		if new_lod != current_lod:
			# Rebuild mesh at new LOD
			MorphologyRouter.rebuild(entity, entity.dna, trait_mapper, new_lod)
			entity.set_meta("lod", new_lod)

			if debug:
				print("[CritterSpawner] LOD change: %s %d → %d" % [
					entity.name, current_lod, new_lod
				])


# ═══════════════════════════════════════════════════════════════
# QUERIES
# ═══════════════════════════════════════════════════════════════

## Get all currently active critters.
func get_active_critters() -> Array[CritterEntity]:
	# Prune invalid references
	var valid: Array[CritterEntity] = []
	for e in _active_critters:
		if is_instance_valid(e):
			valid.append(e)
	_active_critters = valid
	return _active_critters


## Get critters of a specific kingdom.
func get_critters_by_kingdom(kingdom: int) -> Array[CritterEntity]:
	var result: Array[CritterEntity] = []
	for e in _active_critters:
		if is_instance_valid(e) and e.get_kingdom() == kingdom:
			result.append(e)
	return result


## Get the nearest critter to a world position.
func get_nearest(position: Vector3) -> CritterEntity:
	var best: CritterEntity = null
	var best_dist: float = INF

	for e in _active_critters:
		if not is_instance_valid(e):
			continue
		var d: float = e.global_position.distance_squared_to(position)
		if d < best_dist:
			best_dist = d
			best = e

	return best


## Get all critters within a radius of a position.
func get_within_radius(position: Vector3, radius: float) -> Array[CritterEntity]:
	var result: Array[CritterEntity] = []
	var r_sq: float = radius * radius

	for e in _active_critters:
		if is_instance_valid(e) and e.global_position.distance_squared_to(position) <= r_sq:
			result.append(e)

	return result


## Current population count.
func get_population_count() -> int:
	return _active_critters.size()


## Population broken down by kingdom.
func get_population_summary() -> Dictionary:
	var summary := {
		"tree": 0,
		"creature": 0,
		"flower": 0,
		"fungus": 0,
		"hybrid": 0,
		"total": 0,
	}
	for e in _active_critters:
		if is_instance_valid(e):
			var kn: String = e.get_kingdom_name()
			if kn in summary:
				summary[kn] += 1
			summary["total"] += 1
	return summary

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

