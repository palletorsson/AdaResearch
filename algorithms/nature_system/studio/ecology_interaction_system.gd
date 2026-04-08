# EcologyInteractionSystem.gd — Real-time ecological rules between organisms
#
# Handles continuous interactions that happen every tick (not generational).
# Pollination, predation, symbiosis, decomposition, competition — all driven
# by existing DNA genes so no new data is needed.
#
# Runs alongside EvolutionSystem: evolution handles generational cycles,
# ecology handles moment-to-moment interactions.
#
# Usage:
#   var ecology := EcologyInteractionSystem.new()
#   ecology.process_interactions(spawner, delta)  # call each frame or tick

class_name EcologyInteractionSystem
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Radius for pollination interactions (creature near flower).
var pollination_radius: float = 5.0

## Radius for symbiosis (tree + fungus mutual benefit).
var symbiosis_radius: float = 3.0

## Radius for predation (aggressive creature near passive creature).
var predation_radius: float = 4.0

## Radius for competition (same-kingdom crowding).
var competition_radius: float = 1.5

## Radius for decomposition (fungus near dead/low-energy organisms).
var decomposition_radius: float = 3.0

## Energy threshold below which an organism is considered "dying".
var dying_threshold: float = 0.1

## How often to run interaction checks (seconds). Process accumulates delta.
var tick_interval: float = 0.5

## Enable debug output.
var debug: bool = false


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired when a notable ecological event happens.
signal ecology_event(event_type: String, data: Dictionary)


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## Timer accumulator.
var _tick_timer: float = 0.0

## Stats from the last tick.
var _last_stats: Dictionary = {}


# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════

## Call each frame. Accumulates time and runs interactions at tick_interval.
func process(spawner: CritterSpawner, delta: float) -> void:
	_tick_timer += delta
	if _tick_timer < tick_interval:
		return
	_tick_timer -= tick_interval

	process_interactions(spawner, tick_interval)


## Run all ecological interactions for one tick.
func process_interactions(spawner: CritterSpawner, delta: float) -> Dictionary:
	var population: Array[CritterEntity] = spawner.get_active_critters()
	if population.size() < 2:
		return {}

	# Classify population by kingdom for efficient lookups
	var trees: Array[CritterEntity] = []
	var creatures: Array[CritterEntity] = []
	var flowers: Array[CritterEntity] = []
	var fungi: Array[CritterEntity] = []

	for entity in population:
		if not is_instance_valid(entity) or not entity.dna:
			continue
		match entity.get_kingdom():
			0: trees.append(entity)
			1: creatures.append(entity)
			2: flowers.append(entity)
			3: fungi.append(entity)

	var stats: Dictionary = {
		"pollination_events": 0,
		"symbiosis_pairs": 0,
		"predation_events": 0,
		"competition_pairs": 0,
		"decomposition_events": 0,
	}

	# Run each interaction type
	stats["pollination_events"] = _process_pollination(creatures, flowers, delta)
	stats["symbiosis_pairs"] = _process_symbiosis(trees, fungi, delta)
	stats["predation_events"] = _process_predation(creatures, spawner, delta)
	stats["competition_pairs"] = _process_competition(population, delta)
	stats["decomposition_events"] = _process_decomposition(fungi, population, delta)

	_last_stats = stats
	return stats


## Get stats from the last tick.
func get_last_stats() -> Dictionary:
	return _last_stats


# ═══════════════════════════════════════════════════════════════
# POLLINATION — Creatures visiting flowers
# ═══════════════════════════════════════════════════════════════

## Mobile creatures near flowers boost flower energy.
## High-curiosity creatures may trigger cross-pollination.
func _process_pollination(
	creatures: Array[CritterEntity],
	flowers: Array[CritterEntity],
	delta: float
) -> int:
	var events: int = 0

	for creature in creatures:
		if not is_instance_valid(creature) or creature.dna.mobility < 0.3:
			continue

		for flower in flowers:
			if not is_instance_valid(flower):
				continue

			var attract_range: float = flower.dna.scent_strength * pollination_radius
			var dist: float = creature.global_position.distance_to(flower.global_position)
			if dist > attract_range:
				continue

			# Pollinator visits flower — boost flower energy
			var energy_boost: float = flower.dna.nectar_quality * 0.02 * delta
			flower.restore_energy(energy_boost)

			# Creature gets a small energy reward too (nectar)
			creature.restore_energy(energy_boost * 0.5)

			events += 1

			# Cross-pollination: high curiosity → chance to create new flower DNA
			# (This is tracked but actual spawning is left to EvolutionSystem)
			if creature.dna.curiosity > 0.7 and flowers.size() >= 2:
				ecology_event.emit("cross_pollination", {
					"pollinator": creature,
					"flower": flower,
				})

	return events


# ═══════════════════════════════════════════════════════════════
# SYMBIOSIS — Trees and fungi (mycorrhizal network)
# ═══════════════════════════════════════════════════════════════

## Trees and fungi near each other mutually boost efficiency.
func _process_symbiosis(
	trees: Array[CritterEntity],
	fungi: Array[CritterEntity],
	delta: float
) -> int:
	var pairs: int = 0

	for tree in trees:
		if not is_instance_valid(tree):
			continue

		for fungus in fungi:
			if not is_instance_valid(fungus):
				continue

			var dist: float = tree.global_position.distance_to(fungus.global_position)
			if dist > symbiosis_radius:
				continue

			# Mutual benefit — both gain energy proportional to efficiency
			var tree_boost: float = tree.dna.efficiency * 0.01 * delta
			var fungus_boost: float = fungus.dna.efficiency * 0.01 * delta

			tree.restore_energy(tree_boost)
			fungus.restore_energy(fungus_boost)

			pairs += 1

	return pairs


# ═══════════════════════════════════════════════════════════════
# PREDATION — Aggressive creatures attack passive ones
# ═══════════════════════════════════════════════════════════════

## Creatures with high aggression attack lower-aggression creatures in range.
func _process_predation(
	creatures: Array[CritterEntity],
	spawner: CritterSpawner,
	delta: float
) -> int:
	var events: int = 0

	for predator in creatures:
		if not is_instance_valid(predator) or predator.dna.aggression < 0.5:
			continue

		for prey in creatures:
			if not is_instance_valid(prey) or prey == predator:
				continue
			if prey.dna.aggression >= predator.dna.aggression:
				continue

			var dist: float = predator.global_position.distance_to(prey.global_position)
			if dist > predation_radius:
				continue

			# Attack — predator gains energy, prey loses energy
			var attack_power: float = predator.dna.aggression * 5.0 * delta
			var defense: float = prey.dna.mobility * 3.0 * delta  # Fast prey can dodge

			var net_damage: float = maxf(attack_power - defense, 0.0)
			prey.consume_energy(net_damage)
			predator.restore_energy(net_damage * 0.5)  # Energy transfer is lossy

			events += 1

			# If prey energy hits zero, it dies
			if prey.get_energy_ratio() <= 0.0:
				ecology_event.emit("predation_kill", {
					"predator": predator,
					"prey": prey,
				})
				spawner.despawn(prey)

	return events


# ═══════════════════════════════════════════════════════════════
# COMPETITION — Same-kingdom crowding
# ═══════════════════════════════════════════════════════════════

## Same-kingdom entities too close together compete for resources.
func _process_competition(
	population: Array[CritterEntity],
	delta: float
) -> int:
	var pairs: int = 0

	for i in population.size():
		var a: CritterEntity = population[i]
		if not is_instance_valid(a) or not a.dna:
			continue

		for j in range(i + 1, population.size()):
			var b: CritterEntity = population[j]
			if not is_instance_valid(b) or not b.dna:
				continue

			# Only same-kingdom competition
			if a.get_kingdom() != b.get_kingdom():
				continue

			var dist: float = a.global_position.distance_to(b.global_position)
			if dist > competition_radius:
				continue

			# Both lose energy — less efficient organisms lose more
			var a_loss: float = (1.0 - a.dna.efficiency) * 0.005 * delta
			var b_loss: float = (1.0 - b.dna.efficiency) * 0.005 * delta
			a.consume_energy(a_loss)
			b.consume_energy(b_loss)

			pairs += 1

	return pairs


# ═══════════════════════════════════════════════════════════════
# DECOMPOSITION — Fungi recycle dying organisms
# ═══════════════════════════════════════════════════════════════

## Fungi near low-energy organisms restore nearby plant energy.
func _process_decomposition(
	fungi: Array[CritterEntity],
	population: Array[CritterEntity],
	delta: float
) -> int:
	var events: int = 0

	for fungus in fungi:
		if not is_instance_valid(fungus):
			continue

		for organism in population:
			if not is_instance_valid(organism) or organism == fungus:
				continue
			if organism.get_energy_ratio() > dying_threshold:
				continue

			var dist: float = fungus.global_position.distance_to(organism.global_position)
			if dist > decomposition_radius:
				continue

			# Fungus gains energy from decomposing
			fungus.restore_energy(0.03 * delta)

			# Nearby plants (trees, flowers) get a soil fertility boost
			for other in population:
				if not is_instance_valid(other) or other == fungus or other == organism:
					continue
				if other.get_kingdom() != 0 and other.get_kingdom() != 2:
					continue  # Only trees and flowers benefit

				var plant_dist: float = fungus.global_position.distance_to(other.global_position)
				if plant_dist < decomposition_radius:
					other.restore_energy(0.01 * delta)

			events += 1

	return events
