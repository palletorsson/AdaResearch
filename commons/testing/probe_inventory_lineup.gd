extends Node3D
## THE INVENTORY LINE-UP, for looking at: every item in items.json made full size on the floor by the hand's own
## spawn_at (the ball onto its grid point, the rod lying where it fell, the clock standing, the tape as its roll)
## with its MINIATURE floating above it as the right hand wears it (Palle: "the current object must be a small
## version of the original"), each labelled. Not a test: one picture, ada_run/inventory/lineup.png.
## Run: godot --path . --xr-mode off --resolution 1600x900 res://commons/testing/probe_inventory_lineup.tscn

const HandLib = preload("res://commons/player/inventory_hand.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-45, 35, 0);sun.light_energy = 1.2;sun.shadow_enabled = true;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = fb.size;fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(-0.5, 1.25, 4.2)).looking_at(Vector3(-0.5, 0.45, 0));cam.fov = 48;add_child(cam);cam.current = true
	var hand: Node = HandLib.new();add_child(hand)
	var ids: Array = [];var names: Dictionary = {}
	for it in hand.Items.items():
		if str(it.get("coming", "")) == "":ids.append(str(it.id));names[str(it.id)] = str(it.get("name", it.id))
	var xs: Array = [-2.0, -1.0, 0.0, 1.0, 2.0]
	for i in ids.size():
		var id: String = ids[i];var x: float = xs[i]
		hand.set_current(id)
		# full size: made on the floor by the hand itself, then settled by its own rule
		var node: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(x, 0.45, 0)))
		if node != null:
			await get_tree().physics_frame
			if node.has_method("settle"):node.settle()
			elif node.has_method("wear"):   # the tape: its roll, laid on its side
				node.global_transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(x, 0.05, 0))
		# the miniature, as the right hand would wear it: a stand-in for the hand above the thing
		var stand := Node3D.new();stand.name = "Hand_" + id;add_child(stand);stand.global_position = Vector3(x, 0.95, 0)
		hand.sync_worn(stand)
		hand._mini = null;hand._mini_id = ""   # the hand forgets it, so the next item does not put it away
		var worn: Node = hand.worn_of(id)
		if worn != null:worn.visible = true
		var label := Label3D.new();label.text = names[id].to_upper() + "\n" + id;label.font_size = 40;label.pixel_size = .0025;label.modulate = Color("f4eee2")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;label.position = Vector3(x, 1.35, 0);add_child(label)
	hand.set_current("")
	for w in hand._worn.values():
		if is_instance_valid(w):w.visible = true
	var cap := Label3D.new();cap.text = "THE INVENTORY  ·  full size on the floor, the miniature the right hand wears above";cap.font_size = 36;cap.pixel_size = .0025
	cap.modulate = Color("f4eee2");cap.position = Vector3(-0.5, 1.75, 0);cap.billboard = BaseMaterial3D.BILLBOARD_ENABLED;add_child(cap)
	for i in 40:
		await get_tree().physics_frame
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("lineup.png"))
	print("[probe_inventory_lineup] wrote lineup.png with %d items" % ids.size())
	get_tree().quit(0)
