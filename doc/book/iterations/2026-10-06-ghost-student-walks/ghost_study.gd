extends SceneTree
# The ghost student in the starter. A run is a list of acts, given as --do=act;act;...
#   stand:x,z,tx,ty,tz   put the supplied player at feet (x, 0, z), looking at (tx, ty, tz)
#   walk:dx,dz,s         walk that way for s seconds at 2.5 m/s (WASD speed): the player's own
#                        capsule and move_and_slide(); only the velocity comes from me
#   key:NAME             press a key like a person (held six frames), e.g. key:E, key:R
#   hold:NAME,frames     hold a key down for that many physics frames, then let go
#   turn:yaw,pitch       add to the player's yaw and the camera's pitch (radians), in steps
#   wait:n               let n physics frames pass
#   shot:name            save what the camera sees
#   labels               print every Label3D a study made, and where it is
#   where                print the player's feet and the held object, if any

var room: Node3D
var player: CharacterBody3D
var out := "study"
var study_name := "Study"

func _initialize() -> void:
	var scene := ""
	var acts := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.substr(8)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--do="):
			acts = a.substr(5)
	room = load(scene).instantiate()
	root.add_child(room)
	current_scene = room
	for i in 45:
		await physics_frame
	player = room.player
	print("SCENE ", scene)
	for act in acts.split(";", false):
		await perform(act.strip_edges())
	for i in 3:
		await process_frame
	quit()

func perform(act: String) -> void:
	var name := act.get_slice(":", 0)
	var arg := act.substr(name.length() + 1)
	var n := arg.split_floats(",") if arg != "" and "-0123456789.".contains(arg[0]) else PackedFloat64Array()
	match name:
		"stand":
			player.global_position = Vector3(n[0], 0, n[1])
			look_at_point(Vector3(n[2], n[3], n[4]))
			for i in 3:
				await physics_frame
		"walk":
			await walk(Vector2(n[0], n[1]), n[2])
		"key":
			await press(arg, 6)
		"hold":
			await press(arg.get_slice(",", 0), int(arg.get_slice(",", 1)))
		"turn":
			var frames := 20 if n.size() < 3 else int(n[2])
			for i in frames:
				player.rotation.y += n[0] / frames
				player.camera.rotation.x += n[1] / frames
				await physics_frame
		"loop":
			# the mouse moving in a circle: yaw and pitch go round once, back to where they began
			var yaw0 := player.rotation.y
			var pitch0: float = player.camera.rotation.x
			var frames := int(round(n[1] * Engine.physics_ticks_per_second))
			for i in frames + 1:
				var t := TAU * i / frames
				player.rotation.y = yaw0 + n[0] * sin(t)
				player.camera.rotation.x = pitch0 + n[0] * (1.0 - cos(t))
				await physics_frame
		"var":
			var v = room.get_node(study_name).get(arg)
			if v is Array:
				var seen := {}
				for e in v:
					seen[e] = true
				print("   ", arg, ": ", v.size(), " entries, ", seen.size(), " distinct")
			else:
				print("   ", arg, " = ", v)
		"approach":
			# stand 1.3 m in front of one of the study's bodies, looking at it
			var body: Node3D = study_body(arg)
			var at := body.global_position
			player.global_position = Vector3(at.x, 0, at.z + 1.3)
			look_at_point(at)
			for i in 3:
				await physics_frame
		"carry_to":
			# while holding: aim the hold so that it lands exactly on a place (study coordinates)
			await carry_to(room.get_node(study_name).to_global(Vector3(n[0], n[1], n[2])))
		"carry_mid":
			# while holding: carry it to the midpoint of two other bodies of the study, e.g. carry_mid:a,c
			var p: Node3D = study_body(arg.get_slice(",", 0))
			var q: Node3D = study_body(arg.get_slice(",", 1))
			await carry_to((p.global_position + q.global_position) * 0.5)
		"pos":
			for v in arg.split(","):
				var body: Node3D = study_body(v)
				print("   ", v, " local ", body.position.snapped(Vector3.ONE * 0.0001), "  world ", body.global_position.snapped(Vector3.ONE * 0.0001))
		"edge_on", "face_on":
			# stand where the eye lies in the plane of a, b, c (edge_on), or on its normal (face_on)
			var a := study_body("a").global_position
			var b := study_body("b").global_position
			var c := study_body("c").global_position
			var normal := (b - a).cross(c - a).normalized()
			var centre := (a + b + c) / 3.0
			var dist := 1.8 if n.is_empty() else n[0]
			var feet: Vector3
			if name == "edge_on":
				var across := normal.cross(Vector3.UP).normalized()
				var flat_n := Vector3(normal.x, 0, normal.z)
				var lift := 1.65 - centre.y
				feet = centre + across * dist - flat_n * (lift * normal.y / flat_n.length_squared())
			else:
				var flat := Vector3(normal.x, 0, normal.z).normalized()
				if flat.z < 0:
					flat = -flat
				feet = centre + flat * dist
			player.global_position = Vector3(feet.x, 0, feet.z)
			look_at_point(centre)
			for i in 3:
				await physics_frame
			var eye: Vector3 = player.camera.global_position
			print("   ", name, ": eye is ", snappedf(absf((eye - centre).dot(normal)), 0.0001), " m off the triangle's plane")
		"study":
			study_name = arg
		"sample":
			# read the moving cube every n[1] seconds for n[0] seconds of the study's own clock
			var study := room.get_node(study_name)
			var next := 0.0
			var start: float = study.elapsed
			var rows := PackedStringArray()
			while true:
				var age: float = study.elapsed - start
				if age + 0.0001 >= next:
					var cube: Node3D = study.cube
					rows.append("t=%.2f y=%.3f turn=%.0f° scale=%.2f" % [study.elapsed, cube.position.y, fposmod(rad_to_deg(cube.rotation.y), 360.0), cube.scale.x])
					next += n[1]
				if age >= n[0]:
					break
				await process_frame
			print("   ", "  |  ".join(rows))
		"exists":
			print("   ", arg, (" exists, " + str(FileAccess.get_file_as_bytes(arg).size()) + " bytes") if FileAccess.file_exists(arg) else " does not exist")
		"wait":
			for i in int(n[0]):
				await physics_frame
		"shot":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("res://../shots/" + out + "_" + arg + ".png")
		"labels":
			for label in room.find_children("*", "Label3D", true, false):
				if label.get_parent() != room:
					print("   LABEL ", label.get_parent().name, "/", label.name, " at ", label.global_position.snapped(Vector3.ONE * 0.01), ": ", label.text.replace("\n", " | "))
		"where":
			var held = player.grabber.picked_up_object
			print("   feet ", player.global_position.snapped(Vector3.ONE * 0.001), "   holding ", "nothing" if not is_instance_valid(held) else str(held.name) + " at " + str(held.global_position.snapped(Vector3.ONE * 0.001)))

func study_body(name: String) -> Node3D:
	var study := room.get_node(study_name)
	if name.is_valid_int():
		return study.get("handles")[int(name)]
	return study.get(name)

func carry_to(target: Vector3) -> void:
	var off: Vector3 = player.grabber.position
	var lo := -1.4
	var hi := 1.4
	for i in 60:
		var mid := (lo + hi) * 0.5
		var y := (Basis(Vector3.RIGHT, mid) * off).y
		if 1.65 + y < target.y:
			lo = mid
		else:
			hi = mid
	var pitch := (lo + hi) * 0.5
	var basis := Basis(Vector3.UP, player.rotation.y) * Basis(Vector3.RIGHT, pitch)
	var eye := target - basis * off
	player.global_position = Vector3(eye.x, 0, eye.z)
	player.camera.rotation.x = pitch
	for i in 8:
		await physics_frame

func look_at_point(target: Vector3) -> void:
	var eye := player.global_position + Vector3(0, 1.65, 0)
	var flat := Vector3(target.x - eye.x, 0, target.z - eye.z)
	player.rotation.y = atan2(-flat.x, -flat.z)
	player.camera.rotation.x = atan2(target.y - eye.y, flat.length())

func walk(direction: Vector2, seconds: float) -> void:
	var start := player.global_position
	player.set_physics_process(false)
	var heading := Vector3(direction.x, 0, direction.y).normalized()
	var steps := int(round(seconds * Engine.physics_ticks_per_second))
	var dt := 1.0 / Engine.physics_ticks_per_second
	for i in steps:
		await physics_frame
		player.velocity.x = heading.x * 2.5
		player.velocity.z = heading.z * 2.5
		if not player.is_on_floor():
			player.velocity.y -= 9.8 * dt
		player.move_and_slide()
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	var moved := player.global_position - start
	print("   walked from ", start.snapped(Vector3.ONE * 0.001), " to ", player.global_position.snapped(Vector3.ONE * 0.001), ": ", snappedf(Vector2(moved.x, moved.z).length(), 0.001), " m of ", snappedf(2.5 * seconds, 0.001), " m asked")

func press(key_name: String, frames: int) -> void:
	var code := OS.find_keycode_from_string(key_name)
	var down := InputEventKey.new()
	down.physical_keycode = code
	down.keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	for i in frames:
		await process_frame
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	for i in frames:
		await process_frame
