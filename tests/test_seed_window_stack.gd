extends SceneTree
var failures: Array[String] = []
func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason); push_error(reason)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 6: await physics_frame
func expected(value: int, count: int, skip: int = 0) -> PackedColorArray:
	var rng := RandomNumberGenerator.new()
	rng.seed=value
	for i in skip: rng.randf()
	var result:=PackedColorArray()
	for i in count: result.append(Color(rng.randf(),rng.randf(),rng.randf()))
	return result
func run() -> void:
	# Use the authored hall token, so configuration and code cannot silently diverge.
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Random_Definition/map_data.json"))
	var token := ""
	for row in map.layers.interactables:
		for value in row:
			if str(value).begins_with("seed_replay_demo:"): token=str(value)
	check(not token.is_empty(),"Authored window exists")
	var config := {}
	for setting in token.split("#").slice(1):
		config[setting.get_slice(":",0)]=setting.substr(setting.find(":")+1)
	# Keep this an isolated instrument test; the linked hall has its own suite.
	config.erase("hall_seed"); config["movement_seed"]="false"; config["route_link"]=""
	var demo = load("res://algorithms/randomness/seed_replay/seed_replay_demo.gd").new()
	demo.apply_grid_config(config)
	root.add_child(demo)
	load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").install(demo,config)
	await settle()
	check(demo.has_node("SeedCabinet") and not demo.has_node("Stand"),"One body replaces the round pedestal")
	check(demo.find_child("ReachConsole",true,false)==null,"Museum staging leaves embedded controls in the body")
	var panel: Node3D=demo.get_node("Panel")
	check(panel.get_parent()==demo and panel.position.z<0.25,"Interface is mounted on the shared case")
	var lower_top: float=-INF
	var upper_bottom: float=INF
	for pane: MeshInstance3D in demo._columns[0].cubes:
		lower_top=maxf(lower_top,(pane.transform*pane.get_aabb()).end.y)
	for pane: MeshInstance3D in demo._columns[1].cubes:
		upper_bottom=minf(upper_bottom,(pane.transform*pane.get_aabb()).position.y)
	var panel_half: float=float(panel.get_meta("panel_h"))*panel.scale.y*0.5
	check(panel.position.y-panel_half>lower_top and panel.position.y+panel_half<upper_bottom,"Entire interface sits between START and REPLAY without covering panes")
	check(is_equal_approx(panel.position.y,1.63),"Interface centre is 1.63 m above the floor")
	for i in 7:
		var hit: CollisionShape3D=panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton/CollisionShape3D")
		var bounds: AABB=hit.global_transform*AABB(-hit.shape.size*0.5,hit.shape.size)
		check(bounds.position.y>=0.6 and bounds.end.y<=1.8,"Entire button target %d is in the hand reach band" % i)
		check(bounds.position.z>0.12,"Button target %d clears the solid cabinet front" % i)
	for i in 2:
		var slider: Node3D=panel.find_child("Param_%d" % i,true,false)
		for hit: CollisionShape3D in slider.find_children("*","CollisionShape3D",true,false):
			var bounds: AABB=hit.global_transform*hit.shape.get_debug_mesh().get_aabb()
			check(bounds.position.y>=0.6 and bounds.end.y<=1.8,"Slider %d collision geometry fits the hand reach band" % i)
	check(demo.column_count()==3,"Three stacked windows")
	check(demo._column_seeds()==[435,435,436],"Baseline, replay and neighbouring seed")
	check(demo.draws_per_grid()==48,"Four by four uses forty-eight draws")
	var baseline: PackedColorArray = demo.column_colors(0)
	var neighbour: PackedColorArray = demo.column_colors(2)
	check(baseline==expected(435,16) and baseline==demo.column_colors(1),"Independent reseeding reproduces every pane")
	check(neighbour==expected(436,16) and neighbour!=baseline,"Only changed seed creates the third pattern")
	for i in 3:
		var first: Node3D=demo._columns[i].cubes[0]
		check(is_equal_approx(first.position.x,demo._columns[0].cubes[0].position.x),"Windows share one vertical column")
		if i>0: check(first.position.y-demo._columns[i-1].cubes[0].position.y>demo._grid_height,"Windows do not overlap")
		check(str(demo._columns[i].seed) in demo._columns[i].label.text,"Every window exposes its own seed")
	var before_state: int=demo._rng.state
	var prefix: PackedFloat32Array = demo.raw_prefix(0)
	check(prefix==demo.raw_prefix(1) and prefix!=demo.raw_prefix(2),"Draw strips corroborate the comparison")
	check(demo._rng.state==before_state,"Inspection never consumes the exhibit stream")
	demo.find_child("Btn_2",true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
	check(demo.column_colors(0)==baseline and demo.column_colors(2)==neighbour,"Draw skip leaves both controls alone")
	check(demo.column_colors(1)==expected(435,16,1),"Only replay window shifts by one draw")
	check(demo.raw_prefix(1,23)==prefix.slice(1),"Visible replay strip exposes the same shift")
	demo.toggle_extra_draw()
	demo.find_child("Btn_4",true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
	demo.toggle_mapping_range()
	check(demo.column_colors(0)==baseline and demo.column_colors(2)==neighbour,"Mapping leaves both controls alone")
	check(demo.raw_prefix(0)==demo.raw_prefix(1),"Mapping changes colours without changing numbers")
	var saved: Dictionary = demo.capture_museum_state()
	var mapped: PackedColorArray = demo.column_colors(1)
	demo.reset_mapping(); demo.use_kept_seed(9,{})
	demo.restore_museum_state(saved)
	check(demo.column_colors(1)==mapped and demo.column_colors(0)==baseline,"Saved visit restores comparison settings and results")
	demo.reset_mapping()
	demo.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
	check(demo.column_colors(0)==baseline and demo.column_colors(1)==baseline and demo.column_colors(2)==neighbour,"Replay repeats all three windows")
	demo.set_grid_side(16)
	check(demo.column_colors(0)==expected(435,256) and demo.column_colors(0)==demo.column_colors(1),"Resolution preserves the same stream and comparison")
	demo.set_grid_side(4)
	check(demo.column_colors(0)==baseline,"Resolution round trip returns the original picture")
	await settle()
	check(demo.find_children("SeedCabinet","Node3D",true,false).size()==1,"Matrix rebuild leaves one cabinet")
	# Press through real XR Tools collision-hand overlaps, without emitting signals.
	var origin:=XROrigin3D.new(); origin.position=Vector3(demo.SeedStack.INFO_X,0,0.80); root.add_child(origin)
	var camera:=XRCamera3D.new(); camera.position.y=1.6; origin.add_child(camera)
	var controller:=XRController3D.new(); controller.tracker="left_hand"; origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/hands/scenes/collision/collision_hand.tscn").instantiate()
	hand.mode=1; controller.add_child(hand); controller.rotation.y=PI
	controller.global_position=Vector3(demo.SeedStack.INFO_X,0.85,0.80)
	await settle()
	var head_start:=camera.global_transform
	var replayed: Array=[0]
	demo.sequence_replayed.connect(func(): replayed[0]+=1)
	for index in [0,2]:
		var area: Area3D=panel.find_child("Btn_%d" % index,true,false).get_node("InteractableAreaButton")
		var hit: CollisionShape3D=area.get_node("CollisionShape3D")
		controller.global_position=hit.global_position+Vector3(0,0.05,0.11)
		await settle()
		check(area.pressed,"Actual hand presses embedded button %d" % index)
		controller.global_position.z=0.80; await settle()
		check(not area.pressed,"Withdrawal releases embedded button %d" % index)
	check(replayed[0]==1 and demo.extra_on(),"Physical hand presses reach replay and draw-offset callbacks")
	check(camera.global_transform==head_start,"Operating the body leaves the standing viewpoint fixed")
	demo.toggle_extra_draw(); origin.queue_free(); await process_frame
	demo.use_kept_seed(999,{})
	check(demo._column_seeds()==[999,999,1000],"Adjacent comparison remains plus one at slider maximum")
	for mode in ["single","replicas","seeds","ladder","offset"]:
		var ordinary = load("res://algorithms/randomness/seed_replay/seed_replay_demo.gd").new()
		ordinary.apply_grid_config({"comparison":mode,"seed":42})
		root.add_child(ordinary)
		check(ordinary._columns[0].cubes[0].mesh is BoxMesh,"Ordinary placements retain solid cubes")
		check(ordinary.column_count()==(1 if mode=="single" else (3 if mode=="ladder" else 2)),"Legacy comparison count: "+mode)
		if mode=="replicas": check(ordinary.column_colors(0)==ordinary.column_colors(1),"Legacy replicas still match")
		if mode=="offset": check(ordinary.column_colors(1)==expected(42,64,1),"Legacy offset still changes the last grid")
		if mode=="single":
			load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").install(ordinary,{"controls":"compact"})
			await settle()
			check(ordinary.find_child("ReachConsole",true,false)!=null,"Ordinary panels still receive their compact console")
		ordinary.queue_free()
	demo.queue_free()
	await process_frame
	print("SEED WINDOW STACK: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
