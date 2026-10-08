extends SceneTree
const OUT := "res://ada_run/study-integration/"
var checks: Array = []
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
class Press extends RefCounted:
	var event_type := 2
func _initialize() -> void: run.call_deferred()
func check(label: String, value: bool) -> void:
	checks.append({"name":label,"passed":value})
	print("[study-spine] ","PASS " if value else "FAIL ",label)
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var hall := args[0]; var chapter := args[1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL",OUT+"control.json"); em.set("_overrides_path",OUT+"unused.json"); em.set("_hand_path",OUT+"hand.json")
	em.set("start_chapter",chapter); em.set("start_map",hall)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream",{})["bodies"] = 1; em.set("_layout",layout)
	var control := FileAccess.open(OUT+"control.json",FileAccess.WRITE)
	control.store_string(JSON.stringify({"first_chapter":chapter,"dollhouse":0,"grid_pack":1}))
	control.close()
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var seg: Node3D
	for record: Dictionary in em.get("_segments"):
		if record.node.get_meta("em_map","") == hall: seg = record.node; break
	check(hall+" assembled",seg != null)
	if seg == null: finish(hall); return
	for i in 30: await process_frame
	# Retain the assembled floor bodies when freezing only simulation/camera control.
	for body in em.find_children("*","CollisionObject3D",true,false):
		body.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	em.process_mode = Node.PROCESS_MODE_DISABLED; em.set("_shot_path","private-study-capture")
	var player: Node3D = em.get("_player")
	if player: player.hide()
	for timer in em.find_children("*","Timer",true,false): timer.stop()
	var camera := Camera3D.new(); root.add_child(camera); camera.fov = 64; em.set("_cam",camera)
	for overlay in root.find_children("*","CanvasLayer",true,false): overlay.hide()
	for ui in root.find_children("*","Control",true,false):
		# Rack faces are exhibit surfaces, not a player HUD.
		if not ui.get_viewport() is SubViewport: ui.hide()
	var stations: Array = []
	for node in seg.find_children("*","Node3D",true,false):
		if node.get_script() == load("res://commons/artifacts/spine_studies/station.gd"): stations.append(node)
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+hall+"/map_data.json"))["map_info"]["museum"]["reference_studies"]
	check("all authored stations spawned",stations.size() == expected.size())
	for station in stations:
		station.process_mode = Node.PROCESS_MODE_ALWAYS
		camera.global_position = station.to_global(Vector3(4,1.7,station.console_z+2.0))
		camera.look_at(station.to_global(Vector3(0,1.5,0))); camera.make_current()
		for i in 8: em.call("_cull_artifacts"); await process_frame
		check(station.study+" full size",station.global_basis.get_scale().is_equal_approx(Vector3.ONE))
		check(station.study+" visible",station.is_visible_in_tree())
		check(station.study+" controls outside occupied zone",station.can_change())
		var body = station.specimen
		# Exercise the same pointer-event entry used by desktop and XR pointers.
		for button in station.controls: button.pointer_event(Press.new())
		for i in 6: await physics_frame
		match station.study:
			"tube":
				await load("res://commons/testing/tube_painting_checks.gd").new().run(self,station,camera)
			"paired_time":
				await load("res://commons/testing/paired_time_checks.gd").new().run(self,station,camera)
			"tension":
				await load("res://commons/testing/tension_checks.gd").new().run(self,station,camera)
			"network":
				var records_before: String = JSON.stringify(body.RECORDS)
				var counts_before: Array = []
				for n in 8: counts_before.append(body.degree(n))
				station.controls[0].pointer_event(Press.new())
				check("layout retains every directed record",body.arrangement == 1 and JSON.stringify(body.RECORDS) == records_before)
				var same_counts := true
				for n in 8: same_counts = same_counts and body.degree(n) == counts_before[n]
				check("layout preserves computed degree",same_counts and body.degree(0) == Vector2i(0,2))
				station.controls[1].pointer_event(Press.new())
				check("filter selects three grant records",body.visible_edges().size() == 3 and body.degree(4) == Vector2i.ZERO)
				station.controls[2].pointer_event(Press.new())
				check("record control selects inspectable source",body.selected in body.visible_edges() and body.record_label.text.contains("F02"))
			"sentence":
				station.controls[3].pointer_event(Press.new())
				check("same sentence on label and whole strip",body.small.text == body.strip.text)
				station.controls[1].pointer_event(Press.new())
				check("pace changes duration without words",is_equal_approx(body.seconds_per_word,1.7) and body.small.text == body.SENTENCES[0])
				station.controls[2].pointer_event(Press.new())
				var elapsed: float = body.elapsed
				for i in 8: await process_frame
				check("hold freezes word clock",is_equal_approx(elapsed,body.elapsed))
				station.controls[0].pointer_event(Press.new())
				check("sentence selection reaches all displays",body.small.text == body.SENTENCES[1] and body.strip.text == body.SENTENCES[1])
			"witness":
				body.find_sources()
				check("sources are four actual museum readouts",body.ready_sources and body.sources.size() == 4)
				if body.ready_sources:
					var shared := true
					for viewport in body.viewports: shared = shared and viewport.world_3d == station.get_world_3d()
					check("all cameras share actual museum world",shared)
					check("two portable camera bodies and one fixed camera",body.handles.size() == 2 and body.cameras.size() == 3)
					var fixed_pose: Transform3D = body.cameras[2].global_transform
					var grabber := SuppliedGrabber.new(); root.add_child(grabber)
					for i in 2:
						var handle = body.handles[i]
						var home: Transform3D = handle.global_transform
						grabber.global_transform = home; handle.pick_up(grabber)
						check("XR pickup camera "+str(i),handle.is_picked_up())
						grabber.position += Vector3(0.55,0.12,0.2); grabber.rotate_y(0.3)
						for frame in 8: await physics_frame
						body.sync_portable_cameras()
						check("camera follows held translation and rotation "+str(i),handle.global_position.distance_to(home.origin) > 0.2 and not handle.global_basis.is_equal_approx(home.basis) and body.cameras[i].global_transform.is_equal_approx(handle.lens_pose()))
						check("return refuses to move held camera "+str(i),not body.return_cameras())
						handle.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
						var left_pose: Transform3D = handle.global_transform
						for frame in 6: await physics_frame
						check("released camera keeps its aim "+str(i),not handle.is_picked_up() and handle.freeze and handle.global_transform.is_equal_approx(left_pose))
					check("fixed reference camera stays still",body.cameras[2].global_transform.is_equal_approx(fixed_pose))
					grabber.queue_free(); body.return_cameras()
					var pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new(); root.add_child(pointer)
					pointer.set_process(false); pointer._camera = camera
					var viewer_pose := camera.global_transform
					camera.global_position = body.handles[0].to_global(Vector3(0,0,1.5)); camera.look_at(body.handles[0].global_position)
					for frame in 3: await physics_frame
					check("desktop ray finds physical camera",pointer._find_grabbable() == body.handles[0])
					pointer._grab_held(body.handles[0]); pointer._process(0.016)
					check("desktop grab guards return",body.handles[0].desktop_held and not body.return_cameras())
					pointer._drop_held()
					check("desktop drop restores stationary pickable",not body.handles[0].desktop_held and body.handles[0].freeze and body.handles[0].collision_layer == 4)
					pointer.queue_free(); camera.global_transform = viewer_pose
					station.controls[3].pointer_event(Press.new())
					check("return button restores both homes",body.handles[0].global_transform.is_equal_approx(body.home_poses[0]) and body.handles[1].global_transform.is_equal_approx(body.home_poses[1]))
					# A temporary exposure target in the ACTUAL hall proves pixel latency.
					# It is removed before the published museum photograph.
					var target: Node3D = body.sources[0]
					var beacon := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = Vector3(2,2,0.10); beacon.mesh = box
					var surface := StandardMaterial3D.new(); surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					surface.albedo_color = Color.RED; beacon.material_override = surface; target.add_child(beacon); beacon.position = Vector3(0,1.05,0.30)
					var original: Transform3D = body.cameras[0].global_transform
					body.cameras[0].global_position = target.to_global(Vector3(0,1.05,2.0)); body.cameras[0].look_at(beacon.global_position)
					body.handles[0].global_transform = body.cameras[0].global_transform * Transform3D(Basis.IDENTITY,Vector3(0,0,0.32))
					await create_timer(4.6).timeout
					check("delay contains genuinely earlier exposure",not body.delayed_frame.is_empty() and float(body.latest.get("time",0))-float(body.delayed_frame.get("time",0)) >= 3.0)
					station.controls[2].pointer_event(Press.new())
					var held_time: float = body.held_frame.get("time",-1)
					surface.albedo_color = Color.GREEN
					await create_timer(0.7).timeout
					var live: Image = body.latest.get("image")
					var late: Image = body.delayed_frame.get("image")
					check("live green exposure while delay retains red",live != null and late != null and live.get_pixel(192,108).g > 0.7 and late.get_pixel(192,108).r > 0.7)
					check("held frame retains red and original exposure time",body.held and body.held_frame.time == held_time and body.held_frame.image.get_pixel(192,108).r > 0.7 and body.held_frame.has("pose"))
					check("frame buffer bounded",body.frames.size() <= body.MAX_FRAMES)
					check("feed cameras do not take player camera",root.get_camera_3d() == camera)
					station.controls[0].pointer_event(Press.new())
					check("viewpoint change flushes delay and preserves held source",body.frames.is_empty() and body.delayed_frame.is_empty() and body.held_frame.time == held_time)
					beacon.queue_free(); body.cameras[0].global_transform = original; body.return_cameras()
			"assembly":
				var ids: Array = []; for panel in body.panels: ids.append(panel.get_instance_id())
				station.controls[1].pointer_event(Press.new())
				check("screens selected by pointer",body.arrangement == 1)
				station.controls[3].pointer_event(Press.new())
				check("colour preserves arrangement",body.arrangement == 1 and body.colour_rule == 1)
				var same := true
				for i in ids.size(): same = same and body.panels[i].get_instance_id() == ids[i]
				check("panel identities retained",same)
				station.controls[2].pointer_event(Press.new())
			"wall":
				station.controls[0].pointer_event(Press.new()); station.controls[1].pointer_event(Press.new())
				check("spacing and depth pointers",is_equal_approx(body.spacing,0.21) and is_equal_approx(body.projection,0.52))
				station.controls[2].pointer_event(Press.new())
				check("omission hides rail and collider",body.omitted and not body.rails[5].visible and body.rails[5].get_node("Solid").collision_layer == 0)
				station.controls[2].pointer_event(Press.new())
				check("restoration restores collider",body.rails[5].get_node("Solid").collision_layer == 1)
			"signal":
				station.controls[2].pointer_event(Press.new())
				check("permutation preserves counts",body.mode == 2 and body.values.count(1) == 2048)
				station.controls[4].pointer_event(Press.new())
				check("row offset advanced",body.row_offset == 1)
				station.controls[1].pointer_event(Press.new())
			"cut":
				station.controls[1].pointer_event(Press.new())
				check("shared cutter translated",is_equal_approx(body.cut_x,0.75))
				for i in 5: await physics_frame
				var meshes := true
				for wall in body.walls: meshes = meshes and wall.get_meshes().size() == 2
				check("CSG meshes built in museum",meshes)
			"open":
				station.controls[1].pointer_event(Press.new())
				check("25 addressed forms",body.records.size() == 25)
				station.controls[3].pointer_event(Press.new())
				check("selection rule changes",body.alternative and body.form_at(0,1) == 0)
			"hinge":
				station.controls[5].pointer_event(Press.new()); station.controls[2].pointer_event(Press.new())
				for i in 3: await process_frame
				station.controls[3].pointer_event(Press.new()); station.controls[4].pointer_event(Press.new())
				for i in 80: await process_frame
				check("return policy available",station.release_score.return_on_release)
			"pink":
				station.controls[1].pointer_event(Press.new())
				check("second lamp added",body.mask == 3)
				station.controls[5].pointer_event(Press.new())
				check("pink material comparison",body.pink_material)
				station.controls[5].pointer_event(Press.new())
			"void":
				station.controls[0].pointer_event(Press.new())
				check("chalk comparison selected",not body._black_surface)
				station.controls[0].pointer_event(Press.new())
			_:
				station.controls[0].pointer_event(Press.new())
				check(station.study+" amount changed by pointer",is_equal_approx(body.amount,0.75))
		if station.study in ["assembly","wall","passage","cut","open"]:
			var before := camera.global_position
			camera.global_position = station.to_global(Vector3(station.guard_rect.get_center().x,1.7,station.guard_rect.get_center().y))
			check(station.study+" occupied-area guard",not station.can_change())
			camera.global_position = before
		# Inspect a museum-floor bypass beside each study, outside its own footprint.
		for x in [-9.0,9.0]:
			var at: Vector3 = station.to_global(Vector3(x,1.6,0))
			var hit: Dictionary = station.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,at+Vector3.DOWN*3.0,1))
			check(station.study+" bypass floor "+str(x),not hit.is_empty())
		# Reset through the museum button, then keep one deliberate presentation state.
		station.controls[8 if station.study == "tube" else -1].pointer_event(Press.new())
		if station.study == "tube": station.controls[11].pointer_event(Press.new())
		if station.study == "network": check("network reset",body.arrangement == 0 and body.filter_index == 0 and body.selected == 0)
		if station.study == "sentence": check("sentence reset",body.sentence == 0 and not body.paused and not body.whole_strip and is_equal_approx(body.seconds_per_word,0.85))
		if station.study == "witness": check("witness reset",body.view_index == 0 and not body.held and body.frames.is_empty() and is_equal_approx(body.delay_seconds,3))
		if station.study == "assembly": station.controls[2].pointer_event(Press.new())
		if station.study == "wall": station.controls[0].pointer_event(Press.new()); station.controls[1].pointer_event(Press.new())
		if station.study == "signal": station.controls[1].pointer_event(Press.new())
		if station.study == "hinge": station.controls[2].pointer_event(Press.new())
		if station.study == "pink": station.controls[1].pointer_event(Press.new())
		var key := ""
		for id in expected:
			var regmode := {"hinge_release":"hinge","reference_passage":"passage","open_structures":"open","reference_suspension":"suspension","reference_landscape":"landscape","sphere_in_pink":"pink","colour_assembly":"assembly","colour_wall_studies":"wall","signal_room":"signal","reference_pattern_garden":"garden","reference_plural_body":"body","conical_sightline":"cut","kapoor_void_studies":"void","evidence_network":"network","sentence_authority":"sentence","museum_witnesses":"witness"}
			regmode["tension_membrane"] = "tension"
			regmode["paired_time"] = "paired_time"
			regmode["tube_painting"] = "tube"
			if regmode[id] == station.study: key = id
		# Both side routes are sampled with a standing capsule and a floor ray.
		# This verifies room clearance beyond a single camera position.
		var place: Dictionary = expected[key]
		var bay: Array = place.bay; var cell: Array = place.cell
		var capsule := CapsuleShape3D.new(); capsule.radius = 0.24; capsule.height = 1.7
		for gx in [2,int(bay[2])-2]:
			var supported := true; var clear := true
			for gz in range(int(bay[1])+2,int(bay[3])-1):
				var local := Vector3(float(cell[0])-gx,0.9,float(cell[1])-gz)
				var query := PhysicsShapeQueryParameters3D.new(); query.shape = capsule; query.collision_mask = 1
				query.transform = Transform3D(Basis.IDENTITY,station.to_global(local))
				clear = clear and station.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
				var from: Vector3 = station.to_global(local)
				supported = supported and not station.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+Vector3.DOWN*2,1)).is_empty()
			check(key+" standing clearance along side "+str(gx),clear)
			check(key+" support along side "+str(gx),supported)
		if station.study == "hinge": camera.global_position = station.to_global(Vector3(1.35,1.65,2.0)); camera.look_at(station.to_global(Vector3(0,1.25,0)))
		if station.study == "tension": camera.global_position = station.to_global(Vector3(4.3,1.75,5.6)); camera.look_at(station.to_global(Vector3(0,1.9,0)))
		if station.study == "paired_time": camera.global_position = station.to_global(Vector3(4.8,1.7,7.3)); camera.look_at(station.to_global(Vector3(0,2.0,-1.9)))
		if station.study == "tube": camera.global_position = station.to_global(Vector3(4.9,1.8,7.8)); camera.look_at(station.to_global(Vector3(0,2.1,-1.3)))
		if station.study == "wall": camera.global_position = station.to_global(Vector3(7.0,2.0,4.5)); camera.look_at(station.to_global(Vector3(0,2.0,-3.85)))
		if station.study == "signal": camera.global_position = station.to_global(Vector3(3.5,1.7,9.5)); camera.look_at(station.to_global(Vector3(0,2.0,-9)))
		if station.study == "network": camera.global_position = station.to_global(Vector3(6.5,2.4,5)); camera.look_at(station.to_global(Vector3(0,3.5,-3.8)))
		if station.study == "sentence": camera.global_position = station.to_global(Vector3(5.5,1.9,5)); camera.look_at(station.to_global(Vector3(-0.5,3.1,-3.0)))
		if station.study == "witness":
			camera.global_position = station.to_global(Vector3(0.5,2.2,10)); camera.look_at(station.to_global(Vector3(0,2.8,-0.5)))
			await create_timer(4.5).timeout
			station.controls[2].pointer_event(Press.new())
		for i in 12: em.call("_cull_artifacts"); camera.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		check(key+" capture",root.get_texture().get_image().save_png(OUT+key+".png") == OK)
		if station.study == "witness":
			camera.global_position = body.handles[0].to_global(Vector3(0.95,0.2,-1.65))
			camera.look_at(body.handles[0].global_position+Vector3(0,-0.15,0))
			for i in 12: em.call("_cull_artifacts"); await process_frame
			await RenderingServer.frame_post_draw
			check("portable camera native capture",root.get_texture().get_image().save_png(OUT+"museum_witnesses-camera.png") == OK)
	finish(hall)
func finish(hall: String) -> void:
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"map":hall,"passed":passed,"checks":checks,"scope":"Actual endless_museum assembly, pointer-event dispatch and floor rays. No physical headset or full human traversal test."},"  "))
	quit(0 if passed else 1)
