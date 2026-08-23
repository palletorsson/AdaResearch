# GridInteractablesComponent.gd - IMPROVED with lookup_name validation
# Handles placement of interactable artifacts and objects
# Uses lookup_name as the central identifier system

extends Node
class_name GridInteractablesComponent

# Path constants
const REGISTRY_DIR_PATH = "res://commons/artifacts/registry/"
const ARTIFACT_PLACEHOLDER_SCENE_PATH = "res://commons/artifacts/placeholders/ArtifactPlaceholder.tscn"
const ClusterResolverScript = preload("res://commons/grid/cluster_resolver.gd")  # expands cluster:<name> tokens
static var _artifact_registry_cache_by_key: Dictionary = {}

# Known config parameter names (NOT to be treated as tutorial shorthand)
# These are artifact configuration keys that can have numeric values
const CONFIG_PARAM_NAMES = [
	"radial", "rings", "inner", "outer", "config", "height", "radius",
	"width", "depth", "segments", "sides", "rows", "cols", "count",
	"size", "scale", "speed", "delay", "duration", "intensity",
	"number_of_rocks", "container_height", "spawn_area_x", "spawn_area_y", "spawn_area_z",
	"rock_size_min", "rock_size_max", "deformation_min", "deformation_max",
	"roughness_min", "roughness_max", "subdivisions", "generation_seed",
	"rock_mass", "rock_friction", "rock_bounce", "spawn_mode",
	"enable_gravity", "use_pride_colors", "make_rocks_static", "color_variation",
	# Configurable portal / transform params
	"rot_x", "rot_y", "rot_z", "pos_x", "pos_y", "pos_z",
	"dest", "dest_x", "dest_y", "dest_z", "dest_map", "map", "spawn",
	"label", "color1", "color2", "energy", "frame", "active", "cooldown", "mode", "sky",
	# Path-and-block game params
	"debug_test", "grace_seconds", "cell_size", "shape", "win_on_all_befriended",
	"build_shape", "build_interval", "build_ahead", "max_blocks", "build_size", "use_grid_shader",
	# Wave/burst pattern params
	"wave", "wave_rows", "wave_flat", "wave_max", "wave_axis",
	"burst", "burst_rotate", "burst_flat", "burst_axis",
	"grad", "grad_start", "grad_end", "grad_axis", "grad_auto", "bell", "flip", "max_slope",
	"alt_x", "alt_y", "alt_z", "phase", "phase_deg", "phase_mode",
	"spin_x", "spin_y", "spin_z", "speed_x", "speed_y", "speed_z",
	"animate", "duration", "no_collision", "rotate_collision",
	# Random cycle cube params
	"span", "random_span", "wait_min", "wait_span", "down", "up", "hide",
	# Grid2D / Grid3D / substrate params
	"algorithm", "interval", "auto_play", "grid_width", "grid_height", "nodes", "samples",
	# Living paper params
	"paper", "texture", "fold", "orientation",
	# Shader / cove / wallpaper params
	"shader", "pattern_seed", "wallpaper_group", "tile_scale", "grout_width",
	"grout_color", "noise_distort", "emission_strength", "metallic", "roughness",
	"wear_amount", "dust_amount", "fade_amount", "crack_density", "stain_amount", "chip_amount",
	"cove_width", "cove_radius", "curve_segments", "wall_extend", "wall_height",
	"floor_depth", "albedo_color", "shader_list", "cycle_interval", "auto_cycle",
	# Composition params
	"preset", "tile_size", "surface", "composition_type", "composition_json",
	"grid_resolution", "tunnel_width", "tunnel_height", "tunnel_length", "arch_radius",
	"arch_segments", "section_length", "cube_size",
	# Art history gallery params
	"tile_resolution", "tile_world_size", "columns",
	# Tiling coordinate system
	"tiling",
	# lab_room params — keep "key:numeric" parsed as key:value, not as
	# shorthand transform syntax. Without these listed here the token
	# parser treats e.g. "room_width:8.0" as tutorial_id="room_width"
	# with rotation 8.0, and the lab silently falls back to defaults.
	"room_width", "room_depth", "room_height",
	"light_warmth", "light_energy", "accent_strip_energy",
	"floor_tile_count", "panel_columns",
	"window_size", "back_window_size", "front_window_size",
	"front_window_offset_x", "front_window_y",
	"show_floor_window", "floor_window_size", "floor_window_offset",
	"door_wall", "door_width", "door_height",
	"door_sensor_radius", "door_open_offset",
	"show_floor_tiles", "show_observation_window", "window_wall",
	"south_wall_is_glass", "show_back_window", "show_front_window",
	"show_sliding_door", "show_wall_annotations", "show_plinth",
	"wall_pattern", "ceiling_style",
	"signage_top", "signage_sub",
	"annotation_top", "annotation_bottom",
	"accent_color", "floor_color", "wall_color", "ceiling_color",
	"glass_color", "seam_color", "grout_color", "plinth_color",
	"mounted_artifact_scene", "mounted_lab_json",
	"lab_offset_z", "signage_wall", "show_chalkboard", "chalkboard_lookup",
	# catalyst family (vent / foe / crystal) — same issue as lab_room:
	# without these listed, "wave_size:5" became boolean `true` (= wave
	# of 1) and "emit_interval_s:2.0" collapsed to 1.0s. Applies to the
	# Catalyst_* / CatalystLab_* rings and any pedestal token.
	"emit_interval_s", "wave_size", "start_delay_s", "damage_percent",
	"require_catalyst_armed", "initial_state", "foe_mode", "critter_stage",
	"sequence", "all_modes", "start_mode", "unlock_to", "shooting_only",
	"active_mode", "clear_modes", "cage_color", "lease_s",
	# tentacle_placer params — same issue as lab_room: without these
	# listed, e.g. "travel_speed:0.6" gets misparsed as a transform
	# shorthand and the value becomes the boolean `true`, which then
	# converts to 0.0 when read as float — so the tentacle never moves.
	"place_positions", "sky_height", "rest_target", "travel_speed",
	"arrive_threshold", "dwell_seconds", "pyramid_size", "pyramid_height",
	"pyramid_color", "pyramid_lifetime", "cube_size", "cube_color",
	"body_color", "joint_ring_color", "show_pedestal", "show_claw",
	"pedestal_radius", "pedestal_height", "claw_finger_count",
	"claw_finger_length", "radial_segments", "base_radius", "tip_radius",
	"debug_log", "use_manual_ik",
	"claw_offset_segments", "wrist_rod_radius", "max_joint_angle_deg",
	# origin beam params — "beam_height:10.5" was parsed as a shorthand
	# transform (tutorial_id=beam_height, rotation 10.5) so the beam got
	# height true→1.0; listing them keeps key:numeric as key:value.
	"beam_height", "beam_radius", "beam_label",
	# fontana_puncture embed params
	"embed_artifact", "embed_mode",
	# CoordinateSystem3M / coordinate_line
	"tick_step", "axis_length", "axis_thickness", "display_scale",
	# wall_placard params
	"title", "meta", "body", "card_color", "ink_color", "accent",
	# chalkboard params
	"diagram", "lines", "board_width", "board_height", "board_color",
	# palm_scanner params
	"scan_active", "mounting", "scan_hold_seconds", "auto_connect_door", "scan_dwell",
	# "color" — the key registry `default_params` most often declares, and the one
	# a map token uses to override it. It has to be listed or an ALL-DIGIT hex is
	# misread as tutorial shorthand: "#color:112233" becomes tutorial_id "color"
	# with rotation 112233, and the colour is lost. Hexes containing a letter
	# ("FF6060", "4080FF") were never at risk because is_valid_float() rejects
	# them, which is why this went unnoticed. No token anywhere in the corpus
	# carries "#color:" today (2,826,608 cells scanned), so listing it moves no map.
	"color",
	# generic
	"no_collider",
]

# References
var parent_node: Node3D
var structure_component: GridStructureComponent
var utilities_component: GridUtilitiesComponent
var map_data_component: GridDataComponent  # Add reference to data component

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0
var current_palette: String = ""
var cache_artifact_registry: bool = true

# Interactable objects tracking
var interactable_objects: Dictionary = {}
var scene_cache: Dictionary = {}

# Artifact registry loaded from JSON - indexed by lookup_name
var grid_artifact_registry: Dictionary = {}

# Signals
signal interactables_generation_complete(interactable_count: int)
signal interactable_activated(object_id: String, position: Vector3, data: Dictionary)

func _ready():
	print("GridInteractablesComponent: Initialized with lookup_name validation")
	# Artifact registry will be loaded during initialization with map data

# Load artifact registries based on map configuration
func _load_artifact_registries() -> void:
	print("GridInteractablesComponent: ============ LOADING ARTIFACT REGISTRIES ============")
	print("GridInteractablesComponent: Starting artifact registry loading with lookup_name validation...")

	# Get artifact registries from map external references
	var artifact_paths: Array[String] = _get_artifact_registry_paths()
	var cache_key: String = _build_registry_cache_key(artifact_paths)

	if cache_artifact_registry and _artifact_registry_cache_by_key.has(cache_key):
		var cached_registry: Variant = _artifact_registry_cache_by_key.get(cache_key, {})
		if cached_registry is Dictionary:
			grid_artifact_registry = (cached_registry as Dictionary).duplicate(true)
			print("GridInteractablesComponent: Using cached artifact registry (%d artifacts)" % grid_artifact_registry.size())
			return

	grid_artifact_registry.clear()
	print("GridInteractablesComponent: Found %d registry paths to load" % artifact_paths.size())
	for path in artifact_paths:
		print("GridInteractablesComponent:   - %s" % path)

	var total_loaded: int = 0
	var validation_errors: Array[String] = []
	var validation_warnings: Array[String] = []

	for registry_path in artifact_paths:
		var loaded_count: int = _load_single_artifact_registry(registry_path, validation_errors, validation_warnings)
		total_loaded += loaded_count
		print("GridInteractablesComponent:   → Loaded %d artifacts from %s" % [loaded_count, registry_path])

	if cache_artifact_registry:
		_artifact_registry_cache_by_key[cache_key] = grid_artifact_registry.duplicate(true)

	# Report validation results
	if validation_errors.size() > 0:
		push_error("GridInteractablesComponent: VALIDATION ERRORS in artifact registries:")
		for error in validation_errors:
			push_error("  - %s" % error)

	if validation_warnings.size() > 0:
		print("GridInteractablesComponent: Validation warnings:")
		for warning in validation_warnings:
			print("  - %s" % warning)

	print("GridInteractablesComponent: ============================================")
	print("GridInteractablesComponent: ✅ TOTAL: Loaded %d validated artifacts from %d registries" % [total_loaded, artifact_paths.size()])
	print("GridInteractablesComponent: Final registry size: %d" % grid_artifact_registry.size())
	print("GridInteractablesComponent: ============================================")

func _build_registry_cache_key(paths: Array[String]) -> String:
	var sorted_paths: Array[String] = paths.duplicate()
	sorted_paths.sort()
	return "|".join(PackedStringArray(sorted_paths))

# Get artifact registry paths from map data and registry directory
func _get_artifact_registry_paths() -> Array[String]:
	var paths: Array[String] = []

	# Load all JSON files from the registry directory
	var dir = DirAccess.open(REGISTRY_DIR_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				paths.append(REGISTRY_DIR_PATH + file_name)
			file_name = dir.get_next()
	
	# 3. Try to get additional overrides from map's external references
	if map_data_component and map_data_component.json_loader:
		var external_refs = map_data_component.json_loader.map_data.get("external_references", {})
		var map_specific_registries = external_refs.get("artifact_registries", [])
		
		if map_specific_registries.size() > 0:
			print("GridInteractablesComponent: Adding map-specific registries: %s" % str(map_specific_registries))
			for path in map_specific_registries:
				if not paths.has(path):
					paths.append(str(path))
	
	return paths

# Load a single artifact registry file
func _load_single_artifact_registry(registry_path: String, validation_errors: Array, validation_warnings: Array) -> int:
	print("GridInteractablesComponent: Loading registry: %s" % registry_path)
	
	if not FileAccess.file_exists(registry_path):
		push_error("GridInteractablesComponent: Artifacts JSON file not found: %s" % registry_path)
		return 0
	
	var file = FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		push_error("GridInteractablesComponent: Could not open artifacts file: %s" % registry_path)
		return 0
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("GridInteractablesComponent: Failed to parse artifacts JSON: %s" % json.get_error_message())
		return 0
	
	var json_data = json.data
	var raw_artifacts = json_data.get("artifacts", {})
	
	if raw_artifacts.is_empty():
		push_warning("GridInteractablesComponent: No artifacts found in JSON file: %s" % registry_path)
		return 0
	
	var loaded_count = 0
	
	# Process and validate each artifact with lookup_name
	for artifact_key in raw_artifacts.keys():
		var artifact_data = raw_artifacts[artifact_key]

		# Skip comment entries (keys starting with _ that have string values)
		if artifact_key.begins_with("_") and typeof(artifact_data) == TYPE_STRING:
			continue

		# Validate artifact_data is a Dictionary
		if typeof(artifact_data) != TYPE_DICTIONARY:
			validation_errors.append("Artifact '%s' must be a Dictionary, got %s in %s" % [artifact_key, type_string(typeof(artifact_data)), registry_path])
			continue

		# Tolerant validation for in-progress artifact entries.
		var normalized_artifact_data: Dictionary = artifact_data.duplicate(true)
		var lookup_name := str(normalized_artifact_data.get("lookup_name", "")).strip_edges()
		if lookup_name.is_empty():
			lookup_name = artifact_key
			normalized_artifact_data["lookup_name"] = lookup_name
			validation_warnings.append("Artifact '%s' missing lookup_name in %s (defaulted to key)" % [artifact_key, registry_path])
		
		# Keep key consistency deterministic.
		if lookup_name != artifact_key:
			validation_warnings.append("Artifact key '%s' didn't match lookup_name '%s' in %s (using key)" % [artifact_key, lookup_name, registry_path])
			lookup_name = artifact_key
			normalized_artifact_data["lookup_name"] = lookup_name

		var raw_scene_path := str(normalized_artifact_data.get("scene", "")).strip_edges()
		var scene_path := _normalize_artifact_scene_path(raw_scene_path)
		# delegate_to: entries without `scene` are still valid if they
		# delegate to another registered artifact. The actual scene is
		# resolved at instantiation time via _resolve_artifact_scene_for_loading.
		var has_delegate := str(normalized_artifact_data.get("delegate_to", "")).strip_edges() != ""
		if scene_path.is_empty():
			if has_delegate:
				# Skip the placeholder substitution — keep delegate_to in the entry.
				pass
			else:
				scene_path = ARTIFACT_PLACEHOLDER_SCENE_PATH
				normalized_artifact_data["scene"] = scene_path
				normalized_artifact_data["artifact_type"] = "placeholder"
				normalized_artifact_data["placeholder_reason"] = "missing_scene_path"
				validation_warnings.append("Artifact '%s' missing scene in %s (using placeholder)" % [lookup_name, registry_path])
		else:
			normalized_artifact_data["scene"] = scene_path
			if scene_path != raw_scene_path:
				validation_warnings.append("Artifact '%s' scene normalized '%s' -> '%s' in %s" % [lookup_name, raw_scene_path, scene_path, registry_path])
		
		# Check for duplicates
		if grid_artifact_registry.has(lookup_name):
			validation_warnings.append("Duplicate artifact '%s' found in %s (overriding previous definition)" % [lookup_name, registry_path])
		
		# Validate lookup_name format
		if not _is_valid_lookup_name(lookup_name):
			validation_warnings.append("Artifact '%s' has non-standard lookup_name format (prefer snake_case) in %s" % [lookup_name, registry_path])
		
		# Store using lookup_name as key
		grid_artifact_registry[lookup_name] = normalized_artifact_data
		loaded_count += 1
		
		#print("  → Registered artifact: %s ('%s')" % [lookup_name, artifact_data.get("name", "Unnamed")])
	
	return loaded_count

# Validate lookup_name format (prefer snake_case)
func _is_valid_lookup_name(lookup_name: String) -> bool:
	# Check for snake_case pattern: lowercase letters, numbers, underscores only
	var regex = RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	return regex.search(lookup_name) != null

func _normalize_artifact_scene_path(scene_path: String) -> String:
	var normalized := scene_path.strip_edges()
	if normalized.is_empty():
		return ""
	
	if normalized.begins_with("res://"):
		return normalized
	
	if normalized.begins_with("commons/") or normalized.begins_with("algorithms/") or normalized.begins_with("tools/"):
		return "res://" + normalized.trim_prefix("/")
	
	return normalized

func _build_placeholder_artifact_info(lookup_name: String, reason: String, source_scene_path: String = "") -> Dictionary:
	var artifact_info: Dictionary = {
		"name": "Missing Artifact (%s)" % lookup_name,
		"lookup_name": lookup_name,
		"description": "Placeholder shown because artifact is not implemented or scene cannot be loaded yet.",
		"scene": ARTIFACT_PLACEHOLDER_SCENE_PATH,
		"artifact_type": "placeholder",
		"placeholder_reason": reason,
		"sequence": ""
	}
	if not source_scene_path.is_empty():
		artifact_info["source_scene_path"] = source_scene_path
	return artifact_info

func _coerce_artifact_info_to_placeholder(lookup_name: String, artifact_info: Dictionary, reason: String, source_scene_path: String = "") -> Dictionary:
	var merged_info: Dictionary = artifact_info.duplicate(true)
	merged_info["lookup_name"] = lookup_name
	merged_info["scene"] = ARTIFACT_PLACEHOLDER_SCENE_PATH
	merged_info["artifact_type"] = "placeholder"
	merged_info["placeholder_reason"] = reason
	if not source_scene_path.is_empty():
		merged_info["source_scene_path"] = source_scene_path
	if str(merged_info.get("name", "")).strip_edges().is_empty():
		merged_info["name"] = "Missing Artifact (%s)" % lookup_name
	if str(merged_info.get("description", "")).strip_edges().is_empty():
		merged_info["description"] = "Placeholder shown because artifact is not implemented or scene cannot be loaded yet."
	return merged_info

func _get_artifact_info_or_placeholder(lookup_name: String) -> Dictionary:
	if grid_artifact_registry.has(lookup_name):
		var artifact_info: Dictionary = grid_artifact_registry[lookup_name]
		if str(artifact_info.get("lookup_name", "")).strip_edges().is_empty():
			artifact_info["lookup_name"] = lookup_name
		return artifact_info
	
	push_warning("GridInteractablesComponent: Unknown artifact lookup_name '%s' (using placeholder)" % lookup_name)
	return _build_placeholder_artifact_info(lookup_name, "unknown_lookup_name")

func _resolve_artifact_scene_for_loading(lookup_name: String, artifact_info: Dictionary) -> Dictionary:
	var resolved_info: Dictionary = artifact_info.duplicate(true)

	# delegate_to support: when an artifact entry has delegate_to set, it
	# means "instantiate this OTHER artifact and pass me's delegate_params
	# as config." Used by /dna-promoted findings: a registry entry that
	# names an existing builder and supplies the per-instance parameters
	# without requiring per-finding scenes or central dispatchers.
	#
	# Example registry entry:
	#   "dna_facade_classical": {
	#     "delegate_to": "facade_builder",
	#     "delegate_params": { "preset": "classical" },
	#     ...
	#   }
	if resolved_info.has("delegate_to"):
		var target_lookup: String = String(resolved_info.get("delegate_to", "")).strip_edges()
		if not target_lookup.is_empty() and grid_artifact_registry.has(target_lookup):
			var target_info: Dictionary = grid_artifact_registry[target_lookup].duplicate(true)
			# Capture the delegated params for downstream config-data merge.
			var delegate_params: Variant = resolved_info.get("delegate_params", {})
			if delegate_params is Dictionary:
				target_info["__delegate_params__"] = delegate_params
			# Preserve identity from the original entry (so labels still read
			# right in the inspector / catalog), but use the target's scene.
			target_info["__delegated_from__"] = lookup_name
			if resolved_info.has("name"):
				target_info["name"] = resolved_info["name"]
			resolved_info = target_info

	var scene_path := _normalize_artifact_scene_path(str(resolved_info.get("scene", "")).strip_edges())
	
	if scene_path.is_empty():
		resolved_info = _coerce_artifact_info_to_placeholder(lookup_name, resolved_info, "missing_scene_path")
		return {
			"scene_path": ARTIFACT_PLACEHOLDER_SCENE_PATH,
			"artifact_info": resolved_info
		}
	
	if not scene_path.begins_with("res://"):
		resolved_info = _coerce_artifact_info_to_placeholder(lookup_name, resolved_info, "unsupported_scene_path", scene_path)
		return {
			"scene_path": ARTIFACT_PLACEHOLDER_SCENE_PATH,
			"artifact_info": resolved_info
		}
	
	if scene_path != ARTIFACT_PLACEHOLDER_SCENE_PATH and not ResourceLoader.exists(scene_path):
		resolved_info = _coerce_artifact_info_to_placeholder(lookup_name, resolved_info, "scene_file_missing", scene_path)
		return {
			"scene_path": ARTIFACT_PLACEHOLDER_SCENE_PATH,
			"artifact_info": resolved_info
		}
	
	resolved_info["scene"] = scene_path
	return {
		"scene_path": scene_path,
		"artifact_info": resolved_info
	}

# Get artifact info by lookup_name
func get_artifact_info(lookup_name: String) -> Dictionary:
	if not grid_artifact_registry.has(lookup_name):
		push_warning("GridInteractablesComponent: Unknown artifact lookup_name: '%s'" % lookup_name)
		print("GridInteractablesComponent: Available artifacts: %s" % str(grid_artifact_registry.keys()))
		return {}
	
	return grid_artifact_registry[lookup_name]

# Check if artifact exists by lookup_name
func has_artifact(lookup_name: String) -> bool:
	return grid_artifact_registry.has(lookup_name)

# Initialize with references and settings
func initialize(grid_parent: Node3D, struct_component: GridStructureComponent, util_component: GridUtilitiesComponent, data_component: GridDataComponent, settings: Dictionary = {}):
	parent_node = grid_parent
	structure_component = struct_component
	utilities_component = util_component
	map_data_component = data_component
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	current_palette = settings.get("palette", "")
	cache_artifact_registry = bool(settings.get("cache_artifact_registry", true))

	# Load artifact registries based on map configuration
	_load_artifact_registries()

	# Computation budget (gated: only maps that declare settings.proximity_lod;
	# see commons/grid/ProximityLOD.gd). One manager per grid parent, replaced
	# on re-initialize so a flagless map after a flagged one is clean.
	var old_plod = parent_node.get_node_or_null("ProximityLOD")
	if old_plod:
		old_plod.queue_free()
	var plod = settings.get("proximity_lod", null)
	if plod != null and str(plod).to_lower() not in ["false", "0", "off"]:
		var mgr := ProximityLODScript.new()
		mgr.name = "ProximityLOD"
		mgr.configure(plod)
		parent_node.add_child(mgr)
		print("GridInteractablesComponent: ProximityLOD armed (radius=%s)" % str(mgr.radius))

	print("GridInteractablesComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

## Read a runtime flag from ada_run/runtime_flags.json. Mirrors GridSystem's
## helper so we can suppress interactable spawning during clean captures
## without depending on GridSystem's lifetime.
func _runtime_flag_enabled(flag_name: String, default_value: bool) -> bool:
	var path := "res://ada_run/runtime_flags.json"
	if not FileAccess.file_exists(path):
		return default_value
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return default_value
	var raw := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(raw) != OK: return default_value
	var data = json.data
	if data is Dictionary and data.has(flag_name):
		return bool(data[flag_name])
	return default_value


# Generate interactables from data using lookup_name system
func generate_interactables(interactable_data):
	# Capture-mode bypass: skip spawning entire artifact layer when the
	# encyclopedia capture wrapper sets artifacts_enabled=false. This
	# leaves the cube grid visible without huge artifacts (pillar carpets,
	# rainbow arcs, etc.) flooding the frame.
	if not _runtime_flag_enabled("artifacts_enabled", true):
		print("GridInteractablesComponent: artifacts_enabled=false — skipping interactable spawn")
		return
	if not interactable_data:
		print("GridInteractablesComponent: No interactable data provided")
		return
	
	# Check for different property names (layout_data vs interactable_data)
	var interactable_layout = null
	if interactable_data.has_method("get") and interactable_data.get("layout_data"):
		interactable_layout = interactable_data.layout_data
	elif interactable_data.has_method("get") and interactable_data.get("interactable_data"):
		interactable_layout = interactable_data.interactable_data
	
	if not interactable_layout:
		print("GridInteractablesComponent: No interactable layout found")
		return
	
	print("GridInteractablesComponent: Generating interactables using lookup_name system")
	
	var total_size = cube_size + gutter
	var interactable_count = 0
	var placement_errors = []
	var placement_warnings = []
	
	# Get grid dimensions from structure component
	var dimensions = structure_component.get_grid_dimensions()
	
	for z in range(min(dimensions.z, interactable_layout.size())):
		var row = interactable_layout[z]
		for x in range(min(dimensions.x, row.size())):
			var token = str(row[x]).strip_edges()
			
			if token != " " and not token.is_empty():
				# `#` prefix = COMMENT. The token stays in map_data.json
				# as reference / intent ("I considered putting X here") but
				# is skipped at generation time. Strip a single leading `#`
				# to expose what's commented out for logging only — don't
				# parse or place anything.
				if token.begins_with("#"):
					print("GridInteractablesComponent: skipping commented token '%s' at (%d,%d)" % [token.substr(1), x, z])
					continue

				# Check for special prefixes BEFORE parsing (mc:, gridagent:, etc.)
				# These use the colon as part of their identifier, not as parameter separator

				# Check for custom Marching Cubes syntax mc:shape_name
				if token.begins_with("mc:"):
					var parsed = _parse_interactable_token(token)
					var overrides: Dictionary = parsed.get("overrides", {})
					var config_data: Dictionary = parsed.get("config_data", {})
					
					var y_pos = structure_component.find_highest_y_at(x, z)
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1
						
					if _place_marching_cubes_object(x, y_pos, z, token, total_size, overrides, config_data):
						interactable_count += 1
					else:
						placement_errors.append("Failed to place Marching Cubes object '%s' at (%d,%d,%d)" % [token, x, y_pos, z])
					continue
				
				# Check for Grid Agent syntax gridagent:tier
				if token.begins_with("gridagent:"):
					var y_pos = structure_component.find_highest_y_at(x, z)
					if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
						y_pos += 1

					# Grid agent tokens have custom parsing (tier + optional #config stack).
					if _place_grid_agent(x, y_pos, z, token, total_size):
						interactable_count += 1
					else:
						placement_errors.append("Failed to place grid agent '%s' at (%d,%d,%d)" % [token, x, y_pos, z])
					continue

				# Check for Critical Info / Dialectic Panel syntax criticalinfo:name:rotation:scale
				if token.begins_with("criticalinfo:"):
					var parts = token.split(":")
					var dialectic_name = parts[1] if parts.size() > 1 else ""
					var rotation = float(parts[2]) if parts.size() > 2 else 0.0
					var scale_factor = float(parts[3]) if parts.size() > 3 else 1.0

					var y_pos = structure_component.find_highest_y_at(x, z)
					var origin = Vector3(x * total_size, GridCommon.surface_world_y(y_pos, total_size), z * total_size)   # seat on the cube TOP — was y_pos*total_size, half a cube high

					if _place_dialectic_panels(dialectic_name, origin, rotation, scale_factor):
						interactable_count += 1
						print("GridInteractablesComponent: ✅ Placed dialectic panels '%s' at (%d,%d,%d)" % [dialectic_name, x, y_pos, z])
					else:
						placement_errors.append("Failed to place dialectic panels '%s' at (%d,%d,%d)" % [dialectic_name, x, y_pos, z])
					continue

				# Multi-piece curated cluster: cluster:<name>:<rotation> — additive, mirrors mc:/gridagent:/criticalinfo:
				if token.begins_with("cluster:"):
					var cparts = token.split(":")
					var cluster_name = cparts[1] if cparts.size() > 1 else ""
					var cluster_rot = float(cparts[2]) if cparts.size() > 2 else 0.0
					var cy_pos = structure_component.find_highest_y_at(x, z)
					if utilities_component and utilities_component.has_utility_at(x, cy_pos, z):
						cy_pos += 1
					if _place_cluster(x, cy_pos, z, cluster_name, cluster_rot, total_size):
						interactable_count += 1
					else:
						placement_errors.append("Failed to place cluster '%s' at (%d,%d,%d)" % [cluster_name, x, cy_pos, z])
					continue

				# Normal artifact handling (parse token for regular artifacts)
				var parsed = _parse_interactable_token(token)
				var lookup_name: String = parsed.get("lookup_name", "")
				var overrides: Dictionary = parsed.get("overrides", {})
				var config_data: Dictionary = parsed.get("config_data", {})
				var tag: String = parsed.get("tag", "")
				var trigger_action: String = parsed.get("trigger_action", "")
				if lookup_name.is_empty():
					placement_errors.append("Invalid artifact token '%s' at (%d,%d)" % [token, x, z])
					continue

				var y_pos = structure_component.find_highest_y_at(x, z)
				
				# Adjust for utilities at same position
				if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
					y_pos += 1
				
				if not has_artifact(lookup_name):
					placement_warnings.append("Unknown artifact lookup_name '%s' at (%d,%d) (placing placeholder)" % [lookup_name, x, z])
				
				if _place_artifact(x, y_pos, z, lookup_name, total_size, overrides, config_data, tag, trigger_action):
					interactable_count += 1
				else:
					placement_errors.append("Failed to place artifact '%s' at (%d,%d,%d)" % [lookup_name, x, y_pos, z])
	
	# Spine force-include overlay (additive; /artifact-editor writes the flag).
	# Gated by data: with no spine_force_include entries in any registry this
	# is a single in-memory scan and an early return — maps are untouched.
	interactable_count += _apply_spine_force_includes(total_size)

	# Report results
	if placement_errors.size() > 0:
		print("GridInteractablesComponent: Placement errors:")
		for error in placement_errors:
			print("  - %s" % error)
		print("GridInteractablesComponent: Available artifacts: %s" % str(grid_artifact_registry.keys()))
	
	if placement_warnings.size() > 0:
		print("GridInteractablesComponent: Placement warnings:")
		for warning in placement_warnings:
			print("  - %s" % warning)
	
	print("GridInteractablesComponent: ✅ Successfully placed %d interactables" % interactable_count)
	interactables_generation_complete.emit(interactable_count)

# ── Spine force-include ─────────────────────────────────────────────────────
# Registry entries may carry `spine_force_include: true` (+ optional
# `spine_force_cell: "x,z"`), written by the encyclopedia's /artifact-editor.
# After normal placement, every flagged artifact is injected into the current
# map IF the map belongs to a spine sequence — a runtime overlay, no map file
# is edited. Additive and data-gated: no flagged entries → early return.

var _spine_maps_cache: Dictionary = {}   # map_name -> true (lazy, once)

func _spine_map_set() -> Dictionary:
	if not _spine_maps_cache.is_empty():
		return _spine_maps_cache
	var spine_file := FileAccess.open("res://commons/maps/curriculum_spine.json", FileAccess.READ)
	if spine_file == null:
		return _spine_maps_cache
	var spine_json = JSON.parse_string(spine_file.get_as_text())
	spine_file.close()
	if not (spine_json is Dictionary):
		return _spine_maps_cache
	var seqs = spine_json.get("spine", {}).get("sequences", [])
	if not (seqs is Array):
		return _spine_maps_cache
	for s in seqs:
		if not (s is Dictionary):
			continue
		var seq_name := str(s.get("name", ""))
		if seq_name.is_empty():
			continue
		var seq_file := FileAccess.open("res://commons/maps/sequences/%s.json" % seq_name, FileAccess.READ)
		if seq_file == null:
			continue
		var seq_json = JSON.parse_string(seq_file.get_as_text())
		seq_file.close()
		if not (seq_json is Dictionary):
			continue
		var maps = seq_json.get("sequences", {}).get(seq_name, {}).get("maps", [])
		if maps is Array:
			for m in maps:
				_spine_maps_cache[str(m)] = true
	print("GridInteractablesComponent: spine map set loaded (%d maps)" % _spine_maps_cache.size())
	return _spine_maps_cache

func _apply_spine_force_includes(total_size: float) -> int:
	# 1) cheap scan — the data gate
	var flagged: Array[String] = []
	for lookup_name in grid_artifact_registry.keys():
		var info = grid_artifact_registry[lookup_name]
		if info is Dictionary and info.get("spine_force_include", false):
			flagged.append(str(lookup_name))
	if flagged.is_empty():
		return 0

	# 2) only spine maps receive the overlay. Match on the map's IDENTIFIER
	# (folder name / map_info.lookup_name), never map_info.name — that is a
	# display title ("Bridges and Islands"), not the id the spine lists.
	var map_name := ""
	if map_data_component:
		map_name = str(map_data_component.map_name)
	if map_name.is_empty() and map_data_component and map_data_component.json_loader:
		map_name = str(map_data_component.json_loader.map_data.get("map_info", {}).get("lookup_name", ""))
	if map_name.is_empty() or not _spine_map_set().has(map_name):
		return 0

	# 3) collect lookups already present so forcing never doubles
	var present := {}
	for obj in interactable_objects.values():
		if is_instance_valid(obj) and obj.has_meta("artifact_lookup_name"):
			present[str(obj.get_meta("artifact_lookup_name"))] = true

	# 4) walkable free cells from the map's own layers, centre-out
	var layers = {}
	if map_data_component and map_data_component.json_loader:
		layers = map_data_component.json_loader.map_data.get("layers", {})
	var structure = layers.get("structure", [])
	var utilities = layers.get("utilities", [])
	var inter = layers.get("interactables", [])
	if structure.is_empty():
		return 0
	var depth: int = structure.size()
	var width: int = 0
	if structure[0] is Array:
		width = (structure[0] as Array).size()
	var free_cells: Array[Vector2i] = []
	for z in range(depth):
		for x in range(width):
			var s_cell: String = ""
			if structure[z] is Array and x < (structure[z] as Array).size():
				s_cell = str((structure[z] as Array)[x]).strip_edges()
			if not s_cell.is_valid_int() or int(s_cell) <= 0:
				continue   # void or non-walkable
			var u_cell: String = ""
			if z < utilities.size() and utilities[z] is Array and x < (utilities[z] as Array).size():
				u_cell = str((utilities[z] as Array)[x]).strip_edges()
			if not u_cell.is_empty():
				continue
			var i_cell: String = ""
			if z < inter.size() and inter[z] is Array and x < (inter[z] as Array).size():
				i_cell = str((inter[z] as Array)[x]).strip_edges()
			if not i_cell.is_empty():
				continue
			free_cells.append(Vector2i(x, z))
	var centre := Vector2(float(width) * 0.5, float(depth) * 0.5)
	free_cells.sort_custom(func(a, b):
		return Vector2(a).distance_to(centre) < Vector2(b).distance_to(centre))

	# 5) place each flagged artifact
	var placed := 0
	for lookup in flagged:
		if present.has(lookup):
			continue   # the map already carries it naturally
		var cell := Vector2i(-1, -1)
		var wanted := str(grid_artifact_registry[lookup].get("spine_force_cell", ""))
		if not wanted.is_empty():
			var parts := wanted.split(",")
			if parts.size() == 2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
				var cand := Vector2i(int(parts[0]), int(parts[1]))
				if free_cells.has(cand):
					cell = cand
		if cell.x < 0 and not free_cells.is_empty():
			cell = free_cells[0]
		if cell.x < 0:
			print("GridInteractablesComponent: force-include '%s' skipped — no free cell in '%s'" % [lookup, map_name])
			continue
		free_cells.erase(cell)
		var y_pos = structure_component.find_highest_y_at(cell.x, cell.y)
		if utilities_component and utilities_component.has_utility_at(cell.x, y_pos, cell.y):
			y_pos += 1
		if _place_artifact(cell.x, y_pos, cell.y, lookup, total_size):
			placed += 1
			print("GridInteractablesComponent: ✅ force-included '%s' at (%d,%d) in spine map '%s'" % [lookup, cell.x, cell.y, map_name])
	return placed


# Place a Marching Cubes object using API
func _place_cluster(x: int, y: int, z: int, cluster_name: String, rotation: float, total_size: float) -> bool:
	# Expand a curated cluster (commons/data/curated_walls/clusters/<name>.json) at this cell with a
	# Y-rotation, via a ClusterResolver child. Additive: reached ONLY by the new cluster: token prefix,
	# so no existing grid behaviour is touched.
	if cluster_name == "":
		return false
	var resolver = ClusterResolverScript.new()
	parent_node.add_child(resolver)
	resolver.position = Vector3(x * total_size, GridCommon.surface_world_y(y, total_size), z * total_size)   # LOCAL (under the GridSystem), like _place_artifact; surface_world_y seats it on the cube TOP (was y*total_size, half a cube high), and LOCAL avoids the GridSystem's own y-offset that floated it earlier
	resolver.apply_grid_config({"cluster": cluster_name, "rotation": rotation})
	interactable_objects[Vector3i(x, y, z)] = resolver
	print("GridInteractablesComponent: ✅ Placed cluster '%s' at (%d,%d,%d)" % [cluster_name, x, y, z])
	return true


func _place_marching_cubes_object(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}) -> bool:
	var world_pos = Vector3(x * total_size, GridCommon.surface_world_y(y, total_size), z * total_size)   # seat on the cube TOP — was y*total_size, half a cube above the surface (center-origin cubes)
	
	# Determine if object should be pickable/grabbable
	var is_pickable = false
	if config_data.has("pickable"):
		var val = config_data["pickable"]
		is_pickable = (str(val).to_lower() == "true")
	elif config_data.has("grab"):
		var val = config_data["grab"]
		is_pickable = (str(val).to_lower() == "true")
	
	# Create object using API
	var mc_object = MarchingCubesAPI.create(lookup_name, world_pos, 1.0, is_pickable)
	if not mc_object:
		return false
		
	# Apply common transforms
	if overrides.has("y_position"):
		mc_object.position.y += float(overrides.get("y_position", 0.0))
		
	if overrides.has("uniform_scale"):
		var s = float(overrides.get("uniform_scale", 1.0))
		mc_object.scale = Vector3.ONE * s
		print("GridInteractables: Applied uniform scale %f -> Final scale: %s" % [s, str(mc_object.scale)])
		
	# Apply rotation
	if overrides.has("rotation_y_degrees"):
		mc_object.rotation_degrees.y = float(overrides.get("rotation_y_degrees", 0.0))
	if overrides.has("rotation_x_degrees"):
		mc_object.rotation_degrees.x = float(overrides.get("rotation_x_degrees", 0.0))
	if overrides.has("rotation_z_degrees"):
		mc_object.rotation_degrees.z = float(overrides.get("rotation_z_degrees", 0.0))

	# Apply material if specified
	if config_data.has("material"):
		print("GridInteractables: Applying material '%s' to '%s'" % [str(config_data.get("material")), lookup_name])
		MarchingCubesAPI.apply_material(mc_object, str(config_data.get("material")))
	else:
		print("GridInteractables: No material in config_data for '%s'. Data keys: %s" % [lookup_name, config_data.keys()])

	parent_node.add_child(mc_object)
	interactable_objects[Vector3i(x, y, z)] = mc_object
	
	print("  ✅ Placed Marching Cubes object '%s' at (%d,%d,%d)" % [lookup_name, x, y, z])
	return true

func _parse_grid_agent_token(token: String) -> Dictionary:
	token = _normalize_legacy_semicolon_token(token)
	var result := {"tier": "", "overrides": {}, "config_data": {}}
	
	var hash_index = token.find("#")
	var head = token if hash_index == -1 else token.substr(0, hash_index)
	var config_tail = "" if hash_index == -1 else token.substr(hash_index + 1)
	
	var head_parts = head.split(":", false)
	if head_parts.size() < 2:
		return result
	if head_parts[0].strip_edges().to_lower() != "gridagent":
		return result
	
	result["tier"] = head_parts[1].strip_edges().to_lower()
	
	# gridagent:tier[:rotation[:y_offset[:scale]]]
	if head_parts.size() >= 3 and head_parts[2].strip_edges().is_valid_float():
		result["overrides"]["rotation_y_degrees"] = float(head_parts[2].strip_edges())
	if head_parts.size() >= 4 and head_parts[3].strip_edges().is_valid_float():
		result["overrides"]["y_position"] = float(head_parts[3].strip_edges())
	if head_parts.size() >= 5 and head_parts[4].strip_edges().is_valid_float():
		result["overrides"]["uniform_scale"] = float(head_parts[4].strip_edges())
	
	# Optional config syntax:
	# gridagent:copy#stack:array,mirror,twist#mirror_axis:x#twist_angle:18
	if not config_tail.is_empty():
		var config_parts = config_tail.split("#", false)
		for part in config_parts:
			var config_part = part.strip_edges()
			if config_part.is_empty():
				continue
			if config_part.find(":") != -1:
				var kv = config_part.split(":", false, 1)
				if kv.size() == 2:
					result["config_data"][kv[0].strip_edges()] = kv[1].strip_edges()
				else:
					result["config_data"][config_part] = true
			else:
				result["config_data"][config_part] = true
	
	return result

# Place a Grid Agent using gridagent:tier syntax
func _place_grid_agent(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}) -> bool:
	var parsed = _parse_grid_agent_token(lookup_name)
	var tier = str(parsed.get("tier", "")).strip_edges()
	if tier.is_empty():
		print("GridInteractablesComponent: Invalid grid agent format: %s" % lookup_name)
		return false
	
	var merged_overrides: Dictionary = parsed.get("overrides", {}).duplicate(true)
	if not overrides.is_empty():
		merged_overrides.merge(overrides, true)
	
	var merged_config: Dictionary = parsed.get("config_data", {}).duplicate(true)
	if not config_data.is_empty():
		merged_config.merge(config_data, true)
	
	# Load appropriate agent scene based on tier
	var scene_path = "res://commons/hazards/gridagent/variants/grid_agent_%s.tscn" % tier
	if not ResourceLoader.exists(scene_path):
		# Fallback to base agent
		scene_path = "res://commons/hazards/gridagent/grid_agent_base.tscn"
		print("GridInteractablesComponent: Tier-specific scene not found, using base agent: %s" % scene_path)
	
	if not ResourceLoader.exists(scene_path):
		print("GridInteractablesComponent: Grid agent base scene not found: %s" % scene_path)
		return false
	
	var agent_scene = load(scene_path)
	if agent_scene == null or not (agent_scene is PackedScene):
		print("GridInteractablesComponent: Failed to load grid agent scene: %s" % scene_path)
		return false
	var agent = agent_scene.instantiate()
	
	# Position
	var world_pos = Vector3(x * total_size, GridCommon.surface_world_y(y, total_size), z * total_size)   # seat on the cube TOP — was y*total_size, half a cube above the surface (center-origin cubes)
	agent.position = world_pos
	
	# Apply overrides (rotation, y_offset, scale)
	if merged_overrides.has("rotation_y_degrees"):
		agent.rotation_degrees.y = float(merged_overrides.get("rotation_y_degrees", 0.0))
	if merged_overrides.has("y_position"):
		agent.position.y += float(merged_overrides.get("y_position", 0.0))
	if merged_overrides.has("uniform_scale"):
		var s = float(merged_overrides.get("uniform_scale", 1.0))
		agent.scale = Vector3.ONE * s
	
	# Set agent metadata
	agent.set_meta("agent_tier", tier)
	agent.set_meta("spawn_position", Vector3i(x, y, z))
	if not merged_config.is_empty():
		agent.set_meta("agent_config", merged_config.duplicate(true))
	
	# Initialize agent if it has setup methods
	if agent.has_method("set_tier"):
		agent.set_tier(tier)
	if not merged_config.is_empty() and agent.has_method("configure_modifier_stack"):
		agent.configure_modifier_stack(merged_config)
	
	# Add to scene
	parent_node.add_child(agent)
	interactable_objects[Vector3i(x, y, z)] = agent
	
	print("  ✅ Placed grid agent '%s' (tier: %s) at (%d,%d,%d)" % [lookup_name, tier, x, y, z])
	return true

# Place dialectic panels using DialecticPanelGenerator
func _place_dialectic_panels(dialectic_name: String, origin: Vector3, rotation: float, scale_factor: float) -> bool:
	if dialectic_name.is_empty():
		push_error("GridInteractablesComponent: Empty dialectic name provided")
		return false

	# Create the generator node
	var generator = DialecticPanelGenerator.new()
	generator.name = "DialecticPanels_%s" % dialectic_name

	# Add to parent first so it's in the scene tree
	parent_node.add_child(generator)

	# Generate panels from the dialectic JSON
	var success = generator.generate_from_dialectic(dialectic_name, origin, rotation, scale_factor)

	if not success:
		generator.queue_free()
		return false

	print("GridInteractablesComponent: ✅ Generated %d dialectic panels for '%s'" % [generator.get_panel_count(), dialectic_name])
	return true

# Artifact "packaging" — grounding furniture + a framed caption spawned around an artifact from
# its spatial_needs. GATED: only runs when ProjectSettings "ada/packaging/auto_spawn" == true
# (default false), so existing maps are unchanged until you switch it on. preload (not the global
# class_name) so it resolves headless. See commons/artifacts/_hangar/.
const PackagingResolver := preload("res://commons/artifacts/_hangar/packaging_resolver.gd")
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const LabelFramer := preload("res://commons/grid/LabelFramer.gd")
const ProximityLODScript := preload("res://commons/grid/ProximityLOD.gd")


# Text hygiene (Palle: all hanging Label3D become 2D-in-3D boards/plates
# integrated in the artifact — the artifact_readout_screen principle applied
# at the meeting point). Deferred so labels created inside the artifact's own
# _ready are caught too. Safe to repeat (per-label meta marker).
func _frame_labels_deferred(node: Node) -> void:
	if is_instance_valid(node):
		LabelFramer.frame_labels(node)


# Suppress standalone-demo chrome on an embedded artifact: hide screen-space CanvasLayers
# (2D overlays have no place in a VR map) and de-activate the artifact's own Camera3D so it
# can't steal the player's view. Recurses the whole subtree. Safe to call more than once.
func _dress_adjust(node: Node3D, delta: Vector3) -> void:
	## Deferred transform nudge for the dress keys — runs after _auto_ground
	## (FIFO), so the plinth lift / offset stands on the grounded seat.
	if node != null and is_instance_valid(node):
		node.position += delta


func _suppress_embedded_chrome(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for child in node.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
		elif child is Camera3D:
			(child as Camera3D).current = false
		_suppress_embedded_chrome(child)

# Place a single artifact using lookup_name
func _place_artifact(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}, tag: String = "", trigger_action: String = "") -> bool:
	var world_pos = Vector3(x * total_size, GridCommon.surface_world_y(y, total_size), z * total_size)   # seat on the cube TOP — was y*total_size, half a cube above the surface (center-origin cubes)
	
	var artifact_info = _get_artifact_info_or_placeholder(lookup_name)
	if artifact_info.is_empty():
		return false
	
	var scene_resolution: Dictionary = _resolve_artifact_scene_for_loading(lookup_name, artifact_info)
	artifact_info = scene_resolution.get("artifact_info", artifact_info)
	var scene_path: String = str(scene_resolution.get("scene_path", "")).strip_edges()
	if scene_path.is_empty():
		print("GridInteractablesComponent: WARNING - Could not resolve scene path for artifact '%s'" % lookup_name)
		return false
	
	var artifact_object = _load_and_instantiate_artifact(scene_path)
	if not artifact_object:
		if scene_path != ARTIFACT_PLACEHOLDER_SCENE_PATH:
			print("GridInteractablesComponent: WARNING - Failed to load scene for '%s', trying placeholder" % lookup_name)
			artifact_info = _coerce_artifact_info_to_placeholder(lookup_name, artifact_info, "instantiate_failed", scene_path)
			artifact_object = _load_and_instantiate_artifact(ARTIFACT_PLACEHOLDER_SCENE_PATH)
		if not artifact_object:
			print("GridInteractablesComponent: WARNING - Failed to load placeholder scene for artifact '%s'" % lookup_name)
			return false
	
	# Handle visibility override from artifact_definitions
	if artifact_info.has("visible"):
		var should_be_visible = artifact_info.get("visible", true)
		if "visible" in artifact_object:
			artifact_object.visible = should_be_visible
			if not should_be_visible:
				print("    Set artifact '%s' to invisible (from artifact_definitions)" % lookup_name)
	
	# Handle different node types (Node3D vs Control)
	if artifact_object is Node3D:
		# Position the 3D artifact (base grid position)
		artifact_object.position = world_pos
		
		# Apply position/rotation/scale from artifact definition
		_apply_artifact_transform(artifact_object, artifact_info)

		# Apply per-instance overrides for 3D objects
		
		# Apply Y position override (e.g., random_number_book_page_1955:0:2.5:1.2 → Y offset +2.5)
		if overrides.has("y_position"):
			var y_offset = float(overrides.get("y_position", 0.0))
			artifact_object.position.y += y_offset
			print("    Applied Y position offset: +%s" % str(y_offset))
		
		# Apply uniform scale override (e.g., random_number_book_page_1955:0:2.5:1.2 → scale all axes by 1.2)
		if overrides.has("uniform_scale"):
			var scale_factor = float(overrides.get("uniform_scale", 1.0))
			artifact_object.scale *= scale_factor
			print("    Applied uniform scale: %s" % str(scale_factor))
		
		# Apply rotation overrides (Z, X, Y axes)
		var rotation_changed = false
		var current_rotation = artifact_object.rotation_degrees

		if overrides.has("rotation_z_degrees"):
			current_rotation.z = float(overrides.get("rotation_z_degrees", 0.0))
			rotation_changed = true
		if overrides.has("rotation_x_degrees"):
			current_rotation.x = float(overrides.get("rotation_x_degrees", 0.0))
			rotation_changed = true
		if overrides.has("rotation_y_degrees"):
			# Use rotate_y() to properly rotate around Y-axis, adding to existing rotation
			# This works correctly even when the scene has a transform matrix
			var y_rotation = float(overrides.get("rotation_y_degrees", 0.0))
			artifact_object.rotate_y(deg_to_rad(y_rotation))
			rotation_changed = true
			# Also try to set an exported yaw property if available (legacy support)
			_try_set_property(artifact_object, "yaw_degrees", artifact_object.rotation_degrees.y)

		if rotation_changed:
			# Only update rotation_degrees if we changed Z or X (Y is handled by rotate_y above)
			if overrides.has("rotation_z_degrees") or overrides.has("rotation_x_degrees"):
				artifact_object.rotation_degrees = current_rotation
			print("    Applied rotation: Z=%s X=%s Y=%s" % [artifact_object.rotation_degrees.z, artifact_object.rotation_degrees.x, artifact_object.rotation_degrees.y])

		# Apply continuous rotation flags
		if overrides.has("continuous_rotation_z") or overrides.has("continuous_rotation_x") or overrides.has("continuous_rotation_y"):
			var cont_z = overrides.get("continuous_rotation_z", false)
			var cont_x = overrides.get("continuous_rotation_x", false)
			var cont_y = overrides.get("continuous_rotation_y", false)

			# Add continuous rotation script
			_add_continuous_rotation(artifact_object, cont_z, cont_x, cont_y)
			print("    Applied continuous rotation: Z=%s X=%s Y=%s" % [cont_z, cont_x, cont_y])
			
	elif artifact_object is Control:
		# Handle 2D/UI artifacts (like the algorithm overview)
		# For Control nodes, position them to fill the screen or use anchors
		artifact_object.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		print("    Applied fullscreen preset for Control artifact")
		
		# Apply scale override for Control nodes differently
		if overrides.has("uniform_scale"):
			var scale_factor = float(overrides.get("uniform_scale", 1.0))
			artifact_object.scale = Vector2(scale_factor, scale_factor)
			print("    Applied uniform scale for Control: %s" % str(scale_factor))
	else:
		print("GridInteractablesComponent: WARNING - Unknown artifact node type: %s" % artifact_object.get_class())

	# Apply per-instance label text if provided (e.g., level_entrance:90|Level 3)
	if overrides.has("label_text"):
		var label_text = str(overrides.get("label_text", ""))
		_try_set_property(artifact_object, "label_text", label_text)
		# Fallback: update a Label3D child if present
		var label_node = artifact_object.find_child("Label3D", true, false)
		if label_node and (label_node is Label3D):
			label_node.text = label_text
		print("    Applied label text: '%s'" % label_text)
	
	# Set artifact metadata using both lookup_name and display name
	artifact_object.set_meta("artifact_lookup_name", lookup_name)
	artifact_object.set_meta("artifact_id", lookup_name)  # For compatibility
	artifact_object.set_meta("artifact_name", artifact_info.get("name", lookup_name))
	artifact_object.set_meta("artifact_type", artifact_info.get("artifact_type", "unknown"))
	artifact_object.set_meta("description", artifact_info.get("description", ""))
	artifact_object.set_meta("sequence", artifact_info.get("sequence", ""))
	artifact_object.set_meta("is_placeholder_artifact", str(artifact_info.get("artifact_type", "")) == "placeholder")
	if artifact_info.has("placeholder_reason"):
		artifact_object.set_meta("placeholder_reason", str(artifact_info.get("placeholder_reason", "")))
	if artifact_info.has("source_scene_path"):
		artifact_object.set_meta("source_scene_path", str(artifact_info.get("source_scene_path", "")))
	
	# Update labels if they exist
	_update_artifact_labels(artifact_object, lookup_name, artifact_info)
	
	# Connect signals if artifact has them
	_connect_artifact_signals(artifact_object, lookup_name)
	
	# Config precedence, weakest first:
	#
	#   1. registry `default_params`  — what the artifact ENTRY declares it is
	#   2. `delegate_params`          — what a delegate_to entry asks of its host
	#   3. `config_data`              — what THIS map token says, which always wins
	#
	# (1) is new here and is the whole of this repair. The registry declared
	# default_params on exactly SEVEN of 2,691 artifacts and no loader had ever
	# read them, so the declaration was dead data. The visible cost was the QFEP
	# formula: grab_sphere_E / _F / _lambda / _phi are four registry names on ONE
	# scene declaring four distinct colours, and with nothing consuming them all
	# four stood in qfeplaboratory as identical pink pellets. E, F and λ are meant
	# to be different terms of one equation.
	#
	# Routed through this channel and not through an artifact's DNA axis on
	# purpose: an axis value would then also decide WHICH TERM the object is,
	# which is not a staging choice but an identity one.
	#
	# GATED BY DATA. `default_params` absent (2,684 of 2,691 entries) leaves
	# merged_config exactly as it was built before — {} plus delegate params plus
	# token params — and _apply_artifact_config is called under exactly the same
	# condition. Nothing without the new key can move.
	var merged_config: Dictionary = {}
	var default_params: Variant = artifact_info.get("default_params", null)
	if default_params is Dictionary:
		merged_config = (default_params as Dictionary).duplicate(true)
	# Deep-duplicated on the way in, as before, so a nested value in a registry
	# entry can never be mutated through the metadata we hand the artifact.
	var delegate_params: Variant = artifact_info.get("__delegate_params__", null)
	if delegate_params is Dictionary:
		merged_config.merge((delegate_params as Dictionary).duplicate(true), true)
	for k in config_data.keys():
		merged_config[k] = config_data[k]
	if not merged_config.is_empty():
		_apply_artifact_config(artifact_object, merged_config, lookup_name)

	# Apply map-wide palette if available
	if current_palette != "":
		_try_set_property(artifact_object, "default_palette", current_palette)
		print("    Applied map palette: '%s'" % current_palette)
	
	# Handle tag system registration
	# Only register ENTITIES (with #group:tag), not PUZZLES (with #tag:action)
	# Puzzles set trigger_tag/trigger_action properties but don't register themselves
	if tag != "" and trigger_action == "":
		# This is an entity (e.g., cube_scene:0:0:0#group:fillhole)
		TagSystem.register_tagged_node(tag, artifact_object)
		print("    Registered entity with tag: '%s'" % tag)
	
	# Handle puzzle trigger setup
	if trigger_action != "":
		# Set properties on puzzle to trigger action on tag (e.g., cross_line_puzzle#fillhole:reveal)
		if "trigger_tag" in artifact_object:
			artifact_object.trigger_tag = tag
			print("    Set puzzle trigger_tag: '%s'" % tag)
		if "trigger_action" in artifact_object:
			artifact_object.trigger_action = trigger_action
			print("    Set puzzle trigger_action: '%s'" % trigger_action)

	parent_node.add_child(artifact_object)

	# Demo-artifact hygiene: many older algorithms/ scenes were authored as standalone
	# demos with their own screen-space CanvasLayer UI and/or Camera3D. Embedded as a map
	# artifact those leak — the UI overlays the player's view and the camera can steal
	# focus. Screen-space UI is never correct in VR (world-space / 2D-in-3D is), so suppress
	# that demo chrome on embed. The artifact's 3D content is untouched. The deferred pass
	# catches UI/cameras created inside the artifact's own _ready/call_deferred.
	_suppress_embedded_chrome(artifact_object)
	call_deferred("_suppress_embedded_chrome", artifact_object)
	LabelFramer.frame_labels(artifact_object)
	call_deferred("_frame_labels_deferred", artifact_object)

	# Make it editable in VR: the catalyst's Edit-mode laser targets this group,
	# and the B-save uses grid_cell / vr_saved_cell to move it (clearing the old
	# cell). This only TAGS the artifact — it stays fully interactive.
	if artifact_object is Node3D:
		artifact_object.add_to_group("vr_editable_artifact")
		artifact_object.set_meta("grid_cell", Vector2i(x, z))
		artifact_object.set_meta("vr_saved_cell", Vector2i(x, z))

	# Set owner for editor
	if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
		artifact_object.owner = parent_node.get_tree().edited_scene_root

	# Auto-ground ON BY DEFAULT (2026-06-12, convention: "all artifacts grounded
	# at 0,0,0; otherwise change with name:rot:y_offset:scale"). Every artifact's
	# geometry base is snapped to the cell surface. Opt OUT either by setting
	# `auto_ground: false` in the registry, or by giving an explicit y in the
	# token (an explicit y means the placer is taking manual control).
	# The earlier particle-AABB blow-ups (becoming_catalyst 4m lift) are handled
	# by excluding GPUParticles3D from the grounding AABB + the 5.0m safety cap.
	if artifact_object is Node3D:
		var want_ground: bool = artifact_info.get("auto_ground", true) and not overrides.has("y_position")
		if want_ground:
			call_deferred("_auto_ground_artifact", artifact_object, lookup_name)

	# ── DRESS (2026-08-23, grid twin of the museum's per-instance staging:
	# "plinth height, rotate, offset connected to the artifact") ─────────────
	# Reserved token-config keys: #plinth:H stands a plain station plinth
	# under the artifact and lifts the body to its deck; #offset:x,y,z nudges
	# the transform; #scale:S scales it. GATED BY THE KEYS — a token without
	# them is byte-identical to before. The lift and offset are deferred so
	# they run AFTER _auto_ground (deferreds are FIFO): the base grounds to
	# the cell first, then rises to the deck / takes its nudge.
	if artifact_object is Node3D and config_data.has("plinth") \
			and str(config_data["plinth"]).is_valid_float():
		var dress_h: float = clampf(float(str(config_data["plinth"])), 0.0, 3.0)
		if dress_h > 0.05:
			var pl_scene: PackedScene = load("res://commons/artifacts/station/station_plinth.tscn") as PackedScene
			var pl: Node3D = pl_scene.instantiate() as Node3D if pl_scene != null else null
			if pl != null:
				var pl_cfg := {"top_height": dress_h, "cap_meters": 0.9, "width_cells": 1,
					"depth_cells": 1, "top_style": "flat", "glow_light": false}
				for pk in pl_cfg:
					pl.set_meta("config_%s" % str(pk), pl_cfg[pk])
				if pl.has_method("apply_grid_config"):
					pl.call("apply_grid_config", pl_cfg)
				pl.position = Vector3(x * total_size, GridCommon.surface_world_y(y, total_size), z * total_size)
				pl.set_meta("dress_plinth_for", lookup_name)
				parent_node.add_child(pl)
				artifact_object.set_meta("dress_plinth_path", artifact_object.get_path_to(pl) if pl.is_inside_tree() and artifact_object.is_inside_tree() else NodePath())
				call_deferred("_dress_adjust", artifact_object, Vector3(0.0, dress_h, 0.0))
	if artifact_object is Node3D and config_data.has("offset"):
		var dop := str(config_data["offset"]).split(",")
		if dop.size() >= 3 and str(dop[0]).strip_edges().is_valid_float() \
				and str(dop[1]).strip_edges().is_valid_float() and str(dop[2]).strip_edges().is_valid_float():
			call_deferred("_dress_adjust", artifact_object,
				Vector3(float(dop[0]), float(dop[1]), float(dop[2])))
	if artifact_object is Node3D and config_data.has("scale") \
			and str(config_data["scale"]).is_valid_float():
		var dsc: float = clampf(float(str(config_data["scale"])), 0.1, 5.0)
		if not is_equal_approx(dsc, 1.0):
			artifact_object.scale *= dsc

	# Packaging (GATED, default OFF): spawn grounding furniture + a framed caption around the
	# artifact from its spatial_needs. Deferred so it runs AFTER _auto_ground (registered first),
	# and after the artifact has built its geometry. Never package a packaging prop (recursion)
	# or a placeholder.
	if artifact_object is Node3D and _packaging_enabled() \
			and str(artifact_info.get("category", "")) != "packaging" \
			and str(artifact_info.get("artifact_type", "")) != "placeholder":
		call_deferred("_spawn_packaging_for", artifact_object, lookup_name, artifact_info, world_pos)

# Handle successful placement
	var display_name = artifact_info.get("name", lookup_name)
	print("  ✅ Placed artifact '%s' (%s) at (%d,%d,%d)" % [display_name, lookup_name, x, y, z])

	return true



# COLON (:) SYNTAX - For rotation and position/scale:
#   "object"                                   → No overrides
#   "object:45"                                → Y-axis rotation 45°
#   "object:45|Label"                          → Y rotation 45° + label text
#   "object:45:2.5"                            → Y rotation 45° + Y position offset +2.5
#   "object:45:2.5:1.2"                        → Y rotation 45° + Y offset +2.5 + scale 1.2
#   "object:45:30:0"                           → 3-axis rotation (Z=45°, X=30°, Y=0°)
#   "object:45:30:0:true:false:true"           → 3-axis rotation + continuous (Z spin, Y spin)
#
# HASH (#) SYNTAX - For complex configuration (RECOMMENDED for non-rotation configs):
#   "pickup_gate#pickups:5"                    → Config parameter
#   "pickup_gate#pickups:3#color:blue"         → Multiple configs
#
# IMPORTANT: 4-param format is AMBIGUOUS:
#   - Could be: rot_y:y_pos:scale:? (legacy) OR rot_z:rot_x:rot_y (new 3-axis)
#   - System assumes 3-axis rotation if all 4 params are numeric
#   - For position/scale, use 3-param format OR # syntax instead
# Helper function to parse token parameters (without the tag part)
func _parse_token_params(token: String, result: Dictionary) -> Dictionary:
	# Handle legacy : syntax for overrides
	if token.find(":") == -1:
		result.lookup_name = token
		return result
	
	var parts = token.split(":", false)

	# SPECIAL HANDLING FOR MARCHING CUBES (mc:) OBJECTS
	# Format: mc:id:rot_y:y_pos:scale
	if parts.size() >= 2 and parts[0] == "mc":
		result.lookup_name = "mc:" + parts[1].strip_edges()
		
		# Parse parameters if present
		# parts[0]=mc, parts[1]=id
		
		if parts.size() >= 3:
			var p = parts[2].strip_edges()
			if p.is_valid_float():
				result.overrides["rotation_y_degrees"] = float(p)
			else:
				print("GridInteractables: Param 2 (rot) invalid float: '%s'" % p)
			
		if parts.size() >= 4:
			var p = parts[3].strip_edges()
			if p.is_valid_float():
				result.overrides["y_position"] = float(p)
			else:
				print("GridInteractables: Param 3 (pos) invalid float: '%s'" % p)
			
		if parts.size() >= 5:
			var p = parts[4].strip_edges()
			if p.is_valid_float():
				result.overrides["uniform_scale"] = float(p)
				print("GridInteractables: Found scale param in token: %f" % float(p))
			else:
				print("GridInteractables: Param 4 (scale) invalid float: '%s'" % p)
			
		return result
	
	if parts.size() < 2:
		result.lookup_name = token
		return result
		
	var name = parts[0].strip_edges()
	result.lookup_name = name
	
	# Handle different parameter formats:
	# Format 1: name:rot_y|label         (legacy Y rotation + label)
	# Format 2: name:rot_y:y_pos:scale   (legacy Y rotation + position + scale)
	# Format 3: name:rot_z:rot_x:rot_y   (3-axis rotation) - ONLY if all params are numeric
	# Format 4: name:rot_z:rot_x:rot_y:cont_z:cont_x:cont_y  (full rotation + continuous)

	if parts.size() == 2:
		# Legacy format: name:param where param could be rotation or rotation|label
		var param = parts[1].strip_edges()
		var rot_part = param
		var label_part = ""

		if param.find("|") != -1:
			var p2 = param.split("|", false)
			rot_part = p2[0].strip_edges()
			if p2.size() > 1:
				label_part = p2[1].strip_edges()

		# rotation part (Y-axis only for legacy compatibility)
		if rot_part.is_valid_float():
			result.overrides["rotation_y_degrees"] = float(rot_part)
		else:
			# If it's not numeric and no explicit label part, treat rot_part as label text
			if label_part == "" and rot_part != "":
				label_part = rot_part

		# label part
		if label_part != "":
			result.overrides["label_text"] = label_part

	elif parts.size() == 4:
		# Ambiguous: Could be legacy (rot_y:y_pos:scale) OR new 3-axis rotation (rot_z:rot_x:rot_y)
		var param1 = parts[1].strip_edges()
		var param2 = parts[2].strip_edges()
		var param3 = parts[3].strip_edges()

		var all_numeric = param1.is_valid_float() and param2.is_valid_float() and param3.is_valid_float()

		if all_numeric:
			var val1 = float(param1)
			var val2 = float(param2)
			var val3 = float(param3)

			# Heuristic: If 3rd value is a typical scale (0-10 range), assume legacy format
			# Scale of 0 means "use default scale" (1.0)
			# Otherwise (val3 >= 10), assume it's 3-axis rotation
			if val3 < 10.0:
				# Legacy: name:rot_y:y_pos:scale
				result.overrides["rotation_y_degrees"] = val1
				result.overrides["y_position"] = val2
				# Scale of 0 means use default (1.0), otherwise use the value
				if val3 > 0.0:
					result.overrides["uniform_scale"] = val3
			else:
				# NEW: 3-axis rotation: name:rot_z:rot_x:rot_y
				result.overrides["rotation_z_degrees"] = val1
				result.overrides["rotation_x_degrees"] = val2
				result.overrides["rotation_y_degrees"] = val3

	elif parts.size() == 3:
		# Legacy format: name:rot_y:y_pos
		var rot_str = parts[1].strip_edges()
		var y_pos_str = parts[2].strip_edges()

		if rot_str.is_valid_float():
			result.overrides["rotation_y_degrees"] = float(rot_str)

		if y_pos_str.is_valid_float():
			result.overrides["y_position"] = float(y_pos_str)

	return result

func _parse_interactable_token(token: String) -> Dictionary:
	token = _normalize_legacy_semicolon_token(token)
	var result := {"lookup_name": token, "overrides": {}, "config_data": {}, "tag": "", "trigger_action": ""}
	
	# Handle # configuration syntax first - could be tag OR config
	# Tag syntax: artifact:params#group:tagname OR artifact:params#tagname:action
	if token.find("#") != -1:
		# Check if it's a tag (group:tagname or tagname:action) or config (other # usage)
		var parts = token.split("#", false, 1)  # Split on first # only
		if parts.size() == 2:
			var before_hash = parts[0]
			var after_hash = parts[1]
			
			# Check if after_hash looks like a tag: "group:tagname" or "tagname:action"
			if after_hash.begins_with("group:"):
				# Entity tag: artifact:params#group:tagname
				result.lookup_name = before_hash
				result.tag = after_hash.substr(6)  # Remove "group:" prefix
				# Continue parsing the before_hash part for params
				return _parse_token_params(before_hash, result)
			elif after_hash.find(":") != -1:
				# Could be puzzle trigger: artifact:params#tagname:action
				var tag_parts = after_hash.split(":", false, 1)
				if tag_parts.size() == 2:
					var tag_name = tag_parts[0].strip_edges()
					var action_name = tag_parts[1].strip_edges()
					# Validate that action_name looks like an action (not a number/param)
					if action_name in ["remove", "reveal", "hide", "freeze", "unfreeze", "enable_physics", "disable_physics"]:
						result.lookup_name = before_hash
						result.tag = tag_name
						result.trigger_action = action_name
						# Continue parsing the before_hash part for params
						return _parse_token_params(before_hash, result)
			
			# Otherwise, treat as config syntax (clipboard#pages:point,line,triangle)
			return _parse_config_token(token)
	
	# Handle legacy : syntax for overrides (no # found)
	return _parse_token_params(token, result)

# Normalize legacy semicolon separator in artifact tokens.
# Example: "r_c;90:0:1#8" -> "r_c:90:0:1#8"
func _normalize_legacy_semicolon_token(token: String) -> String:
	var semicolon_index = token.find(";")
	if semicolon_index == -1:
		return token

	var hash_index = token.find("#")
	var head_end = hash_index if hash_index != -1 else token.length()

	# Only normalize if ';' is in the artifact head section and the name itself
	# doesn't already contain ':' before that semicolon.
	if semicolon_index > head_end:
		return token

	var before_semicolon = token.substr(0, semicolon_index)
	if before_semicolon.find(":") != -1:
		return token

	var after_semicolon = token.substr(semicolon_index + 1)
	return "%s:%s" % [before_semicolon, after_semicolon]

# Parse configuration token syntax with # (e.g., "clipboard#pages:point,line,triangle")
# Format: "artifact_name[:rotation:height:scale]#config_key:config_value[#config_key2:config_value2]..."
# Supports combining : overrides with # config syntax
# Examples:
#   "clipboard#pages:point,line,triangle"                    → { lookup_name: "clipboard", config_data: { pages: "point,line,triangle" } }
#   "clipboard#title:Getting Started"                        → { lookup_name: "clipboard", config_data: { title: "Getting Started" } }
#   "clipboard#pages:point,line#title:My Clips"              → { lookup_name: "clipboard", config_data: { pages: "point,line", title: "My Clips" } }
#   "code_display:90:0.5:0.2#tutorial:line_axioms"           → { lookup_name: "code_display", overrides: {rotation_y: 90, y_pos: 0.5, scale: 0.2}, config_data: { tutorial: "line_axioms" } }
#   "infokiosk:180:-0.5#message:Hello World#color:red"      → { lookup_name: "infokiosk", overrides: {rotation_y: 180, y_pos: -0.5}, config_data: { message: "Hello World", color: "red" } }
func _parse_config_token(token: String) -> Dictionary:
	var result := {"lookup_name": "", "overrides": {}, "config_data": {}}

	# Split on # to separate artifact name from config parts
	var hash_parts = token.split("#", false)
	if hash_parts.size() < 2:
		result.lookup_name = token
		return result

	var artifact_name_part = hash_parts[0].strip_edges()

	# Parse the artifact name part which may contain : overrides
	# Format: "artifact_name:rotation:height:scale"
	
	# Handle Marching Cubes (mc:) prefix within config token
	# Format: mc:id:rot_y:y_pos:scale#config...
	if artifact_name_part.begins_with("mc:"):
		var name_parts = artifact_name_part.split(":", false)
		if name_parts.size() >= 2:
			result.lookup_name = "mc:" + name_parts[1].strip_edges()
			
			if name_parts.size() >= 3 and name_parts[2].is_valid_float():
				result.overrides["rotation_y_degrees"] = float(name_parts[2])
				
			if name_parts.size() >= 4 and name_parts[3].is_valid_float():
				result.overrides["y_position"] = float(name_parts[3])
				
			if name_parts.size() >= 5 and name_parts[4].is_valid_float():
				result.overrides["uniform_scale"] = float(name_parts[4])
				print("GridInteractables: (Config token) Found mc scale: %f" % result.overrides["uniform_scale"])
				
	elif artifact_name_part.find(":") != -1:
		var name_parts = artifact_name_part.split(":", false)
		result.lookup_name = name_parts[0].strip_edges()

		# Parse positional overrides (rotation, height, scale)
		if name_parts.size() >= 2 and name_parts[1].is_valid_float():
			result.overrides["rotation_y_degrees"] = float(name_parts[1])

		if name_parts.size() >= 3 and name_parts[2].is_valid_float():
			result.overrides["y_position"] = float(name_parts[2])

		if name_parts.size() >= 4 and name_parts[3].is_valid_float():
			result.overrides["uniform_scale"] = float(name_parts[3])

		if not result.overrides.is_empty():
			print("GridInteractablesComponent: Parsed combined syntax - artifact='%s', overrides=%s" % [result.lookup_name, result.overrides])
	else:
		result.lookup_name = artifact_name_part

	# Process all config parts (supports multiple # configs)
	for i in range(1, hash_parts.size()):
		var config_part = hash_parts[i].strip_edges()

		# Parse config part (format: "key:value" or "tutorial_id:rot:height:scale")
		if config_part.find(":") != -1:
			# Check if this is a shorthand with transform params (e.g., "point_zero:15:-0.3:1.1")
			var parts = config_part.split(":", false)

			# If we have numeric params after first part, treat as tutorial_id with transforms
			# Check for shorthand syntax: either single rotation or multiple transform params
			# e.g., "vr_scale_controls:190" (rotation only) or "point_zero:15:-0.3:1.1" (all transforms)
			# BUT NOT config params like "radial:9" or "rings:4" - those are key:value pairs
			var is_shorthand = false
			var first_part_lower = parts[0].strip_edges().to_lower()

			# Skip shorthand detection if first part is a known config parameter name
			if first_part_lower not in CONFIG_PARAM_NAMES:
				# Case 1: Single numeric param (rotation only) - e.g., "tutorial_id:180"
				if parts.size() == 2 and parts[1].is_valid_float():
					is_shorthand = true
				# Case 2: Multiple numeric params - e.g., "tutorial_id:180:0.5:1.0"
				elif parts.size() >= 3:
					var has_numeric_params = true
					for j in range(1, min(parts.size(), 4)):  # Check up to 3 transform params
						if not parts[j].is_valid_float():
							has_numeric_params = false
							break
					is_shorthand = has_numeric_params

			if is_shorthand:
					# This is shorthand syntax: tutorial_id:rotation:height:scale
					var tutorial_id = parts[0].strip_edges()
					result.config_data[tutorial_id] = true

					# Extract transform overrides
					if parts.size() >= 2 and parts[1].is_valid_float():
						result.overrides["rotation_y_degrees"] = float(parts[1])
					if parts.size() >= 3 and parts[2].is_valid_float():
						result.overrides["y_position"] = float(parts[2])
					if parts.size() >= 4 and parts[3].is_valid_float():
						result.overrides["uniform_scale"] = float(parts[3])

					print("GridInteractablesComponent: Parsed config shorthand - tutorial='%s', transforms=%s" % [tutorial_id, result.overrides])
					continue

			# Otherwise, treat as regular key:value config
			var config_parts = config_part.split(":", false, 1)  # Split only on first ":"
			if config_parts.size() == 2:
				var config_key = config_parts[0].strip_edges()
				var config_value = config_parts[1].strip_edges()
				result.config_data[config_key] = config_value
			else:
				# No value provided, just key
				result.config_data[config_part] = true
		else:
			# No colon, treat entire config_part as a key with true value
			result.config_data[config_part] = true

	return result

# Apply configuration data to an artifact using the # syntax
# This is a general system that allows any artifact to receive custom configuration
## Coerce a config value to the type the artifact's own @export declares.
##
## _parse_config_token stores every value as a STRING — `config_data[key] =
## config_parts[1].strip_edges()` — because a token is text. An artifact whose
## export is typed then does `blade_length = config_data["blade_length"]`, Godot
## refuses the assignment, and the artifact silently keeps its default. Nothing
## errors and nothing is logged, so the knob simply does not work.
##
## An audit of every placed artifact found 54 of them in this state across 353
## placements: xyz_slider_plate's min_value and max_value (35 placements),
## pattern_tile_puzzle's tile_size (33), GlassRack's show_liquid (27),
## laser_sword's blade_length and blade_emission (22). lsystem_editor was the
## case that exposed it — seven L-system grammars behind a typed int `preset`,
## so `lsystem_editor#preset:5` rendered Plant in all four maps, forever.
##
## Fixing it here rather than in 54 files is the whole point: the defect is at
## the boundary, not in the artifacts. This asks the INSTANCE what type it
## declared and converts to that, so an artifact with no such property, or a
## value that is not a valid number, is passed through exactly as before.
static func _coerce_to_export_type(target: Node, key: String, value: Variant) -> Variant:
	if not (value is String):
		return value
	var text: String = value
	for prop in target.get_property_list():
		if String(prop.get("name", "")) != key:
			continue
		# only real script exports, never built-in Node properties
		if int(prop.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			return value
		match int(prop.get("type", 0)):
			TYPE_INT:
				return int(text) if text.is_valid_int() else value
			TYPE_FLOAT:
				return float(text) if text.is_valid_float() else value
			TYPE_BOOL:
				var low: String = text.to_lower()
				if low in ["true", "1", "yes", "on"]:
					return true
				if low in ["false", "0", "no", "off"]:
					return false
				return value
			_:
				return value      # String, enum-as-String, everything else: untouched
	return value


# Apply configuration data to an artifact using the # syntax
# This is a general system that allows any artifact to receive custom configuration
func _apply_artifact_config(artifact_object: Node, config_data: Dictionary, lookup_name: String):
	print("GridInteractablesComponent: Applying config to '%s': %s" % [lookup_name, config_data])

	# Type-match the text a token carries against what the artifact declared, so a
	# typed export stops silently rejecting its own value. Purely additive: a key
	# the artifact does not declare, and any value that will not parse, is left
	# exactly as it arrived.
	var typed_config: Dictionary = {}
	for k in config_data.keys():
		typed_config[k] = _coerce_to_export_type(artifact_object, String(k), config_data[k])
	config_data = typed_config

	# Set config data as metadata for the artifact to read
	for config_key in config_data.keys():
		var config_value = config_data[config_key]
		# Sanitize the key to be a valid identifier (letters, numbers, underscore only)
		var sanitized_key = config_key.replace(":", "_").replace(",", "_").replace(" ", "_").replace("-", "_")
		if not sanitized_key.is_valid_identifier():
			# Skip keys that can't be made valid
			print("  → Skipping invalid config key: '%s'" % config_key)
			continue
		var meta_key = "config_%s" % sanitized_key
		artifact_object.set_meta(meta_key, config_value)
		print("  → Set metadata '%s' = '%s'" % [meta_key, str(config_value)])
	
	# Try to call a configuration method on the artifact if it exists
	# This allows artifacts to handle their own configuration logic
	# IMPORTANT: duplicate() the dictionary since call_deferred holds a reference
	# and the original dict may be modified before the deferred call executes
	if artifact_object.has_method("apply_grid_config"):
		artifact_object.call_deferred("apply_grid_config", config_data.duplicate(true))
		print("  → Called apply_grid_config() method")
	elif artifact_object.has_method("configure"):
		artifact_object.call_deferred("configure", config_data.duplicate(true))
		print("  → Called configure() method")
	else:
		# THE BENCH LOOKED HARDER THAN THE WORLD DID, and this closes that gap.
		#
		# capture_config_sweep searches the whole subtree for the node that owns a property
		# (_holder_of, breadth-first). This call site only ever asked the ROOT. For fourteen
		# tokens the script sits on a CHILD of the .tscn, so their axes were measured on the
		# bench, published, and proven to bite — in a place no player can stand. The config
		# landed as metadata on a root that reads nothing, has_method() was false here, and
		# this branch printed a line indistinguishable from a config-less artifact. Every
		# stage green; the axis never happened.
		#
		# 184 placements across 152 maps, none of which carries a #config today — so nothing
		# is broken yet. The trap is armed, not sprung: the first person to write
		# `line#readout:gradation` gets silence and a default-valued artifact.
		#
		# GATED BY CONSTRUCTION: an artifact whose root handles config never reaches this
		# branch, so its path is byte-identical to before.
		var holder: Node = _config_holder(artifact_object, config_data)
		if holder != null:
			for config_key in config_data.keys():
				var sk: String = String(config_key).replace(":", "_").replace(",", "_").replace(" ", "_").replace("-", "_")
				if sk.is_valid_identifier():
					holder.set_meta("config_%s" % sk, config_data[config_key])
			if holder.has_method("apply_grid_config"):
				holder.call_deferred("apply_grid_config", config_data.duplicate(true))
			else:
				holder.call_deferred("configure", config_data.duplicate(true))
			print("  → Forwarded config to child '%s' (root carries no handler)" % holder.name)
		else:
			print("  → No configuration method found, using metadata only")


## The first descendant that either handles the config call or declares one of its keys as a
## property. Breadth-first, mirroring capture_config_sweep._holder_of so the world reaches
## exactly as far as the bench does — no further.
##
## Returns null when nothing claims it, which preserves today's behaviour for every
## genuinely config-less artifact.
func _config_holder(root: Node, config_data: Dictionary) -> Node:
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c in n.get_children():
			if c.has_method("apply_grid_config") or c.has_method("configure"):
				return c
			for k in config_data.keys():
				if String(k) in c:
					return c
			queue.append(c)
	return null

# Safely set a property if the node exposes it
func _try_set_property(obj: Object, prop: String, value) -> void:
	if obj == null:
		return
	var props = obj.get_property_list()
	for p in props:
		if typeof(p) == TYPE_DICTIONARY and p.has("name") and str(p["name"]) == prop:
			obj.set(prop, value)
			return

# Add continuous rotation to an object using a Timer
func _add_continuous_rotation(obj: Node3D, rotate_z: bool, rotate_x: bool, rotate_y: bool) -> void:
	if not obj:
		return

	# Build rotation speed vector (30 degrees per second for each enabled axis)
	var speed := Vector3(
		30.0 if rotate_x else 0.0,
		30.0 if rotate_y else 0.0,
		30.0 if rotate_z else 0.0
	)

	# Skip if no rotation needed
	if speed == Vector3.ZERO:
		return

	# Store the rotation speed in metadata
	obj.set_meta("_rotation_speed", speed)

	# Add a timer that handles rotation updates
	var timer := Timer.new()
	timer.name = "_RotationTimer"
	timer.wait_time = 0.016  # ~60fps
	timer.autostart = true
	obj.add_child(timer)

	timer.timeout.connect(func():
		if is_instance_valid(obj) and obj.has_meta("_rotation_speed"):
			var rot_speed: Vector3 = obj.get_meta("_rotation_speed")
			obj.rotation_degrees += rot_speed * timer.wait_time
	)

# Apply transform data from artifact definition
func _apply_artifact_transform(artifact_object: Node, artifact_info: Dictionary):
	if artifact_object is Node3D:
		# Apply rotation if specified in artifact definition
		if artifact_info.has("rotation"):
			var rotation_data = artifact_info["rotation"]
			if rotation_data is Array and rotation_data.size() >= 3:
				artifact_object.rotation_degrees = Vector3(rotation_data[0], rotation_data[1], rotation_data[2])
		
		# Apply scale if specified in artifact definition
		if artifact_info.has("scale"):
			var scale_data = artifact_info["scale"]
			if scale_data is Array and scale_data.size() >= 3:
				artifact_object.scale = Vector3(scale_data[0], scale_data[1], scale_data[2])
			elif scale_data is float or scale_data is int:
				artifact_object.scale = Vector3.ONE * scale_data
	elif artifact_object is Control:
		# For Control nodes, handle scale differently
		if artifact_info.has("scale"):
			var scale_data = artifact_info["scale"]
			if scale_data is Array and scale_data.size() >= 2:
				artifact_object.scale = Vector2(scale_data[0], scale_data[1])
			elif scale_data is float or scale_data is int:
				artifact_object.scale = Vector2.ONE * scale_data

# Load and instantiate artifact scene
func _load_and_instantiate_artifact(scene_path: String) -> Node:
	var scene_resource = _load_scene_cached(scene_path)
	if scene_resource:
		# Log which scene is being instantiated (helps debug convex hull errors)
		print("GridInteractablesComponent: Instantiating artifact: %s" % scene_path)
		return scene_resource.instantiate()
	return null

# Update artifact labels with information
func _update_artifact_labels(artifact_object: Node, lookup_name: String, artifact_info: Dictionary):
	if artifact_object is Node3D:
		# Look for common 3D label names
		var label_names = ["id_info_Label3D", "Label3D", "InfoLabel"]
		
		for label_name in label_names:
			var label = artifact_object.find_child(label_name)
			if label and label is Label3D:
				var display_name = artifact_info.get("name", lookup_name)
				label.text = "%s: %s" % [lookup_name, display_name]
				print("  Updated 3D label: %s" % label.text)
				break
	elif artifact_object is Control:
		# Look for common 2D label names
		var label_names = ["Label", "TitleLabel", "InfoLabel"]
		
		for label_name in label_names:
			var label = artifact_object.find_child(label_name)
			if label and label is Label:
				var display_name = artifact_info.get("name", lookup_name)
				label.text = "%s: %s" % [lookup_name, display_name]
				print("  Updated 2D label: %s" % label.text)
				break

# Connect artifact signals using lookup_name
func _connect_artifact_signals(artifact_object: Node, lookup_name: String):
	# Connect common interaction signals
	if artifact_object.has_signal("interact"):
		artifact_object.interact.connect(_on_artifact_interact.bind(lookup_name, artifact_object))
	
	if artifact_object.has_signal("activated"):
		artifact_object.activated.connect(_on_artifact_activated.bind(lookup_name, artifact_object))
	
	if artifact_object.has_signal("artifact_activated"):
		artifact_object.artifact_activated.connect(_on_artifact_activated.bind(lookup_name, artifact_object))

	# Connect TELEPORTER signals (for Portal artifacts)
	if artifact_object.has_signal("teleporter_activated"):
		artifact_object.teleporter_activated.connect(_on_teleporter_artifact_activated.bind(lookup_name, artifact_object))
		print("GridInteractables: Connected teleporter signal for '%s'" % lookup_name)

func _on_teleporter_artifact_activated(lookup_name: String, artifact_object: Node):
	print("GridInteractables: 🚀 Teleporter Artifact activated: %s" % lookup_name)
	
	var destination = artifact_object.get_meta("destination", "")
	var action = artifact_object.get_meta("action", "")
	
	# If no explicit destination/action, default to 'next_in_sequence'
	if destination == "" and action == "":
		action = "next_in_sequence"
		print("GridInteractables: No destination/action found, defaulting to 'next_in_sequence'")
	elif destination != "" and action == "":
		action = "load_map" # Default action if map name is provided
	
	# Find SceneManager (it's an Autoload, usually 'SceneManager' or accessible via tree)
	# Assuming 'SceneManager' singleton exists as per your project structure
	var scene_manager = get_node_or_null("/root/SceneManager") 
	if not scene_manager and utilities_component:
		# Try to find it via utilities component helper if available
		if utilities_component.has_method("_find_scene_manager"):
			scene_manager = utilities_component._find_scene_manager()
			
	if scene_manager:
		scene_manager.request_transition({
			"type": 1, # TRANSITION_TYPE.TELEPORT (assuming index 1)
			"action": action,
			"destination": destination,
			"source": "teleporter_artifact",
			"position": artifact_object.global_position
		})
		print("GridInteractables: Requested transition to '%s' (action: %s)" % [destination, action])
	else:
		printerr("GridInteractables: ❌ Could not find SceneManager to trigger teleport!")

# Handle artifact interaction
func _on_artifact_interact(lookup_name: String, artifact_object: Node):
	var artifact_info = _get_artifact_info_or_placeholder(lookup_name)
	var artifact_pos = Vector3.ZERO
	
	# Get position based on node type
	if artifact_object is Node3D:
		artifact_pos = artifact_object.global_position
	elif artifact_object is Control:
		# For Control nodes, use a default position or convert from 2D
		artifact_pos = Vector3(artifact_object.global_position.x, 0, artifact_object.global_position.y)
	
	var artifact_data = {
		"lookup_name": lookup_name,
		"position": artifact_pos,
		"name": artifact_info.get("name", lookup_name),
		"artifact_type": artifact_info.get("artifact_type", "unknown"),
		"description": artifact_info.get("description", ""),
		"sequence": artifact_info.get("sequence", "")
	}
	
	print("GridInteractablesComponent: Artifact interaction - %s ('%s')" % [lookup_name, artifact_info.get("name", "")])
	interactable_activated.emit(lookup_name, artifact_pos, artifact_data)

# Handle artifact activation
func _on_artifact_activated(lookup_name: String, artifact_object: Node):
	_on_artifact_interact(lookup_name, artifact_object)

# Load scene with caching
func _load_scene_cached(scene_path: String) -> PackedScene:
	if scene_cache.has(scene_path):
		return scene_cache[scene_path]
	
	print("GridInteractablesComponent: Loading scene: %s" % scene_path)
	
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		if scene and scene is PackedScene:
			scene_cache[scene_path] = scene
			print("GridInteractablesComponent: OK loaded scene: %s" % scene_path)
			return scene
		print("GridInteractablesComponent: ERROR - Failed to load PackedScene: %s" % scene_path)
	else:
		print("GridInteractablesComponent: ERROR - Scene file not found: %s" % scene_path)
	
	if scene_path != ARTIFACT_PLACEHOLDER_SCENE_PATH:
		print("GridInteractablesComponent: Falling back to placeholder scene")
		return _load_scene_cached(ARTIFACT_PLACEHOLDER_SCENE_PATH)
	
	print("GridInteractablesComponent: ERROR - Placeholder scene is missing: %s" % ARTIFACT_PLACEHOLDER_SCENE_PATH)
	return null

# Get interactable at position
func get_interactable_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return interactable_objects.get(key, null)

# Check if position has interactable
func has_interactable_at(x: int, y: int, z: int) -> bool:
	return interactable_objects.has(Vector3i(x, y, z))

# Clear all interactables
func clear_interactables():
	print("GridInteractablesComponent: Clearing all interactables")
	
	for key in interactable_objects.keys():
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			interactable.queue_free()
	
	interactable_objects.clear()

# Get interactable count
func get_interactable_count() -> int:
	return interactable_objects.size()

# Get all interactable positions
func get_all_interactable_positions() -> Array:
	return interactable_objects.keys()

# Get artifacts by type using lookup_name system
func get_artifacts_by_type(artifact_type: String) -> Array:
	var result = []
	for lookup_name in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[lookup_name]
		if artifact_info.get("artifact_type", "") == artifact_type:
			result.append({
				"lookup_name": lookup_name,
				"info": artifact_info
			})
	return result

# Get all available artifact types
func get_available_artifact_types() -> Array:
	var types = []
	for lookup_name in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[lookup_name]
		var artifact_type = artifact_info.get("artifact_type", "unknown")
		if not types.has(artifact_type):
			types.append(artifact_type)
	return types

# Debug: Print artifact registry status
func print_artifact_registry_status():
	print("=== GridInteractablesComponent Artifact Registry ===")
	print("Total artifacts loaded: %d" % grid_artifact_registry.size())
	print("Artifacts by lookup_name:")
	
	for lookup_name in grid_artifact_registry.keys():
		var artifact_info = grid_artifact_registry[lookup_name]
		var display_name = artifact_info.get("name", "Unnamed")
		var scene_path = artifact_info.get("scene", "No scene")
		var artifact_type = artifact_info.get("artifact_type", "unknown")
		print("  → %s: '%s' (%s) - %s" % [lookup_name, display_name, artifact_type, scene_path])
	
	print("Available artifact types: %s" % str(get_available_artifact_types()))
	print("================================================")


# ── Auto-ground system ─────────────────────────────────────────────────────────
# After an artifact is added to the scene tree (and _ready() has fired), compute
# its AABB and shift it up so the bottom of its geometry sits at the grid surface
# rather than clipping below.
#
# (Reverted the brief 2026-05-03 symmetric-grounding experiment — GPU particle
# systems on procedural artifacts like the catalyst have arbitrary visibility
# AABBs that confused the "shift down" logic and pushed artifacts meters into
# the air. The conservative "only ever lift up" behavior is the documented
# convention; floating-look issues should be solved with plinth structure
# cubes, not with grid-side auto-correction.)

## Deferred callback: computes AABB, shifts artifact up if min_y < 0.
func _auto_ground_artifact(artifact: Node3D, lookup_name: String) -> void:
	if not is_instance_valid(artifact):
		return

	var aabb: AABB = _compute_local_aabb(artifact)
	if aabb.size.length() < 0.01:
		return  # No measurable geometry

	# Clamp AABB Y range to filter hidden MultiMesh instances at Y=-1000
	if aabb.size.y > 50.0:
		var cmin: float = max(aabb.position.y, -10.0)
		var cmax: float = min(aabb.position.y + aabb.size.y, 50.0)
		if cmax > cmin:
			aabb.position.y = cmin
			aabb.size.y = cmax - cmin
		else:
			return  # All geometry is hidden

	var min_y: float = aabb.position.y
	if absf(min_y) < 0.01:
		return  # Already grounded (within tolerance)

	# Snap the geometry base to the cell surface — lift a sunk artifact UP, drop a
	# floating one DOWN. correction = -min_y (negative min_y → lift; positive → drop).
	var correction: float = -min_y

	# Safety cap: skip unreasonably large corrections (probably an environment
	# object like a 40m sphere, a laser beam, or something that should set
	# auto_ground:false in the registry).
	if absf(correction) > 5.0:
		print("  ⚠ Auto-ground: '%s' needs %.2f shift (exceeds 5.0 cap) — skipped. Set auto_ground:false in registry." % [lookup_name, correction])
		return

	artifact.position.y += correction
	print("  %s Auto-ground: shifted '%s' by %.3f" % ["↑" if correction > 0.0 else "↓", lookup_name, correction])


## Is the gated packaging feature on? Default OFF — existing maps untouched until flipped.
func _packaging_enabled() -> bool:
	return bool(ProjectSettings.get_setting("ada/packaging/auto_spawn", false))


## Spawn packaging props (podium / step / wall / readout) around `artifact` from its spatial_needs.
## Runs deferred, after auto-ground. Packaging props are added as siblings under parent_node, built
## origin-at-floor, and tagged is_packaging. A grounding prop also lifts the artifact onto its top.
func _spawn_packaging_for(artifact: Node3D, lookup_name: String, artifact_info: Dictionary, world_pos: Vector3) -> void:
	if not is_instance_valid(artifact):
		return
	var sn: Variant = artifact_info.get("spatial_needs", {})
	if not (sn is Dictionary):
		sn = {}
	var aabb: AABB = _compute_local_aabb(artifact)
	var disp_name := str(artifact_info.get("name", lookup_name))
	var specs: Array = PackagingResolver.resolve(sn, aabb.size, disp_name)
	for spec in specs:
		var scene_path := str(spec.get("scene", ""))
		if scene_path == "" or not ResourceLoader.exists(scene_path):
			continue
		var packed = load(scene_path)
		if packed == null:
			continue
		var inst = packed.instantiate()
		if inst == null:
			continue
		parent_node.add_child(inst)
		if inst is Node3D:
			(inst as Node3D).position = world_pos + (spec.get("pos_offset", Vector3.ZERO) as Vector3)
		if inst.has_method("apply_grid_config"):
			inst.apply_grid_config(spec.get("dna", {}))
		inst.set_meta("is_packaging", true)
		inst.set_meta("packaging_for", lookup_name)
		# Lift the artifact onto the packaging top (the base already grounded by _auto_ground).
		var raise_to := float(spec.get("raise_to", -1.0))
		if raise_to >= 0.0 and is_instance_valid(artifact):
			artifact.position.y += raise_to
	if specs.size() > 0:
		print("  📦 Packaging: spawned %d prop(s) for '%s'" % [specs.size(), lookup_name])


## Render the map's kernel-emitted `systems` block (sources + edges) as visible flow infrastructure.
## GATED by the runtime flag "systems_render" (default OFF) — existing maps are untouched until set
## in ada_run/runtime_flags.json. Read straight from the map file (the block is a simple top-level
## key) to avoid threading it through the data-loader getters. Reload-safe (clears prior nodes).
func render_map_systems() -> void:
	if not _runtime_flag_enabled("systems_render", false):
		return
	if parent_node == null or map_data_component == null:
		return
	var mname: String = map_data_component.get_current_map_name()
	if mname == "":
		return
	var path := "res://commons/maps/%s/map_data.json" % mname
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if not (d is Dictionary):
		return
	var sys = d.get("systems")
	if not (sys is Dictionary):
		return
	for c in parent_node.get_children():           # reload-safe: drop any prior system nodes
		if c.has_meta("is_system"):
			c.queue_free()
	var total: float = float(cube_size) + float(gutter)
	var fy: float = float(cube_size)                # ~floor top for a flat (height-1) generated map
	for s in sys.get("sources", []):
		var cell: Array = s.get("cell", [0, 0])
		var node: Node3D = HangarKit.system_source(str(s.get("kind", "power")))
		node.position = Vector3(int(cell[1]) * total, fy + 1.0, int(cell[0]) * total)
		node.set_meta("is_system", true)
		parent_node.add_child(node)
	var n_edges := 0
	for e in sys.get("edges", []):
		var a := Vector3(int(e["from"][1]) * total, fy + 0.04, int(e["from"][0]) * total)
		var b := Vector3(int(e["to"][1]) * total, fy + 0.6, int(e["to"][0]) * total)
		var edge: Node3D = HangarKit.system_edge(a, b, str(e.get("kind", "power")))
		edge.set_meta("is_system", true)
		parent_node.add_child(edge)
		n_edges += 1
	print("GridInteractablesComponent: 🔌 systems — %d sources, %d edges" % [sys.get("sources", []).size(), n_edges])


## Recursively compute the local-space AABB of a node and all its children.
## Walks MeshInstance3D, MultiMeshInstance3D, CSGShape3D — SOLID geometry only.
## GPUParticles3D are intentionally EXCLUDED: their visibility AABBs are large and
## arbitrary, which is what caused bad auto-ground lifts (becoming_catalyst 4m).
func _compute_local_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false

		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = child.get_meshes()
			if child_meshes.size() >= 2:
				var m = child_meshes[1]
				if m is Mesh:
					child_aabb = child.transform * m.get_aabb()
					has_aabb = true
		# GPUParticles3D deliberately excluded — their visibility_aabb is not the
		# solid footprint and would skew grounding.

		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)

		# Recurse into Node3D children
		if child is Node3D:
			var sub_aabb: AABB = _compute_local_aabb(child)
			if sub_aabb.size.length() > 0:
				sub_aabb = child.transform * sub_aabb
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)

	return result
