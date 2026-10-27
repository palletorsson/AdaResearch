extends "res://tools/probes/array_trial_probe.gd"
## Test the mounted original binary table against the current editable Array layout.
## The earlier trial probe describes the previous four-by-four/worksite arrangement.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	for use_xr in [false,true]:
		await visit_display(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Actual Array trial, desktop and synthetic XR. No physical headset test."
	},"\t"))
	print("ARRAY_CEILING_RESULT ", checks.size(), " checks; failures: ", failed)
	quit(0 if failed.is_empty() else 1)

func visit_display(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	var content: Node3D=game.building.content
	var record: Dictionary=content.data.floors[1].artifacts.filter(func(item):return item.id=="grid")[0]
	var grid: Node3D=content.exhibits["1/grid"].get_node("Artifact")
	var table: Node3D=grid._binary_table
	var mount := table.get_node_or_null("CeilingMount") as Node3D
	check(tag+"original array and live binary table retained",grid.get_script().resource_path=="res://algorithms/arrays/grid_2d_4x4.gd" and table.get_script().resource_path=="res://algorithms/arrays/binary_table/binary_table_display.gd")
	check(tag+"current configured grid retains all its pickup cubes",grid._cube_refs.size()==grid.rows*grid.cols)
	check(tag+"one ceiling housing after the configured grid rebuild",mount!=null and grid.find_children("CeilingMount","Node3D",true,false).size()==1)
	if mount:
		var contact: Vector3=mount.get_node("SlabContact").global_position
		var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(contact-Vector3.UP*.15,contact+Vector3.UP*.15,1))
		check(tag+"mounting plate meets the actual upper slab",not hit.is_empty() and hit.position.distance_to(contact)<.005)
		check(tag+"electrical trunk joins ceiling junction and rear socket",mount.has_node("ServiceTrunk") and mount.has_node("CeilingJunction") and mount.has_node("RearSocket"))
	var position: Array=record.config.get("table_position",[-2,1.8,1.5])
	check(tag+"curated screen position retained",table.position.is_equal_approx(Vector3(position[0],position[1],position[2])))
	var before_score: int=root.get_node("GameManager").player_score
	var neighbour: Node3D=grid._cube_refs["2_1"]
	var selected: Node3D=grid._cube_refs["1_2"]
	game.place_player(selected.global_position+Vector3.UP*.06)
	await frames(30)
	check(tag+"real body overlap collects the addressed cube",not grid._cube_refs.has("1_2") and grid.grid_data[1][2]==0)
	check(tag+"housed screen visibly reports the empty address",table.data[1][2]==0 and table.get_node("Cell_1_2").text=="0")
	check(tag+"neighbour and museum progress stay intact",grid._cube_refs.get("2_1")==neighbour and grid.grid_data[2][1]==1 and root.get_node("GameManager").player_score==before_score)
	if not xr:
		# Both images are real native renders with the game's evening atmosphere.
		var centre: Vector3=table.global_position
		await photo("ceiling-mount",centre+table.global_basis*Vector3(1.6,1.3,5),centre+Vector3(0,1.35,0))
		await photo("live-display",centre+table.global_basis*Vector3(1.7,.35,3.7),centre+Vector3(0,.1,0))
		# The opt-in is essential: the source museum artifact remains unmounted.
		var source: Node3D=load("res://algorithms/arrays/grid_2d_4x4.gd").new()
		source.position=Vector3(100,0,100)
		root.add_child(source)
		await frames(2)
		check("museum default has no Void housing",source.find_children("CeilingMount","Node3D",true,false).is_empty() and source._cube_refs.size()==16)
		source.queue_free()
	game.die("Retry mounted array")
	await frames(120)
	var restored: Node3D=content.exhibits["1/grid"].get_node("Artifact")
	check(tag+"retry restores cubes, live values and exactly one mount",restored._cube_refs.size()==restored.rows*restored.cols and restored._binary_table.get_node("Cell_1_2").text=="1" and restored.find_children("CeilingMount","Node3D",true,false).size()==1)
	game.queue_free()
	await frames(6)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
