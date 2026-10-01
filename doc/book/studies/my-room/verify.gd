extends "res://supplied/verify_tools.gd"
## Headless checks of the room. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed.
## The checks are made on the room as it is shipped, with the example guest as
## its only guest and room_look.gd unchanged. With guests of your own in GUESTS,
## or a look of your own, some checks will say so and fail: that is the check
## working, not the room breaking.

const RoomLook := preload("res://room_look.gd")
const KitLook := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const EXAMPLE := "res://guests/example/example.tscn"

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func open() -> Node3D:
	var room: Node3D = load("res://room.tscn").instantiate()
	root.add_child(room)
	await frames(2)
	await physics_frames(20)
	return room

func close(room: Node) -> void:
	room.free()
	await frames(1)

func run() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "My room" and ProjectSettings.get_setting("application/run/main_scene") == "res://room.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility" and ProjectSettings.get_global_class_list().is_empty(),
		"the project is named My room, its main scene is room.tscn, its renderer Compatibility, and it lists no named class")
	var actions_ok := true
	for action: String in ["move_left", "move_right", "move_forward", "move_backward", "pause", "drop", "look", "jump", "switch_camera"]:
		actions_ok = actions_ok and InputMap.has_action(action)
	check(actions_ok, "the Input Map has the nine actions of the kit base")
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):    # the editor writes one beside every script it has seen
			supplied.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"], "supplied/ holds the kit base's 15 files: %s" % [supplied])
	var same := true
	var room_named: Dictionary = (RoomLook as Script).get_script_constant_map()
	var kit_named: Dictionary = (KitLook as Script).get_script_constant_map()
	for role: String in ["SKY", "GROUND", "BODY", "SECOND", "THIRD", "BONE", "LINE", "GHOST", "INK", "SHADE", "SUN_TURN", "SUN_ENERGY", "AMBIENT_ENERGY", "SKY_TOP", "FILL", "SHADOW_BLUR"]:
		same = same and room_named[role] == kit_named[role]
	check(same, "room_look.gd, the room's own look, starts with the colours and the light of supplied/look.gd")
	var paint := RoomLook.paint(RoomLook.BODY)
	check(paint is StandardMaterial3D and paint.albedo_color.is_equal_approx(RoomLook.BODY) and is_equal_approx(paint.roughness, 0.8), "room_look.gd: paint(BODY) returns a material with BODY as its albedo")

	# The room as shipped.
	var errors_before := errors.size()
	var room := await open()
	var sky: WorldEnvironment = room.get_node_or_null("Sky")
	check(sky != null and sky.environment.background_mode == Environment.BG_SKY and (sky.environment.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color.is_equal_approx(RoomLook.SKY), "the room's environment has SKY as its background")
	check(room.get_node("Floor").material_override.albedo_color.is_equal_approx(RoomLook.GROUND) and room.get_node_or_null("Sun") is DirectionalLight3D and room.get_node("Sun").shadow_enabled,
		"its floor's material is GROUND, and it has a sun with shadows")
	check(room.GUESTS == [EXAMPLE], "GUESTS, the one list to edit, holds the example guest and nothing else: %s" % [room.GUESTS])
	check(room.guests.size() == 1 and near(room.guests[0].global_position, room.place(1)) and room.guests[0].scene_file_path == EXAMPLE and room.said == ["My room: place 1 is " + EXAMPLE],
		"the room loads with the example guest at place 1, %s, and says so: %s" % [room.place(1), room.said])
	var places_ok := true
	var number := 1
	for row in room.ROWS:
		for column in room.COLUMNS:
			places_ok = places_ok and near(room.place(number), Vector3(-7.0 + 2.0 * column, 0.0, -4.0 * row))
			number += 1
	check(places_ok and room.COLUMNS * room.ROWS == 40, "there are 40 places: 8 in a row, 2 m apart, and 5 rows, 4 m apart; place 1 at %s, place 40 at %s" % [room.place(1), room.place(40)])
	var walker: CharacterBody3D = room.get_node("Walker")
	var fixed: Camera3D = room.get_node("Camera3D")
	check(near(walker.global_position, room.place(1) + Vector3(0.0, 0.0, 4.0), 0.01) and walker.is_on_floor() and root.get_camera_3d() == walker.get_node("Eyes"),
		"the walker starts 4 m in front of place 1, on the floor, facing it, and the room is seen through its Eyes")
	await press("switch_camera")
	var second := root.get_camera_3d()
	await press("switch_camera")
	check(second == fixed and root.get_camera_3d() == walker.get_node("Eyes"), "switch_camera changes to the fixed camera above the room, and back")
	var marble: RigidBody3D = room.get_node("Marble")
	await press("drop")
	var dropped_at: Vector3 = marble.global_position
	var rests := await settle(marble)
	check(flat(dropped_at - (walker.global_position + Vector3(0.0, 0.0, -1.0))).length() < 0.05 and dropped_at.y > 1.5 and absf(rests.y - 0.1) < 0.01,
		"M drops the marble 1 m in front of the walker, from above its head; it comes to rest on the floor at %.2f m" % rests.y)
	var how := await walk(walker, [room.place(1)])
	var gap: float = flat(walker.global_position - room.place(1)).length()
	check(how == "blocked" and absf(gap - 0.55) < 0.05, "the walker's autopilot, sent to place 1, is stopped by the example guest's collider: \"%s\", %.2f m from the middle of the place" % [how, gap])
	measured["walk_to_place_1"] = {"ended": how, "metres_from_the_place": snappedf(gap, 0.001)}
	how = await walk(walker, [room.place(2) + Vector3(0.0, 0.0, 1.0), room.place(2)])
	check(how == "arrived", "sent to place 2, which is free, it arrives: \"%s\"" % how)
	await frames(180)
	check(errors.size() == errors_before, "the room has run more than 180 frames and Godot logged no error: %s" % [errors.slice(errors_before)])

	# Other lists, given to the same room.
	room.place_guests([EXAMPLE, EXAMPLE])
	await frames(2)
	check(room.guests.size() == 2 and near(room.guests[1].global_position, room.place(2)) and near(room.place(2), room.place(1) + Vector3(2.0, 0.0, 0.0)),
		"with a second copy of the example in the list, the second stands at place 2, 2 m to the right of place 1")
	how = await walk(walker, [room.place(2)])
	check(how == "blocked", "and now the walker sent to place 2 is stopped there: \"%s\"" % how)
	errors_before = errors.size()
	var said_before: int = room.said.size()
	room.place_guests([EXAMPLE, "res://guests/nobody/nobody.tscn", EXAMPLE])
	await frames(60)
	var line := "My room: no scene at res://guests/nobody/nobody.tscn. Check the line in GUESTS against the folder in guests/. The room goes on without it"
	check(room.said.slice(said_before).has(line) and printed.has(line) and errors.size() == errors_before, "a path with no scene behind it prints one plain line, and Godot logs no error: %s" % line)
	check(room.guests.size() == 2 and near(room.guests[1].global_position, room.place(2)), "the room goes on: the guest after the bad path stands at the next free place, place 2, and the room ran 60 more frames")
	write("user://flat.tscn", "[gd_scene format=3]\n\n[node name=\"Flat\" type=\"Control\"]\n")
	write("user://broken.tscn", "[gd_scene format=3]\n\n[node name=\"Broken\" type=\"Node3D\"\n")
	said_before = room.said.size()
	room.place_guests(["user://flat.tscn", "user://broken.tscn", EXAMPLE])
	await frames(2)
	var lines: Array = room.said.slice(said_before)
	check(lines.size() == 3 and lines[0].contains("its first node is a Control") and lines[1].contains("does not load as a scene") and room.guests.size() == 1,
		"a scene whose first node is not a Node3D, and a scene file that is broken, get a line each and no place; the example still stands at place 1")
	DirAccess.remove_absolute("user://flat.tscn")
	DirAccess.remove_absolute("user://broken.tscn")
	var many := []
	for i in 42:
		many.append(EXAMPLE)
	said_before = room.said.size()
	room.place_guests(many)
	await frames(2)
	lines = room.said.slice(said_before)
	check(room.guests.size() == 40 and near(room.guests[39].global_position, room.place(40)) and lines.size() == 41 and lines[40].begins_with("My room has 40 places and all are taken"),
		"42 guests for 40 places: 40 stand, the last at place 40, and one line says the rest were not placed: %s" % lines[40])
	check(CheckGuest.outside("res://guests/example/").is_empty() and CheckGuest.class_names("res://guests/example/").is_empty(), "the example guest names nothing outside its folder and declares no class_name")
	await close(room)
