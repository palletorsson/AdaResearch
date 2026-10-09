extends "res://tools/probes/transformation_encounters.gd"
const Journey = preload("res://tools/probes/array_entered_address.gd")
var rooms: Node3D
var actor: CharacterBody3D
var driver: Journey.KeyJourney
var completed := false
var paths: Array = []
func walk(local: Vector3) -> bool:
	driver.target = rooms.to_global(local); driver.arrived = false; driver.moving = true
	var start := Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<9000: await physics_frame
	driver.moving = false; driver.release()
	paths.append({"target":xyz(local),"reached":xyz(rooms.to_local(actor.global_position)),"arrived":driver.arrived})
	return driver.arrived
func ray(a: Vector3,b: Vector3) -> Dictionary:
	return rooms.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(rooms.to_global(a),rooms.to_global(b),1))
func landing_checks() -> void:
	root.size = Vector2i(1440,960)
	var grid := hall.get_node_or_null("SimGrid_Color_Flashlight")
	for frame in 3600:
		if grid and grid.has_meta("stage_grid_ready"): break
		await process_frame
	rooms = find_scene("/colour_light_rooms.gd")
	var original := find_scene("/flashlight_demo.gd")
	check("both the existing lamp exhibit and new rooms are in the museum",rooms != null and original != null)
	if rooms == null: return
	rooms.running = false
	check("seven-sided original receiver remains",original.receiver_sides == 7)
	check("source and six concealed washes exist",rooms.central_light != null and rooms.ring_lights.size() == 6)
	var white: Color = rooms.white_material.albedo_color
	var shape: Transform3D = rooms.get_node("WhiteWall").global_transform
	check("central chamber ceiling is solid",not ray(Vector3(1,1,1),Vector3(1,7,1)).is_empty())
	check("all three central ceiling openings are genuinely open",ray(Vector3(10.2,2,0),Vector3(10.2,10,0)).is_empty())
	check("side opening admits the body route",ray(Vector3(-7,1,0),Vector3(-2,1,0)).is_empty())
	check("central wall stops a lateral approach",not ray(Vector3(0,1,0),Vector3(0,1,5)).is_empty())
	var k := Vector2i(int(floor(rooms.global_position.x+1)),int(floor(rooms.global_position.z+1)))
	check("room footprint leaves central walking cells open",not rooms.get_museum_occupied_cells().has(k))
	var walk_cells: Dictionary = museum.get("_walk_cells")
	check("museum walk map includes the new annex interior",walk_cells.has(k))
	var partitions: Array = museum.call("_occupied_cells",rooms,{"x":25,"y":10},0)
	check("museum uses partitions without sealing the room interior",not partitions.is_empty() and not partitions.has(k))
	var wall_cell := Vector2i(int(floor(rooms.global_position.x)),int(floor(rooms.global_position.z+4.4)))
	check("museum partition footprint includes the solid room wall",partitions.has(wall_cell))
	rooms.set_phase(0.24)
	await snapshot("white-room-rose",rooms.to_global(Vector3(-3.2,1.65,2.6)),rooms.to_global(Vector3(0.7,2.0,-1.3)),73)
	var a: Image = root.get_texture().get_image()
	rooms.set_phase(0.64)
	await snapshot("white-room-blue",rooms.to_global(Vector3(-3.2,1.65,2.6)),rooms.to_global(Vector3(0.7,2.0,-1.3)),73)
	var b: Image = root.get_texture().get_image()
	check("changing only light changes the actual rendered room",a.get_data()!=b.get_data())
	check("white material and room geometry stay fixed",rooms.white_material.albedo_color==white and rooms.get_node("WhiteWall").global_transform.is_equal_approx(shape))
	rooms.central_light.visible = false
	await snapshot("white-room-source-off",rooms.to_global(Vector3(-3.2,1.65,2.6)),rooms.to_global(Vector3(0.7,2.0,-1.3)),73)
	var dark: Image = root.get_texture().get_image()
	check("removing the central light changes the receiving walls",dark.get_data()!=b.get_data())
	rooms.central_light.visible = true
	rooms.set_phase(0.10)
	await snapshot("apertures-from-floor",rooms.to_global(Vector3(10.2,1.65,4.0)),rooms.to_global(Vector3(10.2,6.0,-0.5)),86)
	await snapshot("aperture-room",rooms.to_global(Vector3(7,1.65,4.6)),rooms.to_global(Vector3(11,3,-3)),84)
	# Use the actual museum controller, through the first room and up the ramp.
	actor = museum.get("_player"); museum.set("_dollhouse",false)
	actor.global_position = rooms.to_global(Vector3(-10,0.08,0)); actor.velocity = Vector3.ZERO
	driver = Journey.KeyJourney.new(); driver.world = museum; driver.actor = actor; driver.view = museum.get("_cam"); root.add_child(driver)
	for target in [Vector3(-6.5,0.08,0),Vector3(-2,0.08,0),Vector3(2,0.08,0),Vector3(6.5,0.08,0),Vector3(11,0.08,4.9),Vector3(13.7,0.08,4.9),Vector3(13.7,1.25,-4.4),Vector3(13.7,1.25,-5.7),Vector3(10.5,1.25,-5.7)]:
		check("ordinary walker reaches "+str(target),await walk(target))
	check("ramp lifts the body to the upper landing",rooms.to_local(actor.global_position).y>1.1 and rooms.to_local(actor.global_position).y<1.4)
	await snapshot("apertures-from-landing",actor.global_position+Vector3.UP*1.65,rooms.to_global(Vector3(10.2,6.3,0.5)),90)
	for target in [Vector3(13.7,1.25,-5.7),Vector3(13.7,1.25,-4.4),Vector3(13.7,0.08,4.9),Vector3(10.2,0.08,4.9),Vector3(6.5,0.08,0),Vector3(2,0.08,0),Vector3(-6.5,0.08,0)]:
		check("ordinary walker returns via "+str(target),await walk(target))
	var phase: float = rooms.elapsed; rooms.running = true
	await create_timer(0.3).timeout
	check("light changes continue without a panel",rooms.elapsed>phase)
	observations["walks"] = paths;observations["white_albedo"] = [white.r,white.g,white.b];observations["room_position"] = xyz(rooms.global_position)
	completed = true
func finish() -> void:
	if driver: driver.release();driver.set_physics_process(false)
	check("room study completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum; real renderer and ordinary controller, no headset or photometric claim."},"  "))
	print("LIGHT ROOMS ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
