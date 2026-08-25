extends SceneTree

## Focused persistence probe for the Endless Museum plan editor. It exercises
## pool metadata, door placement/orientation, generic artifact configuration,
## passage ownership, wall replacement, and exact undo without touching a real
## curriculum map.

const MuseumScript := preload("res://commons/scenes/endless_museum.gd")
const FIXTURE_NAME := "__plan_editor_probe"
const FIXTURE_DIR := "res://commons/maps/" + FIXTURE_NAME
const FIXTURE_PATH := FIXTURE_DIR + "/map_data.json"

var _failures: PackedStringArray = []


func _initialize() -> void:
	_write_fixture()
	var museum: Node = MuseumScript.new()
	museum.call("_plan_toolbar_on")
	var toolbar: HBoxContainer = museum.get("_plan_toolbar")
	_expect(toolbar != null and toolbar.get_child_count() == 9,
		"plan toolbar exposes the complete editing toolset")
	var toolbar_tools: PackedStringArray = []
	if toolbar != null:
		for child in toolbar.get_children():
			toolbar_tools.append(String(child.get_meta("plan_tool", "")))
	for required_tool in ["", "2", "1", "pool", "door", "0", "passage", "config", "build"]:
		_expect(toolbar_tools.has(required_tool), "plan toolbar includes '%s'" % required_tool)

	var pool: Dictionary = museum.call("_map_plan_edit", FIXTURE_NAME, 1, 1, "pool")
	_expect(bool(pool.get("ok", false)), "pool paint succeeds")
	var doc := _read_fixture()
	var basin: Dictionary = ((doc.get("map_info", {}) as Dictionary).get("museum", {}) as Dictionary).get("basin", {})
	_expect((doc["layers"]["structure"][1] as Array)[1] == "1", "pool keeps a floor structure cell")
	_expect(_has_cell(basin.get("cells", []) as Array, Vector2i(1, 1)),
		"pool is persisted in museum.basin.cells")

	var undo_pool: Dictionary = museum.call("_map_plan_edit", FIXTURE_NAME, 1, 1, "", pool.get("prev", {}))
	_expect(bool(undo_pool.get("ok", false)), "pool undo succeeds")
	doc = _read_fixture()
	basin = ((doc.get("map_info", {}) as Dictionary).get("museum", {}) as Dictionary).get("basin", {})
	_expect(not _has_cell(basin.get("cells", []) as Array, Vector2i(1, 1)),
		"pool undo removes the museum cell")

	var door: Dictionary = museum.call("_map_plan_edit", FIXTURE_NAME, 1, 1, "door")
	_expect(bool(door.get("ok", false)), "door paint succeeds")
	doc = _read_fixture()
	var door_token := str((doc["layers"]["interactables"][1] as Array)[1]).strip_edges()
	_expect(door_token.begins_with("lab_sliding_door:0"), "door aligns with east/west wall neighbours")

	var configured: Dictionary = museum.call("_map_config_replace", FIXTURE_NAME, 1, 1,
		{"panels_open_amount": "0.5", "welcome": "pane"})
	_expect(bool(configured.get("ok", false)), "generic configuration write succeeds")
	_expect(String(configured.get("token", "")).contains("#welcome:pane"), "configuration is encoded in the token")

	var wall: Dictionary = museum.call("_map_plan_edit", FIXTURE_NAME, 1, 1, "2")
	_expect(bool(wall.get("ok", false)), "wall paint succeeds")
	doc = _read_fixture()
	_expect(str((doc["layers"]["interactables"][1] as Array)[1]).strip_edges() == "",
		"painting a wall removes the door occupying that threshold")
	var undo_wall: Dictionary = museum.call("_map_plan_edit", FIXTURE_NAME, 1, 1, "", wall.get("prev", {}))
	_expect(bool(undo_wall.get("ok", false)), "wall undo succeeds")
	doc = _read_fixture()
	_expect(str((doc["layers"]["interactables"][1] as Array)[1]).contains("#welcome:pane"),
		"undo restores the exact configured door token")

	# An authored artifact's fine transform is map dress, not an invisible
	# session override. This is the persistence lane used by Shift-gizmo and Y.
	(doc["layers"]["interactables"][1] as Array)[1] = "probe_artifact"
	var rewrite := FileAccess.open(FIXTURE_PATH, FileAccess.WRITE)
	rewrite.store_string(JSON.stringify(doc))
	rewrite.close()
	var seg := Node3D.new()
	seg.set_meta("em_map", FIXTURE_NAME)
	var body := Node3D.new()
	seg.add_child(body)
	museum.set("_edit_records", [{"token": "probe_artifact", "node": body, "seg": seg,
		"tile_cell": [1, 1], "kind": ""}])
	museum.set("_edit_sel", 0)
	museum.call("_edit_fine", 0.2, 0.4, -0.2)
	doc = _read_fixture()
	var dressed := str((doc["layers"]["interactables"][1] as Array)[1])
	_expect(dressed.contains("#offset:0.20,0.40,-0.20"),
		"fine authored move persists as the token's #offset dress")
	museum.call("_edit_fine", -0.2, -0.4, 0.2)
	doc = _read_fixture()
	_expect(not str((doc["layers"]["interactables"][1] as Array)[1]).contains("#offset:"),
		"returning to zero removes the authored offset ruling")

	# Passage edits live in the authored hall, while their traversable rows are
	# derived at build time. This keeps the join continuous across every view.
	var passage: Dictionary = museum.call("_map_passage_replace", FIXTURE_NAME,
		{"kind": "hall", "width": 3, "offset": 2, "side": "left"})
	_expect(bool(passage.get("ok", false)), "passage declaration write succeeds")
	doc = _read_fixture()
	var passage_decl: Dictionary = ((doc.get("map_info", {}) as Dictionary) \
		.get("museum", {}) as Dictionary).get("passage", {})
	_expect(passage_decl.get("kind") == "hall", "passage form persists")
	_expect(int(passage_decl.get("width", 0)) == 3, "passage width persists")
	_expect(int(passage_decl.get("offset", 0)) == 2 and passage_decl.get("side") == "left",
		"passage side-step and turn side persist")
	museum.call("_passage_open")
	var passage_kind: OptionButton = museum.get("_passage_kind")
	var passage_width: SpinBox = museum.get("_passage_width")
	var passage_side: OptionButton = museum.get("_passage_side")
	_expect(passage_kind != null and String(passage_kind.get_item_metadata(
		passage_kind.selected)) == "hall", "passage panel loads the authored form")
	_expect(passage_width != null and int(passage_width.value) == 3,
		"passage panel loads the authored width")
	_expect(passage_side != null and String(passage_side.get_item_metadata(
		passage_side.selected)) == "left", "passage panel loads the authored turn side")
	museum.call("_plan_config_close")
	var source_tile: Array = (doc["layers"]["structure"] as Array)
	var built_passage: Array = museum.call("_authored_passages", source_tile, passage_decl)
	_expect(built_passage.size() == source_tile.size() + 4,
		"passage hall derives four joined rows")
	for z in range(source_tile.size(), built_passage.size()):
		_expect((built_passage[z] as Array).has("1"),
			"every derived passage row keeps a walkable route")
	var reset_passage: Dictionary = museum.call("_map_passage_replace", FIXTURE_NAME, {})
	_expect(bool(reset_passage.get("ok", false)), "passage default reset succeeds")
	doc = _read_fixture()
	var museum_after_reset: Dictionary = ((doc.get("map_info", {}) as Dictionary) \
		.get("museum", {}) as Dictionary)
	_expect(not museum_after_reset.has("passage"),
		"passage default reset removes the explicit declaration")
	seg.free()

	museum.free()
	_cleanup_fixture()
	if _failures.is_empty():
		print("[probe-plan-editor] PASS — pool, door, config, passage, wall, and undo persist correctly")
		quit(0)
	else:
		for failure in _failures:
			push_error("[probe-plan-editor] " + failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _has_cell(cells: Array, wanted: Vector2i) -> bool:
	# JSON numbers return as floats; compare spatial meaning, not Variant type.
	for value in cells:
		if value is Array and (value as Array).size() >= 2 \
				and int((value as Array)[0]) == wanted.x and int((value as Array)[1]) == wanted.y:
			return true
	return false


func _write_fixture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
	var fixture := {
		"map_info": {"name": FIXTURE_NAME, "museum": {}},
		"layers": {
			"structure": [
				["1", "1", "1", "1", "1", "1", "1"],
				["2", "1", "2", "1", "1", "1", "1"],
				["1", "1", "1", "1", "1", "1", "1"],
				["1", "1", "1", "1", "1", "1", "1"]],
			"interactables": [
				[" ", " ", " ", " ", " ", " ", " "],
				[" ", " ", " ", " ", " ", " ", " "],
				[" ", " ", " ", " ", " ", " ", " "],
				[" ", " ", " ", " ", " ", " ", " "]]
		}
	}
	var file := FileAccess.open(FIXTURE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()


func _read_fixture() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	return parsed if parsed is Dictionary else {}


func _cleanup_fixture() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
