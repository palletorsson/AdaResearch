extends Node
## Earned construction recipes, separate from weapon holsters and museum scores.
## The catalogue is also read by the Three.js tree and the live editor.
const CATALOGUE := "res://commons/void/primitive-prefabs.json"
const SAVE := "user://void-prefab-inventory.json"
signal changed
signal earned(id: String)
var definitions: Dictionary = {}
var completed: Dictionary = {}
var save_path := SAVE
var save_error := ""

func _ready() -> void:
	if not OS.get_environment("VOID_INVENTORY_PATH").is_empty():
		save_path = OS.get_environment("VOID_INVENTORY_PATH")
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	for entry in document.prefabs: definitions[str(entry.id)] = entry
	reload()

func reload() -> void:
	completed.clear()
	var path := save_path if FileAccess.file_exists(save_path) else save_path + ".bak"
	if FileAccess.file_exists(path):
		var state = JSON.parse_string(FileAccess.get_file_as_string(path))
		if state is Dictionary and state.get("completed") is Dictionary:
			completed = state.completed.duplicate(true)
	changed.emit()

func unlocked(id: String) -> bool:
	var rule: Dictionary = definitions.get(id, {}).get("completion", {})
	return not rule.is_empty() and completed.has(str(rule.objective))

## Only the designated main-tower lesson can award a recipe. Preview/trial/copy
## instances still compute, but cannot grant player progress.
func bind_lesson(content: Node, trial: String) -> void:
	if not trial.is_empty(): return
	for id in definitions:
		var entry: Dictionary = definitions[id]
		if not entry.has("completion"): continue
		var placement: Dictionary = entry.placement
		var key := "%d/%s" % [placement.source_floor, placement.source_id]
		var mount: Node = content.exhibits.get(key)
		if not is_instance_valid(mount): continue
		var lesson := mount.get_node_or_null("Artifact")
		if lesson == null or lesson.get_meta("void_source", "") != entry.scene: continue
		if str(content.data.floors[int(placement.source_floor)].map) != entry.completion.map: continue
		var callback := Callable(self, "_lesson_completed").bind(str(id))
		if lesson.has_signal("interaction_completed") and not lesson.is_connected("interaction_completed", callback):
			lesson.connect("interaction_completed", callback)

func _lesson_completed(id: String) -> void:
	if unlocked(id): return
	var rule: Dictionary = definitions[id].completion
	completed[str(rule.objective)] = {"prefab":id, "map":rule.map, "at":Time.get_datetime_string_from_system(true)}
	if not _save():
		completed.erase(str(rule.objective))
		changed.emit()
		return
	changed.emit()
	earned.emit(id)

func _save() -> bool:
	save_error = ""
	var absolute := ProjectSettings.globalize_path(save_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Could not write prefab inventory"; push_warning(save_error); return false
	file.store_string(JSON.stringify({"version":1,"completed":completed}, "  ") + "\n")
	file.close()
	if FileAccess.file_exists(absolute):
		var backup_error := DirAccess.rename_absolute(absolute, absolute + ".bak")
		if backup_error != OK:
			save_error = "Could not back up prefab inventory"; push_warning(save_error); return false
	var result := DirAccess.rename_absolute(absolute + ".tmp", absolute)
	if result != OK:
		save_error = "Could not save prefab inventory"; push_warning(save_error); return false
	return true
