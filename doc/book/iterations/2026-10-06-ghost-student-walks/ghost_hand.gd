extends SceneTree
# The ghost student's hand on desktop. I place the supplied player where I would have
# walked and turn it where I would have looked; the picking itself is the real E key,
# sent through Godot's input, so the starter's own player, ray and grabber do the work.

var room: Node3D
var player: CharacterBody3D
var study: Node3D
var out := "hand"
var room_name := "coords"

func _initialize() -> void:
	var scene := "res://ghost_coords.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.substr(8)
		if a.begins_with("--out="):
			out = a.substr(6)
		if a.begins_with("--room="):
			room_name = a.substr(7)
	room = load(scene).instantiate()
	root.add_child(room)
	current_scene = room
	for i in 60:
		await physics_frame
	player = room.player
	study = room.get_node("Study")
	say("SCENE " + scene + "   player " + player.get_class() + " at " + str(player.global_position))
	match room_name:
		"coords":
			await coords()
		"lines":
			await lines()
		"trace":
			await trace()
		"res":
			await res()
	quit()

func say(s: String) -> void:
	print(s)

func key(code: Key) -> void:
	say("   key " + OS.get_keycode_string(code) + " down at physics frame " + str(Engine.get_physics_frames()) + ", process frame " + str(Engine.get_process_frames()))
	var down := InputEventKey.new()
	down.physical_keycode = code
	down.keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	for i in 2:
		await physics_frame
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	for i in 2:
		await physics_frame

func key_hold(code: Key, frames: int) -> void:
	var down := InputEventKey.new()
	down.physical_keycode = code
	down.keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	for i in frames:
		await process_frame
	say("   while held: ui_accept pressed? " + str(Input.is_action_pressed("ui_accept")))
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	for i in frames:
		await process_frame

func ray_report() -> void:
	await physics_frame
	var start: Vector3 = player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - player.camera.global_basis.z * 2.5, 5)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		say("   ray from " + str(start) + ": nothing within 2.5 m")
	else:
		say("   ray from " + str(start) + " hits " + str(hit.collider.name) + " (" + hit.collider.get_class() + ") at " + str(hit.position) + "  pickable? " + str(hit.collider is XRToolsPickable))

func stand_and_look(feet: Vector3, target: Vector3) -> void:
	player.global_position = feet
	var eye := feet + Vector3(0, 1.65, 0)
	var flat := Vector3(target.x - eye.x, 0, target.z - eye.z)
	player.rotation.y = atan2(-flat.x, -flat.z)
	player.camera.rotation.x = atan2(target.y - eye.y, flat.length())
	for i in 3:
		await physics_frame

func walk(by: Vector3, steps: int) -> void:
	for i in steps:
		player.global_position += by / steps
		await physics_frame

func tilt(by: float, steps: int) -> void:
	for i in steps:
		player.camera.rotation.x += by / steps
		await physics_frame

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("res://../" + out + "_" + name + ".png")

func approach(body: Node3D) -> void:
	var p := body.global_position
	await stand_and_look(Vector3(p.x, 0, p.z + 1.4), p)

func coords() -> void:
	var point: Node3D = study.point
	say("BEFORE  " + study.readout.text.replace("\n", "  |  "))
	await approach(point)
	await shot("1_before")
	await key(KEY_E)
	say("after E: picked up? " + str(point.is_picked_up()) + "   point at " + str(point.global_position))
	await walk(Vector3(0.5, 0, 0), 30)
	await tilt(0.3, 20)
	await walk(Vector3(0, 0, -0.3), 20)
	say("CARRIED " + study.readout.text.replace("\n", "  |  "))
	await shot("2_carried")
	await key(KEY_E)
	say("after second E: picked up? " + str(point.is_picked_up()))
	var left := point.global_position
	await walk(Vector3(-1.0, 0, 1.0), 30)
	say("RELEASED, walked away: point moved? " + str(point.global_position != left) + "  " + study.readout.text.replace("\n", "  |  "))
	await stand_and_look(player.global_position, point.global_position)
	await shot("3_released")

func lines() -> void:
	var a: Node3D = study.point
	var b: Node3D = study.point_b
	for pair in [["A", a], ["B", b]]:
		var who: String = pair[0]
		pair[1].picked_up.connect(func(_p): say("      signal: " + who + " picked_up  (physics frame " + str(Engine.get_physics_frames()) + ")"))
		pair[1].dropped.connect(func(_p): say("      signal: " + who + " dropped  (physics frame " + str(Engine.get_physics_frames()) + ")"))
	say("BEFORE  " + study.readout.text.replace("\n", "  |  "))
	await approach(a)
	await shot("1_before")
	await key(KEY_E)
	say("after E: A picked up? " + str(a.is_picked_up()) + "  B picked up? " + str(b.is_picked_up()))
	await walk(Vector3(-0.4, 0, 0), 20)
	await tilt(0.25, 15)
	say("CARRYING A  " + study.readout.text.replace("\n", "  |  "))
	await shot("2_carried")
	await key(KEY_E)
	await walk(Vector3(0, 0, 0.8), 20)
	await stand_and_look(player.global_position, (a.global_position + b.global_position) * 0.5)
	say("RELEASED A  " + study.readout.text.replace("\n", "  |  "))
	await shot("3_released")
	await approach(b)
	say("   B is at " + str(b.global_position) + ", A at " + str(a.global_position))
	await ray_report()
	await key(KEY_E)
	say("after E at B: B picked up? " + str(b.is_picked_up()))
	await walk(Vector3(0, 0, -0.6), 20)
	await key(KEY_E)
	await stand_and_look(Vector3(0.4, 0, b.global_position.z + 2.2), (a.global_position + b.global_position) * 0.5)
	say("RELEASED B  " + study.readout.text.replace("\n", "  |  "))
	await shot("4_b_moved")

func trace() -> void:
	var point: Node3D = study.point
	var saved := "user://ada_student_trace.scn"
	say("saved trace already on disk before I draw? " + str(FileAccess.file_exists(saved)))
	await approach(point)
	await key(KEY_E)
	say("after E: picked up? " + str(point.is_picked_up()))
	await walk(Vector3(0.6, 0, 0), 40)
	await tilt(0.35, 30)
	var held: int = study.positions.size()
	for i in 90:
		await physics_frame
	say("a one-second pause added " + str(study.positions.size() - held) + " positions")
	await walk(Vector3(-0.6, 0, 0), 40)
	say("DRAWN  " + study.readout.text.replace("\n", "  |  "))
	await shot("1_drawn")
	await key(KEY_E)
	for i in 4:
		await process_frame
	say("after release: picked up? " + str(point.is_picked_up()) + "   saved? " + str(FileAccess.file_exists(saved)))
	if FileAccess.file_exists(saved):
		var drawing: Node3D = load("res://ghost/trace/trace_archive.gd").load_drawing()
		say("archive reads back: " + ("nothing" if drawing == null else str(drawing.get_meta("positions").size()) + " positions, " + str(drawing.get_child_count()) + " segments"))
		if drawing:
			drawing.free()
	await stand_and_look(Vector3(0, 0, point.global_position.z + 2.2), study.to_global(Vector3(0, 1.3, 0)))
	await shot("2_released")

func res() -> void:
	var held: Node3D = study.point
	var other: Node3D = study.comparison
	say("BEFORE  " + study.message.text)
	await approach(held)
	await key(KEY_E)
	say("after E: picked up? " + str(held.is_picked_up()))
	var t := 0
	while t < 203:
		await physics_frame
		t += 1
	say("HELD ~2.25 s  " + study.message.text + "   comparison: rings " + str(other.sphere.rings) + " segments " + str(other.sphere.radial_segments))
	await shot("1_held")
	await key(KEY_E)
	await stand_and_look(Vector3(0, 0, other.global_position.z + 1.6), study.to_global(Vector3(0, 1.12, 0)))
	await shot("2_released")
	await key(KEY_ENTER)
	say("after a quick Enter (ui_accept): " + study.message.text)
	await key_hold(KEY_ENTER, 6)
	say("after Enter held six frames: " + study.message.text)
