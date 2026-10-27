extends "res://tools/probes/array_trial_probe.gd"
## Native input, shared data and real support, exercised with both player rigs.

func mouse(button: int, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=button;event.pressed=down
	Input.parse_input_event(event)
	await frames(15)

func visit(use_xr: bool, museum_score: int) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	var content: Node3D=game.building.content
	var row: Node3D=content.exhibits["1/row"].get_node("Artifact")
	var grid: Node3D=content.exhibits["1/grid"].get_node("Artifact")
	var work: Node3D=content.exhibits["1/worksite"].get_node("Artifact")
	var original_row: Node3D=load("res://algorithms/arrays/row_3_x.gd").new()
	var original_grid: Node3D=load("res://algorithms/arrays/grid_2d_4x4.gd").new()
	root.add_child(original_row);root.add_child(original_grid);await frames(2)
	check(tag+"unconfigured museum scenes retain their original four and sixteen cubes",original_row._cube_refs.size()==4 and original_row._binary_table.cols==4 and original_grid._cube_refs.size()==16)
	original_row.queue_free();original_grid.queue_free();await frames(2)
	check(tag+"four editable encounters; fixed tower and both shafts retained",content.data.floors[1].artifacts.size()==4 and game.building.spec.shafts.size()==2)
	check(tag+"row has 32 cubes and 32 binary-table cells",row._cube_refs.size()==32 and row._binary_table.cols==32)
	var row_record: Dictionary=content.data.floors[1].artifacts.filter(func(a):return a.id=="row")[0]
	var spacing: float=row_record.config.spacing
	check(tag+"long row follows its editable spacing",spacing>=1 and is_equal_approx(row._cube_refs[31].position.x-row._cube_refs[0].position.x,31*spacing))
	await photo("01-long-row",Vector3(-19,-3.6,-2.2),Vector3(7,-5,-5))
	var last: Node3D=row._cube_refs[31]
	game.place_player(row.to_global(Vector3(30*spacing,.06,0)));await frames(30)
	check(tag+"collecting index 30 leaves index 31 in place",not row._cube_refs.has(30) and row.array_data[0][30]==0 and row._binary_table.data[0][30]==0 and row._cube_refs[31]==last)
	check(tag+"walking array has 49 independently addressed cubes",grid._cube_refs.size()==49 and grid.cols==7 and grid.rows==7 and grid._binary_table.rows==7 and grid._binary_table.cols==7)
	game.place_player(grid.to_global(Vector3(1,.06,2)));await frames(30)
	check(tag+"grid [1,2] changes without transposing [2,1]",not grid._cube_refs.has("1_2") and grid.grid_data[1][2]==0 and grid._binary_table.data[1][2]==0 and grid.grid_data[2][1]==1)
	check(tag+"collection score stays in this trial",game.trial_session.score==2 and root.get_node("GameManager").player_score==museum_score)
	if absf(grid._binary_table.rotation_degrees.y)>90:
		await photo("02-seven-by-seven",grid.to_global(Vector3(6.25,3.5,-2)),grid.to_global(Vector3(3,1,4)))
	else:
		await photo("02-seven-by-seven",grid.to_global(Vector3(6.25,3.5,8.8)),grid.to_global(Vector3(3,1,2.4)))
	check(tag+"shaft grid is a batched 49-cell mesh with 49 physical supports",work.large_mesh.multimesh.instance_count==49 and work.colliders.size()==49)
	var mapping_ok:=true
	for x in 7:
		for z in 7:
			var cell:=Vector2i(x,z)
			mapping_ok=mapping_ok and work.index_at(work.cell_position(cell,work.SMALL,Vector3.ZERO))==cell
	check(tag+"all 49 miniature positions map to the correct address",mapping_ok)
	var holes_clear:=true
	for x in 7:
		for z in 7:
			var cell:=Vector2i(x,z)
			work.set_cell(cell,0);await frames(2)
			var centre: Vector3=work.to_global(work.cell_position(cell,work.LARGE,work.TARGET))
			var ray:=PhysicsRayQueryParameters3D.create(centre+Vector3.UP*.4,centre-Vector3.UP*.4,1)
			holes_clear=holes_clear and work.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
			work.set_cell(cell,1)
	check(tag+"all 49 removed supports open a real hole without overlapping landing pads",holes_clear)
	check(tag+"out-of-bounds hand positions clamp to the grid",work.index_at(Vector3(-10,100,10))==Vector2i(0,6))
	# Use the real shared grab implementation, not a test-only selector callback.
	game.place_player(work.to_global(Vector3(0,.06,1.25)));await frames(20)
	if xr:
		hand_at(right,work.point.global_position);await frames(20)
		right.set_input("grip",1.0);await frames(20)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(work.point.global_position);await frames(20)
		await mouse(MOUSE_BUTTON_RIGHT,true)
		await mouse(MOUSE_BUTTON_RIGHT,false)
	check(tag+"real grip picks up the miniature selector",work.point.is_picked_up())
	var target: Vector3=work.to_global(work.cell_position(Vector2i(5,1),work.SMALL,work.BOARD)+Vector3.UP*.1)
	if xr: hand_at(right,target)
	else:
		game.camera.look_at(target)
		# The shared desktop hand uses the wheel to extend its reach.
		await mouse(MOUSE_BUTTON_WHEEL_DOWN,true)
		await mouse(MOUSE_BUTTON_WHEEL_DOWN,false)
	await frames(35)
	print(tag," selected ",work.selected," point ",work.to_local(work.point.global_position))
	check(tag+"moving the held point selects [5,1]",work.selected==Vector2i(5,1))
	check(tag+"large cursor reads the same index",work.large_cursor.position.is_equal_approx(work.cell_position(work.selected,work.LARGE,work.TARGET)+Vector3.UP*.09))
	var selected: Vector2i=work.selected
	if xr:right.set_input("trigger_click",true);await frames(6);right.set_input("trigger_click",false)
	else:await mouse(MOUSE_BUTTON_LEFT,true);await mouse(MOUSE_BUTTON_LEFT,false)
	await frames(15)
	check(tag+"held trigger removes selected tile and its collider",work.values[selected.x][selected.y]==0 and work.colliders[selected].disabled)
	check(tag+"other tiles retain their values",work.values[0][0]==1 and work.values[6][6]==1)
	if xr:right.set_input("grip",0.0)
	else:
		await mouse(MOUSE_BUTTON_RIGHT,true)
		await mouse(MOUSE_BUTTON_RIGHT,false)
	await frames(20)
	check(tag+"release parks the point at the chosen cell",not work.point.is_picked_up() and work.point.position.is_equal_approx(work.cell_position(selected,work.SMALL,work.BOARD)+Vector3.UP*.1))
	await photo("03-hand-and-shaft",Vector3(12,-3.3,6.2),Vector3(10,-5.5,1.7))
	game.place_player(work.to_global(Vector3(1.65,.06,1.5)));await frames(20)
	await press(work.add_button)
	check(tag+"pointer ADD restores selected value and support",work.values[selected.x][selected.y]==1 and not work.colliders[selected].disabled)
	await press(work.remove_button)
	check(tag+"pointer REMOVE clears the same address",work.values[selected.x][selected.y]==0 and work.colliders[selected].disabled)
	await press(work.restore_button)
	check(tag+"pointer RESTORE restores all 49 cells",work.values.all(func(r):return r.all(func(v):return v==1)) and work.pending.is_empty())
	# Restore must never materialise a tile inside a body.
	work.select_cell(Vector2i(3,3));work.write_selected(0);await frames(5)
	var blocker:=CharacterBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=CapsuleShape3D.new();shape.radius=.2;shape.height=1.0
	collision.shape=shape;blocker.add_child(collision)
	root.add_child(blocker)
	blocker.global_position=work.to_global(work.TARGET)
	await frames(5);work.restore_all();await frames(20)
	check(tag+"restore queues an address occupied by a body",work.pending.has(Vector2i(3,3)) and work.values[3][3]==0)
	blocker.queue_free();await frames(30)
	check(tag+"queued support returns after the body clears",work.pending.is_empty() and work.values[3][3]==1 and not work.colliders[Vector2i(3,3)].disabled)
	# Real player stands on the support, then falls into the actual shaft.
	game.place_player(work.to_global(work.TARGET+Vector3.UP*.2));await frames(30)
	var supported_y: float=game.body.global_position.y
	check(tag+"native player can stand on the selected shaft tile",game.body.is_on_floor() and absf(supported_y+6.1)<.15)
	work.select_cell(Vector2i(3,3));work.write_selected(0);await frames(25)
	check(tag+"clearing the tile makes the player fall into the shaft",game.body.global_position.y<supported_y-.5)
	game.place_player(work.to_global(Vector3(0,.06,1.25)));work.restore_all();await frames(20)
	# The shared index mapping remains local when the entire editable assembly turns.
	var original:=work.transform
	work.rotation_degrees.y+=90
	var world: Vector3=work.to_global(work.cell_position(Vector2i(1,6),work.SMALL,work.BOARD))
	check(tag+"rotating the editable assembly preserves local index mapping",work.index_at(work.to_local(world)-work.BOARD)==Vector2i(1,6))
	work.transform=original
	await photo("04-controls",Vector3(10.8,-4.4,6.4),Vector3(10.5,-4.85,4.1))
	game.die("Retry array");await frames(120)
	check(tag+"retry restores 32 and 49 cubes and full shaft support",not game.recovering and game.trial_session.score==0 and content.exhibits["1/row"].get_node("Artifact")._cube_refs.size()==32 and content.exhibits["1/grid"].get_node("Artifact")._cube_refs.size()==49 and content.exhibits["1/worksite"].get_node("Artifact").values[3][3]==1)
	check(tag+"museum progress remains unchanged",root.get_node("GameManager").player_score==museum_score)
	game.queue_free();await frames(6)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
