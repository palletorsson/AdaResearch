extends "res://tools/probes/triangle_shaft_quad_probe.gd"
## Main-tower access/load sampling. Artifact mechanics remain outside this pass.
class MenuHost extends Node3D:
	var chosen := -1
	var closed := false
	func _open_void_floor(index: int) -> void: chosen=index
	func _open_void_trial(_id: String) -> void: pass
	func _close_void_trials() -> void: closed=true

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var source := preload("res://commons/void/room_source.gd")
	if "--menu-only" in OS.get_cmdline_user_args(): source.use_main_tower=true
	var layout: Dictionary=source.read_layout()
	check("all 205 maps are in the main tower",source.read_rooms().floors.size()==205 and layout.levels.size()==205)
	check("24 included sequences in order",layout.spine.size()==24 and layout.spine.back().id=="postfoundationscrisis")
	check("standard floor dimensions retained",layout.width==42 and layout.depth==18 and layout.storey_height==6)
	check("source adapters follow relocated floors",source.floor_trial(layout,67)=="wavefunctions_04" and source.floor_trial(layout,144)=="isosurfaces_02" and source.floor_trial(layout,11).is_empty())
	check("cross-floor copies keep their own adapter context",source.artifact_trial(layout,11,{"config":{"editor_source":{"floor":67,"id":"original"}}})=="wavefunctions_04" and source.artifact_trial(layout,67,{"config":{"editor_source":{"floor":11,"id":"original"}}}).is_empty())
	var fixture := MenuHost.new()
	root.add_child(fixture)
	var picker: Node3D = load("res://commons/void/spine_picker.gd").new()
	fixture.add_child(picker)
	picker.configure(fixture)
	check("menu uses bounded sequence pages",picker.get_children().size()<=10 and picker.get_node("SpinePageTitle").text.contains("1/4"))
	picker.selected_sequence=23
	picker.page=1
	picker.show_page()
	check("last map is selectable on the final page",picker.get_children().any(func(n):return n is StaticBody3D and str(n.text).begins_with("204 /")))
	for child in picker.get_children():
		if child is StaticBody3D and str(child.text).begins_with("204 /"): child.clicked.emit()
	check("menu selection dispatches the actual final floor",fixture.chosen==204)
	if "--menu-only" in OS.get_cmdline_user_args():
		check("main menu choice overrides CLI trial while explicit trials still work",source.selected().is_empty() and source.selected("cellularautomata")=="cellularautomata")
		var visited := {}
		for seq_index in range(layout.spine.size()):
			picker.selected_sequence=seq_index
			for page_index in range(ceili(float(layout.spine[seq_index].floors.size())/6)):
				picker.page=page_index
				picker.show_page()
				for child in picker.get_children():
					if child is StaticBody3D and child.visible and str(child.text).contains(" / "):
						child.clicked.emit()
						visited[fixture.chosen]=true
				await frames(1)
		check("menu dispatches every one of the 205 floors",visited.size()==205)
		check("actual main menu script compiles with navigation",load("res://commons/scenes/main_menu/MainMenu3D.gd")!=null)
		picker.selected_sequence=-1;picker.page=0;picker.show_page()
		await frames(3)
		fixture.queue_free();await frames(4)
		FileAccess.open(out.path_join("native-menu-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks},"  "))
		print("VOID_SPINE_MENU ",checks.size()," checks; passed=",failed.is_empty())
		quit(0 if failed.is_empty() else 1)
		return
	fixture.queue_free()
	await frames(5)
	for mode in [false,true]:
		load("res://commons/void/game.gd").requested_floor=20
		await start(mode)
		var tag := "Synthetic XR: " if mode else "Desktop: "
		check(tag+"main menu request starts directly at Array",game.trial_id.is_empty() and game.checkpoint==20 and game.floor_stream.focus==20)
		check(tag+"selection request consumed once",load("res://commons/void/game.gd").requested_floor==-1)
		# Main-tower relocation, special local adapters and the final floor.
		for index in [20,67,68,144,204]:
			game.checkpoint=index
			game.place_player(game.spawn_for(index))
			await frames(12)
			var content: Node3D=game.building.content
			check(tag+"floor %d is active and at the shared storey" % index,game.floor_stream.focus==index and is_equal_approx(content.roots[index].position.y,float(layout.levels[index])) and game.get_viewport().get_camera_3d()==game.camera)
			check(tag+"floor %d loads every saved artifact" % index,content.data.floors[index].artifacts.all(func(a):return content.exhibits.has("%d/%s" % [index,a.id])))
			check(tag+"floor %d spawn is inside the standard slab" % index,absf(game.spawn_for(index).x)<21 and absf(game.spawn_for(index).z)<9)
			if index==68:
				var adapted := false
				for a in content.data.floors[index].artifacts:
					if a.artifact=="math_objects": adapted=content.exhibits["%d/%s" % [index,a.id]].get_node("Artifact").get_script().resource_path.ends_with("math_gallery_local.gd")
				check(tag+"relocated music gallery keeps its local adapter",adapted)
			if index==144:
				check(tag+"relocated isosurface retains museum context",content.roots[index].get_script()!=null and content.roots[index].get_script().resource_path.ends_with("museum_context.gd"))
			if not mode and index==204:
				await photograph("final-spine-floor",Vector3(10,-1220,7.5),Vector3(0,-1222.5,0))
		check(tag+"structural visibility remains bounded",game.floor_stream.summary().visible_frame.size()<=9)
		var source_item: Dictionary=game.building.content.data.floors[67].artifacts[0].duplicate(true)
		var original_id: String=source_item.id
		source_item.id="spine-context-copy"
		source_item.config.editor_source={"floor":67,"id":original_id}
		source_item.position=[0,7]
		game.building.content._build_artifact(game.building.content.roots[20],20,source_item)
		var copied: Node3D=game.building.content.exhibits["20/spine-context-copy"].get_node("Artifact")
		check(tag+"cross-sequence native copy keeps original local adapter",copied.get_script().resource_path.ends_with("metallophone_local.gd") and is_equal_approx(copied.get_parent().global_position.y,float(layout.levels[20])+float(source_item.height)))
		game.queue_free()
		await frames(10)
		if mode:
			for input_tracker in [head,left,right]: XRServer.remove_tracker(input_tracker)
	var passed := checks.all(func(c):return c.passed)
	FileAccess.open(out.path_join("native-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Main spine navigation, representative desktop/synthetic-XR loading, source adapters and standard frame. No artifact button/grab/combat tests, physical-headset or complete clearance acceptance."},"  "))
	print("VOID_SPINE_PROBE ",checks.size()," checks; passed=",passed)
	quit(0 if passed else 1)
