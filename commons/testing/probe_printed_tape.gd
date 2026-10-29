extends SceneTree
## Printed tape (tape_roll kind "printed"), in a window (a headless run draws no frames): a floor, a
## timber plank, the one-metre block and a wall; strips laid through the roll's own printer and
## print pass (the same calls a committed two-click strip makes), photographed, then the block is
## moved and the strips are read again. Writes ada_run/printed_tape/{tape.png, moved.png, report.json}.
const Strip := preload("res://commons/artifacts/tape_roll/strip.gd")


func _box(name: String, size: Vector3, at: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new();body.name = name;body.position = at
	var mesh := MeshInstance3D.new();var box := BoxMesh.new();box.size = size;mesh.mesh = box
	var mat := StandardMaterial3D.new();mat.albedo_color = color;mat.roughness = .9;mesh.material_override = mat
	var shape := CollisionShape3D.new();var bs := BoxShape3D.new();bs.size = size;shape.shape = bs
	body.add_child(mesh);body.add_child(shape);root.add_child(body)
	return body


func _hit(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	return root.get_world_3d().direct_space_state.intersect_ray(q)


var diagnosis := {}
var reader := Vector3(-.4, 1.6, 3.2)   # where the person laying them stands (the camera's spot, at eye height)

func _lay(roll: Node, from_ray: Array, to_ray: Array, n: int) -> Node3D:
	var a := _hit(from_ray[0], from_ray[1]);var b := _hit(to_ray[0], to_ray[1])
	diagnosis["strip %d" % n] = {"a": str(a.get("collider", "missed")), "b": str(b.get("collider", "missed")), "roll": str(roll), "has_printer": roll != null and roll.has_method("printer")}
	if a.is_empty() or b.is_empty():
		push_error("PRINTED_TAPE: a ray missed");return null
	var strip: Node3D = Strip.new();strip.name = "Printed%d" % n;root.add_child(strip)
	strip.tape_width = 0.075;strip.material_override = roll.tape_material
	var anchors: Array[Dictionary] = [Strip.anchor(a), Strip.anchor(b)]   # typed: an untyped Array is refused
	strip.anchors = anchors
	strip.draw_between(a.position, a.normal, b.position, b.normal)
	strip.print_source = roll.printer(strip, a.collider, b.collider, n)
	strip.print_reader = reader;strip.print_reader_set = true
	strip.lay_print(a.position, a.normal, b.position, b.normal)
	return strip


func _init() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/printed_tape")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("c9c4ba");e.ambient_light_energy = .6;env.environment = e;root.add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 35, 0);sun.light_energy = 1.3;root.add_child(sun)
	var floor_body := _box("Floor", Vector3(7, .2, 6), Vector3(0, -.1, 0), Color("8f8a84"))
	var cube: Node3D = load("res://commons/artifacts/primitive_encounters/platform_block.tscn").instantiate();cube.position = Vector3(1.3, 0, -.6);root.add_child(cube)
	var plank: Node3D = load("res://commons/artifacts/primitive_encounters/timber_plank_2m.tscn").instantiate();plank.position = Vector3(-1.2, .03, .2);root.add_child(plank)
	var wall := _box("Wall", Vector3(5, 2.4, .2), Vector3(0, 1.2, -1.9), Color("d9d4ca"))
	var roll: Node = load("res://commons/artifacts/tape_roll/printed.tscn").instantiate();roll.position = Vector3(-2.6, .2, 1.5);root.add_child(roll)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(-.4, 2.6, 3.2)).looking_at(Vector3(.1, .4, -.6));cam.fov = 58;root.add_child(cam);cam.current = true
	for i in 6:
		await physics_frame
	var down := Vector3.DOWN
	var strips := {}
	strips["plank to block"] = _lay(roll, [Vector3(-.6, 1, .2), Vector3(-.6, -1, .2)], [Vector3(.95, 2, -.6), Vector3(.95, -1, -.6)], 1)
	strips["on the floor"] = _lay(roll, [Vector3(-2.4, 1, 1.1), Vector3(-2.4, -1, 1.1)], [Vector3(.6, 1, 1.1), Vector3(.6, -1, 1.1)], 2)
	strips["up the block"] = _lay(roll, [Vector3(1.3, .08, 1), Vector3(1.3, .08, -2)], [Vector3(1.3, .92, 1), Vector3(1.3, .92, -2)], 3)
	roll.print_mode = "note";roll.note = "this wall was a door"
	strips["a note on the wall"] = _lay(roll, [Vector3(-2.0, 1.5, 0), Vector3(-2.0, 1.5, -3)], [Vector3(0.3, 1.5, 0), Vector3(0.3, 1.5, -3)], 4)
	# a freehand stroke: a half circle on the floor, laid as samples the way a dragged roll records them
	roll.print_mode = "environment"
	var stroke: Node3D = Strip.new();stroke.name = "PrintedStroke";root.add_child(stroke)
	stroke.tape_width = 0.075;stroke.material_override = roll.tape_material
	var samples: Array[Dictionary] = []
	for i in 25:
		var ang := PI * float(i) / 24.0
		var at := Vector3(-1.6 + 1.1 * cos(ang), 0, -0.9 + 0.7 * sin(ang))
		var h := _hit(at + Vector3.UP, at + Vector3.DOWN)
		if not h.is_empty():samples.append(Strip.anchor(h))
	stroke.anchors = samples
	stroke.print_source = roll.printer(stroke, floor_body, floor_body, 5)
	stroke.print_reader = reader;stroke.print_reader_set = true
	strips["a curved stroke"] = stroke
	for i in 4:
		await physics_frame
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("tape.png"))
	var report := {"strips": {}, "diagnosis": diagnosis}
	for k in strips:
		var s: Node3D = strips[k]
		var view: SubViewport = s.get("_print_view") if s != null else null
		report["strips"][k] = {"text": s.get("printed"), "print_px": [view.size.x, view.size.y] if view != null else []} if s != null else {}
	cube.position.x += .6
	for i in 6:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("moved.png"))
	for k in strips:
		var s: Node3D = strips[k]
		if s != null:report["strips"][k]["after the block moved 0.6 m"] = s.get("printed")
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "));f.close()
	quit(0)
