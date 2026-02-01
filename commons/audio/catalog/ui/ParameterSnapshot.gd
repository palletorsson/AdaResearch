# ParameterSnapshot.gd
# A/B comparison and parameter preset management
# Stores, compares, and morphs between parameter states

extends RefCounted
class_name ParameterSnapshot

var name: String = ""
var timestamp: int = 0
var parameters: Dictionary = {}
var tags: Array[String] = []
var notes: String = ""


static func create(snapshot_name: String, params: Dictionary) -> ParameterSnapshot:
	var snap = ParameterSnapshot.new()
	snap.name = snapshot_name
	snap.timestamp = Time.get_unix_time_from_system()
	snap.parameters = params.duplicate(true)
	return snap


func to_dict() -> Dictionary:
	return {
		"name": name,
		"timestamp": timestamp,
		"parameters": parameters,
		"tags": tags,
		"notes": notes
	}


static func from_dict(data: Dictionary) -> ParameterSnapshot:
	var snap = ParameterSnapshot.new()
	snap.name = data.get("name", "")
	snap.timestamp = data.get("timestamp", 0)
	snap.parameters = data.get("parameters", {})
	snap.tags = data.get("tags", [])
	snap.notes = data.get("notes", "")
	return snap


# Morph between two snapshots
static func lerp_snapshots(a: ParameterSnapshot, b: ParameterSnapshot, t: float) -> Dictionary:
	var result = {}
	
	# Get all keys from both
	var all_keys = a.parameters.keys()
	for key in b.parameters.keys():
		if not key in all_keys:
			all_keys.append(key)
	
	for key in all_keys:
		var val_a = a.parameters.get(key, 0.0)
		var val_b = b.parameters.get(key, 0.0)
		
		if val_a is float and val_b is float:
			result[key] = lerp(val_a, val_b, t)
		elif val_a is int and val_b is int:
			result[key] = int(lerp(float(val_a), float(val_b), t))
		elif val_a is Color and val_b is Color:
			result[key] = val_a.lerp(val_b, t)
		else:
			# Non-interpolatable - use A if t < 0.5, else B
			result[key] = val_a if t < 0.5 else val_b
	
	return result


# Calculate difference between two snapshots
static func diff_snapshots(a: ParameterSnapshot, b: ParameterSnapshot) -> Dictionary:
	var diff = {}
	
	var all_keys = a.parameters.keys()
	for key in b.parameters.keys():
		if not key in all_keys:
			all_keys.append(key)
	
	for key in all_keys:
		var val_a = a.parameters.get(key)
		var val_b = b.parameters.get(key)
		
		if val_a != val_b:
			diff[key] = {
				"a": val_a,
				"b": val_b,
				"delta": (val_b - val_a) if (val_a is float and val_b is float) else null
			}
	
	return diff


## ParameterSnapshotManager - stores multiple snapshots

class Manager:
	var snapshots: Dictionary = {}  # name -> ParameterSnapshot
	var history: Array[ParameterSnapshot] = []
	var max_history: int = 50
	var current_index: int = -1
	
	func save_snapshot(snapshot_name: String, params: Dictionary) -> ParameterSnapshot:
		var snap = ParameterSnapshot.create(snapshot_name, params)
		snapshots[snapshot_name] = snap
		_add_to_history(snap)
		return snap
	
	func load_snapshot(snapshot_name: String) -> Dictionary:
		if snapshots.has(snapshot_name):
			return snapshots[snapshot_name].parameters.duplicate(true)
		return {}
	
	func delete_snapshot(snapshot_name: String):
		snapshots.erase(snapshot_name)
	
	func get_snapshot_names() -> Array:
		return snapshots.keys()
	
	func has_snapshot(snapshot_name: String) -> bool:
		return snapshots.has(snapshot_name)
	
	func _add_to_history(snap: ParameterSnapshot):
		# If we're not at the end, truncate forward history
		if current_index < history.size() - 1:
			history = history.slice(0, current_index + 1)
		
		history.append(snap)
		
		# Limit history size
		if history.size() > max_history:
			history = history.slice(history.size() - max_history)
		
		current_index = history.size() - 1
	
	func undo() -> Dictionary:
		if current_index > 0:
			current_index -= 1
			return history[current_index].parameters.duplicate(true)
		return {}
	
	func redo() -> Dictionary:
		if current_index < history.size() - 1:
			current_index += 1
			return history[current_index].parameters.duplicate(true)
		return {}
	
	func can_undo() -> bool:
		return current_index > 0
	
	func can_redo() -> bool:
		return current_index < history.size() - 1
	
	func save_to_file(path: String):
		var data = {}
		for snap_name in snapshots.keys():
			data[snap_name] = snapshots[snap_name].to_dict()
		
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(data, "\t"))
			file.close()
	
	func load_from_file(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			file.close()
			
			if error == OK and json.data is Dictionary:
				for snap_name in json.data.keys():
					snapshots[snap_name] = ParameterSnapshot.from_dict(json.data[snap_name])
