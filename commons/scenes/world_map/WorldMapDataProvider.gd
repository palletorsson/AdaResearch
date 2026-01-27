# WorldMapDataProvider.gd
# Aggregates sequence data from fractal_index and MapProgressionManager
# Provides data for subway map visualization with progressive reveal

class_name WorldMapDataProvider
extends RefCounted

# Metro line colors for QFEP layers
const LINE_COLORS := {
	"primitives": Color(0.75, 0.75, 0.75),    # Silver
	"properties": Color(0.12, 0.56, 1.0),     # Dodger Blue
	"behaviors": Color(1.0, 0.84, 0.0),       # Gold
	"emergence": Color(1.0, 0.27, 0.0),       # Orange Red
	"systems": Color(0.58, 0.44, 0.86),       # Medium Purple
	"integration": Color(1.0, 0.41, 0.71)     # Hot Pink
}

# QFEP layer order for layout
const LAYER_ORDER := ["primitives", "properties", "behaviors", "emergence", "systems", "integration"]

# Station states
enum StationState { COMPLETED, UNLOCKED, LOCKED, HIDDEN }

# Cached data
static var _fractal_index: Dictionary = {}
static var _sequences_cache: Dictionary = {}
static var _layout_cache: Dictionary = {}

# Load fractal index for layer organization
static func _ensure_fractal_index() -> void:
	if not _fractal_index.is_empty():
		return

	var file = FileAccess.open("res://commons/maps/fractal_index.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_fractal_index = json.data
		file.close()

# Get layer info for a QFEP layer
static func get_layer_info(layer_name: String) -> Dictionary:
	_ensure_fractal_index()

	var layers = _fractal_index.get("layers", {})
	if not layers.has(layer_name):
		return {}

	var layer = layers[layer_name]
	return {
		"name": layer_name,
		"qfep_term": layer.get("qfep_term", ""),
		"description": layer.get("description", ""),
		"color": LINE_COLORS.get(layer_name, Color.WHITE),
		"sequences": layer.get("sequences", [])
	}

# Get all sequences organized by layer
static func get_all_sequences() -> Array[Dictionary]:
	_ensure_fractal_index()

	var result: Array[Dictionary] = []
	var layers = _fractal_index.get("layers", {})

	for layer_name in LAYER_ORDER:
		if not layers.has(layer_name):
			continue

		var layer = layers[layer_name]
		var layer_sequences = layer.get("sequences", [])

		for seq_name in layer_sequences:
			var seq_data = _get_sequence_data(seq_name)
			seq_data["layer"] = layer_name
			seq_data["color"] = LINE_COLORS.get(layer_name, Color.WHITE)
			result.append(seq_data)

	return result

# Get sequence data from MapProgressionManager
static func _get_sequence_data(sequence_name: String) -> Dictionary:
	var data := {
		"name": sequence_name,
		"display_name": sequence_name.capitalize().replace("_", " "),
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

	# Get prerequisites from cross_references
	_ensure_fractal_index()
	var cross_refs = _fractal_index.get("cross_references", {})
	if cross_refs.has(sequence_name):
		data["prerequisites"] = cross_refs[sequence_name].get("requires", [])
		data["unlocks"] = cross_refs[sequence_name].get("enables", [])

	return data

# Get visible sequences based on progressive reveal logic
static func get_visible_sequences() -> Array[Dictionary]:
	var all_sequences = get_all_sequences()
	var visible: Array[Dictionary] = []

	for seq in all_sequences:
		var visibility = _calculate_visibility(seq)
		if visibility != StationState.HIDDEN:
			seq["state"] = visibility
			visible.append(seq)

	return visible

# Calculate visibility state for a sequence
static func _calculate_visibility(seq: Dictionary) -> StationState:
	# Completed sequences are always visible
	if seq.get("is_completed", false):
		return StationState.COMPLETED

	# Unlocked sequences are visible
	if seq.get("is_unlocked", false):
		return StationState.UNLOCKED

	# Check if any prerequisite is completed (adjacent reveal)
	var prereqs = seq.get("prerequisites", [])
	for prereq in prereqs:
		if _is_sequence_completed(prereq):
			return StationState.LOCKED  # Visible but locked

	# Primitives layer is always visible (starting point)
	if seq.get("layer", "") == "primitives":
		return StationState.LOCKED

	# Otherwise hidden
	return StationState.HIDDEN

# Helper to check if a sequence is completed
static func _is_sequence_completed(sequence_name: String) -> bool:
	if MapProgressionManager:
		return MapProgressionManager.is_sequence_completed(sequence_name)
	return false

# Calculate subway-style layout positions for sequences
static func calculate_subway_layout(canvas_size: Vector2) -> Dictionary:
	var layout: Dictionary = {}
	var sequences = get_all_sequences()

	# Layout parameters
	var margin := 60.0
	var usable_width := canvas_size.x - margin * 2
	var usable_height := canvas_size.y - margin * 2

	# Calculate positions per layer (horizontal metro lines)
	var layer_height := usable_height / float(LAYER_ORDER.size())

	for seq in sequences:
		var layer_name: String = seq.get("layer", "primitives")
		var layer_idx := LAYER_ORDER.find(layer_name)
		if layer_idx < 0:
			layer_idx = 0

		# Y position based on layer
		var y := margin + layer_height * (layer_idx + 0.5)

		# X position based on sequence order within layer
		var layer_sequences := _get_layer_sequences(layer_name)
		var seq_idx := layer_sequences.find(seq.get("name", ""))
		var seq_count := layer_sequences.size()

		var x: float
		if seq_count <= 1:
			x = canvas_size.x / 2.0
		else:
			x = margin + (usable_width / float(seq_count - 1)) * seq_idx

		layout[seq.get("name", "")] = Vector2(x, y)

	_layout_cache = layout
	return layout

# Get sequences for a specific layer
static func _get_layer_sequences(layer_name: String) -> Array:
	_ensure_fractal_index()
	var layers = _fractal_index.get("layers", {})
	if layers.has(layer_name):
		return layers[layer_name].get("sequences", [])
	return []

# Get connections between sequences (for metro lines)
static func get_sequence_connections() -> Array[Dictionary]:
	_ensure_fractal_index()
	var connections: Array[Dictionary] = []

	var cross_refs = _fractal_index.get("cross_references", {})

	for seq_name in cross_refs.keys():
		var refs = cross_refs[seq_name]
		var enables = refs.get("enables", [])

		for target in enables:
			connections.append({
				"from": seq_name,
				"to": target,
				"visible": _is_connection_visible(seq_name, target)
			})

	return connections

# Check if a connection should be visible
static func _is_connection_visible(from_seq: String, to_seq: String) -> bool:
	# Connection visible if source is completed or both are at least locked
	if _is_sequence_completed(from_seq):
		return true

	var from_data = _get_sequence_data(from_seq)
	var to_data = _get_sequence_data(to_seq)

	var from_vis = _calculate_visibility(from_data)
	var to_vis = _calculate_visibility(to_data)

	return from_vis != StationState.HIDDEN and to_vis != StationState.HIDDEN

# Get current player position (current sequence)
static func get_current_sequence() -> String:
	if MapProgressionManager:
		var current_map = MapProgressionManager.current_map
		# Find which sequence contains this map
		var sequences = MapProgressionManager.sequences
		for seq_name in sequences.keys():
			var seq = sequences[seq_name]
			if seq.has("maps") and current_map in seq.get("maps", []):
				return seq_name
	return ""

# Get total progress statistics
static func get_progress_stats() -> Dictionary:
	var all_seqs = get_all_sequences()
	var completed := 0
	var unlocked := 0
	var total := all_seqs.size()

	for seq in all_seqs:
		if seq.get("is_completed", false):
			completed += 1
		elif seq.get("is_unlocked", false):
			unlocked += 1

	return {
		"total_sequences": total,
		"completed": completed,
		"unlocked": unlocked,
		"locked": total - completed - unlocked,
		"completion_percentage": (float(completed) / float(total) * 100.0) if total > 0 else 0.0
	}
