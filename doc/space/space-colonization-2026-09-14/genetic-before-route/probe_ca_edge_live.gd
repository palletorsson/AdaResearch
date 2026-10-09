extends Node
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "PG_Genetic_Evolution"
const OUT := "res://ada_run/genetic-review-2026-09-14/PG_Genetic_Evolution/"
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
	print("[pair-review] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[pair-review] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/genetic-review-2026-09-14/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_plan_path", "res://ada_run/genetic-review-2026-09-14/review-plan.json")
	em.set("_hand_path", "res://ada_run/genetic-review-2026-09-14/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "proceduralgeneration"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "proceduralgeneration", "dollhouse": 0, "grid_pack": 1})); f.close()
	get_tree().root.add_child(em); get_tree().current_scene = em
	await get_tree().create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
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
		var candidate = rec.get("node")
		if not is_instance_valid(candidate): continue
		var n: Node3D = candidate as Node3D
		if n == null or not seg.is_ancestor_of(n): continue
		var token: String = str(rec.get("token", ""))
		if token not in ["GeneticProgramming", "science_screen"]: continue
		works[token] = n
		var meshes: Array = []
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh and mi.is_visible_in_tree():
				var box: AABB = seg.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
				meshes.append({"name": str(mi.name), "position": [box.position.x,box.position.y,box.position.z-vest], "size": [box.size.x,box.size.y,box.size.z]})
		records.append({"token":token,"position":str(seg.to_local(n.global_position)),"meshes":meshes})
	measurements["inventory"] = records

	check(works.size()==2,"both original works exist")
	await review_works(works,seg,em,cam,vest)
	await shot(cam, seg.to_global(Vector3(6.5,18,12+vest)), seg.to_global(Vector3(6.49,1,6+vest)), "overview", 72)
	_finish()

func shot(cam: Camera3D, at: Vector3, target: Vector3, name_: String, field_of_view: float=68) -> void:
	cam.global_position=at;cam.look_at(target);cam.fov=field_of_view
	for i in range(16): cam.make_current();await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+name_+".png")

func _finish() -> void:
	var f:=FileAccess.open(OUT+"probe_ca_edge_live.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"map":MAP,"checks":checks,"failures":failures,"measurements":measurements,"headset_verified":false},"  "));f.close()
	print("Pair review: ",checks," checks; failures: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func press(driver, desk: Node3D, id: String) -> void:
	var hit: Dictionary = await driver.press(desk.buttons[id],desk.to_global(Vector3(0,0.001,2.57)))
	check(str(hit.get("hover","")) not in ["","none","null","nothing"],"DesktopPlayer pointer reaches "+id)
	await get_tree().create_timer(0.4).timeout

func move_to(driver, target: Vector3, tolerance: float = 0.7) -> bool:
	for attempt in 4:
		var start: Vector3=driver.rig.global_position
		var distance: float=Vector2(target.x-start.x,target.z-start.z).length()
		if distance<tolerance:return true
		driver.aim_at(target+Vector3.UP*1.6)
		await driver.walk("ui_up",maxi(3,int(distance*12)))
	return Vector2(driver.rig.global_position.x-target.x,driver.rig.global_position.z-target.z).length()<tolerance

func review_works(works: Dictionary,seg: Node3D,em: Node3D,cam: Camera3D,vest: int) -> void:
	if not works.has("GeneticProgramming"):return
	var e: Node3D=works.GeneticProgramming
	var desk: Node3D=e.get_node_or_null("SelectionLesson")
	check(desk!=null,"opt-in selection study loads")
	if desk==null:return
	var model: Node3D=desk.model
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();add_child(driver)
	driver.spawn(desk.to_global(Vector3(0,0.001,2.57)),em)
	em.get("_player").global_position=seg.to_global(Vector3(2,0,2+vest))
	check(model.population.size()==6 and model.current_generation==0,"six prepared candidates open at generation zero")
	check(is_equal_approx(model.best_genome.fitness,100) and is_equal_approx(model.estimate_volume(model.best_genome),8),"unit box matches proxy target 8 with score 100")
	check(e.get_node("UI").visible==false and not model.auto_evolve,"lesson keeps time manually stepped and replaces screen-only controls")
	await shot(cam,desk.to_global(Vector3(0,2.5,3.5)),desk.to_global(Vector3(0,1.0,-5)),"entrance",80)
	await press(driver,desk,"HOLD")
	var held_before: Array=desk.signature(desk.held_genome)
	check(desk.held_genome!=model.best_genome and held_before==desk.signature(model.best_genome),"HOLD owns a separate copy of the current leading genome")
	var by_id: Dictionary={}
	for g in model.population:by_id[g.id]=desk.signature(g)
	await press(driver,desk,"TARGET")
	var unchanged:=true
	for g in model.population:unchanged=unchanged and desk.signature(g)==by_id[g.id]
	check(unchanged and model.current_generation==0,"changing target reranks the same six genomes without advancing generation")
	check(is_equal_approx(model.target_volume,16) and is_equal_approx(model.estimate_volume(model.best_genome),15.625),"target 16 makes the size-1.25 box lead")
	check(desk.signature(desk.held_genome)==held_before,"target changes leave the witness unchanged")
	await shot(cam,desk.to_global(Vector3(4,4,3)),desk.to_global(Vector3(0,1,-5)),"target",79)
	var score_before: float=model.best_genome.fitness
	var parts_before: int=model.best_genome.genes.size()
	await press(driver,desk,"RING")
	check(model.best_genome.genes.size()==parts_before+1 and is_equal_approx(model.best_genome.fitness,score_before),"adding a torus changes the leading body's genes without changing its volume score")
	check(model.best_genome.phenotype.get_child_count()==parts_before+1,"the ignored ring is actually drawn by the original builder")
	measurements["ring_comparison"]={"before":score_before,"after":model.best_genome.fitness,"target":model.target_volume,"estimate":model.estimate_volume(model.best_genome)}
	await shot(cam,model.to_global(Vector3(2,3,-5)),model.to_global(Vector3(0,1,0)),"uncounted-ring",72)
	var elite: Array=desk.signature(model.best_genome)
	await press(driver,desk,"STEP")
	var elite_survived:=false
	for g in model.population:elite_survived=elite_survived or desk.signature(g)==elite
	check(model.current_generation==1 and model.population.size()==6,"STEP advances one generation and keeps population bounded")
	check(elite_survived and model.best_genome.fitness>=score_before,"selection copies the elite and cannot lower best score at the fixed target")
	check(desk.signature(desk.held_genome)==held_before,"offspring changes leave held genes unchanged")
	await shot(cam,desk.to_global(Vector3(0,6,-1)),desk.to_global(Vector3(0,0.6,-6)),"generation",83)
	await press(driver,desk,"RULE")
	check(desk.rule_card.visible and desk.rule_card.text.contains("Torus is omitted"),"RULE exposes the exact limitation of the volume estimate")
	await shot(cam,desk.to_global(Vector3(0,1.65,2.57)),desk.to_global(Vector3(0,1.3,1.5)),"controls",77)
	model.current_generation=model.max_generations
	desk.act("STEP")
	check(model.current_generation==model.max_generations and desk.notice.begins_with("Generation limit reached"),"STEP reports the original generation limit without advancing")
	await press(driver,desk,"RESET")
	check(model.current_generation==0 and model.population.size()==6 and is_equal_approx(model.best_genome.fitness,100),"RESET restores the six known opening boxes")
	check(desk.signature(desk.held_genome)==held_before,"RESET keeps the held witness")
	check(desk.buttons.size()==6 and desk.get_node("TextPanel/Glass").material_override.albedo_color.a<0.2,"six full-size controls fit the compact transparent desk")
	check(model.find_children("*","CollisionShape3D",true,false).is_empty(),"generated population does not pretend to provide the museum's support")
	# Read every original height-3 deck from actual physics, independently of its drawing.
	var md: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/PG_Genetic_Evolution/map_data.json"))
	var decks:=0;var all_supported:=true
	for z in md.layers.structure.size():
		for x in md.layers.structure[z].size():
			if str(md.layers.structure[z][x])!="3":continue
			decks+=1
			var from: Vector3=seg.to_global(Vector3(x+0.5,3.9,z+0.5+vest))
			var hit: Dictionary=seg.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from-Vector3.UP*4.5,1))
			all_supported=all_supported and not hit.is_empty() and abs(seg.to_local(hit.position).y-2)<0.06
	check(decks==25 and all_supported,"all 25 inherited high cells have physical support at two metres, rather than full walls")
	check(seg.get_node_or_null("ObservationRampSupport")!=null,"closed observation ramp supplies its own collision")
	driver.rig.global_position=seg.to_global(Vector3(1.35,0.45,25.5+vest))
	check(await move_to(driver,seg.to_global(Vector3(4.45,2.1,25.5+vest)),0.6),"desktop body climbs the new ramp to the retained deck")
	check(driver.rig.global_position.y-seg.global_position.y>1.85,"body reaches the two-metre observation level")
	await shot(cam,seg.to_global(Vector3(9.5,11,32+vest)),seg.to_global(Vector3(9.5,0,26+vest)),"platforms",83)
	await shot(cam,seg.to_global(Vector3(1.4,1.65,25.5+vest)),seg.to_global(Vector3(4.6,2.1,25.5+vest)),"ramp",77)
	if works.has("science_screen"):
		var screen: Node3D=works.science_screen
		em.get("_player").global_position=screen.to_global(Vector3(3,0,3))
		em.set("_wake_until_ms",0);em.call("_cull_artifacts")
		await get_tree().create_timer(1.2).timeout
		await shot(cam,screen.to_global(Vector3(0,1,3.5)),screen.to_global(Vector3(0,0.5,0)),"science",72)
	# The museum crossing uses an independent eastern aisle.
	driver.rig.global_position=seg.to_global(Vector3(16.5,0.1,3+vest))
	for p in [Vector3(16.5,0.1,18),Vector3(16.5,0.1,35),Vector3(9.5,0.1,35),Vector3(9.5,0.1,40.4),Vector3(12.5,0.1,40.4),Vector3(12.5,0.1,41.5)]:
		check(await move_to(driver,seg.to_global(p+Vector3(0,0,vest))),"museum crossing reaches "+str(p))
	var ordinary: Node3D=load("res://algorithms/proceduralgeneration/growth_systems/genetic_programming/GeneticProgramming.tscn").instantiate();ordinary.position=Vector3(1000,0,0);add_child(ordinary)
	check(ordinary.lesson_node==null and ordinary.get_node("UI").visible and ordinary.get_node("GeneticProgramming").population.size()==20,"ordinary artifact retains its 20-member population and original UI")
	remove_child(ordinary);ordinary.queue_free()
	measurements["driver_log"]=driver.log;measurements["next_map"]="PG_Percolation_Network"
	await driver.teardown()
