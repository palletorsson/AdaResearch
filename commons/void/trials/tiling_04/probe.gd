extends "res://commons/void/trials/tiling_03/probe.gd"

func focused_checks(tag: String) -> void:
	check(tag+"standard floor",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	var studio: Node3D=artifact("fabric_shader_studio")
	var runway: Node3D=artifact("drag_catwalk")
	await approach(studio.mount,1.2)
	await press(studio.buttons["REPEAT"])
	check(tag+"REPEAT edits original recipe",studio.recipe.repeats==8)
	await press(studio.buttons["SAVE"])
	check(tag+"SAVE writes recoverable recipe",studio.saved_recipe().repeats==8)
	await press(studio.buttons["RUNWAY SAVED"])
	check(tag+"four original performers wear saved fabric",runway.agents.size()==4 and runway.agents.all(func(a):return a.outfit.skirt_fabric.get("repeats",0)==8))
	await press(studio.buttons["WEAR SAVED"])
	check(tag+"Void visitor wardrobe wears saved fabric",studio.wardrobe()!=null and studio.wardrobe().skirt_fabric.get("repeats",0)==8)
	check(tag+"runway sees actual visitor",runway.viewer==game.camera)
	var mirror: Node3D=artifact("super_drag_mirror")
	await approach(mirror,1.6)
	await press(mirror.buttons[0])
	check(tag+"mirror resolves the same player wardrobe",mirror._wardrobe==studio.wardrobe())
	var table: Node3D=artifact("garment_cutting_table")
	await approach(table,2)
	await press(table.buttons["CUT"])
	check(tag+"CUT starts original ten-panel operation",table.phase=="cutting")
	table.advance(20.0) # Labelled API time advance, not a simulated user action.
	check(tag+"API elapsed time completes ten cuts",table.phase=="cut" and table.completed==10)
	await press(table.buttons["ASSEMBLE"])
	check(tag+"ASSEMBLE starts original fitting",table.phase=="assembling")
	table.advance(20.0)
	await press(table.buttons["WEAR"])
	check(tag+"original fitted garment reaches wardrobe",table.phase=="ready" and table.worn_wardrobe!=null and table.wardrobe().costume.outfit_id=="tailored_suit")
	await press(table.buttons["TAKE OFF"])
	check(tag+"TAKE OFF restores previous outfit",table.worn_wardrobe==null)
	var trail:Node3D=artifact("colortrails")
	game.place_player(game.spawn_for(level));await frames(10)
	if xr:right.set_input("trigger_click",true)
	else:await mouse_button(MOUSE_BUTTON_LEFT,true)
	for i in 25:
		if xr:hand_at(right,game.camera.global_position+Vector3(-.5+i*.04,-.2,-.7))
		else:game.camera.rotation.y+=.012
		await frames(1)
	check(tag+"actual input draws original hand ribbon",trail._right_points.size()>3 and trail._right_mesh.get_surface_count()>0)
	check(tag+"world ribbon is independent of mount transform",trail._right_mesh_inst.global_transform.is_equal_approx(Transform3D.IDENTITY))
	if xr:right.set_input("trigger_click",false)
	else:await mouse_button(MOUSE_BUTTON_LEFT,false)
	game.place_player(game.spawn_for(level));await frames(15)

func expected_empty_source(_node: Node3D) -> bool:
	return false

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	await photo("01-patterns-on-bodies",Vector3(18,y+4,13),Vector3(0,y+1,1))
	var studio: Node3D=artifact("fabric_shader_studio")
	await photo("02-fabric-studio",studio.to_global(Vector3(4,2.7,4)),studio.to_global(Vector3(0,1.2,0)))
