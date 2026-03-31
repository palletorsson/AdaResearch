# SceneNarrator.gd — Claude's virtual body in Godot
# Produces structured text streams that give an LLM spatial intuition about 3D scenes.
# Three lenses: spatial reasoning, simulation playback, player journey.
# Outputs to ada_run/ as markdown/JSONL files readable by Claude via file read.

extends Node

# --- Configuration ---
@export var enabled: bool = true
@export var auto_narrate_on_map_load: bool = true
@export var simulation_interval: float = 2.0

# --- Output paths (use user:// on mobile, res:// on desktop for AI readability) ---
var SPATIAL_PATH: String = "user://ada_run/scene_spatial.md" if OS.has_feature("android") else "res://ada_run/scene_spatial.md"
var SIMULATION_PATH: String = "user://ada_run/simulation_transcript.md" if OS.has_feature("android") else "res://ada_run/simulation_transcript.md"
var JOURNEY_PATH: String = "user://ada_run/journey_narrative.md" if OS.has_feature("android") else "res://ada_run/journey_narrative.md"
var EVENTS_PATH: String = "user://ada_run/scene_events.jsonl" if OS.has_feature("android") else "res://ada_run/scene_events.jsonl"

# --- State ---
var _grid_system: GridSystem = null
var _simulation_timer: Timer = null
var _simulation_active: bool = false
var _simulation_tick: int = 0
var _simulation_start_time: String = ""
var _prev_artifact_states: Dictionary = {}
var _event_stream_active: bool = false
var _last_player_cell: Vector3i = Vector3i(-999, -999, -999)

# --- Signals ---
signal snapshot_written(path: String)
signal narration_complete()

func _ready():
	if not enabled:
		return
	print("SceneNarrator: Initializing perception system...")
	_ensure_output_dir()
	_connect_game_manager()
	# GridSystem is per-scene, connect on first map load
	call_deferred("_try_connect_grid_system")
	# Create simulation timer (not started)
	_simulation_timer = Timer.new()
	_simulation_timer.one_shot = false
	_simulation_timer.timeout.connect(_on_simulation_tick)
	add_child(_simulation_timer)

# ============================================================
# PUBLIC API
# ============================================================

## Full narration: all three lenses in sequence
func narrate_full() -> void:
	if not enabled:
		return
	print("SceneNarrator: Running full narration...")
	take_spatial_snapshot()
	walk_journey()
	print("SceneNarrator: Full narration complete.")
	narration_complete.emit()

## Full narration to custom output paths
func narrate_full_to(spatial_path: String, journey_path: String) -> void:
	var gs = _get_grid_system()
	if not gs:
		push_warning("SceneNarrator: No GridSystem found, skipping narration.")
		return
	var spatial_text = _build_spatial_analysis(gs)
	_write_file(spatial_path, spatial_text)
	var journey_text = _build_journey_narrative(gs)
	_write_file(journey_path, journey_text)

## Returns structured spatial data as a Dictionary
func get_spatial_data() -> Dictionary:
	var gs = _get_grid_system()
	if not gs:
		return {}
	var info = gs.get_current_map_info()
	var dims = gs.get_grid_dimensions()
	var spawn_pos = _find_spawn_position(gs)
	var artifact_positions = _get_artifact_positions(gs)
	var teleporter_pos = _find_teleporter_position(gs)
	var rooms = _detect_rooms(gs, dims)
	var height_stats = _compute_height_stats(gs, dims)

	var artifacts_data: Array = []
	for apos in artifact_positions:
		artifacts_data.append({
			"name": _get_artifact_name_at(gs, apos),
			"pos": [apos.x, apos.y, apos.z],
		})

	var rooms_data: Array = []
	for i in range(rooms.size()):
		var room = rooms[i]
		var room_artifacts = _artifacts_in_region(artifact_positions, room, gs)
		rooms_data.append({
			"label": _room_letter(i),
			"region": _describe_region(room, dims),
			"tiles": room.size(),
			"artifacts": Array(room_artifacts),
		})

	return {
		"map_name": info.get("name", "Unknown"),
		"dimensions": [dims.x, dims.y, dims.z],
		"spawn": [spawn_pos.x, spawn_pos.y, spawn_pos.z] if spawn_pos != Vector3i(-1,-1,-1) else null,
		"teleporter": [teleporter_pos.x, teleporter_pos.y, teleporter_pos.z] if teleporter_pos != Vector3i(-1,-1,-1) else null,
		"artifacts": artifacts_data,
		"rooms": rooms_data,
		"height": height_stats,
	}

## Returns structured journey data with issue detection as a Dictionary
func get_journey_data() -> Dictionary:
	var gs = _get_grid_system()
	if not gs:
		return {}
	var info = gs.get_current_map_info()
	var dims = gs.get_grid_dimensions()
	var spawn_pos = _find_spawn_position(gs)
	var artifact_positions = _get_artifact_positions(gs)
	var teleporter_pos = _find_teleporter_position(gs)

	var metadata = {}
	if gs.data_component:
		metadata = gs.data_component.get_map_metadata()
	var seq_name = metadata.get("sequence", "unknown")

	var issues: Array = []

	if spawn_pos == Vector3i(-1, -1, -1):
		issues.append({"type": "no_spawn", "description": "No spawn point found", "severity": "critical"})
		return {
			"map_name": info.get("name", "Unknown"),
			"sequence": seq_name,
			"spawn_pos": null,
			"teleporter": null,
			"artifacts": [],
			"pacing": {},
			"dead_ends": [],
			"issues": issues,
		}

	var walkable = _get_walkable_tiles(gs, dims)
	var spawn_flat = Vector3i(spawn_pos.x, 0, spawn_pos.z)
	if not walkable.has(spawn_flat):
		walkable[spawn_flat] = true
	var bfs_result = _bfs_from(spawn_flat, walkable, dims)
	var distances = bfs_result.distances

	# Sort artifacts by distance
	var sorted_artifacts: Array = []
	var unreachable_artifacts: Array = []
	for apos in artifact_positions:
		var walk_key = Vector3i(apos.x, 0, apos.z)
		var dist = distances.get(walk_key, -1)
		var name_str = _get_artifact_name_at(gs, apos)
		var visible_from_spawn = _check_line_of_sight(gs, spawn_flat, Vector3i(apos.x, 0, apos.z), dims)
		var entry = {
			"name": name_str,
			"pos": [apos.x, apos.y, apos.z],
			"dist": dist,
			"reachable": dist >= 0,
			"visible_from_spawn": visible_from_spawn,
		}
		if dist >= 0:
			sorted_artifacts.append(entry)
		else:
			unreachable_artifacts.append(entry)
	sorted_artifacts.sort_custom(func(a, b): return a.dist < b.dist)

	# Teleporter reachability
	var tp_data = null
	if teleporter_pos != Vector3i(-1, -1, -1):
		var tp_key = Vector3i(teleporter_pos.x, 0, teleporter_pos.z)
		var tp_dist = distances.get(tp_key, -1)
		if tp_dist < 0:
			for adj in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var neighbor = Vector3i(tp_key.x + adj.x, 0, tp_key.z + adj.y)
				var nd = distances.get(neighbor, -1)
				if nd >= 0 and (tp_dist < 0 or nd + 1 < tp_dist):
					tp_dist = nd + 1
		tp_data = {
			"pos": [teleporter_pos.x, teleporter_pos.y, teleporter_pos.z],
			"reachable": tp_dist >= 0,
			"dist": tp_dist,
		}
		if tp_dist < 0:
			issues.append({"type": "unreachable_teleporter", "description": "Teleporter at (%d,%d,%d) unreachable from spawn" % [teleporter_pos.x, teleporter_pos.y, teleporter_pos.z], "severity": "critical"})

	# Dead ends
	var dead_ends = _find_dead_ends(walkable, dims)
	var dead_end_positions: Array = []
	for de in dead_ends:
		dead_end_positions.append([de.x, de.y, de.z])
	if dead_ends.size() > 3:
		issues.append({"type": "high_dead_ends", "description": "%d dead ends found" % dead_ends.size(), "severity": "low"})

	# Pacing
	var total_walkable = walkable.size()
	var total_reachable = sorted_artifacts.size()
	var total_artifacts = artifact_positions.size()
	var pacing_density: float = 0.0
	if total_reachable > 0 and sorted_artifacts.size() > 0:
		pacing_density = float(sorted_artifacts[-1].dist) / float(total_reachable)
	var pacing = {
		"density": pacing_density,
		"walkable_tiles": total_walkable,
		"reachable_artifacts": total_reachable,
		"total_artifacts": total_artifacts,
	}
	if pacing_density > 8.0:
		issues.append({"type": "sparse_pacing", "description": "%.1f steps per artifact (sparse)" % pacing_density, "severity": "low"})
	elif total_reachable > 0 and pacing_density < 1.0:
		issues.append({"type": "dense_pacing", "description": "%.1f steps per artifact (very dense)" % pacing_density, "severity": "low"})

	# Unreachable artifacts
	if unreachable_artifacts.size() > 0:
		for ua in unreachable_artifacts:
			issues.append({"type": "unreachable_artifact", "description": "%s at (%d,%d,%d) unreachable" % [ua.name, ua.pos[0], ua.pos[1], ua.pos[2]], "severity": "high"})

	var all_artifacts: Array = sorted_artifacts + unreachable_artifacts

	return {
		"map_name": info.get("name", "Unknown"),
		"sequence": seq_name,
		"spawn_pos": [spawn_pos.x, spawn_pos.y, spawn_pos.z],
		"teleporter": tp_data,
		"artifacts": all_artifacts,
		"pacing": pacing,
		"dead_ends": dead_end_positions,
		"issues": issues,
	}

## Lens 1: Spatial analysis — visibility, rooms, sightlines
func take_spatial_snapshot() -> void:
	var gs = _get_grid_system()
	if not gs:
		push_warning("SceneNarrator: No GridSystem found, skipping spatial snapshot.")
		return
	var text = _build_spatial_analysis(gs)
	_write_file(SPATIAL_PATH, text)
	print("SceneNarrator: Spatial snapshot written to %s" % SPATIAL_PATH)
	snapshot_written.emit(SPATIAL_PATH)

## Lens 2: Simulation watch — start/stop periodic state capture
func start_simulation_watch(interval: float = -1.0) -> void:
	if interval > 0:
		simulation_interval = interval
	_simulation_active = true
	_simulation_tick = 0
	_simulation_start_time = Time.get_datetime_string_from_system()
	_prev_artifact_states = {}
	# Write header
	var header = "# Simulation Transcript\nStarted: %s | Interval: %.1fs\n\n" % [_simulation_start_time, simulation_interval]
	_write_file(SIMULATION_PATH, header)
	# Capture initial state
	_on_simulation_tick()
	_simulation_timer.wait_time = simulation_interval
	_simulation_timer.start()
	print("SceneNarrator: Simulation watch started (%.1fs interval)" % simulation_interval)

func stop_simulation_watch() -> void:
	_simulation_active = false
	_simulation_timer.stop()
	_append_file(SIMULATION_PATH, "\n## Watch Stopped\nStopped: %s | Ticks: %d\n" % [Time.get_datetime_string_from_system(), _simulation_tick])
	print("SceneNarrator: Simulation watch stopped after %d ticks" % _simulation_tick)

## Lens 3: Journey walk — BFS from spawn, encounter narrative
func walk_journey() -> void:
	var gs = _get_grid_system()
	if not gs:
		push_warning("SceneNarrator: No GridSystem found, skipping journey walk.")
		return
	var text = _build_journey_narrative(gs)
	_write_file(JOURNEY_PATH, text)
	print("SceneNarrator: Journey narrative written to %s" % JOURNEY_PATH)

## Event stream — log significant events as JSONL
func start_event_stream() -> void:
	_event_stream_active = true
	_last_player_cell = Vector3i(-999, -999, -999)
	var header_line = JSON.stringify({"t": _timestamp(), "event": "stream_started"}) + "\n"
	_write_file(EVENTS_PATH, header_line)
	set_process(true)
	print("SceneNarrator: Event stream started")

func stop_event_stream() -> void:
	_event_stream_active = false
	set_process(false)
	_log_event({"event": "stream_stopped"})
	print("SceneNarrator: Event stream stopped")

# ============================================================
# LENS 1: SPATIAL ANALYSIS
# ============================================================

func _build_spatial_analysis(gs: GridSystem) -> String:
	var info = gs.get_current_map_info()
	var dims = gs.get_grid_dimensions()
	var lines: PackedStringArray = []

	lines.append("# Spatial Analysis — %s (%dx%d)" % [info.get("name", "Unknown"), dims.x, dims.z])
	lines.append("Generated: %s\n" % Time.get_datetime_string_from_system())

	# Get key positions
	var spawn_pos = _find_spawn_position(gs)
	var artifact_positions = _get_artifact_positions(gs)
	var teleporter_pos = _find_teleporter_position(gs)
	var junctions = _find_junctions(gs, dims)

	# Artifact list
	lines.append("## Artifacts (%d)" % artifact_positions.size())
	for apos in artifact_positions:
		var name_str = _get_artifact_name_at(gs, apos)
		var state_str = ""
		var artifact = _try_get_artifact_node(gs, apos)
		if artifact:
			var state = _get_artifact_state(artifact)
			state_str = _format_state_brief(state)
		lines.append("- %s at (%d, %d, %d)%s" % [name_str, apos.x, apos.y, apos.z, state_str])
	lines.append("")

	# Utilities
	lines.append("## Utilities")
	if spawn_pos != Vector3i(-1, -1, -1):
		lines.append("- Spawn at (%d, %d, %d)" % [spawn_pos.x, spawn_pos.y, spawn_pos.z])
	if teleporter_pos != Vector3i(-1, -1, -1):
		lines.append("- Teleporter at (%d, %d, %d)" % [teleporter_pos.x, teleporter_pos.y, teleporter_pos.z])
	lines.append("")

	# Visibility from spawn (flatten to XZ for raycasting)
	var spawn_flat = Vector3i(spawn_pos.x, 0, spawn_pos.z)
	if spawn_pos != Vector3i(-1, -1, -1) and artifact_positions.size() > 0:
		lines.append("## Visibility from Spawn (%d, %d, %d)" % [spawn_pos.x, spawn_pos.y, spawn_pos.z])
		for apos in artifact_positions:
			var name_str = _get_artifact_name_at(gs, apos)
			var apos_flat = Vector3i(apos.x, 0, apos.z)
			var visible = _check_line_of_sight(gs, spawn_flat, apos_flat, dims)
			var dist = _grid_distance(spawn_flat, apos_flat)
			var direction = _cardinal_direction(spawn_flat, apos_flat)
			if visible:
				lines.append("- %s: VISIBLE — %.1fm, %s" % [name_str, dist, direction])
			else:
				lines.append("- %s: BLOCKED — %.1fm, %s" % [name_str, dist, direction])
		lines.append("")

	# Visibility from junctions
	for junc in junctions:
		if junc == spawn_pos:
			continue
		lines.append("## Visibility from Junction (%d, %d, %d)" % [junc.x, junc.y, junc.z])
		for apos in artifact_positions:
			var name_str = _get_artifact_name_at(gs, apos)
			var visible = _check_line_of_sight(gs, junc, apos, dims)
			var dist = _grid_distance(junc, apos)
			var direction = _cardinal_direction(junc, apos)
			if visible:
				lines.append("- %s: VISIBLE — %.1fm, %s" % [name_str, dist, direction])
			else:
				lines.append("- %s: BLOCKED — %.1fm, %s" % [name_str, dist, direction])
		lines.append("")

	# Room detection via flood-fill
	var rooms = _detect_rooms(gs, dims)
	if rooms.size() > 0:
		lines.append("## Rooms and Clusters")
		for i in range(rooms.size()):
			var room = rooms[i]
			var room_artifacts = _artifacts_in_region(artifact_positions, room, gs)
			var region_name = _describe_region(room, dims)
			if room_artifacts.size() > 0:
				lines.append("- Room %s (%s): %s — %d tiles" % [
					_room_letter(i), region_name,
					", ".join(room_artifacts), room.size()])
			else:
				lines.append("- Room %s (%s): empty — %d tiles" % [_room_letter(i), region_name, room.size()])
		lines.append("")

	# Height summary
	lines.append("## Height Map")
	var height_stats = _compute_height_stats(gs, dims)
	lines.append("- Ground (h1): %d tiles (%.0f%%)" % [height_stats.ground, height_stats.ground_pct])
	lines.append("- Walls (h2-h5): %d tiles" % height_stats.walls)
	lines.append("- Boundary (h6+): %d tiles" % height_stats.boundary)
	lines.append("- Void (h0): %d tiles" % height_stats.void)
	lines.append("")

	return "\n".join(lines)

# ============================================================
# LENS 2: SIMULATION WATCH
# ============================================================

func _on_simulation_tick() -> void:
	if not _simulation_active:
		return
	var gs = _get_grid_system()
	if not gs:
		return

	_simulation_tick += 1
	var elapsed = _simulation_tick * simulation_interval
	var current_states = _capture_all_artifact_states(gs)
	var deltas = _compute_state_deltas(current_states, _prev_artifact_states)

	var lines: PackedStringArray = []
	lines.append("## t=%.0fs — Tick %d" % [elapsed, _simulation_tick])

	if deltas.is_empty():
		lines.append("No significant changes\n")
	else:
		for artifact_name in deltas:
			var changes = deltas[artifact_name]
			for param in changes:
				var old_val = changes[param].get("old", "?")
				var new_val = changes[param].get("new", "?")
				lines.append("- %s.%s: %s → %s" % [artifact_name, param, str(old_val), str(new_val)])
		lines.append("")

	_append_file(SIMULATION_PATH, "\n".join(lines) + "\n")
	_prev_artifact_states = current_states

func _capture_all_artifact_states(gs: GridSystem) -> Dictionary:
	var states: Dictionary = {}
	if not gs.interactables_component:
		return states
	for pos in gs.interactables_component.interactable_objects:
		var artifact = gs.interactables_component.interactable_objects[pos]
		if not is_instance_valid(artifact):
			continue
		var name_str = _get_artifact_name(artifact)
		states[name_str] = _get_artifact_state(artifact)
	return states

func _compute_state_deltas(current: Dictionary, previous: Dictionary) -> Dictionary:
	var deltas: Dictionary = {}
	for name_str in current:
		if not previous.has(name_str):
			continue  # New artifact, skip (first tick)
		var curr_state = current[name_str]
		var prev_state = previous[name_str]
		var artifact_deltas: Dictionary = {}
		for key in curr_state:
			if not prev_state.has(key):
				continue
			var cv = curr_state[key]
			var pv = prev_state[key]
			if typeof(cv) == TYPE_FLOAT and typeof(pv) == TYPE_FLOAT:
				if absf(cv - pv) > 0.01:
					artifact_deltas[key] = {"old": snapped(pv, 0.01), "new": snapped(cv, 0.01)}
			elif typeof(cv) == TYPE_INT and typeof(pv) == TYPE_INT:
				if cv != pv:
					artifact_deltas[key] = {"old": pv, "new": cv}
			elif str(cv) != str(pv):
				artifact_deltas[key] = {"old": pv, "new": cv}
		if not artifact_deltas.is_empty():
			deltas[name_str] = artifact_deltas
	return deltas

# ============================================================
# LENS 3: JOURNEY NARRATIVE
# ============================================================

func _build_journey_narrative(gs: GridSystem) -> String:
	var info = gs.get_current_map_info()
	var dims = gs.get_grid_dimensions()
	var lines: PackedStringArray = []

	var spawn_pos = _find_spawn_position(gs)
	var artifact_positions = _get_artifact_positions(gs)
	var teleporter_pos = _find_teleporter_position(gs)

	# Get sequence context from map metadata
	var metadata = {}
	if gs.data_component:
		metadata = gs.data_component.get_map_metadata()
	var seq_name = metadata.get("sequence", "unknown")
	var seq_pos = metadata.get("position", "?")

	lines.append("# Player Journey — %s" % info.get("name", "Unknown"))
	lines.append("Sequence: %s | Position: %s\n" % [seq_name, seq_pos])

	if spawn_pos == Vector3i(-1, -1, -1):
		lines.append("**No spawn point found.** Cannot walk journey.\n")
		return "\n".join(lines)

	# BFS from spawn across walkable tiles (flatten to XZ plane)
	var walkable = _get_walkable_tiles(gs, dims)
	var spawn_flat = Vector3i(spawn_pos.x, 0, spawn_pos.z)
	# Ensure spawn is in walkable set
	if not walkable.has(spawn_flat):
		walkable[spawn_flat] = true
	var bfs_result = _bfs_from(spawn_flat, walkable, dims)
	var distances = bfs_result.distances  # Dict<Vector3i, int>
	var parents = bfs_result.parents  # Dict<Vector3i, Vector3i>

	# Sort artifacts by distance from spawn (encounter order)
	var sorted_artifacts: Array = []
	for apos in artifact_positions:
		var walk_key = Vector3i(apos.x, 0, apos.z)  # BFS on XZ plane
		var dist = distances.get(walk_key, -1)
		if dist >= 0:
			sorted_artifacts.append({"pos": apos, "dist": dist})
	sorted_artifacts.sort_custom(func(a, b): return a.dist < b.dist)

	# Walk-through narrative
	lines.append("## Walk-Through")
	var step = 1
	var current_pos = spawn_pos

	# Spawn description
	var spawn_visible = _visible_artifacts_from(gs, spawn_flat, artifact_positions, dims)
	lines.append("%d. **Spawn** at (%d, %d, %d)" % [step, spawn_pos.x, spawn_pos.y, spawn_pos.z])
	if spawn_visible.size() > 0:
		lines.append("   Visible: %s" % ", ".join(spawn_visible))
	lines.append("")
	step += 1

	# Each artifact in encounter order
	for entry in sorted_artifacts:
		var apos = entry.pos
		var walk_dist = entry.dist
		var name_str = _get_artifact_name_at(gs, apos)
		var direction = _cardinal_direction(current_pos, apos)
		var state_str = ""
		var artifact = _try_get_artifact_node(gs, apos)
		if artifact:
			var state = _get_artifact_state(artifact)
			state_str = _format_state_brief(state)

		lines.append("%d. **%d steps %s** to (%d, %d, %d)" % [step, walk_dist, direction, apos.x, apos.y, apos.z])
		lines.append("   Encounter: %s%s" % [name_str, state_str])

		# What's visible from here?
		var visible_here = _visible_artifacts_from(gs, apos, artifact_positions, dims)
		if visible_here.size() > 1:  # More than just self
			var others: PackedStringArray = []
			for vn in visible_here:
				if vn != name_str:
					others.append(vn)
			if others.size() > 0:
				lines.append("   Also visible: %s" % ", ".join(others))
		lines.append("")
		current_pos = apos
		step += 1

	# Teleporter — may sit on void; check the tile itself OR any adjacent walkable tile
	if teleporter_pos != Vector3i(-1, -1, -1):
		var tp_key = Vector3i(teleporter_pos.x, 0, teleporter_pos.z)
		var tp_dist = distances.get(tp_key, -1)
		if tp_dist < 0:
			# Teleporter tile might be void — check adjacent tiles
			for adj in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var neighbor = Vector3i(tp_key.x + adj.x, 0, tp_key.z + adj.y)
				var nd = distances.get(neighbor, -1)
				if nd >= 0 and (tp_dist < 0 or nd + 1 < tp_dist):
					tp_dist = nd + 1
		if tp_dist >= 0:
			lines.append("%d. **Teleporter** at (%d, %d, %d) — %d steps from spawn" % [
				step, teleporter_pos.x, teleporter_pos.y, teleporter_pos.z, tp_dist])
		else:
			lines.append("%d. **Teleporter** at (%d, %d, %d) — UNREACHABLE from spawn" % [
				step, teleporter_pos.x, teleporter_pos.y, teleporter_pos.z])
		lines.append("")

	# Pacing assessment
	lines.append("## Pacing Assessment")
	var total_walkable = walkable.size()
	var total_artifacts = sorted_artifacts.size()
	var total_dist = 0
	if sorted_artifacts.size() > 0:
		total_dist = sorted_artifacts[-1].dist
	if total_artifacts > 0:
		lines.append("- Artifact density: 1 per %.1f steps" % [float(total_dist) / float(total_artifacts)])
	lines.append("- Total walkable tiles: %d" % total_walkable)
	lines.append("- Artifacts reachable from spawn: %d / %d" % [sorted_artifacts.size(), artifact_positions.size()])

	# Dead end detection
	var dead_ends = _find_dead_ends(walkable, dims)
	lines.append("- Dead ends: %d" % dead_ends.size())
	if dead_ends.size() > 0 and dead_ends.size() <= 5:
		for de in dead_ends:
			lines.append("  - at (%d, %d, %d)" % [de.x, de.y, de.z])

	# Reachability check
	var unreachable = artifact_positions.size() - sorted_artifacts.size()
	if unreachable > 0:
		lines.append("- WARNING: %d artifact(s) unreachable from spawn" % unreachable)
	else:
		lines.append("- All artifacts reachable from spawn")
	lines.append("")

	return "\n".join(lines)

# ============================================================
# ARTIFACT INTROSPECTION
# ============================================================

func _get_artifact_state(artifact: Node3D) -> Dictionary:
	# Priority 1: custom narrator method
	if artifact.has_method("get_narrator_state"):
		return artifact.call("get_narrator_state")
	# Priority 2: reflect on @export properties
	return _reflect_exports(artifact)

func _reflect_exports(node: Node3D) -> Dictionary:
	var state: Dictionary = {}
	var props = node.get_property_list()
	for prop in props:
		# Only exported properties (PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR)
		if not (prop.usage & PROPERTY_USAGE_EDITOR and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var name: String = prop.name
		# Skip common Node3D properties
		if name in ["transform", "position", "rotation", "scale", "visible", "global_position",
					 "global_rotation", "global_transform", "top_level", "rotation_order",
					 "basis", "quaternion", "global_basis"]:
			continue
		var value = node.get(name)
		# Only include simple types
		match typeof(value):
			TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING:
				state[name] = value
			TYPE_COLOR:
				state[name] = "#" + (value as Color).to_html(false)
			TYPE_VECTOR3:
				state[name] = "(%s, %s, %s)" % [snapped(value.x, 0.01), snapped(value.y, 0.01), snapped(value.z, 0.01)]
	return state

func _get_artifact_name(artifact: Node3D) -> String:
	# Check for lookup_name metadata first
	if artifact.has_meta("lookup_name"):
		return artifact.get_meta("lookup_name")
	# Strip numeric suffixes from node name
	var n = artifact.name.replace("@", "")
	var regex = RegEx.new()
	regex.compile("\\d+$")
	return regex.sub(n, "")

## Get artifact name at a position — tries scene node first, falls back to map data cache.
func _get_artifact_name_at(gs: GridSystem, pos: Vector3i) -> String:
	var node = _try_get_artifact_node(gs, pos)
	if node:
		return _get_artifact_name(node)
	if _artifact_name_cache.has(pos):
		return _artifact_name_cache[pos]
	return "unknown"

## Try to get the scene Node3D for an artifact at a position. Returns null if not instantiated.
func _try_get_artifact_node(gs: GridSystem, pos: Vector3i) -> Node3D:
	if gs.interactables_component and gs.interactables_component.interactable_objects.has(pos):
		var obj = gs.interactables_component.interactable_objects[pos]
		if is_instance_valid(obj):
			return obj
	return null

func _format_state_brief(state: Dictionary) -> String:
	if state.is_empty():
		return ""
	var parts: PackedStringArray = []
	var count = 0
	for key in state:
		if count >= 5:  # Limit to 5 params
			parts.append("...")
			break
		parts.append("%s=%s" % [key, str(state[key])])
		count += 1
	return " | " + ", ".join(parts)

# ============================================================
# SPATIAL HELPERS
# ============================================================

func _find_spawn_position(gs: GridSystem) -> Vector3i:
	# Try instantiated utility nodes first
	if gs.utilities_component:
		for pos in gs.utilities_component.utility_objects:
			var util = gs.utilities_component.utility_objects[pos]
			if not is_instance_valid(util):
				continue
			var uname = util.name.to_lower()
			# Match spawn, moveplayer, startpoint, etc.
			if uname.contains("spawn") or uname.contains("move") or uname.contains("start"):
				return pos
		# Fallback: return first non-teleporter utility position
		if gs.utilities_component.utility_objects.size() > 0:
			for pos in gs.utilities_component.utility_objects:
				var util = gs.utilities_component.utility_objects[pos]
				if is_instance_valid(util):
					var uname = util.name.to_lower()
					if not uname.contains("teleport") and not uname.contains("portal"):
						return pos
	# Fallback: read spawn from raw map data utilities layer
	if gs.data_component:
		var spawn_from_data = _find_spawn_from_map_data(gs)
		if spawn_from_data != Vector3i(-1, -1, -1):
			return spawn_from_data
	# Final fallback: first walkable floor tile
	if gs.structure_component and gs.data_component:
		var dims = gs.data_component.get_grid_dimensions()
		for z in range(int(dims.z)):
			for x in range(int(dims.x)):
				var h = gs.structure_component.find_highest_y_at(x, z)
				if h == 1:  # Floor tile
					return Vector3i(x, 0, z)
	return Vector3i(-1, -1, -1)

## Read spawn position from raw map data utilities layer (m: or s: entries)
func _find_spawn_from_map_data(gs: GridSystem) -> Vector3i:
	if not gs.data_component:
		return Vector3i(-1, -1, -1)
	var utility_data = gs.data_component.get_utility_data()
	if not utility_data or not utility_data.layout_data:
		return Vector3i(-1, -1, -1)
	var layout: Array = utility_data.layout_data
	# layout is 2D array [z][x] — same as interactables layer
	for z in range(layout.size()):
		var row = layout[z]
		if not row is Array:
			continue
		for x in range(row.size()):
			var cell = str(row[x]).strip_edges()
			# m: is MovePlayer, s: is Spawn
			if cell.begins_with("m:") or cell.begins_with("s:") or cell == "s" or cell == "m":
				return Vector3i(x, 0, z)
	return Vector3i(-1, -1, -1)

func _find_teleporter_position(gs: GridSystem) -> Vector3i:
	# Try instantiated utility nodes first
	if gs.utilities_component:
		for pos in gs.utilities_component.utility_objects:
			var util = gs.utilities_component.utility_objects[pos]
			if is_instance_valid(util) and (util.name.to_lower().contains("teleport") or util.name.to_lower().contains("portal")):
				return pos
	# Fallback: read from raw map data utilities layer (t: entries)
	if gs.data_component:
		var teleporter_from_data = _find_teleporter_from_map_data(gs)
		if teleporter_from_data != Vector3i(-1, -1, -1):
			return teleporter_from_data
	return Vector3i(-1, -1, -1)

## Read teleporter position from raw map data utilities layer (t: or t entries)
func _find_teleporter_from_map_data(gs: GridSystem) -> Vector3i:
	if not gs.data_component:
		return Vector3i(-1, -1, -1)
	var utility_data = gs.data_component.get_utility_data()
	if not utility_data or not utility_data.layout_data:
		return Vector3i(-1, -1, -1)
	var layout: Array = utility_data.layout_data
	for z in range(layout.size()):
		var row = layout[z]
		if not row is Array:
			continue
		for x in range(row.size()):
			var cell = str(row[x]).strip_edges()
			if cell == "t" or cell.begins_with("t:"):
				return Vector3i(x, 0, z)
	return Vector3i(-1, -1, -1)

func _get_artifact_positions(gs: GridSystem) -> Array:
	# Try scene nodes first (most accurate if available)
	if gs.interactables_component and gs.interactables_component.interactable_objects.size() > 0:
		return gs.interactables_component.interactable_objects.keys()
	# Fallback: read interactable positions from map data layer directly
	return _get_artifact_positions_from_map_data(gs)

## Read artifact positions and names from the raw map data interactables layer.
## Returns Array of Vector3i positions. Also populates _artifact_name_cache.
var _artifact_name_cache: Dictionary = {}  # Vector3i -> String

func _get_artifact_positions_from_map_data(gs: GridSystem) -> Array:
	_artifact_name_cache.clear()
	if not gs.data_component:
		return []
	var interactable_data = gs.data_component.get_interactable_data()
	if not interactable_data or not interactable_data.interactable_data:
		return []
	var layout: Array = interactable_data.interactable_data
	var sc = gs.structure_component
	var positions: Array = []
	for z in range(layout.size()):
		var row = layout[z]
		if not row is Array:
			continue
		for x in range(row.size()):
			var token = str(row[x]).strip_edges()
			if token == " " or token.is_empty():
				continue
			# Parse lookup name (strip parameters after colon)
			var lookup_name = token.split(":")[0].split("#")[0]
			var y = 1
			if sc:
				y = sc.find_highest_y_at(x, z)
			var pos = Vector3i(x, y, z)
			positions.append(pos)
			_artifact_name_cache[pos] = lookup_name
	return positions

func _check_line_of_sight(gs: GridSystem, from: Vector3i, to: Vector3i, dims: Vector3i) -> bool:
	# Bresenham-style line walk on XZ plane checking wall heights
	var sc = gs.structure_component
	if not sc:
		return true  # No structure = everything visible
	var x0 = from.x; var z0 = from.z
	var x1 = to.x; var z1 = to.z
	var dx = absi(x1 - x0)
	var dz = absi(z1 - z0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if z0 < z1 else -1
	var err = dx - dz
	var eye_height = 2  # Check if walls are taller than eye level

	while true:
		if x0 == x1 and z0 == z1:
			break
		# Check if current cell has a wall blocking sight
		if x0 != from.x or z0 != from.z:  # Don't check start cell
			if x0 != to.x or z0 != to.z:  # Don't check end cell
				var height = sc.find_highest_y_at(x0, z0)
				if height >= eye_height:
					return false  # Wall blocks line of sight
		var e2 = 2 * err
		if e2 > -dz:
			err -= dz
			x0 += sx
		if e2 < dx:
			err += dx
			z0 += sy
	return true

func _grid_distance(from: Vector3i, to: Vector3i) -> float:
	var dx = to.x - from.x
	var dz = to.z - from.z
	return sqrt(float(dx * dx + dz * dz))

func _cardinal_direction(from: Vector3i, to: Vector3i) -> String:
	var dx = to.x - from.x
	var dz = to.z - from.z
	if dx == 0 and dz == 0:
		return "here"
	# In Godot grid: +X = east, +Z = south (map renders with Z increasing downward)
	var angle = atan2(float(dx), float(-dz))  # -Z = north (0 rad)
	var deg = rad_to_deg(angle)
	if deg < 0:
		deg += 360.0
	# 8 compass directions
	if deg < 22.5 or deg >= 337.5: return "north"
	if deg < 67.5: return "northeast"
	if deg < 112.5: return "east"
	if deg < 157.5: return "southeast"
	if deg < 202.5: return "south"
	if deg < 247.5: return "southwest"
	if deg < 292.5: return "west"
	return "northwest"

func _find_junctions(gs: GridSystem, dims: Vector3i) -> Array:
	# Junctions = walkable tiles with 3+ walkable neighbors
	var junctions: Array = []
	var sc = gs.structure_component
	if not sc:
		return junctions
	for x in range(dims.x):
		for z in range(dims.z):
			var h = sc.find_highest_y_at(x, z)
			if h != 1:  # Not a floor tile
				continue
			var neighbors = 0
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx = x + dir.x
				var nz = z + dir.y
				if nx >= 0 and nx < dims.x and nz >= 0 and nz < dims.z:
					if sc.find_highest_y_at(nx, nz) == 1:
						neighbors += 1
			if neighbors >= 3:
				junctions.append(Vector3i(x, 0, z))
	# Limit to most important junctions (max 5)
	if junctions.size() > 5:
		junctions.resize(5)
	return junctions

func _detect_rooms(gs: GridSystem, dims: Vector3i) -> Array:
	# Flood-fill to find connected regions of walkable tiles
	var sc = gs.structure_component
	if not sc:
		return []
	var visited: Dictionary = {}
	var rooms: Array = []

	for x in range(dims.x):
		for z in range(dims.z):
			var pos = Vector3i(x, 0, z)
			if visited.has(pos):
				continue
			var h = sc.find_highest_y_at(x, z)
			if h != 1:  # Not floor
				visited[pos] = true
				continue
			# Flood-fill from this tile
			var room: Array = []
			var queue: Array = [pos]
			while queue.size() > 0:
				var current = queue.pop_front()
				if visited.has(current):
					continue
				visited[current] = true
				var ch = sc.find_highest_y_at(current.x, current.z)
				if ch != 1:
					continue
				room.append(current)
				# Check 4 neighbors
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var next = Vector3i(current.x + dir.x, 0, current.z + dir.y)
					if next.x >= 0 and next.x < dims.x and next.z >= 0 and next.z < dims.z:
						if not visited.has(next):
							queue.append(next)
			if room.size() >= 2:  # Ignore single-tile "rooms"
				rooms.append(room)
	return rooms

func _describe_region(tiles: Array, dims: Vector3i) -> String:
	if tiles.is_empty():
		return "empty"
	var avg_x = 0.0
	var avg_z = 0.0
	for t in tiles:
		avg_x += t.x
		avg_z += t.z
	avg_x /= tiles.size()
	avg_z /= tiles.size()
	var mid_x = dims.x / 2.0
	var mid_z = dims.z / 2.0
	var parts: PackedStringArray = []
	if avg_z < mid_z * 0.7: parts.append("north")
	elif avg_z > mid_z * 1.3: parts.append("south")
	if avg_x < mid_x * 0.7: parts.append("west")
	elif avg_x > mid_x * 1.3: parts.append("east")
	if parts.is_empty(): parts.append("center")
	return ", ".join(parts)

func _room_letter(index: int) -> String:
	return char(65 + index)  # A, B, C...

func _artifacts_in_region(artifact_positions: Array, room_tiles: Array, gs: GridSystem) -> PackedStringArray:
	var names: PackedStringArray = []
	var room_set: Dictionary = {}
	for t in room_tiles:
		room_set[Vector3i(t.x, 0, t.z)] = true
	for apos in artifact_positions:
		var flat = Vector3i(apos.x, 0, apos.z)
		if room_set.has(flat):
			names.append(_get_artifact_name_at(gs, apos))
	return names

func _compute_height_stats(gs: GridSystem, dims: Vector3i) -> Dictionary:
	var sc = gs.structure_component
	var ground = 0; var walls = 0; var boundary = 0; var void_count = 0
	var total = dims.x * dims.z
	if not sc:
		return {"ground": 0, "ground_pct": 0.0, "walls": 0, "boundary": 0, "void": total}
	for x in range(dims.x):
		for z in range(dims.z):
			var h = sc.find_highest_y_at(x, z)
			if h == 0: void_count += 1
			elif h == 1: ground += 1
			elif h <= 5: walls += 1
			else: boundary += 1
	var pct = (float(ground) / float(maxi(total, 1))) * 100.0
	return {"ground": ground, "ground_pct": pct, "walls": walls, "boundary": boundary, "void": void_count}

func _visible_artifacts_from(gs: GridSystem, pos: Vector3i, artifact_positions: Array, dims: Vector3i) -> PackedStringArray:
	var visible: PackedStringArray = []
	for apos in artifact_positions:
		if _check_line_of_sight(gs, pos, apos, dims):
			visible.append(_get_artifact_name_at(gs, apos))
	return visible

# ============================================================
# LENS 4: EXPERIENTIAL WALK-THROUGH
# ============================================================

## Returns structured first-person walkthrough data.
## Walks from spawn through artifacts in nearest-neighbor order,
## recording what's visible at each stop — like a player touring the map.
func get_walkthrough_data() -> Dictionary:
	var gs = _get_grid_system()
	if not gs:
		return {}
	var info = gs.get_current_map_info()
	var dims = gs.get_grid_dimensions()
	var spawn_pos = _find_spawn_position(gs)
	var artifact_positions = _get_artifact_positions(gs)
	var teleporter_pos = _find_teleporter_position(gs)

	if spawn_pos == Vector3i(-1, -1, -1):
		return {"map_name": info.get("name", "Unknown"), "stops": [], "summary": {"total_stops": 0, "total_steps": 0, "artifacts_visited": 0}}

	var walkable = _get_walkable_tiles(gs, dims)
	var spawn_flat = Vector3i(spawn_pos.x, 0, spawn_pos.z)
	if not walkable.has(spawn_flat):
		walkable[spawn_flat] = true
	var bfs_result = _bfs_from(spawn_flat, walkable, dims)
	var distances = bfs_result.distances

	# Order artifacts by nearest-neighbor from spawn (greedy walk)
	var ordered = _order_by_nearest_neighbor(spawn_flat, artifact_positions, distances, gs, dims)

	var stops: Array = []
	var total_steps: int = 0
	var current_pos = spawn_flat

	# Stop 0: Spawn
	var first_look_at = ordered[0].pos if ordered.size() > 0 else teleporter_pos
	var spawn_facing = _cardinal_direction(spawn_flat, first_look_at) if first_look_at != Vector3i(-1, -1, -1) else "south"
	var spawn_visible = _visible_artifact_details(gs, spawn_flat, artifact_positions, dims, distances)

	stops.append({
		"type": "spawn",
		"pos": [spawn_pos.x, spawn_pos.y, spawn_pos.z],
		"facing": spawn_facing,
		"look_at": [first_look_at.x, first_look_at.y, first_look_at.z] if first_look_at != Vector3i(-1, -1, -1) else null,
		"visible": spawn_visible,
		"total_steps": 0,
	})

	# Walk to each artifact in nearest-neighbor order
	for entry in ordered:
		var apos = entry.pos
		var apos_flat = Vector3i(apos.x, 0, apos.z)
		var step_dist = entry.dist_from_prev

		# Skip artifacts sitting on the spawn tile (already noted in spawn stop)
		if step_dist == 0 and apos_flat == spawn_flat:
			continue

		total_steps += step_dist

		var approach_dir = _cardinal_direction(current_pos, apos_flat)
		var visible_here = _visible_artifact_details(gs, apos_flat, artifact_positions, dims, distances)
		# Remove self from visible list
		var name_str = _get_artifact_name_at(gs, apos)
		var others: Array = []
		for v in visible_here:
			if v.name != name_str:
				others.append(v)

		# Determine what to look at next
		var next_look = null
		for i in range(ordered.size()):
			if ordered[i].pos == apos:
				if i + 1 < ordered.size():
					next_look = ordered[i + 1].pos
				break
		if next_look == null and teleporter_pos != Vector3i(-1, -1, -1):
			next_look = teleporter_pos

		var facing = _cardinal_direction(apos_flat, next_look) if next_look != null and next_look != Vector3i(-1, -1, -1) else approach_dir

		stops.append({
			"type": "artifact",
			"pos": [apos.x, apos.y, apos.z],
			"name": name_str,
			"approach_from": approach_dir,
			"facing": facing,
			"steps_from_prev": step_dist,
			"total_steps": total_steps,
			"visible_others": others,
		})
		current_pos = apos_flat

	# Final stop: teleporter
	if teleporter_pos != Vector3i(-1, -1, -1):
		var tp_flat = Vector3i(teleporter_pos.x, 0, teleporter_pos.z)
		var tp_dist = distances.get(tp_flat, -1)
		if tp_dist < 0:
			for adj in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var neighbor = Vector3i(tp_flat.x + adj.x, 0, tp_flat.z + adj.y)
				var nd = distances.get(neighbor, -1)
				if nd >= 0 and (tp_dist < 0 or nd + 1 < tp_dist):
					tp_dist = nd + 1

		var steps_to_tp = maxi(0, tp_dist - (distances.get(current_pos, 0)))
		if steps_to_tp < 0:
			steps_to_tp = absi(tp_flat.x - current_pos.x) + absi(tp_flat.z - current_pos.z)
		total_steps += steps_to_tp

		stops.append({
			"type": "teleporter",
			"pos": [teleporter_pos.x, teleporter_pos.y, teleporter_pos.z],
			"approach_from": _cardinal_direction(current_pos, tp_flat),
			"steps_from_prev": steps_to_tp,
			"total_steps": total_steps,
			"reachable": tp_dist >= 0,
		})

	return {
		"map_name": info.get("name", "Unknown"),
		"stops": stops,
		"summary": {
			"total_stops": stops.size(),
			"total_steps": total_steps,
			"artifacts_visited": ordered.size(),
		},
	}

## Build first-person walkthrough narrative markdown
func build_walkthrough_narrative(gs_override: GridSystem = null) -> String:
	var gs = gs_override if gs_override else _get_grid_system()
	if not gs:
		return "No GridSystem found.\n"

	var data = get_walkthrough_data()
	if data.is_empty() or data.get("stops", []).size() == 0:
		return "No walkthrough data — no spawn point found.\n"

	var info = gs.get_current_map_info()
	var lines: PackedStringArray = []
	lines.append("# Walk-Through Experience — %s" % data.get("map_name", "Unknown"))
	lines.append("Generated: %s\n" % Time.get_datetime_string_from_system())

	var step = 1
	for stop in data.stops:
		match stop.type:
			"spawn":
				lines.append("%d. **Spawn** at (%d,%d,%d) — facing %s" % [
					step, stop.pos[0], stop.pos[1], stop.pos[2], stop.facing])
				if stop.visible.size() > 0:
					var vis_parts: PackedStringArray = []
					for v in stop.visible:
						vis_parts.append("%s (%d steps %s)" % [v.name, v.dist, v.direction])
					lines.append("   I can see: %s" % ", ".join(vis_parts))
				else:
					lines.append("   Nothing visible from here")

			"artifact":
				lines.append("%d. **Walk %d steps %s** → %s at (%d,%d,%d)" % [
					step, stop.steps_from_prev, stop.approach_from,
					stop.name, stop.pos[0], stop.pos[1], stop.pos[2]])
				if stop.visible_others.size() > 0:
					var vis_parts: PackedStringArray = []
					for v in stop.visible_others:
						vis_parts.append("%s (%d steps %s)" % [v.name, v.dist, v.direction])
					lines.append("   Looking around: %s" % ", ".join(vis_parts))
				else:
					lines.append("   Nothing else visible from here")

			"teleporter":
				if stop.reachable:
					lines.append("%d. **Walk %d steps %s** → Teleporter at (%d,%d,%d)" % [
						step, stop.steps_from_prev, stop.approach_from,
						stop.pos[0], stop.pos[1], stop.pos[2]])
				else:
					lines.append("%d. **Teleporter** at (%d,%d,%d) — UNREACHABLE" % [
						step, stop.pos[0], stop.pos[1], stop.pos[2]])

		lines.append("")
		step += 1

	var summary = data.get("summary", {})
	lines.append("---")
	lines.append("Journey complete: %d total steps, %d artifacts encountered, %d stops" % [
		summary.get("total_steps", 0),
		summary.get("artifacts_visited", 0),
		summary.get("total_stops", 0)])
	lines.append("")

	return "\n".join(lines)

## Order artifact positions by nearest-neighbor walk from start
func _order_by_nearest_neighbor(start: Vector3i, artifact_positions: Array, distances: Dictionary, gs: GridSystem, dims: Vector3i) -> Array:
	var ordered: Array = []
	var remaining: Array = artifact_positions.duplicate()
	var current_pos = start

	while remaining.size() > 0:
		var nearest_idx: int = -1
		var nearest_dist: float = INF

		for i in range(remaining.size()):
			var apos = remaining[i]
			var apos_flat = Vector3i(apos.x, 0, apos.z)
			# Use Manhattan distance as approximation for nearest-neighbor
			var d = absi(apos_flat.x - current_pos.x) + absi(apos_flat.z - current_pos.z)
			if d < nearest_dist:
				nearest_dist = d
				nearest_idx = i

		if nearest_idx < 0:
			break

		var apos = remaining[nearest_idx]
		var apos_flat = Vector3i(apos.x, 0, apos.z)
		var bfs_dist = distances.get(apos_flat, -1)
		if bfs_dist < 0:
			# Unreachable artifact — skip
			remaining.remove_at(nearest_idx)
			continue

		ordered.append({
			"pos": apos,
			"name": _get_artifact_name_at(gs, apos),
			"dist_from_spawn": bfs_dist,
			"dist_from_prev": int(nearest_dist),
		})
		current_pos = apos_flat
		remaining.remove_at(nearest_idx)

	return ordered

## Get visible artifact details from a position (name, distance, direction)
## Distance is Manhattan distance from the current position, not BFS from spawn.
func _visible_artifact_details(gs: GridSystem, from: Vector3i, artifact_positions: Array, dims: Vector3i, _distances: Dictionary) -> Array:
	var result: Array = []
	for apos in artifact_positions:
		var apos_flat = Vector3i(apos.x, 0, apos.z)
		if apos_flat == from:
			continue
		if _check_line_of_sight(gs, from, apos_flat, dims):
			# Use Manhattan distance from current position
			var dist = absi(apos_flat.x - from.x) + absi(apos_flat.z - from.z)
			var direction = _cardinal_direction(from, apos_flat)
			result.append({
				"name": _get_artifact_name_at(gs, apos),
				"dist": dist,
				"direction": direction,
			})
	# Sort by distance
	result.sort_custom(func(a, b): return a.dist < b.dist)
	return result

# ============================================================
# BFS / PATHFINDING
# ============================================================

func _get_walkable_tiles(gs: GridSystem, dims: Vector3i) -> Dictionary:
	var walkable: Dictionary = {}
	var sc = gs.structure_component
	if not sc:
		return walkable
	for x in range(dims.x):
		for z in range(dims.z):
			var h = sc.find_highest_y_at(x, z)
			if h == 1:  # Floor tile
				walkable[Vector3i(x, 0, z)] = true
	return walkable

func _bfs_from(start: Vector3i, walkable: Dictionary, dims: Vector3i) -> Dictionary:
	var start_flat = Vector3i(start.x, 0, start.z)
	var distances: Dictionary = {}
	var parents: Dictionary = {}
	var queue: Array = [start_flat]
	distances[start_flat] = 0
	parents[start_flat] = start_flat

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_dist = distances[current]
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next = Vector3i(current.x + dir.x, 0, current.z + dir.y)
			if walkable.has(next) and not distances.has(next):
				distances[next] = current_dist + 1
				parents[next] = current
				queue.append(next)

	return {"distances": distances, "parents": parents}

func _find_dead_ends(walkable: Dictionary, dims: Vector3i) -> Array:
	var dead_ends: Array = []
	for pos in walkable:
		var neighbors = 0
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next = Vector3i(pos.x + dir.x, 0, pos.z + dir.y)
			if walkable.has(next):
				neighbors += 1
		if neighbors == 1:
			dead_ends.append(pos)
	return dead_ends

# ============================================================
# EVENT STREAM
# ============================================================

func _process(_delta: float) -> void:
	if not _event_stream_active:
		return
	# Track player grid cell changes
	var player = GameManager.get_player() if GameManager else null
	if player and is_instance_valid(player):
		var pos = player.global_position
		var cell = Vector3i(floori(pos.x), floori(pos.y), floori(pos.z))
		if cell != _last_player_cell:
			_log_event({
				"event": "player_moved",
				"from": [_last_player_cell.x, _last_player_cell.y, _last_player_cell.z],
				"to": [cell.x, cell.y, cell.z],
			})
			_last_player_cell = cell

func _log_event(data: Dictionary) -> void:
	data["t"] = _timestamp()
	var line = JSON.stringify(data) + "\n"
	_append_file(EVENTS_PATH, line)

# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _connect_game_manager() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		push_warning("SceneNarrator: GameManager not found")
		return
	if gm.has_signal("current_map_changed"):
		gm.current_map_changed.connect(_on_map_changed)
	if gm.has_signal("player_damaged"):
		gm.player_damaged.connect(_on_player_damaged)

func _on_map_changed(new_map_name: String) -> void:
	print("SceneNarrator: Map changed to %s" % new_map_name)
	_try_connect_grid_system()
	if _event_stream_active:
		_log_event({"event": "map_changed", "map": new_map_name})

func _on_player_damaged(amount: float, new_health: float) -> void:
	if _event_stream_active:
		_log_event({"event": "player_damaged", "amount": amount, "health": new_health})

func _on_grid_generation_complete() -> void:
	var gs = _get_grid_system()
	if _event_stream_active and gs:
		var info = gs.get_current_map_info()
		_log_event({"event": "map_loaded", "map": info.get("name", "?"),
					"artifacts": info.get("objects", {}).get("interactables", 0)})
	if auto_narrate_on_map_load:
		# Artifacts are already placed by the time grid_generation_complete fires
		# Just narrate directly
		narrate_full()

func _on_interactable_activated(object_id, position, data) -> void:
	if _event_stream_active:
		_log_event({"event": "artifact_interacted",
					"id": str(object_id), "position": str(position)})

# ============================================================
# GRID SYSTEM CONNECTION
# ============================================================

func _try_connect_grid_system() -> void:
	# Disconnect old
	if _grid_system and is_instance_valid(_grid_system):
		if _grid_system.map_generation_complete.is_connected(_on_grid_generation_complete):
			_grid_system.map_generation_complete.disconnect(_on_grid_generation_complete)
		if _grid_system.interactable_activated.is_connected(_on_interactable_activated):
			_grid_system.interactable_activated.disconnect(_on_interactable_activated)

	_grid_system = null
	var nodes = get_tree().get_nodes_in_group("grid_system")
	if nodes.size() > 0:
		_grid_system = nodes[0] as GridSystem
		_grid_system.map_generation_complete.connect(_on_grid_generation_complete)
		_grid_system.interactable_activated.connect(_on_interactable_activated)
		print("SceneNarrator: Connected to GridSystem (%s)" % _grid_system.map_name)

func _get_grid_system() -> GridSystem:
	if _grid_system and is_instance_valid(_grid_system):
		return _grid_system
	_try_connect_grid_system()
	return _grid_system

# ============================================================
# FILE I/O
# ============================================================

func _ensure_output_dir() -> void:
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("ada_run"):
		dir.make_dir("ada_run")

func _write_file(path: String, content: String) -> void:
	var actual_path = _resolve_path(path)
	var file = FileAccess.open(actual_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	else:
		push_error("SceneNarrator: Failed to write %s (error: %s)" % [actual_path, FileAccess.get_open_error()])

func _append_file(path: String, content: String) -> void:
	var actual_path = _resolve_path(path)
	var file: FileAccess
	if FileAccess.file_exists(actual_path):
		file = FileAccess.open(actual_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:
		file = FileAccess.open(actual_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

func _resolve_path(path: String) -> String:
	# Try res:// first, fall back to user:// if not writable
	if path.begins_with("res://"):
		var test = FileAccess.open(path, FileAccess.WRITE)
		if test:
			test.close()
			return path
		# Fall back to user:// and ensure directory exists
		var user_path = path.replace("res://", "user://")
		var dir_path = user_path.get_base_dir()
		DirAccess.make_dir_recursive_absolute(dir_path)
		return user_path
	return path

func _timestamp() -> String:
	return Time.get_time_string_from_system()
