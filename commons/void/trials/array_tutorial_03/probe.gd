extends "res://tools/probes/void_transfer_probe.gd"
var musical_steps := 0

func focused_checks(tag: String) -> void:
	if level==1: await walls_checks(tag)
	else: await disco_checks(tag)

func panel_button(node: Node3D, label: String) -> Node3D:
	for panel in node.find_children("*","Node3D",true,false):
		if panel.get_script()==load("res://commons/ui/control_panel.gd"):
			for item in panel._items:
				if item.label==label:return item.node
	return null

func point_press(parent: Node3D, at := Vector3.ZERO) -> void:
	# Marker locates a real collision target; input still travels through the
	# desktop or tracked XR pointer, never directly to the tested callback.
	var proxy := Node3D.new();parent.add_child(proxy);proxy.position=at
	var area := Node3D.new();area.name="InteractableAreaButton";proxy.add_child(area)
	var point := Node3D.new();point.name="CollisionShape3D";area.add_child(point)
	await press(proxy);proxy.queue_free()

func ui_press(seq: Node3D, control: Control) -> void:
	var viewport: Node3D=seq.get_node("Viewport2Din3D")
	var pixel: Vector2=control.get_global_rect().get_center()
	await point_press(viewport,Vector3((pixel.x/viewport.viewport_size.x-.5)*viewport.screen_size.x,(.5-pixel.y/viewport.viewport_size.y)*viewport.screen_size.y,.005))

func walls_checks(tag: String) -> void:
	var tiles: Node3D=artifact("tiling_principles")
	var wall: Node3D=artifact("wall_exception")
	var rule: Node3D=tiles.rule_study
	check(tag+"six upright originals and 25 linked chart samples",tiles.walls and tiles.surfaces.size()==6 and rule.chart_samples.size()==25 and rule.field==null)
	check(tag+"full size eye chart clears ceiling",rule.chart.to_global(Vector3(0,6.3,0)).y<game.building.spec.levels[0]-.36)
	check(tag+"hinged wall binds to this floor's pattern",wall.study==tiles and wall.face.material_override.albedo_texture==tiles.surfaces[5].material_override.albedo_texture)
	var button: Node3D=panel_button(tiles,"TURN MOTIF")
	await approach(button.get_parent().get_parent().get_parent(),2.2)
	var textures: Array=tiles.surfaces.map(func(n):return n.material_override.albedo_texture.get_image().get_data())
	await press(button)
	check(tag+"TURN MOTIF updates all six walls",tiles.phase==1 and range(6).all(func(i):return tiles.surfaces[i].material_override.albedo_texture.get_image().get_data()!=textures[i]))
	var closed: Transform3D=wall.hinge.transform
	await press(panel_button(tiles,"EXCEPTION"))
	check(tag+"image exception does not move physical wall",tiles.exception and wall.hinge.transform==closed and wall.face.material_override.albedo_texture==tiles.surfaces[5].material_override.albedo_texture)
	await approach(rule.chart,2.3)
	var before: PackedByteArray=rule.local_texture.get_image().get_data()
	await press(rule.chart_button)
	check(tag+"chart NEXT RULE updates desk and all 25 samples together",rule.selected==3 and rule.applied and rule.local_texture.get_image().get_data()!=before and rule.chart_samples.all(func(n):return n.material_override.albedo_texture==rule.local_texture))
	await press(panel_button(rule.chart,"APPLY / UNDO"))
	check(tag+"chart UNDO restores repetition at all sizes",not rule.applied and rule.chart_samples.all(func(n):return n.material_override.albedo_texture.get_image().get_data()==rule.before.material_override.albedo_texture.get_image().get_data()))
	await approach(rule.desk,2.8)
	var address: Vector2i=rule.cell
	await press(rule.cell_button)
	check(tag+"desk NEXT TILE advances address without changing rule",rule.cell!=address and rule.selected==3)
	game.place_player(wall.to_global(Vector3(-2.2,.06,1.6)));await frames(20)
	var start: Vector3=wall.to_global(Vector3(-.7,1,.7))
	var finish: Vector3=wall.to_global(Vector3(.7,1,.7))
	check(tag+"closed sheet blocks passage",not ray(start,finish).is_empty())
	var image_before: Texture2D=wall.face.material_override.albedo_texture
	await press(wall.turn_button);await frames(160)
	check(tag+"TURN WALL moves its collision a quarter turn",wall.open and not wall.moving and is_equal_approx(wall.angle,PI/2) and ray(start,finish).is_empty())
	check(tag+"physical turn preserves the same printed texture",wall.face.material_override.albedo_texture==image_before)
	game.place_player(wall.to_global(Vector3(1,.06,.7)));await frames(20)
	await press(wall.turn_button)
	check(tag+"occupied landing refuses to close through player",wall.occupied() and wall.open and not wall.moving and wall.caption.text.contains("RETURN INSIDE"))
	game.place_player(wall.to_global(Vector3(-2.2,.06,1.6)));await frames(15)
	await press(wall.turn_button);await frames(160)
	check(tag+"return inside permits closing",not wall.open and not wall.moving and is_zero_approx(wall.angle))
	game.place_player(game.spawn_for(1));await frames(15)

func disco_checks(tag: String) -> void:
	var controls: Node3D=artifact("disco_controls")
	var floor_node: Node3D=artifact("standalone_disco").get_node("DiscoFloor")
	var seq: Node3D=artifact("step_sequencer")
	check(tag+"original 12 by 12 floor uses source 0.8 metre tiles",floor_node.grid_width==12 and floor_node.grid_depth==12 and floor_node.multimesh.instance_count==144 and is_equal_approx(floor_node.tile_size,.8) and is_zero_approx(floor_node.floor_y_offset))
	check(tag+"controls and musical bridge bind within same floor",controls.floor_node==floor_node and controls.sequencer==seq and floor_node.get_node("SequencerBridge").step_sequencer==seq)
	check(tag+"source monochrome mode and silent house preset",not controls.colour and controls.palette==0 and floor_node.monochrome and seq.sound_preset=="90s_house" and not seq._is_playing)
	check(tag+"receiver preserves readable values without white emission",not floor_node.multimesh_instance.material_override.emission_enabled and floor_node.multimesh_instance.material_override.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED)
	var button: Node3D=panel_button(controls,"PLAY / HOLD")
	await approach(button.get_parent().get_parent().get_parent(),1.8)
	await press(button)
	var phase: int=controls.phase
	var colours: Array=floor_node.tile_colors.duplicate()
	await frames(40)
	check(tag+"HOLD stops visual clock and tile values",not controls.running and controls.phase==phase and floor_node.tile_colors==colours)
	await press(panel_button(controls,"ONE STEP"))
	check(tag+"ONE STEP exchanges checker values at fixed addresses",controls.phase==phase+1 and floor_node.tile_colors[0]==colours[1] and floor_node.tile_colors[1]==colours[0])
	await press(panel_button(controls,"PATTERN"))
	check(tag+"PATTERN starts the rows rule",controls.pattern==1 and controls.phase==0)
	var interval: float=controls.interval
	await press(panel_button(controls,"SPEED"))
	check(tag+"SPEED changes interval without phase",controls.interval!=interval and controls.phase==0)
	for i in 3:await press(panel_button(controls,"PATTERN"))
	check(tag+"SUPER TRIANGLE retains original live surface",controls.pattern==4 and is_instance_valid(controls.triangle_surface) and controls.triangle_surface.visible)
	await press(panel_button(controls,"ONE STEP"))
	check(tag+"held triangles step to next pose",controls.phase==1 and controls.triangle_motion==1 and not controls.running)
	await press(panel_button(controls,"PATTERN"))
	check(tag+"pattern cycle returns to checker",controls.pattern==0 and not controls.triangle_surface.visible)
	await approach(seq,1.1)
	await ui_press(seq,seq._sequencer_ui._buttons[1][0])
	check(tag+"pointer writes a note through original 2D score",seq._sequencer_ui._grid_data[1][0])
	musical_steps=0
	seq.step_triggered.connect(func(_track,_step):musical_steps+=1)
	phase=controls.phase
	await ui_press(seq,seq._sequencer_ui._play_button);await frames(35)
	check(tag+"PLAY runs musical clock while visual clock holds",seq._is_playing and musical_steps>0 and controls.phase==phase and not controls.running)
	await ui_press(seq,seq._sequencer_ui._play_button);await frames(20)
	check(tag+"STOP ends score clock and clears temporary flashes",not seq._is_playing and controls.pulse_remaining.is_empty())
	# Explicit API edge assertion: source bridge maps 16 score steps to 12
	# columns. Real pointer playback above tests the live connection separately.
	var bridge: Node=floor_node.get_node("SequencerBridge")
	var values: Array=floor_node.tile_colors.duplicate()
	seq.step_triggered.emit(1,12);await frames(1)
	check(tag+"API step 12 wraps to floor column zero",bridge._beat_step==12 and controls.pulse_remaining.has(0) and floor_node.tile_colors[0]!=values[0])
	await frames(14)
	check(tag+"musical flash restores held values",controls.pulse_remaining.is_empty() and floor_node.tile_colors==values)
	var monitor: Node3D=artifact("film_disco_phase")
	await approach(monitor,2)
	await point_press(monitor.buttons["pause"])
	check(tag+"film pointer pauses its independent stage",not monitor.stage.running)
	await point_press(monitor.buttons["pause"])
	check(tag+"film pointer resumes stage",monitor.stage.running)
	# Traverse a changing field with the real locomotion provider.
	if xr:
		var rig: Node3D=game.get_node("XROrigin3D")
		left.set_pose("aim",Transform3D(rig.global_basis.inverse(),Vector3(-.3,1.2,-.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	controls.running=true
	var support: Transform3D=floor_node.get_node("FloorCollision").global_transform
	var tile: Transform3D=floor_node.multimesh.get_instance_transform(0)
	game.place_player(floor_node.to_global(Vector3(0,.06,3.5)));await frames(15)
	check(tag+"walk across animated values on unchanged support",await move_to(floor_node.to_global(Vector3(0,.06,-3.5))) and floor_node.get_node("FloorCollision").global_transform==support and floor_node.multimesh.get_instance_transform(0)==tile)
	seq.play();await frames(12)
	game.place_player(game.spawn_for(1));await frames(25)
	phase=controls.phase
	var music_position: int=seq._playhead_position
	await frames(45)
	check(tag+"leaving Disco pauses both clocks and sound",not controls.can_process() and controls.phase==phase and seq._playhead_position==music_position and seq._audio_players.all(func(p):return not p.playing or p.stream_paused))
	# SPEED selected a one-second interval: wait longer than a complete beat.
	game.place_player(game.spawn_for(2));await frames(90)
	print("DISCO_RESUME ",tag," process=",controls.can_process()," phase=",phase," -> ",controls.phase," note=",seq._sequencer_ui._grid_data[1][0]," interval=",controls.interval)
	check(tag+"return resumes same score and visual clock",controls.can_process() and controls.phase>phase and seq._sequencer_ui._grid_data[1][0])
	seq.stop();controls.running=false;controls.pattern=0;controls.phase=0;controls.paint()
	game.place_player(game.spawn_for(2));await frames(12)

func capture_floor() -> void:
	if level==1:
		var tiles: Node3D=artifact("tiling_principles")
		await photo("01-six-upright-rules",tiles.to_global(Vector3(1.5,2.5,-15)),tiles.to_global(Vector3(0,2,0)))
		var wall: Node3D=artifact("wall_exception")
		wall.turn_wall();await frames(160)
		await photo("02-turning-the-physical-wall",wall.to_global(Vector3(-2,3,5)),wall.to_global(Vector3(1.1,1.8,.5)))
	else:
		var floor_node: Node3D=artifact("standalone_disco")
		await photo("03-array-with-a-clock",floor_node.to_global(Vector3(7,5.3,8)),floor_node.to_global(Vector3(0,0,0)))
		var controls: Node3D=artifact("disco_controls")
		controls.pattern=4;controls.phase=4;controls.triangle_motion=4;controls.paint()
		await photo("04-super-triangle",floor_node.to_global(Vector3(-7,4.8,6)),floor_node.to_global(Vector3(0,0,0)))
