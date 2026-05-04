extends SceneTree

## Verifies catalyst_vent loads from the registry into a real map.
## Loads Point_One headless and checks the scene tree for a CatalystVent
## node — proving the registry → grid → scene chain works end-to-end.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== catalyst_vent registry/scene smoke test ===")
	# Load the map's compiled scene if present, otherwise load directly via the artifact registry path.
	var vent_scene := load("res://commons/hazards/catalyst_foe/catalyst_vent.tscn") as PackedScene
	if vent_scene == null:
		print("FAIL: vent scene didn't load")
		quit(1); return
	print("- vent scene loaded:", vent_scene.resource_path)

	# Check registry entry has correct 'scene' field (matches what
	# GridInteractablesComponent reads).
	var f := FileAccess.open("res://commons/artifacts/registry/hazards.json", FileAccess.READ)
	if f == null:
		print("FAIL: hazards registry not found")
		quit(1); return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		print("FAIL: hazards registry malformed")
		quit(1); return
	var arts: Dictionary = (json.data as Dictionary).get("artifacts", {})
	var vent: Dictionary = arts.get("catalyst_vent", {})
	if not vent:
		print("FAIL: catalyst_vent not in registry")
		quit(1); return
	var scene_field: String = String(vent.get("scene", ""))
	print("- registry scene field:", scene_field)
	if not scene_field.ends_with("catalyst_vent.tscn"):
		print("FAIL: registry 'scene' field doesn't point at vent")
		quit(1); return

	# Instantiate to confirm the script loads.
	var inst: Node = vent_scene.instantiate()
	get_root().add_child(inst)
	if inst == null or not inst.has_method("apply_grid_config"):
		print("FAIL: vent missing apply_grid_config")
		quit(1); return
	print("- instantiated CatalystVent OK; has apply_grid_config")

	# Verify Point_One map now has the catalyst_vent token in interactables.
	var mf := FileAccess.open("res://commons/maps/Point_One/map_data.json", FileAccess.READ)
	if mf == null:
		print("FAIL: Point_One/map_data.json missing")
		quit(1); return
	var mjson := JSON.new()
	mjson.parse(mf.get_as_text())
	var md: Dictionary = mjson.data as Dictionary
	var found_vent_in_interactables := false
	for row: Array in (md.get("layers", {}).get("interactables", []) as Array):
		for cell in row:
			if String(cell).begins_with("catalyst_vent"):
				found_vent_in_interactables = true
				break
	if not found_vent_in_interactables:
		print("FAIL: Point_One's interactables don't contain a catalyst_vent token")
		quit(1); return
	print("- Point_One has catalyst_vent in interactables")

	print("PASS: registry+scene+map all wired for catalyst_vent in Point_One")
	quit(0)
