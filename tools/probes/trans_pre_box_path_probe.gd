extends "res://tools/probes/void_trial_probe.gd"

func artifact(id: String) -> Node3D:
	return game.building.content.exhibits["1/"+id].get_node("Artifact")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg == "--capture": take_photos = true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated test saves", OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1); return
	for use_xr in ([false] if take_photos else [false,true]):
		await start(use_xr)
		var tag := "XR" if use_xr else "desktop"
		var content: Node3D = game.building.content
		check(tag+" starts in Pre", game.checkpoint==1)
		check(tag+" individual paintable construction cells", content.data.floors[1].construction.size()==175)
		var health_box: Node3D = artifact("first-health")
		var prefab_box: Node3D = artifact("found-solid")
		check(tag+" boxes initially closed", not health_box.opened and not prefab_box.opened)
		check(tag+" approach from below does not reveal", not health_box.can_open_from(game.body))
		var other := CharacterBody3D.new()
		game.add_child(other)
		check(tag+" ordinary bodies cannot claim rewards", not health_box.can_open_from(other))
		other.queue_free()
		var rise: Node3D = artifact("rise")
		var turn: Node3D = artifact("turn")
		var swell: Node3D = artifact("swell")
		var before_y: float = rise.position.y
		var before_turn: Basis = turn.basis
		var skin: MeshInstance3D = swell.find_child("CubeBaseMesh",true,false)
		var before_scale: Vector3 = skin.scale
		await frames(30)
		check(tag+" original rise still moves", not is_equal_approx(rise.position.y,before_y))
		check(tag+" original turn still turns", not turn.basis.is_equal_approx(before_turn))
		check(tag+" original scale still changes", not skin.scale.is_equal_approx(before_scale))
		rise.collect()
		check(tag+" demonstration stays in place", not rise.has_been_collected)
		if take_photos:
			await photograph("whole-path",Vector3(-11,-1.5,8),Vector3(3,-5,0))
			await photograph("learning-platforms",Vector3(0,-2.8,5.4),Vector3(0,-4.5,-1.3))
		game.place_player(Vector3(-6,-5.94,4.5)); await frames(15)
		check(tag+" climb the carried wedge", await move_to(Vector3(-6,-5,0)))
		check(tag+" walk into still example", await move_to(Vector3(-5,-5,-2)))
		check(tag+" still cube collects through real body overlap",game.trial_session.score==1)
		check(tag+" return to promenade", await move_to(Vector3(-5,-5,0)))
		check(tag+" step on health box", await move_to(Vector3(-3,-5,0)))
		check(tag+" footstep reveals a real health cross", health_box.opened and health_box.selected_kind=="health" and is_instance_valid(health_box.reward))
		check(tag+" full health leaves cross available", not health_box.reward.is_spent())
		game.health.set_health(60); await frames(45)
		check(tag+" revealed cross heals by 25", is_equal_approx(game.health.get_health(),85))
		check(tag+" health is delivered once", health_box.reward.is_spent())
		health_box.open_box(); await frames(40)
		check(tag+" repeated step cannot farm health", health_box.find_children("Reward","",false,false).size()==1 and is_equal_approx(game.health.get_health(),85))
		for x in [-1.5,2,5.5]:
			check(tag+" visit next explanation "+str(x),await move_to(Vector3(x,-5,0)))
		check(tag+" turn along south bank",await move_to(Vector3(6,-5,4)))
		check(tag+" step on mystery box",await move_to(Vector3(8,-5,4)))
		check(tag+" one existing solid selected",prefab_box.selected_kind in ["tetrahedron","pyramid","wedge"])
		var reward: Node3D = prefab_box.reward
		var selected: String = prefab_box.selected_kind
		prefab_box.open_box()
		check(tag+" selection does not reroll or duplicate",prefab_box.reward==reward and prefab_box.selected_kind==selected)
		check(tag+" original solid mesh remains visible",reward.find_children("*","MeshInstance3D",true,false).size()>0)
		check(tag+" late pickup registered for streaming",reward in game.floor_stream.records[1].pickables)
		if xr:
			var hand: Node3D=game.pickups[1]
			reward.pick_up(hand)
			check("XR reward accepts grip",reward.is_picked_up())
			reward.let_go(hand,Vector3.ZERO,Vector3.ZERO)
			check("XR reward releases",not reward.is_picked_up())
		else:
			reward.on_desktop_grab(game.body.desktop_pointer)
			check("desktop reward accepts grab",reward.held())
			reward.on_desktop_drop(game.body.desktop_pointer)
			check("desktop reward releases",not reward.held())
		if take_photos:
			await photograph("step-reward",Vector3(8.7,-3.2,6.1),Vector3(8,-4.6,4))
			await photograph("boxes-to-pickups",Vector3(8,-2.8,8.3),Vector3(16,-4.5,1))
		check(tag+" second health box",await move_to(Vector3(13,-5,4)))
		check(tag+" healing clamps at maximum",is_equal_approx(game.health.get_health(),100))
		check(tag+" join the pickup platform",await move_to(Vector3(16,-5,4)))
		check(tag+" collect along the raised deck",await move_to(Vector3(16,-5,-3)))
		check(tag+" four original pickups collected",game.trial_session.score==5)
		check(tag+" walk down the exit wedges",await move_to(Vector3(16,-6,-6)))
		for shaft_x in [-10,10]:
			var hit := ray(Vector3(shaft_x,-4,0),Vector3(shaft_x,-6.5,0))
			check(tag+" shaft remains open "+str(shaft_x),hit.is_empty())
		var box_top := ray(Vector3(-3,-4.8,0),Vector3(-3,-5.2,0))
		check(tag+" revealed box remains a walking support", not box_top.is_empty() and absf(box_top.position.y+5)<.02)
		game.place_player(game.spawn_for(2));await frames(20)
		game.place_player(game.spawn_for(1));await frames(20)
		check(tag+" leave and return keeps outcome",artifact("found-solid")==prefab_box and prefab_box.selected_kind==selected)
		check(tag+" leave and return keeps spent health",health_box.reward.is_spent())
		game.die("Retry box path");await frames(150)
		check(tag+" retry restores closed boxes",not artifact("first-health").opened and not artifact("found-solid").opened)
		check(tag+" retry restores the original collectibles",game.trial_session.score==0 and is_instance_valid(artifact("still")))
		var seen: Dictionary = {}
		for seed_value in range(12):
			var sample: Node3D = load("res://commons/void/step_prefab_box.tscn").instantiate()
			sample.reward_seed = seed_value
			sample.position = Vector3(0,-5,-8)
			game.add_child(sample)
			sample.open_box()
			seen[sample.selected_kind] = true
			check(tag+" seeded prefab "+str(seed_value)+" retains its mesh", not sample.reward.find_children("*","MeshInstance3D",true,false).is_empty())
			check(tag+" seeded prefab "+str(seed_value)+" removes scenery bodies", sample.reward.find_children("*","StaticBody3D",true,false).is_empty())
			var same: Node3D = load("res://commons/void/step_prefab_box.tscn").instantiate()
			same.reward_seed = seed_value
			game.add_child(same); same.open_box()
			check(tag+" seed repeats the same choice "+str(seed_value), same.selected_kind==sample.selected_kind)
			sample.free();same.free()
		check(tag+" reward pool exercises all three solids",seen.size()==3)
		game.queue_free();await frames(5)
		if xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"physical_headset":"not tested"},"\t"))
	print("PRE_BOX_PATH ",checks.size()," checks; failures ",failed)
	quit(0 if failed.is_empty() else 1)
