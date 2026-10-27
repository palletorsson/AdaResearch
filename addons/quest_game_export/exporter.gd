@tool
extends EditorExportPlugin
## Enforce the boundary also for future trial/evidence files not in the preset.
const POLICY := "res://addons/quest_game_export/runtime-trial-files.json"
var active := false
var runtime: Dictionary = {}
var kept := 0
var omitted := 0
func _get_name() -> String: return "QuestGameContentBoundary"
func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
	active = features.has("quest_game")
	kept = 0; omitted = 0; runtime.clear()
	if not active: return
	var policy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POLICY))
	for path in policy.get("runtime", []): runtime["res://"+str(path)] = true
	assert(not runtime.is_empty(), "Run python tools/configure_quest_content.py --apply before exporting Quest.")
func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if not active: return
	var authoring := path.begins_with("res://ada_run/") or path.begins_with("res://addons/quest_game_export/") or "/evidence/" in path or "/screenshots/" in path
	if path.begins_with("res://commons/void/trials/") and not runtime.has(path): authoring = true
	if authoring:
		omitted += 1
		skip()
	else: kept += 1
func _export_end() -> void:
	if active: print("[Quest game export] Retained %d gameplay resources; omitted %d authoring files. Separate trials remain in Ada Encyclopedia." % [kept, omitted])
