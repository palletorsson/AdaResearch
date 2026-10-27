extends "res://tools/probes/sine_yoke.gd"
var capture := false
func run() -> void:
	var Workshop: PackedScene = load("res://commons/artifacts/pallet_assemblage/pallet_assemblage.tscn")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":capture = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene;root.size = Vector2i(1440,900)
	var world := WorldEnvironment.new();world.environment = Environment.new();world.environment.background_mode = Environment.BG_COLOR;world.environment.background_color = Color("34353e");world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color = Color("fff0de");world.environment.ambient_light_energy = .45;scene.add_child(world)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-45,-35,0);sun.shadow_enabled = true;scene.add_child(sun)
	var floor := StaticBody3D.new();floor.position.y = -72.1;scene.add_child(floor)
	var box := BoxMesh.new();box.size = Vector3(14,.2,12);var skin := MeshInstance3D.new();skin.mesh = box;floor.add_child(skin)
	var material := StandardMaterial3D.new();material.albedo_color = Color("8b8c87");material.roughness = .9;skin.material_override = material
	var collider := CollisionShape3D.new();collider.shape = BoxShape3D.new();collider.shape.size = box.size;floor.add_child(collider)
	var work: Node3D = Workshop.instantiate();work.position = Vector3(0,-72,0);scene.add_child(work);await tick(8)
	check("Jolt and twenty stable independent pickables",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics" and work.pieces.size()==20)
	var volume := 0.0
	for body: Node3D in work.pieces.values():
		var shape: BoxShape3D = body.get_node("SolidWood").shape;volume += shape.size.x*shape.size.y*shape.size.z
	check("wood is full real-size geometry with separate colliders",volume>.035 and volume<.06 and work.part_defaults.size()==22)
	camera = Camera3D.new();camera.fov = 44;scene.add_child(camera);camera.make_current()
	if capture:await photo("01-pallet",work.to_global(Vector3(2.6,2.5,3.7)),work.to_global(Vector3(.25,.65,0)))
	# Use the actual desktop hand and XRTools grab driver, not a script teleport of the bodies.
	var hand: Node3D = load("res://commons/void/desktop_hand.gd").new();hand.cam = camera;scene.add_child(hand);hand.enabled = false
	var body: Node3D = work.pieces.deck_1
	camera.global_position = body.global_position+Vector3(0,.5,1.3);camera.look_at(body.global_position)
	hand._grab_held(body);await tick(3)
	check("production desktop hand picks one plank only",body.is_picked_up() and hand.shared_grab and work.pieces.deck_2.freeze)
	body.rotate_in_hand(Vector3.RIGHT,15);await tick(3)
	check("desktop hand can turn held timber",absf(body.rotation_degrees.x)>5)
	hand._drop_held();await tick(3)
	check("place mode retains released pose without a weld",body.freeze and not body.is_picked_up())
	var origin := XROrigin3D.new();scene.add_child(origin);var controller := XRController3D.new();origin.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform = work.pieces.block_1_1.global_transform;work.pieces.block_1_1.pick_up(pickup);await tick(3)
	controller.global_position += Vector3(0,.25,.2);await tick(6)
	check("supplied XR hand moves the same block",work.pieces.block_1_1.is_picked_up() and work.pieces.block_1_1.position.y>.2)
	work.pieces.block_1_1.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(3)
	# Create one reusable example with the SAME hand driver, one part at a time.
	var i := 0
	for id in work.pieces:
		var piece: Node3D = work.pieces[id]
		controller.global_transform = piece.global_transform;piece.pick_up(pickup);await tick(2)
		var target := Vector3.ZERO
		var tilt := Vector3.ZERO
		if i<3:target = Vector3(-2,.011,(i-1)*.32)
		elif i<12:
			var k := i-3;target = Vector3(-2+(floori(k/3.0)-1)*.4,.061+(k%3)*.078,0)
		elif i<15:target = Vector3(-2+(i-13)*.4,.267,0)
		elif i<18:target = Vector3(-2+(i-16)*.4,.878,0);tilt.z = PI/2
		else:target = Vector3(-2,1.489,(i-18.5)*.16)
		controller.global_position = work.to_global(target)
		controller.global_basis = work.global_basis*Basis.from_euler(tilt)
		await tick(8);piece.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(2);i += 1
	check("every timber piece moved independently by supplied hand",work.events.filter(func(e):return e.action=="pick_up").size()>=22)
	if capture:await photo("02-hand-sculpture",work.to_global(Vector3(2.8,2.6,4.0)),work.to_global(Vector3(-.15,1,-.6)))
	var before: Dictionary = work.snapshot("Pallet / hand-built open frame")
	var saved_receipt: Dictionary = {}
	if capture:
		saved_receipt = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("saved.json")))
	else:
		work.editor_url = "http://127.0.0.1:65535";work.request.timeout = 2;work.save_prefab()
		var deadline := Time.get_ticks_msec()+10000
		while work.saving and Time.get_ticks_msec()<deadline:await process_frame
		check("offline SAVE reports failure and retains a local draft",work.status.text.begins_with("NOT SAVED") and not work.pending_save.is_empty())
		work.pieces.deck_1.position += Vector3(.1,.1,0);work.recover_draft()
		check("RECOVER restores the captured hand arrangement",work.pieces.deck_1.position.distance_to(work.vec(before.parts[15].position))<.0001)
		work.editor_url = "http://127.0.0.1:3003";work.request.timeout = 12
		work.pending_save = work.snapshot("Pallet / hand-built open frame");work.pending_save["key"] = "pallet-assembly-demonstration-2026-10-24-v2"
		work.save_prefab()
		deadline = Time.get_ticks_msec()+20000
		while work.saving and Time.get_ticks_msec()<deadline:await process_frame
		check("production SAVE persists the real hand poses via editor API",not work.last_saved_id.is_empty())
		saved_receipt = {"id":work.last_saved_id,"snapshot":before}
		FileAccess.open(out.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(saved_receipt,"  "))
	if not saved_receipt.id.is_empty():
		var copy: Node3D = Workshop.instantiate();copy.apply_grid_config({"term":saved_receipt.id,"workshop":false});copy.position = Vector3(3,-72,0);copy.rotation.y = .47;scene.add_child(copy);await tick(5)
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/modular/terms.json"));var parts: Array = doc.terms[saved_receipt.id].handmade.parts
		var parity: bool = copy.pieces.size()==20
		for p in parts:
			parity = parity and copy.pieces[p.id].position.distance_to(work.vec(p.position))<.0001 and copy.pieces[p.id].get_meta("pallet_part_id")==p.id
		check("saved term reloads all IDs and local poses on moved rotated negative floor",parity)
		check("saved collection has no implicit physical joints",copy.find_children("*","Joint3D",true,false).is_empty())
		var kernel: Node3D = load("res://commons/modular/builder.gd").build({"t":saved_receipt.id},doc.terms)
		var kernel_parity: bool = kernel.get_child_count()==20
		for p in parts:
			var member := kernel.get_node_or_null(NodePath(p.id)) as Node3D
			kernel_parity = kernel_parity and member!=null and member.position.distance_to(work.vec(p.position))<.0001 and member.get_meta("part_id","")==p.id
		check("modular kernel rebuilds the canonical recipe with persistent IDs",kernel_parity);kernel.free()
		var test: Node3D = copy.pieces.deck_1;var old := test.global_position;copy.set_placing(false);await tick(90)
		check("gravity mode really releases Jolt bodies",not test.freeze and test.global_position.distance_to(old)>.05)
		copy.queue_free();await tick(2)
	if FileAccess.file_exists(out.path_join("editor-roundtrip.json")):
		var editor: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("editor-roundtrip.json")))
		for record in editor.floors[12].copies:
			if record.id!="pallet-roundtrip-check":continue
			var rebuilt: Node3D = Workshop.instantiate();rebuilt.apply_grid_config(record.config);rebuilt.position = Vector3(record.position[0],-72+record.height,record.position[1]);rebuilt.rotation_degrees.y = record.facing;scene.add_child(rebuilt);await tick(3)
			var matches: bool = rebuilt.pieces.size()==20
			for id in rebuilt.pieces:
				matches = matches and rebuilt.pieces[id].position.distance_to(work.vec(record.config.parts[id].position))<.0001
			check("live-editor serialized moves reload as twenty native editable pieces",matches);rebuilt.queue_free();await tick(2)
	work.reset_pallet();await tick(3)
	check("reset restores pallet without removing saved recipe",absf(work.pieces.deck_1.position.y-.733)<.001 and FileAccess.file_exists("res://commons/modular/terms.json"))
	# The real tower, not the isolated test stage, is the final placement view.
	if capture:
		work.hide();floor.hide();Source.use_main_tower = true
		var building: Node3D = load("res://commons/void/architecture.gd").new();building.stream_content = true;scene.add_child(building)
		building.content.load_floor(12);var shown: Array[int] = [12];building.show_floor_window(shown);await tick(30)
		var placed: Node3D = building.content.exhibits["12/pallet-hand-workshop"].get_node("Artifact")
		check("real Melencolia placement has all twenty parts",placed.pieces.size()==20 and placed.global_position.distance_to(Vector3(-4,-72,4.8))<.001)
		await photo("03-melencolia",placed.to_global(Vector3(2.8,2.4,3.5)),placed.to_global(Vector3(.15,.8,0)))
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"saved":saved_receipt.id,"scope":"Production desktop pickup, supplied XRTools hand poses, HTTP save, canonical term reload and Jolt loose-body gravity. No physical-headset acceptance."}
	FileAccess.open(out.path_join("capture-checks.json" if capture else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	origin.queue_free();hand.queue_free();await tick(3)
	print("PALLET_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
