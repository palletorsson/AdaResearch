# ===============================
# TOPOLOGY MANAGER - Orchestrates walkable mathematical spaces
# ===============================
extends Node3D
class_name TopologyManager

@export var space_separation: float = 30.0
@export var teleport_height: float = 5.0

# ── Core Spaces ──────────────────────────────────────────────
@export_group("Core Spaces")
@export var create_sine_space: bool = true
@export var create_noise_space: bool = true
@export var create_voronoi_space: bool = true
@export var create_random_space: bool = true
@export var create_fractal_space: bool = true

# ── Cellular / Emergent ──────────────────────────────────────
@export_group("Cellular & Emergent")
@export var create_worley_space: bool = false
@export var create_cellular_automata_space: bool = false
@export var create_reaction_diffusion_space: bool = false

# ── Mathematical Structures ──────────────────────────────────
@export_group("Mathematical Structures")
@export var create_mandelbrot_space: bool = false
@export var create_lsystem_space: bool = false
@export var create_wave_interference_space: bool = false
@export var create_ridged_noise_space: bool = false
@export var create_spherical_harmonics_space: bool = false
@export var create_flow_field_space: bool = false

# ── Terrain & Simulation ─────────────────────────────────────
@export_group("Terrain & Simulation")
@export var create_domain_warp_space: bool = false
@export var create_erosion_space: bool = false

# ── Topology / Non-Euclidean ─────────────────────────────────
@export_group("Topology & Non-Euclidean")
@export var create_mobius_space: bool = false
@export var create_torus_space: bool = false
@export var create_hyperbolic_space: bool = false

# ── Meta ─────────────────────────────────────────────────────
@export_group("Meta Spaces")
@export var create_knowledge_terrain: bool = false

var spaces: Array[Node3D] = []
var current_space_index: int = 0

# Registry of all space types for dynamic creation
const SPACE_REGISTRY = {
	# [flag_name, script_path, display_name]
	"sine":                 ["res://commons/context/walkgrids/SineSpace.gd",                "SineSpace"],
	"noise":                ["res://commons/context/walkgrids/NoiseSpace.gd",               "NoiseSpace"],
	"voronoi":              ["res://commons/context/walkgrids/VoronoiSpace.gd",             "VoronoiSpace"],
	"random":               ["res://commons/context/walkgrids/RandomSpace.gd",              "RandomSpace"],
	"fractal":              ["res://commons/context/walkgrids/FractalSpace.gd",             "FractalSpace"],
	"worley":               ["res://commons/context/walkgrids/WorleySpace.gd",              "WorleySpace"],
	"cellular_automata":    ["res://commons/context/walkgrids/CellularAutomataSpace.gd",    "CellularAutomataSpace"],
	"reaction_diffusion":   ["res://commons/context/walkgrids/ReactionDiffusionSpace.gd",   "ReactionDiffusionSpace"],
	"mandelbrot":           ["res://commons/context/walkgrids/MandelbrotSpace.gd",          "MandelbrotSpace"],
	"lsystem":              ["res://commons/context/walkgrids/LSystemSpace.gd",             "LSystemSpace"],
	"wave_interference":    ["res://commons/context/walkgrids/WaveInterferenceSpace.gd",    "WaveInterferenceSpace"],
	"ridged_noise":         ["res://commons/context/walkgrids/RidgedNoiseSpace.gd",         "RidgedNoiseSpace"],
	"spherical_harmonics":  ["res://commons/context/walkgrids/SphericalHarmonicsSpace.gd",  "SphericalHarmonicsSpace"],
	"flow_field":           ["res://commons/context/walkgrids/FlowFieldSpace.gd",           "FlowFieldSpace"],
	"domain_warp":          ["res://commons/context/walkgrids/DomainWarpSpace.gd",          "DomainWarpSpace"],
	"erosion":              ["res://commons/context/walkgrids/ErosionSpace.gd",             "ErosionSpace"],
	"mobius":               ["res://commons/context/walkgrids/MobiusSpace.gd",              "MobiusSpace"],
	"torus":                ["res://commons/context/walkgrids/TorusSpace.gd",               "TorusSpace"],
	"hyperbolic":           ["res://commons/context/walkgrids/HyperbolicSpace.gd",          "HyperbolicSpace"],
	"knowledge":            ["res://commons/context/walkgrids/KnowledgeTerrainSpace.gd",    "KnowledgeTerrainSpace"],
}

func _ready():
	create_selected_topology_spaces()

func create_selected_topology_spaces():
	spaces.clear()
	var position_index = 0

	# Map export flags to registry keys
	var flag_map = {
		"sine": create_sine_space,
		"noise": create_noise_space,
		"voronoi": create_voronoi_space,
		"random": create_random_space,
		"fractal": create_fractal_space,
		"worley": create_worley_space,
		"cellular_automata": create_cellular_automata_space,
		"reaction_diffusion": create_reaction_diffusion_space,
		"mandelbrot": create_mandelbrot_space,
		"lsystem": create_lsystem_space,
		"wave_interference": create_wave_interference_space,
		"ridged_noise": create_ridged_noise_space,
		"spherical_harmonics": create_spherical_harmonics_space,
		"flow_field": create_flow_field_space,
		"domain_warp": create_domain_warp_space,
		"erosion": create_erosion_space,
		"mobius": create_mobius_space,
		"torus": create_torus_space,
		"hyperbolic": create_hyperbolic_space,
		"knowledge": create_knowledge_terrain,
	}

	for key in flag_map:
		if flag_map[key]:
			var entry = SPACE_REGISTRY[key]
			var script_path: String = entry[0]
			var display_name: String = entry[1]
			var space = _create_space_from_path(display_name, script_path)
			if space:
				space.position.x = position_index * space_separation
				spaces.append(space)
				position_index += 1

	print("TopologyManager: Created %d mathematical spaces" % spaces.size())

func _create_space_from_path(space_name: String, script_path: String) -> Node3D:
	var script = load(script_path)
	if script == null:
		push_warning("TopologyManager: Could not load script: %s" % script_path)
		return null
	var space = script.new()
	space.name = space_name
	add_child(space)
	return space

# Legacy helper (kept for compatibility)
func create_space(space_name: String, script_resource: Script) -> Node3D:
	var space = script_resource.new()
	space.name = space_name
	add_child(space)
	return space

# ── Navigation API ───────────────────────────────────────────

func get_current_space() -> Node3D:
	if spaces.is_empty():
		return null
	return spaces[current_space_index]

func get_space_count() -> int:
	return spaces.size()

func get_space_names() -> Array[String]:
	var names: Array[String] = []
	for s in spaces:
		names.append(s.name)
	return names

func next_space() -> Node3D:
	if spaces.is_empty():
		return null
	current_space_index = (current_space_index + 1) % spaces.size()
	return spaces[current_space_index]

func previous_space() -> Node3D:
	if spaces.is_empty():
		return null
	current_space_index = (current_space_index - 1 + spaces.size()) % spaces.size()
	return spaces[current_space_index]

func teleport_to_space(index: int) -> Vector3:
	"""Returns the position to teleport the player to for the given space"""
	if index < 0 or index >= spaces.size():
		return Vector3.ZERO
	current_space_index = index
	var space = spaces[index]
	return space.global_position + Vector3(0, teleport_height, 0)

func teleport_to_space_by_name(space_name: String) -> Vector3:
	for i in range(spaces.size()):
		if spaces[i].name == space_name:
			return teleport_to_space(i)
	push_warning("TopologyManager: No space named '%s'" % space_name)
	return Vector3.ZERO

# ── Dynamic Space Management ─────────────────────────────────

func add_space_at_runtime(registry_key: String) -> Node3D:
	"""Add a space dynamically after initial setup"""
	if not SPACE_REGISTRY.has(registry_key):
		push_warning("TopologyManager: Unknown space key '%s'" % registry_key)
		return null

	var entry = SPACE_REGISTRY[registry_key]
	var space = _create_space_from_path(entry[1], entry[0])
	if space:
		space.position.x = spaces.size() * space_separation
		spaces.append(space)
		print("TopologyManager: Added %s (total: %d)" % [entry[1], spaces.size()])
	return space

func remove_space(index: int):
	"""Remove a space by index"""
	if index < 0 or index >= spaces.size():
		return
	var space = spaces[index]
	spaces.remove_at(index)
	space.queue_free()
	if current_space_index >= spaces.size():
		current_space_index = maxi(0, spaces.size() - 1)

func remove_all_spaces():
	for space in spaces:
		space.queue_free()
	spaces.clear()
	current_space_index = 0
