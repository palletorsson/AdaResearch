extends "res://tools/probes/ca_spine_active.gd"
## Focused extension acceptance; prior eight-floor receipts remain untouched.
var bounds_rows: Array = []
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--mode="):mode = arg.trim_prefix("--mode=")
	xr = mode=="xr";take_photos = not xr
	await start(xr)
	for floor in [104,107]:
		level = floor;game.place_player(game.spawn_for(level));await frames(100)
		var tag := ("XR " if xr else "Desktop ")+str(level)+": "
		check(tag+"safe actual main-floor arrival",game.body.is_on_floor() and game.floor_stream.focus==level)
		if floor==104:await slice_checks(tag)
		else:await canopy_checks(tag)
		var y: float = game.building.spec.levels[level]
		for entry in game.building.content.data.floors[level].artifacts:
			var boxes: Array = [];geometry(station(entry.id),boxes)
			check(tag+entry.id+" real visible geometry",not boxes.is_empty())
			if boxes.is_empty():continue
			var b: AABB = boxes[0]
			for box: AABB in boxes:b = b.merge(box)
			check(tag+entry.id+" stays inside main floor XZ and ceiling",b.position.x>=-21.05 and b.end.x<=21.05 and b.position.z>=-9.05 and b.end.z<=9.05 and b.end.y-y<=5.65)
			bounds_rows.append({"floor":level,"id":entry.id,"min":[b.position.x,b.position.y-y,b.position.z],"max":[b.end.x,b.end.y-y,b.end.z]})
		for shaft in game.building.spec.shafts:
			check(tag+"shaft centre remains open "+str(shaft.name),ray(Vector3(shaft.x,y+1,0),Vector3(shaft.x,y-.5,0)).is_empty())
		check(tag+"visitor camera retained",game.get_viewport().get_camera_3d()==game.camera)
	FileAccess.open(out.path_join("native-%s.json"%mode),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"bounds":bounds_rows,"mode":mode,"scope":"Two new source-linked architectural receivers; original CA state, real controls, fit and placement. Synthetic XR is not physical headset acceptance."},"  "))
	print("CA_BASELINE_RESULT ",checks.size()," checks; failures ",failed);quit(0 if failed.is_empty() else 1)
func slice_checks(tag: String) -> void:
	var work: Node3D = artifact("structure_growth");var study: Node3D = work.get_node("StructureStudy")
	var slices: Array = []
	for i in 3:slices.append(station("ca-neighbour-slice-%d"%i))
	study.replay();await frames(8)
	check_slices(tag+"seed: ",work,slices)
	await states_checks(tag) # actual STEP twice, native pickup and point trigger
	await frames(8);check_slices(tag+"after real input: ",work,slices)
	await control_press(work,study.get_node("Console/StudyControls"),3);await frames(8)
	check_slices(tag+"height view: ",work,slices)
	var address := Vector3i(26,22,24);var expected: Color = study.neighbour_room.colour_for(1,address)
	check(tag+"VIEW also changes architectural colour mapping",slices[1].cells.get_instance_color(4).is_equal_approx(expected))
	await control_press(work,study.get_node("Console/StudyControls"),3)
	await control_press(work,study.get_node("Console/StudyControls"),2);await frames(8)
	check(tag+"REPLAY clears stale receiver state",work.generation==0 and slices[1].rendered[4]==1)
	await control_press(work,study.get_node("Console/StudyControls"),0);await frames(8)
	if not xr:
		await photo("ca-104-three-slices",Vector3(0,-624+2.5,8.5),Vector3(0,-624+2.7,-4))
		await photo("ca-104-witness",Vector3(-3,-624+2.6,-.4),Vector3(0,-624+2.7,-5.65))
	var middle: Node3D = slices[1];var pose: Transform3D = middle.transform
	middle.position.x += .25;middle.rotation.y = .15;await frames(8)
	check(tag+"moved/rotated receiver still resolves original state",middle.source==work and middle.rendered[4]==2)
	var solid_at: Vector3 = middle.to_global(Vector3(0,2.72,-.2))
	var hit: Dictionary = ray(solid_at+middle.global_basis.z,solid_at-middle.global_basis.z)
	check(tag+"solid frame follows receiver movement and rotation",not hit.is_empty() and middle.is_ancestor_of(hit.collider))
	middle.transform = pose
	if not xr:
		game.place_player(Vector3(-3.7,-624+.06,-4.5));await frames(15)
		var a: bool = await move_to(Vector3(-3.7,-624+.06,-7.0),false,240)
		var b: bool = await move_to(Vector3(3.7,-624+.06,-7.0),false,300)
		var c: bool = await move_to(Vector3(3.7,-624+.06,-4.5),false,240)
		check(tag+"actual left rear and right walk-around stays clear",a and b and c)
func check_slices(tag: String, work: Node3D, slices: Array) -> void:
	var all_match := true
	for slice: Node3D in slices:
		for y in range(-1,2):
			for x in range(-1,2):
				var p := Vector3i(26+x,22+y,24+slice.depth)
				var state: int = work.current_state[p.x+p.y*work.stride_y+p.z*work.stride_z]
				if slice.rendered[(y+1)*3+x+1]!=state:all_match = false
	check(tag+"all27 addresses exactly equal original 50-cubed state",all_match)
func canopy_checks(tag: String) -> void:
	var work: Node3D = artifact("decaying_bridge");var study: Node3D = work.get_node("ProximityStudy")
	var canopy: Node3D = station("ca-health-canopy")
	study.source_mode = 1;study.probe_near = true;study.full_reset();await frames(8)
	check(tag+"canopy holds80 original health addresses",canopy.angles.size()==80 and canopy.rendered==work.grid)
	check(tag+"healthy leaves initially close",is_zero_approx(canopy.angles[Vector2i(2,6)]))
	check(tag+"moving geometry uses3 instanced batches",canopy.leaves.instance_count==80 and canopy.rims.instance_count==160 and canopy.axles.instance_count==80)
	if not xr:await photo("ca-107-closed",Vector3(4,-642+2.4,7.2),Vector3(0,-642+3.0,0))
	await control_press(work,study.console,0);await frames(8)
	var h: float = work.grid[Vector2i(2,6)]
	check(tag+"real STEP drives the overhead aperture from original health",study.ticks==1 and h<1 and is_equal_approx(canopy.angles[Vector2i(2,6)],deg_to_rad(80*(1-h))))
	for i in 22:study.step_once()
	await frames(8)
	var matches := true
	for coord: Vector2i in work.grid:
		if not is_equal_approx(canopy.rendered[coord],work.grid[coord]):matches = false
	check(tag+"all80 louvers match bridge health without a second solver",matches)
	check(tag+"depleted witness opens past60degrees",rad_to_deg(canopy.angles[Vector2i(2,6)])>60)
	var site: Vector3 = work.to_global(Vector3(0,0,3.6))
	game.place_player(site+Vector3.UP*.06);await frames(40)
	check(tag+"original support withdrawal still drops visitor into basin",game.body.global_position.y<game.building.spec.levels[level]-.4 and game.body.is_on_floor())
	if not xr:
		await photo("ca-107-open",Vector3(4,-642+2.4,7.2),Vector3(0,-642+3.0,0))
	var pose: Transform3D = canopy.transform;canopy.position.z+=.25;canopy.rotation.y+=.2;await frames(8)
	check(tag+"moved and rotated canopy retains original state association",canopy.source==work and canopy.rendered==work.grid)
	canopy.transform = pose
	var drained: Dictionary = work.grid.duplicate()
	study.probe_near = false
	for i in 12:study.step_once()
	await frames(8)
	var recovered := false
	for coord: Vector2i in work.grid:
		if work.grid[coord]>drained[coord]:recovered = true
	check(tag+"neighbour recovery is reflected without forcing the depleted centre to heal",canopy.rendered==work.grid and recovered)
	await control_press(work,study.console,2);await frames(8)
	check(tag+"actual RESTORE closes source and ceiling together",study.ticks==0 and canopy.rendered==work.grid and is_zero_approx(canopy.angles[Vector2i(2,6)]))
func photo(filename: String, at: Vector3, target: Vector3) -> void:
	var visible_charge: bool = game.charge_display.visible;game.charge_display.hide()
	await super.photo(filename,at,target);game.charge_display.visible = visible_charge
