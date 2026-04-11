# CritterPlacer.gd — Grid-placeable DNA organism
#
# Bridges the grid system and the nature system. Place in the interactables
# layer of map_data.json to spawn a specific CritterDNA organism at a grid cell.
#
# Grid syntax:
#   critter_placer#preset:lsystem_tree          → pre-defined teaching organism
#   critter_placer#kingdom:0#branch_angle:45    → custom DNA with gene overrides
#   critter_placer#kingdom:2#symmetry:6:180     → flower with rotation
#
# The organism is built via MorphologyRouter from CritterDNA, so it's a real
# nature system entity — it breathes, has surface types, deposits presence.

class_name CritterPlacer
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Preset definitions — teaching-specific organisms
# ─────────────────────────────────────────────────────────────

const PRESETS: Dictionary = {
	# L-system grammar → branching structure
	"lsystem_tree": {
		"kingdom": 0, "segments": 5.0, "branch_angle": 45.0, "symmetry": 3.0,
		"branch_decay": 0.65, "leaf_density": 0.7, "scale": 1.5,
		"primary_color": "2ecc71", "secondary_color": "8b4513", "tertiary_color": "f1c40f",
		"root_type": 0.6, "roughness": 0.7,
	},
	# Golden angle → petal arrangement
	"fibonacci_flower": {
		"kingdom": 2, "symmetry": 8.0, "phyllotaxis": 0.618, "segments": 3.0,
		"scent_strength": 0.7, "nectar_quality": 0.8, "branch_angle": 60.0,
		"scale": 1.3, "primary_color": "ff6b6b", "secondary_color": "c44569",
		"roughness": 0.15, "iridescence": 0.4,
	},
	# Reaction-diffusion → colony patterns
	"turing_fungus": {
		"kingdom": 3, "pattern_type": 0.5, "sociality": 0.9, "part_curve": 0.6,
		"transparency": 0.2, "iridescence": 0.3, "scale": 1.0,
		"primary_color": "a29bfe", "secondary_color": "6c5ce7", "tertiary_color": "00cec9",
		"inflorescence": 0.6, "leaf_density": 0.7,
	},
	# Swarm rules → collective behavior
	"flocking_creature": {
		"kingdom": 1, "mobility": 0.8, "sociality": 0.7, "curiosity": 0.6,
		"segments": 6.0, "symmetry": 4.0, "scale": 1.2,
		"primary_color": "e84393", "secondary_color": "6c5ce7", "tertiary_color": "fdcb6e",
		"aggression": 0.2, "iridescence": 0.5,
	},
	# IK locomotion → hexapod gait
	"walking_tree": {
		"kingdom": 0, "mobility": 0.4, "root_type": 0.7, "symmetry": 6.0,
		"segments": 4.0, "branch_angle": 35.0, "scale": 1.5,
		"primary_color": "2ecc71", "secondary_color": "8b4513",
		"leaf_density": 0.6, "branch_decay": 0.65,
	},
	# Genetic algorithms → variation
	"evolving_flower": {
		"kingdom": 2, "fertility": 0.9, "volatility": 0.5, "symmetry": 5.0,
		"scale": 1.1, "primary_color": "fd79a8", "secondary_color": "a29bfe",
		"scent_strength": 0.6, "iridescence": 0.6,
	},
	# Predator-prey dynamics
	"predator": {
		"kingdom": 1, "aggression": 0.8, "mobility": 0.9, "curiosity": 0.4,
		"segments": 5.0, "symmetry": 2.0, "scale": 1.4,
		"primary_color": "d63031", "secondary_color": "2d3436", "tertiary_color": "fdcb6e",
		"part_length": 1.2, "metallic": 0.15,
	},
	# Mycorrhizal networks
	"symbiont_pair": {
		"kingdom": 3, "sociality": 0.95, "scent_strength": 0.8,
		"part_curve": 0.5, "transparency": 0.15, "scale": 0.8,
		"primary_color": "6c5ce7", "secondary_color": "a29bfe", "tertiary_color": "00cec9",
		"inflorescence": 0.7, "iridescence": 0.2,
	},
	# Boundary dissolution → QFEP
	"hybrid_drag": {
		"kingdom": -1, "body_type": 1.7, "iridescence": 0.8, "volatility": 0.6,
		"mobility": 0.5, "symmetry": 5.0, "scale": 1.3,
		"primary_color": "fd79a8", "secondary_color": "a29bfe", "tertiary_color": "ffeaa7",
		"pattern_type": 0.8, "affinity": 0.9,
	},
	# Simple oak tree
	"oak": {
		"kingdom": 0, "segments": 4.0, "branch_angle": 35.0, "symmetry": 4.0,
		"branch_decay": 0.7, "leaf_density": 0.8, "scale": 1.8,
		"primary_color": "27ae60", "secondary_color": "6d4c2a", "tertiary_color": "f39c12",
		"roughness": 0.8, "root_type": 0.5,
	},
	# Mushroom colony
	"mushroom_colony": {
		"kingdom": 3, "sociality": 0.9, "part_curve": 0.4, "part_width": 0.6,
		"scale": 0.9, "inflorescence": 0.7,
		"primary_color": "e17055", "secondary_color": "d35400", "tertiary_color": "fdcb6e",
		"transparency": 0.1, "iridescence": 0.15,
	},
}


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _dna: CritterDNA = null
var _entity: CritterEntity = null


# ═══════════════════════════════════════════════════════════════
# GRID INTEGRATION — called by GridInteractablesComponent
# ═══════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		# No config — spawn a random organism
		_dna = CritterDNA.random()
	elif "preset" in config:
		_dna = _load_preset(str(config["preset"]))
	else:
		_dna = _build_from_config(config)

	# Build the organism at this position
	_spawn_organism()


func _ready() -> void:
	# If no config was applied (standalone use), spawn random
	if _dna == null:
		_dna = CritterDNA.random_kingdom(0)  # Default tree
		call_deferred("_spawn_organism")


# ═══════════════════════════════════════════════════════════════
# DNA BUILDING
# ═══════════════════════════════════════════════════════════════

func _load_preset(preset_name: String) -> CritterDNA:
	if preset_name not in PRESETS:
		push_warning("[CritterPlacer] Unknown preset: %s — using random" % preset_name)
		return CritterDNA.random()

	var preset: Dictionary = PRESETS[preset_name]
	return _build_from_config(preset)


func _build_from_config(config: Dictionary) -> CritterDNA:
	var kingdom: int = int(config.get("kingdom", 0))
	var dna: CritterDNA

	if kingdom < 0:
		# Negative kingdom = fully random base (for hybrids with explicit body_type)
		dna = CritterDNA.random()
	else:
		dna = CritterDNA.random_kingdom(kingdom)

	# Override specific genes from config
	var color_keys: Array[String] = ["primary_color", "secondary_color", "tertiary_color"]

	for key in config:
		if key in ["kingdom", "preset"]:
			continue

		if key in color_keys:
			# Parse hex color string
			var hex: String = str(config[key])
			if hex.length() == 6:
				dna.set(key, Color.html(hex))
		elif dna.get(key) != null:
			# Set numeric gene
			var val = config[key]
			if val is String:
				dna.set(key, float(val))
			elif val is float or val is int:
				dna.set(key, float(val))

	return dna


# ═══════════════════════════════════════════════════════════════
# ORGANISM SPAWNING
# ═══════════════════════════════════════════════════════════════

func _spawn_organism() -> void:
	if _dna == null:
		return

	# Create entity
	_entity = CritterEntity.new()
	_entity.name = "PlacedCritter_%s" % _dna.get_kingdom_name()
	add_child(_entity)

	# Build morphology
	var trait_mapper := CritterTraitMapper.new()
	MorphologyRouter.build(_dna, _entity, trait_mapper, 0)
	_entity.init_from_dna(_dna)

	# Store DNA in metadata for ecosystem interactions
	set_meta("dna", _dna)
	set_meta("kingdom", _dna.get_kingdom_name())
	set_meta("is_critter_placer", true)

	print("[CritterPlacer] Spawned %s (preset or custom)" % _dna.get_kingdom_name())


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

func get_dna() -> CritterDNA:
	return _dna

func get_entity() -> CritterEntity:
	return _entity

func get_kingdom_name() -> String:
	return _dna.get_kingdom_name() if _dna else "none"
