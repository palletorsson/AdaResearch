extends "res://tools/probes/matter_gates_probe.gd"
const ModelStorage = preload("res://tools/generated_storage.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	level=7;take_photos=true
	# Exercise the actual shared writer with an old-style res:// output request.
	var requested := "res://ada_run/generated-storage-migration/guard-model.glb"
	var actual := ModelStorage.output_directory(requested)
	var witness := MeshInstance3D.new();witness.mesh=BoxMesh.new();root.add_child(witness)
	var document := GLTFDocument.new();var state := GLTFState.new()
	check("shared export builds native model",document.append_from_scene(witness,state)==OK)
	check("old project output redirects to external storage",actual.begins_with(ModelStorage.root_directory()+"/project/") and ModelStorage.write_gltf(document,state,requested)==OK)
	check("no generated GLB returns to source or isolated Godot project",not FileAccess.file_exists(requested) and not FileAccess.file_exists(ModelStorage.project_directory().path_join("ada_run/generated-storage-migration/guard-model.glb")))
	check("absolute and res paths agree",actual==ModelStorage.output_directory(ModelStorage.project_directory().path_join("ada_run/generated-storage-migration/guard-model.glb")))
	var loaded := GLTFState.new()
	check("actual external GLB remains readable",document.append_from_file(actual,loaded)==OK)
	witness.queue_free()
	var original := load("res://addons/godot-xr-tools/hands/model/Hand_low_L.gltf") as PackedScene
	check("original imported XR hand model still loads",original!=null)
	if original!=null:
		var hand_scene := original.instantiate()
		check("original hand retains its actual mesh",not hand_scene.find_children("*","MeshInstance3D",true,false).is_empty())
		hand_scene.free()
	for mode in [false,true]:
		xr=mode
		OS.set_environment("VOID_INVENTORY_PATH",out.path_join("isolated-storage-"+str(mode)+"-"+str(Time.get_ticks_usec())+".json"))
		if xr:
			head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
			left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
			right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
			left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		game=load("res://commons/void/void.tscn").instantiate();game.force_xr=xr
		root.add_child(game);current_scene=game
		if not xr:game.body.scripted_input=true
		await frames(60);game.scene_loaded();game.scene_visible();await frames(30)
		game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180);game.atmosphere.environment.fog_enabled=false
		var label := "Synthetic XR / " if xr else "Desktop / "
		check(label+"main Cube floor starts",game.trial_id.is_empty() and game.checkpoint==7 and not game.recovering)
		check(label+"visitor camera stays active",game.get_viewport().get_camera_3d()==game.camera)
		check(label+"all saved floor artifacts instantiate",game.building.content.data.floors[7].artifacts.all(func(a):return game.building.content.exhibits.has("7/"+str(a.id))))
		var gate: Node3D=station("matter-and")
		check(label+"game still uses native scene and editable parts",gate.scene_file_path=="res://commons/artifacts/matter_gates/matter_and.tscn" and gate.part_defaults.size()>=27)
		game.place_player(gate.to_global(Vector3(.08,.06,1)));await frames(15)
		await press(gate.buttons[3].get_node("PushButton"))
		for i in 2:await press(gate.buttons[i].get_node("PushButton"))
		await press(gate.buttons[2].get_node("PushButton"));await await_result(gate)
		check(label+"real mouse / trigger input still runs native ball physics",gate.inputs==Vector2i.ONE and gate.outcome==1)
		if not xr:await photo("desktop-after-move",gate.to_global(Vector3(.4,1.65,1.8)),gate.to_global(Vector3(.05,1.05,-.05)))
		game.queue_free();await frames(10)
		if xr:
			for item in [head,left,right]:XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("native-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"external_model":actual,"scope":"Actual writer redirect and readback, original imported XR model, main floor7 native geometry/startup/camera, real desktop mouse and synthetic XR trigger input with physical AND arrival. No physical headset."},"  "))
	print("GENERATED_STORAGE_RESULT ",checks.size()," ",failed);quit(0 if failed.is_empty() else 1)
