extends SceneTree
## Render the installed Color_Flashlight annex in a private museum runtime.
const OUT := "res://ada_run/light-opening-museum/"
var checks: Array = []
var failures: Array = []
var rooms: Node3D
var em: Node3D
var camera: Camera3D

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failures.append(label)
	print("[light-museum] ","PASS " if passed else "FAIL ",label)

func ray(a: Vector3,b: Vector3) -> Dictionary:
	return rooms.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(rooms.to_global(a),rooms.to_global(b),1))

func shot(label: String,eye: Vector3,target: Vector3,fov := 72.0) -> Image:
	camera.global_position = rooms.to_global(eye)
	camera.look_at(rooms.to_global(target))
	camera.fov = fov
	for frame in 12:
		em.call("_cull_artifacts")
		camera.make_current()
		await process_frame
	check("capture visible: "+label,rooms.is_visible_in_tree())
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	check("capture saved: "+label,img.save_png(OUT+label+".png") == OK)
	return img

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL",OUT+"control.json")
	em.set("_overrides_path",OUT+"unused-overrides.json")
	em.set("_hand_path",OUT+"hand.json")
	em.set("start_chapter","color")
	em.set("start_map","Color_Flashlight")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream",{})["bodies"] = 1
	em.set("_layout",layout)
	var file := FileAccess.open(OUT+"control.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter":"color","first_map":"Color_Flashlight","dollhouse":0,"grid_pack":1}))
	file.close()
	root.add_child(em)
	current_scene = em
	await create_timer(1).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	for frame in 45: await process_frame
	var hall: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","") == "Color_Flashlight": hall = rec.node
	check("Color_Flashlight assembled",hall != null)
	if hall == null: finish(); return
	var original: Node3D
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script() == load("res://commons/artifacts/colour_light_rooms/colour_light_rooms.gd"): rooms = node
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/flashlight_demo.gd"): original = node
	check("annex and original torch exhibit are both installed",rooms != null and original != null)
	if rooms == null: finish(); return
	rooms.running = false
	em.process_mode = Node.PROCESS_MODE_DISABLED
	# CollisionObject3D normally removes its bodies when processing is disabled.
	# Keep this artifact active for physics queries while freezing its colour loop.
	rooms.process_mode = Node.PROCESS_MODE_ALWAYS
	rooms.set_process(false)
	var player: Node3D = em.get("_player")
	if player != null: player.hide()
	em.set("_shot_path","private-capture")
	for timer in em.find_children("*","Timer",true,false): timer.stop()
	camera = Camera3D.new()
	root.add_child(camera)
	em.set("_cam",camera)
	for overlay in root.find_children("*","CanvasLayer",true,false): overlay.hide()
	for ui in root.find_children("*","Control",true,false): ui.hide()
	await physics_frame
	check("entry and connecting passage remain clear",ray(Vector3(-6,1.2,0),Vector3(7,1.2,0)).is_empty())
	check("pink opening has physical depth",ray(Vector3(0,1.5,-2.8),Vector3(0,1.5,-4.15)).is_empty())
	check("recess ends at a solid back wall",not ray(Vector3(0,1.5,-4.1),Vector3(0,1.5,-4.6)).is_empty())
	check("solid cheeks surround the opening",not ray(Vector3(3.5,1.5,-2.6),Vector3(3.5,1.5,-3.6)).is_empty())
	check("ceiling opens all the way to the sky",ray(Vector3(10.2,2,0),Vector3(10.2,10,0)).is_empty())
	check("sides of the light well close the old sky leaks",not ray(Vector3(10.2,5,0),Vector3(13.6,5,0)).is_empty())
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.7
	for p in [Vector3(-3,0.9,0),Vector3(0,0.9,-2.9),Vector3(0,0.9,-3.85),Vector3(4.95,0.9,0),Vector3(7,0.9,0),Vector3(11,0.9,4.8)]:
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = capsule
		q.transform = Transform3D(Basis.IDENTITY,rooms.to_global(p))
		q.collision_mask = 1
		check("standing body clearance "+str(p),rooms.get_world_3d().direct_space_state.intersect_shape(q).is_empty())
		check("floor supports "+str(p),not ray(p,Vector3(p.x,-0.3,p.z)).is_empty())
	var occupancy: Array = rooms.get_museum_occupied_cells()
	var wp: Vector3 = rooms.to_global(Vector3(0,0,-3.8))
	check("recess remains open in museum route footprint",not occupancy.has(Vector2i(floor(wp.x),floor(wp.z))))
	var white: Color = rooms.white_material.albedo_color
	var fixed_pink: Color = rooms.threshold_lights[0].light_color
	var fixed_wall: Transform3D = rooms.get_node("WhiteWall").global_transform
	rooms.set_phase(0.20)
	await shot("pink-threshold",Vector3(0,1.65,-1.0),Vector3(0,1.7,-4.1),92)
	await shot("threshold-from-side",Vector3(1.7,1.65,-2.1),Vector3(0,1.65,-4.0),64)
	var a: Image = await shot("white-room-rose",Vector3(-3.2,1.65,2.6),Vector3(0.7,2,-1.3),73)
	rooms.set_phase(0.60)
	var b: Image = await shot("white-room-blue",Vector3(-3.2,1.65,2.6),Vector3(0.7,2,-1.3),73)
	check("changing the central light changes the room image",a.get_data() != b.get_data())
	check("receiver and geometry stay fixed",white == rooms.white_material.albedo_color and fixed_wall.is_equal_approx(rooms.get_node("WhiteWall").global_transform))
	check("pink recess source stays fixed while surround changes",fixed_pink == rooms.threshold_lights[0].light_color)
	rooms.set_phase(0.16)
	await shot("light-well-rose",Vector3(10.2,1.65,0.5),Vector3(10.2,6.5,-0.1),100)
	rooms.set_phase(0.38)
	await shot("light-well-violet",Vector3(10.2,1.65,0.5),Vector3(10.2,6.5,-0.1),100)
	rooms.set_phase(0.16)
	await shot("light-well-landing",Vector3(10.5,2.85,-5.65),Vector3(10.2,6.0,1.0),96)
	finish()

func finish() -> void:
	var report := FileAccess.open(OUT+"report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"map":"Color_Flashlight","artifact":"colour_light_rooms","checks":checks,"failures":failures,
		"scope":"Actual museum assembly. Standing capsule and collision rays, rendered comparisons; no tracked-headset or perceptual measurement."},"\t"))
	report.close()
	quit(0 if failures.is_empty() else 1)
