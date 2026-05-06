# ForceTransmutationConfig.gd
# Single source of truth for all force type configurations.
# Each force has a hazard mode and a transmuted mode.
# Q-FEP: same potential, different restraint, different manifestation.
extends RefCounted
class_name ForceTransmutationConfig

# ── Force type constants (matching ForceField.ForceType enum order) ──────
const FIRE: int = 0
const VACUUM: int = 1
const ELECTRIC: int = 2
const TOXIC: int = 3
const RADIATION: int = 4
const FREEZING: int = 5
const ACID: int = 6
const MAGNETIC: int = 7
const GRAVITY: int = 8
const ENTROPY: int = 9
const RESONANCE: int = 10
const VOID: int = 11

# ── Master config dictionary ─────────────────────────────────────────────
# Follows the FORM_VISUALS pattern from PlasmaCritter.
const FORCE_CONFIGS: Dictionary = {
	FIRE: {
		"name": "Fire",
		"hazard": {
			"damage_per_tick": 10.0,
			"tick_interval": 0.5,
			"color": Color(1.0, 0.4, 0.0, 0.4),
			"emission": Color(1.0, 0.3, 0.0),
			"emission_energy": 1.5,
			"particle_color_start": Color(1.0, 0.9, 0.4, 0.9),
			"particle_color_end": Color(1.0, 0.2, 0.0, 0.0),
			"particle_direction": Vector3(0, 1, 0),
			"particle_spread": 35.0,
			"light_color": Color(1.0, 0.5, 0.1),
			"light_energy": 2.0,
			"description": "FIRE: Burns on contact. Heat accumulates.",
		},
		"transmuted": {
			"heal_per_second": 5.0,
			"buff_id": "fire_resistance",
			"buff_duration": 30.0,
			"color": Color(1.0, 0.85, 0.4, 0.3),
			"emission": Color(1.0, 0.9, 0.5),
			"emission_energy": 1.0,
			"particle_color_start": Color(1.0, 0.95, 0.7, 0.7),
			"particle_color_end": Color(1.0, 0.8, 0.3, 0.0),
			"particle_direction": Vector3(0, 0.3, 0),
			"particle_spread": 50.0,
			"light_color": Color(1.0, 0.9, 0.6),
			"light_energy": 1.2,
			"description": "WARMTH: Heals and grants fire resistance.",
		},
		"conditions": {
			"mediator_groups": ["mushroom", "water", "crystal"],
			"exposure_threshold": 3.0,
			"courage_threshold": 8.0,  # Seconds to transmute through endurance alone
		},
		"pedagogical_hint": "Fire is energy seeking release. Restraint transforms destruction into warmth.",
	},

	VACUUM: {
		"name": "Vacuum",
		"hazard": {
			"damage_per_tick": 8.0,
			"tick_interval": 0.8,
			"color": Color(0.1, 0.1, 0.3, 0.3),
			"emission": Color(0.2, 0.2, 0.5),
			"emission_energy": 0.5,
			"particle_color_start": Color(0.3, 0.3, 0.6, 0.5),
			"particle_color_end": Color(0.05, 0.05, 0.15, 0.0),
			"particle_direction": Vector3(0, -0.5, 0),
			"particle_spread": 90.0,
			"light_color": Color(0.2, 0.2, 0.5),
			"light_energy": 0.4,
			"description": "VACUUM: Oxygen depletes. Pressure drops.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "low_gravity",
			"buff_duration": 20.0,
			"color": Color(0.3, 0.3, 0.7, 0.2),
			"emission": Color(0.4, 0.4, 0.9),
			"emission_energy": 0.8,
			"particle_color_start": Color(0.5, 0.5, 1.0, 0.4),
			"particle_color_end": Color(0.2, 0.2, 0.5, 0.0),
			"particle_direction": Vector3(0, 1, 0),
			"particle_spread": 120.0,
			"light_color": Color(0.4, 0.4, 0.9),
			"light_energy": 0.6,
			"description": "WEIGHTLESSNESS: Float free. Reach the unreachable.",
		},
		"conditions": {
			"mediator_groups": ["mushroom", "sealed_tool"],
			"exposure_threshold": 4.0,
			"courage_threshold": 12.0,
		},
		"pedagogical_hint": "Absence is not nothing. It is invitation.",
	},

	ELECTRIC: {
		"name": "Electric",
		"hazard": {
			"damage_per_tick": 15.0,
			"tick_interval": 1.5,
			"color": Color(0.0, 0.8, 1.0, 0.4),
			"emission": Color(0.3, 0.9, 1.0),
			"emission_energy": 2.5,
			"particle_color_start": Color(0.7, 0.95, 1.0, 1.0),
			"particle_color_end": Color(0.0, 0.5, 0.8, 0.0),
			"particle_direction": Vector3(0, 0.2, 0),
			"particle_spread": 180.0,
			"light_color": Color(0.3, 0.8, 1.0),
			"light_energy": 3.0,
			"description": "ELECTRIC: Shock pulses. Periodic bursts.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "energy_harvest",
			"buff_duration": 25.0,
			"color": Color(0.3, 0.9, 1.0, 0.25),
			"emission": Color(0.5, 1.0, 1.0),
			"emission_energy": 1.5,
			"particle_color_start": Color(0.6, 1.0, 1.0, 0.6),
			"particle_color_end": Color(0.2, 0.6, 0.8, 0.0),
			"particle_direction": Vector3(0, 0.8, 0),
			"particle_spread": 40.0,
			"light_color": Color(0.5, 1.0, 1.0),
			"light_energy": 1.8,
			"description": "POWER: Energy harvested. Doors open. Items charge.",
		},
		"conditions": {
			"mediator_groups": ["crystal", "grounding_tool"],
			"exposure_threshold": 2.5,
			"courage_threshold": 6.0,
		},
		"pedagogical_hint": "Current flows toward need. Ground yourself and the shock becomes fuel.",
	},

	TOXIC: {
		"name": "Toxic",
		"hazard": {
			"damage_per_tick": 7.0,
			"tick_interval": 0.6,
			"color": Color(0.2, 0.8, 0.2, 0.35),
			"emission": Color(0.3, 1.0, 0.3),
			"emission_energy": 1.2,
			"particle_color_start": Color(0.3, 0.9, 0.3, 0.8),
			"particle_color_end": Color(0.1, 0.4, 0.1, 0.0),
			"particle_direction": Vector3(0, 0.8, 0),
			"particle_spread": 45.0,
			"light_color": Color(0.3, 0.8, 0.2),
			"light_energy": 1.0,
			"description": "TOXIC: Poison lingers. Vision blurs.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "revelation_vision",
			"buff_duration": 40.0,
			"color": Color(0.4, 1.0, 0.6, 0.2),
			"emission": Color(0.5, 1.0, 0.7),
			"emission_energy": 0.8,
			"particle_color_start": Color(0.5, 1.0, 0.8, 0.5),
			"particle_color_end": Color(0.2, 0.6, 0.4, 0.0),
			"particle_direction": Vector3(0, 0.5, 0),
			"particle_spread": 60.0,
			"light_color": Color(0.4, 1.0, 0.6),
			"light_energy": 0.9,
			"description": "REVELATION: Hidden paths glow. Secrets visible.",
		},
		"conditions": {
			"mediator_groups": ["mushroom", "antidote"],
			"exposure_threshold": 3.5,
			"courage_threshold": 10.0,
		},
		"pedagogical_hint": "Poison and medicine are dosage apart. The difference is relationship.",
	},

	RADIATION: {
		"name": "Radiation",
		"hazard": {
			"damage_per_tick": 5.0,
			"tick_interval": 1.0,
			"color": Color(1.0, 1.0, 0.0, 0.15),
			"emission": Color(1.0, 1.0, 0.3),
			"emission_energy": 0.6,
			"particle_color_start": Color(1.0, 1.0, 0.5, 0.3),
			"particle_color_end": Color(0.8, 0.8, 0.0, 0.0),
			"particle_direction": Vector3(0, 0.1, 0),
			"particle_spread": 180.0,
			"light_color": Color(1.0, 1.0, 0.4),
			"light_energy": 0.3,
			"description": "RADIATION: Invisible decay. Geiger warning.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "mutation",
			"buff_duration": 60.0,
			"color": Color(1.0, 1.0, 0.5, 0.15),
			"emission": Color(0.9, 1.0, 0.6),
			"emission_energy": 0.8,
			"particle_color_start": Color(1.0, 1.0, 0.7, 0.4),
			"particle_color_end": Color(0.5, 0.8, 0.3, 0.0),
			"particle_direction": Vector3(0, 0.4, 0),
			"particle_spread": 90.0,
			"light_color": Color(0.8, 1.0, 0.5),
			"light_energy": 0.6,
			"description": "TRANSFORMATION: Nearby critters evolve. Forms shift.",
		},
		"conditions": {
			"mediator_groups": ["crystal", "lead_tool"],
			"exposure_threshold": 5.0,
			"courage_threshold": 15.0,
		},
		"pedagogical_hint": "Decay is change wearing a mask. Given time, destruction becomes evolution.",
	},

	FREEZING: {
		"name": "Freezing",
		"hazard": {
			"damage_per_tick": 6.0,
			"tick_interval": 0.7,
			"color": Color(0.6, 0.85, 1.0, 0.3),
			"emission": Color(0.7, 0.9, 1.0),
			"emission_energy": 0.8,
			"particle_color_start": Color(0.8, 0.95, 1.0, 0.7),
			"particle_color_end": Color(0.4, 0.6, 0.8, 0.0),
			"particle_direction": Vector3(0, -0.5, 0),
			"particle_spread": 30.0,
			"light_color": Color(0.7, 0.85, 1.0),
			"light_energy": 0.7,
			"description": "FREEZING: Movement slows. Ice crystallizes.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "preservation",
			"buff_duration": 25.0,
			"color": Color(0.7, 0.9, 1.0, 0.2),
			"emission": Color(0.8, 0.95, 1.0),
			"emission_energy": 0.6,
			"particle_color_start": Color(0.85, 0.95, 1.0, 0.4),
			"particle_color_end": Color(0.6, 0.8, 0.95, 0.0),
			"particle_direction": Vector3(0, -0.2, 0),
			"particle_spread": 20.0,
			"light_color": Color(0.8, 0.92, 1.0),
			"light_energy": 0.5,
			"description": "PRESERVATION: Time slows. Hazards freeze. Ice bridges form.",
		},
		"conditions": {
			"mediator_groups": ["plasma", "heat_source"],
			"exposure_threshold": 3.0,
			"courage_threshold": 9.0,
		},
		"pedagogical_hint": "Stillness holds what motion cannot. Cold preserves what heat transforms.",
	},

	ACID: {
		"name": "Acid",
		"hazard": {
			"damage_per_tick": 12.0,
			"tick_interval": 0.4,
			"color": Color(0.8, 1.0, 0.0, 0.4),
			"emission": Color(0.9, 1.0, 0.1),
			"emission_energy": 1.8,
			"particle_color_start": Color(0.9, 1.0, 0.2, 0.9),
			"particle_color_end": Color(0.4, 0.5, 0.0, 0.0),
			"particle_direction": Vector3(0, -0.3, 0),
			"particle_spread": 25.0,
			"light_color": Color(0.8, 1.0, 0.1),
			"light_energy": 1.5,
			"description": "ACID: Dissolves rapidly. Corrosion spreads.",
		},
		"transmuted": {
			"heal_per_second": 2.0,
			"buff_id": "cleansing",
			"buff_duration": 20.0,
			"color": Color(0.7, 1.0, 0.5, 0.2),
			"emission": Color(0.6, 0.9, 0.4),
			"emission_energy": 0.7,
			"particle_color_start": Color(0.6, 1.0, 0.5, 0.5),
			"particle_color_end": Color(0.3, 0.6, 0.2, 0.0),
			"particle_direction": Vector3(0, 0.5, 0),
			"particle_spread": 40.0,
			"light_color": Color(0.5, 0.9, 0.4),
			"light_energy": 0.8,
			"description": "CLEANSING: Debuffs dissolve. Barriers melt. Architecture revealed.",
		},
		"conditions": {
			"mediator_groups": ["crystal", "alkaline_tool"],
			"exposure_threshold": 2.0,
			"courage_threshold": 7.0,
		},
		"pedagogical_hint": "Dissolution precedes renewal. What acid unmakes, it also frees.",
	},

	MAGNETIC: {
		"name": "Magnetic",
		"hazard": {
			"damage_per_tick": 0.0,  # No damage, just force
			"tick_interval": 0.1,
			"color": Color(0.5, 0.0, 0.5, 0.3),
			"emission": Color(0.7, 0.1, 0.7),
			"emission_energy": 1.2,
			"particle_color_start": Color(0.8, 0.2, 0.8, 0.7),
			"particle_color_end": Color(0.3, 0.0, 0.3, 0.0),
			"particle_direction": Vector3(0, 0, 0),
			"particle_spread": 180.0,
			"light_color": Color(0.6, 0.1, 0.6),
			"light_energy": 1.0,
			"description": "MAGNETIC: Repels. Disorients. Pushes away.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "attraction",
			"buff_duration": 30.0,
			"color": Color(0.6, 0.2, 0.8, 0.2),
			"emission": Color(0.7, 0.3, 0.9),
			"emission_energy": 0.8,
			"particle_color_start": Color(0.7, 0.4, 1.0, 0.5),
			"particle_color_end": Color(0.3, 0.1, 0.5, 0.0),
			"particle_direction": Vector3(0, 0.3, 0),
			"particle_spread": 60.0,
			"light_color": Color(0.6, 0.3, 0.9),
			"light_energy": 0.7,
			"description": "ATTRACTION: Pull objects to hand. Magnetic climbing.",
		},
		"conditions": {
			"mediator_groups": ["iron_tool", "compass"],
			"exposure_threshold": 3.0,
			"courage_threshold": -1.0,  # Cannot transmute by courage alone
		},
		"pedagogical_hint": "Repulsion and attraction are the same force. Polarity is perspective.",
	},

	GRAVITY: {
		"name": "Gravity",
		"hazard": {
			"damage_per_tick": 3.0,
			"tick_interval": 1.0,
			"color": Color(0.2, 0.0, 0.3, 0.35),
			"emission": Color(0.3, 0.1, 0.4),
			"emission_energy": 0.4,
			"particle_color_start": Color(0.4, 0.2, 0.5, 0.6),
			"particle_color_end": Color(0.1, 0.0, 0.2, 0.0),
			"particle_direction": Vector3(0, -1, 0),
			"particle_spread": 10.0,
			"light_color": Color(0.3, 0.1, 0.4),
			"light_energy": 0.3,
			"description": "GRAVITY: Weight crushes. Movement drags.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "levitation",
			"buff_duration": 20.0,
			"color": Color(0.4, 0.2, 0.6, 0.15),
			"emission": Color(0.5, 0.3, 0.8),
			"emission_energy": 0.6,
			"particle_color_start": Color(0.5, 0.3, 0.8, 0.4),
			"particle_color_end": Color(0.2, 0.1, 0.4, 0.0),
			"particle_direction": Vector3(0, 1, 0),
			"particle_spread": 15.0,
			"light_color": Color(0.5, 0.3, 0.7),
			"light_energy": 0.5,
			"description": "LEVITATION: Float free. Gravity inverted. Explore the heights.",
		},
		"conditions": {
			"mediator_groups": ["crystal", "anti_mass"],
			"exposure_threshold": 4.0,
			"courage_threshold": -1.0,
		},
		"pedagogical_hint": "Weight is potential awaiting direction. Invert the frame and falling becomes flying.",
	},

	ENTROPY: {
		"name": "Entropy",
		"hazard": {
			"damage_per_tick": 4.0,
			"tick_interval": 1.2,
			"color": Color(0.5, 0.5, 0.5, 0.25),
			"emission": Color(0.6, 0.6, 0.6),
			"emission_energy": 0.5,
			"particle_color_start": Color(0.7, 0.7, 0.7, 0.6),
			"particle_color_end": Color(0.2, 0.2, 0.2, 0.0),
			"particle_direction": Vector3(0, -0.2, 0),
			"particle_spread": 180.0,
			"light_color": Color(0.5, 0.5, 0.5),
			"light_energy": 0.3,
			"description": "ENTROPY: Objects decay. Order crumbles.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "creation",
			"buff_duration": 30.0,
			"color": Color(0.8, 0.6, 1.0, 0.2),
			"emission": Color(0.9, 0.7, 1.0),
			"emission_energy": 1.0,
			"particle_color_start": Color(1.0, 0.8, 1.0, 0.6),
			"particle_color_end": Color(0.5, 0.3, 0.7, 0.0),
			"particle_direction": Vector3(0, 0.8, 0),
			"particle_spread": 90.0,
			"light_color": Color(0.8, 0.6, 1.0),
			"light_energy": 0.8,
			"description": "CREATION: Novelty spawns. Disorder becomes fertility.",
		},
		"conditions": {
			"mediator_groups": ["entropy_jar", "entropy_axiom"],
			"exposure_threshold": 3.0,
			"courage_threshold": 10.0,
		},
		"pedagogical_hint": "Disorder is fertility. Every ending seeds a beginning the old order could not imagine.",
	},

	RESONANCE: {
		"name": "Resonance",
		"hazard": {
			"damage_per_tick": 8.0,
			"tick_interval": 2.0,
			"color": Color(1.0, 0.6, 0.0, 0.3),
			"emission": Color(1.0, 0.7, 0.2),
			"emission_energy": 1.5,
			"particle_color_start": Color(1.0, 0.8, 0.3, 0.7),
			"particle_color_end": Color(0.6, 0.3, 0.0, 0.0),
			"particle_direction": Vector3(0, 0.2, 0),
			"particle_spread": 180.0,
			"light_color": Color(1.0, 0.7, 0.2),
			"light_energy": 1.5,
			"description": "RESONANCE: Shatters held objects. Ground trembles.",
		},
		"transmuted": {
			"heal_per_second": 0.0,
			"buff_id": "harmony",
			"buff_duration": 35.0,
			"color": Color(1.0, 0.85, 0.4, 0.2),
			"emission": Color(1.0, 0.9, 0.5),
			"emission_energy": 0.8,
			"particle_color_start": Color(1.0, 0.9, 0.6, 0.5),
			"particle_color_end": Color(0.7, 0.5, 0.2, 0.0),
			"particle_direction": Vector3(0, 0.5, 0),
			"particle_spread": 60.0,
			"light_color": Color(1.0, 0.9, 0.5),
			"light_energy": 0.9,
			"description": "HARMONY: Critters synchronize. Harmonic puzzles unlock.",
		},
		"conditions": {
			"mediator_groups": ["tuning_fork", "singing_mushroom"],
			"exposure_threshold": 3.0,
			"courage_threshold": -1.0,
		},
		"pedagogical_hint": "Every frequency finds its partner. Dissonance is harmony not yet resolved.",
	},

	VOID: {
		"name": "Void",
		"hazard": {
			"damage_per_tick": 50.0,
			"tick_interval": 2.0,
			"color": Color(0.0, 0.0, 0.0, 0.5),
			"emission": Color(0.05, 0.0, 0.1),
			"emission_energy": 0.1,
			"particle_color_start": Color(0.1, 0.0, 0.15, 0.8),
			"particle_color_end": Color(0.0, 0.0, 0.0, 0.0),
			"particle_direction": Vector3(0, -0.3, 0),
			"particle_spread": 180.0,
			"light_color": Color(0.05, 0.0, 0.1),
			"light_energy": 0.1,
			"description": "VOID: Annihilation. Presence dissolves.",
		},
		"transmuted": {
			"heal_per_second": 10.0,
			"buff_id": "potentia",
			"buff_duration": 120.0,
			"color": Color(0.1, 0.0, 0.2, 0.15),
			"emission": Color(0.3, 0.1, 0.5),
			"emission_energy": 2.0,
			"particle_color_start": Color(0.5, 0.2, 0.8, 0.6),
			"particle_color_end": Color(0.1, 0.0, 0.3, 0.0),
			"particle_direction": Vector3(0, 1, 0),
			"particle_spread": 30.0,
			"light_color": Color(0.3, 0.1, 0.5),
			"light_energy": 1.5,
			"description": "POTENTIA: Nothing contains everything. Q-FEP axioms revealed.",
		},
		"conditions": {
			"mediator_groups": ["companion_bonded"],
			"exposure_threshold": 5.0,
			"courage_threshold": -1.0,  # Cannot brute-force the void
		},
		"pedagogical_hint": "Nothing contains everything. The void is pure potential, uncollapsed.",
	},
}


# ── Static accessors ─────────────────────────────────────────────────────

static func get_config(force_type: int) -> Dictionary:
	return FORCE_CONFIGS.get(force_type, FORCE_CONFIGS[FIRE])


static func get_hazard_config(force_type: int) -> Dictionary:
	var cfg: Dictionary = get_config(force_type)
	return cfg.get("hazard", {})


static func get_transmuted_config(force_type: int) -> Dictionary:
	var cfg: Dictionary = get_config(force_type)
	return cfg.get("transmuted", {})


static func get_conditions(force_type: int) -> Dictionary:
	var cfg: Dictionary = get_config(force_type)
	return cfg.get("conditions", {})


static func get_pedagogical_hint(force_type: int) -> String:
	var cfg: Dictionary = get_config(force_type)
	return cfg.get("pedagogical_hint", "")


static func get_force_name(force_type: int) -> String:
	var cfg: Dictionary = get_config(force_type)
	return cfg.get("name", "Unknown")


static func parse_force_type(type_str: String) -> int:
	match type_str.to_lower().strip_edges():
		"fire": return FIRE
		"vacuum": return VACUUM
		"electric": return ELECTRIC
		"toxic": return TOXIC
		"radiation": return RADIATION
		"freezing": return FREEZING
		"acid": return ACID
		"magnetic": return MAGNETIC
		"gravity": return GRAVITY
		"entropy": return ENTROPY
		"resonance": return RESONANCE
		"void": return VOID
		_: return FIRE
