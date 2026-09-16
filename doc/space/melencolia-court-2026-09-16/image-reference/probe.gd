extends SceneTree
## Load the real endless museum, measure both decks and photograph the encounter.
const OUT := "res://doc/space/melencolia-court-2026-09-16/image-reference/"
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func run() -> void:
	var ctl := OUT + "probe-control.json"
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"primitives","dollhouse":0,"grid_pack":1})); f.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL",ctl); em.set("_overrides_path",ctl+".unused"); em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","primitives"); em.set("start_map","Primitives_Melencolia")
	root.add_child(em); current_scene=em
	await create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")=="Primitives_Melencolia": seg=rec.node; break
	check(seg != null,"Requested hall loaded")
	if seg == null: finish([]); return
	for i in range(4): await physics_frame
	var heights: Dictionary = seg.get_meta("em_heights",{})
	var solid: StaticBody3D = seg.get_node("Collision")
	for z in range(3,8):
		for x in range(3,8):
			check(is_equal_approx(float(heights.get(Vector2i(x,z),-1)),1.0),"Court height "+str(Vector2i(x,z)))
			check(is_equal_approx(solid_top(seg,solid,x,z),1.0),"Court collision "+str(Vector2i(x,z)))
	for z in range(14,19):
		for x in range(3,8):
			check(is_equal_approx(float(heights.get(Vector2i(x,z),-1)),2.0),"Durer height "+str(Vector2i(x,z)))
			check(is_equal_approx(solid_top(seg,solid,x,z),2.0),"Durer collision "+str(Vector2i(x,z)))
	var stamps: Array = []
	var counts: Dictionary = {}
	for record: Dictionary in em.get("_edit_records"):
		var n: Node3D = record.get("node")
		if n==null or not is_instance_valid(n) or not seg.is_ancestor_of(n): continue
		if record.get("tile_cell",[]).size()!=2: continue
		var tok := str(record.token)
		counts[tok]=int(counts.get(tok,0))+1
		var p := seg.to_local(n.global_position)
		stamps.append({"token":tok,"cell":record.tile_cell,"position":[p.x,p.y,p.z],"scale":str(n.global_basis.get_scale())})
		if tok == "pyramid":
			var mesh := n.find_child("Pyramid",true,false) as MeshInstance3D
			check(mesh != null, "Corner mesh exists")
			if mesh != null:
				check(is_equal_approx(mesh.mesh.get_aabb().size.y,2.4), "Corner height is 2.4m")
				check(pigment(mesh,"B7C7DB"), "Corner is solid blue")
			check(is_equal_approx(p.y,1.0), "Corner seated on deck")
		if tok == "pyramidlong":
			var mesh := n.find_child("PyramidLong",true,false) as MeshInstance3D
			var base := n.find_child("PedestalMesh",true,false) as MeshInstance3D
			check(mesh != null and base != null, "Central spire and pedestal exist")
			if mesh != null and base != null:
				check(pigment(mesh,"DF93B8") and pigment(base,"DF93B8"), "Pink centre and matching block")
				check(is_equal_approx(seg.to_local(mesh.to_global(Vector3(0,2.8,0))).y,4.6), "Central tip is 4.6m above floor")
				check(is_equal_approx(seg.to_local(base.to_global(Vector3(0,-0.4,0))).y,1.0), "Central block meets deck")
		if tok == "cube_scene":
			var mesh := n.find_child("CubeBaseMesh",true,false) as MeshInstance3D
			check(mesh != null, "Cross cube exists")
			if mesh != null:
				check(pigment(mesh,"D9AB63"), "Cross cube is ochre")
				check(mesh.global_basis.get_scale().is_equal_approx(Vector3.ONE*0.8), "Cross cube is 0.8m")
				check(is_equal_approx(seg.to_local(mesh.to_global(Vector3(0,-0.5,0))).y,1.0), "Cross cube lower face meets deck")

	check(counts.get("pyramid",0)==4,"Four corner pyramids stamped")
	check(counts.get("pyramidlong",0)==1,"One central spire stamped")
	check(counts.get("cube_scene",0)==4,"Four small cubes stamped")
	check(counts.get("durer_scene",0)==1,"Durer tableau stamped")
	check(counts.get("bigframe",0)==2,"Both historical side frames stamped")
	check(stamps.size()==18,"All eighteen placements stamped")
	var space := seg.get_world_3d().direct_space_state
	for ends in [[Vector3(1.05,0,9.5),Vector3(2.95,0,9.5)],[Vector3(5.5,0,16.05),Vector3(5.5,0,17.95)]]:
		var tops: Array[float] = []
		for point: Vector3 in ends:
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(seg.to_global(point+Vector3.UP*3),seg.to_global(point-Vector3.UP*0.1)))
			tops.append(seg.to_local(hit.position).y if not hit.is_empty() else -99.0)
		print("[melencolia-ramp] ",ends," tops ",tops)
		check(tops[0]>=-0.01 and tops[1]-tops[0]>0.7,"Ramp rises toward its destination deck: "+str(ends))
	if "--capture" in OS.get_cmdline_user_args():
		check(DisplayServer.get_name()!="headless","Capture has a renderer")
		var cam := Camera3D.new(); em.add_child(cam); cam.fov=65
		var shots := [
			["court-entrance",Vector3(6.5,1.65,5.8),Vector3(5.5,2.4,10)],
			["reference-court",Vector3(8.8,5.2,6.0),Vector3(5.5,2.4,9.5)],
			["court-and-tableau",Vector3(10.8,9,5.8),Vector3(5.5,1.4,16)],
			["durer-approach",Vector3(7.8,3.1,16),Vector3(6.0,3.1,20)]
		]
		for shot in shots:
			cam.global_position=seg.to_global(shot[1]); cam.look_at(seg.to_global(shot[2]))
			for i in range(15): cam.make_current(); await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+shot[0]+".png")
	finish(stamps)
func solid_top(seg: Node3D,solid: StaticBody3D,x: int,z: int) -> float:
	var q := PhysicsRayQueryParameters3D.create(seg.to_global(Vector3(x+0.5,3.8,z+4.5)),seg.to_global(Vector3(x+0.5,-0.2,z+4.5)))
	q.hit_from_inside=true
	var ignored: Array[RID] = []
	for i in range(64):
		q.exclude=ignored
		var hit := seg.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty(): return -99.0
		if hit.collider==solid: return seg.to_local(hit.position).y
		ignored.append(hit.rid)
	return -98.0
func finish(stamps: Array) -> void:
	var report := {"checks":checks,"failures":failures,"placements":stamps,"headset_verified":false}
	var f := FileAccess.open(OUT+"runtime-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  ")); f.close()
	print("[melencolia] ",checks," checks; failures: ",failures)
	quit(0 if failures.is_empty() else 1)

func pigment(mesh: MeshInstance3D, html: String) -> bool:
	var m := mesh.material_override as StandardMaterial3D
	return m != null and m.albedo_color.is_equal_approx(Color.html(html)) and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
