extends SceneTree
var checks := 0
var failures: Array[String] = []
var pointer: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	pointer = Node3D.new()
	world.add_child(pointer)
	var portals = load("res://commons/primitives/combines/combine_portals.tscn").instantiate()
	portals.set_meta("config_discovery","1")
	world.add_child(portals)
	var panel: Node3D = portals.get_node("ExperimentPanel")
	check(portals._portals.size()==20,"twenty finite portals retained")
	var first: Dictionary = portals.discovery_snapshot()
	check(first.rings==3 and first.segments==3 and first.triangles==18,"first ring reads actual 3 by 3 torus")
	var positions: Array = portals._portals.map(func(n): return n.position)
	var counts: Array = portals._portals.map(func(n): return Vector2i(n.mesh.rings,n.mesh.ring_segments))
	press(panel.get_node("NextButton"))
	check(portals.selected_portal==1,"pointer next selects second ring")
	check(panel.get_node("PolygonDiagram").sides==4,"pointer selection updates the actual drawn polygon")
	var second: Dictionary = portals.discovery_snapshot()
	check(second.perimeter>first.perimeter and second.gap<first.gap,"separate unit-polygon perimeter approaches circumference")
	for i in 30: press(panel.get_node("NextButton"))
	var last: Dictionary = portals.discovery_snapshot()
	check(last.index==20 and last.rings==22 and last.segments==41 and last.gap>0,"last finite ring retains a positive polygon gap")
	press(panel.get_node("ReverseButton"))
	check(panel.get_node("PolygonDiagram").sides==3,"reversal redraws the selected polygon count")
	check(portals._portals.map(func(n): return n.position)==positions,"reverse preserves every ring position")
	var reversed: Array = counts.duplicate()
	reversed.reverse()
	check(portals._portals.map(func(n): return Vector2i(n.mesh.rings,n.mesh.ring_segments))==reversed,"reverse preserves mesh family in opposite order")
	press(panel.get_node("ReverseButton"))
	check(portals._portals.map(func(n): return Vector2i(n.mesh.rings,n.mesh.ring_segments))==counts,"second reversal restores original refinement")
	check(portals.get_node_or_null("Portal_00")==portals._portals[0],"rapid rebuilding preserves stable child names")
	for i in 30: press(panel.get_node("PreviousButton"))
	check(portals.selected_portal==0,"previous stops at first finite member")
	var race = load("res://commons/primitives/combines/achilles_tortoise.tscn").instantiate()
	race.position = Vector3(12,1,3)
	race.rotation_degrees.y = 25
	race.set_meta("config_discovery","1")
	world.add_child(race)
	check(not race.get_node("ExperimentPanel").has_node("PolygonDiagram"),"Achilles keeps its own instrument without a polygon")
	race.set_process(false)
	var race_panel: Node3D = race.get_node("ExperimentPanel")
	check(race._manual and race._current_step==0,"discovery starts held at stage zero")
	press(race_panel.get_node("StepButton"))
	var state: Dictionary = race.discovery_snapshot()
	check(state.step==1 and is_equal_approx(state.remaining,3.0) and is_equal_approx(state.gap,1.5),"manual step places exact first halving stage")
	for i in 9: press(race_panel.get_node("StepButton"))
	state = race.discovery_snapshot()
	check(state.step==10 and is_equal_approx(state.remaining,6.0/1024.0),"tenth stage retains 6/1024 metres to limit")
	press(race_panel.get_node("StepButton"))
	race.call("_process",20.0)
	check(race._current_step==10 and race._manual,"final stage stays available for inspection")
	press(race_panel.get_node("RestartButton"))
	check(race._current_step==0 and race._achilles.position==Vector3.ZERO and race._manual,"restart returns to a held initial stage")
	press(race_panel.get_node("PlayButton"))
	race.call("_process",2.01)
	race._motion.custom_step(0.25)
	state = race.discovery_snapshot()
	check(not is_equal_approx(state.remaining,state.target_remaining),"autoplay distinguishes interpolated position from stage target")
	press(race_panel.get_node("PlayButton"))
	var paused: Vector3 = race._achilles.position
	await create_timer(0.15).timeout
	check(race._achilles.position.is_equal_approx(paused),"pause freezes in-flight marker tween")
	press(race_panel.get_node("RestartButton"))
	await create_timer(0.15).timeout
	check(race._achilles.position==Vector3.ZERO,"restart cancels old tween so markers cannot drift back")
	for i in 9: press(race_panel.get_node("StepButton"))
	press(race_panel.get_node("PlayButton"))
	race.call("_process",2.01)
	race._motion.custom_step(0.2)
	press(race_panel.get_node("PlayButton"))
	press(race_panel.get_node("PlayButton"))
	race._motion.custom_step(1.1)
	race.call("_process",0.01)
	check(race._manual and is_equal_approx(race.discovery_snapshot().remaining,6.0/1024.0),"last animated step can pause and resume before final hold")
	await process_frame
	for p in [panel,race_panel]:
		p.update_readout()
	await process_frame
	for p in [panel,race_panel]:
		var bounds: AABB = p.text_label.get_aabb()
		check(bounds.end.x+p.text_label.position.x < 0.775 and bounds.position.y+p.text_label.position.y > -0.25,"readout fits case above controls")
	var legacy = load("res://commons/primitives/combines/achilles_tortoise.tscn").instantiate()
	world.add_child(legacy)
	legacy.set_process(false)
	check(not legacy.has_node("ExperimentPanel") and not legacy._manual,"unconfigured race keeps autoplay without a panel")
	for i in 10: legacy._advance(false)
	legacy.call("_process",0.01)
	check(legacy._paused,"legacy last stage enters its reset pause")
	legacy.call("_process",4.01)
	check(legacy._current_step==0 and not legacy._paused,"legacy loop still resets after four seconds")
	legacy.queue_free()
	var museum: Node = load("res://commons/scenes/endless_museum.tscn").instantiate()
	museum.set("_studio",true)
	museum.set("_headless",true)
	check(not museum.call("_has_collider",portals),"local controls do not classify the portal ladder as a solid obstacle")
	var obstacle := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	obstacle.add_child(collision)
	portals.add_child(obstacle)
	check(museum.call("_has_collider",portals),"real subject collider still classifies an obstacle")
	portals.remove_child(obstacle)
	obstacle.queue_free()
	var row: Dictionary = museum.call("_derive_map_row","Primitives_Portals")
	var placed := Node3D.new()
	world.add_child(placed)
	var matched := 0
	for entry: Dictionary in row.artifacts:
		if entry.token not in ["combine_portals","achilles_tortoise"]: continue
		var cell: Array = entry.tile_cell
		check(museum.call("_stamp",placed,"res://commons/primitives/combines/"+entry.token+".tscn",entry.token,{"x":cell[0],"y":cell[1],"top":0.0},0,1,{},false,0.0,float(entry.rotation),entry.get("config",{})),"actual map primary stamps")
		matched += 1
	check(matched==2 and placed.get_children().filter(func(n): return n.has_node("ExperimentPanel")).size()==2,"both actual map primaries expose instruments")
	check(not museum.get("_live_ledger").get("combine_portals",{}).get("has_collider",true),"footprint ledger refreshes the nonblocking ladder classification")
	for subject: Node3D in placed.get_children():
		if not subject.has_method("select_next"): continue
		check(is_equal_approx(subject.portal_spacing,1.4),"actual map applies compact portal spacing")
		check(is_equal_approx(subject._portals[-1].position.z-subject._portals[0].position.z,26.6),"all twenty origins fit within 26.6 metres")
		var compact_positions: Array = subject._portals.map(func(n): return n.position)
		subject.reverse_discovery_order()
		check(subject._portals.map(func(n): return n.position)==compact_positions,"compact map preserves spacing through reversal")
	placed.queue_free()
	museum.free()
	await process_frame
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.current = true
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.10,0.12,0.15)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color.WHITE
		env.environment.ambient_light_energy = 0.9
		world.add_child(env)
		for shot in ["portals","race"]:
			if shot=="portals":
				camera.position = Vector3(0.8,2.2,-6.0)
				camera.look_at(Vector3(0.8,1.5,1))
			else:
				press(race_panel.get_node("RestartButton"))
				press(race_panel.get_node("StepButton"))
				var aim: Vector3 = race.to_global(Vector3(0.6,0.2,-1.7))
				camera.global_position = aim + race.global_basis.z*3.7 + Vector3.UP*2.1
				camera.look_at(aim)
			await create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/portals_primary/"+shot+".png")
	FileAccess.open("res://ada_run/portals_primary/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Pointer events, mesh/order checks, actual tweens and configured museum stamping; full-corridor/headset routes unverified."},"  "))
	print("RESULT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)
