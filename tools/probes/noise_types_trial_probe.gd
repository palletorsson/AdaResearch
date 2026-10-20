extends "res://tools/probes/void_trial_probe.gd"
## The Random_Noise_Types trial: six original artifacts, the sampling bench's
## seeded admission accounting, the weather's fixed glass as partitions, gallery
## audio across floor residency, retry and re-entry. Desktop and synthetic XR.
const TRIAL_SCENE := "res://commons/void/trials/noise/trial.tscn"
var measure_only := false

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-.3,1.2,-.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
		right.set_input("grip",0.0); right.set_input("trigger_click",false)
	var scene: PackedScene = load(TRIAL_SCENE)
	var staged: Node3D = scene.instantiate()
	check("trial satisfies staging scene type", is_instance_of(staged, load("res://addons/godot-xr-tools/staging/scene_base.gd")))
	game = staged
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input=true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)
	game.atmosphere.animate_sky=false; game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
		if arg=="--measure": measure_only=true
	DirAccess.make_dir_recursive_absolute(out)
	check("probe uses isolated save data", OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	var curated_floors: int = Source.read_rooms().floors.size()
	check("curated tower is read untouched", curated_floors>=1 and Source.read_rooms().floors[0].map=="Point_Zero")
	check("transformation trial keeps five floors", Source.read_rooms("transformation").floors.size()==5)
	if measure_only:
		await start(false)
		await measure()
		game.queue_free(); await frames(5)
		quit(0); return
	var museum_score: int = root.get_node("GameManager").player_score
	for use_xr in ([true] if take_photos else [false,true]):
		await visit(use_xr, museum_score)
	check("trial selection does not leak into the tower",Source.read_rooms().floors.size()==curated_floors)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot 4.6, actual physics, desktop and synthetic tracked XR. Mobile screenshots when captured. No physical headset."},"\t"))
	print("VOID_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

## Floor-local bounds of every visible mesh under a node, on the trial floor.
func floor_bounds(node: Node3D, level: float) -> AABB:
	var result := AABB()
	var first := true
	for geometry in node.find_children("*","GeometryInstance3D",true,false):
		if not geometry.is_visible_in_tree(): continue
		var local: AABB
		if geometry is MeshInstance3D and geometry.mesh!=null: local=geometry.mesh.get_aabb()
		elif geometry is MultiMeshInstance3D and geometry.multimesh!=null: local=geometry.multimesh.get_aabb()
		else: continue
		local=geometry.global_transform*local
		result=local if first else result.merge(local)
		first=false
	result.position.y-=level
	return result

func colliders(node: Node3D, level: float) -> Array:
	var found: Array=[]
	for shape in node.find_children("*","CollisionShape3D",true,false):
		if shape.shape is BoxShape3D:
			var body := shape.get_parent()
			var centre: Vector3 = shape.global_position - Vector3(0,level,0)
			var size: Vector3 = (shape.global_basis * (shape.shape as BoxShape3D).size).abs()
			found.append({"body":str(body.name),"centre":[snappedf(centre.x,.01),snappedf(centre.y,.01),snappedf(centre.z,.01)],"size":[snappedf(size.x,.01),snappedf(size.y,.01),snappedf(size.z,.01)]})
	return found

func measure() -> void:
	var content: Node3D=game.building.content
	var level: float=float(game.building.spec.levels[1])
	var report := {"artifacts":{},"props":{}}
	for key in content.exhibits:
		if not str(key).begins_with("1/"): continue
		var mount: Node3D=content.exhibits[key]
		var artifact: Node3D=mount.get_node("Artifact")
		var b := floor_bounds(artifact,level)
		report.artifacts[str(key)]={"mount":[mount.position.x,mount.position.y,mount.position.z],"yaw":mount.rotation_degrees.y+artifact.rotation_degrees.y,
			"min":[snappedf(b.position.x,.01),snappedf(b.position.y,.01),snappedf(b.position.z,.01)],"max":[snappedf(b.end.x,.01),snappedf(b.end.y,.01),snappedf(b.end.z,.01)],
			"size":[snappedf(b.size.x,.01),snappedf(b.size.y,.01),snappedf(b.size.z,.01)],"colliders":colliders(artifact,level)}
	for key in content.props:
		if not str(key).begins_with("1/"): continue
		var b := floor_bounds(content.props[key],level)
		report.props[str(key)]={"min":[snappedf(b.position.x,.01),snappedf(b.position.y,.01),snappedf(b.position.z,.01)],"max":[snappedf(b.end.x,.01),snappedf(b.end.y,.01),snappedf(b.end.z,.01)]}
	var construction: Node3D = content.roots[1].get_node_or_null("Construction")
	if construction!=null:
		var b := floor_bounds(construction,level)
		report["construction"]={"min":[b.position.x,b.position.y,b.position.z],"max":[b.end.x,b.end.y,b.end.z]}
	FileAccess.open(out.path_join("measure.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("MEASURE ",JSON.stringify(report))
	if take_photos:
		# An overview from above the open storey: hide the canopy slab and its details.
		game.building.floors[0].hide(); game.building.detail_root(0).hide()
		await photo("plan-overview",Vector3(3,-6+14,0.5),Vector3(3,-6,0.4))
		await photo("plan-east-wing",Vector3(16,-6+12,0.5),Vector3(16,-6,0.4))
		await photo("plan-weather",Vector3(-1,-6+12,0),Vector3(-1,-6,-0.1))
		game.building.floors[0].show(); game.building.detail_root(0).show()

## Stand the tracked controller `offset` away from `target`, aim its ray at it and pull the trigger.
func point_and_press(controller: XRControllerTracker, target: Vector3, offset: Vector3) -> void:
	var origin: Node3D=game.get_node("XROrigin3D")
	var at: Vector3=target+offset
	var forward: Vector3=(target-at).normalized()
	# A controller's ray leaves along its local -Z.
	var basis := Basis.looking_at(forward,Vector3.UP)
	controller.set_pose("aim",Transform3D(basis,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(20)
	controller.set_input("trigger_click",true); await frames(6)
	controller.set_input("trigger_click",false); await frames(12)
	hand_at(controller,game.body.global_position+Vector3(0.3,1.2,-0.4)); await frames(5)

func photo(filename:String,at:Vector3,target:Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show()

func visit(use_xr: bool, museum_score: int) -> void:
	await start(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var level: float=float(game.building.spec.levels[1])
	check(tag+"starts on the encounter floor beside shaft B",game.checkpoint==1 and absf(game.body.global_position.y-level)<0.12 and game.body.global_position.x>12.5)
	check(tag+"three levels, fixed frame, both shafts",game.building.spec.levels.size()==3 and game.building.spec.width==42 and game.building.spec.shafts.size()==2)
	check(tag+"six original placements on the encounter floor",content.data.floors[1].artifacts.size()==6 and content.exhibits.keys().filter(func(key): return str(key).begins_with("1/")).size()==6)
	var point: Node3D=content.exhibits["1/point"].get_node("Artifact")
	var bench: Node3D=content.exhibits["1/bench"].get_node("Artifact")
	var surface: Node3D=content.exhibits["1/surface"].get_node("Artifact")
	var field: Node3D=content.exhibits["1/field"].get_node("Artifact")
	var spectrum: Node3D=content.exhibits["1/spectrum"].get_node("Artifact")
	var weather: Node3D=content.exhibits["1/weather"].get_node("Artifact")
	check(tag+"original scene scripts",point.get_script().resource_path=="res://algorithms/randomness/randompoint/randompoint.gd" and bench.get_script().resource_path=="res://algorithms/randomness/randompoints/randompoints.gd" and surface.get_script().resource_path=="res://commons/artifacts/geometry_noise/GeometryNoiseTest.gd" and field.get_script().resource_path=="res://algorithms/randomness/whitenoise/white_noise_spectrum.gd" and spectrum.get_script().resource_path=="res://algorithms/randomness/whitenoise/noise_spectrum_3d.gd" and weather.get_script().resource_path=="res://commons/artifacts/related_weather/related_weather.gd")
	check(tag+"museum configurations reach the artifacts",point.stand=="bounds" and is_equal_approx(point.area_half_extent,0.6) and bench.stand=="compare" and bench.num_points==24 and is_equal_approx(bench.area_size.x,0.9) and field._gallery_stand and spectrum._gallery_stand and field.seed_value==31415 and spectrum.seed_value==31415 and weather.run_seed==4321)
	check(tag+"galleries keep their museum miniature scale with human-sized consoles",field.scale.is_equal_approx(Vector3.ONE*0.05) and spectrum.scale.is_equal_approx(Vector3.ONE*0.1) and field.has_node("GalleryConsole") and spectrum.has_node("GalleryConsole") and field.get_node("GalleryConsole").global_basis.get_scale().is_equal_approx(Vector3.ONE))
	for key in ["point","bench","surface","field","spectrum","weather"]:
		var lead: Node3D = content.get_node("Content1/Lead_" + key)
		check(tag+"overhead supply lead reaches "+key, lead.get_meta("station")==content.data.floors[1].artifacts.filter(func(a): return a.id==key)[0].station and lead.has_node("ArtifactFeed") and lead.get_node("ArtifactFeed").position.y>=1.9 and content.exhibits["1/"+key].get_meta("supply")=="ceiling_bus")
	# The bench: one named seed, the admission rule and its two accounts.
	var state: Dictionary=bench.sampling_state()
	check(tag+"bench carries the explicit seed",int(state.seed)==31415 and bench.sampling_seed==31415)
	check(tag+"admission accounting balances",int(state.admitted.attempts)==int(state.admitted.accepted)+int(state.admitted.refused) and int(state.requested)==24 and int(state.admitted.accepted)+int(state.admitted.short)==24)
	check(tag+"every admitted pair keeps the minimum distance",float(state.admitted.closest)>=float(state.min_dist)-0.0005 and float(state.min_dist)>0.05)
	check(tag+"refused candidates are drawn within the display budget",int(state.admitted.ghosts_shown)<=220 and int(state.admitted.ghosts_shown)==mini(220,int(state.admitted.refused)))
	var homes_before: Array=state.homes.admitted.duplicate(true)
	var proposed_before: Array=state.homes.proposed.duplicate(true)
	bench.redraw(); await frames(3)
	var again: Dictionary=bench.sampling_state()
	check(tag+"REDRAW reproduces both clouds from the same seed",again.homes.admitted==homes_before and again.homes.proposed==proposed_before and int(again.admitted.refused)==int(state.admitted.refused))
	bench.cycle_load(); await frames(3)
	var loaded: Dictionary=bench.sampling_state()
	check(tag+"LOAD x4 requests 96 at the same spacing and reports unfilled places honestly",int(loaded.requested)==96 and is_equal_approx(float(loaded.min_dist),float(state.min_dist)) and int(loaded.admitted.accepted)+int(loaded.admitted.short)==96 and int(loaded.admitted.attempts)<=96*100 and float(loaded.admitted.closest)>=float(loaded.min_dist)-0.0005)
	# The left cloud draws first from the seed, so its first 24 proposals repeat; the right
	# cloud continues the stream after them and legitimately differs at a larger request.
	check(tag+"the first 24 proposals of the larger request repeat the smaller one",loaded.homes.proposed.slice(0,proposed_before.size())==proposed_before and loaded.homes.admitted!=homes_before)
	bench.cycle_load(); await frames(3)
	# A controlled failure: a rule wider than the volume admits one point and spends the whole budget.
	var fixture_host := Node3D.new(); game.add_child(fixture_host)
	var fixture: Dictionary=content.data.floors[1].artifacts.filter(func(a): return a.id=="bench")[0].duplicate(true)
	fixture.id="bench-fixture"; fixture.config=fixture.config.duplicate(true); fixture.config["count"]=5; fixture.config["dist"]=3.0
	content._build_artifact(fixture_host,1,fixture); await frames(3)
	var narrow: Node3D=content.exhibits["1/bench-fixture"].get_node("Artifact")
	var starved: Dictionary=narrow.sampling_state()
	check(tag+"a rule wider than the volume admits one point and exhausts 400 attempts",int(starved.admitted.accepted)==1 and int(starved.admitted.refused)==400 and int(starved.admitted.attempts)==401 and int(starved.admitted.short)==4)
	content.exhibits.erase("1/bench-fixture"); fixture_host.queue_free(); await frames(2)
	# Carrying a point: the rule is reported, never enforced, and RESTORE returns the record.
	var sample: Node3D=bench._points.admitted[0]
	var neighbour: Node3D=bench._points.admitted[1]
	var home: Vector3=sample.get_meta("home")
	sample.position=neighbour.position+Vector3(0.02,0,0); await frames(20)
	var moved: Dictionary=bench.sampling_state()
	check(tag+"a carried point is counted, not pushed away",int(moved.under_distance)>=1 and int(moved.moved)>=1 and sample.position.distance_to(neighbour.position)<0.05)
	bench.restore(); await frames(3)
	check(tag+"RESTORE returns the generated positions without a new draw",sample.position.is_equal_approx(home) and bench.sampling_state().homes.admitted==homes_before)
	if use_xr:
		# Real input: the tracked hand pokes the bench's REDRAW button and grips a sample.
		var pressed: Array=[]
		for i in range(5):
			var area: Node=bench.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
			area.button_pressed.connect(func(_b): pressed.append("Btn_%d"%i))
		var redraw_button: Node3D=bench.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
		# Architectural terminals forward to these same source callbacks.
		if content.props.has("1/bench-console"):
			var terminal: Node3D=content.props["1/bench-console"].get_node("Prefab")
			if terminal.controls!=null:
				redraw_button=terminal.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
		var instance_before: Node3D=bench._points.admitted[0]
		# The museum's VR convention for rack buttons: point the controller at the
		# switch and pull the trigger. The panel faces west, so aim along +X.
		await point_and_press(right,redraw_button.global_position,Vector3(-0.55,0.08,0.0))
		print("[void] bench buttons pressed by the pointer: ",pressed)
		check("XR: pointer + trigger presses REDRAW alone",pressed==["Btn_0"])
		check("XR: pointer press on REDRAW rebuilds the same clouds",is_instance_valid(bench._points.admitted[0]) and bench._points.admitted[0]!=instance_before and bench.sampling_state().homes.admitted==homes_before)
		sample=bench._points.admitted[0]; neighbour=bench._points.admitted[1]; home=sample.get_meta("home")
		hand_at(right,sample.global_position+Vector3(-0.03,0,0)); await frames(20)
		print("[void] pickup closest before grip: ",game.pickups[1].closest_object," sample layer ",sample.collision_layer," hand at ",game.pickups[1].global_position," sample at ",sample.global_position)
		right.set_input("grip",1.0); await frames(15)
		check("XR: grip carries a sampled point with XRTools",game.pickups[1].picked_up_object==sample and sample.is_picked_up())
		hand_at(right,neighbour.global_position+Vector3(0,0.05,0.03)); await frames(20)
		right.set_input("grip",0.0); await frames(25)
		check("XR: release leaves the point near its neighbour and the shells report it",not sample.is_picked_up() and sample.global_position.distance_to(neighbour.global_position)<0.12 and int(bench.sampling_state().under_distance)>=1)
		bench.restore(); await frames(5)
		check("XR: RESTORE after a real carry returns the record",sample.position.is_equal_approx(home))
		hand_at(right,game.body.global_position+Vector3(0.3,1.2,-0.4)); await frames(5)
	# The single point keeps its plane every frame.
	# Carry the point beyond its frame and out of its plane (a frozen body moves through
	# the physics server as well as its node), then let the artifact's own frame clip it.
	var dot: RigidBody3D=point.point_node
	dot.position=Vector3(0.9,0.2,0.4)
	PhysicsServer3D.body_set_state(dot.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,dot.global_transform)
	await frames(8)
	check(tag+"the single point clips to its bounds and discards depth",absf(dot.position.x-0.6)<0.001 and absf(dot.position.y-0.2)<0.001 and absf(dot.position.z)<0.001)
	# The weather: fixed glass blocks a body; the shutters only change sight.
	var glass: Array=[]
	for child in weather.get_children():
		if str(child.name).begins_with("FixedGlass"): glass.append(child)
	check(tag+"three glazed walls with solid glass",glass.size()==3 and glass.all(func(g): return g.find_child("StaticBody3D",true,false)!=null or g.get_child_count()>0))
	var wall_x: float=weather.to_global(Vector3(3.3,1.0,0)).x
	var through := ray(Vector3(wall_x+1.0,level+1.0,0.0),Vector3(wall_x-1.0,level+1.0,0.0))
	check(tag+"a ray through a wall hits the fixed glass, not a shutter",not through.is_empty() and weather.is_ancestor_of(through.collider) and absf(through.position.x-wall_x)<0.05)
	game.place_player(Vector3(wall_x+1.2,level+0.06,0.0)); await frames(10)
	axes(Vector2(-1,0)); await frames(90); axes(Vector2.ZERO); await frames(10)
	check(tag+"walking into a glazed wall is stopped on the near side",game.body.global_position.x>wall_x+0.15 and not game.recovering)
	check(tag+"walls can be passed around their south ends",await move_to(Vector3(wall_x+1.0,level,5.2)) and await move_to(Vector3(wall_x-1.6,level,5.2)) and await move_to(Vector3(wall_x-1.6,level,0.0)))
	weather.toggle_run(); await frames(130)
	check(tag+"RUN advances the shared clock and records moments",weather.running and weather.records.size()>=1 and int(weather.get_state().seed)==4321)
	weather.toggle_run(); await frames(3)
	var count_held: int=weather.records.size()
	await frames(60)
	check(tag+"HOLD stops recording",weather.records.size()==count_held)
	weather.replay(); await frames(3)
	check(tag+"REPLAY empties the record and restores the seed",weather.records.is_empty() and int(weather.run_seed)==4321)
	# Gallery sound: starts on request, sleeps with its floor, returns with it.
	field._play_noise_preview(field.NoiseType.PINK); await frames(5)
	check(tag+"gallery sound plays on request only",field._audio_playing and field._audio_player.playing and not spectrum._audio_playing)
	var home_floor: int=game.checkpoint
	game.place_player(game.spawn_for(2)); await frames(40)
	check(tag+"leaving the floor puts its gallery sound to sleep",game.floor_stream.focus==2 and field._audio_player.stream_paused and field.process_mode==Node.PROCESS_MODE_DISABLED)
	game.place_player(game.spawn_for(1)); await frames(40)
	check(tag+"returning wakes the same gallery instance",game.floor_stream.focus==1 and not field._audio_player.stream_paused and field.process_mode!=Node.PROCESS_MODE_DISABLED and is_instance_valid(field))
	field._stop_audio_preview(); await frames(3)
	check(tag+"STOP ends the sound",not field._audio_playing)
	check(tag+"the bench keeps its clouds across leave and return",bench.sampling_state().homes.admitted==homes_before)
	game.checkpoint=home_floor
	# Arrival through B and departure through A, on the actual boards.
	game.checkpoint=0
	var cushions:int=game.cushioned_landings
	game.place_player(Vector3(11.7,0.06,1.9)); await frames(140)
	check(tag+"arrival drop B lands on the boards without injury",game.checkpoint==1 and game.deaths==0 and game.cushioned_landings==cushions+1 and game.health.get_health()==100)
	check(tag+"step from the boards onto the east wing",await move_to(Vector3(13.4,level,1.9)))
	check(tag+"reach the single point",await move_to(Vector3(13.0,level,-1.2)))
	check(tag+"reach the bench front",await move_to(Vector3(16.2,level,-0.3)))
	check(tag+"reach the surface console",await move_to(Vector3(17.0,level,-2.6)))
	check(tag+"reach both gallery consoles",await move_to(Vector3(14.6,level,4.2)) and await move_to(Vector3(18.1,level,4.2)))
	for at in [Vector3(17.2,level,3.0),Vector3(13.6,level,3.2),Vector3(12.6,level,5.2),Vector3(9.8,level,5.2),Vector3(6.0,level,4.2),Vector3(5.2,level,0.0),Vector3(5.2,level,-4.6),Vector3(1.0,level,-6.2)]:
		check(tag+"return route around B to the weather controls "+str(at),await move_to(at))
	for at in [Vector3(-2.65,level,-4.9),Vector3(-2.65,level,0.0),Vector3(-2.65,level,4.9),Vector3(-5.1,level,4.9),Vector3(-5.1,level,0.0),Vector3(-6.9,level,-3.9)]:
		check(tag+"walk a lane and leave it at its end "+str(at),await move_to(at))
	# Photographs while the encounter floor is live: the visitor stands beside the gold line.
	if take_photos:
		weather.toggle_run(); await frames(150); weather.toggle_run(); await frames(5)
	await photo("bench-arrival",Vector3(12.9,level+1.65,2.4),Vector3(17.2,level+1.0,-0.6))
	await photo("bench-close",Vector3(15.6,level+1.6,-0.3),Vector3(17.6,level+1.1,-0.3))
	await photo("galleries",Vector3(16.8,level+1.65,2.4),Vector3(17.2,level+0.9,5.5))
	await photo("weather-corridor",Vector3(6.2,level+1.65,3.8),Vector3(-4,level+1.2,-2))
	await photo("weather-lane",Vector3(-2.65,level+1.65,5.6),Vector3(-2.65,level+1.3,-5))
	await photo("weather-controls",Vector3(2.2,level+1.65,-4.1),Vector3(-1.5,level+1.3,-6.2))
	await photo("toward-departure",Vector3(-5.6,level+1.65,5.2),Vector3(-10,level+0.3,-1.9))
	await photo("wide-view",Vector3(20.5,level+1.9,8.3),Vector3(-4,level+0.6,-2))
	cushions=game.cushioned_landings
	check(tag+"walk off A onto the catch floor's boards",await move_to(Vector3(-8.3,level-6,-1.9)))
	check(tag+"departure drop A saves the catch floor without injury",game.checkpoint==2 and game.deaths==0 and game.cushioned_landings==cushions+1 and game.health.get_health()==100)
	# Retry rebuilds the floor; the seeded bench returns identical.
	sample.position=neighbour.position+Vector3(0.02,0,0); await frames(5)
	game.die("Retry trial"); await frames(120)
	var rebuilt: Node3D=content.exhibits["1/bench"].get_node("Artifact")
	check(tag+"retry returns to the encounter floor with a rebuilt, identical bench",game.checkpoint==1 and not game.recovering and rebuilt!=bench and rebuilt.sampling_state().homes.admitted==homes_before)
	check(tag+"trial never changes museum score",root.get_node("GameManager").player_score==museum_score)
	game.queue_free(); await frames(15)
	if use_xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)
