extends SceneTree
## Isolated wearer: never writes progression or the player's appearance save.
const Wardrobe := preload("res://commons/player/costume_wardrobe.gd")
const Mirror := preload("res://commons/artifacts/super_drag_mirror/super_drag_mirror.gd")
const Outfits := preload("res://commons/player/super_drag_outfit.gd")
var failures: Array[String] = []
var checks: int = 0

class ProgressStub extends Node:
	signal sequence_completed(sequence: String)
	func is_sequence_completed(_id: String) -> bool:
		return false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("DRAG CHECK: " + label)

func run() -> void:
	root.size = Vector2i(1200, 900)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("242136")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("dde2ff")
	env.environment.ambient_light_energy = 0.7
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 1.4
	stage.add_child(sun)
	var head := Camera3D.new()
	head.name = "TestHead"
	head.position = Vector3(0, 1.65, 2.3)
	stage.add_child(head)
	head.current = true
	var left := Node3D.new()
	left.position = Vector3(-0.42, 1.15, 2.15)
	stage.add_child(left)
	var right := Node3D.new()
	right.position = Vector3(0.44, 1.35, 2.10)
	stage.add_child(right)
	var stub := ProgressStub.new()
	stage.add_child(stub)
	var wardrobe := Wardrobe.new()
	wardrobe.mount_path = stage.get_path()
	wardrobe.head_path = head.get_path()
	wardrobe.manager_path = stub.get_path()
	wardrobe.appearance_save_path = "res://ada_run/probe_super_drag_appearance.cfg"
	# Avoid restoring a previous probe's choice; enable persistence only below.
	var save_path: String = wardrobe.appearance_save_path
	wardrobe.appearance_save_path = ""
	stage.add_child(wardrobe)
	var mirror := Mirror.new()
	mirror.viewer_path = head.get_path()
	mirror.wardrobe_path = wardrobe.get_path()
	stage.add_child(mirror)
	for i in range(12):
		await process_frame
	check(is_instance_valid(wardrobe.costume), "actual player costume exists")
	wardrobe.costume.call("mount_on", head, left, right)
	wardrobe.give("primitives", true)
	var old_stage := int(wardrobe.costume.get("stage"))
	check(not wardrobe.choose_outfit("invalid", false), "unknown outfit rejected")
	var shoot := OS.get_cmdline_user_args().has("--shots")
	if shoot:
		DirAccess.make_dir_recursive_absolute("res://ada_run/super_drag_shots")
	for i in range(Outfits.LOOKS.size()):
		# Follow the desktop/XR pointer path through the area's press handler.
		var area: Node3D = mirror.buttons[1].get_node("InteractableAreaButton")
		XRToolsPointerEvent.pressed(right, area, area.global_position)
		XRToolsPointerEvent.released(right, area, area.global_position)
		for frame in range(10):
			await process_frame
		check(wardrobe.costume.get("outfit_id") == Outfits.LOOKS[i], "button wears " + Outfits.LOOKS[i])
		check(int(wardrobe.costume.get("stage")) == old_stage, "dress preserves earned stage")
		check(wardrobe.worn() == ["primitives"], "dress preserves trophies")
		var outfit: Node3D = wardrobe.costume.get("drag_outfit")
		check(outfit.visible and not wardrobe.costume.get("_garment").visible, "selected outfit replaces base cloth")
		check(not head.get_cull_mask_value(19), "own head excluded from first person")
		check(mirror.reflection.get_cull_mask_value(19), "mirror includes dressed head")
		check(not mirror.reflection.get_cull_mask_value(20), "mirror excludes recursive panes")
		var glove: Node3D = outfit.get("gloves")[1]
		right.position.x += 0.05
		for f in range(5):
			await process_frame
		check(glove.global_position.distance_to(right.global_position) < 0.015, "sleeve follows right hand")
		if shoot:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/super_drag_shots/%s.png" % Outfits.LOOKS[i])
	# Check projection with an off-centre head: mirror corners must land on the
	# fixed viewport corners. This catches wrong frustum offset and size signs.
	head.position = Vector3(0.4, 1.8, 2.6)
	mirror.update_reflection()
	check(mirror.reflection.global_position.is_equal_approx(Vector3(0.4, 1.8, -2.6)), "eye reflected across plane")
	var top_left: Vector2 = mirror.reflection.unproject_position(Vector3(-0.9, 2.75, 0))
	check(top_left.distance_to(Vector2(mirror.viewport.size.x, 0)) < 2.0, "off-axis projection fixes top-left mirror corner")
	var bottom_right: Vector2 = mirror.reflection.unproject_position(Vector3(0.9, 0.05, 0))
	check(bottom_right.distance_to(Vector2(0, mirror.viewport.size.y)) < 2.0, "off-axis projection fixes bottom-right mirror corner")
	# Rotated/translated placement uses the same local reflection relation.
	mirror.rotation.y = 0.7
	mirror.position = Vector3(3, 0.2, -4)
	head.global_position = mirror.to_global(Vector3(0.3, 1.6, 2))
	mirror.update_reflection()
	check(mirror.to_local(mirror.reflection.global_position).is_equal_approx(Vector3(0.3, 1.6, -2)), "rotated mirror reflects in its own plane")
	head.global_position = mirror.to_global(Vector3(0, 1.6, -1))
	mirror.update_reflection()
	check(mirror.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "mirror sleeps from behind")
	wardrobe.appearance_save_path = save_path
	check(wardrobe.choose_outfit("chrome_orchid"), "outfit save request succeeds")
	var restored := ConfigFile.new()
	check(restored.load(save_path) == OK and restored.get_value("appearance", "outfit", "") == "chrome_orchid", "choice persisted separately from progression")
	var second_head := Camera3D.new()
	stage.add_child(second_head)
	second_head.position = Vector3(30, 1.65, 0)
	var reloaded := Wardrobe.new()
	reloaded.mount_path = stage.get_path()
	reloaded.head_path = second_head.get_path()
	reloaded.manager_path = stub.get_path()
	reloaded.appearance_save_path = save_path
	stage.add_child(reloaded)
	for frame in range(8):
		await process_frame
	check(reloaded.costume.get("outfit_id") == "chrome_orchid", "new player wardrobe restores saved outfit")
	check(reloaded.worn().is_empty(), "appearance restore grants no progression")
	mirror.buttons[2].pressed.emit()
	check(wardrobe.costume.get("_garment").visible and not wardrobe.costume.get("drag_outfit").visible, "walk dress restored without deleting outfit history")
	check(int(wardrobe.costume.get("stage")) == old_stage, "restore preserves progression")
	check(head.get_cull_mask_value(19), "returning to walk dress restores camera mask")
	var report := {"checks": checks, "failures": failures, "passed": failures.is_empty(), "headset_tested": false}
	var file := FileAccess.open("res://ada_run/probe_super_drag.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("SUPER_DRAG_RESULT ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
