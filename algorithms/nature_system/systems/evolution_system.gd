# EvolutionSystem.gd — Population management and evolutionary dynamics
#
# Manages generational cycles for the Nature System. Each tick:
#   1. Evaluate fitness of all critters
#   2. Select parents (tournament selection)
#   3. Reproduce (crossover + mutation)
#   4. Cull the weakest to maintain population bounds
#   5. Spawn offspring via CritterSpawner
#
# Fitness is NOT hardcoded — it's a pluggable callback. Different
# environments can define different selection pressures. The default
# fitness rewards survival, energy efficiency, and player engagement.
#
# Cross-kingdom breeding is allowed but rare — controlled by the
# CROSS_KINGDOM_RATE constant. When two critters from different kingdoms
# breed, the child's body_type is a blend, producing a hybrid.
#
# Usage:
#   var evo := EvolutionSystem.new()
#   evo.spawner = my_spawner
#   evo.start(1.0 / 30.0)  # Evolve every 30 seconds
#
#   # Custom fitness:
#   evo.fitness_function = func(entity: CritterEntity) -> float:
#       return entity.get_energy_ratio() * 0.5 + custom_score(entity) * 0.5

class_name EvolutionSystem
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired after each evolution cycle.
signal generation_complete(gen_number: int, stats: Dictionary)

## Fired when a new critter is born.
signal critter_born(entity: CritterEntity, parent_a: CritterEntity, parent_b: CritterEntity)

## Fired when a critter dies (culled by evolution).
signal critter_died(entity: CritterEntity, cause: String)

## Fired when cross-kingdom breeding occurs.
signal cross_kingdom_breed(parent_a: CritterEntity, parent_b: CritterEntity, child_kingdom: String)


# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## The spawner that manages critter instantiation.
var spawner: CritterSpawner = null

## Optional transmutation manager — bonded critters get fitness bonus.
var transmutation_manager: TransmutationManager = null

## Pluggable fitness function. Takes CritterEntity, returns float (0-1).
## If null, uses default_fitness().
var fitness_function: Callable = Callable()

## How many generations have elapsed.
var current_generation: int = 0

## Target population size. Evolution tries to maintain this count.
var target_population: int = 40

## Minimum population — below this, asexual reproduction kicks in.
var min_population: int = 10

## Maximum allowed — hard cap, excess are culled.
var max_population: int = 80

## Fraction of population that reproduces each cycle (top N%).
var reproduction_fraction: float = 0.5

## Fraction of population culled each cycle (bottom N%).
var cull_fraction: float = 0.2

## Base mutation rate per gene per generation.
var mutation_rate: float = 0.05

## Mutation strength (how far a gene moves when mutated).
var mutation_strength: float = 0.1

## Probability that two critters from different kingdoms can breed.
var cross_kingdom_rate: float = 0.05

## Tournament selection size (larger = more selective pressure).
var tournament_size: int = 3

## Spatial radius for finding mates (critters must be "near" each other).
var mating_radius: float = 10.0

## Enable asexual reproduction when population is critically low.
var allow_asexual: bool = true

## Asexual reproduction mutation rate (higher than sexual to maintain diversity).
var asexual_mutation_rate: float = 0.12

## Enable debug output.
var debug: bool = false

# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## Cached fitness scores from last evaluation. Key: instance_id, Value: float.
var _fitness_cache: Dictionary = {}

## Running stats for the current generation.
var _generation_stats: Dictionary = {}

## History of generation stats (for dashboard / trend graphs).
var _generation_history: Array[Dictionary] = []

## Optional mating filter — if set, overrides kingdom/radius checks.
## Callable(parent_a: CritterEntity, parent_b: CritterEntity) -> bool
var custom_mating_filter: Callable = Callable()

## Is the system currently running automatic cycles?
var _running: bool = false

## Timer accumulator for auto-cycling.
var _cycle_timer: float = 0.0

## Time between evolution cycles (seconds).
var _cycle_interval: float = 30.0


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

## Start automatic evolution cycles at the given interval.
func start(interval: float = 30.0) -> void:
	_cycle_interval = maxf(interval, 1.0)
	_running = true
	_cycle_timer = 0.0

	if debug:
		print("[EvolutionSystem] Started — interval: %.1fs, target pop: %d" % [
			_cycle_interval, target_population
		])


## Stop automatic cycling (can still call evolve_step() manually).
func stop() -> void:
	_running = false


## Call each frame (or each physics tick) to advance the timer.
## When the interval elapses, one evolution step runs automatically.
func process(delta: float) -> void:
	if not _running:
		return

	_cycle_timer += delta
	if _cycle_timer >= _cycle_interval:
		_cycle_timer -= _cycle_interval
		evolve_step()


# ═══════════════════════════════════════════════════════════════
# EVOLUTION STEP — The main cycle
# ═══════════════════════════════════════════════════════════════

## Run one complete evolution cycle:
##   evaluate → select → reproduce → cull → stats
func evolve_step() -> void:
	if not spawner:
		push_error("[EvolutionSystem] Cannot evolve: no spawner")
		return

	current_generation += 1
	var population: Array[CritterEntity] = spawner.get_active_critters()

	if population.is_empty():
		if debug:
			print("[EvolutionSystem] Gen %d — empty population, skipping" % current_generation)
		return

	# 1. Evaluate fitness
	_evaluate_fitness(population)

	# 2. Sort by fitness (descending)
	var ranked: Array[CritterEntity] = _rank_by_fitness(population)

	# 3. Reproduce — top fraction breeds
	var offspring_count: int = _reproduce(ranked)

	# 4. Cull — remove bottom fraction if over target
	var culled_count: int = _cull(ranked)

	# 5. Emergency asexual reproduction if below minimum
	var asexual_count: int = 0
	if allow_asexual and spawner.get_population_count() < min_population:
		asexual_count = _asexual_rescue(ranked)

	# 6. Stats
	_generation_stats = _build_stats(ranked, offspring_count, culled_count, asexual_count)
	_generation_history.append(_generation_stats)
	if _generation_history.size() > 500:
		_generation_history = _generation_history.slice(-250)
	generation_complete.emit(current_generation, _generation_stats)

	if debug:
		print("[EvolutionSystem] Gen %d — pop: %d, born: %d, culled: %d, asexual: %d, avg_fit: %.3f" % [
			current_generation,
			spawner.get_population_count(),
			offspring_count,
			culled_count,
			asexual_count,
			_generation_stats.get("avg_fitness", 0.0),
		])


# ═══════════════════════════════════════════════════════════════
# FITNESS EVALUATION
# ═══════════════════════════════════════════════════════════════

## Evaluate fitness for all critters and cache the results.
func _evaluate_fitness(population: Array[CritterEntity]) -> void:
	_fitness_cache.clear()

	for entity in population:
		if not is_instance_valid(entity):
			continue

		var fitness: float = 0.0

		if fitness_function.is_valid():
			fitness = fitness_function.call(entity) as float
		else:
			fitness = _default_fitness(entity)

		_fitness_cache[entity.get_instance_id()] = fitness


## Default fitness function — multi-objective:
##   energy efficiency + age (survival) + bond level + kingdom diversity bonus
func _default_fitness(entity: CritterEntity) -> float:
	if not entity.dna:
		return 0.0

	var score: float = 0.0

	# Energy efficiency (how well it manages resources) — 30%
	score += entity.get_energy_ratio() * 0.30

	# Survival (older = proven viable) — 20%
	var age_score: float = clampf(entity.get_age() / 100.0, 0.0, 1.0)
	score += age_score * 0.20

	# Fertility gene (reproductive potential) — 15%
	score += entity.dna.fertility * 0.15

	# Player bond (Haraway — critters that engage with player are more "fit") — 20%
	var bond: float = entity.get_bond_level()
	if transmutation_manager:
		bond = maxf(bond, transmutation_manager.get_bond_level(entity))
	score += bond * 0.20

	# Efficiency gene — 15%
	score += clampf(entity.dna.efficiency / 2.0, 0.0, 1.0) * 0.15

	return clampf(score, 0.0, 1.0)


## Get the cached fitness for an entity.
func get_fitness(entity: CritterEntity) -> float:
	if not entity:
		return 0.0
	return _fitness_cache.get(entity.get_instance_id(), 0.0) as float


# ═══════════════════════════════════════════════════════════════
# SELECTION
# ═══════════════════════════════════════════════════════════════

## Rank population by fitness (descending).
func _rank_by_fitness(population: Array[CritterEntity]) -> Array[CritterEntity]:
	var scored: Array[Dictionary] = []
	for entity in population:
		if is_instance_valid(entity):
			scored.append({
				"entity": entity,
				"fitness": _fitness_cache.get(entity.get_instance_id(), 0.0),
			})

	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["fitness"] as float) > (b["fitness"] as float)
	)

	var ranked: Array[CritterEntity] = []
	for item in scored:
		ranked.append(item["entity"] as CritterEntity)
	return ranked


## Tournament selection — pick the best from a random subset.
func _tournament_select(ranked: Array[CritterEntity], rng: RandomNumberGenerator) -> CritterEntity:
	if ranked.is_empty():
		return null

	var best: CritterEntity = null
	var best_fitness: float = -1.0

	for _i in tournament_size:
		var idx: int = rng.randi_range(0, ranked.size() - 1)
		var candidate: CritterEntity = ranked[idx]
		var fit: float = _fitness_cache.get(candidate.get_instance_id(), 0.0) as float
		if fit > best_fitness:
			best_fitness = fit
			best = candidate

	return best


# ═══════════════════════════════════════════════════════════════
# REPRODUCTION
# ═══════════════════════════════════════════════════════════════

## Reproduce from the top fraction of the population.
## Returns the number of offspring spawned.
func _reproduce(ranked: Array[CritterEntity]) -> int:
	if ranked.size() < 2:
		return 0

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# How many offspring to create this cycle
	var current_pop: int = spawner.get_population_count()
	var desired_births: int = maxi(roundi(float(target_population - current_pop) * 0.5), 0)
	desired_births = mini(desired_births, roundi(float(ranked.size()) * reproduction_fraction))

	if desired_births <= 0:
		return 0

	var born: int = 0

	for _i in desired_births:
		# Select two parents
		var parent_a: CritterEntity = _tournament_select(ranked, rng)
		var parent_b: CritterEntity = _tournament_select(ranked, rng)

		if not parent_a or not parent_b:
			continue

		# Avoid self-breeding
		if parent_a == parent_b:
			parent_b = _tournament_select(ranked, rng)
			if parent_a == parent_b:
				continue

		# Cross-kingdom check
		var same_kingdom: bool = parent_a.get_kingdom() == parent_b.get_kingdom()
		if not same_kingdom and rng.randf() > cross_kingdom_rate:
			# Different kingdoms and didn't pass the cross-kingdom check — skip
			continue

		# Spatial check — must be within mating radius
		if parent_a.global_position.distance_to(parent_b.global_position) > mating_radius:
			continue

		# Breed
		var child_dna: CritterDNA = parent_a.breed_with(parent_b)
		if not child_dna:
			continue

		# Apply additional mutation
		CritterDNA.mutate(child_dna, mutation_rate, mutation_strength)

		# Spawn between parents
		var spawn_pos: Vector3 = (parent_a.global_position + parent_b.global_position) * 0.5
		spawn_pos += Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))

		var child: CritterEntity = spawner.spawn(child_dna, spawn_pos)
		if child:
			born += 1
			critter_born.emit(child, parent_a, parent_b)

			if not same_kingdom:
				cross_kingdom_breed.emit(parent_a, parent_b, child.get_kingdom_name())

				if debug:
					print("[EvolutionSystem] Cross-kingdom breed! %s(%s) x %s(%s) → %s" % [
						parent_a.name, parent_a.get_kingdom_name(),
						parent_b.name, parent_b.get_kingdom_name(),
						child.get_kingdom_name()
					])
		else:
			break  # Spawner at capacity

	return born


## Emergency asexual reproduction when population is critically low.
func _asexual_rescue(ranked: Array[CritterEntity]) -> int:
	if ranked.is_empty():
		return 0

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var needed: int = min_population - spawner.get_population_count()
	if needed <= 0:
		return 0

	var born: int = 0

	for _i in needed:
		# Pick a random survivor (biased toward the fittest)
		var parent_idx: int = rng.randi_range(0, mini(ranked.size() - 1, 4))
		var parent: CritterEntity = ranked[parent_idx]
		if not is_instance_valid(parent):
			continue

		var child_dna: CritterDNA = parent.reproduce_asexual(asexual_mutation_rate)
		if not child_dna:
			continue

		var spawn_pos: Vector3 = parent.global_position + Vector3(
			rng.randf_range(-2.0, 2.0), 0.0, rng.randf_range(-2.0, 2.0)
		)

		var child: CritterEntity = spawner.spawn(child_dna, spawn_pos)
		if child:
			born += 1
			critter_born.emit(child, parent, null)

			if debug:
				print("[EvolutionSystem] Asexual rescue: %s → %s" % [
					parent.name, child.name
				])
		else:
			break

	return born


# ═══════════════════════════════════════════════════════════════
# CULLING — Population control
# ═══════════════════════════════════════════════════════════════

## Remove the weakest critters to maintain population bounds.
## Returns the number culled.
func _cull(ranked: Array[CritterEntity]) -> int:
	var current_pop: int = spawner.get_population_count()
	if current_pop <= target_population:
		return 0

	# How many to remove
	var excess: int = current_pop - target_population
	var max_cull: int = roundi(float(ranked.size()) * cull_fraction)
	var cull_count: int = mini(excess, max_cull)

	if cull_count <= 0:
		return 0

	# Cull from the bottom of the ranked list (weakest fitness)
	var culled: int = 0
	var idx: int = ranked.size() - 1

	while culled < cull_count and idx >= 0:
		var entity: CritterEntity = ranked[idx]
		if not is_instance_valid(entity):
			idx -= 1
			continue

		# Don't cull critters the player has bonded with
		if entity.get_bond_level() > 0.3:
			idx -= 1
			continue

		# Don't cull transmuted critters
		if transmutation_manager and transmutation_manager.is_transmuted(entity):
			idx -= 1
			continue

		critter_died.emit(entity, "evolution_cull")
		spawner.despawn(entity)
		culled += 1
		idx -= 1

	return culled


# ═══════════════════════════════════════════════════════════════
# STATS
# ═══════════════════════════════════════════════════════════════

## Build generation statistics.
func _build_stats(
	ranked: Array[CritterEntity],
	births: int,
	deaths: int,
	asexual: int
) -> Dictionary:
	if ranked.is_empty():
		return {
			"generation": current_generation,
			"population": 0,
			"births": births,
			"deaths": deaths,
			"asexual_births": asexual,
			"avg_fitness": 0.0,
			"max_fitness": 0.0,
			"min_fitness": 0.0,
			"kingdom_counts": {},
			"avg_generation": 0.0,
			"avg_hybridity": 0.0,
		}

	var total_fitness: float = 0.0
	var max_fitness: float = 0.0
	var min_fitness: float = INF
	var total_gen: float = 0.0
	var total_hybrid: float = 0.0
	var kingdom_counts: Dictionary = {"tree": 0, "creature": 0, "flower": 0, "fungus": 0, "hybrid": 0}
	var valid_count: int = 0

	for entity in ranked:
		if not is_instance_valid(entity):
			continue
		valid_count += 1

		var fit: float = _fitness_cache.get(entity.get_instance_id(), 0.0) as float
		total_fitness += fit
		max_fitness = maxf(max_fitness, fit)
		min_fitness = minf(min_fitness, fit)

		if entity.dna:
			total_gen += float(entity.dna.generation)
			total_hybrid += entity.get_hybridity()

			var kn: String = entity.get_kingdom_name()
			if kn in kingdom_counts:
				kingdom_counts[kn] = (kingdom_counts[kn] as int) + 1

	var n: float = maxf(float(valid_count), 1.0)

	return {
		"generation": current_generation,
		"population": valid_count,
		"births": births,
		"deaths": deaths,
		"asexual_births": asexual,
		"avg_fitness": total_fitness / n,
		"max_fitness": max_fitness,
		"min_fitness": min_fitness if min_fitness < INF else 0.0,
		"kingdom_counts": kingdom_counts,
		"avg_generation": total_gen / n,
		"avg_hybridity": total_hybrid / n,
	}


## Get the stats from the last evolution cycle.
func get_last_stats() -> Dictionary:
	return _generation_stats


## Get stats history for all recorded generations (for trend graphs).
func get_generation_history() -> Array[Dictionary]:
	return _generation_history


# ═══════════════════════════════════════════════════════════════
# QUERIES
# ═══════════════════════════════════════════════════════════════

## Get the fittest N critters from the last evaluation.
func get_fittest(count: int = 5) -> Array[CritterEntity]:
	if not spawner:
		return []

	var population: Array[CritterEntity] = spawner.get_active_critters()
	if _fitness_cache.is_empty():
		_evaluate_fitness(population)

	var ranked: Array[CritterEntity] = _rank_by_fitness(population)
	return ranked.slice(0, mini(count, ranked.size()))


## Get the genetic diversity of the current population (0 = clones, 1 = maximally diverse).
func get_diversity() -> float:
	if not spawner:
		return 0.0

	var population: Array[CritterEntity] = spawner.get_active_critters()
	if population.size() < 2:
		return 0.0

	# Sample pairwise distances
	var total_dist: float = 0.0
	var pair_count: int = 0
	var max_pairs: int = 100  # Cap for performance

	for i in population.size():
		for j in range(i + 1, population.size()):
			if pair_count >= max_pairs:
				break
			if is_instance_valid(population[i]) and is_instance_valid(population[j]):
				if population[i].dna and population[j].dna:
					total_dist += CritterDNA.distance(population[i].dna, population[j].dna)
					pair_count += 1
		if pair_count >= max_pairs:
			break

	if pair_count == 0:
		return 0.0

	return total_dist / float(pair_count)


## Check if population is viable (enough critters to sustain evolution).
func is_population_viable() -> bool:
	if not spawner:
		return false
	return spawner.get_population_count() >= min_population
