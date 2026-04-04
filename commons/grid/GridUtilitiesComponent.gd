# GridUtilitiesComponent.gd
# Handles utility object placement (teleports, lifts, doors, etc.)
# Uses UtilityRegistry for type definitions and validation

extends Node
class_name GridUtilitiesComponent

# Path constants - CORRECTED TO MATCH ACTUAL PROJECT STRUCTURE
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"
const DEFAULT_TEXT_DISPLAY := "A POINT IS ENTROPY THAT HAS COOLED INTO MEMORY."

# References
var parent_node: Node3D
var structure_component: GridStructureComponent

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0
var map_settings: Dictionary = {}

# Utility objects tracking
var utility_objects: Dictionary = {}
var scene_cache: Dictionary = {}

# Cached utility layout for cross-referencing (e.g. m:t:name lookups)
var _cached_utility_layout: Array = []

# Signals
signal utility_generation_complete(utility_count: int)
signal utility_activated(utility_type: String, position: Vector3, data: Dictionary)

func _ready():
	print("GridUtilitiesComponent: Initialized")

# Initialize with references and settings
func initialize(grid_parent: Node3D, struct_component: GridStructureComponent, settings: Dictionary = {}):
	parent_node = grid_parent
	structure_component = struct_component

	# Apply settings
	map_settings = settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)

	print("GridUtilitiesComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Generate Big Pipe System
func _generate_big_pipe(bp_code: String, start_pos: Vector3 = Vector3.ZERO) -> void:
	print("GridUtilitiesComponent: Generating Big Pipe System at %s with code: %s" % [start_pos, bp_code])

	# Create BigPipeSystem instance (using global class_name)
	var pipe_system = BigPipeSystem.new()
	pipe_system.name = "BigPipeSystem"
	pipe_system.position = start_pos

	# Configure pipe parameters to align with grid
	pipe_system.segment_length = cube_size + gutter
	pipe_system.pipe_radius = (cube_size * 0.5) * 0.8 # Fit inside grid cell

	# Generate geometry
	pipe_system.generate_pipes(bp_code)

	# Add to scene
	parent_node.add_child(pipe_system)


# Preprocess map layers for select-repeat (sr) utilities
static func preprocess_select_repeat(layers: Dictionary) -> Dictionary:
	if not layers.has("utilities"):
		return layers

	var utilities = layers.utilities
	var structure = layers.get("structure", [])
	var interactables = layers.get("interactables", [])

	# Scan for sr utilities
	for z in range(utilities.size()):
		var row = utilities[z]
		for x in range(row.size()):
			var cell = str(row[x]).strip_edges()
			if cell.begins_with("sr:"):
				# Parse sr:start:end:count
				var parts = cell.split(":")
				if parts.size() >= 4:
					var start_idx = int(parts[1])
					var end_idx = int(parts[2])
					var repeat_count = int(parts[3])

					print("GridUtilitiesComponent: Processing sr:%d:%d:%d at position (%d,%d)" % [start_idx, end_idx, repeat_count, x, z])

					# Apply the repeat operation
					layers = _apply_select_repeat(layers, start_idx, end_idx, repeat_count, z)

	return layers

# Apply select-repeat operation to all layers
static func _apply_select_repeat(layers: Dictionary, start_idx: int, end_idx: int, repeat_count: int, insert_after: int) -> Dictionary:
	# Extract the range (in order, not reversed)
	var selected_rows_structure = []
	var selected_rows_utilities = []
	var selected_rows_interactables = []

	# Extract rows from start to end (in order)
	for i in range(start_idx, end_idx + 1):
		if layers.structure.size() > i:
			selected_rows_structure.append(layers.structure[i].duplicate())
		if layers.utilities.size() > i:
			selected_rows_utilities.append(layers.utilities[i].duplicate())
		if layers.has("interactables") and layers.interactables.size() > i:
			selected_rows_interactables.append(layers.interactables[i].duplicate())

	# Repeat the selection 'repeat_count' times
	var new_structure = []
	var new_utilities = []
	var new_interactables = []

	# Copy everything up to insert_after
	for i in range(min(insert_after + 1, layers.structure.size())):
		new_structure.append(layers.structure[i].duplicate())
		if layers.utilities.size() > i:
			new_utilities.append(layers.utilities[i].duplicate())
		if layers.has("interactables") and layers.interactables.size() > i:
			new_interactables.append(layers.interactables[i].duplicate())

	# Insert repeated selections
	for rep in range(repeat_count):
		for row in selected_rows_structure:
			new_structure.append(row.duplicate())
		for row in selected_rows_utilities:
			new_utilities.append(row.duplicate())
		for row in selected_rows_interactables:
			new_interactables.append(row.duplicate())

	# Copy the rest
	for i in range(insert_after + 1, layers.structure.size()):
		new_structure.append(layers.structure[i].duplicate())
		if layers.utilities.size() > i:
			new_utilities.append(layers.utilities[i].duplicate())
		if layers.has("interactables") and layers.interactables.size() > i:
			new_interactables.append(layers.interactables[i].duplicate())

	# Update layers
	layers.structure = new_structure
	layers.utilities = new_utilities
	if layers.has("interactables"):
		layers.interactables = new_interactables

	print("GridUtilitiesComponent: ✅ Applied sr - Selected %d rows, repeated %d times. New grid size: %d" % [selected_rows_structure.size(), repeat_count, new_structure.size()])

	return layers

# Generate utilities from data
func generate_utilities(utility_data, utility_definitions: Dictionary = {}):
	if not utility_data:
		print("GridUtilitiesComponent: No utility data provided")
		return

	if not utility_data.layout_data:
		print("GridUtilitiesComponent: No layout_data in utility data")
		return

	print("GridUtilitiesComponent: Generating utilities")

	var utility_layout = utility_data.layout_data
	_cached_utility_layout = utility_layout  # Cache for m:t:name lookups
	var total_size = cube_size + gutter
	var utility_count = 0

	# Get grid dimensions from structure component
	var dimensions = structure_component.get_grid_dimensions()

	# Validate utilities using UtilityRegistry
	var validation = UtilityRegistry.validate_utility_grid(utility_layout)
	if not validation.valid:
		print("GridUtilitiesComponent: WARNING - Utility validation issues:")
		for error in validation.errors:
			print("  ERROR: %s" % error)
		for warning in validation.warnings:
			print("  WARNING: %s" % warning)

	# Separate info board utilities and tutorial text displays from regular utilities
	var info_board_data = []
	var tutorial_display_data = []
	var regular_utilities = []

	# Place utilities
	for z in range(min(dimensions.z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(dimensions.x, row.size())):
			var utility_cell = str(row[x]).strip_edges()

			if utility_cell.is_empty() or utility_cell == " ":
				continue

			# Check if this is an info board utility (ib: prefix)
			if utility_cell.begins_with("ib:"):
				# Handle info board utilities
				var board_data = _parse_info_board_utility(utility_cell, x, z)
				if not board_data.is_empty():
					info_board_data.append(board_data)
				utility_count += 1
			# Check if this is a tutorial text display (tt: prefix)
			elif utility_cell.begins_with("tt:"):
				# Handle tutorial text displays
				var display_data = _parse_tutorial_display_utility(utility_cell, x, z)
				if not display_data.is_empty():
					tutorial_display_data.append(display_data)
				utility_count += 1
			# Check if this is a border frame utility (bf: prefix)
			elif utility_cell.begins_with("bf:"):
				# Handle border frame utilities
				var border_data = _parse_border_frame_utility(utility_cell, x, z)
				if not border_data.is_empty():
					_generate_border_frame(border_data)
				utility_count += 1
			# Check if this is a Big Pipe System (bp: prefix)
			elif utility_cell.begins_with("bp:"):
				var bp_data = _parse_big_pipe_utility(utility_cell, x, z)
				if not bp_data.is_empty():
					_generate_big_pipe(bp_data.code, bp_data.position)
				utility_count += 1
			# Check if this is a Force Field (f: prefix) — dual-nature hazard/benefit
			elif utility_cell.begins_with("f:"):
				var y_pos = structure_component.find_highest_y_at(x, z)
				_place_force_field(utility_cell, x, y_pos, z, total_size)
				utility_count += 1
			else:
				# Handle regular utilities
				var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
				var utility_type = parsed.type

				# Check settings for Infoboard ("an")
				if utility_type == "an" and not GameManager.show_infoboard:
					print("GridUtilitiesComponent: Skipping Infoboard due to user setting")
					continue
				var parameters = parsed.parameters

				if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
					var y_pos = structure_component.find_highest_y_at(x, z)

					# Get utility definition if available
					var utility_definition = utility_definitions.get(utility_type, {})

					# Ensure utility_definition is always a Dictionary (handle string references)
					if typeof(utility_definition) != TYPE_DICTIONARY:
						print("GridUtilitiesComponent: Note - Using external utility reference for '%s': %s" % [utility_type, str(utility_definition)])
						utility_definition = {}

					_place_utility(x, y_pos, z, utility_type, parameters, utility_definition, total_size)
					utility_count += 1

	# Generate info boards if any were found
	if not info_board_data.is_empty():
		_generate_info_boards(info_board_data)

	# Generate tutorial displays if any were found
	if not tutorial_display_data.is_empty():
		_generate_tutorial_displays(tutorial_display_data)

	print("GridUtilitiesComponent: Added %d utilities" % utility_count)
	utility_generation_complete.emit(utility_count)

# Parse Big Pipe utility string
func _parse_big_pipe_utility(cell_value: String, x: int, z: int) -> Dictionary:
	# Format: bp:code or bp:code
	# Code: f,f,s,u...
	var parts = cell_value.split(":")
	var code = ""

	if parts.size() > 1:
		# Join rest of parts back together in case code has colons (unlikely but safe)
		# Actually code is usually comma separated.
		# bp:f,f,s
		code = parts[1]

	if code.is_empty():
		return {}

	# Calculate position
	var y = structure_component.find_highest_y_at(x, z)
	var total_size = cube_size + gutter
	var pos = Vector3(x, y, z) * total_size

	return {
		"code": code,
		"position": pos
	}

# Find the grid position of a teleport by sequence name (scans cached utility layout)
# Returns Vector3i(col, 0, row) or Vector3i(-1,-1,-1) if not found
func _find_teleport_grid_position(sequence_name: String) -> Vector3i:
	var target_prefix = "t:" + sequence_name
	for z in range(_cached_utility_layout.size()):
		var row = _cached_utility_layout[z]
		for x_col in range(row.size()):
			var cell = str(row[x_col]).strip_edges()
			if cell.begins_with(target_prefix):
				# Verify it's the right teleport (not t:wavefunctions matching t:wave)
				var remainder = cell.substr(target_prefix.length())
				if remainder.is_empty() or remainder.begins_with(":"):
					return Vector3i(x_col, 0, z)
	return Vector3i(-1, -1, -1)

# Find the nearest cell with structure value "1" (flat ground floor)
# Searches in expanding radius around the given position
# A cell is "structure 1" if it has a cube at y=0 but NOT at y=1
# Also avoids cells with teleports on them
# Returns Vector2i(col, row) of the safe cell, or best fallback
func _find_safe_adjacent_cell(grid_x: int, grid_z: int) -> Vector2i:
	var dims = structure_component.get_grid_dimensions()
	var best_fallback := Vector2i(grid_x + 1, grid_z)
	var found_any_floor := false

	# Search in expanding radius (1 to 5 cells away)
	for radius in range(1, 6):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				# Only check cells at this exact radius (ring, not filled square)
				if abs(dx) != radius and abs(dz) != radius:
					continue

				var check_x = grid_x + dx
				var check_z = grid_z + dz

				# Bounds check
				if check_x < 0 or check_x >= dims.x or check_z < 0 or check_z >= dims.z:
					continue

				# Check for structure == "1": cube at y=0 but not y=1
				var has_ground = structure_component.has_cube_at(check_x, 0, check_z)
				if not has_ground:
					continue

				var has_above = structure_component.has_cube_at(check_x, 1, check_z)

				# Skip cells with teleports
				var has_teleport := false
				if check_z < _cached_utility_layout.size() and check_x < _cached_utility_layout[check_z].size():
					var util_cell = str(_cached_utility_layout[check_z][check_x]).strip_edges()
					if util_cell.begins_with("t:"):
						has_teleport = true

				if has_teleport:
					continue

				# Track best fallback (any walkable floor)
				if not found_any_floor:
					best_fallback = Vector2i(check_x, check_z)
					found_any_floor = true

				# Ideal: structure "1" - flat ground, no wall above
				if not has_above:
					print("GridUtilitiesComponent: Safe flat floor (structure=1) at grid(%d,%d), %d cells from teleport" % [check_x, check_z, radius])
					return Vector2i(check_x, check_z)

	# If no structure=1 found, use best fallback
	print("GridUtilitiesComponent: WARNING - No structure=1 cell found near grid(%d,%d), using fallback grid(%d,%d)" % [grid_x, grid_z, best_fallback.x, best_fallback.y])
	return best_fallback

# Place a single utility object
func _place_utility(x: int, y: int, z: int, utility_type: String, parameters: Array, definition: Dictionary, total_size: float):
	var position = Vector3(x, y, z) * total_size

	var scene_path = UtilityRegistry.get_utility_scene_path(utility_type)
	if scene_path.is_empty():
		print("GridUtilitiesComponent: WARNING - No scene file for utility type '%s'" % utility_type)
		return

	var scene_resource = _load_scene_cached(UtilityRegistry.get_utility_info(utility_type).file)
	if not scene_resource:
		print("GridUtilitiesComponent: WARNING - Could not load scene for utility type '%s'" % utility_type)
		return

	var utility_object = scene_resource.instantiate()
	if utility_object:
		utility_object.position = position
		if utility_type == "br":
			# Bridges should sit slightly lower to align with surrounding walkable surfaces.
			utility_object.position.y -= 0.1

		# Apply parameters if supported
		print("GridUtilitiesComponent: Utility type '%s' has %d parameters: %s" % [utility_type, parameters.size(), str(parameters)])
		if parameters.size() > 0 and UtilityRegistry.supports_parameters(utility_type):
			print("GridUtilitiesComponent: Applying parameters for utility type '%s'" % utility_type)
			_apply_utility_parameters(utility_object, utility_type, parameters)
		else:
			print("GridUtilitiesComponent: No parameters to apply for utility type '%s' (supports: %s)" % [utility_type, UtilityRegistry.supports_parameters(utility_type)])

		# Apply definition properties
		_apply_utility_definition(utility_object, utility_type, definition)

		# Connect signals if utility has them
		_connect_utility_signals(utility_object, utility_type)

		# Add to utility group for desktop interaction
		utility_object.add_to_group("utility")

		parent_node.add_child(utility_object)

		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			utility_object.owner = parent_node.get_tree().edited_scene_root

		utility_objects[Vector3i(x, y, z)] = utility_object

		var param_info = ""
		if parameters.size() > 0:
			param_info = " (params: %s)" % str(parameters)
		print("  Added %s at (%d,%d,%d)%s" % [UtilityRegistry.get_utility_name(utility_type), x, y, z, param_info])


## Place a ForceField from notation like f:fire:1.5
func _place_force_field(cell_value: String, x: int, y: int, z: int, total_size: float) -> void:
	var parts: PackedStringArray = cell_value.split(":")
	var force_type_str: String = "fire"
	var intensity: float = 1.0

	if parts.size() > 1:
		force_type_str = parts[1].strip_edges().to_lower()
	if parts.size() > 2 and parts[2].is_valid_float():
		intensity = float(parts[2])

	var force_field: ForceField = ForceField.new()
	force_field.force_type = ForceTransmutationConfig.parse_force_type(force_type_str) as ForceField.ForceType
	force_field.force_intensity = intensity
	force_field.position = Vector3(x, y, z) * total_size
	force_field.add_to_group("utility")

	parent_node.add_child(force_field)
	utility_objects[Vector3i(x, y, z)] = force_field

	print("  Added ForceField (%s, intensity=%.1f) at (%d,%d,%d)" % [force_type_str, intensity, x, y, z])


# Apply utility-specific parameters parsed from map notation (e.g. "t:next:3", "jp:15:3:8")
func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array):
	var normalized_type = utility_type.to_lower()
	match normalized_type:
		"t":  # Teleport
			var destination = ""
			var height_offset = 0.0
			var has_explicit_destination = false

			# Parse parameters: can be t, t:next, t:next:3, t:3, t:mapname, t:mapname:2
			if parameters.size() > 0:
				var first_param = parameters[0]

				# If first param is numeric, treat it as height offset only
				if first_param.is_valid_float():
					height_offset = float(first_param)
					# Don't set destination - let utility_definitions handle it
				# If first param is "next", it's explicit but handled by utility_definitions
				elif first_param == "next":
					# Don't set destination - let utility_definitions handle it
					# Check for height offset in second parameter
					if parameters.size() > 1:
						var second_param = parameters[1]
						if second_param.is_valid_float():
							height_offset = float(second_param)
				# Otherwise it's a specific map destination
				else:
					destination = first_param
					has_explicit_destination = true

					# Check for height offset in second parameter
					if parameters.size() > 1:
						var second_param = parameters[1]
						if second_param.is_valid_float():
							height_offset = float(second_param)

			# Only set destination if explicitly provided (not "next" or numeric-only)
			if has_explicit_destination:
				if "destination" in utility_object:
					utility_object.destination = destination
				else:
					utility_object.set_meta("destination", destination)

				# Set scene name for display label
				if "scene_name" in utility_object:
					utility_object.scene_name = destination

				print("GridUtilitiesComponent: Set teleporter destination to: %s" % destination)
			else:
				print("GridUtilitiesComponent: Teleporter using default 'next_in_sequence' behavior from utility_definitions")

			# Apply height offset if specified
			if height_offset != 0.0:
				if "height_offset" in utility_object:
					utility_object.height_offset = height_offset
				else:
					utility_object.set_meta("height_offset", height_offset)

				# Adjust the teleporter's vertical position
				utility_object.position.y += height_offset

				print("GridUtilitiesComponent: Set teleporter height offset to: %f" % height_offset)
		"l":  # Lift
			if parameters.size() > 0 and "height" in utility_object:
				utility_object.height = float(parameters[0])
		"s":  # Spawn point
			if parameters.size() >= 3:
				# Format: s:x:y:z (grid coordinates)
				var x_param = parameters[0].strip_edges()
				var y_param = parameters[1].strip_edges()
				var z_param = parameters[2].strip_edges()

				if x_param.is_valid_float() and y_param.is_valid_float() and z_param.is_valid_float():
					var spawn_x = float(x_param)
					var spawn_y = float(y_param)
					var spawn_z = float(z_param)

					# Store coordinates as metadata for GridSpawnComponent to use
					utility_object.set_meta("spawn_coordinates", Vector3(spawn_x, spawn_y, spawn_z))
					print("GridUtilitiesComponent: ✅ Set spawn coordinates to (%.1f, %.1f, %.1f) on utility object: %s" % [spawn_x, spawn_y, spawn_z, utility_object.name])
				else:
					print("GridUtilitiesComponent: WARNING - Invalid spawn coordinates in parameters: %s" % parameters)
			elif parameters.size() > 0:
				# Legacy support: spawn name parameter
				utility_object.set_meta("spawn_name", parameters[0])
				print("GridUtilitiesComponent: Set spawn name to: %s" % parameters[0])
		"wp":  # Walkable prism
			if parameters.size() > 0:
				var rotation_y = float(parameters[0])
				utility_object.rotation_degrees.y = rotation_y
				print("GridUtilitiesComponent: Set walkable prism rotation to: %f degrees" % rotation_y)
			if parameters.size() > 1:
				var color_param = parameters[1]
				_apply_color_to_utility(utility_object, color_param)
				print("GridUtilitiesComponent: Applied color '%s' to walkable prism" % color_param)
		"el":  # Extra light
			var energy_value = null
			if parameters.size() > 0:
				var raw_energy := str(parameters[0]).strip_edges()
				if not raw_energy.is_empty():
					if raw_energy.is_valid_float():
						energy_value = raw_energy.to_float()
					else:
						print("GridUtilitiesComponent: WARNING - Invalid light energy value %s for extra light" % raw_energy)
			if energy_value != null:
				if utility_object.has_method("set_light_intensity"):
					utility_object.set_light_intensity(energy_value)
				else:
					var light_node := utility_object.get_node_or_null("StaticBody3D/OmniLight3D")
					if light_node:
						light_node.light_energy = max(energy_value, 0.0)
				print("GridUtilitiesComponent: Set extra light intensity to %.2f" % energy_value)
			var hide_flag_set := false
			var hide_flag := false
			if parameters.size() > 1:
				var raw_hide := str(parameters[1]).strip_edges()
				if not raw_hide.is_empty():
					if raw_hide.is_valid_int():
						hide_flag = raw_hide.to_int() != 0
						hide_flag_set = true
					elif raw_hide.is_valid_float():
						hide_flag = raw_hide.to_float() != 0.0
						hide_flag_set = true
					else:
						hide_flag = raw_hide.to_lower() in ["true", "yes"]
						hide_flag_set = true
			if hide_flag_set:
				if utility_object.has_method("set_fixture_hidden"):
					utility_object.set_fixture_hidden(hide_flag)
				else:
					var static_body := utility_object.get_node_or_null("StaticBody3D")
					if static_body:
						var collision_shape := static_body.get_node_or_null("CollisionShape3D")
						if collision_shape and collision_shape is CollisionShape3D:
							collision_shape.disabled = hide_flag
						var mesh_node := static_body.get_node_or_null("MeshInstance3D_lightbody")
						if mesh_node == null:
							mesh_node = static_body.get_node_or_null("MeshInstance3D")
						if mesh_node and mesh_node is Node3D:
							mesh_node.visible = not hide_flag
				print("GridUtilitiesComponent: Set extra light fixture hidden=%s" % str(hide_flag))
		"3t":  # Text display
			var text_value = _build_text_display_message(parameters)
			utility_object.set_meta("display_text", text_value)
			_apply_text_display_text(utility_object, text_value)
			print("GridUtilitiesComponent: Set 3t text to '%s'" % text_value)
		"tts":  # Text to Speech
			var message = _build_text_display_message(parameters)
			if "message" in utility_object:
				utility_object.message = message
				print("GridUtilitiesComponent: Set TTS message to '%s'" % message)
		"sr":  # Speed reader
			var sr_key = ""
			if parameters.size() > 0:
				sr_key = parameters[0].strip_edges().to_lower()
			var sr_speed = -1.0
			var sr_loop = false
			for i in range(1, parameters.size()):
				var raw = str(parameters[i]).strip_edges()
				var lowered = raw.to_lower()
				if raw.is_valid_float():
					sr_speed = float(raw)
				elif lowered in ["loop", "true", "1"]:
					sr_loop = true
			if sr_key.is_empty():
				sr_key = "point_axioms"
			if utility_object.has_method("configure_speed_reader"):
				utility_object.configure_speed_reader(sr_key, sr_speed, sr_loop)
			else:
				utility_object.set_meta("speed_reader_key", sr_key)
			print("GridUtilitiesComponent: Configured speed reader '%s' (seconds=%.2f, loop=%s)" % [sr_key, sr_speed, str(sr_loop)])
		"an":  # Annotation/Info Board
			var map_info = {}
			# Try to fetch map info from the parent GridSystem
			if parent_node and "map_data" in parent_node:
				var m_data = parent_node.map_data
				if m_data is Dictionary and m_data.has("info"):
					map_info = m_data.info

			if not map_info.is_empty():
				var title = map_info.get("title", "Untitled Map")
				var description = map_info.get("description", "")

				# Apply to utility object properties
				# We try multiple property names to cover different board implementations
				utility_object.set("title", title)
				utility_object.set("description", description)
				utility_object.set("header_text", title)
				utility_object.set("body_text", description)

				# Fallback: some boards might need a specific method call
				if utility_object.has_method("set_content"):
					utility_object.set_content(title, description)

				print("GridUtilitiesComponent: Populated 'an' board with map info: %s" % title)
			else:
				print("GridUtilitiesComponent: 'an' board placed, but no map info found in parent")

			# Apply rotation if specified as parameter (an:90)
			if parameters.size() > 0:
				var rot_y = float(parameters[0])
				utility_object.rotation_degrees.y = rot_y
				print("GridUtilitiesComponent: Set 'an' board rotation to %.1f degrees" % rot_y)
		"tc":  # Transport Cube
			if parameters.size() >= 2:
				var distance = float(parameters[0])
				var direction_param = parameters[1]
				var direction = Vector3(1, 0, 0)
				match direction_param.to_lower():
					"x":
						direction = Vector3(1, 0, 0)
					"y":
						direction = Vector3(0, 1, 0)
					"z":
						direction = Vector3(0, 0, 1)
					"-x":
						direction = Vector3(-1, 0, 0)
					"-y":
						direction = Vector3(0, -1, 0)
					"-z":
						direction = Vector3(0, 0, -1)
					_:
						var coords = direction_param.split(",")
						if coords.size() >= 3:
							direction = Vector3(
								coords[0].to_float(),
								coords[1].to_float(),
								coords[2].to_float()
							)
				if "set_transport_parameters" in utility_object:
					utility_object.set_transport_parameters(distance, direction)

				# Check for optional third parameter: "auto"
				if parameters.size() >= 3:
					var auto_param = parameters[2].strip_edges().to_lower()
					if auto_param == "auto" and "set_auto_start" in utility_object:
						utility_object.set_auto_start(true)
						print("GridUtilitiesComponent: Set transport cube to move %.1f units in direction %s (AUTO-START)" % [distance, direction])
					else:
						print("GridUtilitiesComponent: Set transport cube to move %.1f units in direction %s" % [distance, direction])
				else:
					print("GridUtilitiesComponent: Set transport cube to move %.1f units in direction %s" % [distance, direction])
		"br":  # Bridge Path
			# Format: br:AXIS:LENGTH (e.g. "br:z:3", "br:-x:2")
			if parameters.size() >= 1:
				var bridge_axis = parameters[0].strip_edges().to_lower()
				if bridge_axis not in ["x", "z", "-x", "-z"]:
					bridge_axis = "x"
				var bridge_length = 4
				if parameters.size() >= 2 and parameters[1].is_valid_int():
					bridge_length = int(parameters[1])
				if utility_object.has_method("set_bridge_parameters"):
					utility_object.set_bridge_parameters(bridge_length, bridge_axis)
				print("GridUtilitiesComponent: Set bridge path %d segments along %s" % [bridge_length, bridge_axis])
		"jp":  # Jump Pad — parabolic arc launcher
			# Format: jp:target_x:target_z[:arc_height]
			if parameters.size() >= 2:
				var target_x: int = int(parameters[0])
				var target_z: int = int(parameters[1])
				var arc_h: float = 6.0
				if parameters.size() >= 3 and parameters[2].is_valid_float():
					arc_h = float(parameters[2])

				# Compute world-space target from grid coords
				var ts: float = cube_size + gutter
				var target_world := Vector3(
					target_x * ts + ts * 0.5,
					0.0,
					target_z * ts + ts * 0.5
				)
				# Look up structure height at target for landing Y
				if structure_component:
					var struct_y: int = structure_component.find_highest_y_at(target_x, target_z)
					target_world.y = (struct_y + 1) * ts  # land on top of highest cube

				# Apply config via the standard apply_grid_config pattern
				if utility_object.has_method("apply_grid_config"):
					utility_object.apply_grid_config({
						"target_x": target_x,
						"target_z": target_z,
						"arc_height": arc_h
					})
				# Also set the world target directly
				if "target_world_pos" in utility_object:
					utility_object.target_world_pos = target_world
				if utility_object.has_method("set_grid_spacing"):
					utility_object.set_grid_spacing(cube_size, gutter)

				print("GridUtilitiesComponent: Jump pad -> target grid (%d,%d), arc=%.1f, world=%s" % [target_x, target_z, arc_h, target_world])
		"rc":  # Rotation Cube
			# Format: rc:angle:axis:pause:y_offset (e.g. "45:y:4:0.5")
			if parameters.size() >= 1:
				var angle = float(parameters[0])
				var axis = Vector3.UP  # Default Y axis
				var pause = 4.0  # Default pause duration
				var y_off = 0.0  # Default y offset

				if parameters.size() >= 2:
					match parameters[1].to_lower():
						"x": axis = Vector3.RIGHT
						"y": axis = Vector3.UP
						"z": axis = Vector3.BACK
						"-x": axis = Vector3.LEFT
						"-y": axis = Vector3.DOWN
						"-z": axis = Vector3.FORWARD

				if parameters.size() >= 3:
					pause = float(parameters[2])

				if parameters.size() >= 4:
					y_off = float(parameters[3])

				# Apply to rotation cube
				if utility_object.has_method("set_step_pause_mode"):
					utility_object.set_step_pause_mode(angle, axis, pause)
				else:
					if "rotation_angle" in utility_object:
						utility_object.rotation_angle = angle
					if "rotation_axis" in utility_object:
						utility_object.rotation_axis = axis
					if "pause_duration" in utility_object:
						utility_object.pause_duration = pause

				if "y_offset" in utility_object:
					utility_object.y_offset = y_off

				print("GridUtilitiesComponent: Set rotation cube to %.1f° on %s axis, %.1fs pause, y=%.1f" % [angle, parameters[1] if parameters.size() >= 2 else "y", pause, y_off])
		"sc":  # Scale Cube
			# Format: sc:max:min:offset_x:y_offset (e.g. "3:0.5:1.5:0.5")
			if parameters.size() >= 1:
				var max_scale = float(parameters[0])
				var min_scale = 0.5  # Default
				var offset_x = 1.5  # Default
				var y_off = 0.0  # Default y offset

				if parameters.size() >= 2:
					min_scale = float(parameters[1])

				if parameters.size() >= 3:
					offset_x = float(parameters[2])

				if parameters.size() >= 4:
					y_off = float(parameters[3])

				# Apply to scale cube
				if utility_object.has_method("set_scale_range"):
					utility_object.set_scale_range(min_scale, max_scale)
				else:
					if "min_scale" in utility_object:
						utility_object.min_scale = min_scale
					if "max_scale" in utility_object:
						utility_object.max_scale = max_scale

				if utility_object.has_method("set_offset"):
					utility_object.set_offset(Vector3(offset_x, 0, 0))
				elif "center_offset" in utility_object:
					utility_object.center_offset = Vector3(offset_x, 0, 0)

				if "y_offset" in utility_object:
					utility_object.y_offset = y_off

				print("GridUtilitiesComponent: Set scale cube %.1f→%.1f, offset_x=%.1f, y=%.1f" % [min_scale, max_scale, offset_x, y_off])
		"rg":  # Regenerate cube
			var target_params: Array = []
			var status_message := ""
			for param in parameters:
				var value := str(param).strip_edges()
				if value.is_empty():
					continue
				if value.begins_with("msg="):
					status_message = value.substr(4, value.length() - 4)
				else:
					target_params.append(value)
			if utility_object.has_method("set_targets_from_parameters"):
				utility_object.set_targets_from_parameters(target_params)
			elif utility_object.has_method("set_target_data"):
				utility_object.set_target_data([], target_params)
			if status_message.length() > 0 and utility_object.has_method("set_status_message"):
				utility_object.set_status_message(status_message)
		"la":  # Label - displays artifact name from the artifact registry
			if parameters.size() > 0:
				var keyid = parameters[0]
				if utility_object.has_method("set_keyid"):
					utility_object.set_keyid(keyid)
					print("GridUtilitiesComponent: Set label keyid to: %s" % keyid)
				else:
					print("GridUtilitiesComponent: Warning - Label object doesn't have set_keyid method")
		"m":  # Move player - drops player at this cell's position from 2m above
			# Place m: where you want the player to land (like placing s: for spawn)
			# Format: m or m:delay or m:t:name:delay (t:name is just a label)
			# Target position computed at runtime from global_position (in MovePlayerController)
			var move_delay := 0.5

			# Parse optional delay from parameters
			if parameters.size() >= 1:
				if parameters[0] == "t":
					# m:t:sequencename:delay — name is just a label
					if parameters.size() >= 3 and parameters[2].is_valid_float():
						move_delay = float(parameters[2])
				elif parameters[0].is_valid_float():
					# m:delay
					move_delay = float(parameters[0])

			utility_object.set_meta("move_delay", move_delay)
			if "move_delay" in utility_object:
				utility_object.move_delay = move_delay
			print("GridUtilitiesComponent: m: placed at local %s, delay %.1fs (target computed at runtime from global_position)" % [utility_object.position, move_delay])

		"pb":  # Player body trigger - unlocks/activates player customization
			# Format: pb:feature or pb:feature:color
			# Examples: pb:dress, pb:dress_wicked, pb:skin_color:FF0000
			if utility_object.has_method("configure"):
				utility_object.configure(parameters)
			else:
				# Manual configuration
				if parameters.size() > 0:
					utility_object.feature_name = parameters[0]
				if parameters.size() > 1:
					utility_object.color_param = parameters[1]
			print("GridUtilitiesComponent: Configured player body trigger for '%s'" % (parameters[0] if parameters.size() > 0 else "dress"))

		"sub":  # Subtitle trigger - Portal 2-style subtitle on player entry
			# Format: sub:key or sub:key:speaker or sub:key:speaker:level
			# Examples: sub:map, sub:welcome, sub:tt:point_axioms, sub:hello:GLaDOS:1
			if utility_object.has_method("configure"):
				utility_object.configure(parameters)
			else:
				# Manual configuration
				if parameters.size() > 0:
					utility_object.subtitle_key = parameters[0]
				if parameters.size() > 1:
					utility_object.speaker_name = parameters[1]
				if parameters.size() > 2:
					var param2 = parameters[2]
					if param2 in ["1", "2", "3"]:
						utility_object.text_level = int(param2)
					else:
						utility_object.duration = float(param2)
			print("GridUtilitiesComponent: Configured subtitle trigger for '%s'" % (parameters[0] if parameters.size() > 0 else "map"))

		"cp":  # Checkpoint - save point
			# Format: cp or cp:checkpoint_id
			# Examples: cp, cp:save_01, cp:midpoint
			var cp_id = ""
			if parameters.size() > 0:
				cp_id = parameters[0].strip_edges()

			if cp_id.is_empty():
				# Auto-generate ID from position
				cp_id = "cp_%d_%d" % [int(utility_object.position.x), int(utility_object.position.z)]

			if "checkpoint_id" in utility_object:
				utility_object.checkpoint_id = cp_id
			else:
				utility_object.set_meta("checkpoint_id", cp_id)

			print("GridUtilitiesComponent: Configured checkpoint '%s'" % cp_id)

		"h":  # Hazard zone - danger area
			# Format: h:type or h:type:damage
			# Examples: h:fire, h:electric:25, h:death, h:vacuum:10
			var hazard_type = "generic"
			var damage = 10.0

			if parameters.size() > 0:
				hazard_type = parameters[0].strip_edges().to_lower()

			if parameters.size() > 1 and parameters[1].is_valid_float():
				damage = float(parameters[1])

			# Map type string to enum
			var type_enum = 5  # GENERIC default
			match hazard_type:
				"fire": type_enum = 0
				"vacuum": type_enum = 1
				"electric": type_enum = 2
				"toxic": type_enum = 3
				"radiation": type_enum = 4
				"death":
					type_enum = 5
					if "instant_kill" in utility_object:
						utility_object.instant_kill = true

			if "danger_type" in utility_object:
				utility_object.danger_type = type_enum
			if "damage_per_tick" in utility_object:
				utility_object.damage_per_tick = damage

			print("GridUtilitiesComponent: Configured hazard zone type=%s damage=%.1f" % [hazard_type, damage])

# Apply color to utility object (works with materials and shaders)
func _apply_color_to_utility(utility_object: Node3D, color_param: String):
	var color = _parse_color_parameter(color_param)
	if color == Color.WHITE:
		print("GridUtilitiesComponent: Warning - Could not parse color '%s', using white" % color_param)

	# Find the mesh instance in the utility object
	var mesh_instance = _find_mesh_instance_in_utility(utility_object)
	if not mesh_instance:
		print("GridUtilitiesComponent: Warning - No MeshInstance3D found in utility object")
		return

	# Apply color based on material type
	var material = mesh_instance.material_override
	if material is ShaderMaterial:
		_apply_color_to_shader_material(material as ShaderMaterial, color)
	elif material is StandardMaterial3D:
		_apply_color_to_standard_material(material as StandardMaterial3D, color)
	else:
		# Create new standard material if none exists
		var new_material = StandardMaterial3D.new()
		_apply_color_to_standard_material(new_material, color)
		mesh_instance.material_override = new_material

# Parse color parameter string to Color object
func _parse_color_parameter(color_param: String) -> Color:
	match color_param.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"cyan": return Color.CYAN
		"magenta": return Color.MAGENTA
		"orange": return Color.ORANGE
		"purple": return Color.PURPLE
		"pink": return Color.PINK
		"white": return Color.WHITE
		"black": return Color.BLACK
		"gray", "grey": return Color.GRAY
		"lime": return Color(0.5, 1.0, 0.0, 1.0)
		"navy": return Color(0.0, 0.0, 0.5, 1.0)
		"maroon": return Color(0.5, 0.0, 0.0, 1.0)
		"olive": return Color(0.5, 0.5, 0.0, 1.0)
		"aqua": return Color(0.0, 1.0, 1.0, 1.0)
		"silver": return Color(0.75, 0.75, 0.75, 1.0)
		_:
			# Try to parse as hex color (e.g., "ff0000" for red)
			if color_param.length() == 6:
				var hex_color = Color.html("#" + color_param)
				if hex_color != Color.BLACK or color_param == "000000":
					return hex_color
			# Try direct HTML color parsing
			var html_color = Color.html(color_param)
			if html_color != Color.BLACK or color_param.to_lower() == "black":
				return html_color
			return Color.WHITE  # Default fallback

# Apply color to shader material (like the walkable prism)
func _apply_color_to_shader_material(shader_material: ShaderMaterial, color: Color):
	# Check for common shader parameter names
	var shader_params = ["fill_color", "base_color", "albedo_color", "modelColor", "color"]

	for param_name in shader_params:
		if shader_material.shader and shader_material.shader.get_shader_params().has(param_name):
			shader_material.set_shader_parameter(param_name, color)
			print("GridUtilitiesComponent: Set shader parameter '%s' to %s" % [param_name, color])
			break

	# Also try to set wireframe color to a complementary color
	var wireframe_params = ["wireframe_color", "edge_color", "wireframeColor"]
	var wireframe_color = Color(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, 1.0)  # Complementary color

	for param_name in wireframe_params:
		if shader_material.shader and shader_material.shader.get_shader_params().has(param_name):
			shader_material.set_shader_parameter(param_name, wireframe_color)
			print("GridUtilitiesComponent: Set wireframe parameter '%s' to %s" % [param_name, wireframe_color])
			break

# Apply color to standard material
func _apply_color_to_standard_material(standard_material: StandardMaterial3D, color: Color):
	standard_material.albedo_color = color
	# Add subtle emission for better visibility
	standard_material.emission_enabled = true
	standard_material.emission = color * 0.2
	print("GridUtilitiesComponent: Set standard material albedo to %s" % color)

# Find MeshInstance3D in utility object
func _find_mesh_instance_in_utility(utility_object: Node3D) -> MeshInstance3D:
	# Check if the object itself is a MeshInstance3D
	if utility_object is MeshInstance3D:
		return utility_object as MeshInstance3D

	# Search children recursively
	return _find_mesh_instance_recursive(utility_object)

func _find_mesh_instance_recursive(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		var found = _find_mesh_instance_recursive(child)
		if found:
			return found
	return null

# Apply utility definition properties from JSON
# Build a display string for 3t text utilities
func _build_text_display_message(parameters: Array) -> String:
	if parameters.is_empty():
		return DEFAULT_TEXT_DISPLAY

	var cleaned_parts: Array[String] = []
	for param in parameters:
		var cleaned = str(param).strip_edges()
		if cleaned.is_empty():
			continue
		cleaned_parts.append(cleaned)

	var combined = ":".join(cleaned_parts) if cleaned_parts.size() > 0 else ""
	combined = combined.replace("_", " ").strip_edges()
	if combined.is_empty():
		return DEFAULT_TEXT_DISPLAY
	return combined

# Apply a text value to the TextMesh used by 3t utilities
func _apply_text_display_text(utility_object: Node3D, text_value: String):
	var mesh_instance = _find_mesh_instance_in_utility(utility_object)
	if not mesh_instance:
		print("GridUtilitiesComponent: WARNING - 3t utility has no MeshInstance3D child")
		return

	var mesh_resource = mesh_instance.mesh
	if mesh_resource and mesh_resource is TextMesh:
		var text_mesh: TextMesh = mesh_resource.duplicate()
		text_mesh.text = text_value
		mesh_instance.mesh = text_mesh
		print("GridUtilitiesComponent: Updated TextMesh content to '%s'" % text_value)
	else:
		print("GridUtilitiesComponent: WARNING - 3t utility missing TextMesh resource")

func _apply_utility_definition(utility_object: Node3D, utility_type: String, definition: Dictionary):
	if definition.is_empty():
		return

	var properties = definition.get("properties", {})

	# Apply visual effects for teleporters
	if utility_type == "t" and properties.has("visual_effect"):
		_apply_teleporter_visual_effect(utility_object, properties["visual_effect"])

	# Apply spawn point properties
	if utility_type == "s":
		_apply_spawn_point_properties(utility_object, properties)

	# Apply generic properties
	for property_name in properties.keys():
		var property_value = properties[property_name]
		if property_name in utility_object:
			utility_object.set(property_name, property_value)
		else:
			# Store as metadata if property doesn't exist
			utility_object.set_meta(property_name, property_value)

# Apply spawn point specific properties
func _apply_spawn_point_properties(spawn_point: Node3D, properties: Dictionary):
	# Set spawn point metadata
	if properties.has("spawn_name"):
		spawn_point.set_meta("spawn_name", properties["spawn_name"])

	if properties.has("priority"):
		spawn_point.set_meta("priority", int(properties["priority"]))

	if properties.has("height"):
		spawn_point.set_meta("height", float(properties["height"]))

	if properties.has("player_rotation"):
		spawn_point.set_meta("player_rotation", float(properties["player_rotation"]))

	# Apply visual settings
	if properties.has("visible_in_game"):
		var visible = bool(properties["visible_in_game"])
		_set_spawn_point_visibility(spawn_point, visible)

# Set spawn point visual components visibility
func _set_spawn_point_visibility(spawn_point: Node3D, visible: bool):
	var components = ["Platform", "Indicator", "Label3D"]
	for component_name in components:
		var component = spawn_point.get_node_or_null(component_name)
		if component:
			component.visible = visible

# Apply teleporter visual effects
func _apply_teleporter_visual_effect(teleporter: Node3D, effect: String):
	# This would depend on the teleporter scene structure
	match effect:
		"portal_glow":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(0.2, 0.6, 1.0)
		"warning":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(1.0, 0.5, 0.0)
		"exit":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(0.0, 1.0, 0.3)

# Connect utility signals
func _connect_utility_signals(utility_object: Node3D, utility_type: String):
	# Connect common utility signals
	if utility_object.has_signal("activated"):
		utility_object.activated.connect(_on_utility_activated.bind(utility_type, utility_object))

	if utility_object.has_signal("teleporter_activated"):
		utility_object.teleporter_activated.connect(_on_teleporter_activated.bind(utility_object))
		print("GridUtilitiesComponent: ✅ Connected teleporter_activated signal for %s" % utility_type)

# Handle general utility activation
func _on_utility_activated(utility_type: String, utility_object: Node3D):
	var utility_data = {
		"position": utility_object.global_position,
		"name": utility_object.name,
		"type": utility_type
	}

	# Add utility-specific data
	if "destination" in utility_object:
		utility_data["destination"] = utility_object.destination
	else:
		utility_data["destination"] = utility_object.get_meta("destination", "")

	# Add action property from metadata (crucial for teleporters!)
	if utility_object.has_meta("action"):
		utility_data["action"] = utility_object.get_meta("action")
		print("GridUtilitiesComponent: 🎯 Found action in metadata: %s" % utility_data["action"])

	utility_activated.emit(utility_type, utility_object.global_position, utility_data)

# Handle teleporter activation specifically - connect to SceneManager
func _on_teleporter_activated(utility_object: Node3D):
	print("GridUtilitiesComponent: 🚀 Teleporter activated - checking for custom handling")

	# Get destination and action from teleporter
	var destination = ""
	if "destination" in utility_object:
		destination = utility_object.destination
	else:
		destination = utility_object.get_meta("destination", "")

	var action = utility_object.get_meta("action", "")

	# First, try to let the parent GridSystem handle it (for lab-specific logic)
	if parent_node and parent_node.has_method("_on_utility_activated"):
		var utility_data = {
			"position": utility_object.global_position,
			"name": utility_object.name,
			"type": "t",
			"destination": destination,
			"action": action
		}

		print("GridUtilitiesComponent: Delegating to parent GridSystem for custom handling")
		print("GridUtilitiesComponent: Action: %s" % action)
		print("GridUtilitiesComponent: Destination: %s" % destination)
		parent_node._on_utility_activated("t", utility_object.global_position, utility_data)
		return

	# Fallback to default behavior
	print("GridUtilitiesComponent: Using default teleporter behavior")
	var scene_manager = _find_scene_manager()
	if scene_manager:
		scene_manager.request_transition({
			"type": 1,
			"action": "start_sequence" if _is_sequence_name(destination) else "load_map",
			"sequence": destination if _is_sequence_name(destination) else "",
			"destination": destination if not _is_sequence_name(destination) else "",
			"source": "teleporter",
			"position": utility_object.global_position
		})
# Find SceneManager in the scene tree
func _find_scene_manager():
	# Try common locations for SceneManager
	var potential_managers = [
		get_node_or_null("/root/SceneManager"),
		get_node_or_null("/root/AdaSceneManager"),
		get_tree().current_scene.find_child("SceneManager", true, false),
		get_tree().current_scene.find_child("AdaSceneManager", true, false)
	]

	for manager in potential_managers:
		if manager:
			print("GridUtilitiesComponent: Found SceneManager at: %s" % manager.get_path())
			return manager

	return null

## Cached sequence names — auto-discovered from res://commons/maps/sequences/*.json
var _known_sequences_cache: Array = []

func _is_sequence_name(name: String) -> bool:
	if _known_sequences_cache.is_empty():
		_known_sequences_cache = _discover_sequence_names()
	return name in _known_sequences_cache

## Scan the sequences directory for all .json files and extract their names.
## Runs once, cached for the session.
static func _discover_sequence_names() -> Array:
	var names: Array = []
	var dir := DirAccess.open("res://commons/maps/sequences")
	if not dir:
		push_warning("GridUtilitiesComponent: Could not open sequences directory for autodiscovery")
		return names
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and file_name != "sequence_index.json" and file_name != "templates.json":
			names.append(file_name.get_basename())
		file_name = dir.get_next()
	return names

# Debug: Print scene tree to help find SceneManager
func _debug_print_scene_tree():
	print("GridUtilitiesComponent: Scene tree structure:")
	_print_node_tree(get_tree().current_scene, 0)

func _print_node_tree(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])

	if depth < 3:  # Limit depth to avoid spam
		for child in node.get_children():
			_print_node_tree(child, depth + 1)

# Load scene with caching
func _load_scene_cached(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null

	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]

	var scene_path = MAP_OBJECTS_PATH + scene_filename
	print("GridUtilitiesComponent: Attempting to load scene: %s" % scene_path)

	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		print("GridUtilitiesComponent: ✅ Successfully loaded scene: %s" % scene_filename)
		return scene
	else:
		print("GridUtilitiesComponent: ❌ ERROR - Scene file not found: %s" % scene_path)

		# Try to find what files actually exist
		_list_available_scenes()

		return null

# Debug: List available utility scenes
func _list_available_scenes():
	print("GridUtilitiesComponent: Listing available scenes in %s:" % MAP_OBJECTS_PATH)

	var dir = DirAccess.open(MAP_OBJECTS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tscn"):
				print("  → %s" % file_name)
			file_name = dir.get_next()
	else:
		print("GridUtilitiesComponent: Could not open scenes directory: %s" % MAP_OBJECTS_PATH)

# Get utility at position
func get_utility_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return utility_objects.get(key, null)

# Check if position has utility
func has_utility_at(x: int, y: int, z: int) -> bool:
	return utility_objects.has(Vector3i(x, y, z))

# Clear all utilities
func clear_utilities():
	print("GridUtilitiesComponent: Clearing all utilities")

	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()

	utility_objects.clear()

# Get utility count
func get_utility_count() -> int:
	return utility_objects.size()

# Get all utility positions
func get_all_utility_positions() -> Array:
	return utility_objects.keys()

# Parse info board utility (ib:vectors, ib:forces:1.5, ib:triangle:90:2:0.2, etc.)
# Format: ib:board_type[:rotation[:up[:scale]]]
#   - rotation: Y-axis rotation in degrees (default: 0)
#   - up: Y position offset (default: 0)
#   - scale: uniform scale factor (default: 1.0)
# Special case: Single small float (< 10) assumed to be legacy height for backward compat
func _parse_info_board_utility(utility_cell: String, x: int, z: int) -> Dictionary:
	var parts = utility_cell.split(":")
	if parts.size() < 2:
		print("GridUtilitiesComponent: Invalid info board format: %s" % utility_cell)
		return {}

	var board_type = parts[1]  # e.g., "vectors", "forces", "triangle"
	var rotation_degrees = 0.0
	var height_offset = 0.0
	var scale_factor = 1.0

	# Parse parameters based on count
	if parts.size() > 2:
		# New format priority: ib:board:rotation:up:scale

		if parts.size() == 3:
			# Single parameter - could be rotation OR legacy height
			var param = parts[2]
			if param.is_valid_float():
				var value = float(param)
				# If value is small (< 10), assume it's legacy height offset
				# If value is large (>= 10), assume it's rotation in degrees
				if value < 10.0:
					height_offset = value
				else:
					rotation_degrees = value

		elif parts.size() == 4:
			# Two parameters: rotation and up
			if parts[2].is_valid_float():
				rotation_degrees = float(parts[2])
			if parts[3].is_valid_float():
				height_offset = float(parts[3])

		elif parts.size() >= 5:
			# Three+ parameters: rotation, up, and scale
			if parts[2].is_valid_float():
				rotation_degrees = float(parts[2])
			if parts[3].is_valid_float():
				height_offset = float(parts[3])
			if parts[4].is_valid_float():
				scale_factor = float(parts[4])

	# Validate board type using InfoBoardRegistry
	if not InfoBoardRegistry.is_valid_board_type(board_type):
		print("GridUtilitiesComponent: Invalid info board type: %s" % board_type)
		return {}

	return {
		"board_type": board_type,
		"position": Vector3i(x, 0, z),  # x, y, z - y will be calculated from structure
		"rotation_degrees": rotation_degrees,
		"height_offset": height_offset,
		"scale": scale_factor
	}

# Generate info boards at their specific locations
func _generate_info_boards(info_board_data: Array):
	print("GridUtilitiesComponent: Generating %d info boards at specific locations" % info_board_data.size())

	# Place each info board at its specific location
	for board_data in info_board_data:
		var board_type = board_data.board_type
		var grid_pos = board_data.position
		var height_offset = board_data.get("height_offset", 0.0)
		var rotation_degrees = board_data.get("rotation_degrees", 0.0)
		var scale_factor = board_data.get("scale", 1.0)

		# Calculate 3D position
		var total_size = cube_size + gutter
		var y_pos = structure_component.find_highest_y_at(grid_pos.x, grid_pos.z)
		var position = Vector3(grid_pos.x, y_pos, grid_pos.z) * total_size

		# Apply height offset
		position.y += height_offset

		# Generate the info board at this specific location
		_place_info_board_at_position(board_type, position, rotation_degrees, scale_factor)

		print("GridUtilitiesComponent: Placed %s info board at %s (rotation: %.1f°, scale: %.2f)" % [board_type, position, rotation_degrees, scale_factor])

# Create info board using universal template (works with centralized JSON content)
func _create_info_board_with_universal_template(board_id: String) -> Node3D:
	# Check if content exists for this board
	var page_count = InfoBoardContentLoader.get_page_count(board_id)
	if page_count == 0:
		return null  # No content, can't create board

	# Load the HandheldInfoBoard base structure (3D frame + viewport)
	var base_scene_path = "res://commons/infoboards_3d/base/HandheldInfoBoard.tscn"
	if not ResourceLoader.exists(base_scene_path):
		push_error("GridUtilitiesComponent: HandheldInfoBoard base scene not found")
		return null

	var board_scene = load(base_scene_path)
	if not board_scene:
		push_error("GridUtilitiesComponent: Failed to load HandheldInfoBoard scene: " + base_scene_path)
		return null
	var board_3d = board_scene.instantiate()

	# Configure the Viewport2Din3D script properties on the root node
	# The script automatically loads the scene into the viewport
	if board_3d.has_method("set") and board_3d.get("scene") != null:
		# Set the board_id property which will be passed to UniversalInfoBoard
		board_3d.set("board_id", board_id)
		board_3d.set("display_mode", 1)  # DisplayMode.SINGLE_BOARD
		board_3d.set("auto_load_on_ready", true)
		board_3d.set("enable_navigation", true)

		print("GridUtilitiesComponent: Configured HandheldInfoBoard - board_id: %s" % board_id)
	else:
		push_error("GridUtilitiesComponent: HandheldInfoBoard doesn't have Viewport2Din3D script configured")
		board_3d.queue_free()
		return null

	print("GridUtilitiesComponent: Created '%s' InfoBoard using UniversalInfoBoard (Content: %d pages)" % [board_id, page_count])

	return board_3d

# Place a single info board at a specific position
func _place_info_board_at_position(board_type: String, position: Vector3, rotation_degrees: float = 0.0, scale_factor: float = 1.0):
	# NEW: Try to create using universal template with centralized content
	var info_board = _create_info_board_with_universal_template(board_type)

	# Fallback: Try loading from registry scene path (for legacy boards)
	if not info_board:
		var scene_path = InfoBoardRegistry.get_board_scene_path(board_type)
		if scene_path.is_empty():
			print("GridUtilitiesComponent: WARNING - No scene file for info board type '%s'" % board_type)
			return

		if not ResourceLoader.exists(scene_path):
			print("GridUtilitiesComponent: WARNING - Scene file not found: %s" % scene_path)
			return

		var scene_resource = ResourceLoader.load(scene_path)
		if not scene_resource:
			print("GridUtilitiesComponent: WARNING - Could not load scene for info board type '%s': %s" % [board_type, scene_path])
			return

		info_board = scene_resource.instantiate()

	if info_board:
		# Only set transform if it's a 3D node
		if info_board is Node3D:
			info_board.position = position

			# Apply Y-axis rotation
			if rotation_degrees != 0.0:
				info_board.rotation_degrees.y = rotation_degrees

			# Apply uniform scale
			if scale_factor != 1.0:
				info_board.scale = Vector3(scale_factor, scale_factor, scale_factor)

		# Add to parent node
		parent_node.add_child(info_board)

		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			info_board.owner = parent_node.get_tree().edited_scene_root

		# Store in utility objects for tracking
		var grid_pos = Vector3i(int(position.x / (cube_size + gutter)), int(position.y), int(position.z / (cube_size + gutter)))
		utility_objects[grid_pos] = info_board

		print("GridUtilitiesComponent: ✅ Successfully placed %s info board at %s" % [board_type, position])
	else:
		print("GridUtilitiesComponent: ❌ Failed to instantiate info board: %s" % board_type)

# Parse tutorial display utility (tt:tutorial_name, tt:tutorial_name:rotation:up:scale)
# Format: tt:tutorial_name[:rotation[:up[:scale]]]
#   - tutorial_name: The tutorial key from tutorial_text.json (e.g., "point_axioms", "line")
#   - rotation: Y-axis rotation in degrees (default: 0)
#   - up: Y position offset (default: 0)
#   - scale: uniform scale factor (default: 1.0)
func _parse_tutorial_display_utility(utility_cell: String, x: int, z: int) -> Dictionary:
	var parts = utility_cell.split(":")
	if parts.size() < 2:
		print("GridUtilitiesComponent: Invalid tutorial display format: %s" % utility_cell)
		return {}

	var tutorial_name = parts[1]  # e.g., "point_axioms", "line"
	var rotation_degrees = 0.0
	var height_offset = 0.0
	var scale_factor = 1.0

	# Parse parameters based on count (same as info board parsing)
	if parts.size() > 2:
		if parts.size() == 3:
			# Single parameter - could be rotation OR legacy height
			var param = parts[2]
			if param.is_valid_float():
				var value = float(param)
				# If value is small (< 10), assume it's legacy height offset
				# If value is large (>= 10), assume it's rotation in degrees
				if value < 10.0:
					height_offset = value
				else:
					rotation_degrees = value

		elif parts.size() == 4:
			# Two parameters: rotation and up
			if parts[2].is_valid_float():
				rotation_degrees = float(parts[2])
			if parts[3].is_valid_float():
				height_offset = float(parts[3])

		elif parts.size() >= 5:
			# Three+ parameters: rotation, up, and scale
			if parts[2].is_valid_float():
				rotation_degrees = float(parts[2])
			if parts[3].is_valid_float():
				height_offset = float(parts[3])
			if parts[4].is_valid_float():
				scale_factor = float(parts[4])

	return {
		"tutorial_name": tutorial_name,
		"position": Vector3i(x, 0, z),  # x, y, z - y will be calculated from structure
		"rotation_degrees": rotation_degrees,
		"height_offset": height_offset,
		"scale": scale_factor
	}

# Generate tutorial displays at their specific locations
func _generate_tutorial_displays(tutorial_display_data: Array):
	print("GridUtilitiesComponent: Generating %d tutorial displays at specific locations" % tutorial_display_data.size())

	# Place each tutorial display at its specific location
	for display_data in tutorial_display_data:
		var tutorial_name = display_data.tutorial_name
		var grid_pos = display_data.position
		var height_offset = display_data.get("height_offset", 0.0)
		var rotation_degrees = display_data.get("rotation_degrees", 0.0)
		var scale_factor = display_data.get("scale", 1.0)

		# Calculate 3D position
		var total_size = cube_size + gutter
		var y_pos = structure_component.find_highest_y_at(grid_pos.x, grid_pos.z)
		var position = Vector3(grid_pos.x, y_pos, grid_pos.z) * total_size

		# Apply height offset
		position.y += height_offset

		# Generate the tutorial display at this specific location
		_place_tutorial_display_at_position(tutorial_name, position, rotation_degrees, scale_factor)

		print("GridUtilitiesComponent: Placed '%s' tutorial display at %s (rotation: %.1f°, scale: %.2f)" % [tutorial_name, position, rotation_degrees, scale_factor])

# Place a single tutorial display at a specific position
func _place_tutorial_display_at_position(tutorial_name: String, position: Vector3, rotation_degrees: float = 0.0, scale_factor: float = 1.0):
	# Load the codeDisplay scene
	var scene_path = "res://commons/context/clipboard/codeDisplay.tscn"

	if not ResourceLoader.exists(scene_path):
		print("GridUtilitiesComponent: WARNING - Tutorial display scene not found: %s" % scene_path)
		return

	var scene_resource = ResourceLoader.load(scene_path)
	if not scene_resource:
		print("GridUtilitiesComponent: WARNING - Could not load tutorial display scene: %s" % scene_path)
		return

	var display = scene_resource.instantiate()

	if display:
		# Only set transform if it's a 3D node
		if display is Node3D:
			display.position = position

			# Apply Y-axis rotation
			if rotation_degrees != 0.0:
				display.rotation_degrees.y = rotation_degrees

			# Apply uniform scale
			if scale_factor != 1.0:
				display.scale = Vector3(scale_factor, scale_factor, scale_factor)

		# Add to parent node first so the scene is in the tree
		parent_node.add_child(display)

		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			display.owner = parent_node.get_tree().edited_scene_root

		# Wait a frame for the display to initialize
		await get_tree().process_frame

		# Apply grid config with tutorial parameter
		if display.has_method("apply_grid_config"):
			display.apply_grid_config({"tutorial": tutorial_name})
			print("GridUtilitiesComponent: Applied tutorial config '%s' to display" % tutorial_name)
		else:
			print("GridUtilitiesComponent: WARNING - Tutorial display doesn't have apply_grid_config method")

		# Store in utility objects for tracking
		var grid_pos = Vector3i(int(position.x / (cube_size + gutter)), int(position.y), int(position.z / (cube_size + gutter)))
		utility_objects[grid_pos] = display

		print("GridUtilitiesComponent: ✅ Successfully placed '%s' tutorial display at %s" % [tutorial_name, position])
	else:
		print("GridUtilitiesComponent: ❌ Failed to instantiate tutorial display for: %s" % tutorial_name)

# Parse border frame utility string (bf:start_x:start_z:end_x:end_z:thickness:height)
func _parse_border_frame_utility(utility_cell: String, grid_x: int, grid_z: int) -> Dictionary:
	# Format: bf:start_x:start_z:end_x:end_z:thickness:height
	# Example: bf:0:0:5:30:2:1 = Frame from (0,0) to (5,30), 2m thick walls, 1m tall

	var parts = utility_cell.split(":")
	if parts.size() < 7:
		print("GridUtilitiesComponent: WARNING - Invalid border frame format '%s'. Expected: bf:start_x:start_z:end_x:end_z:thickness:height" % utility_cell)
		return {}

	var start_x = parts[1].strip_edges()
	var start_z = parts[2].strip_edges()
	var end_x = parts[3].strip_edges()
	var end_z = parts[4].strip_edges()
	var thickness = parts[5].strip_edges()
	var height = parts[6].strip_edges()

	if not (start_x.is_valid_float() and start_z.is_valid_float() and
			end_x.is_valid_float() and end_z.is_valid_float() and
			thickness.is_valid_float() and height.is_valid_float()):
		print("GridUtilitiesComponent: WARNING - Invalid border frame parameters in '%s'" % utility_cell)
		return {}

	return {
		"start_x": float(start_x),
		"start_z": float(start_z),
		"end_x": float(end_x),
		"end_z": float(end_z),
		"thickness": float(thickness),
		"height": float(height)
	}

# Generate border frame (4 walls forming a rectangular perimeter)
func _generate_border_frame(border_data: Dictionary):
	var start_x = border_data.start_x
	var start_z = border_data.start_z
	var end_x = border_data.end_x
	var end_z = border_data.end_z
	var thickness = border_data.thickness
	var wall_height = border_data.height

	# Calculate dimensions and center
	var total_size = cube_size + gutter
	var min_x = min(start_x, end_x)
	var max_x = max(start_x, end_x)
	var min_z = min(start_z, end_z)
	var max_z = max(start_z, end_z)

	var width = (max_x - min_x) * total_size
	var depth = (max_z - min_z) * total_size
	var center_x = (min_x + max_x) / 2.0
	var center_z = (min_z + max_z) / 2.0

	# Y position: start at 0.5, center of wall is 0.5 + half height
	var y_pos = 0.5

	# Load SimpleGrid shader
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if not shader:
		push_error("GridUtilitiesComponent: Failed to load SimpleGrid shader")
		return

	# Create shader material with black model color and light blue outline
	var wall_material = ShaderMaterial.new()
	wall_material.shader = shader
	wall_material.set_shader_parameter("modelColor", Color(0.0, 0.0, 0.0, 1.0))  # Black
	wall_material.set_shader_parameter("wireframeColor", Color(0.3, 0.7, 1.0, 1.0))  # Light blue
	wall_material.set_shader_parameter("emissionColor", Color(0.3, 0.7, 1.0, 1.0))  # Light blue
	wall_material.set_shader_parameter("width", 2.0)
	wall_material.set_shader_parameter("emission_strength", 2.0)

	# Create 4 walls: North, South, East, West
	# North wall (along X axis, at max Z)
	_create_wall(
		Vector3(center_x * total_size, y_pos + wall_height / 2, max_z * total_size + thickness / 2),
		Vector3(width + thickness * 2, wall_height, thickness),
		wall_material,
		"BorderFrame_North"
	)

	# South wall (along X axis, at min Z)
	_create_wall(
		Vector3(center_x * total_size, y_pos + wall_height / 2, min_z * total_size - thickness / 2),
		Vector3(width + thickness * 2, wall_height, thickness),
		wall_material,
		"BorderFrame_South"
	)

	# East wall (along Z axis, at max X)
	_create_wall(
		Vector3(max_x * total_size + thickness / 2, y_pos + wall_height / 2, center_z * total_size),
		Vector3(thickness, wall_height, depth),
		wall_material,
		"BorderFrame_East"
	)

	# West wall (along Z axis, at min X)
	_create_wall(
		Vector3(min_x * total_size - thickness / 2, y_pos + wall_height / 2, center_z * total_size),
		Vector3(thickness, wall_height, depth),
		wall_material,
		"BorderFrame_West"
	)

	print("GridUtilitiesComponent: Generated border frame from (%.1f,%.1f) to (%.1f,%.1f) - thickness: %.1fm, height: %.1fm" %
		[start_x, start_z, end_x, end_z, thickness, wall_height])

# Create a single wall segment with collider
func _create_wall(position: Vector3, size: Vector3, material: Material, wall_name: String):
	# Create static body for collision
	var static_body = StaticBody3D.new()
	static_body.name = wall_name
	static_body.position = position

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)

	# Create mesh for visual representation
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	static_body.add_child(mesh_instance)

	# Add to scene
	parent_node.add_child(static_body)

	# Set owner for editor
	if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
		static_body.owner = parent_node.get_tree().edited_scene_root
		collision_shape.owner = parent_node.get_tree().edited_scene_root
		mesh_instance.owner = parent_node.get_tree().edited_scene_root
