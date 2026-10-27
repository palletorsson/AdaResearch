extends "res://tools/probes/array_hand_index_probe.gd"
## Run the existing real-input experiment through the new physical housings.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	var museum_score: int=root.get_node("GameManager").player_score
	for use_xr in [false,true]:
		await visit(use_xr,museum_score)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native desktop and simulated XR grip, movement, trigger and pointer input. No physical headset test."
	},"\t"))
	print("ARRAY_HARDWARE_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func start(use_xr: bool) -> void:
	await super.start(use_xr)
	var tag: String="XR: " if xr else "Desktop: "
	var content: Node3D=game.building.content
	var row: Node3D=content.exhibits["1/row"].get_node("Artifact")
	var work: Node3D=content.exhibits["1/worksite"].get_node("Artifact")
	var strip: Node3D=row._binary_table.get_node_or_null("CeilingMount")
	check(tag+"row has one mounted live readout",strip!=null and row._binary_table.data==row.array_data)
	check(tag+"row title clears the column-index band",row._binary_table.get_node("TitleLabel").position.y-row._binary_table.get_node("ColLabel_16").position.y>.12)
	if strip:
		var contacts: Array=strip.get_children().filter(func(n):return n is Marker3D and str(n.name).contains("HangerContact"))
		check(tag+"long readout has two real slab connections",contacts.size()==2 and contacts.all(func(n):return meets_slab(n)))
	var grid: Node3D=content.exhibits["1/grid"].get_node("Artifact")
	var grid_mount: Node3D=grid._binary_table.get_node_or_null("CeilingMount")
	check(tag+"existing seven-by-seven screen retains its ceiling connection",grid_mount!=null and meets_slab(grid_mount.get_node("SlabContact")))
	var hardware: Node3D=work.get_node_or_null("ArchitecturalHardware")
	check(tag+"selector has a floor cabinet and ceiling service route",hardware!=null and hardware.has_node("GridCabinet") and hardware.has_node("ControlCabinet") and hardware.has_node("ServiceTrunk") and hardware.has_node("SlabJunction"))
	if hardware:check(tag+"selector service plate meets the actual upper slab",meets_slab(hardware.get_node("SlabContact")))
	var rectangular:=true
	for button in [work.add_button,work.remove_button,work.restore_button]:
		rectangular=rectangular and button.get_node("Button/ButtonMesh").mesh is BoxMesh and button.get_node("InteractableAreaButton/CollisionShape3D").shape is BoxShape3D
	check(tag+"all three existing buttons have rectangular caps and touch volumes",rectangular)
	check(tag+"miniature grid and carried point keep their original working height",work.point.position.y>1.1 and work.point.position.y<1.2 and is_equal_approx(work.small_mesh.multimesh.get_instance_transform(0).origin.y,1.04))
	work.apply_grid_config({"interface_style":"architectural"})
	check(tag+"reapplying configuration creates no duplicate cabinet",work.find_children("ArchitecturalHardware","Node3D",true,false).size()==1)
	var source: Node3D=load("res://commons/artifacts/array_index_bridge/array_index_bridge.gd").new()
	source.position=Vector3(100,0,100)
	root.add_child(source);await frames(3)
	check(tag+"unconfigured artifact keeps its original presentation",not source.has_node("ArchitecturalHardware") and source.get_node("ControlTable").visible)
	source.queue_free()
	var original_row: Node3D=load("res://algorithms/arrays/row_3_x.gd").new()
	original_row.position=Vector3(100,0,100)
	root.add_child(original_row);await frames(2)
	check(tag+"original museum row has no architectural mount",not original_row._binary_table.has_node("CeilingMount"))
	original_row.queue_free()
	if not xr:
		await photo("mounted-row",row._binary_table.global_position+Vector3(3,1.2,6),row._binary_table.global_position+Vector3(0,.5,0))
		await photo("selector-station",work.to_global(Vector3(3.1,2.45,3.5)),work.to_global(Vector3(.8,1.15,-.1)))
		await photo("player-sightline",work.to_global(Vector3(1.65,1.65,1.5)),work.to_global(Vector3(1.65,1.65,-3.9)))
		await photo("both-displays",work.to_global(Vector3(.8,1.65,2.3)),work.to_global(Vector3(.8,1.65,-3.9)))
		await photo("ceiling-connection",work.to_global(Vector3(4,3.4,4.3)),work.to_global(Vector3(.9,2.6,-.3)))

func meets_slab(marker: Node3D) -> bool:
	var at:=marker.global_position
	var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at-Vector3.UP*.15,at+Vector3.UP*.15,1))
	return not hit.is_empty() and hit.position.distance_to(at)<.005

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if xr:return
	var visible_before: bool=game.body.visible
	game.body.hide()
	await super.photo(filename,at,target)
	game.body.visible=visible_before
