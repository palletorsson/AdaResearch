extends RefCounted
## Instance-scoped trials never replace the curated tower's data.
const TRIALS := "res://commons/void/trials/playable.json"
## A menu choice may leave a process launched with --void-trial. Explicit trial
## scenes still win; choosing the main tower clears the CLI default for it.
static var use_main_tower := false

## Separate drafts belong to the encyclopedia/editor, not the Quest release.
## Runtime import adapters are still packaged for their integrated tower floors.
static func trials_available() -> bool:
	return not OS.has_feature("quest_game")

## An imported spine floor retains the adapters of its source trial even after
## its floor number changes. Explicit trials continue to use their own context.
static func floor_trial(layout: Dictionary, index: int, trial := "") -> String:
	return trial if not trial.is_empty() else str(layout.get("floor_sources", {}).get(str(index), {}).get("trial", ""))

## Cross-floor editor copies keep their original import adapter as well as their
## preview model. Curated source floors deliberately have no trial adapter.
static func artifact_trial(layout: Dictionary, index: int, item: Dictionary, trial := "") -> String:
	var source_index := int(item.get("config", {}).get("editor_source", {}).get("floor", index))
	return floor_trial(layout, source_index, trial)

static func selected(explicit_id := "") -> String:
	if not trials_available(): return ""
	if not explicit_id.is_empty(): return explicit_id
	if use_main_tower: return ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-trial="): return arg.trim_prefix("--void-trial=")
	return ""

static func definition(id: String) -> Dictionary:
	if id.is_empty() or not trials_available(): return {}
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TRIALS))
	assert(manifest.trials.has(id), "Unknown Void trial: " + id)
	return manifest.trials.get(id, {})

static func read_rooms(trial := "") -> Dictionary:
	var record := definition(selected(trial))
	var path: String = record.get("rooms", "res://commons/void/rooms.json")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-draft="): path = arg.trim_prefix("--void-draft=")
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func read_layout(trial := "") -> Dictionary:
	var record := definition(selected(trial))
	return JSON.parse_string(FileAccess.get_file_as_string(record.get("layout", "res://commons/void/layout.json")))
