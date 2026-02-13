# WorldMapDataProvider.gd
# Aggregates sequence data from curriculum_spine.json and MapProgressionManager
# Provides data for subway map visualization with QFEP-guided progressive reveal

class_name WorldMapDataProvider
extends RefCounted

# QFEP Phase colors (from curriculum_spine.json)
const PHASE_COLORS := {
	"F_order": Color("#4A90D9"),       # Blue - order, prediction
	"oscillation": Color("#9B59B6"),   # Purple - F↔E balance
	"E_entropy": Color("#E74C3C"),     # Red - entropy, disorder
	"lambda_edge": Color("#F39C12"),   # Orange - edge of chaos
	"integration": Color("#2ECC71"),   # Green - φΔE emergence
	"synthesis": Color("#E91E63")      # Pink - full QFEP
}

# QFEP phase order (matches spine progression)
const PHASE_ORDER := ["F_order", "oscillation", "E_entropy", "lambda_edge", "integration", "synthesis"]

# Station states
enum StationState { COMPLETED, UNLOCKED, LOCKED, HIDDEN }

# Sequence types
enum SequenceType { SPINE, BRANCH }

# Cached data
static var _spine_data: Dictionary = {}
static var _fractal_index: Dictionary = {}  # Keep for map details
static var _sequences_cache: Dictionary = {}
static var _layout_cache: Dictionary = {}

#region Data Loading

# Load curriculum spine (primary source of truth for flow)
static func _ensure_spine_loaded() -> void:
	if not _spine_data.is_empty():
		return
	
	var file = FileAccess.open("res://commons/maps/curriculum_spine.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_spine_data = json.data
		file.close()
	else:
		push_warning("WorldMapDataProvider: Could not load curriculum_spine.json")

# Load fractal index for additional sequence details
static func _ensure_fractal_index() -> void:
	if not _fractal_index.is_empty():
		return
	
	var file = FileAccess.open("res://commons/maps/fractal_index.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_fractal_index = json.data
		file.close()

#endregion

#region Spine Access

# Get the ordered spine sequences (the recommended path)
static func get_spine_sequences() -> Array[Dictionary]:
	_ensure_spine_loaded()
	
	var result: Array[Dictionary] = []
	var spine = _spine_data.get("spine", {})
	var sequences = spine.get("sequences", [])
	
	for seq in sequences:
		var seq_data = _build_sequence_data(seq.get("name", ""), SequenceType.SPINE)
		seq_data["spine_order"] = seq.get("order", 0)
		seq_data["phase"] = seq.get("phase", "F_order")
		seq_data["qfep_role"] = seq.get("qfep_role", "")
		seq_data["lab_post"] = seq.get("lab_post", "")
		seq_data["color"] = PHASE_COLORS.get(seq.get("phase", "F_order"), Color.WHITE)
		result.append(seq_data)
	
	return result

# Get spine sequence names in order
static func get_spine_order() -> Array[String]:
	_ensure_spine_loaded()
	
	var result: Array[String] = []
	var spine = _spine_data.get("spine", {})
	var sequences = spine.get("sequences", [])
	
	for seq in sequences:
		result.append(seq.get("name", ""))
	
	return result

# Check if a sequence is on the spine
static func is_spine_sequence(sequence_name: String) -> bool:
	return sequence_name in get_spine_order()

# Get the next recommended spine sequence
static func get_next_spine_sequence() -> String:
	var spine_order = get_spine_order()
	
	for seq_name in spine_order:
		if not _is_sequence_completed(seq_name):
			return seq_name
	
	return ""  # All spine completed

# Get spine position (1-based order, 0 if not on spine)
static func get_spine_position(sequence_name: String) -> int:
	var spine_order = get_spine_order()
	var idx = spine_order.find(sequence_name)
	return idx + 1 if idx >= 0 else 0

#endregion

#region Branch Access

# Get all branch sequences (optional content)
static func get_branch_sequences() -> Array[Dictionary]:
	_ensure_spine_loaded()
	
	var result: Array[Dictionary] = []
	var branches = _spine_data.get("branches", {})
	var branch_points = branches.get("branch_points", {})
	
	# Collect all unique branch sequences
	var branch_names: Array[String] = []
	for spine_seq in branch_points.keys():
		var unlocks = branch_points[spine_seq].get("unlocks", [])
		for branch_name in unlocks:
			if branch_name not in branch_names:
				branch_names.append(branch_name)
	
	for branch_name in branch_names:
		var seq_data = _build_sequence_data(branch_name, SequenceType.BRANCH)
		seq_data["parent_spine"] = _get_branch_parent(branch_name)
		# Branches inherit parent's phase color (slightly desaturated)
		var parent_phase = _get_sequence_phase(seq_data["parent_spine"])
		var base_color = PHASE_COLORS.get(parent_phase, Color.WHITE)
		seq_data["color"] = base_color.lerp(Color.WHITE, 0.3)
		result.append(seq_data)
	
	return result

# Get branches that unlock from a specific spine sequence
static func get_branches_from(spine_sequence: String) -> Array[String]:
	_ensure_spine_loaded()
	
	var branches = _spine_data.get("branches", {})
	var branch_points = branches.get("branch_points", {})
	
	if branch_points.has(spine_sequence):
		var unlocks = branch_points[spine_sequence].get("unlocks", [])
		var result: Array[String] = []
		for u in unlocks:
			result.append(u)
		return result
	
	return []

# Get which spine sequence unlocks a branch
static func _get_branch_parent(branch_name: String) -> String:
	_ensure_spine_loaded()
	
	var branches = _spine_data.get("branches", {})
	var branch_points = branches.get("branch_points", {})
	
	for spine_seq in branch_points.keys():
		var unlocks = branch_points[spine_seq].get("unlocks", [])
		if branch_name in unlocks:
			return spine_seq
	
	return ""

#endregion

#region Phase Info

# Get phase metadata
static func get_phase_info(phase_name: String) -> Dictionary:
	_ensure_spine_loaded()
	
	var phases = _spine_data.get("phases", {})
	if phases.has(phase_name):
		var phase = phases[phase_name]
		return {
			"name": phase.get("name", phase_name),
			"color": PHASE_COLORS.get(phase_name, Color.WHITE),
			"description": phase.get("description", ""),
			"gamwell_chapters": phase.get("gamwell_chapters", "")
		}
	
	return {"name": phase_name, "color": Color.WHITE, "description": "", "gamwell_chapters": ""}

# Get all phases in order
static func get_all_phases() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for phase_name in PHASE_ORDER:
		result.append(get_phase_info(phase_name))
	return result

# Get phase for a sequence
static func _get_sequence_phase(sequence_name: String) -> String:
	_ensure_spine_loaded()
	
	var spine = _spine_data.get("spine", {})
	var sequences = spine.get("sequences", [])
	
	for seq in sequences:
		if seq.get("name", "") == sequence_name:
			return seq.get("phase", "F_order")
	
	# Branch inherits parent's phase
	var parent = _get_branch_parent(sequence_name)
	if parent != "":
		return _get_sequence_phase(parent)
	
	return "F_order"

#endregion

#region All Sequences (Combined)

# Get ALL sequences (spine + branches) with unified data
static func get_all_sequences() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	# Add spine sequences first (in order)
	result.append_array(get_spine_sequences())
	
	# Add branch sequences
	result.append_array(get_branch_sequences())
	
	return result

# Get all sequences with explicit state assignment.
# If reveal_hidden_as_locked is true, hidden items are included as locked.
static func get_all_sequences_with_states(reveal_hidden_as_locked: bool = true) -> Array[Dictionary]:
	var all_sequences = get_all_sequences()
	var with_states: Array[Dictionary] = []

	for seq in all_sequences:
		var state: int = _calculate_visibility(seq)
		if state == StationState.HIDDEN and reveal_hidden_as_locked:
			state = StationState.LOCKED
		seq["state"] = state
		with_states.append(seq)

	return with_states

# Get visible sequences based on progressive reveal logic
static func get_visible_sequences() -> Array[Dictionary]:
	var all_sequences = get_all_sequences_with_states(false)
	var visible: Array[Dictionary] = []
	
	for seq in all_sequences:
		var visibility: int = seq.get("state", StationState.HIDDEN)
		if visibility != StationState.HIDDEN:
			visible.append(seq)
	
	return visible

# Build sequence data from various sources
static func _build_sequence_data(sequence_name: String, type: SequenceType) -> Dictionary:
	var data := {
		"name": sequence_name,
		"display_name": sequence_name.capitalize().replace("_", " "),
		"type": type,
		"is_spine": type == SequenceType.SPINE,
		"maps": [],
		"completion_pct": 0.0,
		"is_completed": false,
		"is_unlocked": false,
		"prerequisites": [],
		"unlocks": []
	}
	
	# Get from MapProgressionManager if available
	if MapProgressionManager:
		var maps = MapProgressionManager.get_sequence_maps(sequence_name)
		data["maps"] = maps
		data["completion_pct"] = MapProgressionManager.get_sequence_completion_percentage(sequence_name)
		data["is_completed"] = MapProgressionManager.is_sequence_completed(sequence_name)
		
		# Check if sequence is unlocked (first map is unlocked)
		if maps.size() > 0:
			data["is_unlocked"] = MapProgressionManager.is_map_unlocked(maps[0])
	
	# Get prerequisites from fractal_index cross_references
	_ensure_fractal_index()
	var cross_refs = _fractal_index.get("cross_references", {})
	if cross_refs.has(sequence_name):
		data["prerequisites"] = cross_refs[sequence_name].get("requires", [])
		data["unlocks"] = cross_refs[sequence_name].get("enables", [])
	
	return data

#endregion

#region Visibility Logic

# Calculate visibility state for a sequence
static func _calculate_visibility(seq: Dictionary) -> StationState:
	# Completed sequences are always visible
	if seq.get("is_completed", false):
		return StationState.COMPLETED
	
	# Unlocked sequences are visible
	if seq.get("is_unlocked", false):
		return StationState.UNLOCKED
	
	var seq_name: String = seq.get("name", "")
	var is_spine: bool = seq.get("is_spine", false)
	
	# Spine sequences: visible if previous spine is completed
	if is_spine:
		var spine_pos = get_spine_position(seq_name)
		if spine_pos == 1:
			return StationState.LOCKED  # First spine always visible
		
		var spine_order = get_spine_order()
		if spine_pos > 1:
			var prev_spine = spine_order[spine_pos - 2]  # -2 because pos is 1-based
			if _is_sequence_completed(prev_spine):
				return StationState.LOCKED
	else:
		# Branch sequences: visible if parent spine is completed
		var parent = _get_branch_parent(seq_name)
		if parent != "" and _is_sequence_completed(parent):
			return StationState.LOCKED
	
	# Check if any prerequisite is completed (adjacent reveal)
	var prereqs = seq.get("prerequisites", [])
	for prereq in prereqs:
		if _is_sequence_completed(prereq):
			return StationState.LOCKED
	
	return StationState.HIDDEN

# Helper to check if a sequence is completed
static func _is_sequence_completed(sequence_name: String) -> bool:
	if MapProgressionManager:
		return MapProgressionManager.is_sequence_completed(sequence_name)
	return false

#endregion

#region Layout

# Calculate subway-style layout positions for sequences
# Spine runs as the main trunk, branches extend outward
static func calculate_subway_layout(canvas_size: Vector2) -> Dictionary:
	var layout: Dictionary = {}
	var margin := 80.0
	var branch_offset := 60.0
	
	var usable_height := canvas_size.y - margin * 2
	var center_x := canvas_size.x / 2.0
	
	# Layout spine as vertical trunk
	var spine_seqs = get_spine_sequences()
	var spine_count = spine_seqs.size()
	
	for i in range(spine_count):
		var seq = spine_seqs[i]
		var seq_name: String = seq.get("name", "")
		
		# Vertical position based on spine order
		var y := margin + (usable_height / float(spine_count - 1)) * i if spine_count > 1 else canvas_size.y / 2.0
		
		# Slight horizontal offset per phase for visual interest
		var phase: String = seq.get("phase", "F_order")
		var phase_idx := PHASE_ORDER.find(phase)
		var phase_offset := (phase_idx - 2.5) * 20.0  # Center around middle phases
		
		layout[seq_name] = Vector2(center_x + phase_offset, y)
		
		# Layout branches extending from this spine point
		var branches = get_branches_from(seq_name)
		var branch_count = branches.size()
		
		for j in range(branch_count):
			var branch_name = branches[j]
			# Alternate left/right, spread vertically
			var side := -1.0 if j % 2 == 0 else 1.0
			var vertical_offset := (j / 2) * 30.0
			
			var branch_x := center_x + phase_offset + (branch_offset + 40.0 * (j / 2 + 1)) * side
			var branch_y := y + vertical_offset
			
			layout[branch_name] = Vector2(branch_x, branch_y)
	
	_layout_cache = layout
	return layout

# Get cached layout
static func get_layout() -> Dictionary:
	return _layout_cache

#endregion

#region Connections

# Get connections between sequences (for metro lines)
static func get_sequence_connections() -> Array[Dictionary]:
	var connections: Array[Dictionary] = []
	
	# Spine connections (thick main line)
	var spine_order = get_spine_order()
	for i in range(spine_order.size() - 1):
		var from_seq = spine_order[i]
		var to_seq = spine_order[i + 1]
		connections.append({
			"from": from_seq,
			"to": to_seq,
			"type": "spine",
			"visible": _is_connection_visible(from_seq, to_seq),
			"color": PHASE_COLORS.get(_get_sequence_phase(to_seq), Color.WHITE)
		})
	
	# Branch connections (dashed offshoots)
	_ensure_spine_loaded()
	var branches = _spine_data.get("branches", {})
	var branch_points = branches.get("branch_points", {})
	
	for spine_seq in branch_points.keys():
		var unlocks = branch_points[spine_seq].get("unlocks", [])
		for branch_name in unlocks:
			var base_color = PHASE_COLORS.get(_get_sequence_phase(spine_seq), Color.WHITE)
			connections.append({
				"from": spine_seq,
				"to": branch_name,
				"type": "branch",
				"visible": _is_connection_visible(spine_seq, branch_name),
				"color": base_color.lerp(Color.WHITE, 0.3)
			})
	
	return connections

# Check if a connection should be visible
static func _is_connection_visible(from_seq: String, to_seq: String) -> bool:
	if _is_sequence_completed(from_seq):
		return true
	
	var from_data = _build_sequence_data(from_seq, SequenceType.SPINE if is_spine_sequence(from_seq) else SequenceType.BRANCH)
	var to_data = _build_sequence_data(to_seq, SequenceType.SPINE if is_spine_sequence(to_seq) else SequenceType.BRANCH)
	
	var from_vis = _calculate_visibility(from_data)
	var to_vis = _calculate_visibility(to_data)
	
	return from_vis != StationState.HIDDEN and to_vis != StationState.HIDDEN

#endregion

#region Player State

# Get current player position (current sequence)
static func get_current_sequence() -> String:
	if MapProgressionManager:
		var current_map = MapProgressionManager.current_map
		var sequences = MapProgressionManager.sequences
		for seq_name in sequences.keys():
			var seq = sequences[seq_name]
			if seq.has("maps") and current_map in seq.get("maps", []):
				return seq_name
	return ""

# Get total progress statistics
static func get_progress_stats() -> Dictionary:
	var spine_seqs = get_spine_sequences()
	var branch_seqs = get_branch_sequences()
	
	var spine_completed := 0
	var branch_completed := 0
	var spine_unlocked := 0
	var branch_unlocked := 0
	
	for seq in spine_seqs:
		if seq.get("is_completed", false):
			spine_completed += 1
		elif seq.get("is_unlocked", false):
			spine_unlocked += 1
	
	for seq in branch_seqs:
		if seq.get("is_completed", false):
			branch_completed += 1
		elif seq.get("is_unlocked", false):
			branch_unlocked += 1
	
	var total_spine := spine_seqs.size()
	var total_branch := branch_seqs.size()
	
	return {
		"total_sequences": total_spine + total_branch,
		"spine_total": total_spine,
		"spine_completed": spine_completed,
		"spine_unlocked": spine_unlocked,
		"branch_total": total_branch,
		"branch_completed": branch_completed,
		"branch_unlocked": branch_unlocked,
		"spine_progress_pct": (float(spine_completed) / float(total_spine) * 100.0) if total_spine > 0 else 0.0,
		"total_progress_pct": (float(spine_completed + branch_completed) / float(total_spine + total_branch) * 100.0) if (total_spine + total_branch) > 0 else 0.0,
		"next_recommended": get_next_spine_sequence()
	}

#endregion

#region Lab Evolution

# Get lab changes for completed spine points
static func get_lab_evolution_state() -> Array[String]:
	_ensure_spine_loaded()
	
	var result: Array[String] = []
	var lab_evolution = _spine_data.get("lab_evolution", {})
	var patterns = lab_evolution.get("patterns", [])
	
	for pattern in patterns:
		var after_seq: String = pattern.get("after", "")
		if _is_sequence_completed(after_seq):
			var changes = pattern.get("changes", [])
			for change in changes:
				if change not in result:
					result.append(change)
	
	return result

# Check if a specific lab feature should be active
static func is_lab_feature_active(feature_name: String) -> bool:
	return feature_name in get_lab_evolution_state()

#endregion
