extends "res://doc/book/iterations/2026-09-19-color-review/opening/probes/probe_color_recovery.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

var phase := "before"
var demo: Node3D
var camera: Camera3D
var measures := {}

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	await museum("Color_Flashlight")
	for n in current_scene.find_children("*", "Node3D", true, false):
		if n.get_script() != null and n.get_script().resource_path.ends_with("flashlight_demo.gd"):
			demo = n
	check(demo != null, "flashlight installation exists in the actual museum")
	if demo == null:
		finish()
		return
	var body: CharacterBody3D = current_scene.get("_player")
	body.set_physics_process(false)
	body.hide() # Hide the off-camera desktop avatar in the fixed audit camera.
	current_scene.get("_feel").set_process(false)
	body.global_position = demo.to_global(Vector3(0,1.0,6.5))
	camera = current_scene.get("_cam")
	camera.fov = 65
	camera.global_position = demo.to_global(Vector3(0,2.0,6.7))
	camera.look_at(demo.to_global(Vector3(0.5,1.65,-1.7)))
	for i in 20:
		camera.make_current()
		current_scene.call("_cull_artifacts")
		await process_frame
	var board: CSGBox3D = demo.get_node("Canvas")
	var albedo: Color = board.material.albedo_color
	check(demo.mount == "standing" and demo.ground == "white", "white standing installation is the active configuration")
	check(is_equal_approx(board.position.y-board.size.y/2.0,0.0), "board starts at the installation floor")
	check(board.use_collision, "board has physical collision")
	var white: Node3D = demo.get_node("WhiteFlashlight")
	check(is_equal_approx(white.rotation_degrees.y,-60.0), "white lamp starts aimed aside")
	var targets := {"RedFlashlight":Color.RED,"GreenFlashlight":Color.GREEN,"BlueFlashlight":Color.BLUE}
	for lamp_name in targets:
		var lamp: Node3D = demo.get_node(lamp_name)
		var light: SpotLight3D = lamp.get_node("SpotLight3D")
		check(light.light_color.is_equal_approx(targets[lamp_name]),lamp_name+" has its expected RGB value")
		check(is_equal_approx(lamp.position.y,1.1) and lamp.freeze,lamp_name+" floats within reach before pickup")
	await snap("overview")
	var red: Node3D = demo.get_node("RedFlashlight")
	var home: Transform3D = red.global_transform
	var grabber := SuppliedGrabber.new()
	current_scene.add_child(grabber)
	grabber.global_transform = red.global_transform
	red.pick_up(grabber)
	grabber.rotate_y(0.65)
	grabber.global_position += demo.global_basis.x * 0.25
	for i in 20: await physics_frame
	check(not red.global_transform.is_equal_approx(home), "supplied grabber moves the live red lamp")
	red.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	var released: Transform3D = red.global_transform
	for i in 30: await physics_frame
	check(red.global_transform.is_equal_approx(released), "released lamp keeps its chosen aim")
	check(board.material.albedo_color.is_equal_approx(albedo), "moving the lamp leaves the board albedo fixed")
	await snap("red-aside")
	red.global_transform = home
	var cube: CSGBox3D = demo.get_node_or_null("ReceiverCube")
	measures.receiver_cube_present = cube != null
	if phase == "after":
		check(cube != null,"promised side cube exists")
		if cube != null:
			check(cube.use_collision,"side cube has physical collision")
			check(cube.material.albedo_color.is_equal_approx(albedo),"cube and board share the near-white albedo")
			check(is_equal_approx(cube.position.y-cube.size.y/2.0,0.0),"side cube rests on the same floor")
			var ray := PhysicsRayQueryParameters3D.create(cube.global_position+Vector3.UP*3.0,cube.global_position-Vector3.UP*2.0,1)
			var hit := cube.get_world_3d().direct_space_state.intersect_ray(ray)
			check(not hit.is_empty() and hit.collider == cube,"comparison cube can be hit by the physics ray")
			var floor_ray := PhysicsRayQueryParameters3D.create(cube.global_position+Vector3(1.0,3.0,0),cube.global_position+Vector3(1.0,-4.0,0),1)
			var floor_hit := cube.get_world_3d().direct_space_state.intersect_ray(floor_ray)
			check(not floor_hit.is_empty() and absf(floor_hit.position.y-(cube.global_position.y-0.5))<0.01,"cube bottom matches the actual adjacent museum floor")
			var shape := CapsuleShape3D.new()
			shape.radius = 0.25
			shape.height = 1.6
			var sweep := PhysicsShapeQueryParameters3D.new()
			sweep.shape = shape
			sweep.collision_mask = 1
			sweep.exclude = [body.get_rid()]
			sweep.transform.origin = demo.to_global(Vector3(5.3,0.85,4))
			sweep.motion = demo.global_basis * Vector3(0,0,-8)
			check(cube.get_world_3d().direct_space_state.cast_motion(sweep)[0]>0.999,"visitor-sized capsule can pass beside the new receiver")
			red.look_at(cube.global_position)
			await snap("red-on-cube")
			check(cube.material.albedo_color.is_equal_approx(albedo),"aiming red at the cube keeps its stored albedo fixed")
			red.global_transform = home
			measures.cube_world_position = str(cube.global_position)
			measures.cube_size = str(cube.size)
	await snap("overview-final")
	finish()

func snap(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	for i in 20:
		camera.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://doc/book/iterations/2026-09-19-color-review/opening/runtime/flashlight-"+phase+"-"+label+".png")

func finish() -> void:
	var data := {"checks":checks,"failures":failures,"phase":phase,"measures":measures,"headset_tested":false,"scope":"Actual endless museum; supplied grabber exercises lamp pickup, aim and release. Images rendered with Vulkan mobile; no headset tracking or comfort claim."}
	var f := FileAccess.open("res://doc/book/iterations/2026-09-19-color-review/opening/runtime/flashlight-"+phase+"-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
	print("FLASHLIGHT_REVIEW ",JSON.stringify(data))
	quit(0 if failures.is_empty() else 1)
