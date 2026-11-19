extends RefCounted
## The opening edit lives in each floor's encounter score. The same selection
## drives the sightlines, song triggers and live-voice preparation.
const POLICIES := {
	"Point_Zero": "res://commons/data/encounters/point_zero_progression.json",
	"Point_One": "res://commons/data/encounters/point_one_progression.json",
	"Point_Coordinates": "res://commons/data/encounters/point_coordinates_progression.json",
	"Point_Lines": "res://commons/data/encounters/point_lines_progression.json",
	"Point_Trace": "res://commons/data/encounters/point_trace_progression.json",
}
static var _frames := {}
const PLACEMENTS := "res://commons/data/encounters/opera_frame_placements.json"
const WHEEL := "spine_c2b6fc98a64a37b397"
static var _placements: Variant = null

static func placements(map: String) -> Dictionary:
	if _placements == null:
		_placements = JSON.parse_string(FileAccess.get_file_as_string(PLACEMENTS)) if FileAccess.file_exists(PLACEMENTS) else {}
	return _placements.get(map, {}) if _placements is Dictionary else {}

static func frames(map: String) -> Dictionary:
	if not _frames.has(map):
		var selected := {}
		if POLICIES.has(map):
			var policy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POLICIES[map]))
			for encounter in policy.encounters:
				if encounter.has("view_frame"): selected[encounter.song] = encounter
		var edits := placements(map)
		for song in edits:
			if song == WHEEL: continue # The wheel owns its mechanical trigger.
			var edit: Dictionary = edits[song]
			if edit.get("kind") == "encounter" or not edit.has("position"): continue
			var encounter: Dictionary = selected.get(song, {"song":song, "badge":edit.badge})
			var spec: Dictionary = encounter.get("view_frame", {}).duplicate()
			spec.merge(edit, true)
			encounter.view_frame = spec
			selected[song] = encounter
		_frames[map] = selected
	return _frames[map]

static func bindings(map: String, published: Dictionary) -> Dictionary:
	if not POLICIES.has(map): return published
	var selected := frames(map)
	var result := {}
	for row in published:
		var id: String = published[row]
		if not selected.has(id): continue
		result[row] = id
		for reference in selected[id].get("also_observe", []):
			result[reference] = id
	return result
