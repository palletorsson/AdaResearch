# LineageTracker.gd — Family tree tracking across studio + ecosystem
#
# Records every birth, tracks parent-child relationships, and provides
# lineage queries for the Pokemon Studio. Connects to EvolutionSystem
# and PokemonStudio signals to automatically track all births.
#
# Usage:
#   var tracker := LineageTracker.new()
#   tracker.record_birth(child_dna, parent_a_id, parent_b_id)
#   var tree: Dictionary = tracker.get_lineage_tree(specimen_id)

class_name LineageTracker
extends RefCounted


## Persistence file for lineage data.
const LINEAGE_FILE: String = "user://pokemon_studio/lineage.json"

## Maximum tracked entries (prevents unbounded growth).
const MAX_ENTRIES: int = 2000


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## All lineage records. Key: entity_id (String), Value: record Dictionary.
## Record: { id, kingdom, generation, parent_a_id, parent_b_id,
##           children_ids: Array, released, born_at, body_type }
var _records: Dictionary = {}

## Counter for generating unique IDs when no entity instance is available.
var _id_counter: int = 0


# ═══════════════════════════════════════════════════════════════
# RECORDING
# ═══════════════════════════════════════════════════════════════

## Record a birth from DNA data. Returns the assigned lineage ID.
## parent_a_id and parent_b_id should be lineage IDs (not Godot instance IDs).
func record_birth(
	dna: CritterDNA,
	parent_a_id: String = "",
	parent_b_id: String = "",
	lineage_id: String = ""
) -> String:
	# Generate an ID if not provided
	var id: String = lineage_id
	if id.is_empty():
		_id_counter += 1
		id = "lin_%04d" % _id_counter

	# Prune if at capacity
	if _records.size() >= MAX_ENTRIES:
		_prune_oldest()

	var record: Dictionary = {
		"id": id,
		"kingdom": dna.get_kingdom_name(),
		"body_type": dna.body_type,
		"generation": dna.generation,
		"parent_a_id": parent_a_id,
		"parent_b_id": parent_b_id,
		"children_ids": [],
		"released": false,
		"born_at": Time.get_datetime_string_from_system(),
	}

	_records[id] = record

	# Update parent records to include this child
	if parent_a_id in _records:
		(_records[parent_a_id] as Dictionary)["children_ids"].append(id)
	if not parent_b_id.is_empty() and parent_b_id in _records:
		(_records[parent_b_id] as Dictionary)["children_ids"].append(id)

	return id


## Record a birth from a CritterEntity (convenience for EvolutionSystem signals).
func record_entity_birth(
	child: CritterEntity,
	parent_a: CritterEntity,
	parent_b: CritterEntity
) -> String:
	if not child or not child.dna:
		return ""

	var pa_id: String = ""
	var pb_id: String = ""
	if parent_a:
		pa_id = _entity_to_lineage_id(parent_a)
	if parent_b:
		pb_id = _entity_to_lineage_id(parent_b)

	var id: String = _entity_to_lineage_id(child)
	return record_birth(child.dna, pa_id, pb_id, id)


## Mark a lineage entry as released to the ecosystem.
func mark_released(lineage_id: String) -> void:
	if lineage_id in _records:
		(_records[lineage_id] as Dictionary)["released"] = true


# ═══════════════════════════════════════════════════════════════
# QUERIES
# ═══════════════════════════════════════════════════════════════

## Get a single lineage record.
func get_record(lineage_id: String) -> Dictionary:
	if lineage_id in _records:
		return _records[lineage_id] as Dictionary
	return {}


## Get all ancestors of an entry up to a given depth.
## Returns an array of records from immediate parents outward.
func get_ancestors(lineage_id: String, max_depth: int = 10) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var queue: Array[String] = [lineage_id]
	var visited: Dictionary = {}
	var depth: int = 0

	while not queue.is_empty() and depth < max_depth:
		var next_queue: Array[String] = []
		for current_id in queue:
			if current_id in visited or current_id not in _records:
				continue
			visited[current_id] = true

			var record: Dictionary = _records[current_id] as Dictionary
			if current_id != lineage_id:  # Don't include the starting entry
				result.append(record)

			var pa: String = record.get("parent_a_id", "") as String
			var pb: String = record.get("parent_b_id", "") as String
			if not pa.is_empty() and pa not in visited:
				next_queue.append(pa)
			if not pb.is_empty() and pb not in visited:
				next_queue.append(pb)

		queue = next_queue
		depth += 1

	return result


## Get all descendants of an entry up to a given depth.
func get_descendants(lineage_id: String, max_depth: int = 10) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var queue: Array[String] = [lineage_id]
	var visited: Dictionary = {}
	var depth: int = 0

	while not queue.is_empty() and depth < max_depth:
		var next_queue: Array[String] = []
		for current_id in queue:
			if current_id in visited or current_id not in _records:
				continue
			visited[current_id] = true

			var record: Dictionary = _records[current_id] as Dictionary
			if current_id != lineage_id:
				result.append(record)

			var children: Array = record.get("children_ids", []) as Array
			for child_id in children:
				if (child_id as String) not in visited:
					next_queue.append(child_id as String)

		queue = next_queue
		depth += 1

	return result


## Build a full family tree structure rooted at a lineage ID.
## Returns a nested dictionary: { record, parents: [tree, tree], children: [tree, ...] }
func get_lineage_tree(lineage_id: String, ancestor_depth: int = 3, descendant_depth: int = 5) -> Dictionary:
	if lineage_id not in _records:
		return {}

	return _build_tree_node(lineage_id, ancestor_depth, descendant_depth, {})


## Find the entry with the most descendants.
func get_most_prolific() -> Dictionary:
	var best_id: String = ""
	var best_count: int = 0

	for id in _records:
		var descendants: Array[Dictionary] = get_descendants(id as String, 20)
		if descendants.size() > best_count:
			best_count = descendants.size()
			best_id = id as String

	if best_id.is_empty():
		return {}
	return {"id": best_id, "record": _records[best_id], "descendant_count": best_count}


## Find the longest unbroken lineage chain.
func get_longest_lineage() -> Dictionary:
	var best_id: String = ""
	var best_depth: int = 0

	for id in _records:
		var depth: int = _measure_ancestor_depth(id as String, {})
		if depth > best_depth:
			best_depth = depth
			best_id = id as String

	if best_id.is_empty():
		return {}
	return {"id": best_id, "record": _records[best_id], "depth": best_depth}


## Get summary statistics.
func get_summary() -> Dictionary:
	var kingdom_counts: Dictionary = {"tree": 0, "creature": 0, "flower": 0, "fungus": 0, "hybrid": 0}
	var total_released: int = 0
	var max_gen: int = 0

	for id in _records:
		var record: Dictionary = _records[id] as Dictionary
		var kn: String = record.get("kingdom", "unknown") as String
		if kn in kingdom_counts:
			kingdom_counts[kn] = (kingdom_counts[kn] as int) + 1
		if record.get("released", false) as bool:
			total_released += 1
		max_gen = maxi(max_gen, record.get("generation", 0) as int)

	return {
		"total_entries": _records.size(),
		"kingdom_counts": kingdom_counts,
		"total_released": total_released,
		"max_generation": max_gen,
	}


# ═══════════════════════════════════════════════════════════════
# PERSISTENCE
# ═══════════════════════════════════════════════════════════════

## Save lineage data to disk.
func save() -> void:
	DirAccess.make_dir_recursive_absolute("user://pokemon_studio/")
	var data: Dictionary = {
		"records": _records,
		"id_counter": _id_counter,
	}
	var json_str: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(LINEAGE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()


## Load lineage data from disk.
func load_data() -> void:
	if not FileAccess.file_exists(LINEAGE_FILE):
		return

	var file := FileAccess.open(LINEAGE_FILE, FileAccess.READ)
	if not file:
		return

	var json_str: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		_records = data.get("records", {}) as Dictionary
		_id_counter = int(data.get("id_counter", 0))


## Export lineage as JSON string (for web editor).
func export_json() -> String:
	return JSON.stringify(_records, "\t")


# ═══════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════

## Convert a CritterEntity to a lineage ID (using Godot instance ID as string).
func _entity_to_lineage_id(entity: CritterEntity) -> String:
	return "ent_%d" % entity.get_instance_id()


## Build a tree node recursively.
func _build_tree_node(
	lineage_id: String,
	ancestor_depth: int,
	descendant_depth: int,
	visited: Dictionary
) -> Dictionary:
	if lineage_id in visited or lineage_id not in _records:
		return {}
	visited[lineage_id] = true

	var record: Dictionary = _records[lineage_id] as Dictionary
	var node: Dictionary = {"record": record, "parents": [], "children": []}

	# Build parent branches (going up)
	if ancestor_depth > 0:
		var pa: String = record.get("parent_a_id", "") as String
		var pb: String = record.get("parent_b_id", "") as String
		if not pa.is_empty() and pa not in visited:
			var parent_node: Dictionary = _build_tree_node(pa, ancestor_depth - 1, 0, visited)
			if not parent_node.is_empty():
				(node["parents"] as Array).append(parent_node)
		if not pb.is_empty() and pb not in visited:
			var parent_node: Dictionary = _build_tree_node(pb, ancestor_depth - 1, 0, visited)
			if not parent_node.is_empty():
				(node["parents"] as Array).append(parent_node)

	# Build child branches (going down)
	if descendant_depth > 0:
		var children: Array = record.get("children_ids", []) as Array
		for child_id in children:
			if (child_id as String) not in visited:
				var child_node: Dictionary = _build_tree_node(child_id as String, 0, descendant_depth - 1, visited)
				if not child_node.is_empty():
					(node["children"] as Array).append(child_node)

	return node


## Measure ancestor chain depth (for longest lineage query).
func _measure_ancestor_depth(lineage_id: String, visited: Dictionary) -> int:
	if lineage_id in visited or lineage_id not in _records:
		return 0
	visited[lineage_id] = true

	var record: Dictionary = _records[lineage_id] as Dictionary
	var pa: String = record.get("parent_a_id", "") as String
	var pb: String = record.get("parent_b_id", "") as String

	var depth_a: int = 0
	var depth_b: int = 0

	if not pa.is_empty():
		depth_a = _measure_ancestor_depth(pa, visited)
	if not pb.is_empty():
		depth_b = _measure_ancestor_depth(pb, visited)

	return 1 + maxi(depth_a, depth_b)


## Remove oldest entries when at capacity.
func _prune_oldest() -> void:
	# Find entries with no children (leaf nodes) and oldest born_at
	var candidates: Array[String] = []
	for id in _records:
		var record: Dictionary = _records[id] as Dictionary
		var children: Array = record.get("children_ids", []) as Array
		if children.is_empty():
			candidates.append(id as String)

	# Sort by born_at (oldest first) and remove some
	# Simple approach: remove 10% of leaf nodes
	var to_remove: int = maxi(candidates.size() / 10, 1)
	for i in mini(to_remove, candidates.size()):
		_records.erase(candidates[i])
