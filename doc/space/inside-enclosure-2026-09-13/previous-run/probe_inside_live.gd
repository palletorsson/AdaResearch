extends Node
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Noise_Inside_Noise"
const OUT := "res://ada_run/inside-review-2026-09-13/Noise_Inside_Noise/"
const MAP_CELL := Vector2i(5, 2)
const SPOT := Vector3(9.5, 0.0, 5.2)    # the visitor's spot: before the instrument, which the
                                        # token's 180 turns toward the hall's north door
const EYE_H := 1.6

func _ready() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[inside-review] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[inside-review] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/inside-review-2026-09-13/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_plan_path", "res://ada_run/inside-review-2026-09-13/review-plan.json")
	em.set("_hand_path", "res://ada_run/inside-review-2026-09-13/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "noise"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "noise", "dollhouse": 0, "grid_pack": 1})); f.close()
	get_tree().root.add_child(em); get_tree().current_scene = em
	await get_tree().create_timer(1.0).timeout
	em.set_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == MAP: seg = rec.node; break
	check(seg != null, "the hall exists in the active museum")
	if seg == null:
		_finish(); return
	for i in range(30): await get_tree().process_frame
	var vest: int = int(em.get("VESTIBULE_H"))
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	var cam: Camera3D
	if capture:
		var wc: Camera3D = em.get("_cam")
		if wc != null and is_instance_valid(wc):
			for c in wc.get_children():
				if c is Timer: (c as Timer).stop()
		cam = Camera3D.new(); em.add_child(cam); cam.fov = 62
	measurements["captures"] = {}

	var records: Array = []
	var works: Dictionary = {}
	for rec: Dictionary in em.get("_edit_records"):
		var n: Node3D = rec.get("node") as Node3D
		if n == null or not seg.is_ancestor_of(n): continue
		var token: String = str(rec.get("token", ""))
		if token not in ["noisesphere", "dark_sphere"]: continue
		works[token] = n
		var meshes: Array = []
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh and mi.is_visible_in_tree():
				var box: AABB = seg.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
				meshes.append({"name": str(mi.name), "position": [box.position.x,box.position.y,box.position.z-vest], "size": [box.size.x,box.size.y,box.size.z]})
		records.append({"token":token,"position":str(seg.to_local(n.global_position)),"meshes":meshes})
	measurements["inventory"] = records
	check(works.size()==2,"both authored works exist")
	await review_works(works,seg,em,cam,vest)
	await shot(cam, seg.to_global(Vector3(6.5,16,6.5+vest)), seg.to_global(Vector3(6.48,0,6.5+vest)), "plan")
	_finish()

func shot(cam: Camera3D, at: Vector3, target: Vector3, name_: String, field_of_view: float=68) -> void:
	cam.global_position=at;cam.look_at(target);cam.fov=field_of_view
	for i in range(16): cam.make_current();await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+name_+".png")

func _finish() -> void:
	var f:=FileAccess.open(OUT+"probe_inside_live.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"map":MAP,"checks":checks,"failures":failures,"measurements":measurements,"headset_verified":false},"  "));f.close()
	print("Inside review: ",checks," checks; failures: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func review_works(works: Dictionary, seg: Node3D, em: Node3D, cam: Camera3D, vest: int) -> void:
	var study: Node3D=works.noisesphere.get_node_or_null("WarpStudy")
	check(study!=null,"sphere builds the optional coordinate study")
	if study==null:return
	var foreign: Node3D=load("res://algorithms/randomness/noisesphere/noisesphere.tscn").instantiate();foreign.visible=false;get_tree().root.add_child(foreign)
	var old_mesh: MeshInstance3D=foreign.get_node("MeshInstance3D4")
	var old_material: Material=old_mesh.material_override
	check(not foreign.has_node("WarpStudy") and old_mesh.mesh is SphereMesh and old_mesh.scale.length()>40,"unconfigured legacy dome remains large and separate")
	check(study.spheres[0].material_override!=old_material and study.spheres[1].material_override!=old_material,"comparison owns its materials")
	check(study.base.seed==4 and study.base.noise_type==FastNoiseLite.TYPE_VALUE and study.base.fractal_type==FastNoiseLite.FRACTAL_NONE,"base generator contract is explicit")
	check(study.warp_x.seed==19 and study.warp_z.seed==47 and study.warp_x.fractal_type==FastNoiseLite.FRACTAL_NONE,"two coordinate offsets have explicit fixed seeds")
	var direct: Array=study.values[0].duplicate();var revision: int=study.revision;var orb_time: float=works.dark_sphere.get("_time_elapsed")
	await get_tree().create_timer(0.25).timeout
	check(study.revision==revision and study.values[0]==direct,"comparison stays still without any clock control")
	check(works.dark_sphere.get("_time_elapsed")>orb_time,"retained orb keeps its independent time")
	var original_shapes: Array=[]
	for c: CollisionShape3D in study.find_children("*","CollisionShape3D",true,false):original_shapes.append(c.shape.get_instance_id())
	measurements["cases"]=[]
	for index in range(4):
		study.strength_index=index;study.relief=false;study.refresh()
		var amount: float=study.strength();var rec: Dictionary=study.selected()
		var p:=Vector2(rec.p[0],rec.p[1]);var q:=Vector2(rec.q[0],rec.q[1])
		var expected:=p+amount*Vector2(study.warp_x.get_noise_2d(p.x,p.y),study.warp_z.get_noise_2d(p.x,p.y))
		check(q.is_equal_approx(expected) and is_equal_approx(rec.warped,study.base.get_noise_2d(q.x,q.y)),"selected address and evaluation agree at warp %.2f" % amount)
		check(study.values[0]==direct,"base plate is unchanged at warp %.2f" % amount)
		var vertices0: PackedVector3Array=study.spheres[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var vertices1: PackedVector3Array=study.spheres[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(vertices0==vertices1,"SKIN keeps both sphere geometries identical at warp %.2f" % amount)
		var changed: int=0
		for j in range(direct.size()):
			if absf(direct[j]-study.values[1][j])>0.00001:changed+=1
		check((changed==0 and study.images[0].get_data()==study.images[1].get_data()) if index==0 else changed>direct.size()/2,"zero identity or changed output at warp %.2f" % amount)
		var c: Dictionary={"strength":amount,"selected":rec,"changed_samples":changed,"samples":direct.size(),"vertices":vertices0.size(),"probes":[]}
		for sample_i in range(5):study.sample_index=sample_i;c.probes.append(study.selected())
		study.sample_index=0;study._update_witness()
		study.images[0].save_png(OUT+"direct_%d.png" % index);study.images[1].save_png(OUT+"warped_%d.png" % index)
		measurements.cases.append(c)
		await shot(cam,study.to_global(Vector3(0,2.1,3.45)),study.to_global(Vector3(0,1.1,0.2)),"skin_%d" % index,90)
	study.strength_index=2;study.refresh()
	await shot(cam,study.to_global(Vector3(0,1.75,3.1)),study.get_node("Instrument").global_position,"instrument",96)
	await shot(cam,study.to_global(Vector3(0,1.75,3.5)),study.get_node("Instrument/Readout").global_position,"readout",80)
	var texture_before: PackedByteArray=study.images[1].get_data()
	var vertex_before: PackedVector3Array=study.spheres[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	study.toggle_relief()
	check(study.images[1].get_data()==texture_before,"RELIEF preserves the field image")
	var va: Array=study.spheres[1].mesh.surface_get_arrays(0);var vv: PackedVector3Array=va[Mesh.ARRAY_VERTEX]
	var error: float=0
	for i in range(vv.size()):
		# SurfaceTool may reorder indexed vertices while rebuilding normals.
		# Recover the sample direction from each actual output vertex.
		var dir: Vector3=vv[i].normalized()
		var p:=Vector2(dir.x,dir.z)*3.0;var q: Vector2=study.address_at(p,study.strength())
		var radius: float=0.94+0.16*study.base.get_noise_2d(q.x,q.y)
		error=maxf(error,vv[i].distance_to(dir*radius))
	check(error<0.0001 and vv!=vertex_before,"RELIEF places every vertex from its warped sample")
	measurements["relief_max_error"]=error
	await shot(cam,study.to_global(Vector3(0,2.1,3.45)),study.to_global(Vector3(0,1.1,0.2)),"relief",90)
	study.zero_warp()
	check(study.spheres[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==study.spheres[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"zero warp restores identical relief geometry")
	var after_shapes: Array=[]
	for c: CollisionShape3D in study.find_children("*","CollisionShape3D",true,false):after_shapes.append(c.shape.get_instance_id())
	check(original_shapes==after_shapes,"field and relief controls preserve staging collision")
	study.strength_index=2;study.relief=false;study.refresh()
	var before_field: Array=study.values[1].duplicate();var witness: Array=study._grid.mesh.surface_get_arrays(0)
	study.next_sample();var selected: Dictionary=study.selected();var pp:=Vector2(selected.p[0],selected.p[1]);var qq:=Vector2(selected.q[0],selected.q[1])
	check(study.values[1]==before_field,"SAMPLE moves the witness without changing the field")
	check(study._plate_markers[1].position.is_equal_approx(Vector3(-1.53,0.08,0.04)+study._plot(qq)),"pink marker locates q on the base plate")
	check(study._plate_markers[2].position.is_equal_approx(Vector3(0,0.08,0.03)+study._plot(pp)),"warped plate retains the original p address")
	check(witness[Mesh.ARRAY_VERTEX].size()==2306,"coordinate witness includes direct and displaced grids")
	var driver: Node=load("res://commons/testing/wcn_desktop_driver.gd").new();get_tree().root.add_child(driver)
	var controls: Node3D=study.get_node("Controls")
	var approach: Vector3=study.to_global(Vector3(2.62,0.10,2.25));driver.spawn(approach,em)
	for i in range(20):await get_tree().physics_frame
	approach=driver.rig.global_position;measurements["pointer"]=[]
	for entry in [[0,"WARP","strength_index"],[1,"SAMPLE","sample_index"],[2,"RELIEF","relief"],[3,"ZERO","strength_index"]]:
		var before: Variant=study.get(entry[2]);var rec: Dictionary=await driver.press(controls.find_child("Btn_%d" % entry[0],true,false),approach)
		var after: Variant=study.get(entry[2]);measurements.pointer.append({"control":entry[1],"before":before,"after":after,"hover":rec.hover})
		check(str(rec.hover).contains("InteractableAreaButton") and before!=after,"desktop pointer operates %s" % entry[1])
	check(seg.to_local(driver.rig.global_position).y>-0.1,"controls have a physical standing approach")
	driver.rig.global_position=seg.to_global(Vector3(1.5,0.12,2.1+vest));driver.rig.velocity=Vector3.ZERO
	for i in range(20):await get_tree().physics_frame
	var start: Vector3=seg.to_local(driver.rig.global_position)
	driver.aim_at(seg.to_global(Vector3(1.5,1.6,10+vest)));await driver.walk("ui_up",70)
	var end: Vector3=seg.to_local(driver.rig.global_position)
	measurements["apron_walk"]={"start":str(start),"end":str(end)}
	check(end.z>7.5+vest and end.y>-0.1,"desktop body walks the apron alongside the study")
	driver.rig.global_position=seg.to_global(Vector3(11.5,0.12,11.5+vest));driver.rig.velocity=Vector3.ZERO
	for i in range(20):await get_tree().physics_frame
	driver.aim_at(seg.to_global(Vector3(11.5,1.6,16+vest)));await driver.walk("ui_up",24)
	var turn: Vector3=seg.to_local(driver.rig.global_position)
	driver.aim_at(seg.to_global(Vector3(6,1.6,13.5+vest)));await driver.walk("ui_up",48)
	var exit_end: Vector3=seg.to_local(driver.rig.global_position)
	measurements["exit_walk"]={"turn":str(turn),"end":str(exit_end)}
	check(turn.z>13.0+vest and exit_end.x<8.5 and exit_end.y>-0.1,"desktop body follows the ground passage around the preserved exit wall")
	check(old_mesh.material_override==old_material and not foreign.has_node("WarpStudy"),"local controls leave the legacy dome untouched")
	measurements["museum_walk_severed"]=[]
	for r: Dictionary in em.get("_walk_severed"):
		if str(r.get("hall","")).contains(MAP):measurements.museum_walk_severed.append(r)
	check(measurements.museum_walk_severed.is_empty(),"museum route is connected")
	measurements["walk_diagnostic"]=[]
	for cell: Vector2i in em.get("_walk_cells"):
		if cell.y>=-4 and cell.y<=16:
			measurements.walk_diagnostic.append({"x":cell.x,"z":cell.y,"h":em.get("_walk_h").get(cell,0.0),"reachable":em.get("_reach").has(cell),"climb":em.get("_walk_climb").has(cell)})
	driver.teardown();foreign.queue_free();study.strength_index=2;study.relief=false;study.sample_index=0;study.refresh()
	await shot(cam,works.dark_sphere.global_position+seg.global_basis*Vector3(0,1.3,-1.7),works.dark_sphere.global_position+Vector3.UP*0.4,"orb")
