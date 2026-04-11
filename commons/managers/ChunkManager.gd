# ChunkManager.gd — Spatial chunk-based LOD for the ecosystem
#
# Divides the spawn area into a grid of chunks (4×4m cells by default).
# Each chunk manages its organisms with distance-based LOD: near chunks
# get full-detail morphology (LOD 3), far chunks get simplified meshes
# (LOD 0). Godot's visibility_range system handles GPU-side culling.
#
# Because every organism has unique DNA → unique geometry, we can't batch
# them into shared MultiMeshes. Instead, LOD works by:
#   1. Building morphology at the chunk's LOD tier (MorphologyRouter accepts lod 0-3)
#   2. Applying visibility_range_end so Godot skips distant draw calls
#   3. Rebuilding morphology when the player moves and chunk tiers change
#   4. Throttling creature animations at distance
#
# Replaces flat-circle spawning from EcosystemNatureSpawner with spatial
# awareness while keeping the same EcosystemManager integration.
#
# Usage:
#   Created automatically by EcosystemNatureSpawner when use_chunk_system = true.
#   Or place directly in a scene and configure exports.

extends Node3D
class_name ChunkManager

# ── Configuration ─────────────────────────────────────────────────────

## World-space size of each chunk cell (square, XZ plane).
@export var chunk_size: float = 4.0

## Max total organisms across all chunks.
@export var max_population: int = 60

## Spawn radius around center (circular boundary).
@export var spawn_radius: float = 12.0

## Spawn center offset from this node's position.
@export var center_offset: Vector3 = Vector3.ZERO

## Seed for deterministic placement (-1 = random).
@export var rng_seed: int = -1

## Seconds between LOD tier recalculations.
@export var lod_update_interval: float = 0.5

## Distance beyond which creature animations are throttled.
@export var creature_throttle_distance: float = 10.0

## Override EcosystemManager density (for test maps). -1 = use EcosystemManager.
@export var override_density: float = -1.0

## Override EcosystemManager kingdoms (for test maps). Empty = use EcosystemManager.
@export var override_kingdoms: Array[String] = []


# ── LOD tier distance thresholds ─────────────────────────────────────

## Distances defining LOD tier boundaries (from player to chunk center).
const LOD_TIER_NEAR: float = 5.0     # < 5m → LOD 3 (full detail)
const LOD_TIER_MID: float = 10.0     # 5-10m → LOD 2
const LOD_TIER_FAR: float = 18.0     # 10-18m → LOD 1
# Beyond LOD_TIER_FAR → LOD 0 (minimal detail)

## Population density multiplier per LOD tier.
const TIER_DENSITY := [0.3, 0.5, 0.8, 1.0]  # [tier0, tier1, tier2, tier3]

## Morphology LOD per tier (inverted: tier 3 = most detail = lod 3).
const TIER_MORPH_LOD := [0, 1, 2, 3]  # [tier0, tier1, tier2, tier3]

## Hysteresis band (meters) to prevent LOD popping at boundaries.
const LOD_HYSTERESIS: float = 1.0

## Max morphology rebuilds per LOD update tick (frame budget control).
const MAX_REBUILDS_PER_TICK: int = 3


# ── Kingdom constants (matching CritterDNA) ──────────────────────────

const KINGDOM_FLOWER: int = 0
const KINGDOM_TREE: int = 1
const KINGDOM_FUNGUS: int = 2
const KINGDOM_CREATURE: int = 3

const KINGDOM_MAP: Dictionary = {
	"flower": KINGDOM_FLOWER,
	"tree": KINGDOM_TREE,
	"fungus": KINGDOM_FUNGUS,
	"creature": KINGDOM_CREATURE,
}


# ── Runtime state ────────────────────────────────────────────────────

var _spawner: CritterSpawner = null
var _nature_root: Node3D = null
var _player_node: Node3D = null
var _player_position: Vector3 = Vector3.ZERO
var _spawn_center: Vector3 = Vector3.ZERO

## Chunk grid: Vector2i coord → ChunkData
var _chunks: Dictionary = {}

## Queue of pending LOD rebuilds: [{entity, dna, lod}]
var _rebuild_queue: Array[Dictionary] = []

## Queue of pending spawn jobs: [{chunk, kingdom_id, dna, pos, morph_lod}]
var _spawn_queue: Array[Dictionary] = []

## Max morphology builds per frame (spawn + rebuild combined).
const MAX_BUILDS_PER_FRAME: int = 2

## Timer for periodic LOD updates.
var _lod_timer: float = 0.0

## Whether we've done the initial population.
var _has_populated: bool = false

# ── Performance monitoring ──────────────────────────────────────────
var _perf_timer: float = 0.0
const PERF_LOG_INTERVAL: float = 3.0  # seconds between perf logs
var _perf_frame_times: Array[float] = []  # recent delta values
var _perf_build_count: int = 0  # morphology builds since last log


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_nature_root = Node3D.new()
	_nature_root.name = "ChunkPopulation"
	add_child(_nature_root)

	_spawner = CritterSpawner.new(_nature_root)
	_spawner.max_population = max_population

	# Connect to EcosystemManager
	call_deferred("_connect_signals")
	call_deferred("_initial_populate")


func _connect_signals() -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco:
		if eco.has_signal("ecosystem_stage_advanced"):
			eco.ecosystem_stage_advanced.connect(_on_stage_advanced)
		if eco.has_signal("vegetation_config_changed"):
			eco.vegetation_config_changed.connect(_on_vegetation_changed)
		print("ChunkManager: Connected to EcosystemManager")


func _initial_populate() -> void:
	await get_tree().process_frame
	_find_player()
	_update_player_position()
	_rebuild_population()


func _on_stage_advanced(_sequence_name: String) -> void:
	_rebuild_population()


func _on_vegetation_changed(_config: Dictionary) -> void:
	_rebuild_population()


func _process(delta: float) -> void:
	# Track frame times for perf monitoring
	_perf_frame_times.append(delta)

	# Process pending spawn jobs and LOD rebuilds (budget-limited per frame)
	var builds_this_frame: int = 0
	builds_this_frame += _process_spawn_queue(MAX_BUILDS_PER_FRAME)
	if builds_this_frame < MAX_BUILDS_PER_FRAME:
		_process_rebuild_queue(MAX_BUILDS_PER_FRAME - builds_this_frame)
	_perf_build_count += builds_this_frame

	# Periodic LOD tier recalculation
	_lod_timer += delta
	if _lod_timer < lod_update_interval:
		# Performance logging (independent of LOD timer)
		_perf_timer += delta
		if _perf_timer >= PERF_LOG_INTERVAL:
			_log_performance()
		return
	_lod_timer = 0.0

	# Update player tracking
	if not _player_node or not is_instance_valid(_player_node):
		_find_player()
	_update_player_position()

	# Recalculate chunk LOD tiers
	_update_chunk_lod_tiers()

	# Throttle distant creature animations
	_throttle_creatures()

	# Performance logging
	_perf_timer += delta
	if _perf_timer >= PERF_LOG_INTERVAL:
		_log_performance()


# ═══════════════════════════════════════════════════════════════
# PLAYER TRACKING
# ═══════════════════════════════════════════════════════════════

func _find_player() -> void:
	# Follow the project's established pattern for finding the VR player
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		get_tree().get_first_node_in_group("xr_origin"),
		get_tree().current_scene.find_child("XROrigin3D", true, false) if get_tree().current_scene else null,
		get_tree().current_scene.find_child("Player", true, false) if get_tree().current_scene else null,
	]:
		if candidate is Node3D:
			_player_node = candidate
			return
	_player_node = null


func _update_player_position() -> void:
	if _player_node and is_instance_valid(_player_node):
		_player_position = _player_node.global_position
	else:
		# Fallback: use spawn center
		_player_position = _spawn_center


# ═══════════════════════════════════════════════════════════════
# CHUNK GRID
# ═══════════════════════════════════════════════════════════════

## Convert a world position to chunk grid coordinate.
func _world_to_chunk(world_pos: Vector3) -> Vector2i:
	var local_x: float = world_pos.x - (_spawn_center.x - spawn_radius)
	var local_z: float = world_pos.z - (_spawn_center.z - spawn_radius)
	return Vector2i(floori(local_x / chunk_size), floori(local_z / chunk_size))


## Get the world-space center of a chunk coordinate.
func _chunk_center(coord: Vector2i) -> Vector3:
	var base_x: float = _spawn_center.x - spawn_radius
	var base_z: float = _spawn_center.z - spawn_radius
	return Vector3(
		base_x + (coord.x + 0.5) * chunk_size,
		_spawn_center.y,
		base_z + (coord.y + 0.5) * chunk_size
	)


## Determine which chunk coordinates fall within the spawn radius circle.
func _get_active_chunk_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var grid_span: int = ceili(spawn_radius * 2.0 / chunk_size)

	for cx in range(grid_span):
		for cz in range(grid_span):
			var coord := Vector2i(cx, cz)
			var center := _chunk_center(coord)
			# Check if chunk center is within spawn radius
			var dist_xz := Vector2(center.x - _spawn_center.x, center.z - _spawn_center.z).length()
			if dist_xz <= spawn_radius + chunk_size * 0.5:
				coords.append(coord)

	return coords


## Calculate LOD tier for a chunk based on distance to player.
## Returns 0 (distant) to 3 (near).
func _calculate_tier(chunk_center: Vector3) -> int:
	var dist := Vector2(
		chunk_center.x - _player_position.x,
		chunk_center.z - _player_position.z
	).length()

	if dist < LOD_TIER_NEAR:
		return 3
	elif dist < LOD_TIER_MID:
		return 2
	elif dist < LOD_TIER_FAR:
		return 1
	else:
		return 0


## Calculate LOD tier with hysteresis (prevents popping at boundaries).
func _calculate_tier_with_hysteresis(chunk_center: Vector3, current_tier: int) -> int:
	var dist := Vector2(
		chunk_center.x - _player_position.x,
		chunk_center.z - _player_position.z
	).length()

	# If uninitialized, just return the raw tier
	if current_tier < 0:
		return _calculate_tier(chunk_center)

	# Apply hysteresis: require crossing the boundary + margin to change tier
	var new_tier: int = current_tier

	# Check if we should upgrade (increase detail = higher tier number)
	match current_tier:
		0:
			if dist < LOD_TIER_FAR - LOD_HYSTERESIS:
				new_tier = 1
		1:
			if dist < LOD_TIER_MID - LOD_HYSTERESIS:
				new_tier = 2
			elif dist > LOD_TIER_FAR + LOD_HYSTERESIS:
				new_tier = 0
		2:
			if dist < LOD_TIER_NEAR - LOD_HYSTERESIS:
				new_tier = 3
			elif dist > LOD_TIER_MID + LOD_HYSTERESIS:
				new_tier = 1
		3:
			if dist > LOD_TIER_NEAR + LOD_HYSTERESIS:
				new_tier = 2

	return new_tier


# ═══════════════════════════════════════════════════════════════
# POPULATION
# ═══════════════════════════════════════════════════════════════

## Rebuild the entire population from scratch.
## Queues spawn jobs instead of building all meshes in one frame.
func _rebuild_population() -> void:
	var eco = get_node_or_null("/root/EcosystemManager")

	# Resolve density and kingdoms — use overrides if set, else EcosystemManager
	var density: float = override_density if override_density >= 0.0 else (eco.get_vegetation_density() if eco else 0.0)
	var kingdoms: Array = override_kingdoms if not override_kingdoms.is_empty() else (eco.get_allowed_kingdoms() if eco else [])

	# Nothing to spawn
	if density <= 0.0 or kingdoms.is_empty():
		_despawn_all()
		print("ChunkManager: Nothing to spawn (density=%.2f, kingdoms=%s)" % [density, str(kingdoms)])
		return

	# Skip if population is already roughly correct
	var target_total: int = int(max_population * density)
	var current_total: int = _spawner.get_population_count()
	if abs(current_total - target_total) < 3 and _has_populated:
		return

	# Clear everything
	_despawn_all()

	_spawn_center = global_position + center_offset
	_update_player_position()

	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	# Resolve kingdom IDs
	var kingdom_ids: Array[int] = []
	for k_name in kingdoms:
		if KINGDOM_MAP.has(k_name):
			kingdom_ids.append(KINGDOM_MAP[k_name])
	if kingdom_ids.is_empty():
		return

	# Calculate chunk grid
	var coords := _get_active_chunk_coords()
	if coords.is_empty():
		return

	# Distribute population across chunks with distance-based density
	var total_weight: float = 0.0
	var chunk_tiers: Dictionary = {}  # Vector2i → tier

	for coord in coords:
		var center := _chunk_center(coord)
		var tier: int = _calculate_tier(center)
		chunk_tiers[coord] = tier
		total_weight += TIER_DENSITY[tier]

	# Queue spawn jobs per chunk (no meshes built yet — just DNA + positions)
	var queued_total: int = 0
	for coord in coords:
		var tier: int = chunk_tiers[coord]
		var center := _chunk_center(coord)

		# Allocate organisms to this chunk proportional to its weight
		var chunk_target: int = 0
		if total_weight > 0.0:
			chunk_target = roundi(target_total * TIER_DENSITY[tier] / total_weight)
		chunk_target = maxi(chunk_target, 0)

		# Create chunk data
		var chunk := ChunkData.new()
		chunk.coord = coord
		chunk.center = center
		chunk.current_lod_tier = tier
		_chunks[coord] = chunk

		if chunk_target == 0:
			continue

		# Distribute across kingdoms
		var per_kingdom: int = maxi(1, chunk_target / kingdom_ids.size())
		var half_chunk: float = chunk_size * 0.5

		for kid in kingdom_ids:
			var count: int = per_kingdom
			if kid == KINGDOM_FLOWER and density < 0.5:
				count = int(count * 1.5)
			elif kid == KINGDOM_CREATURE and density < 0.7:
				count = int(count * 0.5)

			if queued_total + count > target_total:
				count = target_total - queued_total
			if count <= 0:
				continue

			# Queue individual spawn jobs (cheap — just DNA + position, no mesh yet)
			for _i in range(count):
				var dna := CritterDNA.random_kingdom(kid, rng.randi())
				# Scale DNA complexity by density — early maps get simpler organisms
				_scale_dna_complexity(dna, density)
				var offset_x: float = rng.randf_range(-half_chunk, half_chunk)
				var offset_z: float = rng.randf_range(-half_chunk, half_chunk)
				var pos := Vector3(
					chunk.center.x + offset_x,
					_spawn_center.y,
					chunk.center.z + offset_z
				)
				# Reject outside spawn radius
				var dist_xz := Vector2(pos.x - _spawn_center.x, pos.z - _spawn_center.z).length()
				if dist_xz > spawn_radius:
					continue
				# Reject inside grid area (organisms should be in the ring, not on the grid)
				if has_meta("grid_half_w") and has_meta("grid_center"):
					var gc: Vector3 = get_meta("grid_center")
					var hw: float = get_meta("grid_half_w")
					var hd: float = get_meta("grid_half_d")
					if absf(pos.x - gc.x) < hw and absf(pos.z - gc.z) < hd:
						continue

				_spawn_queue.append({
					"chunk_coord": coord,
					"kingdom_id": kid,
					"dna": dna,
					"pos": pos,
					"tier": tier,
				})
				queued_total += 1

			if queued_total >= target_total:
				break
		if queued_total >= target_total:
			break

	_has_populated = true
	print("ChunkManager: Queued %d organisms across %d chunks (density=%.2f, kingdoms=%s)" % [
		queued_total, _chunks.size(), density, str(kingdoms)
	])


## Scale DNA complexity by curriculum density.
## Low density (early sequences) → simple organisms. High density → full complexity.
func _scale_dna_complexity(dna: CritterDNA, density: float) -> void:
	# Lerp from simple (few segments, small) to complex (many segments, large)
	dna.segments = lerpf(2.0, dna.segments, density)
	dna.symmetry = lerpf(1.0, dna.symmetry, density)
	dna.branch_angle = lerpf(25.0, dna.branch_angle, density)
	dna.branch_decay = lerpf(0.7, dna.branch_decay, density)
	dna.leaf_density = lerpf(0.3, dna.leaf_density, density)
	dna.iridescence = lerpf(0.0, dna.iridescence, density)
	dna.scale = lerpf(0.5, dna.scale, clampf(density * 1.5, 0.0, 1.0))


## Process pending spawn jobs (budget-limited per frame). Returns builds done.
func _process_spawn_queue(budget: int) -> int:
	var count: int = 0
	while not _spawn_queue.is_empty() and count < budget:
		var job: Dictionary = _spawn_queue.pop_front()
		var coord: Vector2i = job["chunk_coord"]
		var kingdom_id: int = job["kingdom_id"]
		var dna: CritterDNA = job["dna"]
		var pos: Vector3 = job["pos"]
		var tier: int = job["tier"]

		# Always build at LOD 0 (fastest mesh). LOD system upgrades nearby later.
		var entity: CritterEntity = _spawner.spawn(dna, pos, 0)
		if not entity:
			break  # At capacity

		# Merge all child meshes into one draw call (massive VR perf win)
		_merge_entity_meshes(entity)

		# Apply visibility ranges
		VisibilityRangeHelper.apply_lod_tier_ranges(entity, tier)

		# Register in chunk
		var chunk: ChunkData = _chunks.get(coord)
		if chunk:
			if _is_static_kingdom(kingdom_id):
				entity.set_process(false)
				entity.set_physics_process(false)
				chunk.add_plant(entity, dna)
			else:
				chunk.add_creature(entity)

			# If chunk is near player, queue LOD upgrade from 0 → actual tier LOD
			if tier >= 2:
				_rebuild_queue.append({
					"entity": entity,
					"dna": dna,
					"lod": TIER_MORPH_LOD[tier],
					"tier": tier,
				})

		count += 1
	return count


## Clear all chunks and despawn all organisms.
func _despawn_all() -> void:
	_spawner.despawn_all()
	_chunks.clear()
	_rebuild_queue.clear()
	_spawn_queue.clear()
	_has_populated = false


# ═══════════════════════════════════════════════════════════════
# LOD UPDATES
# ═══════════════════════════════════════════════════════════════

## Recalculate LOD tiers for all chunks based on current player position.
func _update_chunk_lod_tiers() -> void:
	for coord in _chunks:
		var chunk: ChunkData = _chunks[coord]
		var new_tier: int = _calculate_tier_with_hysteresis(
			chunk.center, chunk.current_lod_tier
		)

		if new_tier != chunk.current_lod_tier:
			var old_tier: int = chunk.current_lod_tier
			chunk.current_lod_tier = new_tier

			# Queue LOD rebuilds for plant entities in this chunk
			var new_morph_lod: int = TIER_MORPH_LOD[new_tier]
			for i in range(chunk.plant_entities.size()):
				var entity: CritterEntity = chunk.plant_entities[i]
				if not is_instance_valid(entity):
					continue
				var dna: CritterDNA = chunk.plant_dna_cache[i]
				_rebuild_queue.append({
					"entity": entity,
					"dna": dna,
					"lod": new_morph_lod,
					"tier": new_tier,
				})

			# Update visibility ranges on creatures immediately (cheap)
			for entity in chunk.creature_entities:
				if is_instance_valid(entity):
					VisibilityRangeHelper.apply_lod_tier_ranges(entity, new_tier)


## Process pending LOD rebuilds (budget-limited per frame).
func _process_rebuild_queue(budget: int = MAX_REBUILDS_PER_TICK) -> void:
	var count: int = 0
	while not _rebuild_queue.is_empty() and count < budget:
		var job: Dictionary = _rebuild_queue.pop_front()
		var entity: CritterEntity = job["entity"]
		var dna: CritterDNA = job["dna"]
		var lod: int = job["lod"]
		var tier: int = job["tier"]

		if not is_instance_valid(entity):
			continue

		# Rebuild morphology at new LOD
		MorphologyRouter.rebuild(entity, dna, _spawner.trait_mapper, lod)

		# Re-merge meshes after rebuild (draw call reduction)
		_merge_entity_meshes(entity)

		# Update visibility ranges
		VisibilityRangeHelper.apply_lod_tier_ranges(entity, tier)

		# Update metadata
		entity.set_meta("lod", lod)

		count += 1


# ═══════════════════════════════════════════════════════════════
# CREATURE THROTTLING
# ═══════════════════════════════════════════════════════════════

## Throttle/unthrottle creature animations based on distance.
func _throttle_creatures() -> void:
	for coord in _chunks:
		var chunk: ChunkData = _chunks[coord]
		if chunk.creature_entities.is_empty():
			continue

		for entity in chunk.creature_entities:
			if not is_instance_valid(entity):
				continue

			var dist := entity.global_position.distance_to(_player_position)

			if dist > creature_throttle_distance:
				# Throttle: disable physics/process
				if not entity.get_meta("animation_throttled", false):
					entity.set_physics_process(false)
					entity.set_meta("animation_throttled", true)
			else:
				# Unthrottle: restore physics/process
				if entity.get_meta("animation_throttled", false):
					entity.set_physics_process(true)
					entity.set_meta("animation_throttled", false)


# ═══════════════════════════════════════════════════════════════
# UTILITY
# ═══════════════════════════════════════════════════════════════

## Merge all MeshInstance3D children of an entity into one combined mesh.
## Finds the morphology_root child and merges its mesh descendants.
func _merge_entity_meshes(entity: Node3D) -> void:
	# Find the morphology root (tagged by MorphologyRouter)
	var morph_root: Node3D = null
	for child in entity.get_children():
		if child.has_meta("morphology_root"):
			morph_root = child as Node3D
			break
	if not morph_root:
		morph_root = entity  # Fallback: merge directly under entity

	var merged: int = VisibilityRangeHelper.merge_mesh_children(morph_root)
	if merged > 1:
		entity.set_meta("meshes_merged", merged)


## Check if a kingdom ID is static (plants don't move after spawn).
func _is_static_kingdom(kingdom_id: int) -> bool:
	return kingdom_id != KINGDOM_CREATURE


## Get total organism count across all chunks.
func get_population_count() -> int:
	return _spawner.get_population_count()


## Log performance metrics to console.
func _log_performance() -> void:
	_perf_timer = 0.0

	if _perf_frame_times.is_empty():
		return

	# Calculate frame time stats
	var frame_count: int = _perf_frame_times.size()
	var sum: float = 0.0
	var worst: float = 0.0
	for ft in _perf_frame_times:
		sum += ft
		if ft > worst:
			worst = ft
	var avg_ms: float = (sum / frame_count) * 1000.0
	var worst_ms: float = worst * 1000.0
	var avg_fps: float = 1000.0 / avg_ms if avg_ms > 0.0 else 0.0

	# Godot engine stats
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var objects_drawn: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var vertices: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	# Ecosystem stats
	var pop: int = _spawner.get_population_count() if _spawner else 0
	var spawn_q: int = _spawn_queue.size()
	var rebuild_q: int = _rebuild_queue.size()

	# Chunk tier breakdown
	var tier_counts := [0, 0, 0, 0]
	for coord in _chunks:
		var chunk: ChunkData = _chunks[coord]
		if chunk.current_lod_tier >= 0 and chunk.current_lod_tier <= 3:
			tier_counts[chunk.current_lod_tier] += 1

	print("─── PERF ─── fps=%d avg=%.1fms worst=%.1fms | draws=%d objs=%d verts=%d nodes=%d | pop=%d spawn_q=%d rebuild_q=%d builds=%d | tiers=[%d,%d,%d,%d]" % [
		int(avg_fps), avg_ms, worst_ms,
		draw_calls, objects_drawn, vertices, node_count,
		pop, spawn_q, rebuild_q, _perf_build_count,
		tier_counts[0], tier_counts[1], tier_counts[2], tier_counts[3],
	])

	_perf_frame_times.clear()
	_perf_build_count = 0


## Get summary of chunk states for debugging.
func get_chunk_summary() -> Dictionary:
	var tier_counts := [0, 0, 0, 0]
	var total_plants: int = 0
	var total_creatures: int = 0

	for coord in _chunks:
		var chunk: ChunkData = _chunks[coord]
		if chunk.current_lod_tier >= 0 and chunk.current_lod_tier <= 3:
			tier_counts[chunk.current_lod_tier] += 1
		total_plants += chunk.plant_entities.size()
		total_creatures += chunk.creature_entities.size()

	return {
		"total_chunks": _chunks.size(),
		"tier_0_distant": tier_counts[0],
		"tier_1_far": tier_counts[1],
		"tier_2_mid": tier_counts[2],
		"tier_3_near": tier_counts[3],
		"total_plants": total_plants,
		"total_creatures": total_creatures,
		"rebuild_queue_size": _rebuild_queue.size(),
	}
