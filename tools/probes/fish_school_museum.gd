extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream= museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var school:=find_scene("/fish_school.gd")
	var original:=find_scene("/boid_manager.gd")
	var tank:=find_scene("/boids_aquarium.gd")
	check("New fish encounter loads in the real Boids hall",school!=null)
	check("Original flock and aquarium retained",original!=null and tank!=null and original.get_boids().size()==100)
	check("Original balcony retained",hall.get_node_or_null("ObservationBalcony")!=null)
	if school==null:return
	check("72 full-size fish and PointBody load",school.boids.size()==72 and school.point!=null)
	var home:Vector3=school.point.global_position
	var foot:=school.to_global(Vector3(0,0,1))
	var floor:=floor_at(foot)
	check("Visitor can stand beside sphere on balcony",not floor.is_empty())
	if not floor.is_empty():
		check("Sphere is at hand height",home.y-floor.position.y>.95 and home.y-floor.position.y<1.45)
	observations.sphere_home=xyz(home)
	observations.school_centre=xyz(school.boundary.global_position)
	observations.controls="VR grip; hold trigger to scatter. Desktop right click to carry/drop, left click to scatter."
	check("Only the small stand seals walk cells",school.get_museum_occupied_cells().size()<=4)
	var path_clear:=true
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	for i in range(32):
		var at:=school.to_global(Vector3(9.0-float(i)*.25,.87,0.7))
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=at
		if not hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty():path_clear=false
	check("Standing capsule has a clear approach from hall to sphere",path_clear)
	await snapshot("balcony-school",school.to_global(Vector3(3.5,1.7,.7)),school.to_global(Vector3(-3,1.6,0)),78)
	await snapshot("school-above",school.to_global(Vector3(-8,24,6)),school.to_global(Vector3(3,0,0)),64)
	var pointer:=Node3D.new();root.add_child(pointer)
	school.point.on_desktop_grab(pointer)
	school.point.global_position=school.to_global(Vector3(-.6,1.4,.5))
	await create_timer(10).timeout
	var gathered:=mean_distance(school)
	check("Held point activates gather in the actual hall",school.point.held() and not school.scatter)
	check("Gather readout and range are visible",school.status.text.begins_with("GATHER") and school.range_rings[0].visible)
	await snapshot("gather",school.to_global(Vector3(3.5,1.7,.7)),school.to_global(Vector3(-3,1.6,0)),78)
	school.point.action()
	await create_timer(3).timeout
	var scattered:=mean_distance(school)
	check("Actual action signal scatters fish",school.scatter and school.status.text.begins_with("SCATTER"))
	check("School spreads away from held sphere",scattered>gathered+.15)
	observations.mean_distance_gather=gathered;observations.mean_distance_scatter=scattered
	await snapshot("scatter",school.to_global(Vector3(3.5,1.7,.7)),school.to_global(Vector3(-3,1.6,0)),78)
	school.point.action_release();school.point.on_desktop_drop(pointer)
	await create_timer(2).timeout
	check("Released point returns to stand and stops influencing",school.point.global_position.distance_to(home)<.02 and school.steering_at(home+Vector3.RIGHT,Vector3.ZERO)==Vector3.ZERO)
	check("Doorway remains clear",not floor_at(school.to_global(Vector3(6,0,0))).is_empty())
	pointer.queue_free()
	observations.headset_tested=false
	completed=true

func mean_distance(school:Node3D) -> float:
	var total:=0.0
	for b in school.boids:total+=b.global_position.distance_to(school.point.global_position)
	return total/school.boids.size()

func finish() -> void:
	var result:Dictionary={"passed":completed and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Native museum; synthetic pickup/action; rendered moving production flock. Physical headset untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
