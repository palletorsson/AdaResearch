# GroundSpawner.gd — Procedural ecosystem generation from ground presence
#
# The feedback loop: organisms mark the ground → ground presence accumulates →
# when presence is high enough, NEW organisms spontaneously grow from it.
# This is how ecosystems self-organize — the ground becomes fertile.
#
# Rules:
#   - High tree presence (R) → seeds new trees nearby (forest spread)
#   - High flower presence (B) → pollinates new flowers (meadow formation)
#   - High fungus presence (A) → spawns new fungi (colony expansion)
#   - Creature trails (G) → DON'T spawn creatures (they reproduce sexually)
#   - Mixed presence → chance of hybrid organisms
#   - Presence decays, so barren ground won't spawn anything
#
# This runs alongside EvolutionSystem (sexual reproduction) and
# EcologyInteractionSystem (real-time interactions). Ground spawning is
# the third pillar: asexual propagation from environmental conditions.
#
# Usage:
#   var gs := GroundSpawner.new()
#   gs.spawner = my_spawner
#   gs.presence = my_presence_grid
#   gs.process(delta)  # call each frame

class_name GroundSpawner
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## The spawner to create new organisms.
var spawner: CritterSpawner = null

## The presence grid to read ground conditions from.
var presence = null  # PresenceGrid instance

## How often to check for spawning opportunities (seconds).
var check_interval: float = 5.0

## Minimum presence to trigger a spawn (per channel).
var spawn_threshold: float = 0.6

## Maximum organisms the ground can spawn per check.
var max_spawns_per_check: int = 3

## Probability of spawning when presence exceeds threshold.
var spawn_chance: float = 0.3

## Minimum distance from existing organisms (avoid overcrowding).
var min_spacing: float = 3.0

## Maximum population from ground spawning (prevents runaway growth).
## This is separate from EvolutionSystem's population cap.
var max_ground_population: int = 30

## Terrain size (for sampling random positions).
var terrain_size: float = 50.0

## How many random positions to sample per check.
var sample_count: int = 20

## Enable debug output.
var debug: bool = false


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired when the ground spontaneously grows a new organism.
signal ground_birth(entity: CritterEntity, kingdom: int, position: Vector3)


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _timer: float = 0.0
var _ground_spawned_count: int = 0
var _rng: RandomNumberGenerator = null


# ═══════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════

func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════

func process(delta: float) -> void:
	if not spawner or not presence:
		return

	_timer += delta
	if _timer < check_interval:
		return
	_timer -= check_interval

	if _ground_spawned_count >= max_ground_population:
		return
	if spawner.get_population_count() >= spawner.max_population:
		return

	_check_and_spawn()


# ═══════════════════════════════════════════════════════════════
# SPAWN LOGIC
# ═══════════════════════════════════════════════════════════════

func _check_and_spawn() -> void:
	var spawned: int = 0
	var half: float = terrain_size * 0.5

	# Sample random positions on the terrain
	for _i in sample_count:
		if spawned >= max_spawns_per_check:
			break

		var pos := Vector3(
			_rng.randf_range(-half, half),
			0.0,
			_rng.randf_range(-half, half)
		)

		# Read ground presence at this position
		var p: Color = presence.get_presence(pos)

		# Find the strongest kingdom presence
		var kingdom: int = -1
		var strength: float = spawn_threshold

		# Trees (R channel) — forest spread
		if p.r > strength:
			kingdom = 0
			strength = p.r

		# Flowers (B channel) — meadow formation
		if p.b > strength:
			kingdom = 2
			strength = p.b

		# Fungi (A channel) — colony expansion
		if p.a > strength:
			kingdom = 3
			strength = p.a

		# Creatures (G channel) — don't spontaneously generate
		# Creatures reproduce sexually via EvolutionSystem

		if kingdom < 0:
			continue

		# Roll the dice
		if _rng.randf() > spawn_chance:
			continue

		# Check spacing — don't spawn too close to existing organisms
		var nearby: Array[CritterEntity] = spawner.get_within_radius(pos, min_spacing)
		if not nearby.is_empty():
			continue

		# Check for mixed presence → hybrid chance
		var mixed_count: int = 0
		if p.r > 0.3: mixed_count += 1
		if p.b > 0.3: mixed_count += 1
		if p.a > 0.3: mixed_count += 1
		if p.g > 0.3: mixed_count += 1

		var dna: CritterDNA
		if mixed_count >= 2 and _rng.randf() < 0.15:
			# Mixed ground → chance of hybrid
			dna = _create_hybrid_dna(p)
		else:
			# Pure ground → kingdom-specific organism
			dna = _create_ground_dna(kingdom, strength)

		# Spawn it
		var entity: CritterEntity = spawner.spawn(dna, pos)
		if entity:
			spawned += 1
			_ground_spawned_count += 1
			ground_birth.emit(entity, kingdom, pos)

			if debug:
				print("[GroundSpawner] Sprouted %s at %s (presence=%.2f)" % [
					dna.get_kingdom_name(), str(pos), strength
				])


# ═══════════════════════════════════════════════════════════════
# DNA GENERATION — organisms born from the ground
# ═══════════════════════════════════════════════════════════════

## Create DNA for an organism that grew from the ground.
## Influenced by surrounding presence — inherits the soil's character.
func _create_ground_dna(kingdom: int, presence_strength: float) -> CritterDNA:
	var dna: CritterDNA = CritterDNA.random_kingdom(kingdom, _rng.randi())

	# Ground-born organisms are always rooted (low mobility)
	if kingdom != 1:  # Not creature
		dna.mobility = _rng.randf_range(0.0, 0.05)

	# Smaller than bred organisms (they just sprouted)
	dna.scale *= _rng.randf_range(0.4, 0.8)

	# Higher scent = mark the ground more strongly (propagate presence)
	dna.scent_strength = _rng.randf_range(0.4, 0.9)

	# Fertility influenced by presence strength
	dna.fertility = presence_strength * _rng.randf_range(0.5, 1.0)

	# Generation 0 (first generation from ground)
	dna.generation = 0

	return dna


## Create a hybrid DNA from mixed ground presence.
func _create_hybrid_dna(p: Color) -> CritterDNA:
	# Find the two strongest kingdoms
	var vals: Array[float] = [p.r, 0.0, p.b, p.a]  # Skip creature (G)
	var best_k: int = 0
	var second_k: int = 2
	var best_v: float = 0.0
	var second_v: float = 0.0

	for k in [0, 2, 3]:
		if vals[k] > best_v:
			second_k = best_k
			second_v = best_v
			best_k = k
			best_v = vals[k]
		elif vals[k] > second_v:
			second_k = k
			second_v = vals[k]

	# body_type between the two kingdoms
	var blend: float = second_v / maxf(best_v + second_v, 0.01)
	var body_type: float = float(best_k) + (float(second_k) - float(best_k)) * blend

	var dna: CritterDNA = CritterDNA.random(_rng.randi())
	dna.body_type = clampf(body_type, 0.0, 4.0)
	dna.mobility = _rng.randf_range(0.0, 0.05)
	dna.scale *= _rng.randf_range(0.3, 0.7)  # Small — ground hybrids start tiny
	dna.scent_strength = _rng.randf_range(0.5, 0.95)
	dna.generation = 0

	return dna


# ═══════════════════════════════════════════════════════════════
# QUERIES
# ═══════════════════════════════════════════════════════════════

## How many organisms have been spawned from the ground.
func get_ground_spawned_count() -> int:
	return _ground_spawned_count


## Reset the counter (e.g., when resetting the ecosystem).
func reset() -> void:
	_ground_spawned_count = 0
	_timer = 0.0
