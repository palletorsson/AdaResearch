extends SceneTree
const OUT := "res://ada_run/cube-net-cycle/"
var checks: Array = []
var frame_times: Array = []
var seen: Array[String] = []
var camera: Camera3D

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("[cube-cycle] ","PASS " if passed else "FAIL ",label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"frames"))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL",OUT+"control.json"); em.set("_overrides_path",OUT+"unused.json"); em.set("_hand_path",OUT+"hand.json")
	em.set("start_chapter","primitives"); em.set("start_map","Point_Animatedcube")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream",{})["bodies"] = 1; em.set("_layout",layout)
	FileAccess.open(OUT+"control.json",FileAccess.WRITE).store_string(JSON.stringify({"first_chapter":"primitives","dollhouse":0,"grid_pack":1}))
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var hall: Node3D
	for record: Dictionary in em.get("_segments"):
		if record.node.get_meta("em_map","") == "Point_Animatedcube": hall = record.node; break
	check("actual Animated Cube museum hall assembled",hall != null)
	if hall == null: finish(); return
	for i in 20: await process_frame
	for collision in em.find_children("*","CollisionObject3D",true,false):
		collision.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	em.process_mode = Node.PROCESS_MODE_DISABLED
	var net: Node3D
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script() == load("res://commons/infoboards_3d/visualizations/polyhedron_nets.gd"): net = node; break
	check("existing net uses opt-in fall cycle",net != null and net.fall_cycle)
	if net == null or not net.fall_cycle: finish(); return
	net.process_mode = Node.PROCESS_MODE_ALWAYS; net._apply_fold_mode()
	var cycle = net._fall_controller
	for overlay in root.find_children("*","CanvasLayer",true,false): overlay.hide()
	var player: Node3D = em.get("_player")
	if player: player.hide()
	for ui in root.find_children("*","Control",true,false):
		if not ui.get_viewport() is SubViewport: ui.hide()
	camera = Camera3D.new(); root.add_child(camera); camera.fov = 52
	em.set("_cam",camera); camera.make_current()
	var started := Time.get_ticks_msec()
	while cycle.phase == "ARRIVE" and Time.get_ticks_msec()-started < 4000: await process_frame
	check("net finds the actual floor before beginning",cycle.phase == "OPEN")
	if cycle.phase == "ARRIVE": finish(); return
	var p: Vector3 = cycle.home.origin
	camera.global_position = Vector3(p.x+2.2,cycle.floor_y+1.8,p.z-1.8)
	camera.look_at(Vector3(p.x+0.20,cycle.floor_y+0.85,p.z))
	for i in 5: em.call("_cull_artifacts"); await process_frame
	net.show()
	var ids: Array = cycle.original_materials.keys().map(func(n): return n.get_instance_id())
	check("six original faces form the visible net",ids.size() == 6)
	var fastest := 0.0; var last_phase := ""
	var first_cube: RigidBody3D
	var first_landing := Vector3.ZERO
	var retained_low := true
	var next_frame := 0.0
	started = Time.get_ticks_msec()
	# PNG readbacks can slow the off-screen renderer; leave time for two full
	# simulated cycles even when capture runs below the normal frame rate.
	while cycle.completed_cycles < 2 and Time.get_ticks_msec()-started < 60000:
		await process_frame
		var seconds := (Time.get_ticks_msec()-started)/1000.0
		if cycle.phase == "FALL": fastest = minf(fastest,cycle.body.linear_velocity.y)
		if is_instance_valid(first_cube) and cycle.phase == "REOPEN":
			# Later drops may nudge it along the floor; it must not rise with the net.
			retained_low = retained_low and first_cube.global_position.y<cycle.floor_y+net.edge_length
		if cycle.phase != last_phase:
			last_phase = cycle.phase
			if not seen.has(last_phase):
				seen.append(last_phase)
				if last_phase == "CLOSED":
					check("all faces meet into a cube before release",cube_bounds(net).size.is_equal_approx(Vector3.ONE*net.edge_length))
				if last_phase == "THINK":
					first_cube = cycle.body; first_landing = first_cube.global_position
					check("small cube physically settles near the museum floor",first_landing.y<cycle.floor_y+net.edge_length*net.drop_scale*1.8 and first_cube.get_contact_count()>0)
				if last_phase == "FALL":
					check("finished cube shrinks to 45 percent before falling",cycle.collider.shape.size.is_equal_approx(Vector3.ONE*net.edge_length*net.drop_scale))
					check("drop retains six outlined faces rather than a plain substitute",cycle.body.find_children("*","MeshInstance3D",true,false).filter(func(n): return n.mesh is PlaneMesh).size()==6)
				if last_phase in ["OPEN","CLOSED","FALL","THINK","REOPEN"]: await snapshot(last_phase.to_lower())
		if cycle.phase == "FOLD" and net.fold_progress > 0.45 and not seen.has("HALF"):
			seen.append("HALF"); await snapshot("folding")
		if seconds >= next_frame:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"frames/frame_%04d.png" % frame_times.size())
			frame_times.append((Time.get_ticks_msec()-started)/1000.0)
			next_frame = seconds+0.1
	print("[cube-cycle] completed=",cycle.completed_cycles," final phase=",cycle.phase," capture wall seconds=",(Time.get_ticks_msec()-started)/1000.0)
	check("gravity accelerates the finished cube",fastest < -1.0)
	check("first cube stays on the floor while the next net opens",retained_low and is_instance_valid(first_cube))
	check("two complete cycles return to the original open net",cycle.completed_cycles == 2 and net.fold_progress == 0 and net._cube_root.global_transform.is_equal_approx(cycle.home))
	check("each cycle leaves another independent cube",cycle.produced_cubes==2 and cycle.dropped_cubes.size()==2 and cycle.dropped_cubes[0]!=cycle.dropped_cubes[1])
	check("both dropped cubes remain visible and collidable",cycle.dropped_cubes.size()==2 and cycle.dropped_cubes.all(func(n): return n.visible and not n.get_node("SixFaces").is_queued_for_deletion() and n.collision_mask==7))
	check("working net is restored at full size above the collection",net._cube_root.visible and ids == cycle.original_materials.keys().map(func(n): return n.get_instance_id()))
	await snapshot("collection")
	# Bound continued production without changing the two natural cycles above.
	net.max_dropped_cubes = 2
	cycle.set_physics_process(false); net.fold_progress=1.0; cycle._set_size(net.drop_scale)
	cycle._release(); await process_frame
	check("oldest cube retires when the collection reaches its limit",cycle.dropped_cubes.size()==2 and not is_instance_valid(first_cube))
	# Reconfiguration must retire a moving body and its decorations cleanly.
	net.apply_grid_config({"fall_cycle":false,"fold":"closed"})
	await physics_frame
	check("static DNA pose retires drops and restores original faces",net._fall_controller == null and net.fold_progress == 1 and net._cube_root.visible and net._cube_root.find_children("*","MeshInstance3D",true,false).size() == 6)
	for kind in ["latin_cross","staircase","zed","two_rows"]:
		net.apply_grid_config({"net":kind,"fold":"closed"})
		check("existing net closes after reconfiguration: "+kind,cube_bounds(net).size.is_equal_approx(Vector3.ONE*net.edge_length))
	net.apply_grid_config({"net":"latin_cross","fold":"animated","fall_cycle":true})
	await create_timer(0.5).timeout
	check("museum cycle can restart after live reconfiguration",net._fall_controller != null and net._fall_controller.phase == "OPEN")
	FileAccess.open(OUT+"frame-times.json",FileAccess.WRITE).store_string(JSON.stringify(frame_times))
	finish()

func cube_bounds(net: Node3D) -> AABB:
	var box := AABB(); var got := false
	for face in net._cube_root.find_children("*","MeshInstance3D",true,false):
		if not face.mesh is PlaneMesh: continue
		for x in [-0.5,0.5]:
			for z in [-0.5,0.5]:
				var vertex: Vector3 = net._cube_root.to_local(face.to_global(Vector3(x,0,z)*net.edge_length))
				if got: box = box.expand(vertex)
				else: box = AABB(vertex,Vector3.ZERO); got = true
	return box

func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	check("museum capture "+name,root.get_texture().get_image().save_png(OUT+name+".png") == OK)

func finish() -> void:
	var passed := true
	for entry in checks: passed = passed and entry.passed
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"phases":seen,"scope":"Actual museum assembly, two physics cycles, geometry continuity and native captures. Physical headset untested."},"  "))
	quit(0 if passed else 1)
