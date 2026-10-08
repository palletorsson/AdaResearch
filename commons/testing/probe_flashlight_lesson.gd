extends "res://commons/testing/probe_color_recovery.gd"
## Actual museum, XRTools pickup callbacks with supplied motion, rendered light comparisons.
## Does not simulate tracked hands or establish headset comfort.
class SuppliedGrabber extends Node3D:
	var picked_up_ranged: bool = false

var samples: Dictionary = {}
var demo: Node3D
var head: Camera3D

func run() -> void:
	await museum("Color_Flashlight")
	for node in current_scene.find_children("*", "Node3D", true, false):
		if node.get_script() != null and node.get_script().resource_path.ends_with("flashlight_demo.gd"):
			demo = node
			break
	check(demo != null, "registered flashlight scene is present")
	if demo == null:
		quit(1)
		return
	head = current_scene.get("_cam")
	var player: CharacterBody3D = current_scene.get("_player")
	player.set_physics_process(false)
	var feel: Node = current_scene.get("_feel")
	if feel != null:
		feel.set_process(false)
	player.global_position += demo.to_global(Vector3(0, 1.65, 6)) - head.global_position
	head.look_at(demo.to_global(Vector3(0, 1.7, -2)))
	for frame in range(20):
		current_scene.call("_cull_artifacts")
		await process_frame
	check(demo.ground == "white", "authored map uses white receiving surface")
	var canvas: CSGBox3D = demo.get_node("Canvas")
	check(demo.mount == "standing" and canvas.use_collision, "floor installation has a solid receiving board")
	check(is_equal_approx(canvas.global_position.y - canvas.size.y * 0.5, 0.0), "entire board starts above the museum floor")
	var material: Material = canvas.material
	var names := ["RedFlashlight", "GreenFlashlight", "BlueFlashlight", "WhiteFlashlight"]
	var expected := [Color.RED, Color.GREEN, Color.BLUE, Color.WHITE]
	var lamps: Array[Node3D] = []
	var homes: Array[Transform3D] = []
	var grabber := SuppliedGrabber.new()
	current_scene.add_child(grabber)
	for i in range(4):
		var lamp: Node3D = demo.get_node(names[i])
		lamps.append(lamp)
		homes.append(lamp.global_transform)
		var light: SpotLight3D = lamp.get_node("SpotLight3D")
		check(light.light_color.is_equal_approx(expected[i]), "configured beam " + names[i])
		# Resolve after autoloads initialise; a static XRTools class reference in
		# a --script entry point compiles its singleton dependencies too early.
		check(lamp.get_script().resource_path.ends_with("objects/pickable.gd") and lamp.can_pick_up(grabber), "pickable " + names[i])
		grabber.global_transform = lamp.global_transform
		lamp.pick_up(grabber)
		check(lamp.is_picked_up(), "pickup callback " + names[i])
		var initial: Vector3 = lamp.global_position
		grabber.position.x += 0.2
		grabber.rotate_y(0.18)
		for frame in range(6):
			await physics_frame
		check(lamp.global_position.distance_to(initial) > 0.1, "held lamp follows supplied movement " + names[i])
		lamp.let_go(grabber, Vector3.ZERO, Vector3.ZERO)
		check(not lamp.is_picked_up() and lamp.freeze, "release holds lamp in place " + names[i])
		lamp.global_transform = homes[i]
		print("LAMP_HEIGHT ", names[i], " ", lamp.global_position.y)
	var ray := PhysicsRayQueryParameters3D.create(head.global_position, head.global_position - Vector3.UP * 4, 1)
	ray.exclude = [player.get_rid()]
	var ground: Dictionary = current_scene.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not ground.is_empty(), "visitor has supporting floor at viewing position")
	if not ground.is_empty():
		check(lamps.all(func(lamp): return lamp.global_position.y - ground.position.y >= 0.8 and lamp.global_position.y - ground.position.y <= 1.5), "lamp handles begin within standing reach")
	print("DEMO_TRANSFORM ", demo.global_transform)
	if "--shots" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://ada_run/flashlight_lesson_shots")
		await shot("arrival")
		# Fixture-only isolation: the shipped lamps have no on/off UI.
		for lamp in lamps:
			lamp.get_node("SpotLight3D").visible = false
		await shot("ambient")
		lamps[0].get_node("SpotLight3D").visible = true
		await shot("red")
		lamps[1].get_node("SpotLight3D").visible = true
		await shot("red_green")
		lamps[2].get_node("SpotLight3D").visible = true
		await shot("rgb")
		for lamp in lamps:
			lamp.get_node("SpotLight3D").visible = true
		await shot("returned")
		# Repeat the book's actual gesture, with every lamp still switched on.
		grabber.global_transform = lamps[0].global_transform
		lamps[0].pick_up(grabber)
		grabber.rotate_y(PI * 0.5)
		for frame in range(12):
			await physics_frame
		await shot("red_aimed_away")
		check(samples.returned.r > samples.red_aimed_away.r + 0.015, "aiming a held red lamp away removes its red contribution")
		grabber.global_transform = homes[0]
		for frame in range(12):
			await physics_frame
		lamps[0].let_go(grabber, Vector3.ZERO, Vector3.ZERO)
		await shot("red_aimed_back")
		check(samples.red_aimed_back.r > samples.red_aimed_away.r + 0.015, "aiming it back restores the contribution")
		check(samples.red.r > samples.ambient.r + 0.015, "red beam changes received red light")
		check(samples.red_green.g > samples.red.g + 0.015, "overlapping green adds a visible green contribution")
		check(samples.rgb.b > samples.red_green.b + 0.015, "blue contributes to overlap")
	check(canvas.material == material and canvas.material.albedo_color.is_equal_approx(Color(0.95,0.95,0.95,1)), "receiving material unchanged throughout comparisons")
	var report := {"checks": checks, "failures": failures, "samples": samples, "xr_input": "supplied grabber, not tracked hands", "headset_tested": false}
	var file := FileAccess.open("res://ada_run/probe_flashlight_lesson.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("FLASHLIGHT_LESSON ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func shot(label: String) -> void:
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png("res://ada_run/flashlight_lesson_shots/" + label + ".png")
	var pixel := head.unproject_position(demo.to_global(Vector3(-0.5, 0.9, -1.94)))
	var value := Color(0,0,0,0)
	for x in range(-4,5):
		for y in range(-4,5):
			value += picture.get_pixel(clampi(int(pixel.x)+x,0,picture.get_width()-1),clampi(int(pixel.y)+y,0,picture.get_height()-1))
	value /= 81.0
	samples[label] = {"r": value.r, "g": value.g, "b": value.b}
