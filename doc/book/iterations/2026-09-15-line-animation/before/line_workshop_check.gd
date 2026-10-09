extends Node3D
var failures: Array[String] = []
var checks := 0
class TestHand extends Node3D:
	var picked_up_ranged := false

func _ready() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[line-workshop] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var workshop = load("res://commons/artifacts/line_space_workshop/line_space_workshop.tscn").instantiate()
	add_child(workshop)
	await get_tree().create_timer(0.15).timeout
	check(workshop.rods.size() == 4, "Four count-led stations")
	for bay in 4:
		for mode in workshop.PRESETS[bay].size():
			var expected: int = bay + 2 if bay < 3 else (12 if mode == 3 else 6)
			check(workshop.rods[bay].size() == expected, "%s keeps its declared count %d" % [workshop.PRESETS[bay][mode], expected])
			var length_ok := true
			for r in workshop.rods[bay]:
				length_ok = length_ok and is_equal_approx(r.span, 0.8 if bay == 0 else 0.6)
			check(length_ok, "Every segment keeps the station's fixed length")
			workshop.buttons["NEXT_%d" % bay].pressed.emit()
	workshop.buttons["NEXT_3"].pressed.emit()
	var h = workshop.rods[3][0].endpoints()
	var v = workshop.rods[3][1].endpoints()
	check(is_equal_approx(h[0].z - v[0].z, 0.25), "Projected grid crossings separate by a quarter metre in depth")
	var rod = workshop.rods[0][0]
	var initial: Transform3D = rod.transform
	var hand := TestHand.new()
	add_child(hand)
	hand.global_position = rod.global_position
	rod.pick_up(hand)
	check(rod.is_picked_up(), "Real XRTools grab driver accepts a grab")
	workshop.buttons["RESET_0"].pressed.emit()
	check(workshop.rods[0][0] == rod and is_instance_valid(rod), "Reset cannot delete a held line")
	workshop.buttons["NEXT_0"].pressed.emit()
	check(workshop.modes[0] == 0, "Next cannot replace a held arrangement")
	hand.position += Vector3(0.13, 0.17, 0.25)
	hand.rotation_degrees.z = 32
	for i in 10: await get_tree().physics_frame
	check(rod.position.distance_to(initial.origin) > 0.1, "Hand movement displaces the held segment")
	rod.let_go(hand, Vector3.ONE * 3, Vector3.ONE)
	var released: Transform3D = rod.transform
	for i in 10: await get_tree().physics_frame
	check(not rod.is_picked_up() and rod.freeze and rod.transform.is_equal_approx(released), "Released segment holds its new position despite throw velocity")
	check(rod.collision_layer == 4 and rod.collision_mask == 0, "Released line remains detectable on the XR pickable layer")
	check(is_equal_approx(rod.endpoints()[0].distance_to(rod.endpoints()[1]), rod.span), "Grabbing preserves segment length")
	workshop.buttons["RESET_0"].pressed.emit()
	check(workshop.rods[0][0].transform.is_equal_approx(initial), "Reset restores authored endpoints")
	workshop.modes[0] = 5
	workshop.reset_bay(0)
	check(workshop.rods[0][0].endpoints()[1].is_equal_approx(workshop.rods[0][1].endpoints()[1]), "Drawing really joins the two endpoints")
	workshop.modes[0] = 4
	workshop.reset_bay(0)
	check(workshop.rods[0][0].endpoints()[1].distance_to(workshop.rods[0][1].endpoints()[1]) > 0.39, "Rails remain separated in world space")
	if "--capture" in OS.get_cmdline_user_args():
		var light := DirectionalLight3D.new()
		add_child(light)
		light.rotation_degrees = Vector3(-40,-30,0)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("162b32")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.65
		add_child(environment)
		var camera := Camera3D.new()
		add_child(camera)
		camera.position = Vector3(2.7,2.5,5.2)
		camera.look_at(Vector3(0,1.0,0))
		camera.fov = 52
		camera.make_current()
		for i in 20: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://ada_run/line-workshop-preview.png")
	var file := FileAccess.open("res://ada_run/line-workshop-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_verified":false},"  "))
	file.close()
	get_tree().quit(0 if failures.is_empty() else 1)
