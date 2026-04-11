## CameraTourManager — Automated first-person camera tour through the entire game.
## Loads maps in curriculum spine order, generates camera paths through artifacts,
## and provides speed/pause/skip controls. No player body — just a floating camera.
##
## Cleanup strategy: before each map transition, ALL non-essential children of
## LabGridSystem are destroyed (keeping only CubeScene + 8 component nodes).
## Stray root nodes are also removed. The grid rebuilds everything from scratch
## via LabGridSystem.reload_map = true.
extends Node3D
class_name CameraTourManager

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
@export var camera_height: float = 1.8		## Eye height above grid floor
@export var move_speed: float = 4.0			## Base movement speed (units/sec)
@export var gaze_duration: float = 2.0		## Seconds to look at each artifact
@export var approach_distance: float = 2.0	## Stop this far from artifact
@export var fade_duration: float = 0.3		## Map transition fade time
@export var look_smoothing: float = 5.0		## Camera look-at interpolation speed
@export var overview_height: float = 6.0	## Height for map overview waypoints
@export var start_with_lab: bool = true		## Start tour from Lab hub first
@export var start_sequence: String = ""		## Jump to this sequence (e.g. "color", "vectors"). Empty = start from beginning.

# ---------------------------------------------------------------------------
# References (set in _ready)
# ---------------------------------------------------------------------------
var tour_camera: Camera3D
var lab_grid_system: Node  # LabGridSystem (typed loosely to avoid load errors)
var fade_rect: ColorRect

# UI labels
var sequence_label: Label
var map_label: Label
var speed_label: Label
var progress_bar: ProgressBar
var help_label: Label

# ---------------------------------------------------------------------------
# Tour state
# ---------------------------------------------------------------------------
var tour_data: Array[Dictionary] = []	# [{sequence_name, display_name, phase, maps}]
var spine_index: int = 0
var map_index: int = 0
var current_map_name: String = ""

# Waypoint state
var waypoints: Array[Dictionary] = []	# [{position, look_target, type, name, duration}]
var waypoint_index: int = 0
var _look_target: Vector3 = Vector3.ZERO
var _is_looking: bool = false

# Controls
var speed_multiplier: float = 1.0
var is_paused: bool = false
var is_transitioning: bool = false
var active_tween: Tween = null
var tour_complete: bool = false
var _last_precached_seq: int = -1  # Track which sequence we've already pre-cached

# Snapshot of root's children at startup (autoloads + scene — used for cleanup)
var _root_snapshot: Array[StringName] = []

# Children of LabGridSystem that must survive between map reloads
const _GRID_ESSENTIAL := [
	"CubeScene",
	"GridDataComponent", "GridStructureComponent", "GridUtilitiesComponent",
	"GridInteractablesComponent", "GridSpawnComponent", "GridCeilingComponent",
	"GridWallComponent", "GridAudioComponent",
]

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Find references
	tour_camera = get_node_or_null("../TourCamera")
	lab_grid_system = get_node_or_null("../LabGridSystem")
	fade_rect = get_node_or_null("../TourOverlay/FadeRect")

	# Find UI elements
	sequence_label = get_node_or_null("../TourOverlay/InfoPanel/VBox/SequenceLabel")
	map_label = get_node_or_null("../TourOverlay/InfoPanel/VBox/MapLabel")
	speed_label = get_node_or_null("../TourOverlay/InfoPanel/VBox/SpeedLabel")
	progress_bar = get_node_or_null("../TourOverlay/InfoPanel/VBox/ProgressBar")
	help_label = get_node_or_null("../TourOverlay/HelpLabel")

	if not tour_camera:
		push_error("CameraTourManager: TourCamera not found!")
		return
	if not lab_grid_system:
		push_error("CameraTourManager: LabGridSystem not found!")
		return

	# No mouse capture needed
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tour_camera.current = true

	# Initialize UI
	_update_speed_display()
	if help_label:
		help_label.text = "SPACE: Pause | +/-: Speed | N/P: Next/Prev Map | S: Next Seq | ESC: Quit"

	# Start fade rect fully black (we'll fade in after map loads)
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 1)

	# Defer startup so all other nodes' deferred inits complete first
	call_deferred("_deferred_start")

func _deferred_start() -> void:
	_take_snapshot()

	# Disconnect LabGridSystem's catalog setup — camera tour doesn't need the
	# DesktopArtifactCatalog, and its synchronous load() blocks every transition.
	if lab_grid_system and lab_grid_system.map_generation_complete.is_connected(
			lab_grid_system._on_lab_map_ready_for_catalog):
		lab_grid_system.map_generation_complete.disconnect(
			lab_grid_system._on_lab_map_ready_for_catalog)
		print("CameraTourManager: Disconnected catalog setup (not needed for tour)")

	_initialize_tour()

func _initialize_tour() -> void:
	_load_tour_data()

	if tour_data.is_empty():
		push_error("CameraTourManager: No tour data loaded!")
		if fade_rect:
			fade_rect.color.a = 0.0
		return

	print("CameraTourManager: Loaded %d sequences for tour" % tour_data.size())
	for td in tour_data:
		print("  - %s: %d maps" % [td.display_name, td.maps.size()])

	# If start_sequence is set, jump directly to that sequence
	if start_sequence != "":
		var found := false
		for i in tour_data.size():
			if tour_data[i].sequence_name == start_sequence:
				spine_index = i
				map_index = 0
				current_map_name = tour_data[i].maps[0]
				lab_grid_system.map_name = current_map_name
				_update_sequence_display()
				_update_map_display()
				print("CameraTourManager: Jumping to sequence '%s' (index %d)" % [start_sequence, i])
				_wait_for_initial_map()
				found = true
				break
		if not found:
			push_warning("CameraTourManager: Sequence '%s' not found, starting from Lab" % start_sequence)
		else:
			return

	if start_with_lab:
		spine_index = -1
		map_index = 0
		current_map_name = "Lab"
		_update_sequence_display()
		_update_map_display()
		_wait_for_initial_map()
	else:
		spine_index = 0
		map_index = 0
		if tour_data.size() > 0 and tour_data[0].maps.size() > 0:
			current_map_name = tour_data[0].maps[0]
			lab_grid_system.map_name = current_map_name
			_update_sequence_display()
			_update_map_display()
			_wait_for_initial_map()

func _wait_for_initial_map() -> void:
	"""Wait for the first map (loaded by LabGridSystem._ready) to finish generating."""
	print("CameraTourManager: Waiting for initial map '%s'..." % current_map_name)
	is_transitioning = true

	var wait_time: float = 0.0
	var max_wait: float = 15.0

	# For the initial load, the map might already be ready or still generating.
	# Connect signal first, then check if already done.
	var signal_received := false
	var _on_complete := func(): signal_received = true
	lab_grid_system.map_generation_complete.connect(_on_complete, CONNECT_ONE_SHOT)

	# If already ready, the signal won't fire again — use polling as fallback
	while not signal_received and wait_time < max_wait:
		if lab_grid_system.has_method("is_map_ready") and lab_grid_system.is_map_ready():
			break
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	if not signal_received and lab_grid_system.map_generation_complete.is_connected(_on_complete):
		lab_grid_system.map_generation_complete.disconnect(_on_complete)

	await get_tree().process_frame
	await get_tree().process_frame

	# Stop audio that auto-started during generation — start after fade-in
	var audio_comp = lab_grid_system.get_node_or_null("GridAudioComponent")
	if audio_comp and audio_comp.has_method("stop_ambient"):
		audio_comp.stop_ambient()

	print("CameraTourManager: Map '%s' ready (%.2fs)" % [current_map_name, wait_time])
	_generate_path()
	_position_camera_at_start()
	await _fade_from_black(fade_duration)

	# NOW start audio — screen is visible
	if audio_comp and audio_comp.has_method("start_ambient"):
		audio_comp.start_ambient()

	is_transitioning = false
	_start_traversal()

	# Pre-cache the first sequence's artifact scenes while Lab tour plays.
	_precache_sequence(0)

# ---------------------------------------------------------------------------
# Tour data loading — reads spine.sequences sorted by order field
# This follows the curriculum spine's recommended progression through QFEP.
# ---------------------------------------------------------------------------
func _load_tour_data() -> void:
	tour_data.clear()

	var spine_path := "res://commons/maps/curriculum_spine.json"
	if not FileAccess.file_exists(spine_path):
		push_error("CameraTourManager: curriculum_spine.json not found!")
		return

	var spine_file := FileAccess.open(spine_path, FileAccess.READ)
	var spine_json = JSON.parse_string(spine_file.get_as_text())
	spine_file.close()

	if spine_json == null or not spine_json.has("spine"):
		push_error("CameraTourManager: Invalid curriculum_spine.json (missing 'spine')")
		return

	# Read spine.sequences sorted by order field
	var sequences: Array = spine_json["spine"]["sequences"]
	sequences.sort_custom(func(a, b): return a.get("order", 999) < b.get("order", 999))

	var added: Dictionary = {}
	for spine_entry in sequences:
		var seq_name: String = spine_entry.get("name", "")
		var phase: String = spine_entry.get("phase", "")
		if seq_name != "" and not added.has(seq_name):
			_try_add_sequence(seq_name, phase, added)

func _try_add_sequence(seq_name: String, phase: String, added: Dictionary) -> void:
	var seq_data := _load_sequence_maps(seq_name)
	if seq_data.is_empty():
		print("CameraTourManager: WARNING - No maps for '%s', skipping" % seq_name)
		return
	tour_data.append({
		"sequence_name": seq_name,
		"display_name": seq_data.get("display_name", seq_name),
		"phase": phase,
		"maps": seq_data.get("maps", [])
	})
	added[seq_name] = true

func _load_sequence_maps(seq_name: String) -> Dictionary:
	var seq_path := "res://commons/maps/sequences/%s.json" % seq_name
	if not FileAccess.file_exists(seq_path):
		return {}
	var seq_file := FileAccess.open(seq_path, FileAccess.READ)
	var seq_json = JSON.parse_string(seq_file.get_as_text())
	seq_file.close()
	if seq_json == null or not seq_json.has("sequences"):
		return {}
	var seq_dict: Dictionary = seq_json["sequences"]
	var data: Dictionary = {}
	if seq_dict.has(seq_name):
		data = seq_dict[seq_name]
	else:
		for key in seq_dict:
			data = seq_dict[key]
			break
	if data.is_empty():
		return {}
	return {
		"display_name": data.get("name", seq_name),
		"maps": data.get("maps", [])
	}

# ---------------------------------------------------------------------------
# Map loading — fast reload via GridSystem.reload_map with stray node cleanup
# ---------------------------------------------------------------------------
func _load_map(map_name: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	current_map_name = map_name

	# Kill any active camera tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null
	_is_looking = false

	_update_sequence_display()
	_update_map_display()

	print("CameraTourManager: Transitioning to map '%s' via reload_map" % map_name)

	var audio_comp = lab_grid_system.get_node_or_null("GridAudioComponent")

	# Fade to black
	await _fade_to_black(fade_duration)

	# Stop audio from previous map before nuking
	if audio_comp and audio_comp.has_method("stop_ambient"):
		audio_comp.stop_ambient()

	# Nuke all non-essential content from previous map
	_nuke_map_content()
	await get_tree().process_frame  # let queue_free process

	# Connect signal BEFORE triggering reload — this way we can't miss it,
	# no matter how many frames the deferred chain takes.
	var map_ready := false
	var _on_done := func(): map_ready = true
	lab_grid_system.map_generation_complete.connect(_on_done, CONNECT_ONE_SHOT)

	# Trigger fast grid reload
	lab_grid_system.map_name = map_name
	lab_grid_system.reload_map = true

	# Wait for signal (no frame-count guessing needed)
	var wait_time: float = 0.0
	while not map_ready and wait_time < 15.0:
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	if not map_ready and lab_grid_system.map_generation_complete.is_connected(_on_done):
		lab_grid_system.map_generation_complete.disconnect(_on_done)

	# Two frames for interactables to finish their _ready()
	await get_tree().process_frame
	await get_tree().process_frame

	# Stop audio that GridSystem auto-started during generation —
	# we only want it playing after the screen is visible
	if audio_comp and audio_comp.has_method("stop_ambient"):
		audio_comp.stop_ambient()

	print("CameraTourManager: Map '%s' ready (%.2fs)" % [current_map_name, wait_time])
	_generate_path()
	_position_camera_at_start()
	await _fade_from_black(fade_duration)

	# NOW start audio — screen is visible
	if audio_comp and audio_comp.has_method("start_ambient"):
		audio_comp.start_ambient()

	is_transitioning = false
	_start_traversal()

	# Pre-cache next sequence's artifacts in background (if entering a new sequence)
	if spine_index >= 0 and spine_index != _last_precached_seq:
		_last_precached_seq = spine_index
		_precache_sequence(spine_index + 1)

# ---------------------------------------------------------------------------
# Cleanup — nuke all non-essential content before loading a new map
# ---------------------------------------------------------------------------
func _take_snapshot() -> void:
	"""Record root's children at startup (autoloads + scene) for stray node cleanup."""
	_root_snapshot.clear()
	for child in get_tree().root.get_children():
		_root_snapshot.append(child.name)
	print("CameraTourManager: Snapshot taken — root: %d nodes" % _root_snapshot.size())

func _nuke_map_content() -> void:
	"""Destroy ALL non-essential children of LabGridSystem and stray root nodes.
	The grid system rebuilds everything during map generation, so only the 9
	essential nodes (CubeScene + 8 components) need to survive."""
	var removed: int = 0

	# Destroy all non-essential children of LabGridSystem (cubes, artifacts,
	# collision bodies, multimesh instances, spawn managers, everything)
	if lab_grid_system:
		for child in lab_grid_system.get_children():
			if child.name not in _GRID_ESSENTIAL:
				child.queue_free()
				removed += 1
		# Null out LabGridSystem's catalog refs — they'll be recreated
		# by _on_lab_map_ready_for_catalog() on next map_generation_complete
		if lab_grid_system.get("desktop_catalog"):
			lab_grid_system.desktop_catalog = null
		if lab_grid_system.get("artifact_spawn_manager"):
			lab_grid_system.artifact_spawn_manager = null

	# Destroy stray nodes on root (DesktopArtifactCatalog, sound clones, effects)
	for child in get_tree().root.get_children():
		if child.name not in _root_snapshot:
			child.queue_free()
			removed += 1

	print("CameraTourManager: Nuked %d nodes before map reload" % removed)

# ---------------------------------------------------------------------------
# Camera positioning — always start at origin looking +Z
# ---------------------------------------------------------------------------
func _position_camera_at_start() -> void:
	if not is_instance_valid(tour_camera):
		return
	# Always start at origin, eye height, looking in +Z direction
	tour_camera.global_position = Vector3(0, camera_height, 0)
	tour_camera.global_transform = tour_camera.global_transform.looking_at(
		Vector3(0, camera_height, 1.0), Vector3.UP)
	if waypoints.size() > 0:
		_look_target = waypoints[0].look_target
	else:
		_look_target = Vector3(0, camera_height, 5.0)
	_is_looking = true

# ---------------------------------------------------------------------------
# Camera path generation
# ---------------------------------------------------------------------------
func _generate_path() -> void:
	waypoints.clear()
	waypoint_index = 0

	if not is_instance_valid(tour_camera):
		return

	var start_pos := Vector3(0, camera_height, 0)

	# Collect POIs
	var artifacts := _collect_artifacts()
	print("CameraTourManager: Found %d artifacts in '%s'" % [artifacts.size(), current_map_name])
	var utilities := _collect_utilities()
	print("CameraTourManager: Found %d utilities in '%s'" % [utilities.size(), current_map_name])

	var all_pois: Array[Dictionary] = []
	all_pois.append_array(artifacts)
	all_pois.append_array(utilities)

	if all_pois.is_empty():
		_generate_overview_path(start_pos)
		return

	# Order by nearest-neighbor from start
	var ordered := _order_nearest_neighbor(start_pos, all_pois)

	# Overview waypoint
	var grid_dims := _get_grid_dimensions()
	var map_center := Vector3(grid_dims.x * 0.5, 0, grid_dims.z * 0.5)
	var overview_pos := Vector3(map_center.x, overview_height, map_center.z + grid_dims.z * 0.3)

	waypoints.append({
		"position": overview_pos,
		"look_target": map_center,
		"type": "overview",
		"name": "Map Overview: %s" % current_map_name,
		"duration": 1.5
	})

	# Move to first POI area
	waypoints.append({
		"position": start_pos,
		"look_target": ordered[0].world_position if ordered.size() > 0 else map_center,
		"type": "move",
		"name": "Start",
		"duration": 0.0
	})

	# Visit each POI
	for i in range(ordered.size()):
		var poi: Dictionary = ordered[i]
		var artifact_pos: Vector3 = poi.world_position
		var prev_pos: Vector3 = waypoints[waypoints.size() - 1].position
		var approach_pos := _compute_approach_position(prev_pos, artifact_pos)

		waypoints.append({
			"position": approach_pos,
			"look_target": artifact_pos,
			"type": "approach",
			"name": "Approaching %s" % poi.name,
			"duration": 0.0
		})
		waypoints.append({
			"position": approach_pos,
			"look_target": artifact_pos,
			"type": "gaze",
			"name": "Viewing %s" % poi.name,
			"duration": gaze_duration
		})

	if progress_bar:
		progress_bar.max_value = waypoints.size()
		progress_bar.value = 0

func _generate_overview_path(start_pos: Vector3) -> void:
	var dims := _get_grid_dimensions()
	var center := Vector3(dims.x * 0.5, 0, dims.z * 0.5)

	waypoints.append({
		"position": Vector3(center.x, overview_height, center.z + dims.z * 0.5),
		"look_target": center,
		"type": "overview",
		"name": "Overview",
		"duration": 1.5
	})
	waypoints.append({
		"position": Vector3(0, camera_height + 1, 0),
		"look_target": center, "type": "move", "name": "Corner A", "duration": 0.0
	})
	waypoints.append({
		"position": Vector3(dims.x, camera_height + 1, 0),
		"look_target": center, "type": "move", "name": "Corner B", "duration": 0.0
	})
	waypoints.append({
		"position": Vector3(dims.x, camera_height + 1, dims.z),
		"look_target": center, "type": "move", "name": "Corner C", "duration": 0.0
	})
	waypoints.append({
		"position": Vector3(0, camera_height + 1, dims.z),
		"look_target": center, "type": "move", "name": "Corner D", "duration": 0.0
	})
	waypoints.append({
		"position": Vector3(center.x, overview_height, center.z - dims.z * 0.3),
		"look_target": center,
		"type": "overview",
		"name": "Final Overview",
		"duration": 1.5
	})

	if progress_bar:
		progress_bar.max_value = waypoints.size()
		progress_bar.value = 0

# ---------------------------------------------------------------------------
# Artifact / POI collection
# ---------------------------------------------------------------------------
func _collect_artifacts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not lab_grid_system:
		return result

	var interactables_comp = lab_grid_system.get("interactables_component")
	if not interactables_comp:
		for child in lab_grid_system.get_children():
			if child.has_method("get_all_interactable_positions"):
				interactables_comp = child
				break
	if not interactables_comp:
		return result
	if not interactables_comp.has_method("get_all_interactable_positions"):
		return result

	var positions = interactables_comp.get_all_interactable_positions()
	for grid_pos in positions:
		if interactables_comp.has_method("get_interactable_at"):
			var node = interactables_comp.get_interactable_at(grid_pos.x, grid_pos.y, grid_pos.z)
			if node and is_instance_valid(node) and node is Node3D:
				var pos: Vector3 = node.global_position
				if pos.is_finite():
					result.append({
						"world_position": pos,
						"name": node.get_meta("artifact_name", node.name),
						"type": "artifact"
					})
	return result

func _collect_utilities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var utilities := get_tree().get_nodes_in_group("utility")
	for util in utilities:
		if util is Node3D and is_instance_valid(util):
			var pos: Vector3 = util.global_position
			if pos.is_finite():
				result.append({
					"world_position": pos,
					"name": "Teleporter: %s" % util.name,
					"type": "utility"
				})
	return result

# ---------------------------------------------------------------------------
# Path ordering
# ---------------------------------------------------------------------------
func _order_nearest_neighbor(start_pos: Vector3, pois: Array[Dictionary]) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = []
	var remaining := pois.duplicate()
	var current_pos := start_pos
	while remaining.size() > 0:
		var nearest_idx: int = 0
		var nearest_dist: float = INF
		for i in range(remaining.size()):
			var dist := current_pos.distance_to(remaining[i].world_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_idx = i
		ordered.append(remaining[nearest_idx])
		current_pos = remaining[nearest_idx].world_position
		remaining.remove_at(nearest_idx)
	return ordered

func _compute_approach_position(from_pos: Vector3, artifact_pos: Vector3) -> Vector3:
	var direction := (artifact_pos - from_pos)
	direction.y = 0
	if direction.length_squared() < 0.01:
		direction = Vector3(1, 0, 1).normalized()
	direction = direction.normalized()
	var approach := artifact_pos - direction * approach_distance
	approach.y = maxf(artifact_pos.y + 0.5, camera_height)
	if approach.distance_to(artifact_pos) < 0.5:
		approach = artifact_pos + Vector3(-approach_distance, 0.5, -approach_distance)
		approach.y = maxf(approach.y, camera_height)
	return approach

# ---------------------------------------------------------------------------
# Camera movement — tween-based
# ---------------------------------------------------------------------------
func _start_traversal() -> void:
	if waypoints.is_empty():
		_on_map_tour_complete()
		return
	waypoint_index = 0
	_move_to_next_waypoint()

func _move_to_next_waypoint() -> void:
	if not is_instance_valid(tour_camera):
		return
	if waypoint_index >= waypoints.size():
		_on_map_tour_complete()
		return

	var wp: Dictionary = waypoints[waypoint_index]

	_look_target = wp.look_target
	_is_looking = true
	_update_progress_display()

	print("CameraTourManager: [%d/%d] %s" % [waypoint_index + 1, waypoints.size(), wp.name])

	var distance := tour_camera.global_position.distance_to(wp.position)
	var move_duration := distance / maxf(move_speed, 0.1)
	move_duration = clampf(move_duration, 0.05, 30.0)

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_ease(Tween.EASE_IN_OUT)
	active_tween.set_trans(Tween.TRANS_CUBIC)
	active_tween.tween_property(tour_camera, "global_position", wp.position, move_duration)
	active_tween.tween_callback(_on_waypoint_reached)

	if is_paused:
		active_tween.set_speed_scale(0.0)
	else:
		active_tween.set_speed_scale(speed_multiplier)

func _on_waypoint_reached() -> void:
	if not is_instance_valid(tour_camera):
		return
	if waypoint_index >= waypoints.size():
		_on_map_tour_complete()
		return

	var wp: Dictionary = waypoints[waypoint_index]

	if wp.type == "gaze" or wp.type == "overview":
		var hold_duration: float = wp.get("duration", gaze_duration)
		hold_duration = maxf(hold_duration / maxf(speed_multiplier, 0.1), 0.1)

		if active_tween and active_tween.is_valid():
			active_tween.kill()

		active_tween = create_tween()
		active_tween.tween_interval(hold_duration)
		active_tween.tween_callback(_advance_waypoint)

		if is_paused:
			active_tween.set_speed_scale(0.0)
	else:
		_advance_waypoint()

func _advance_waypoint() -> void:
	waypoint_index += 1
	_move_to_next_waypoint()

func _on_map_tour_complete() -> void:
	print("CameraTourManager: Map '%s' tour complete" % current_map_name)
	_is_looking = false
	_advance_to_next_map()

func _advance_to_next_map() -> void:
	if spine_index == -1:
		spine_index = 0
		map_index = 0
	else:
		map_index += 1

	while spine_index < tour_data.size():
		var seq: Dictionary = tour_data[spine_index]
		if map_index < seq.maps.size():
			_load_map(seq.maps[map_index])
			return
		else:
			spine_index += 1
			map_index = 0

	_tour_finished()

func _tour_finished() -> void:
	print("CameraTourManager: === TOUR COMPLETE ===")
	tour_complete = true
	if sequence_label:
		sequence_label.text = "TOUR COMPLETE"
	if map_label:
		map_label.text = "All %d sequences visited" % tour_data.size()
	if speed_label:
		speed_label.text = "Press ESC to quit"

# ---------------------------------------------------------------------------
# Smooth look-at in _process
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not _is_looking or not is_instance_valid(tour_camera):
		return

	var to_target := _look_target - tour_camera.global_position
	var dist := to_target.length()
	if dist < 0.1:
		return

	var look_dir := to_target / dist
	if absf(look_dir.dot(Vector3.UP)) > 0.99:
		return

	var target_transform := tour_camera.global_transform.looking_at(_look_target, Vector3.UP)
	tour_camera.global_transform = tour_camera.global_transform.interpolate_with(
		target_transform, minf(look_smoothing * delta, 1.0))

# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_SPACE:
			_toggle_pause()
		KEY_EQUAL, KEY_KP_ADD:
			_change_speed(2.0)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_change_speed(0.5)
		KEY_N:
			_skip_to_next_map()
		KEY_P:
			_skip_to_previous_map()
		KEY_S:
			_skip_to_next_sequence()
		KEY_ESCAPE:
			get_tree().quit()

func _toggle_pause() -> void:
	is_paused = !is_paused
	if active_tween and active_tween.is_valid():
		active_tween.set_speed_scale(0.0 if is_paused else speed_multiplier)
	_update_speed_display()
	print("CameraTourManager: %s" % ("PAUSED" if is_paused else "RESUMED"))

func _change_speed(factor: float) -> void:
	speed_multiplier = clampf(speed_multiplier * factor, 0.25, 100.0)
	if active_tween and active_tween.is_valid() and not is_paused:
		active_tween.set_speed_scale(speed_multiplier)
	_update_speed_display()
	print("CameraTourManager: Speed = %.1fx" % speed_multiplier)

func _skip_to_next_map() -> void:
	if is_transitioning or tour_complete:
		return
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	_advance_to_next_map()

func _skip_to_previous_map() -> void:
	if is_transitioning or tour_complete:
		return
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	if map_index > 0:
		map_index -= 1
	elif spine_index > 0:
		spine_index -= 1
		var seq: Dictionary = tour_data[spine_index]
		map_index = maxi(0, seq.maps.size() - 1)
	elif spine_index == 0:
		spine_index = -1
		map_index = 0
		_load_map("Lab")
		return

	if spine_index >= 0 and spine_index < tour_data.size():
		var seq: Dictionary = tour_data[spine_index]
		if map_index < seq.maps.size():
			_load_map(seq.maps[map_index])

func _skip_to_next_sequence() -> void:
	if is_transitioning or tour_complete:
		return
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	spine_index += 1
	map_index = 0

	if spine_index < tour_data.size():
		_load_map(tour_data[spine_index].maps[0])
	else:
		_tour_finished()

# ---------------------------------------------------------------------------
# Fade transitions
# ---------------------------------------------------------------------------
func _fade_to_black(dur: float) -> void:
	if not fade_rect:
		return
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", 1.0, dur)
	await t.finished

func _fade_from_black(dur: float) -> void:
	if not fade_rect:
		return
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", 0.0, dur)
	await t.finished

# ---------------------------------------------------------------------------
# UI updates
# ---------------------------------------------------------------------------
func _update_sequence_display() -> void:
	if not sequence_label:
		return
	if spine_index == -1:
		sequence_label.text = "Laboratory Hub"
	elif spine_index >= 0 and spine_index < tour_data.size():
		var seq: Dictionary = tour_data[spine_index]
		sequence_label.text = "%s (%d/%d)" % [seq.display_name, spine_index + 1, tour_data.size()]
	else:
		sequence_label.text = "Tour"

func _update_map_display() -> void:
	if not map_label:
		return
	if spine_index == -1:
		map_label.text = "Lab"
	elif spine_index >= 0 and spine_index < tour_data.size():
		var seq: Dictionary = tour_data[spine_index]
		map_label.text = "%s (%d/%d)" % [current_map_name, map_index + 1, seq.maps.size()]
	else:
		map_label.text = current_map_name

func _update_speed_display() -> void:
	if not speed_label:
		return
	if is_paused:
		speed_label.text = "PAUSED"
	else:
		speed_label.text = "Speed: %.1fx" % speed_multiplier

func _update_progress_display() -> void:
	if progress_bar:
		progress_bar.value = waypoint_index

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _get_grid_dimensions() -> Vector3:
	if lab_grid_system and lab_grid_system.has_method("get_grid_dimensions"):
		var dims = lab_grid_system.get_grid_dimensions()
		return Vector3(dims.x, dims.y, dims.z)
	var data_comp = lab_grid_system.get("data_component") if lab_grid_system else null
	if data_comp and data_comp.has_method("get_grid_dimensions"):
		var dims = data_comp.get_grid_dimensions()
		return Vector3(dims.x, dims.y, dims.z)
	return Vector3(10, 4, 10)

# ---------------------------------------------------------------------------
# Per-sequence pre-caching — load next sequence's artifact scenes in background
# ---------------------------------------------------------------------------
var _artifact_registry: Dictionary = {}  # lookup_name -> scene_path (built once)

func _build_artifact_registry() -> void:
	"""Build a lookup_name → scene_path dictionary from all registry JSONs."""
	# Try to reuse GridInteractablesComponent's loaded registry first
	if lab_grid_system:
		var interactables = lab_grid_system.get_node_or_null("GridInteractablesComponent")
		if interactables and interactables.get("grid_artifact_registry"):
			for key in interactables.grid_artifact_registry:
				var entry = interactables.grid_artifact_registry[key]
				if entry is Dictionary and entry.has("scene"):
					_artifact_registry[key] = entry["scene"]
			if _artifact_registry.size() > 0:
				print("CameraTourManager: Built registry from GridInteractablesComponent (%d entries)" % _artifact_registry.size())
				return

	# Fallback: read registry JSONs ourselves
	var registry_paths: Array[String] = []
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".json"):
				registry_paths.append("res://commons/artifacts/registry/" + fname)
			fname = dir.get_next()

	for reg_path in registry_paths:
		if not FileAccess.file_exists(reg_path):
			continue
		var f := FileAccess.open(reg_path, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		if data == null:
			continue
		var artifacts: Dictionary = data.get("artifacts", {})
		for key in artifacts:
			var entry = artifacts[key]
			if entry is Dictionary:
				var sp: String = entry.get("scene", "")
				if sp != "":
					_artifact_registry[key] = sp
	print("CameraTourManager: Built registry from JSON files (%d entries)" % _artifact_registry.size())

func _extract_lookup_name(token: String) -> String:
	"""Strip #config and :rotation suffixes from a map interactable token."""
	var base := token.split("#")[0]
	base = base.split(":")[0]
	return base.strip_edges()

func _precache_sequence(seq_index: int) -> void:
	"""Pre-cache artifact scenes for a specific sequence by reading its map JSONs."""
	if seq_index < 0 or seq_index >= tour_data.size():
		return
	if _artifact_registry.is_empty():
		_build_artifact_registry()

	var seq: Dictionary = tour_data[seq_index]
	var scene_paths: Dictionary = {}

	# Read each map's JSON to find which artifacts it uses
	for map_name in seq.maps:
		var map_path := "res://commons/maps/%s/map_data.json" % map_name
		if not FileAccess.file_exists(map_path):
			continue
		var f := FileAccess.open(map_path, FileAccess.READ)
		var map_data = JSON.parse_string(f.get_as_text())
		f.close()
		if map_data == null:
			continue
		var layers = map_data.get("layers", {})
		var interactables = layers.get("interactables", [])
		for row in interactables:
			if row is Array:
				for token in row:
					if token is String and token != "":
						var lookup := _extract_lookup_name(token)
						if lookup != "":
							var sp: String = _artifact_registry.get(lookup, "")
							if sp != "" and not scene_paths.has(sp):
								scene_paths[sp] = true

	# Pre-load in batches, yielding to avoid frame stutter
	var count: int = 0
	var batch: int = 0
	for sp in scene_paths:
		if ResourceLoader.exists(sp):
			var res = ResourceLoader.load(sp)
			if res != null:
				count += 1
			batch += 1
			if batch >= 5:
				batch = 0
				await get_tree().process_frame
	print("CameraTourManager: Pre-cached %d scenes for '%s'" % [count, seq.sequence_name])
