# GridSpawnComponent.gd
# Player spawn positioning — reads map data and places the player.
#
# ---------------------------------------------------------------------------
# SPAWN POLICY (READ THIS WHEN TOUCHING MAP FILES)
# ---------------------------------------------------------------------------
# The `s` utility cell is OPTIONAL. Maps do not need one. When absent, the
# player lands at a sensible default — the centroid of the floor — facing
# the interactables. The goal: authors shouldn't have to think about spawn
# unless they want explicit control.
#
# Priority chain (first match wins):
#
#   PRIORITY 1 — Utility spawn coordinates (`s:x:y:z` in utilities layer)
#                If a spawn utility has explicit coordinates in its params,
#                use those. Rotation is auto-computed unless the utility
#                also sets `player_rotation` metadata.
#
#   PRIORITY 2 — JSON `spawn_points.default` (position + rotation arrays)
#                If present in map_data.json, honored exactly as specified.
#                Author-level explicit override. Always wins over auto.
#
#   PRIORITY 3 — Smart default (no `s`, no spawn_points)
#                Position: centroid of all floor cells (structure level >= 1),
#                  at player eye height (1.8).
#                Rotation: face the centroid of interactables. If no
#                  interactables, face the teleporter. If no teleporter,
#                  face +Z (north, arbitrary).
#
# Auto-rotation kicks in for PRIORITY 1 and PRIORITY 3 so the player
# consistently lands looking AT the content, not away from it. Authors who
# want a specific facing must use PRIORITY 2 (explicit rotation array).
#
# Map authors: the cheapest map has NO `s` cell and NO `spawn_points` block.
# The smart default handles it. Add `s` only when you need a specific
# grid cell; add `spawn_points` only when you need a specific facing.
# ---------------------------------------------------------------------------

extends Node
class_name GridSpawnComponent

# References
var data_component: GridDataComponent

# Hard fallback when a map has NO floor cells at all (should never happen
# in practice). World origin at eye height, facing forward.
const ABSOLUTE_FALLBACK_POSITION = Vector3(0.0, 1.8, 0.0)
const ABSOLUTE_FALLBACK_ROTATION = Vector3(0.0, 0.0, 0.0)
const PLAYER_EYE_HEIGHT = 1.8

# Signals
signal spawn_positioning_complete(spawn_position: Vector3)

func _ready():
	print("GridSpawnComponent: Initialized")

# Initialize with data component only
func initialize(data_comp: GridDataComponent, settings: Dictionary = {}):
	data_component = data_comp
	print("GridSpawnComponent: Ready to handle spawning")

# Handle player spawn positioning after map generation
func handle_player_spawn():
	print("GridSpawnComponent: STARTING SPAWN POSITIONING")

	# Wait for VR system to be ready
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.5).timeout

	# Resolve spawn through the priority chain documented at top of file.
	var spawn_data = _get_spawn_data_from_json()

	print("GridSpawnComponent: Spawn data retrieved:")
	print("  Position: %s" % spawn_data.position)
	print("  Rotation: %s" % spawn_data.rotation)
	print("  Source: %s" % spawn_data.source)

	var player_positioned: bool = _position_player(spawn_data)
	_update_reset_systems(spawn_data.position)

	print("GridSpawnComponent: SPAWN POSITIONING COMPLETE (player_positioned=%s)" % str(player_positioned))
	spawn_positioning_complete.emit(spawn_data.position)


# Resolve spawn data — see "SPAWN POLICY" doc block at top of file.
func _get_spawn_data_from_json() -> Dictionary:
	# PRIORITY 1: utility-based spawn (s:x:y:z). Position explicit, rotation
	# auto-computed unless the utility also carries `player_rotation`.
	var utility_spawn = _check_utility_spawn()
	if utility_spawn:
		if utility_spawn.get("rotation_is_auto", false):
			utility_spawn["rotation"] = _compute_auto_rotation(utility_spawn.position)
		return utility_spawn

	# PRIORITY 2: explicit JSON spawn_points.default. Author-level override.
	if data_component:
		var spawn_points = data_component.get_spawn_points()
		if spawn_points and not spawn_points.is_empty():
			var default_spawn = spawn_points.get("default", {})
			if not default_spawn.is_empty():
				var pos_array = default_spawn.get("position", [])
				var rot_array = default_spawn.get("rotation", [])
				var has_pos = pos_array.size() >= 3
				var has_rot = rot_array.size() >= 3

				if has_pos:
					var position = Vector3(pos_array[0], pos_array[1], pos_array[2])
					var rotation = Vector3(rot_array[0], rot_array[1], rot_array[2]) if has_rot else _compute_auto_rotation(position)
					print("GridSpawnComponent: Using JSON spawn_points.default: %s (rotation %s)" % [position, "explicit" if has_rot else "auto"])
					return {
						"position": position,
						"rotation": rotation,
						"source": "json_spawn_points"
					}

	# PRIORITY 3: smart default — floor centroid, facing interactables.
	return _compute_smart_default()


# Check for a spawn utility (`s`) in the utilities layer.
# Three forms, in order of preference:
#   1. `s:x:y:z` — explicit world coordinates stored in `spawn_coordinates` meta
#   2. `s#player_rotation:180` — uses the utility's cell position, explicit facing
#   3. bare `s` — uses the utility's cell position, rotation auto-computed
# Returns {} if no spawn utility found anywhere in the map.
func _check_utility_spawn() -> Dictionary:
	var parent_node = get_parent()
	if not parent_node:
		return {}

	var utilities_component = parent_node.find_child("GridUtilitiesComponent", false, false)
	if not utilities_component:
		return {}

	var utility_positions = utilities_component.get_all_utility_positions()

	for pos in utility_positions:
		var utility = utilities_component.get_utility_at(pos.x, pos.y, pos.z)
		if not utility:
			continue

		# Identify spawn utilities. The GridUtilitiesComponent names its
		# spawn_point instances after the scene file, so we check both
		# metadata presence and node type/name.
		var is_spawn = utility.has_meta("spawn_coordinates") \
			or utility.has_meta("spawn_name") \
			or utility.has_meta("player_rotation") \
			or String(utility.name).to_lower().find("spawn") != -1
		if not is_spawn:
			continue

		# Resolve position: explicit coords meta wins, otherwise the utility's
		# own world position (set by the grid when placing the cell).
		var world_pos: Vector3
		if utility.has_meta("spawn_coordinates"):
			var coords = utility.get_meta("spawn_coordinates")
			var cube_size = 1.0
			var gutter = 0.0
			if data_component:
				var settings = data_component.get_settings()
				cube_size = settings.get("cube_size", 1.0)
				gutter = settings.get("gutter", 0.0)
			world_pos = Vector3(
				coords.x * (cube_size + gutter),
				coords.y,
				coords.z * (cube_size + gutter)
			)
		else:
			# Bare `s` — use the spawn utility's own world position, bumped to
			# player eye height.
			world_pos = utility.global_position
			world_pos.y = PLAYER_EYE_HEIGHT

		# Resolve rotation: explicit `player_rotation` meta wins, otherwise
		# auto-compute to face interactables.
		var rotation = ABSOLUTE_FALLBACK_ROTATION
		var rotation_is_auto = true
		if utility.has_meta("player_rotation"):
			rotation.y = float(utility.get_meta("player_rotation"))
			rotation_is_auto = false

		print("GridSpawnComponent: Using utility spawn at %s (rotation %s)" % [world_pos, "explicit" if not rotation_is_auto else "auto"])
		return {
			"position": world_pos,
			"rotation": rotation,
			"rotation_is_auto": rotation_is_auto,
			"source": "utility_spawn"
		}

	return {}


# PRIORITY 3: Compute a sensible default when no `s` and no `spawn_points`.
# Position = centroid of all floor cells. Rotation = face interactables.
func _compute_smart_default() -> Dictionary:
	var position = _compute_default_position()
	var rotation = _compute_auto_rotation(position)
	print("GridSpawnComponent: Smart default — position %s, rotation %s" % [position, rotation])
	return {
		"position": position,
		"rotation": rotation,
		"source": "smart_default"
	}


# Centroid of floor cells (structure layer values >= 1), converted to world
# coordinates at player eye height. Falls back to the absolute fallback
# position only if a map has no floor at all.
func _compute_default_position() -> Vector3:
	if not data_component or not data_component.json_loader:
		return ABSOLUTE_FALLBACK_POSITION

	var structure: Array = data_component.json_loader.get_structure_layer()
	if structure.is_empty():
		return ABSOLUTE_FALLBACK_POSITION

	var sum_x = 0.0
	var sum_z = 0.0
	var count = 0
	for z in range(structure.size()):
		var row = structure[z]
		if typeof(row) != TYPE_ARRAY:
			continue
		for x in range(row.size()):
			var cell = row[x]
			# Accept any non-void, non-empty cell as walkable floor.
			var str_cell = str(cell).strip_edges()
			if str_cell == "" or str_cell == "0":
				continue
			sum_x += x
			sum_z += z
			count += 1

	if count == 0:
		return ABSOLUTE_FALLBACK_POSITION

	var cube_size = data_component.get_settings().get("cube_size", 1.0)
	var gutter = data_component.get_settings().get("gutter", 0.0)
	var cell = cube_size + gutter

	return Vector3(
		(sum_x / count) * cell,
		PLAYER_EYE_HEIGHT,
		(sum_z / count) * cell
	)


# Auto-rotation: face the centroid of interactables, or teleporter, or +Z.
# Returns Euler angles (x,y,z) in degrees — only y (yaw) is set.
func _compute_auto_rotation(from_position: Vector3) -> Vector3:
	var target = _find_interactables_centroid()
	if target == Vector3.INF:
		target = _find_teleporter_position()
	if target == Vector3.INF:
		# No content to face. Use absolute fallback (face +Z).
		return ABSOLUTE_FALLBACK_ROTATION

	# Compute yaw to face target on the X/Z plane.
	var delta = target - from_position
	if delta.length_squared() < 0.001:
		return ABSOLUTE_FALLBACK_ROTATION

	# atan2(-x, -z) gives the yaw that makes the player look toward target
	# in Godot's convention (default forward = -Z).
	var yaw_rad = atan2(-delta.x, -delta.z)
	return Vector3(0.0, rad_to_deg(yaw_rad), 0.0)


# Returns world centroid of all non-empty interactable cells, or INF if none.
func _find_interactables_centroid() -> Vector3:
	if not data_component or not data_component.json_loader:
		return Vector3.INF

	var interactables: Array = data_component.json_loader.get_interactables_layer()
	if interactables.is_empty():
		return Vector3.INF

	var sum_x = 0.0
	var sum_z = 0.0
	var count = 0
	for z in range(interactables.size()):
		var row = interactables[z]
		if typeof(row) != TYPE_ARRAY:
			continue
		for x in range(row.size()):
			var cell = str(row[x]).strip_edges()
			if cell == "" or cell == " ":
				continue
			sum_x += x
			sum_z += z
			count += 1

	if count == 0:
		return Vector3.INF

	var cube_size = data_component.get_settings().get("cube_size", 1.0)
	var gutter = data_component.get_settings().get("gutter", 0.0)
	var cell = cube_size + gutter
	return Vector3((sum_x / count) * cell, PLAYER_EYE_HEIGHT, (sum_z / count) * cell)


# Returns world position of the first teleporter in utilities, or INF if none.
func _find_teleporter_position() -> Vector3:
	if not data_component or not data_component.json_loader:
		return Vector3.INF

	var utilities: Array = data_component.json_loader.get_utilities_layer()
	if utilities.is_empty():
		return Vector3.INF

	for z in range(utilities.size()):
		var row = utilities[z]
		if typeof(row) != TYPE_ARRAY:
			continue
		for x in range(row.size()):
			var cell = str(row[x]).strip_edges()
			# Teleporter codes: bare "t" or "t:<destination>"
			if cell == "t" or cell.begins_with("t:"):
				var cube_size = data_component.get_settings().get("cube_size", 1.0)
				var gutter = data_component.get_settings().get("gutter", 0.0)
				var cell_size = cube_size + gutter
				return Vector3(x * cell_size, PLAYER_EYE_HEIGHT, z * cell_size)

	return Vector3.INF


# Position the player at spawn point
func _position_player(spawn_data: Dictionary) -> bool:
	var vr_origin = _find_vr_origin()
	if not vr_origin:
		print("GridSpawnComponent: ERROR - Could not find VR origin")
		return false

	var position = spawn_data.position
	var rotation = spawn_data.rotation

	vr_origin.global_position = position
	vr_origin.global_rotation_degrees = rotation

	print("GridSpawnComponent: ✓ Player spawned at %s (rotation: %s, source: %s)" % [position, rotation, spawn_data.source])
	return true


# Find VR origin in the scene
func _find_vr_origin() -> Node3D:
	var scene_root = get_tree().current_scene
	if not scene_root:
		return null

	var origin_names = ["XROrigin3D", "VROrigin", "ARVROrigin", "Origin", "XRPlayer"]
	for name in origin_names:
		var origin = scene_root.find_child(name, true, false)
		if origin and origin is Node3D:
			return origin as Node3D
	return null


# Update reset systems with new spawn position
func _update_reset_systems(spawn_position: Vector3):
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	var reset_nodes = [
		scene_root.find_child("ResetArea", true, false),
		scene_root.find_child("ResetArea3D", true, false),
		scene_root.find_child("Reset", true, false),
	]

	for reset_node in reset_nodes:
		if reset_node and reset_node.has_method("set_reset_position"):
			reset_node.set_reset_position(spawn_position)
			print("GridSpawnComponent: Updated %s to spawn position" % reset_node.name)
			return
