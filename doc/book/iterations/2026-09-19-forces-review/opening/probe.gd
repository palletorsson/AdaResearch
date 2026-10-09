extends SceneTree
const BASE := "res://doc/book/iterations/2026-09-19-forces-review/opening/"
var out := BASE + "runtime/"
var before := false
var museum_mode := false
var captures := false
var originals: Array[Resource] = []
var checks: Array[Dictionary] = []
var observation: Dictionary = {}
var torque: Node3D
var cam: Camera3D
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	before = "--before" in OS.get_cmdline_user_args()
	museum_mode = "--museum" in OS.get_cmdline_user_args()
	captures = "--capture" in OS.get_cmdline_user_args()
	if museum_mode:
		var frozen := GDScript.new()
		frozen.source_code=FileAccess.get_file_as_string(BASE+"frozen-museum.gd")
		check(frozen.reload()==OK,"frozen shared museum source compiles")
		frozen.take_over_path("res://commons/scenes/endless_museum.gd")
		originals.append(frozen)
	if before:
		var saved := GDScript.new()
		saved.source_code = FileAccess.get_file_as_string(BASE + "before/commons/artifacts/torque_crank/torque_crank.gd").replace("class_name TorqueCrank", "")
		check(saved.reload() == OK, "saved original torque source compiles")
		saved.take_over_path("res://commons/artifacts/torque_crank/torque_crank.gd")
		originals.append(saved)
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"ok":ok, "message":message})
	print("TORQUE REVIEW ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	if museum_mode: await museum()
	else:
		var world := Node3D.new(); root.add_child(world); current_scene = world
		torque = load("res://commons/artifacts/torque_crank/torque_crank.tscn").instantiate(); world.add_child(torque)
		await process_frame
	if torque == null: finish(); return
	await torque_checks()
	if not museum_mode: await normalize_checks()
	if captures:
		torque.apply_grid_config({"seed":0,"leverage":0.78,"workings":"trace","purchase":"balanced"})
		torque._slider.set_normalized_value(0.78)
		torque._slider.emit_signal("slider_moved",0.78)
		await capture("standing",Vector3(0,1.65,1.6),Vector3(0,1.3,0))
		await capture("readout",Vector3(-0.4,1.45,0.95),Vector3(-0.25,1.26,0.05))
	finish()
func wheel() -> Node3D:
	return torque.demo_root.get_child(0).get_child(3)
func torque_checks() -> void:
	check(torque._slider != null, "live LEVERAGE control exists")
	var poses: Array = []
	for value in [0.0,0.5,1.0]:
		torque._slider.set_normalized_value(value)
		torque._slider.emit_signal("slider_moved",value)
		for i in 3: await process_frame
		var factor := sin(value * PI * 0.5)
		check(is_equal_approx(torque.leverage,value), "canonical slider signal sets leverage " + str(value))
		check(is_equal_approx(wheel().rotation.y, factor * deg_to_rad(48.0)), "static wheel pose follows unit cross product " + str(value))
		var text: String = torque.monitor_label.text
		check(text.contains("%d rpm" % int(round(factor*320))) if before else text.contains("sin θ = %.2f" % factor) and text.contains("static diagram") and not text.contains("rpm"), "readout states actual old or repaired quantity " + str(value))
		poses.append({"leverage":value,"factor":factor,"wheel_angle":wheel().rotation.y,"readout":text})
	var angle: float = wheel().rotation.y
	await create_timer(0.2).timeout
	check(is_equal_approx(wheel().rotation.y,angle), "wheel does not accumulate rotation with elapsed time")
	for purchase in ["balanced","long","stub"]:
		torque.apply_grid_config({"purchase":purchase,"workings":"expression","leverage":0.5})
		for i in 3: await process_frame
		var board: Label3D = torque.demo_root.find_child("Algebra",true,false)
		check(board != null and board.text.ends_with("0.32"), "equal arm/push products retain cross-product area " + purchase)
		check(is_equal_approx(wheel().rotation.y,sin(PI/4)*deg_to_rad(48)), "purchase retains displayed angular factor " + purchase)
	for workings in ["outcome","trace","operands","expression"]:
		torque.apply_grid_config({"purchase":"balanced","workings":workings,"leverage":0.78})
		for i in 3: await process_frame
		check(torque.demo_root.get_child_count()==1, "workings retains one current demo rig: " + workings)
		check(torque.monitor_label.text.contains("rpm") if before else torque.monitor_label.text.contains("static diagram"), "honest readout retained across workings: " + workings)
	observation["angle_states"] = poses
func normalize_checks() -> void:
	var norm: Node3D = load("res://commons/artifacts/vector_normalize_demo/vector_normalize_demo.tscn").instantiate()
	current_scene.add_child(norm); norm.set_process(false)
	await process_frame
	for magnitude in [0.0,0.0005,0.001,0.0011,0.25,2.0]:
		var value := Vector3(magnitude,0,0)
		norm._update_unit_vector(value); norm._update_info(value); norm._update_unit_label(value)
		var expected := 1.0 if magnitude>=0.001 else 0.0
		if magnitude==0.001:
			observation["nominal_threshold"]={"requested_decimal":magnitude,"stored_length":value.length(),"threshold":0.001}
			check(value.length()>0.001,"single-precision Vector3 stores nominal 0.001 slightly above comparison threshold")
		var end: Node3D = norm._cached_unit_nodes.end
		check(is_equal_approx(end.position.length(),expected), "normalization geometry threshold " + str(magnitude))
		check(norm.info_label.text.ends_with("%.3f" % expected), "normalization numeric output matches threshold " + str(magnitude))
		check(norm.unit_label.visible == (expected>0), "zero neighbourhood has no tip label " + str(magnitude))
	norm.queue_free()
func museum() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	check(em.get_script().source_code==FileAccess.get_file_as_string(BASE+"frozen-museum.gd"),"actual museum scene loaded the frozen script bytes")
	observation["loaded_museum_source_sha256"]=em.get_script().source_code.sha256_text()
	var ctl := out + "museum-control.json"
	var f := FileAccess.open(ctl,FileAccess.WRITE); f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","forces");em.set("start_map","Vectors_Act2_VectorArithmetic")
	root.add_child(em);current_scene=em
	await create_timer(1.0).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var segment: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")=="Vectors_Act2_VectorArithmetic":segment=rec.node
	check(segment != null,"actual Vector Arithmetic museum segment loads")
	if not segment:return
	for i in 30:await process_frame
	var player: CharacterBody3D = em.get("_player"); player.set_physics_process(false)
	em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	for node in segment.find_children("*","Node3D",true,false):
		if node.get_meta("artifact_lookup_name","")=="torque_crank":torque=node;break
	check(torque!=null,"authored torque crank found in actual hall")
	if not torque:return
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and segment.is_ancestor_of(n):n.visible=true
	cam=Camera3D.new();em.add_child(cam);cam.fov=56
	var capsule:=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.exclude=[player.get_rid()]
	query.transform.origin=torque.to_global(Vector3(0,0.85,1.6))
	await physics_frame
	check(torque.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"standing capsule fits before torque console")
	observation["torque_world_position"]=[torque.global_position.x,torque.global_position.y,torque.global_position.z]
func capture(id: String,position: Vector3,target: Vector3) -> void:
	var pos:=torque.to_global(position);var aim:=torque.to_global(target)
	cam.global_position=pos;cam.look_at(aim);cam.make_current()
	for i in 20:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+id+".png")
	var f:=FileAccess.open(out+id+"-camera.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":[pos.x,pos.y,pos.z],"target":[aim.x,aim.y,aim.z],"fov":cam.fov,"viewport":[root.size.x,root.size.y]},"  "));f.close()
func finish() -> void:
	var failures:=checks.filter(func(item):return not item.ok)
	var f:=FileAccess.open(out+"verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observation,"replay_before":before,"headset_tested":false,"interaction":"slider set_normalized_value plus canonical slider_moved signal; no physical hand dragging"},"  "));f.close()
	print("FORCES OPENING CHECKS ",checks.size()," FAILURES ",failures.size())
	quit(0 if failures.is_empty() else 1)
