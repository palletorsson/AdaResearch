class_name ContentValidator
extends RefCounted

## Validates the full content chain: sequences → maps → artifacts → scenes
## Also loads descriptive content (blurb, technical, summary, critical)

const SEQUENCES_PATH = "res://commons/maps/sequences/"
const MAPS_PATH = "res://commons/maps/"
const SPINE_PATH = "res://commons/maps/curriculum_spine.json"
const ARTIFACT_REGISTRY_PATH = "res://commons/artifacts/grid_artifacts.json"
const ARTIFACT_REGISTRY_DIR = "res://commons/artifacts/registry/"

#region Data Structures

class ValidationReport:
	var sequences: Dictionary = {}  # name → SequenceInfo
	var spine_order: Array[String] = []
	var branch_map: Dictionary = {}  # spine_name → [branch_names]
	var issues: Array[Dictionary] = []
	var summary: String = ""
	
	var total_sequences: int = 0
	var total_maps: int = 0
	var total_artifacts: int = 0
	var missing_maps: int = 0
	var missing_artifacts: int = 0
	var missing_scenes: int = 0
	var orphaned_maps: int = 0

class SequenceInfo:
	var name: String = ""
	var display_name: String = ""
	var phase: String = ""
	var is_spine: bool = false
	var spine_order: int = 0
	var maps: Array[String] = []
	var map_status: Dictionary = {}  # map_name → MapInfo
	
	# Descriptive content from sequence JSON
	var description: String = ""
	var truth: String = ""
	var qfep_connection: String = ""
	var formula: String = ""
	var difficulty: String = ""
	var estimated_time: String = ""
	var learning_objectives: Array[String] = []

class MapInfo:
	var name: String = ""
	var exists: bool = false
	var path: String = ""
	var folder_path: String = ""
	var artifacts: Array[String] = []
	var artifact_status: Dictionary = {}  # artifact_key → ArtifactStatus
	
	# Map metadata from map_data.json
	var description: String = ""
	var difficulty: String = ""
	var estimated_time: String = ""
	var dimensions: Dictionary = {}
	
	# Descriptive content files
	var blurb: String = ""
	var technical: String = ""
	var summary_text: String = ""  # "summary" is reserved
	var critical: String = ""
	var has_blurb: bool = false
	var has_technical: bool = false
	var has_summary: bool = false
	var has_critical: bool = false

class ArtifactStatus:
	var key: String = ""
	var in_registry: bool = false
	var scene_path: String = ""
	var scene_exists: bool = false
	var error: String = ""

#endregion

#region Main Validation

static func validate_all() -> ValidationReport:
	var report = ValidationReport.new()
	
	_load_spine(report)
	_load_sequences(report)
	
	var artifact_registry = _load_artifact_registry()
	
	for seq_name in report.sequences.keys():
		var seq = report.sequences[seq_name]
		_validate_sequence_maps(seq, artifact_registry, report)
	
	_find_orphaned_maps(report)
	_generate_summary(report)
	
	return report

#endregion

#region Spine Loading

static func _load_spine(report: ValidationReport) -> void:
	var file = FileAccess.open(SPINE_PATH, FileAccess.READ)
	if not file:
		report.issues.append({"type": "error", "category": "spine", "message": "Could not load curriculum_spine.json"})
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		report.issues.append({"type": "error", "category": "spine", "message": "Invalid JSON: " + json.get_error_message()})
		file.close()
		return
	file.close()
	
	var data = json.data
	var spine = data.get("spine", {})
	var sequences = spine.get("sequences", [])
	for seq in sequences:
		var name = seq.get("name", "")
		if name != "":
			report.spine_order.append(name)
	
	var branches = data.get("branches", {})
	var branch_points = branches.get("branch_points", {})
	for spine_name in branch_points.keys():
		report.branch_map[spine_name] = branch_points[spine_name].get("unlocks", [])

#endregion

#region Sequence Loading

static func _load_sequences(report: ValidationReport) -> void:
	var dir = DirAccess.open(SEQUENCES_PATH)
	if not dir:
		report.issues.append({"type": "error", "category": "sequences", "message": "Could not open sequences directory"})
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_load_single_sequence(file_name.replace(".json", ""), report)
		file_name = dir.get_next()
	dir.list_dir_end()

static func _load_single_sequence(seq_name: String, report: ValidationReport) -> void:
	var path = SEQUENCES_PATH + seq_name + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	
	var data = json.data
	var seq_info = SequenceInfo.new()
	seq_info.name = seq_name
	
	# Navigate to actual sequence data
	var sequences_wrapper = data.get("sequences", {})
	var seq_data = sequences_wrapper.get(seq_name, {})
	if seq_data.is_empty():
		seq_data = data
	
	seq_info.display_name = seq_data.get("name", seq_name.capitalize())
	
	# Load descriptive content
	seq_info.description = seq_data.get("description", "")
	seq_info.truth = seq_data.get("truth", "")
	seq_info.qfep_connection = seq_data.get("qfep_connection", "")
	seq_info.formula = seq_data.get("formula", "")
	seq_info.difficulty = seq_data.get("difficulty", "")
	seq_info.estimated_time = seq_data.get("estimated_time", "")
	
	var objectives = seq_data.get("learning_objectives", [])
	for obj in objectives:
		seq_info.learning_objectives.append(str(obj))
	
	# Get maps
	var maps = seq_data.get("maps", [])
	for m in maps:
		seq_info.maps.append(m)
	
	# Spine info
	var spine_idx = report.spine_order.find(seq_name)
	seq_info.is_spine = spine_idx >= 0
	seq_info.spine_order = spine_idx + 1 if spine_idx >= 0 else 0
	
	if seq_info.is_spine:
		seq_info.phase = _get_phase_for_sequence(seq_name)
	
	report.sequences[seq_name] = seq_info
	report.total_sequences += 1

static func _get_phase_for_sequence(seq_name: String) -> String:
	var file = FileAccess.open(SPINE_PATH, FileAccess.READ)
	if not file:
		return ""
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return ""
	file.close()
	
	var sequences = json.data.get("spine", {}).get("sequences", [])
	for seq in sequences:
		if seq.get("name", "") == seq_name:
			return seq.get("phase", "")
	return ""

#endregion

#region Map Validation

static func _validate_sequence_maps(seq: SequenceInfo, artifact_registry: Dictionary, report: ValidationReport) -> void:
	for map_name in seq.maps:
		var mi = MapInfo.new()
		mi.name = map_name
		mi.folder_path = MAPS_PATH + map_name + "/"
		mi.path = mi.folder_path + "map_data.json"
		
		if FileAccess.file_exists(mi.path):
			mi.exists = true
			report.total_maps += 1
			_load_map_metadata(mi)
			_load_map_texts(mi)
			_validate_map_artifacts(mi, artifact_registry, report)
		else:
			mi.exists = false
			report.missing_maps += 1
			report.issues.append({
				"type": "error", "category": "map",
				"sequence": seq.name, "map": map_name,
				"message": "Map folder/map_data.json missing"
			})
		
		seq.map_status[map_name] = mi

static func _load_map_metadata(mi: MapInfo) -> void:
	var file = FileAccess.open(mi.path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	
	var data = json.data
	var map_info = data.get("map_info", {})
	mi.description = map_info.get("description", "")
	mi.dimensions = map_info.get("dimensions", {})
	
	var metadata = map_info.get("metadata", {})
	mi.difficulty = metadata.get("difficulty", "")
	mi.estimated_time = metadata.get("estimated_time", "")

static func _load_map_texts(mi: MapInfo) -> void:
	# Load blurb.md
	var blurb_path = mi.folder_path + "blurb.md"
	if FileAccess.file_exists(blurb_path):
		var f = FileAccess.open(blurb_path, FileAccess.READ)
		if f:
			mi.blurb = f.get_as_text()
			mi.has_blurb = true
			f.close()
	
	# Load technical.md
	var tech_path = mi.folder_path + "technical.md"
	if FileAccess.file_exists(tech_path):
		var f = FileAccess.open(tech_path, FileAccess.READ)
		if f:
			mi.technical = f.get_as_text()
			mi.has_technical = true
			f.close()
	
	# Load summary.md
	var sum_path = mi.folder_path + "summary.md"
	if FileAccess.file_exists(sum_path):
		var f = FileAccess.open(sum_path, FileAccess.READ)
		if f:
			mi.summary_text = f.get_as_text()
			mi.has_summary = true
			f.close()
	
	# Load critical.md
	var crit_path = mi.folder_path + "critical.md"
	if FileAccess.file_exists(crit_path):
		var f = FileAccess.open(crit_path, FileAccess.READ)
		if f:
			mi.critical = f.get_as_text()
			mi.has_critical = true
			f.close()

static func _validate_map_artifacts(mi: MapInfo, artifact_registry: Dictionary, report: ValidationReport) -> void:
	var file = FileAccess.open(mi.path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	
	var layers = json.data.get("layers", {})
	var interactables = layers.get("interactables", [])
	
	var artifact_keys: Dictionary = {}
	for row in interactables:
		if row is Array:
			for cell in row:
				if cell is String and cell.strip_edges() != "" and cell != " ":
					var base_key = cell.split(":")[0].split("#")[0]
					artifact_keys[base_key] = true
	
	for key in artifact_keys.keys():
		var status = ArtifactStatus.new()
		status.key = key
		
		if artifact_registry.has(key):
			status.in_registry = true
			status.scene_path = artifact_registry[key].get("scene", "")
			if status.scene_path != "":
				status.scene_exists = ResourceLoader.exists(status.scene_path)
				if not status.scene_exists:
					status.error = "Scene not found"
					report.missing_scenes += 1
					report.issues.append({
						"type": "error", "category": "scene",
						"map": mi.name, "artifact": key,
						"scene": status.scene_path, "message": "Scene file missing"
					})
		else:
			status.in_registry = false
			status.error = "Not in registry"
			report.missing_artifacts += 1
			report.issues.append({
				"type": "error", "category": "artifact",
				"map": mi.name, "artifact": key,
				"message": "Artifact not in registry"
			})
		
		mi.artifacts.append(key)
		mi.artifact_status[key] = status
		report.total_artifacts += 1

#endregion

#region Artifact Registry

static func _load_artifact_registry() -> Dictionary:
	var registry: Dictionary = {}
	_load_registry_file(ARTIFACT_REGISTRY_PATH, registry)
	
	var dir = DirAccess.open(ARTIFACT_REGISTRY_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				_load_registry_file(ARTIFACT_REGISTRY_DIR + file_name, registry)
			file_name = dir.get_next()
		dir.list_dir_end()
	return registry

static func _load_registry_file(path: String, registry: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	
	var artifacts = json.data.get("artifacts", json.data)
	if artifacts is Dictionary:
		for key in artifacts.keys():
			if artifacts[key] is Dictionary:
				registry[key] = artifacts[key]

#endregion

#region Orphan Detection

static func _find_orphaned_maps(report: ValidationReport) -> void:
	var all_folders: Dictionary = {}
	var dir = DirAccess.open(MAPS_PATH)
	if not dir:
		return
	
	dir.list_dir_begin()
	var folder = dir.get_next()
	while folder != "":
		if dir.current_is_dir() and folder != "sequences":
			if FileAccess.file_exists(MAPS_PATH + folder + "/map_data.json"):
				all_folders[folder] = true
		folder = dir.get_next()
	dir.list_dir_end()
	
	var claimed: Dictionary = {}
	for seq_name in report.sequences.keys():
		var seq = report.sequences[seq_name]
		for map_name in seq.maps:
			claimed[map_name] = seq_name
	
	for folder_name in all_folders.keys():
		if not claimed.has(folder_name):
			report.orphaned_maps += 1
			report.issues.append({
				"type": "warning", "category": "orphan",
				"map": folder_name, "message": "Map not in any sequence"
			})

#endregion

#region Summary

static func _generate_summary(report: ValidationReport) -> void:
	var lines: Array[String] = []
	lines.append("=== AdaResearch Content Validation ===")
	lines.append("")
	lines.append("SEQUENCES: %d (%d spine + %d branch)" % [
		report.total_sequences, report.spine_order.size(),
		report.total_sequences - report.spine_order.size()
	])
	lines.append("MAPS: %d | %d missing | %d orphaned" % [
		report.total_maps, report.missing_maps, report.orphaned_maps
	])
	lines.append("ARTIFACTS: %d | %d undefined | %d scenes missing" % [
		report.total_artifacts, report.missing_artifacts, report.missing_scenes
	])
	
	var errors = report.issues.filter(func(i): return i.get("type") == "error").size()
	var warnings = report.issues.size() - errors
	
	lines.append("")
	if errors == 0 and warnings == 0:
		lines.append("✅ All validations passed!")
	else:
		lines.append("ISSUES: %d errors | %d warnings" % [errors, warnings])
	
	report.summary = "\n".join(lines)

static func print_report(report: ValidationReport) -> void:
	print(report.summary)
	if report.issues.size() > 0:
		print("\n--- ISSUES ---")
		for issue in report.issues:
			var prefix = "❌" if issue.get("type") == "error" else "⚠️"
			var loc = issue.get("sequence", "") + "/" + issue.get("map", "")
			if issue.has("artifact"):
				loc += "/" + issue["artifact"]
			print("%s [%s] %s: %s" % [prefix, issue.get("category", ""), loc.trim_prefix("/"), issue.get("message", "")])

static func get_sequence_hierarchy(report: ValidationReport, seq_name: String) -> String:
	if not report.sequences.has(seq_name):
		return "Sequence not found"
	
	var seq = report.sequences[seq_name] as SequenceInfo
	var lines: Array[String] = []
	
	var badge = " [SPINE #%d]" % seq.spine_order if seq.is_spine else ""
	lines.append("%s%s" % [seq.display_name, badge])
	
	for i in range(seq.maps.size()):
		var map_name = seq.maps[i]
		var prefix = "└─" if i == seq.maps.size() - 1 else "├─"
		var status = "?"
		if seq.map_status.has(map_name):
			var mi = seq.map_status[map_name] as MapInfo
			status = "✓" if mi.exists else "✗ MISSING"
		lines.append("  %s %s %s" % [prefix, map_name, status])
	
	return "\n".join(lines)

#endregion
