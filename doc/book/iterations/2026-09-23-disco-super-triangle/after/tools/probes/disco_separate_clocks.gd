extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var controls:Node3D
var floor_node:Node3D
var seq:Node3D
var ui:Control
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var buttons:Array
var notes:Array=[]
var completed:=false
var walking_y:=0.0

func press(index:int) -> void:
	var area:Node3D=buttons[index]
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.12).timeout
func photo(title:String) -> void:
	await snapshot(title,floor_node.to_global(Vector3(7,9,-9)),floor_node.to_global(Vector3(0,0,0)),63)
func score() -> Array:
	var cells:Array=[]
	for t in 4:
		for s in 16:cells.append(ui.get_cell(t,s))
	return cells
func walk(point:Vector3,title:String) -> bool:
	driver.target=floor_node.to_global(point);driver.arrived=false;driver.moving=true
	var begin:=Time.get_ticks_msec();var low:=INF;var high:=-INF
	while not driver.arrived and Time.get_ticks_msec()-begin<9000:
		await physics_frame
		var h:float=floor_node.to_local(actor.global_position).y;low=minf(low,h);high=maxf(high,h)
	driver.moving=false;driver.release()
	check(title,driver.arrived and low > walking_y-0.05 and high < walking_y+0.3)
	var collisions:Array=[]
	for i in actor.get_slide_collision_count():
		var hit:=actor.get_slide_collision(i)
		collisions.append({"collider":str(hit.get_collider().get_path()),"normal":xyz(hit.get_normal()),"position":xyz(hit.get_position())})
	observations[title]={"feet":xyz(floor_node.to_local(actor.global_position)),"minimum_y":low,"maximum_y":high,"world":xyz(actor.global_position),"target":xyz(driver.target),"velocity":xyz(actor.velocity),"keys":driver.held,"collisions":collisions,"spine_ui":str(museum.get("_spine_ui")),"typing":str(root.get_tree().get_first_node_in_group("ada_typing")),"basis":str(actor.global_basis),"floor_transform":str(floor_node.global_transform)}
	return driver.arrived
func landing_checks() -> void:
	AudioServer.set_bus_mute(0,true)
	controls=find_scene("/disco_controls.gd");floor_node=find_scene("/StandaloneDiscoFloor.gd");seq=find_scene("/step_sequencer.gd")
	check("all three existing artifacts are placed",controls!=null and floor_node!=null and seq!=null)
	if controls==null or floor_node==null or seq==null:return
	ui=seq.get("_sequencer_ui")
	check("controller and score are bound to this floor",controls.floor_node==floor_node and controls.sequencer==seq and ui!=null)
	if ui==null:return
	seq.stop();ui.clear_pattern()
	check("current floor has 144 monochrome tiles",floor_node.grid_width==12 and floor_node.grid_depth==12 and floor_node.multimesh.instance_count==144 and floor_node.monochrome and not controls.colour)
	buttons=controls.find_children("InteractableAreaButton","Area3D",true,false)
	check("four physical floor controls exist",buttons.size()==4)
	if buttons.size()!=4:return
	if controls.running:await press(1)
	var held:int=controls.phase
	await create_timer(0.7).timeout
	check("HOLD stops the visual clock",not controls.running and controls.phase==held)
	# Cycle the actual pattern control back to CHECKER at phase zero.
	for i in controls.PATTERNS.size():await press(0)
	check("pattern cycle restores CHECKER at phase zero",controls.pattern==0 and controls.phase==0)
	var geometry:Array=[]
	for i in 144:geometry.append(floor_node.multimesh.get_instance_transform(i))
	var zero:Array=floor_node.tile_colors.duplicate()
	await photo("checker-zero")
	await press(2)
	check("ONE STEP advances the held pattern",not controls.running and controls.phase==1)
	var inverted:=true
	for i in 144:inverted=inverted and not floor_node.tile_colors[i].is_equal_approx(zero[i])
	check("checker values switch at every fixed address",inverted)
	await photo("checker-one")
	await press(2)
	check("second step restores the checker values",floor_node.tile_colors==zero and controls.phase==2)
	await press(3);var slow:float=controls.interval
	await press(3);var fast:float=controls.interval
	await press(3)
	check("three speeds preserve the current values",is_equal_approx(slow,1.0) and is_equal_approx(fast,0.25) and is_equal_approx(controls.interval,0.5) and floor_node.tile_colors==zero)
	await press(0)
	check("ROWS starts at the first row",controls.pattern==1 and controls.phase==0)
	for phase in 12:
		if phase>0:await press(2)
		var bright:Array=[]
		for z in 12:
			if floor_node.tile_colors[z*12].r>0.9:bright.append(z)
		check("ROW phase "+str(phase)+" lights its own row",bright==[phase])
		await photo("rows-"+str(phase).pad_zeros(2))
	var fixed:=true
	for i in 144:fixed=fixed and floor_node.multimesh.get_instance_transform(i).is_equal_approx(geometry[i])
	check("all tile transforms remain fixed",fixed)
	ui.set_cell(1,0,true)
	seq.step_triggered.connect(func(track:int,step_index:int):notes.append([track,step_index]))
	var before_play:int=controls.phase
	ui.playback_toggled.emit(true)
	await create_timer(0.6).timeout
	check("score plays while the floor clock holds",seq._is_playing and notes.size()>0 and controls.phase==before_play and not controls.running)
	ui.playback_toggled.emit(false)
	await create_timer(0.25).timeout
	check("musical flashes expire while held",controls.pulse_remaining.is_empty())
	await press(1)
	await create_timer(1.1).timeout
	check("visual clock runs with the score stopped",controls.phase>before_play and not seq._is_playing)
	await press(1)
	# Screen is a direct export from the same placed sequencer, not a redraw.
	await RenderingServer.frame_post_draw
	var saved:int=ui.get_viewport().get_texture().get_image().save_png(folder+"one-note-score.png")
	check("saved placed sequencer screen",saved==OK)
	observations["score_notes"]=notes
	actor=museum.get("_player")
	var ray:=PhysicsRayQueryParameters3D.create(floor_node.to_global(Vector3(0,8,-4)),floor_node.to_global(Vector3(0,-2,-4)),1,[actor.get_rid()])
	var support:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check("placed floor has a physical standing surface",not support.is_empty())
	if support.is_empty():return
	walking_y=floor_node.to_local(support.position).y
	observations["standing_surface"]={"local_y":walking_y,"world":xyz(support.position),"collider":str(support.collider.get_path()),"tile_size":floor_node.tile_size,"floor_y_offset":floor_node.floor_y_offset}
	actor.global_position=floor_node.to_global(Vector3(0,walking_y+0.06,-4));actor.velocity=Vector3.ZERO
	museum.set("_dollhouse",false)
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	var held_score:=score();var before_walk:int=controls.phase
	await press(1)
	if not await walk(Vector3(0,walking_y+0.05,4),"walk across the running rows"):return
	if not await walk(Vector3(4,walking_y+0.05,4),"walk across the row direction"):return
	check("walking does not write into the score",score()==held_score)
	check("floor keeps its own time during the walks",controls.phase>before_walk)
	await press(1)
	await snapshot("underfoot",actor.global_position+Vector3.UP*1.65,floor_node.to_global(Vector3(0,0,-1)),72)
	await snapshot("floor-console",controls.to_global(Vector3(0,1.7,-1.9)),controls.to_global(Vector3(0,1.2,0)),57)
	observations["floor_world"]=xyz(floor_node.global_position)
	for path in ["commons/artifacts/regularity/disco_controls.gd","commons/context/discofloor/StandaloneDiscoFloor.gd","commons/context/discofloor/DiscoSequencerBridge.gd","commons/audio/sequencer/step_sequencer.gd","commons/audio/sequencer/sequencer_ui.gd"]:
		observations[path]=FileAccess.get_sha256("res://"+path)
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	if seq!=null:seq.stop()
	check("encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Isolated production museum. Floor controls receive supplied pointer events; sequencer controls receive UI signals. Selected key-input walks use the ordinary museum controller. Held phases and staged cameras supply the illustrations. Audio bus muted; generated note events do not establish listening quality, headset comfort or learner understanding."},"  "))
	print("DISCO SEPARATE CLOCKS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
