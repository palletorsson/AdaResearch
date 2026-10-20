extends "res://tools/probes/noise_types_trial_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	for use_xr in ([true] if take_photos else [false,true]):
		await start(use_xr)
		var content: Node3D=game.building.content
		var level: float=game.building.spec.levels[1]
		game.place_player(game.spawn_for(1))
		await frames(45)
		var bench: Node3D=content.exhibits["1/bench"].get_node("Artifact")
		var weather: Node3D=content.exhibits["1/weather"].get_node("Artifact")
		var a: Node3D=content.props["1/bench-console"].get_node("Prefab")
		var b: Node3D=content.props["1/weather-console"].get_node("Prefab")
		check("bench console binds original bench",a.source==bench and a.ports.size()==5)
		check("wall console binds original weather",b.source==weather and b.ports.size()==4)
		if a.controls==null or b.controls==null:
			game.queue_free();await frames(5);break
		check("original buttons hidden without deleting source",not a.source_panel.visible and is_instance_valid(a.ports[0]))
		check("old button colliders disabled",a.ports[0].collision_layer==0)
		var homes: Array=bench.sampling_state().homes.admitted.duplicate(true)
		var instance: Node3D=bench._points.admitted[0]
		var input: Node3D=a.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
		if use_xr:
			await point_and_press(right,input.global_position,Vector3(-.6,.25,0))
		else:
			input.button_pressed.emit(input)
			await frames(4)
		check("architectural REDRAW reaches source and preserves seeded homes",bench._points.admitted[0]!=instance and bench.sampling_state().homes.admitted==homes)
		var load_button: Node=b.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
		if use_xr: await point_and_press(right,load_button.global_position,Vector3(0,.3,.7))
		else: load_button.button_pressed.emit(load_button)
		await frames(100)
		check("architectural RUN starts the original weather clock",weather.running and weather.records.size()>0)
		b.controls.find_child("Btn_2",true,false).get_node("InteractableAreaButton").button_pressed.emit(load_button)
		await frames(3)
		check("architectural REPLAY resets the original record",weather.records.is_empty() and not weather.running)
		check("screen shows the real sampling accounting",a.screen.text==bench._readout.text)
		check("screen shows the real weather state",b.screen.text==weather.status.text+"\n"+weather.values.text)
		check("rigid supply reaches the architecture",a.has_node("HardwareSupply") and a.get_node("HardwareSupply").has_meta("grid_socket"))
		check("mounted controls use rectangular buttons",a.controls.find_child("Btn_0",true,false).get_node("Button/ButtonMesh").mesh is BoxMesh)
		# All mounts are native prefabs, with an honest unassigned state.
		var samples: Array[Node3D]=[]
		var kinds:=["floor","wall","pillar","ceiling_l","ceiling_j"]
		for i in range(kinds.size()):
			var node: Node3D=load("res://commons/void/interface_"+kinds[i]+".tscn").instantiate()
			content.roots[1].add_child(node)
			node.position=Vector3(-17+i*3,0,5.0)
			samples.append(node)
			check(kinds[i]+" has an unassigned physical socket",node.screen.text.begins_with("UNASSIGNED"))
		if take_photos:
			await photo("bench-console",Vector3(16.0,level+1.7,3.4),Vector3(18.5,level+1.3,1.5))
			await photo("weather-console",Vector3(1.7,level+1.7,-4.5),Vector3(-1,level+1.5,-6.85))
			await photo("mount-family",Vector3(-10.8,level+3.4,13.3),Vector3(-10.8,level+2.1,5))
			for i in range(kinds.size()):
				var at: Vector3=samples[i].global_position
				await photo(kinds[i],at+Vector3(1.9,2.2,3.3),at+Vector3(0,2.2 if kinds[i].begins_with("ceiling") else 1.25,0))
		for sample in samples: sample.queue_free()
		# Removing a terminal restores its source controls, including collision.
		var original: Node3D=a.source_panel
		a.queue_free();await frames(3)
		check("removing terminal restores original controls",original.visible and original.find_child("InteractableAreaButton",true,false).collision_layer!=0)
		game.queue_free();await frames(5)
		if use_xr:
			for tracker_node in [head,left,right]: XRServer.remove_tracker(tracker_node)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot desktop signal contract and synthetic XR pointer/trigger. Not physical headset evidence."},"\t"))
	quit(0 if failed.is_empty() else 1)
