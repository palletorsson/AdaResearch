extends SceneTree

const RUN := "res://ada_run/melencolia_restore/probe_runtime/"
const MAP := "Primitives_Melencolia"
var _fails: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func _arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func _run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUN + "spec.json"))
	var m: Node3D = (load(RUN + "museum_snapshot.tscn") as PackedScene).instantiate() as Node3D
	m.set("EM_CONTROL", RUN + "control.json")
	m.set("_hand_path", RUN + "necklace_hand.json")
	m.set("_overrides_path", RUN + "em_overrides.json")
	m.set("start_chapter", "primitives")
	m.set("start_map", MAP)
	root.add_child(m)
	var start := Time.get_ticks_msec()
	while not bool(m.get("_museum_core_ready")) and Time.get_ticks_msec() - start < 60000:
		await process_frame
	m.set("_lazy_pending", 0)
	m.set_process(false)
	m.set_physics_process(false)
	m.call("flush_stamps")
	await create_timer(1.2).timeout
	var seg: Node3D = null
	for child in m.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == MAP:
			seg = child
			break
	if seg == null:
		push_error("Melencolia did not load as the actual museum hall")
		quit(1)
		return
	var origin := seg.global_position + Vector3(0, 0, 4)
	var report := {"map":MAP,"scene":"endless_museum.tscn with output-only script path substitutions", "origin":_arr(origin),
		"source_manifest": RUN+"source_manifest.json", "scope":"Actual museum geometry, artifact placements and physics probes; no human or VR walkthrough claim.",
		"bodies":[],"rays":[],"walks":[],"shots":[],"wedges":[]}
	for rec_v in m.get("_edit_records"):
		var rec: Dictionary = rec_v
		var node: Node3D = rec.get("node") as Node3D
		if node == null or not is_instance_valid(node) or rec.get("seg") != seg:
			continue
		var bounds: AABB = m.call("_seat_extent", node)
		(report["bodies"] as Array).append({"token":rec.get("token",""),"kind":rec.get("kind",""),
			"map_cell":rec.get("from",[]),"position":_arr(node.global_position-origin),"scale":_arr(node.scale),
			"rotation_degrees":_arr(node.rotation_degrees),"bounds_bottom":bounds.position.y-origin.y,
			"bounds_size":_arr(bounds.size)})
		if str(rec.get("token", "")) == "durer_scene":
			var pieces: Array = []
			for mesh in node.find_children("*", "MeshInstance3D", true, false):
				var mi := mesh as MeshInstance3D
				if mi.mesh == null: continue
				var bb: AABB = mi.global_transform * mi.get_aabb()
				pieces.append({"path":str(node.get_path_to(mi)),"bottom":bb.position.y-origin.y,"size":_arr(bb.size),"position":_arr(mi.global_position-origin)})
			report["durer_meshes"] = pieces
	for wedge in seg.find_children("Wedge_*", "Node3D", true, false):
		(report["wedges"] as Array).append({"name":str(wedge.name),"position":_arr((wedge as Node3D).global_position-origin)})
	var court_corners: Array = []
	var long_middle: Array = []
	var cubes: Array = []
	for row in report["bodies"]:
		var pos: Array = row["position"]
		var tok: String = row["token"]
		if tok == "pyramid" and float(pos[2]) >= 9.0:
			court_corners.append([float(pos[0]),float(pos[2])])
			if absf(float(row["bounds_bottom"])-1.0)>0.03: _fails.append("corner pyramid unsupported")
			if absf(float((row["scale"] as Array)[0])-1.0)>0.01: _fails.append("corner pyramid unequal scale")
		if tok == "pyramidlong":
			long_middle.append(row)
			if Vector2(float(pos[0])-5.5,float(pos[2])-11.5).length()>0.03 or absf(float(row["bounds_bottom"])-1.0)>0.03:
				_fails.append("long pyramid moved or unsupported")
		if tok == "cube_scene" and float(pos[2])>=9.0:
			cubes.append(row)
			if absf(float(row["bounds_bottom"])-1.0)>0.03: _fails.append("half cube unsupported")
		if tok == "durer_scene":
			if absf(float(pos[1])-2.0)>0.03: _fails.append("Durer tableau origin off its deck")
			var sphere_supported := false
			for piece in report.get("durer_meshes", []):
				if str(piece["path"])=="Sphere": sphere_supported=absf(float(piece["bottom"])-2.0)<0.03
			if not sphere_supported: _fails.append("Durer sphere not seated on deck")
			report["durer_native_geometry_note"]="The Polyhedron child reaches 0.225m below the tableau origin at scale0.5; Sphere base sits at the origin. Whole-tableau lift would float the sphere. Native composition retained."
	for expected in [[3.5,9.5],[7.5,9.5],[3.5,13.5],[7.5,13.5]]:
		var found := false
		for actual in court_corners:
			if Vector2(float(actual[0])-float(expected[0]),float(actual[1])-float(expected[1])).length()<0.03:
				found=true
		if not found: _fails.append("missing exact pyramid corner "+str(expected))
	if court_corners.size()!=4: _fails.append("expected 4 court pyramids; found "+str(court_corners.size()))
	if long_middle.size()!=1: _fails.append("expected 1 long centre pyramid")
	if cubes.size()!=4: _fails.append("expected 4 half cubes")
	await physics_frame
	var space := seg.get_world_3d().direct_space_state
	for row_v in spec.get("rays", []):
		var row: Dictionary = row_v
		var x := float(row["x"])
		var z := float(row["z"])
		var ray := PhysicsRayQueryParameters3D.create(origin+Vector3(x, 20, z), origin+Vector3(x, -1, z))
		ray.collision_mask = 1
		var hit := space.intersect_ray(ray)
		var out := {"tag":row.get("tag",""),"x":x,"z":z,"hit":not hit.is_empty()}
		if not hit.is_empty():
			out["top"] = (hit["position"] as Vector3).y-origin.y
			out["collider"] = str((hit["collider"] as Node).get_path())
		var ok: bool = not hit.is_empty() and (not row.has("top") or absf(float(out.get("top",-999))-float(row["top"])) <= float(row.get("tolerance",0.06)))
		out["passed"] = ok
		if not ok: _fails.append("ray: " + str(row.get("tag","")))
		(report["rays"] as Array).append(out)
	var walker: CharacterBody3D = m.get("_player")
	m.set("_player", null)
	for row_v in spec.get("walks", []):
		var row: Dictionary = row_v
		if walker == null:
			_fails.append("No museum CharacterBody3D available")
			break
		var from: Vector3 = _vec(row["from"])+origin
		var to: Vector3 = _vec(row["to"])+origin
		walker.global_position = from
		walker.velocity = Vector3.ZERO
		for i in range(int(float(row.get("seconds",5.0))*60)):
			var delta: Vector3 = to-walker.global_position
			delta.y=0.0
			var dir := delta.normalized() if delta.length()>0.1 else Vector3.ZERO
			walker.velocity = Vector3(dir.x*2.0, 0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60.0, dir.z*2.0)
			walker.move_and_slide()
			await physics_frame
		var actual := walker.global_position
		var collisions: Array = []
		for ci in range(walker.get_slide_collision_count()):
			var collision := walker.get_slide_collision(ci)
			collisions.append({"collider":str((collision.get_collider() as Node).get_path()),"position":_arr(collision.get_position()-origin),"normal":_arr(collision.get_normal())})
		var error := Vector2(actual.x-to.x, actual.z-to.z).length()
		var ok := error<float(row.get("tolerance",0.3)) and absf(actual.y-to.y)<float(row.get("height_tolerance",0.15))
		(report["walks"] as Array).append({"tag":row.get("tag",""),"end":_arr(actual-origin),"target":row["to"],"horizontal_error":error,"passed":ok,"end_collisions":collisions})
		if not ok: _fails.append("walk: "+str(row.get("tag","")))
	if DisplayServer.get_name() != "headless":
		var old_camera: Camera3D = m.get("_cam")
		if old_camera != null:
			for timer in old_camera.find_children("*", "Timer", true, false):
				(timer as Timer).stop()
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.current=true
		for row_v in spec.get("shots", []):
			var row: Dictionary = row_v
			camera.global_position=_vec(row["from"])+origin
			camera.look_at(_vec(row["look_at"])+origin)
			camera.fov=float(row.get("fov",70))
			camera.current=true
			await create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			var target := RUN+str(row.get("tag","shot"))+".png"
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(target))
			(report["shots"] as Array).append(target)
	report["failures"] = _fails
	report["passed"] = _fails.is_empty()
	var f := FileAccess.open(RUN+"report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	f.close()
	print("MELENCOLIA PROBE ", "PASS" if _fails.is_empty() else "FAIL", ": ", str(_fails))
	quit(0 if _fails.is_empty() else 1)
