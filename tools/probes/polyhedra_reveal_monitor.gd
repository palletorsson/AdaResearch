extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-04-polyhedra-reveal-monitor/"
var checks: Array[Dictionary] = []
var preview: Node3D
var monitor: Node3D
var stage: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	print("PASS " if passed else "FAIL ", title)

func run() -> void:
	root.size = Vector2i(1440, 1000)
	preview = load("res://commons/artifacts/concept_monitor/polyhedra_reveal_preview.tscn").instantiate()
	root.add_child(preview)
	monitor = preview.get("monitor")
	stage = monitor.get("stage")
	monitor.set_process(false)
	monitor.set_physics_process(false)
	var body: Node3D = preview.get("body")
	await physics_frame
	await physics_frame
	check(monitor.get("source") == body, "Monitor discovers the real tetrahedron")
	check(stage.corners.size() == 4 and stage.boundaries.size() == 6 and stage.faces.size() == 4, "Four positions, six edges and four source faces")
	var geometry: Dictionary = body.call("_tetrahedron_geometry")
	var original_mesh: Mesh = body.get_node("MeshInstance3D").mesh
	var original_shape: Shape3D = body.get_node("CollisionShape3D").shape
	for key in ["route", "step", "replay", "pause", "pause"]: monitor.call("activate", key)
	check(body.call("_tetrahedron_geometry") == geometry and body.get_node("MeshInstance3D").mesh == original_mesh and body.get_node("CollisionShape3D").shape == original_shape, "Monitor controls leave source geometry, mesh and collision unchanged")
	stage.set("camera_angle", 0.0)
	stage.set("running", true)
	monitor.call("_physics_process", 0.2)
	check(monitor.get("gaze_active"), "Looking at the screen starts the film")
	var before: float = stage.playhead
	monitor.call("_process", 0.1)
	check(stage.playhead > before, "Filmed construction advances while viewed")
	var eye: Camera3D = preview.get("camera")
	eye.rotation.y += PI
	monitor.call("_physics_process", 0.2)
	before = stage.playhead
	monitor.call("_process", 0.1)
	check(not monitor.get("gaze_active") and stage.playhead == before, "Looking away freezes the film")
	eye.look_at(Vector3(0, 1.5, 0))
	monitor.call("activate", "pause")
	monitor.call("_physics_process", 0.2)
	monitor.call("_process", 0.1)
	check(stage.playhead == before, "Manual pause survives returning gaze")
	stage.set("playhead", 14.0)
	stage.call("refresh")
	var base: Array = stage.record.faces[3]
	var points: PackedVector3Array = stage.record.points
	var a: Vector3 = stage.display_position(points[base[0]])
	var b: Vector3 = stage.display_position(points[base[1]])
	var c: Vector3 = stage.display_position(points[base[2]])
	var plane := Plane(a, b, c)
	var coplanar := true
	var unchanged_edges := true
	for i in range(4):
		var row: Array = stage.record.faces[i]
		for j in range(3):
			var original: Vector3 = stage.display_position(points[row[j]])
			var next: Vector3 = stage.display_position(points[row[(j + 1) % 3]])
			var folded: Vector3 = stage.faces[i].transform * original
			var folded_next: Vector3 = stage.faces[i].transform * next
			coplanar = coplanar and absf(plane.distance_to(folded)) < 0.0001
			unchanged_edges = unchanged_edges and is_equal_approx(folded.distance_to(folded_next), original.distance_to(next))
	check(coplanar, "Rendered unfolded copies lie in one plane")
	check(unchanged_edges, "Unfolding preserves all triangle edge lengths")
	stage.set("playhead", 22.0)
	stage.call("refresh")
	var restored := true
	for face in stage.faces: restored = restored and face.transform.is_equal_approx(Transform3D.IDENTITY)
	check(restored, "Folding closes precisely onto the source geometry")
	if DisplayServer.get_name() != "headless":
		var feed: SubViewport = monitor.get("viewport")
		for item in [[2.0,"positions"],[4.5,"edges"],[8.0,"faces"],[10.6,"unfolding"],[14.0,"net"],[18.0,"folding"],[22.0,"closed"]]:
			stage.set("playhead", item[0])
			stage.call("refresh")
			await settle(feed)
			feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + item[1] + ".png"))
		stage.set("playhead", 10.6)
		stage.call("refresh")
		await settle(feed)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "preview.png"))
		for i in range(46):
			stage.set("playhead", float(i) * 0.5)
			stage.call("refresh")
			await settle(feed)
			feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "frame-%02d.png" % i))
		await museum_capture()
	var passed := true
	for item in checks: passed = passed and bool(item.passed)
	var file := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks}, "\t"))
	file.close()
	print("POLYHEDRA REVEAL ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)

func settle(feed: SubViewport) -> void:
	feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw

func museum_capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty(): return
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var folder: String = spec.run
	preview.hide()
	for child in preview.get_children():
		if child is Label: child.hide()
	var museum: Node3D = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", "primitives")
	museum.set("start_map", "Primitives_Polythedra")
	museum.set("plan_file", folder + "plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 65000: await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.5).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == "Primitives_Polythedra": hall = child
	check(hall != null, "Actual Polyhedra museum hall loads")
	if hall == null: return
	var placed: Node3D
	for child in hall.find_children("*", "Node3D", true, false):
		var script: Script = child.get_script()
		if script != null and script.resource_path.ends_with("/polyhedra_reveal_monitor.gd"): placed = child
	check(placed != null, "Registered monitor appears in the actual hall")
	if placed == null: return
	placed.set_process(false)
	placed.set_physics_process(false)
	placed.call("discover_source")
	placed.call("observe", 0.25)
	check(placed.get("source") != null, "Hall monitor finds the existing tetrahedron")
	var filmed: Node3D = placed.get("stage")
	check(filmed.record.points.size() >= 3 and filmed.faces.size() >= 1, "Hall's tetrahedron supplies the filmed surface")
	filmed.set("playhead", 10.6)
	filmed.set("running", false)
	filmed.call("refresh")
	var eye := Camera3D.new()
	root.add_child(eye)
	var target: Vector3 = placed.get("screen").global_position
	eye.global_position = target + placed.global_basis.z * 3.2 - placed.global_basis.x * 0.3
	eye.look_at(target)
	eye.fov = 68
	eye.make_current()
	await physics_frame
	check(placed.call("is_looking_at_screen", eye), "Screen has an unobstructed viewing position inside the museum")
	for corner in [Vector3(-1.24,-0.68,0), Vector3(1.24,-0.68,0), Vector3(-1.24,0.68,0), Vector3(1.24,0.68,0)]:
		var screen_node: Node3D = placed.get("screen")
		var destination := screen_node.to_global(corner)
		var sight := PhysicsRayQueryParameters3D.create(eye.global_position, destination.move_toward(eye.global_position,0.002),1)
		var blocked := placed.get_world_3d().direct_space_state.intersect_ray(sight)
		check(blocked.is_empty(), "Screen corner visible: " + str(corner))
		if not blocked.is_empty(): print("SCREEN BLOCKER ",blocked.collider.get_path())
	for key in ["pause", "replay", "step", "route"]:
		var button: Node3D = placed.get("buttons")[key]
		var from := button.global_position + placed.global_basis.z
		var ray := PhysicsRayQueryParameters3D.create(from, button.global_position - placed.global_basis.z * 0.05, 1 | (1 << 20))
		ray.collide_with_areas = true
		var hit := placed.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == button, "Hall control reachable: " + key)
	await settle(placed.get("viewport"))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "museum.png"))
	placed.get("viewport").get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "museum-feed.png"))
	var file := FileAccess.open(OUT + "placement.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"monitor": str(placed.global_position), "source": str(placed.get("source").global_position), "record_points": filmed.record.points.size()}, "\t"))
	file.close()
