extends SceneTree
## DOES F ACTUALLY THROW ONE IN A REAL MAP (2026-08-27, Palle asking a second
## time: "how do I shoot the mushrooms?").
##
## probe_mushroom_hand pressed F in an empty tree with no other input handler in
## it and reported that the key reaches the autoload. That is a bench. In a real
## map the event passes DesktopPlayer._input, the XR-Tools pointer, any UI on a
## CanvasLayer and the map's own handlers first, and _unhandled_input only ever
## sees what none of them consumed. If any of them calls set_input_as_handled()
## broadly, F never arrives and nothing anywhere reports it.
##
## So: load Point_One through the project's own catalog, press F, and count.
const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const MAP := "Point_One"
const TXT := "res://ada_run/fire_in_map.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _press(code: int) -> void:
	var d := InputEventKey.new()
	d.keycode = code
	d.physical_keycode = code
	d.pressed = true
	Input.parse_input_event(d)
	await process_frame
	var u := InputEventKey.new()
	u.keycode = code
	u.physical_keycode = code
	u.pressed = false
	Input.parse_input_event(u)
	await process_frame

func _run() -> void:
	var gm: Node = get_root().get_node_or_null("GameManager")
	var hand: Node = get_root().get_node_or_null("MushroomHand")
	if gm == null or hand == null:
		_say("FAIL no GameManager (%s) or no MushroomHand (%s)" % [str(gm != null), str(hand != null)])
		var f0 := FileAccess.open(TXT, FileAccess.WRITE)
		f0.store_string("\n".join(PackedStringArray(_l)) + "\n"); f0.close()
		quit(1); return

	if change_scene_to_file(CATALOG) != OK:
		_say("FAIL could not load the catalog"); quit(1); return
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		_say("FAIL no catalog"); quit(1); return
	if not bool(catalog.call("load_map_fresh", MAP)):
		_say("FAIL the map would not load"); quit(1); return
	await create_timer(3.0).timeout

	_say("F IN A REAL MAP (%s, through the project's own catalog)" % MAP)
	_say("  current_scene is %s" % String(current_scene.name))
	var cam: Camera3D = get_root().get_camera_3d()
	_say("  a camera to throw from: %s" % ("yes" if cam != null else "NO — nothing to aim"))
	gm.call("refill_mushrooms")
	var before: int = int(gm.get("mushrooms"))
	var bait_before: int = get_nodes_in_group("spider_bait").size()
	_say("  mushrooms %d, bait already on the floor %d" % [before, bait_before])

	hand.set("_cool", 0.0)
	await _press(KEY_F)
	await create_timer(0.4).timeout
	var after: int = int(gm.get("mushrooms"))
	_say("  after pressing F: %d" % after)

	# and the middle mouse, the other desktop binding
	hand.set("_cool", 0.0)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_MIDDLE
	m.pressed = true
	Input.parse_input_event(m)
	await process_frame
	await create_timer(0.4).timeout
	var after_mmb: int = int(gm.get("mushrooms"))
	_say("  after the middle mouse: %d" % after_mmb)

	await create_timer(2.5).timeout
	var bait_after: int = get_nodes_in_group("spider_bait").size()
	_say("  mushrooms landed as bait: %d (was %d)" % [bait_after, bait_before])

	var fails: Array = []
	if after != before - 1:
		fails.append("F did not throw one — something between the OS and the autoload ate it")
	if after_mmb != after - 1:
		fails.append("the middle mouse did not throw one")
	if bait_after <= bait_before:
		fails.append("nothing landed on the floor")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("F and the middle mouse both throw one, in a real map"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)
