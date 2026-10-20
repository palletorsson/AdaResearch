extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	if map_id=="Random_Remove":await removal_checks()
	else:await room_checks()

func removal_checks() -> void:
	var arena:=find_scene("/removal_arena.gd")
	check("configured arena loaded",arena!=null)
	if arena==null:return
	arena.set_physics_process(false)
	observations["arena_position"]=xyz(arena.position)
	observations["arena_world"]=xyz(arena.global_position)
	check("15 by 11 tiles and coils",arena.columns==15 and arena.rows==11 and arena.coils!=null and arena.colliders.size()==165)
	check("full crossing configured",arena.full_crossing and arena.tesla_coils)
	check("arena retains unit scale",arena.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	await tick()
	var supported:=0
	for i in range(165):
		var p:Vector3=arena.to_global(arena.coils.cell_position(i))
		var hit:=floor_at(p)
		if not hit.is_empty() and arena.is_ancestor_of(hit.collider):supported+=1
	check("all 165 initial support rays hit arena colliders",supported==165)
	# If museum secretly filled the old side lanes, these rays would still hit.
	for i in [0,14,75,89,150,164]:arena.colliders[i].disabled=true
	await tick()
	var clear:=true
	for i in [0,14,75,89,150,164]:
		clear=clear and floor_at(arena.to_global(arena.coils.cell_position(i))).is_empty()
	check("removed side tiles expose void without a hidden bypass floor",clear)
	arena.reset_arena();await tick()
	var order:Array=[]
	for turn in range(3):
		arena.request_removal()
		var chosen:int=arena.remover.get_state().last_selected
		check("charge marks selected address "+str(turn),arena.coils.charge_marker.visible and arena.coils.charge_marker.position.is_equal_approx(arena.coils.cell_position(chosen)+Vector3.UP*3.66))
		await arena.remover.instance_removed
		await tick()
		order.append(chosen)
		check("strike and disabled collider share address "+str(turn),arena.coils.active_index==chosen and arena.colliders[chosen].disabled)
		check("bolt falls from tip to tile "+str(turn),arena.coils.strike_points[0].is_equal_approx(arena.coils.cell_position(chosen)+Vector3.UP*3.55) and arena.coils.strike_points[-1].is_equal_approx(arena.coils.cell_position(chosen)+Vector3.UP*0.02))
	observations["first_three"]=order
	var struck:Vector3=arena.coils.cell_position(order[-1])
	await snapshot("lightning-strike",arena.to_global(struck+Vector3(-2,1.8,-2.5)),arena.to_global(struck+Vector3.UP*1.8),67)
	await snapshot("lightning-crossing",arena.to_global(Vector3(-5.6,2.2,-6.6)),arena.to_global(Vector3(0,1.4,1)),65)
	await snapshot("lightning-overview",arena.to_global(Vector3(0,9,-7.1)),arena.to_global(Vector3(0,0,0)),64)
	arena.reset_arena();await tick()
	for chosen in order:
		arena.request_removal();check("replay repeats address "+str(chosen),arena.remover.get_state().last_selected==chosen)
		await arena.remover.instance_removed
	arena.reset_arena();await tick()
	arena.request_removal();arena.reset_arena()
	await create_timer(1.0).timeout
	check("reset cancels pending removal and charge",arena.get_state().remaining==165 and not arena.coils.charge_marker.visible and not arena.coils.bolt.visible)
	# Exercise the real area and idle timer with the museum's actual desktop body.
	var player:CharacterBody3D=museum.get("_player")
	if player!=null:
		player.set_physics_process(false)
		player.global_position=arena.to_global(Vector3(0,1.0,-4))
		arena.set_physics_process(true)
		await create_timer(0.95).timeout
		check("entry starts removal",arena.remover.removed_count>=1)
		await create_timer(4.2).timeout
		check("standing inside also receives timed random strikes",arena.remover.removed_count>=2)
		player.global_position=arena.to_global(Vector3(0,1,-8))
		await tick();arena.set_physics_process(false)
	arena.reset_arena();await tick()
	await snapshot("crossing-entrance",arena.to_global(Vector3(0,1.7,-8)),arena.to_global(Vector3(0,1.6,0)),66)

func room_checks() -> void:
	var room:=find_scene("/seeded_room.gd")
	check("seeded walk-through loaded",room!=null)
	if room==null:return
	observations["room_position"]=xyz(room.position)
	observations["room_world"]=xyz(room.global_position)
	check("full scale 8 by 8 grid",room.blocks.size()==64 and room.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	var initial:Array=room.values.duplicate()
	room.panel.find_child("Btn_0",true,false).pressed.emit()
	check("real replay button retains all values",initial==room.values)
	room.activate(1)
	check("next seed changes tested arrangement",room.seed_value==43 and initial!=room.values)
	room.restore_museum_state({"seed":42})
	room.activate(5)
	check("frequency leaves independent values unchanged",initial==room.values)
	room.activate(4)
	check("Perlin changes tested field",initial!=room.values)
	var correlated:Array=room.values.duplicate()
	room.activate(0)
	check("coherent field also replays",correlated==room.values)
	room.restore_museum_state({"seed":42})
	var paired:=true
	for i in range(64):
		paired=paired and room.plan_cells[i].material_override.albedo_color==room.blocks[i].material_override.albedo_color
		paired=paired and is_equal_approx(room.boundaries[i].shape.size.y,room.blocks[i].mesh.size.y)
	check("plan colours and solid collision match displayed columns",paired)
	var open:=true
	for i in room.passage:open=open and is_equal_approx(room.heights[i],0.025)
	check("all declared passage cells stay low",open)
	await snapshot("seeded-room-overview",room.to_global(Vector3(-0.4,7.8,-5.7)),room.to_global(Vector3(0,0.5,0)),65)
	await snapshot("seeded-room-entrance",room.to_global(Vector3(0.5,1.7,-6.1)),room.to_global(Vector3(-0.1,1.6,0)),78)
	await snapshot("seed-plan",room.to_global(Vector3(-2.4,2,-6.7)),room.to_global(Vector3(-2.4,1.9,-5.35)),65)
	# Real body sweep along the entire declared winding path.
	var walker:=CharacterBody3D.new();walker.collision_layer=524288;walker.collision_mask=1
	walker.add_to_group("player_body")
	var col:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.2;capsule.height=1.7
	col.shape=capsule;col.position.y=0.85;walker.add_child(col);hall.add_child(walker)
	walker.global_position=room.to_global(room.centre(4)+Vector3(0,0.05,-0.6))
	await tick()
	var walked:=true
	var prev:=4
	for z in range(8):
		var next:int=room.TURN_COLUMNS[z]
		var destinations:Array=[room.centre(z*8+prev),room.centre(z*8+next)]
		for destination:Vector3 in destinations:
			var goal:Vector3=room.to_global(destination+Vector3.UP*0.045)
			for step in range(150):
				var delta:=goal-walker.global_position;delta.y=0
				if delta.length()<0.1:break
				walker.velocity=delta.normalized()*4.0+Vector3.DOWN
				walker.move_and_slide();await tick()
			var remaining:Vector3=goal-walker.global_position;remaining.y=0
			if remaining.length()>0.16:walked=false;observations["blocked_at"]=xyz(walker.global_position);break
		prev=next
		if not walked:break
	check("capsule walks full winding route through the raised room",walked)
	check("body inside is detected",room.occupied())
	room.activate(1)
	check("room cannot regenerate around an occupied body",room.seed_value==42)
	await snapshot("inside-seeded-room",room.to_global(Vector3(0.55,1.7,-2.7)),room.to_global(Vector3(-0.55,1.4,0.5)),70)
	var exit_goal:Vector3=room.to_global(Vector3(-3.85,0.045,5.5))
	for step in range(150):
		var delta:=exit_goal-walker.global_position;delta.y=0
		if delta.length()<0.1:break
		walker.velocity=delta.normalized()*4+Vector3.DOWN;walker.move_and_slide();await tick()
	var exit_gap:Vector3=exit_goal-walker.global_position;exit_gap.y=0
	check("capsule exits through connecting doorway",exit_gap.length()<0.16)
	walker.queue_free();await tick();await tick()
	room.activate(2);await create_timer(1.8).timeout
	check("flatten preserves samples and lowers colliders",initial==room.values and is_zero_approx(room.lift) and is_equal_approx(room.boundaries[0].shape.size.y,0.025))
	await snapshot("flat-seeded-plan",room.to_global(Vector3(-0.4,7.8,-5.7)),room.to_global(Vector3(0,0,0)),65)
	room.activate(2);await create_timer(1.8).timeout
	check("raise returns the same geometry",initial==room.values and is_equal_approx(room.lift,1))
	var legacy:Node3D=load("res://commons/artifacts/randomness_space/removal_arena.tscn").instantiate()
	root.add_child(legacy);legacy.position=Vector3(1000,0,0);await tick()
	check("unconfigured legacy arena remains 99 tiles without coils",legacy.columns==9 and legacy.rows==11 and legacy.coils==null and not legacy.full_crossing)
	legacy.queue_free()
