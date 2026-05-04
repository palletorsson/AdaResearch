extends SceneTree

## End-to-end test: load Catalyst_01_Primitives's map_data.json, find the
## becoming_catalyst token, parse it via the same path GridSystem uses,
## instantiate the catalyst, and verify the crystal lands with the right
## unlocked_modes (no voxel_editor) and active mode (primitives).
##
## (Pre-2026-05-03 the test maps wrapped the catalyst in a
## becoming_catalyst cage. We now place becoming_catalyst directly,
## matching Bracelet_Zoo's convention.)

const CATALYST_SCENE := preload("res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== catalyst pedestal token end-to-end test ===")

	# 1. Read the map directly.
	var map_path := "res://commons/maps/Catalyst_01_Primitives/map_data.json"
	var f := FileAccess.open(map_path, FileAccess.READ)
	if f == null:
		print("FAIL: map not found"); quit(1); return
	var json := JSON.new()
	json.parse(f.get_as_text())
	var md: Dictionary = json.data as Dictionary

	# 2. Find the becoming_catalyst token in interactables.
	var pedestal_token: String = ""
	var inter: Array = md.get("layers", {}).get("interactables", []) as Array
	for row in inter:
		for cell in row:
			var s := String(cell)
			if s.begins_with("becoming_catalyst"):
				pedestal_token = s
				break
		if not pedestal_token.is_empty():
			break
	print("- token: %s" % pedestal_token)
	if pedestal_token.is_empty():
		print("FAIL: no becoming_catalyst token in map"); quit(1); return

	# 3. Parse config_data the same way GridInteractablesComponent does.
	# Format: name:rot:y_offset#key:value#key:value...
	var config_data: Dictionary = {}
	var hash_idx := pedestal_token.find("#")
	if hash_idx >= 0:
		var tail := pedestal_token.substr(hash_idx + 1)
		for part in tail.split("#", false):
			var kv := part.split(":", false, 1)
			if kv.size() == 2:
				config_data[kv[0].strip_edges()] = kv[1].strip_edges()
			else:
				config_data[part.strip_edges()] = true
	print("- parsed config: %s" % config_data)
	if not config_data.has("shooting_only"):
		print("FAIL: shooting_only missing from parsed config — token grammar issue")
		quit(1); return

	# 4. Instantiate becoming_catalyst directly + apply config.
	var root := Node3D.new()
	root.name = "TestRoot"
	get_root().add_child(root)
	var crystal: Node = CATALYST_SCENE.instantiate()
	root.add_child(crystal)
	await get_root().get_tree().process_frame

	if crystal.has_method("apply_grid_config"):
		crystal.call("apply_grid_config", config_data)
	else:
		print("FAIL: catalyst has no apply_grid_config"); quit(1); return

	await get_root().get_tree().process_frame
	await get_root().get_tree().process_frame

	if crystal == null:
		print("FAIL: crystal not spawned"); quit(1); return

	var unlocked: Array = crystal.get("unlocked_modes")
	var current_idx: int = int(crystal.get("current_mode_index"))
	var current_mode_id: String = ""
	if current_idx >= 0 and current_idx < unlocked.size():
		current_mode_id = String(unlocked[current_idx])
	print("- crystal.unlocked_modes = %s" % [unlocked])
	print("- crystal.current_mode_index = %d  → mode_id = '%s'" % [current_idx, current_mode_id])

	# 6. Assert the right thing.
	var ok := true
	if "voxel_editor" in unlocked:
		print("FAIL: voxel_editor still in unlocked_modes after shooting_only — strip failed")
		ok = false
	if "wedge_placer" in unlocked:
		print("FAIL: wedge_placer still in unlocked_modes after shooting_only — strip failed")
		ok = false
	if not ("primitives" in unlocked):
		print("FAIL: primitives missing from unlocked_modes")
		ok = false
	if current_mode_id != "primitives":
		print("FAIL: current_mode_id is '%s', expected 'primitives'" % current_mode_id)
		ok = false

	if ok:
		print("PASS: token grammar parses correctly and crystal lands on primitives")
		quit(0)
	else:
		quit(1)
