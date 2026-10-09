extends "res://tools/probes/disco_separate_clocks.gd"
## A focused colour-return check. Same floor, independently changed palette.
func eye_photo(title: String) -> void:
	await snapshot(title,floor_node.to_global(Vector3(0,walking_y+1.65,-4)),floor_node.to_global(Vector3(1,walking_y,1.5)),76)
func values() -> Array:
	var out: Array=[]
	for z in 12:
		for x in 12:out.append(controls.value_at(x,z,12,12))
	return out
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	AudioServer.set_bus_mute(0,true)
	var grid=hall.get_node_or_null("SimGrid_Pattern_Disco")
	for frame in 3600:
		if grid and grid.has_meta("stage_grid_ready"):break
		await process_frame
	controls=find_scene("/disco_controls.gd");floor_node=find_scene("/StandaloneDiscoFloor.gd");seq=find_scene("/step_sequencer.gd")
	check("three placed disco artifacts",controls!=null and floor_node!=null and seq!=null)
	if controls==null or floor_node==null or seq==null:return
	ui=seq.get("_sequencer_ui")
	for i in 120:
		if controls.floor_node==floor_node and controls.sequencer==seq and ui:break
		await process_frame
	check("controls and score bind to the placed floor",controls.floor_node==floor_node and controls.sequencer==seq and ui!=null)
	if ui==null:return
	seq.stop();ui.clear_pattern()
	check("colour return exposes 144 tiles",controls.colour and not floor_node.monochrome and floor_node.multimesh.instance_count==144)
	buttons=controls.find_children("InteractableAreaButton","Area3D",true,false)
	check("COLOUR is the fifth real pointer button",buttons.size()==5)
	if buttons.size()!=5:return
	if controls.running:await press(1)
	while controls.pattern!=0:await press(0)
	actor=museum.get("_player")
	var ray=PhysicsRayQueryParameters3D.create(floor_node.to_global(Vector3(0,8,-4)),floor_node.to_global(Vector3(0,-2,-4)),1,[actor.get_rid()])
	var support=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check("floor supports a standing body",not support.is_empty())
	if support.is_empty():return
	walking_y=floor_node.to_local(support.position).y
	var geometry:Array=[]
	for i in 144:geometry.append(floor_node.multimesh.get_instance_transform(i))
	var original_values=values();var original_phase:int=controls.phase
	var names=["palette-black-white","palette-navy-pink","palette-teal-yellow","palette-violet-mint"]
	for i in 4:
		var palette_index:int=controls.palette
		await eye_photo(names[palette_index])
		var colours_match=true
		for j in 144:colours_match=colours_match and floor_node.tile_colors[j].is_equal_approx(controls.PALETTES[palette_index][original_values[j]])
		check("palette %d colours each unchanged binary address" % palette_index,colours_match)
		await press(4)
		check("palette switch %d preserves values and phase" % i,controls.phase==original_phase and values()==original_values and not controls.running)
	check("palette cycle returns to its starting pair",controls.palette==1)
	await press(2)
	check("ONE STEP exchanges values while keeping the palette",controls.phase==original_phase+1 and controls.palette==1 and values()!=original_values)
	await press(0)
	check("pattern change resets ROWS to phase zero",controls.pattern==1 and controls.phase==0)
	var row_values=values();await press(3)
	check("speed change preserves pattern and palette",controls.pattern==1 and controls.palette==1 and values()==row_values)
	await snapshot("colour-console",controls.to_global(Vector3(0,1.7,-1.9)),controls.to_global(Vector3(0,1.2,0)),57)
	museum.set("_dollhouse",false);actor.global_position=floor_node.to_global(Vector3(0,walking_y+0.05,-4));actor.velocity=Vector3.ZERO
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	var before_walk=score();var before_phase:int=controls.phase
	await press(1)
	if not await walk(Vector3(0,walking_y+0.05,4),"walk across the coloured rows"):return
	if not await walk(Vector3(3,walking_y+0.05,4),"walk across the direction of the coloured rows"):return
	check("walking leaves musical addresses unchanged",score()==before_walk)
	check("visual clock advances with music stopped",controls.phase>before_phase and not seq._is_playing)
	await press(1)
	await eye_photo("a-band-to-cross")
	for i in 3:await press(0)
	check("fourth pattern change reaches SUPER TRIANGLE",controls.pattern==controls.TRIANGLE_MODE)
	await press(1);await create_timer(0.31).timeout;await press(1)
	var held:float=controls.triangle_motion
	await eye_photo("triangle-pink")
	await press(4)
	check("palette also preserves an unfinished triangle turn",is_equal_approx(controls.triangle_motion,held) and not controls.running)
	check("shader takes the new two colours",controls.triangle_surface.material_override.get_shader_parameter("ink")==controls.PALETTES[2][0] and controls.triangle_surface.material_override.get_shader_parameter("paper")==controls.PALETTES[2][1])
	await eye_photo("triangle-yellow")
	var all_fixed=true
	for i in 144:all_fixed=all_fixed and geometry[i].is_equal_approx(floor_node.multimesh.get_instance_transform(i))
	check("pattern palette tempo and walk preserve tile geometry",all_fixed)
	var held_phase:int=controls.phase
	ui.set_cell(1,0,true)
	seq.step_triggered.connect(func(track:int,step_index:int):notes.append([track,step_index]))
	ui.playback_toggled.emit(true);await create_timer(0.8).timeout
	check("one note plays while visual movement holds",seq._is_playing and not notes.is_empty() and controls.phase==held_phase and not controls.running)
	ui.playback_toggled.emit(false);await create_timer(0.3).timeout
	check("stopping the score lets its flashes expire",controls.pulse_remaining.is_empty())
	seq.step_triggered.emit(1,12);await process_frame
	check("musical event still addresses a floor column",controls.pulse_remaining.has(0))
	await create_timer(0.3).timeout
	check("event response expires without moving the held triangles",controls.pulse_remaining.is_empty() and is_equal_approx(controls.triangle_motion,held))
	await snapshot("sequencer-beside-floor",seq.to_global(Vector3(0,1.0,2.0)),seq.to_global(Vector3(0,0.4,0)),62)
	observations["held_triangle_motion"]=held;observations["note_events"]=notes;observations["source_floor_support"]=str(support.collider.get_path())
	completed=true
func finish() -> void:
	if driver:driver.release();driver.set_physics_process(false)
	if seq:seq.stop()
	check("colour return completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Actual museum, real palette/pattern pointer callbacks, ordinary-controller walks and generated musical events. Audio muted. Eye-height native images; no headset, listening-quality or perceptual response claim."},"  "))
	print("COLOUR RETURN ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
