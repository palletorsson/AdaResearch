# TransmutationManager.gd — Bond tracking + ability granting (the Haraway mechanic)
#
# "Nothing is purely enemy. Nothing is purely medicine. Everything is
#  potential under restraint — and the restraint can change."
#
# Tracks the player's relationship with each critter. As the bond deepens
# through observation, feeding, proximity, and survived encounters, the
# critter's latent potential gradually unlocks. At the transmutation
# threshold, both player and critter are transformed.
#
# Each critter carries a latent_ability gene (0-5) that maps to one of
# six ability categories. The specific ability within that category is
# further shaped by kingdom and other genes.
#
# Usage:
#   var tm := TransmutationManager.new()
#   tm.on_interaction(critter_entity, "observe")
#   tm.on_interaction(critter_entity, "feed")
#   # ... bond grows ...
#   # When bond >= threshold → transmutation_triggered signal fires

class_name TransmutationManager
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired when a bond level changes.
signal bond_updated(entity: CritterEntity, old_level: float, new_level: float)

## Fired when a critter reaches transmutation threshold.
signal transmutation_triggered(entity: CritterEntity, ability: Dictionary)

## Fired when the player gains a new ability from transmutation.
signal ability_granted(ability_name: String, ability_data: Dictionary)

## Fired when a ritual step is completed.
signal ritual_progress(entity: CritterEntity, ritual_name: String, progress: float)


# ─────────────────────────────────────────────────────────────
#  Constants — Interaction deltas
# ─────────────────────────────────────────────────────────────

## Bond change per interaction type. Positive = trust, negative = fear.
const INTERACTION_DELTAS: Dictionary = {
	"observe": 0.02,         # Slow and safe — patience
	"feed": 0.10,            # Generous — builds trust
	"touch": 0.05,           # Risky — shows courage
	"proximity": 0.005,      # Passive — just being near
	"survive": 0.15,         # Near-death shared experience
	"protect": 0.12,         # Defend critter from threat
	"cross_pollinate": 0.08, # Breeding interaction
	"enter_space": 0.06,     # Enter critter's territory
	"fight": -0.30,          # Violence destroys trust
	"flee": -0.05,           # Running away — mild rejection
	"harvest": -0.20,        # Taking from critter without giving
}

## Bond level required for transmutation (can be modified by affinity gene).
const BASE_TRANSMUTATION_THRESHOLD: float = 0.95

## Bond decay rate per second when not interacting (very slow).
const BOND_DECAY_RATE: float = 0.001

## Maximum number of tracked bonds (performance limit).
const MAX_TRACKED_BONDS: int = 200


# ─────────────────────────────────────────────────────────────
#  Ability categories (mapped from latent_ability gene 0-5)
# ─────────────────────────────────────────────────────────────

## Ability categories. The latent_ability gene (0-5) selects one.
## Kingdom + other genes determine the specific variant.
const ABILITY_CATEGORIES: Array[Dictionary] = [
	{  # 0: VISION — see what was hidden
		"category": "vision",
		"variants": {
			"tree": {"name": "root_network_sense", "description": "See underground connections between trees"},
			"creature": {"name": "infrared_vision", "description": "See heat signatures through walls"},
			"flower": {"name": "pollen_sight", "description": "See Q-FEP energy field lines"},
			"fungus": {"name": "spore_vision", "description": "See mycelium networks and decay patterns"},
		},
	},
	{  # 1: PERCEPTION — hear/feel the world differently
		"category": "perception",
		"variants": {
			"tree": {"name": "wind_sense", "description": "Feel distant movement through air currents"},
			"creature": {"name": "echolocation", "description": "Navigate darkness with sound"},
			"flower": {"name": "scent_mapping", "description": "Map the world through chemical trails"},
			"fungus": {"name": "ground_sense", "description": "Feel vibrations through the earth"},
		},
	},
	{  # 2: MOBILITY — move in new ways
		"category": "mobility",
		"variants": {
			"tree": {"name": "root_travel", "description": "Fast-travel between bonded trees"},
			"creature": {"name": "gliding", "description": "Glide on air currents"},
			"flower": {"name": "pollen_drift", "description": "Float briefly on pollen clouds"},
			"fungus": {"name": "mycelium_slide", "description": "Rapid underground movement on mycelium"},
		},
	},
	{  # 3: DEFENSE — protection and resilience
		"category": "defense",
		"variants": {
			"tree": {"name": "bark_shield", "description": "Temporary bark armor grows on body"},
			"creature": {"name": "plasma_shield", "description": "Energy barrier from bonded plasma critter"},
			"flower": {"name": "thorn_garden", "description": "Defensive ring of thorns at your feet"},
			"fungus": {"name": "spore_cloud", "description": "Concealing cloud that confuses enemies"},
		},
	},
	{  # 4: HEALING — restoration and growth
		"category": "healing",
		"variants": {
			"tree": {"name": "photosynthesis", "description": "Slowly regenerate in sunlight"},
			"creature": {"name": "symbiont_repair", "description": "Bonded creature heals your wounds"},
			"flower": {"name": "nectar_regeneration", "description": "Rapid healing from flower nectar"},
			"fungus": {"name": "decompose_renew", "description": "Break down damage, regrow fresh"},
		},
	},
	{  # 5: COMMUNICATION — connect with other beings
		"category": "communication",
		"variants": {
			"tree": {"name": "wood_wide_web", "description": "Send messages through tree root network"},
			"creature": {"name": "hive_mind_view", "description": "See through bonded creature's eyes"},
			"flower": {"name": "pheromone_command", "description": "Attract or repel nearby creatures"},
			"fungus": {"name": "spore_network", "description": "Communicate through spore chemical signals"},
		},
	},
]


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## Bond data per critter instance ID.
## Key: int (instance_id), Value: Dictionary { level, history, last_interaction_time, ritual_progress }
var _bonds: Dictionary = {}

## Granted abilities. Key: ability_name, Value: ability_data Dictionary.
var _granted_abilities: Dictionary = {}

## Critters that have already been transmuted (prevent double-grant).
var _transmuted_ids: Dictionary = {}

## Enable debug output.
var debug: bool = false


# ═══════════════════════════════════════════════════════════════
# INTERACTION — The core gameplay loop
# ═══════════════════════════════════════════════════════════════

## Record a player interaction with a critter.
## This is the main entry point — call from VR interaction system.
func on_interaction(entity: CritterEntity, action: String) -> void:
	if not entity or not entity.dna:
		return

	var entity_id: int = entity.get_instance_id()

	# Get or create bond record
	var bond: Dictionary = _get_or_create_bond(entity_id)

	# Calculate delta
	var base_delta: float = INTERACTION_DELTAS.get(action, 0.0) as float
	if absf(base_delta) < 0.0001:
		if debug:
			push_warning("[TransmutationManager] Unknown action: %s" % action)
		return

	# Affinity gene modulates bonding speed (0.5x to 1.5x)
	var affinity_mult: float = 0.5 + entity.dna.affinity
	var final_delta: float = base_delta * affinity_mult

	# Volatility adds unpredictability (can increase OR decrease delta)
	if entity.dna.volatility > 0.1:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var volatility_jitter: float = rng.randf_range(-entity.dna.volatility * 0.3, entity.dna.volatility * 0.3)
		final_delta += volatility_jitter

	# Apply
	var old_level: float = bond["level"] as float
	var new_level: float = clampf(old_level + final_delta, 0.0, 1.0)
	bond["level"] = new_level
	bond["last_interaction_time"] = Time.get_ticks_msec()

	# Record in history
	var history: Array = bond["history"] as Array
	history.append({"action": action, "delta": final_delta, "time": Time.get_ticks_msec()})
	# Cap history size
	if history.size() > 50:
		history.pop_front()

	# Update the entity's visual bond level
	entity.set_bond_level(new_level)

	# Emit update
	bond_updated.emit(entity, old_level, new_level)

	# Check ritual progress
	_update_ritual_progress(entity, bond, action)

	# Check transmutation threshold
	var threshold: float = BASE_TRANSMUTATION_THRESHOLD - (entity.dna.affinity * 0.1)
	if new_level >= threshold and entity_id not in _transmuted_ids:
		_trigger_transmutation(entity)

	if debug:
		print("[TransmutationManager] %s '%s' → bond: %.3f (delta: %.3f, affinity: %.2f)" % [
			entity.name, action, new_level, final_delta, entity.dna.affinity
		])


## Process passive proximity bonding. Call each tick with nearby critters.
func on_proximity(entities: Array[CritterEntity], _delta_time: float) -> void:
	for entity in entities:
		if not entity or not entity.dna:
			continue
		on_interaction(entity, "proximity")


## Apply bond decay over time. Call periodically (e.g., every second).
func decay_bonds(delta_seconds: float) -> void:
	var decay: float = BOND_DECAY_RATE * delta_seconds

	for entity_id in _bonds:
		var bond: Dictionary = _bonds[entity_id] as Dictionary
		var level: float = bond["level"] as float
		if level > 0.0:
			bond["level"] = maxf(level - decay, 0.0)


# ═══════════════════════════════════════════════════════════════
# TRANSMUTATION — The moment of transformation
# ═══════════════════════════════════════════════════════════════

## Trigger transmutation for a critter that has reached the bond threshold.
func _trigger_transmutation(entity: CritterEntity) -> void:
	var entity_id: int = entity.get_instance_id()
	_transmuted_ids[entity_id] = true

	# Determine which ability this critter grants
	var ability: Dictionary = resolve_ability(entity.dna)

	# Grant the ability
	_granted_abilities[ability["name"]] = ability

	# Emit signals
	transmutation_triggered.emit(entity, ability)
	ability_granted.emit(ability["name"] as String, ability)

	if debug:
		print("[TransmutationManager] TRANSMUTATION! %s → grants '%s' (%s)" % [
			entity.name, ability["name"], ability["description"]
		])


## Determine which ability a critter's DNA would grant upon transmutation.
## Can be called without actually transmuting (for UI preview).
func resolve_ability(dna: CritterDNA) -> Dictionary:
	# latent_ability gene (0-5) selects the category
	var category_idx: int = clampi(roundi(dna.latent_ability), 0, 5)
	var category: Dictionary = ABILITY_CATEGORIES[category_idx]

	# Kingdom determines the specific variant
	var kingdom_name: String = dna.get_kingdom_name()
	var variants: Dictionary = category["variants"] as Dictionary

	if kingdom_name in variants:
		var variant: Dictionary = variants[kingdom_name] as Dictionary
		return {
			"name": variant["name"],
			"description": variant["description"],
			"category": category["category"],
			"kingdom": kingdom_name,
			"latent_ability": dna.latent_ability,
			"power": _calculate_ability_power(dna),
		}
	else:
		# Hybrid or unknown — pick the variant with strongest gene affinity
		var best_variant_name: String = "unknown_ability"
		var best_variant_desc: String = "A mysterious transformation"
		for kn in variants:
			best_variant_name = (variants[kn] as Dictionary)["name"] as String
			best_variant_desc = (variants[kn] as Dictionary)["description"] as String
			break  # Take first as fallback

		return {
			"name": best_variant_name,
			"description": best_variant_desc,
			"category": category["category"],
			"kingdom": kingdom_name,
			"latent_ability": dna.latent_ability,
			"power": _calculate_ability_power(dna),
		}


## Calculate how powerful a transmuted ability is (0-1).
## Influenced by generation depth, bond level, and gene expression.
func _calculate_ability_power(dna: CritterDNA) -> float:
	var base_power: float = 0.5

	# Older lineages grant stronger abilities
	var gen_bonus: float = clampf(float(dna.generation) * 0.02, 0.0, 0.2)

	# High affinity = stronger bond = stronger ability
	var affinity_bonus: float = dna.affinity * 0.15

	# Volatility adds potential but also risk
	var volatility_bonus: float = dna.volatility * 0.1

	return clampf(base_power + gen_bonus + affinity_bonus + volatility_bonus, 0.0, 1.0)


# ═══════════════════════════════════════════════════════════════
# RITUALS — Structured interaction sequences
# ═══════════════════════════════════════════════════════════════

## Ritual definitions. A ritual is a specific sequence of actions that,
## when completed, gives a large bond boost and/or unique reward.
## The ritual that activates depends on the critter's kingdom.
const RITUALS: Dictionary = {
	"tree_kinship": {
		"kingdom": 0,
		"description": "Rest under a tree for 30 seconds without moving",
		"required_action": "proximity",
		"required_count": 30,  # 30 proximity ticks (~30 seconds at 1/sec)
		"bond_bonus": 0.25,
	},
	"creature_respect": {
		"kingdom": 1,
		"description": "Survive an encounter, then observe without fleeing",
		"required_actions": ["survive", "observe", "observe", "observe"],
		"bond_bonus": 0.30,
	},
	"flower_inhale": {
		"kingdom": 2,
		"description": "Approach a toxic flower and stay (enter_space + proximity)",
		"required_action": "enter_space",
		"required_count": 1,
		"follow_up_action": "proximity",
		"follow_up_count": 10,
		"bond_bonus": 0.20,
	},
	"fungus_communion": {
		"kingdom": 3,
		"description": "Feed a mushroom, then touch it (ingest)",
		"required_actions": ["feed", "touch"],
		"bond_bonus": 0.25,
	},
}


## Update ritual progress for an entity after an interaction.
func _update_ritual_progress(entity: CritterEntity, bond: Dictionary, action: String) -> void:
	var kingdom: int = entity.get_kingdom()
	var progress: Dictionary = bond["ritual_progress"] as Dictionary

	for ritual_name in RITUALS:
		var ritual: Dictionary = RITUALS[ritual_name] as Dictionary
		var ritual_kingdom: int = ritual["kingdom"] as int
		if ritual_kingdom != kingdom:
			continue

		# Initialize progress if needed
		if ritual_name not in progress:
			progress[ritual_name] = {"step": 0, "count": 0}

		var rp: Dictionary = progress[ritual_name] as Dictionary

		# Check for sequence-based rituals
		if "required_actions" in ritual:
			var required: Array = ritual["required_actions"] as Array
			var step: int = rp["step"] as int
			if step < required.size():
				var needed_action: String = required[step] as String
				if action == needed_action:
					rp["step"] = step + 1

					# Check completion
					if rp["step"] as int >= required.size():
						_complete_ritual(entity, bond, ritual_name, ritual)
						rp["step"] = 0
				elif action == "fight" or action == "flee":
					rp["step"] = 0  # Reset on negative actions

		# Check for count-based rituals
		elif "required_action" in ritual:
			var needed: String = ritual["required_action"] as String
			if action == needed:
				rp["count"] = (rp["count"] as int) + 1

				var required_count: int = ritual["required_count"] as int
				var current: float = float(rp["count"] as int) / float(required_count)
				ritual_progress.emit(entity, ritual_name, clampf(current, 0.0, 1.0))

				if rp["count"] as int >= required_count:
					_complete_ritual(entity, bond, ritual_name, ritual)
					rp["count"] = 0


## Complete a ritual — apply the bond bonus.
func _complete_ritual(entity: CritterEntity, bond: Dictionary, ritual_name: String, ritual: Dictionary) -> void:
	var bonus: float = ritual["bond_bonus"] as float
	var old_level: float = bond["level"] as float
	bond["level"] = clampf(old_level + bonus, 0.0, 1.0)
	entity.set_bond_level(bond["level"] as float)

	ritual_progress.emit(entity, ritual_name, 1.0)
	bond_updated.emit(entity, old_level, bond["level"] as float)

	if debug:
		print("[TransmutationManager] Ritual '%s' completed! Bond: %.3f → %.3f" % [
			ritual_name, old_level, bond["level"]
		])


# ═══════════════════════════════════════════════════════════════
# BOND MANAGEMENT
# ═══════════════════════════════════════════════════════════════

## Get or create a bond record for a critter.
func _get_or_create_bond(entity_id: int) -> Dictionary:
	if entity_id in _bonds:
		return _bonds[entity_id] as Dictionary

	# Enforce max tracked bonds
	if _bonds.size() >= MAX_TRACKED_BONDS:
		_prune_weakest_bond()

	var bond: Dictionary = {
		"level": 0.0,
		"history": [],
		"last_interaction_time": Time.get_ticks_msec(),
		"ritual_progress": {},
	}
	_bonds[entity_id] = bond
	return bond


## Remove the weakest bond to make room.
func _prune_weakest_bond() -> void:
	var weakest_id: int = -1
	var weakest_level: float = INF

	for entity_id in _bonds:
		var bond: Dictionary = _bonds[entity_id] as Dictionary
		var level: float = bond["level"] as float
		if level < weakest_level:
			weakest_level = level
			weakest_id = entity_id

	if weakest_id >= 0:
		_bonds.erase(weakest_id)


## Get the current bond level for a critter (returns 0 if no bond exists).
func get_bond_level(entity: CritterEntity) -> float:
	if not entity:
		return 0.0
	var entity_id: int = entity.get_instance_id()
	if entity_id in _bonds:
		return (_bonds[entity_id] as Dictionary)["level"] as float
	return 0.0


## Get full bond data for a critter (for UI display).
func get_bond_data(entity: CritterEntity) -> Dictionary:
	if not entity:
		return {}
	var entity_id: int = entity.get_instance_id()
	if entity_id in _bonds:
		return _bonds[entity_id] as Dictionary
	return {}


## Check if a critter has been transmuted.
func is_transmuted(entity: CritterEntity) -> bool:
	if not entity:
		return false
	return entity.get_instance_id() in _transmuted_ids


# ═══════════════════════════════════════════════════════════════
# ABILITY QUERIES
# ═══════════════════════════════════════════════════════════════

## Check if the player has a specific ability.
func has_ability(ability_name: String) -> bool:
	return ability_name in _granted_abilities


## Get data for a granted ability.
func get_ability(ability_name: String) -> Dictionary:
	if ability_name in _granted_abilities:
		return _granted_abilities[ability_name] as Dictionary
	return {}


## Get all granted abilities.
func get_all_abilities() -> Dictionary:
	return _granted_abilities


## Get abilities by category.
func get_abilities_by_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ability_name in _granted_abilities:
		var ability: Dictionary = _granted_abilities[ability_name] as Dictionary
		if ability.get("category", "") == category:
			result.append(ability)
	return result


## Preview what ability a critter would grant (without transmuting).
func preview_ability(entity: CritterEntity) -> Dictionary:
	if not entity or not entity.dna:
		return {}
	return resolve_ability(entity.dna)


# ═══════════════════════════════════════════════════════════════
# SUMMARY / DEBUG
# ═══════════════════════════════════════════════════════════════

## Get a summary of all active bonds.
func get_bond_summary() -> Dictionary:
	var summary := {
		"total_bonds": _bonds.size(),
		"above_50": 0,
		"above_80": 0,
		"transmuted": _transmuted_ids.size(),
		"abilities_granted": _granted_abilities.size(),
	}

	for entity_id in _bonds:
		var level: float = (_bonds[entity_id] as Dictionary)["level"] as float
		if level > 0.5:
			summary["above_50"] = (summary["above_50"] as int) + 1
		if level > 0.8:
			summary["above_80"] = (summary["above_80"] as int) + 1

	return summary
