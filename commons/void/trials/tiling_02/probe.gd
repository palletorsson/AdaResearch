extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	check(tag+"standard 42 x 32 x 6 tower",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	for i in 20: await frames(1)
	if level==1: await foundry_checks(tag)
	else: await tutorial_checks(tag)

func mouse_button(button: int, down: bool) -> void:
	var e:=InputEventMouseButton.new();e.button_index=button;e.pressed=down
	Input.parse_input_event(e)
	for i in 10: await frames(1)

func palm_at(world: Vector3) -> void:
	# The museum hand's grip point is offset from its aim tracker. Centre the
	# palm on a 4 cm cube, rather than inadvertently choosing its neighbour.
	var aim: Vector3=world
	for i in 20:
		hand_at(right,aim);await frames(1)
		aim+=world-game.pickups[1].global_position

func puzzle_checks(tag: String, key: String) -> void:
	var puzzle: Node3D=artifact(key)
	var cubes: Array=puzzle.get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path=="res://commons/primitives/arrays/pattern_tile_cube.gd" and n.color_index==1)
	check(tag+"palette has original pickable colour cubes",not cubes.is_empty())
	if cubes.is_empty():return
	var cube: RigidBody3D=cubes[0]
	await approach(puzzle,1.5)
	if xr:
		await palm_at(cube.global_position)
		right.set_input("grip",1.0)
		for i in 15: await frames(1)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(cube.global_position)
		for i in 15: await frames(1)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"actual grip picks up a source tile cube",cube.is_picked_up() if xr else game.body.desktop_pointer._held==cube)
	var target: Vector3=puzzle._editor_container.to_global(puzzle._cell_snap_positions[0][0])
	if xr:
		await palm_at(target)
		for i in 15: await frames(1)
		right.set_input("grip",0.0)
	else:
		game.body.desktop_pointer._hold_distance=game.camera.global_position.distance_to(target)
		game.camera.look_at(target)
		for i in 35: await frames(1)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	for i in 15:await frames(1)
	check(tag+"drop snaps cube and updates source tile",cube.is_placed and cube.grid_position==Vector2i.ZERO and puzzle._grid_data[0][0]==1)
	check(tag+"replacement palette cube keeps carry adapter",puzzle.get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path=="res://commons/primitives/arrays/pattern_tile_cube.gd" and n.color_index==1 and n!=cube and n.has_node("VoidTileCarry")).size()>0)

func panel_button(owner_node: Node, title: String, label: String) -> Node3D:
	for p in owner_node.get_children():
		if "title" in p and p.title==title:
			for item in p._items:
				if item.label==label:return item.node
	return null

func foundry_checks(tag: String) -> void:
	for pair in [["pattern_tile_4x4",0],["pattern_tile_mirror",3],["pattern_tile_brick",6],["pattern_tile_herringbone",8]]:
		check(tag+pair[0]+" registry mode retained",artifact(pair[0]).repeat_mode==pair[1])
	await puzzle_checks(tag,"pattern_tile_4x4")
	var loom: Node3D=artifact("pattern_machine_a")
	var study: Node3D=loom.get_node("RecipeStudy")
	await approach(study.get_node("RecipeControls"),1.5)
	var updates: int=study.updates
	await press(study.buttons[0])
	check(tag+"loom MARK updates five source receivers",study.updates>updates and study.receivers.size()==5)
	await press(study.buttons[3])
	check(tag+"HOLD disconnects curved sample",not study.receivers.CURVE.linked)
	await press(study.buttons[5])
	check(tag+"UNDO LINK reconnects curved sample",study.receivers.CURVE.linked)
	var repeat_before: float=loom.repeat_metres
	await press(study.buttons[6])
	check(tag+"repeat-size button updates original recipe",not is_equal_approx(loom.repeat_metres,repeat_before))
	var architecture: Node3D=artifact("pattern_architecture")
	check(tag+"architecture binds four original machines",architecture.sources.size()==4 and architecture.source_texture()!=null)
	check(tag+"architecture skins mounted on fixed structure",architecture.skins.size()==2 and architecture.receiver_root.get_parent()==game.building.floors[level])
	var source_button:=panel_button(architecture,"DRESS THE ARCHITECTURE","SOURCE")
	await approach(source_button.get_parent().get_parent().get_parent(),1.8)
	await press(source_button)
	check(tag+"SOURCE changes live architecture texture",architecture.source_index==1 and architecture.skins[1].material_override.albedo_texture==architecture.source_texture())
	await press(panel_button(architecture,"DRESS THE ARCHITECTURE","TARGET"))
	check(tag+"TARGET paints floor without closing shafts",architecture.target==2 and architecture.skins[0].material_override.albedo_texture==architecture.source_texture())
	await press(panel_button(architecture,"DRESS THE ARCHITECTURE","LIVE / HOLD"))
	check(tag+"HOLD snapshots architecture",architecture.held and architecture.skins[0].material_override.albedo_texture!=architecture.source_texture())
	var fixed: Transform3D=architecture.receiver_root.global_transform
	var mount: Node3D=architecture.get_parent();mount.position.x+=.25
	check(tag+"moving editor console keeps receivers fixed",architecture.receiver_root.global_transform==fixed)
	mount.position.x-=.25
	var catwalk: Node3D=artifact("drag_catwalk")
	check(tag+"four original runway performers",catwalk.agents.size()==4)
	await approach(catwalk.get_node("ShowControls"),1.5)
	await press(catwalk.buttons[0]);check(tag+"catwalk HOLD button",not catwalk.running)
	await press(catwalk.buttons[0]);check(tag+"catwalk resumes",catwalk.running)
	var wall: Node3D=artifact("wall_drawing_291")
	await approach(wall,1.7)
	await press(wall.square_press_area(0).get_parent())
	check(tag+"wall draws first of forty squares by pointer",wall.square_count()==40 and wall.drawn_count()==1)
	await press(wall.square_press_area(0).get_parent())
	check(tag+"same square cycles direction without extra count",wall.square_state(0)==2 and wall.drawn_count()==1)
	game.place_player(game.spawn_for(1));await frames(15)

func tutorial_checks(tag: String) -> void:
	check(tag+"tutorial mirror keeps registry variant",artifact("pattern_tile_mirror").repeat_mode==3)
	await puzzle_checks(tag,"pattern_tile_puzzle")
	var maker: Node3D=artifact("pattern_maker_station")
	var lesson: Node3D=maker.fixed_motif_lesson
	check(tag+"original fixed motif comparison loaded",lesson!=null and lesson.panels.size()==2)
	if lesson!=null:
		await approach(lesson,1.8)
		var seed: Array=maker._grid_data.duplicate(true)
		await press(lesson.buttons.PM)
		check(tag+"PM changes rule while source stays fixed",maker._group_index==2 and maker._grid_data==seed)
		await press(lesson.buttons["FLIP X"])
		check(tag+"FLIP X changes shared source",maker._grid_data!=seed)
		await press(lesson.buttons.UNDO)
		check(tag+"UNDO restores source but keeps rule",maker._grid_data==seed and maker._group_index==2)
	var loom: Node3D=artifact("panel_bridge_loom")
	check(tag+"original overshot example has eight shafts and populated draft",loom.current_example==1 and loom.panel_bridge.data_store.shafts==8 and loom.panel_bridge.panel_instances.size()==3 and loom.panel_bridge.data_store._threading.count(1)>0)
	check(tag+"standalone loom overlay and retry shortcut disabled",not loom.has_node("InfoOverlay") and not loom.is_processing_unhandled_input())
	var model: Node3D=artifact("grid_model")
	check(tag+"miniature represents this floor only",model._initialized and model._map_width==42 and model._map_depth==32 and not model._grid_system.is_in_group("grid_system"))
	var grid: Node=model._structure_component
	check(tag+"grid API protects slab and shaft",not grid.stack_remove(21,16) and not grid.stack_add(10,16))
	check(tag+"grid API adds one metre support",grid.stack_add(20,9))
	await frames(12)
	check(tag+"added support appears under same floor",model._layout_mirror[9][20]==2 and grid.batch.items.size()==1 and model.receiver.get_parent().get_meta("void_content_floor")==level)
	check(tag+"grid API removes added support",grid.stack_remove(20,9))
	await frames(12)
	check(tag+"miniature follows removal",model._layout_mirror[9][20]==1 and grid.batch.items.is_empty())
	await model_grab_check(tag,model)
	game.place_player(game.spawn_for(2));await frames(15)

func model_grab_check(tag: String, model: Node3D) -> void:
	var cube: RigidBody3D=model._spawner_cubes[0]
	await approach(model,1.5)
	if xr:
		await palm_at(cube.global_position);right.set_input("grip",1.0)
		for i in 15: await frames(1)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(cube.global_position)
		for i in 15:await frames(1)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	check(tag+"original miniature spawner is grabbable",cube.is_picked_up())
	var target: Vector3=model._model_container.to_global(Vector3(20.5,1.5,9.5)*model._cell_size)
	if xr:
		await palm_at(target)
		for i in 15:await frames(1)
		right.set_input("grip",0.0)
	else:
		game.body.desktop_pointer._hold_distance=game.camera.global_position.distance_to(target)
		game.camera.look_at(target)
		for i in 35:await frames(1)
		await mouse_button(MOUSE_BUTTON_RIGHT,true);await mouse_button(MOUSE_BUTTON_RIGHT,false)
	for i in 50:await frames(1)
	check(tag+"miniature drop builds actual one metre support",model._structure_component.get_height_at(20,9)==2 and model._structure_component.batch.items.size()==1)
	model._structure_component.stack_remove(20,9);await frames(12)

func capture_floor() -> void:
	if level==1:
		var a:Node3D=artifact("pattern_machine_a")
		await photo("01-foundry-loom",a.to_global(Vector3(-4,3.9,-4)),a.to_global(Vector3(-1,1,2)))
		var c:Node3D=artifact("pattern_machine_c")
		await photo("02-foundry-machines",c.to_global(Vector3(8,4,-4)),c.to_global(Vector3(0,.8,3)))
	else:
		var maker:Node3D=artifact("pattern_maker_station")
		await photo("03-tutorial-motif",maker.to_global(Vector3(3,2.7,-5)),maker.to_global(Vector3(0,1,0)))
		var loom:Node3D=artifact("panel_bridge_loom")
		await photo("04-tutorial-loom",loom.to_global(Vector3(3,2.8,4)),loom.to_global(Vector3(0,1,-1)))
