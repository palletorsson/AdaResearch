extends Node
## Actual museum placement + synthetic input through the existing desktop rig.
## No tracked hand or headset claim. Never asserts a predetermined exit count.
const OUT := "res://ada_run/sine-flow-hall/"
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
func _ready() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("SINE-FLOW ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var control := OUT+"control.json"
	var f := FileAccess.open(control, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"wavefunctions","dollhouse":0,"grid_pack":1})); f.close()
	em.set("EM_CONTROL", control); em.set("_overrides_path", control+".unused"); em.set("_hand_path","res://ada_run/necklace_hand.json")
	em.set("start_chapter","wavefunctions"); em.set("start_map","WaveFunctions_Sine_Space")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream",{})["bodies"] = 1; em.set("_layout",layout)
	get_tree().root.add_child(em); get_tree().current_scene = em
	await get_tree().create_timer(1).timeout
	em.set_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","") == "WaveFunctions_Sine_Space": seg = rec.node; break
	check(seg != null,"Sine Space exists in the actual museum")
	if seg == null: finish(); return
	var clear_rects: Array = seg.get_meta("em_sculpture_clear_rects",[])
	check(not clear_rects.is_empty() and clear_rects.all(func(r): return r.size.x>0 and r.size.y>0),"sculpture exclusions have valid positive dimensions")
	for i in 30: await get_tree().process_frame
	var tray: Node3D
	var cor: Node3D
	var placed := []
	for rec: Dictionary in em.get("_edit_records"):
		var node: Node = rec.get("node")
		if node == null or not seg.is_ancestor_of(node) or node.get_script() == null: continue
		var path := str(node.get_script().resource_path)
		if path.ends_with("sine_flow_tray.gd"): tray = node; placed.append(rec.get("tile_cell",[]))
		if path.ends_with("SineWallCorridor.gd"): cor = node
	check(placed == [[3,4]],"exactly one contact tray at map cell (3,4)")
	check(tray != null and cor != null,"both book artifacts are present")
	if tray == null or cor == null: finish(); return
	var vest: int = em.get("VESTIBULE_H")
	measurements["tray_origin"] = vec(seg.to_local(tray.global_position))
	check(tray.scale.is_equal_approx(Vector3.ONE),"tray placed at declared metre scale")
	check(not bool(cor.get("enable_collision")),"corridor walls retain their visible-only contract")
	var all_extent := AABB(); var first := true
	for node in tray.find_children("*","MeshInstance3D",true,false):
		var m: MeshInstance3D = node
		if m.mesh == null: continue
		var extent: AABB = seg.global_transform.affine_inverse()*m.global_transform*m.get_aabb()
		all_extent = extent if first else all_extent.merge(extent); first = false
	measurements["tray_extent"] = [vec(all_extent.position),vec(all_extent.end)]
	check(all_extent.position.x > 1 and all_extent.end.x < 7 and all_extent.position.z-vest > 1 and all_extent.end.z-vest < 7,"casing and side console fit entirely in the forecourt")
	var space := seg.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(tray.tray.to_global(Vector3(0,2,0)),tray.tray.to_global(Vector3(0,-1,0)),1))
	check(not hit.is_empty() and hit.collider == tray.surface,"descending ray hits the sampled sine collision surface")
	var capsule := CapsuleShape3D.new(); capsule.radius=.22; capsule.height=1.6
	for route in [["entry to old antechamber",Vector3(7.5,.9,1.5),Vector3(0,0,7)],
		["approach side controls",Vector3(7.5,.9,4.5),Vector3(-.65,0,0)],
		["corridor west to east",Vector3(1.8,.9,10.5),Vector3(9,0,0)],
		["east mouth to bridge",Vector3(10.5,.9,10.5),Vector3(0,0,2)]]:
		var q := PhysicsShapeQueryParameters3D.new(); q.shape=capsule
		q.transform=Transform3D(Basis.IDENTITY,seg.to_global(route[1]+Vector3(0,0,vest))); q.motion=route[2]
		var fraction: float = space.cast_motion(q)[0]
		measurements[route[0]]=fraction; check(fraction > .99,route[0]+" remains clear for the test capsule")
	var driver: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
	get_tree().root.add_child(driver)
	var stand: Vector3 = tray.panel.to_global(Vector3(0,0,.95))
	driver.spawn(stand,em); await get_tree().create_timer(.5).timeout
	check(driver.is_ready(),"actual desktop rig and pointer ready")
	var log := []
	for id in ["RULE","RULE","SIZE","RELIEF","RESET"]:
		var b: Node3D = tray.buttons[id]
		var at: Vector3 = tray.panel.to_global(Vector3(b.position.x,0,.95))
		check(absf(seg.to_local(b.global_position).y-1.04)<.06,id+" button at standing hand height")
		var before: Dictionary = tray.snapshot()
		var before_rule: bool = tray.reveal
		var click: Dictionary = await driver.press(b,at)
		await get_tree().process_frame
		log.append({"id":id,"input":click,"before":before,"after":tray.snapshot()})
		if id == "RULE": check(tray.reveal != before_rule,"pointer click toggles RULE")
		elif id == "SIZE": check(tray.snapshot().radius_m != before.radius_m and tray.snapshot().relief_m == before.relief_m,"SIZE changes radius alone")
		elif id == "RELIEF": check(tray.snapshot().relief_m != before.relief_m and tray.snapshot().radius_m == before.radius_m,"RELIEF changes height range alone")
		else: check(tray.radius_index==1 and tray.relief_index==1 and not tray.has_run,"RESET restores declared setup")
	measurements["desktop_controls"]=log
	var cam := Camera3D.new(); em.add_child(cam); cam.fov=68
	var env: Environment = em.get_world_3d().environment
	if env != null: cam.environment=env.duplicate(); cam.environment.fog_enabled=false
	var baseline_samples: Array = Array(tray.samples)
	measurements["trials"]=[]
	for trial_index in 3:
		if trial_index > 0:
			var size_button: Node3D = tray.buttons["SIZE"]
			await driver.press(size_button,tray.panel.to_global(Vector3(size_button.position.x,0,.95)))
			check(tray.bodies.is_empty(),"size change clears the previous batch")
		check(Array(tray.samples)==baseline_samples,"size comparison preserves every terrain sample")
		var release_button: Node3D = tray.buttons["RELEASE"]
		await driver.press(release_button,tray.panel.to_global(Vector3(release_button.position.x,0,.95)))
		check(tray.running and tray.bodies.size()==32,"desktop RELEASE starts exactly 32 bodies")
		while tray.running: await get_tree().physics_frame
		await get_tree().physics_frame; await get_tree().process_frame
		var result: Dictionary = tray.snapshot(); measurements.trials.append(result)
		check(result.ticks==12*result.physics_hz and result.outlet+result.still_in+result.other_exit==32,"complete window and mutually exclusive outcomes")
		check(tray.bodies.all(func(b): return b.freeze and is_equal_approx(b.mass,.1)),"bodies freeze at the deadline, all with mass 0.1 kg")
		check(tray.bodies.all(func(b): return b.position.y > -.5),"no simulated bodies leak below the hall")
		if trial_index == 0:
			cam.global_position=seg.to_global(Vector3(6.8,2.1,1.9+vest)); cam.look_at(tray.to_global(Vector3(0,1,0)))
			await capture(cam,"tray-contact.png")
			cam.global_position=seg.to_global(Vector3(9,8,1+vest)); cam.look_at(seg.to_global(Vector3(5,.7,6+vest)))
			await capture(cam,"forecourt-and-corridor.png")
	await driver.teardown()
	check(tray.bodies.size()==32,"repeated trials keep the active body count bounded")
	measurements["museum_severed"]=em.get("_seg_severed")
	for rec in em.get("_seg_severed"):
		check(str(rec.get("token","")) != "sine_flow_tray","new tray does not sever the museum route")
	finish()

func capture(cam: Camera3D, name: String) -> void:
	for i in 20: cam.make_current(); await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+name)
func vec(v: Vector3) -> Array: return [v.x,v.y,v.z]
func finish() -> void:
	var f := FileAccess.open(OUT+"report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"measurements":measurements,
		"engine":Engine.get_version_info().string,"headset_verified":false,
		"input":"synthetic mouse input through the project's desktop rig; museum walker and tracked hands are separate lanes"},"  ")); f.close()
	print("SINE-FLOW COMPLETE ",checks," checks, ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
