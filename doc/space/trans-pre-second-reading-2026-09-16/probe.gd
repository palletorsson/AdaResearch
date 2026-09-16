extends SceneTree
const OUT := "res://doc/space/trans-pre-second-reading-2026-09-16/"
const PICKUP_PATH := "res://commons/scenes/mapobjects/pick_up_cube.gd"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func pickups(seg: Node3D) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for n in seg.find_children("*", "Node3D", true, false):
		if n.get_script() != null and n.get_script().resource_path == PICKUP_PATH: result.append(n)
	return result
func run() -> void:
	var ctl := OUT + "control.json"
	var f := FileAccess.open(ctl,FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation","dollhouse":0,"grid_pack":1}));f.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","transformation");em.set("start_map","Trans_Pre")
	root.add_child(em);current_scene=em
	await create_timer(1.0).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var player: Node3D=em.get("_player")
	if player != null:
		player.set_process(false);player.set_physics_process(false)
		player.global_position.y+=20.0
	var seg: Node3D
	for record: Dictionary in em.get("_segments"):
		if record.node.get_meta("em_map","")=="Trans_Pre":seg=record.node;break
	check(seg!=null,"Actual Trans_Pre museum segment loaded")
	if seg==null:finish([]);return
	var cubes: Array[Node3D]=[]
	for i in range(120):
		cubes=pickups(seg)
		if cubes.size()==8:break
		await create_timer(0.1).timeout
	check(cubes.size()==8,"Four demonstration and four collectible cubes instantiated")
	var demos: Array[Node3D]=[]
	var collectables: Array[Node3D]=[]
	for cube in cubes:
		cube.set_process(false)
		if cube.get("hold")=="demo":demos.append(cube)
		else:collectables.append(cube)
	demos.sort_custom(func(a: Node3D,b: Node3D):return a.global_position.z<b.global_position.z)
	check(demos.size()==4 and collectables.size()==4,"Collection modes distinguish the two encounters")
	var evidence: Array=[]
	for i in demos.size():
		var cube := demos[i]
		var mesh := cube.get_node("CubeBaseMesh") as MeshInstance3D
		var detector := cube.get_node("DetectionArea/CollisionShape3D") as CollisionShape3D
		var size_before: Vector3 = detector.shape.size
		var scale_before := detector.scale
		cube.set("time_passed",0.0);cube.rotation=Vector3.ZERO;cube.call("_process",0.0)
		var p:=cube.global_position;var b:=cube.basis;var s:=mesh.scale
		cube.call("_process",0.4)
		check((not cube.global_position.is_equal_approx(p))==(i>=1),"Vertical motion at stage "+str(i+1))
		check((not cube.basis.is_equal_approx(b))==(i>=2),"Rotation at stage "+str(i+1))
		check((not mesh.scale.is_equal_approx(s))==(i>=3),"Scale pulse at stage "+str(i+1))
		check(detector.shape.size.is_equal_approx(size_before) and detector.scale.is_equal_approx(scale_before),"Detector dimensions unchanged by visual pulse")
		cube.call("collect")
		check(not cube.get("has_been_collected"),"Demonstration cannot be collected")
		check(not (cube.get_node("DetectionArea") as Area3D).monitoring,"Demo detector disabled")
		evidence.append({"motion":cube.get("motion"),"position":str(cube.global_position),"detector_size":str(size_before),"visual_scale":str(mesh.scale)})
	for cube in collectables:
		check(cube.get("motion")=="all" and (cube.get_node("DetectionArea") as Area3D).monitoring,"Route pickup animates and can detect collection")
	var health:=0;var markers:=0
	for n in seg.find_children("*","Node3D",true,false):
		if n.get_script()==null:continue
		var path: String=n.get_script().resource_path
		if path=="res://commons/artifacts/health_cross/health_cross.gd":health+=1
		if path in ["res://commons/artifacts/axis_translation_cube/axis_translation_cube.gd","res://commons/artifacts/rotation_oscillation_cube/rotation_oscillation_cube.gd","res://commons/artifacts/uniform_scale_marker/uniform_scale_marker.gd"]:markers+=1
	check(health==2,"Two existing health crosses retained")
	check(markers==3,"All three operation markers present")
	if "--capture" in OS.get_cmdline_user_args() and demos.size()==4:
		var first:=demos[0].global_position
		var cam:=Camera3D.new();em.add_child(cam);cam.fov=68
		var shots: Array=[
			["cumulative-cubes",first+Vector3(5,5,2),first+Vector3(0,0.8,6)],
			["arrival",first+Vector3(1,1.6,-1.5),first+Vector3(0,0.8,7)],
			["small-level",first+Vector3(4.7,5.2,12),first+Vector3(0,1,17)]
		]
		for shot in shots:
			cam.global_position=shot[1];cam.look_at(shot[2])
			for i in range(15):cam.make_current();await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+shot[0]+".png")
	finish(evidence)
func finish(evidence: Array) -> void:
	var f:=FileAccess.open(OUT+"runtime-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"stages":evidence,"headset_verified":false},"  "));f.close()
	print("[trans-pre-reading] ",checks," checks; failures: ",failures)
	quit(0 if failures.is_empty() else 1)
