# UtilityRegistry.gd
extends RefCounted
class_name UtilityRegistry

# Centralized utility type definitions - SINGLE SOURCE OF TRUTH
# This is the authoritative definition for all utility types used in the grid system
const UTILITY_TYPES = {
	# Transportation utilities
	"l": {
		"name": "platform_lift", 
		"file": "platform_lift_scene.tscn", 
		"category": "transport",
		"description": "Vertical platform that lifts players",
		"supports_parameters": true
	},
	"d": {
		"name": "door", 
		"file": "door_scene.tscn", 
		"category": "transport",
		"description": "Transitions between areas",
		"supports_parameters": false
	},
 
	"wp": {
		"name": "walkway", 
		"file": "walkableprism.tscn", 
		"category": "transport",
		"description": "walkway walk your way",
		"supports_parameters": true  # destination, spawn point
	},
	"t": {
		"name": "teleport",
		"file": "teleport_scene.tscn",
		"category": "transport",
		"description": "Instant location changes",
		"supports_parameters": true  # destination, spawn point
	},
	"m": {
		"name": "move_player",
		"file": "move_player.tscn",
		"category": "transport",
		"description": "Moves player to specific location after delay",
		"supports_parameters": true  # x, y, z, delay
	},
	"s": {
		"name": "spawn_point",
		"file": "spawn_point_scene.tscn",
		"category": "transport",
		# OPTIONAL. When absent, GridSpawnComponent places the player at the
		# centroid of floor cells, facing the centroid of interactables.
		# See the SPAWN POLICY doc block at the top of GridSpawnComponent.gd.
		# Add `s` only to override position; add map_data.json
		# `spawn_points.default.rotation` to override facing.
		"description": "Optional — explicit player start. Defaults to floor centroid facing interactables.",
		"supports_parameters": true  # spawn_name, rotation, priority
	},
	"cp": {
		"name": "checkpoint",
		"file": "checkpoint.tscn",
		"category": "safety",
		"description": "Save point - green sphere with S, saves player progress on touch",
		"supports_parameters": true  # checkpoint_id
	},
	"sp": {
	"name": "score points", 
	"file": "score_cube.tscn", 
	"category": "score",
	"description": "show score",
	"supports_parameters": true  # position, height_offset, warning_distance
	},
	"an": {
	"name": "annotation_cube", 
	"file": "info_board.tscn", 
	"category": "ui",
	"description": "Displays current map name and description",
	"supports_parameters": true  # display_mode, text_scale
	},
	"tts": {
		"name": "text_to_speech",
		"file": "tts_speaker.tscn",
		"category": "audio",
		"description": "Speaks text on load",
		"supports_parameters": true  # message string
	},
	"sub": {
		"name": "subtitle_trigger",
		"file": "subtitle_trigger.tscn",
		"category": "ui",
		"description": "Shows Portal 2-style subtitle when player enters area",
		"supports_parameters": true  # key: 'map' for map desc, or custom text/key
	},
	"3t": {
		"name": "text_display",
		"file": "word_is.tscn",
		"category": "ui",
		"description": "Displays custom short text using a TextMesh",
		"supports_parameters": true  # message string (underscores become spaces)
	},
	"sr": {
		"name": "speed_reader",
		"file": "speed_text.tscn",
		"category": "ui",
		"description": "Shows tutorial text one line at a time (3D speed read)",
		"supports_parameters": true  # key[:seconds[:loop]]
	},
	"Sr": {
		"name": "speed_reader (legacy)",
		"file": "speed_text.tscn",
		"category": "ui",
		"description": "Deprecated alias for 'sr' (use lowercase)",
		"supports_parameters": true
	},
	"r": {
	"name": "reset_cube", 
	"file": "reset_cube.tscn", 
	"category": "safety",
	"description": "Resets player to safe position when approached",
	"supports_parameters": true  # position, height_offset, warning_distance
	},
	"h": {
		"name": "hazard_zone",
		"file": "danger_zone.tscn",
		"category": "hazard",
		"description": "Danger zone that damages player (h:fire, h:vacuum, h:electric, h:toxic, h:radiation, h:death)",
		"supports_parameters": true  # type:damage_per_tick (e.g. "fire:20", "death")
	},
	"f": {
		"name": "force_field",
		"file": "",
		"category": "hazard",
		"description": "Dual-nature force zone — hazard that transmutes into benefit (f:fire, f:electric:15, f:toxic:10). Q-FEP: same potential, different restraint.",
		"supports_parameters": true  # type:intensity (e.g. "fire:1.5", "electric:2")
	},
	"e": {
		"name": "catalyst_vent",
		"file": "",  # no scene here — CatalystVentScanner instantiates post-load (GridSystem._scan_catalyst_vents)
		"category": "hazard",
		"description": "Catalyst vent — emits CatalystFoe waves (e:RATE:WAVE:DELAY[:KIND], KIND = goo/transport/swarm/drainfriend/chroma/wave/fractal/branch). Same grammar as the /editor enemy brush.",
		"supports_parameters": true  # rate, wave_size, start_delay, foe kind
	},
	"q": {
		"name": "quit_cube", 
		"file": "quit_cube.tscn", 
		"category": "game_control",
		"description": "Quit game when player approaches - with confirmation",
		"supports_parameters": true  # confirmation_timeout, require_confirmation
	},
	# Visual/Structural utilities
	"el": {
		"name": "extra_light",
		"file": "overhead_light.tscn",
		"category": "visual",
		"description": "An extra overhead light.",
		"supports_parameters": true
	},
	"w": {
		"name": "window", 
		"file": "window_scene.tscn", 
		"category": "visual",
		"description": "Visual portals and openings",
		"supports_parameters": false
	},
	"a": {
		"name": "wall", 
		"file": "wall_scene.tscn", 
		"category": "structure",
		"description": "Barriers and boundaries",
		"supports_parameters": true  # material, transparency
	},
	"hb": {
		"name": "horizontal_border", 
		"file": "horizontalboarder.tscn", 
		"category": "structure",
		"description": "Horizontal border element",
		"supports_parameters": false
	},
	
	# Furniture utilities
	"b": {
		"name": "table", 
		"file": "table_scene.tscn", 
		"category": "furniture",
		"description": "Surface for objects and interaction",
		"supports_parameters": false
	},
	
	# Interactive utilities
	"p": {
		"name": "pick_up", 
		"file": "pick_up_cube.tscn", 
		"category": "interactive",
		"description": "Grabbable objects for interaction",
		"supports_parameters": false
	},
	"n": {
		"name": "next_cube", 
		"file": "next_cube.tscn", 
		"category": "interactive",
		"description": "Advances to next example/pattern with 3s respawn",
		"supports_parameters": true  # respawn_time, rotation_speed
	},

	"rg": {
		"name": "regenerate_cube", 
		"file": "regenerate_cube.tscn", 
		"category": "interactive",
		"description": "Triggers regenerate signal for linked listings",
		"supports_parameters": true
	},
	"tc": {
		"name": "transport_cube",
		"file": "transport_cube.tscn",
		"category": "transport",
		"description": "Cube that carries players across voids with directional movement",
		"supports_parameters": true  # distance:direction[:auto] (e.g. "4:z", "3.5:1,0,0", "3:z:auto")
	},
	"br": {
		"name": "bridge_path",
		"file": "bridge_path.tscn",
		"category": "transport",
		"description": "Transparent green grid bridge spanning voids on x/z axis",
		"supports_parameters": true  # axis:length (e.g. "z:3", "-x:2")
	},
	"jp": {
		"name": "jump_pad",
		"file": "jump_pad.tscn",
		"category": "transport",
		"description": "Parabolic arc launcher to target grid position — player becomes the projectile",
		"supports_parameters": true  # target_x:target_z[:arc_height] (e.g. "15:3", "15:3:8")
	},
	"rc": {
		"name": "rotation_cube",
		"file": "rotation_cube.tscn",
		"category": "transport",
		"description": "Cube that rotates to create walkable ramps/surfaces",
		"supports_parameters": true  # angle:axis:pause (e.g. "45:y:2" = 45° on Y, 2s pause) or "continuous:x:30"
	},
	"sc": {
		"name": "scale_cube",
		"file": "scale_cube.tscn",
		"category": "transport",
		"description": "Cube that scales to fill gaps with presence",
		"supports_parameters": true  # max:min:offset (e.g. "3:0.5:1.5" = scale 0.5→3, offset 1.5)
	},
	
	# UI/Information utilities
	"x": {
		"name": "xp_label", 
		"file": "xp_label.tscn", 
		"category": "ui",
		"description": "Experience point displays",
		"supports_parameters": false
	},
	"i": {
		"name": "info_board",
		"file": "info_board.tscn",
		"category": "educational",
		"description": "Information and instruction displays",
		"supports_parameters": false
	},
	"ib": {
		"name": "info_board_handheld",
		"file": "",
		"category": "educational",
		"description": "Handheld 3D info board for algorithm education (ib:randomwalk, ib:vectors, ib:forces, etc.)",
		"supports_parameters": true  # board_type, height_offset
	},
	"la": {
		"name": "label",
		"file": "info_label.tscn",
		"category": "ui",
		"description": "Displays artifact name from the artifact registry by keyid",
		"supports_parameters": true  # keyid parameter
	},

	# Navigation utilities
	"arrow": {
		"name": "exit_arrow", 
		"file": "exit_arrow_scene.tscn", 
		"category": "navigation",
		"description": "Directional indicators and exits",
		"supports_parameters": true  # direction, destination
	},
	
	"bp": {
		"name": "big_pipe",
		"file": "",
		"category": "structure",
		"description": "Procedural pipe system (bp:f,f,s,u...)",
		"supports_parameters": true  # pipe code string
	},

	# Player body customization
	"pb": {
		"name": "player_body_trigger",
		"file": "player_body_trigger.tscn",
		"category": "interactive",
		"description": "Triggers player body customization (pb:dress, pb:skin_color, pb:dress_wicked)",
		"supports_parameters": true  # feature_name, optional color/params
	},

	"ds": {
		"name": "dark_sphere",
		"file": "dark_sphere_utility.tscn",
		"category": "atmosphere",
		"description": "Large dark sphere that envelops the scene — makes artifacts pop against darkness",
		"supports_parameters": true  # radius (default covers entire map)
	},

	# Empty space
	" ": {
		"name": "none",
		"file": "",
		"category": "empty",
		"description": "Empty grid space",
		"supports_parameters": false
	},

	# ─────────────────────────────────────────────────────────────
	# AUTHORIAL ANNOTATIONS (@-prefixed)
	# Invisible at runtime. Read by the map pipeline (validation,
	# reverse-extraction, differential capture, constraint solver).
	# They declare authorial intent the generator must respect.
	# ─────────────────────────────────────────────────────────────
	"@void": {
		"name": "annotation_void",
		"file": "",
		"category": "authorial",
		"description": "Argued emptiness — this cell (or W:D region anchored here) MUST stay empty. Stronger than absence. Generator, placement rules, and biome layers all skip. Params: W:D footprint extending +x/+z from anchor (default 1:1).",
		"supports_parameters": true  # W:D (e.g. "@void:3:2")
	},
	"@look": {
		"name": "annotation_look",
		"file": "",
		"category": "authorial",
		"description": "Change-detection region anchor. Params: W:D cell footprint. Capture pipeline diffs this zone between runs and surfaces deltas.",
		"supports_parameters": true  # W:D (e.g. "@look:3:2")
	},
	"@sample": {
		"name": "annotation_sample",
		"file": "",
		"category": "authorial",
		"description": "Named golden reference region. Generator copies verbatim when scoring similarity. Params: key:W:D — `key` identifies the sample for cross-map reuse (e.g. @sample:pedestal_single:3:3).",
		"supports_parameters": true  # key:W:D
	},
	"@hold": {
		"name": "annotation_hold",
		"file": "",
		"category": "authorial",
		"description": "Frozen region — generator cannot modify ANY cell inside this W:D footprint, whatever the cells contain. Stronger than @void (which forbids placement) and @sample (which reads but doesn't lock).",
		"supports_parameters": true  # W:D
	},
	"@must": {
		"name": "annotation_must",
		"file": "",
		"category": "authorial",
		"description": "Required artifact slot — generator must place the named token here. Params: token name (e.g. @must:rotation_gimbal).",
		"supports_parameters": true
	},
	"@block": {
		"name": "annotation_block",
		"file": "",
		"category": "authorial",
		"description": "Exclusion — the named token may not appear on this map. Params: token name.",
		"supports_parameters": true
	},
	"@signature": {
		"name": "annotation_signature",
		"file": "",
		"category": "authorial",
		"description": "Load-bearing artifact — protected from dimming/shuffling by composition passes. Params: token name.",
		"supports_parameters": true
	},
	"@breath": {
		"name": "annotation_breath",
		"file": "",
		"category": "authorial",
		"description": "Intentional sparse zone — biome layers dim here. Authored breath in a dense sequence.",
		"supports_parameters": false
	},
	"@echo": {
		"name": "annotation_echo",
		"file": "",
		"category": "authorial",
		"description": "Sequence-echo marker — run an earlier sequence's biome layers at this stage. Params: sequence name (e.g. @echo:primitives).",
		"supports_parameters": true
	},
	"@style": {
		"name": "annotation_style",
		"file": "",
		"category": "authorial",
		"description": "Style hint for biome palette/density. Params: style token (kusama|rams|bauhaus|escher|pompeii).",
		"supports_parameters": true
	},
	"@seed": {
		"name": "annotation_seed",
		"file": "",
		"category": "authorial",
		"description": "Deterministic seed override for generation around this cell. Params: integer.",
		"supports_parameters": true
	},
	"@dense": {
		"name": "annotation_dense",
		"file": "",
		"category": "authorial",
		"description": "Per-map density multiplier hint, applied by surrounding generation. Params: float 0..1.",
		"supports_parameters": true
	}
}

# Categories for organizing utilities
const CATEGORIES = {
	"transport": "Transportation and movement utilities",
	"visual": "Visual elements and portals", 
	"structure": "Structural elements and barriers",
	"furniture": "Furniture and static objects",
	"interactive": "Interactive and grabbable objects",
	"authorial": "Authorial annotations — invisible at runtime, read by the pipeline",
	"ui": "User interface elements",
	"educational": "Educational and informational content",
	"navigation": "Navigation aids and indicators",
	"safety": "Checkpoints and reset points",
	"hazard": "Danger zones and environmental hazards",
	"atmosphere": "Scene atmosphere and environmental effects",
	"empty": "Empty space marker"
}

# Empty space constant
const EMPTY_SPACE = " "

# Path constants
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"

# Get utility type info
static func get_utility_info(type_code: String) -> Dictionary:
	if UTILITY_TYPES.has(type_code):
		return UTILITY_TYPES[type_code]
	else:
		push_warning("UtilityRegistry: Unknown utility type '%s'" % type_code)
		return {}

# Check if utility type exists
static func is_valid_utility_type(type_code: String) -> bool:
	return UTILITY_TYPES.has(type_code)

# Get utility scene file path
static func get_utility_scene_path(type_code: String) -> String:
	var info = get_utility_info(type_code)
	if info.has("file") and not info["file"].is_empty():
		return MAP_OBJECTS_PATH + info["file"]
	return ""

# Get utility name
static func get_utility_name(type_code: String) -> String:
	var info = get_utility_info(type_code)
	return info.get("name", "unknown")

# Get utility category
static func get_utility_category(type_code: String) -> String:
	var info = get_utility_info(type_code)
	return info.get("category", "unknown")

# Get utility description
static func get_utility_description(type_code: String) -> String:
	var info = get_utility_info(type_code)
	return info.get("description", "No description available")

# Check if utility supports parameters
static func supports_parameters(type_code: String) -> bool:
	var info = get_utility_info(type_code)
	return info.get("supports_parameters", false)

# Get all utilities by category
static func get_utilities_by_category(category: String) -> Array:
	var result = []
	for type_code in UTILITY_TYPES.keys():
		var info = UTILITY_TYPES[type_code]
		if info.get("category") == category:
			result.append({
				"code": type_code,
				"name": info.get("name"),
				"file": info.get("file"),
				"description": info.get("description")
			})
	return result

# Get all available categories
static func get_all_categories() -> Array:
	return CATEGORIES.keys()

# Get category description
static func get_category_description(category: String) -> String:
	return CATEGORIES.get(category, "Unknown category")

# Validate utility data grid
static func validate_utility_grid(grid_data: Array) -> Dictionary:
	var validation_result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"unknown_types": []
	}
	
	for z in range(grid_data.size()):
		var row = grid_data[z]
		for x in range(row.size()):
			var cell_value = str(row[x]).strip_edges()
			
			# Skip empty cells
			if cell_value.is_empty() or cell_value == " ":
				continue
				
			# Extract base utility type (first character or before first colon)
			var utility_type = cell_value[0] if not cell_value.is_empty() else " "
			if ":" in cell_value:
				utility_type = cell_value.split(":")[0]
			
			# Special handling for info board utilities (ib: prefix)
			if utility_type == "ib":
				# Validate info board type using InfoBoardRegistry
				var board_type = cell_value.split(":")[1] if cell_value.split(":").size() > 1 else ""
				if not InfoBoardRegistry.is_valid_board_type(board_type):
					validation_result.valid = false
					validation_result.errors.append(
						"Invalid info board type '%s' at position [%d, %d]" % [board_type, x, z]
					)
					if not validation_result.unknown_types.has("ib:" + board_type):
						validation_result.unknown_types.append("ib:" + board_type)
				continue  # Skip regular utility validation for info boards
			
			# Check if utility type is valid
			if not is_valid_utility_type(utility_type):
				validation_result.valid = false
				validation_result.errors.append(
					"Unknown utility type '%s' at position [%d, %d]" % [utility_type, x, z]
				)
				if not validation_result.unknown_types.has(utility_type):
					validation_result.unknown_types.append(utility_type)
			
			# Check for parameter usage with non-parameter utilities
			if ":" in cell_value and not supports_parameters(utility_type):
				validation_result.warnings.append(
					"Utility type '%s' at [%d, %d] has parameters but doesn't support them" % [utility_type, x, z]
				)
	
	return validation_result

# Parse utility cell value with parameters
static func parse_utility_cell(cell_value: String) -> Dictionary:
	var result = {
		"type": " ",
		"parameters": []
	}
	
	if cell_value.is_empty():
		return result
		
	var clean_value = cell_value.strip_edges()
	if clean_value.is_empty() or clean_value == " ":
		return result
	
	# Split by colon to separate type from parameters
	var parts = clean_value.split(":")
	result.type = parts[0]
	
	# Extract parameters if they exist
	if parts.size() > 1:
		for i in range(1, parts.size()):
			if not parts[i].is_empty():
				result.parameters.append(parts[i])
	
	return result


## ONE RULE FOR ONE CELL (2026-09-02, Palle: "make sure that the transport cube
## work the same way in the endless museum as in the grid, they only work in the
## grid"). The grid read a `tc` cell in GridUtilitiesComponent and the endless
## museum read it again in its own _utility_apply_params, and a second
## implementation of one rule drifts. It had: the museum's axis test knew only
## "x" and "y" and sent everything else along +Z, so the corpus's most-placed
## form, `tc:1:auto:auto` (425 cells, whose second field is not an axis at all),
## crossed +X in the grid and +Z in the museum; and the museum turned auto_start
## ON for any two-parameter cell, where the grid leaves the cube waiting for a
## body unless the word `auto` is written. Both callers now ask this function.
##
## The grammar, unchanged: tc:DISTANCE:DIRECTION[:auto]
##   DIRECTION is x, y, z, -x, -y, -z, or three comma-separated numbers.
##   Anything else leaves the cube's own default, +X — which is what the grid
##   has always done with it, and what those 425 cells were laid against.
## `applied` is false when there are fewer than two parameters: the grid sets
## nothing at all in that case, and the cube keeps every exported default.
static func transport_params(parameters: Array) -> Dictionary:
	var out := {"distance": 4.0, "direction": Vector3(1, 0, 0), "auto": false, "applied": false}
	if parameters.size() < 2:
		return out
	out["applied"] = true
	out["distance"] = float(parameters[0])
	var dp := String(parameters[1]).strip_edges().to_lower()
	match dp:
		"x":  out["direction"] = Vector3(1, 0, 0)
		"y":  out["direction"] = Vector3(0, 1, 0)
		"z":  out["direction"] = Vector3(0, 0, 1)
		"-x": out["direction"] = Vector3(-1, 0, 0)
		"-y": out["direction"] = Vector3(0, -1, 0)
		"-z": out["direction"] = Vector3(0, 0, -1)
		_:
			var coords := dp.split(",")
			if coords.size() >= 3:
				out["direction"] = Vector3(coords[0].to_float(), coords[1].to_float(), coords[2].to_float())
	if parameters.size() >= 3:
		out["auto"] = String(parameters[2]).strip_edges().to_lower() == "auto"
	return out


## WHO THE CUBE CAN SEE. transport_cube ships with its DetectionArea masking
## layer 20 alone — the grid's player layer — and it is that area, not the
## unused CarryArea beside it, that sets `carried_player` and starts the ride.
## The endless museum's walker is a bare CharacterBody3D on the default layer,
## so a cube stamped into a hall watched a body stand on it and did nothing.
## Widen the carrier rather than moving the walker onto layer 20: that layer is
## also read by danger_zone, next_cube and every pick-up in the corpus, and
## being seen by all of them is not what was asked for. Returns how many areas
## were widened, so a caller can say so rather than assume it.
static func make_carriable(node: Node3D) -> int:
	if node == null:
		return 0
	var widened := 0
	for a_v in node.find_children("*", "Area3D", true, false):
		var ar := a_v as Area3D
		if ar != null and (ar.collision_mask & 1) == 0:
			ar.collision_mask |= 1
			widened += 1
	return widened



## ONE RULE, ONE DOOR (2026-09-05, Palle: "can we either improve the utilities so
## they work similarly as in the grid, or should we change them to be
## artifacts?" - improve them). The grid read rc/sc/br/jp cells in
## GridUtilitiesComponent and the endless museum read them again in its own
## copy, and the copy had drifted: the scale cube's minimum went onto the
## property unsanitised (both corpus forms say -0.5; the scene's own setter
## lifts that to 0.001), a bridge's sign was dropped (br:-x:2 pointed +x), and a
## jump pad's target was written to properties that do not exist, so every
## museum pad aimed at cell (0,0). tc moved here on 2026-09-02. From today the
## PARSE (the *_params functions) and the APPLY (apply_params: the scene's own
## setters when it has them) live here and both callers ask. Every corpus form
## is held against the grid's old reading by
## commons/testing/probe_utility_parity.gd.

## The grid's axis words: x, y, z, -x, -y, -z; anything else keeps `fallback`.
static func axis_of(word: String, fallback: Vector3) -> Vector3:
	match word.strip_edges().to_lower():
		"x": return Vector3.RIGHT
		"y": return Vector3.UP
		"z": return Vector3.BACK
		"-x": return Vector3.LEFT
		"-y": return Vector3.DOWN
		"-z": return Vector3.FORWARD
		_: return fallback


## rc:ANGLE:AXIS:PAUSE:Y_OFFSET (e.g. "90:y:4:-0.6"), or rc:continuous:AXIS:SPEED.
## The grid's defaults when a field is omitted: axis y, pause 4 s, y_offset 0.
## `continuous` is the registry's documented second form; the grid's old branch
## put the word through float() and rotated by 0 degrees. That is the one place
## the shared rule departs from the old grid reading, on purpose, and the probe
## records it.
static func rotation_params(parameters: Array) -> Dictionary:
	var out := {"applied": false, "mode": "step", "angle": 45.0, "axis": Vector3.UP, "pause": 4.0,
		"y_offset": 0.0, "continuous_axis": Vector3.RIGHT, "continuous_speed": 30.0}
	if parameters.size() < 1:
		return out
	out["applied"] = true
	var first := String(parameters[0]).strip_edges().to_lower()
	if first == "continuous":
		out["mode"] = "continuous"
		if parameters.size() >= 2:
			out["continuous_axis"] = axis_of(String(parameters[1]), Vector3.RIGHT)
		if parameters.size() >= 3 and String(parameters[2]).is_valid_float():
			out["continuous_speed"] = String(parameters[2]).to_float()
		return out
	out["angle"] = String(parameters[0]).to_float()
	if parameters.size() >= 2:
		out["axis"] = axis_of(String(parameters[1]), Vector3.UP)
	if parameters.size() >= 3:
		out["pause"] = String(parameters[2]).to_float()
	if parameters.size() >= 4:
		out["y_offset"] = String(parameters[3]).to_float()
	return out


## sc:MAX:MIN:OFFSET_X:Y_OFFSET (e.g. "3:-0.5:1:0"). The grid's defaults when a
## field is omitted: min 0.5, offset 1.5, y_offset 0. The scene sanitises the
## range in set_scale_range (a minimum under 0.001 is lifted, a reversed pair
## swapped); the museum's copy wrote the raw -0.5 onto the property.
static func scale_params(parameters: Array) -> Dictionary:
	var out := {"applied": false, "max_scale": 3.0, "min_scale": 0.5, "offset_x": 1.5, "y_offset": 0.0}
	if parameters.size() < 1:
		return out
	out["applied"] = true
	out["max_scale"] = String(parameters[0]).to_float()
	if parameters.size() >= 2:
		out["min_scale"] = String(parameters[1]).to_float()
	if parameters.size() >= 3:
		out["offset_x"] = String(parameters[2]).to_float()
	if parameters.size() >= 4:
		out["y_offset"] = String(parameters[3]).to_float()
	return out


## br:AXIS:LENGTH (e.g. "z:3", "-x:2"): the axis is one of x, z, -x, -z, anything
## else is x; the length is a whole number, else 4. The corpus also holds
## "br:5:x" and "br:3:z" - number first - which the grid has always read as
## "4 along x"; the rule stays the grid's, and the probe lists them.
static func bridge_params(parameters: Array) -> Dictionary:
	var out := {"applied": false, "axis": "x", "length": 4}
	if parameters.size() < 1:
		return out
	out["applied"] = true
	var a := String(parameters[0]).strip_edges().to_lower()
	if a in ["x", "z", "-x", "-z"]:
		out["axis"] = a
	if parameters.size() >= 2 and String(parameters[1]).is_valid_int():
		out["length"] = int(String(parameters[1]))
	return out


## jp:TARGET_X:TARGET_Z[:ARC_HEIGHT] (e.g. "17:11:8"); the arc is 6 when omitted.
static func jump_params(parameters: Array) -> Dictionary:
	var out := {"applied": false, "target_x": 0, "target_z": 0, "arc_height": 6.0}
	if parameters.size() < 2:
		return out
	out["applied"] = true
	out["target_x"] = int(String(parameters[0]))
	out["target_z"] = int(String(parameters[1]))
	if parameters.size() >= 3 and String(parameters[2]).is_valid_float():
		out["arc_height"] = String(parameters[2]).to_float()
	return out


## APPLY one cell to its scene the way the grid always has: the scene's own
## setters when it has them, its exported properties when it has not. Returns
## the parsed config with `applied`, plus a `summary` line for the caller's log.
## ctx: "cube_size" and "gutter" for a jump pad's grid spacing (the museum's
## cells are 1 m with no gutter), and "landing_y" for the structure-aware
## landing height only the grid can compute. The grid's ORDER for a pad is kept
## as it was: set_grid_spacing recomputes the target after the landing height
## is written, and that recompute puts y back to 0 - the grid has always landed
## its pads at y = 0. Not changed here; noted 2026-09-05.
static func apply_params(node: Node3D, code: String, parameters: Array, ctx: Dictionary = {}) -> Dictionary:
	if node == null:
		return {}
	match code:
		"tc":
			var t: Dictionary = transport_params(parameters)
			if bool(t["applied"]):
				var dist: float = float(t["distance"])
				var dir: Vector3 = t["direction"]
				if node.has_method("set_transport_parameters"):
					node.call("set_transport_parameters", dist, dir)
				else:
					node.set("move_distance", dist)
					node.set("move_direction", dir.normalized())
				if bool(t["auto"]):
					if node.has_method("set_auto_start"):
						node.call("set_auto_start", true)
					else:
						node.set("auto_start", true)
				t["summary"] = "Set transport cube to move %.1f units in direction %s%s" % [
					dist, dir, " (AUTO-START)" if bool(t["auto"]) else ""]
			return t
		"rc":
			var r: Dictionary = rotation_params(parameters)
			if bool(r["applied"]):
				if String(r["mode"]) == "continuous":
					if node.has_method("set_continuous_mode"):
						node.call("set_continuous_mode", r["continuous_axis"], float(r["continuous_speed"]))
					else:
						node.set("mode", 1)
						node.set("continuous_axis", r["continuous_axis"])
						node.set("continuous_speed", float(r["continuous_speed"]))
					r["summary"] = "Set rotation cube continuous on %s at %.1f deg/s" % [
						r["continuous_axis"], float(r["continuous_speed"])]
				else:
					if node.has_method("set_step_pause_mode"):
						node.call("set_step_pause_mode", float(r["angle"]), r["axis"], float(r["pause"]))
					else:
						node.set("rotation_angle", float(r["angle"]))
						node.set("rotation_axis", r["axis"])
						node.set("pause_duration", float(r["pause"]))
					if "y_offset" in node:
						node.set("y_offset", float(r["y_offset"]))
					r["summary"] = "Set rotation cube to %.1f deg on %s, %.1fs pause, y=%.1f" % [
						float(r["angle"]), r["axis"], float(r["pause"]), float(r["y_offset"])]
			return r
		"sc":
			var s: Dictionary = scale_params(parameters)
			if bool(s["applied"]):
				var mn: float = float(s["min_scale"])
				var mx: float = float(s["max_scale"])
				if node.has_method("set_scale_range"):
					node.call("set_scale_range", mn, mx)
				else:
					if "min_scale" in node:
						node.set("min_scale", mn)
					if "max_scale" in node:
						node.set("max_scale", mx)
				var off := Vector3(float(s["offset_x"]), 0, 0)
				if node.has_method("set_offset"):
					node.call("set_offset", off)
				elif "center_offset" in node:
					node.set("center_offset", off)
				if "y_offset" in node:
					node.set("y_offset", float(s["y_offset"]))
				s["summary"] = "Set scale cube %.1f->%.1f, offset_x=%.1f, y=%.1f" % [
					mn, mx, float(s["offset_x"]), float(s["y_offset"])]
			return s
		"br":
			var b: Dictionary = bridge_params(parameters)
			if bool(b["applied"]):
				if node.has_method("set_bridge_parameters"):
					node.call("set_bridge_parameters", int(b["length"]), String(b["axis"]))
				else:
					node.set("bridge_length", int(b["length"]))
					node.set("bridge_axis", String(b["axis"]))
				b["summary"] = "Set bridge path %d segments along %s" % [int(b["length"]), String(b["axis"])]
			return b
		"jp":
			var j: Dictionary = jump_params(parameters)
			if bool(j["applied"]):
				var ts: float = float(ctx.get("cube_size", 1.0)) + float(ctx.get("gutter", 0.0))
				if node.has_method("apply_grid_config"):
					node.call("apply_grid_config", {"target_x": int(j["target_x"]), "target_z": int(j["target_z"]),
						"arc_height": float(j["arc_height"])})
				if ctx.has("landing_y") and "target_world_pos" in node:
					node.set("target_world_pos", Vector3(float(j["target_x"]) * ts + ts * 0.5,
						float(ctx["landing_y"]), float(j["target_z"]) * ts + ts * 0.5))
				if node.has_method("set_grid_spacing") and ctx.has("cube_size"):
					node.call("set_grid_spacing", float(ctx["cube_size"]), float(ctx.get("gutter", 0.0)))
				j["summary"] = "Jump pad -> target grid (%d,%d), arc=%.1f" % [
					int(j["target_x"]), int(j["target_z"]), float(j["arc_height"])]
			return j
	return {}


## THE RIDE IS A SPAN (moved out of the museum's utility door, 2026-09-05, so the
## hall that embeds the real grid can ask the same question): the cells a
## configured transport cube's travel covers, its start first - read off the
## node, so this is the cube's own answer and not a second reading of the cell.
static func transport_span(node: Node3D, start: Vector2i) -> Array:
	var out: Array = [start]
	if node == null:
		return out
	var dv: Variant = node.get("move_direction")
	var dirv: Vector3 = dv if dv is Vector3 else Vector3(0, 0, 1)
	var mv: Variant = node.get("move_distance")
	var distv: float = float(mv) if mv != null else 4.0
	var sgn: float = 1.0 if distv >= 0.0 else -1.0
	for s in range(1, int(ceil(absf(distv))) + 1):
		var step: float = float(s) * sgn
		out.append(Vector2i(start.x + int(round(dirv.x * step)), start.y + int(round(dirv.z * step))))
	return out


# Generate utility type mapping comment for data files
static func generate_utility_mapping_comment() -> String:
	var comment_lines = [
		"# Utility type mapping (auto-generated - do not edit manually)",
		"# Generated by UtilityRegistry.gd - single source of truth for utility types"
	]
	
	# Group by category
	var categories_used = {}
	for type_code in UTILITY_TYPES.keys():
		if type_code == " ":
			continue
		var category = get_utility_category(type_code)
		if not categories_used.has(category):
			categories_used[category] = []
		categories_used[category].append(type_code)
	
	# Add category sections
	for category in categories_used.keys():
		comment_lines.append("# %s:" % category.capitalize())
		for type_code in categories_used[category]:
			var name = get_utility_name(type_code)
			var desc = get_utility_description(type_code)
			comment_lines.append("# \"%s\": %s - %s" % [type_code, name, desc])
		comment_lines.append("#")
	
	comment_lines.append("# \" \": empty space (no utility)")
	
	return "\n".join(comment_lines)

# Print utility registry summary
static func print_registry_summary():
	print("=== Utility Registry Summary ===")
	print("Total utility types: %d" % (UTILITY_TYPES.size() - 1))  # -1 for empty space
	print("Categories: %d" % CATEGORIES.size())
	
	for category in CATEGORIES.keys():
		if category == "empty":
			continue
		var utilities = get_utilities_by_category(category)
		print("  %s (%d): %s" % [category.capitalize(), utilities.size(), CATEGORIES[category]])
		for utility in utilities:
			var param_support = " (supports parameters)" if supports_parameters(utility.code) else ""
			print("    %s: %s%s" % [utility.code, utility.name, param_support]) 
