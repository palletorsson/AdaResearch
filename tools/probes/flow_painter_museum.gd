extends "res://tools/probes/transformation_encounters.gd"
var complete:=false
func landing_checks()->void:
	museum.call("flush_stamps")
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.65;camera.attributes=exposure
	var h:=find_scene("/flow_direction_table.gd")
	check("Field painter loads at the original table placement",h!=null)
	if h==null:return
	check("Only one original FlowFieldMain runs",hall.find_children("*","Node3D",true,false).filter(func(n):return n.get_script()!=null and n.get_script().resource_path.ends_with("/FlowFieldMain.gd")).size()==1)
	check("Existing walk-in crowd is still present",find_scene("/flow_crowd.gd")!=null)
	check("Two views share the existing 200-agent field",h.flow.agents.size()==200 and h.pad.material_override==h.screen.material_override)
	var private_world:World3D=h.viewport.find_world_3d()
	var isolated:bool=h.get_world_3d()!=private_world
	for n in h.viewport.find_children("*","VisualInstance3D",true,false):
		if n.get_world_3d()!=private_world:isolated=false;print("WORLD LEAK ",n.get_path())
	check("Every table simulation visual remains in its private world",isolated)
	print("HOST POSE ",h.global_transform)
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	var supported:=true;var clear:=true
	# Walk to the near edge, then sideways to either controls or pickup.
	var points:Array[Vector3]=[Vector3(0,0,4),Vector3(0,0,3.65),Vector3(.78,0,3.65),Vector3(0,0,3.65),Vector3(0,0,3.05),Vector3(0,0,3.65),Vector3(-1.3,0,3.65),Vector3(-1.3,0,2.15)]
	for i in range(points.size()-1):
		var steps:=ceili(points[i].distance_to(points[i+1])/.1)
		for j in range(steps+1):
			var at:=h.to_global(points[i].lerp(points[i+1],float(j)/maxi(steps,1)))
			supported=supported and not floor_at(at).is_empty()
			var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.transform.origin=at+Vector3.UP*.9
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
			if not hits.is_empty():clear=false;print("PAINTER BLOCK ",h.to_local(at)," ",hits[0].collider.get_path())
	check("Approach and both controls have continuous floor",supported)
	check("Standing approach to point and buttons is clear",clear)
	check("Point and drawing surface are at hand height",h.HOME.y>1 and h.HOME.y<1.3 and h.PAD.y==1)
	h.toggle_play()
	await snapshot("table-before",h.to_global(Vector3(0,2.9,4.2)),h.to_global(Vector3(0,.8,.6)),66)
	await snapshot("hand-controls",h.to_global(Vector3(.8,1.8,3.5)),h.to_global(Vector3(0,1.1,2)),70)
	await snapshot("hall-above",h.to_global(Vector3(5,28,10)),h.to_global(Vector3(0,0,9)),80)
	var pointer:=Node3D.new();root.add_child(pointer);h.point.on_desktop_grab(pointer)
	h.point.global_position=h.to_global(h.PAD+Vector3(0,.2,-.32));await tick();h.point.action();await create_timer(.08).timeout
	# A vertical instruction through the centre, curling left at its end.
	for i in range(41):
		h.point.global_position=h.to_global(h.PAD+Vector3(0,.2,-.32+float(i)/40*.58));await create_timer(.055).timeout
	for i in range(21):
		var a:=float(i)/20*PI/2
		h.point.global_position=h.to_global(h.PAD+Vector3(-.19+.19*cos(a),.2,.26+.06*sin(a)));await create_timer(.055).timeout
	h.point.action_release()
	check("Actual held point edits a direction stripe",h.field_edits>8 and h.changed.count(1)>80)
	await snapshot("directions-written",h.to_global(Vector3(0,2.9,4.2)),h.to_global(Vector3(0,.8,.6)),66)
	await snapshot("field-close",h.to_global(Vector3(0,3.3,.15)),h.to_global(Vector3(0,.94,0)),82)
	var field:PackedVector2Array=h.flow.grid.vector_field.duplicate()
	var positions:Array=[]
	for agent in h.flow.agents:positions.append(agent.position)
	h.point.on_desktop_drop(pointer);h.toggle_play();await create_timer(6).timeout
	var moved:=0
	for i in range(200):
		if h.flow.agents[i].position.distance_to(positions[i])>.1:moved+=1
	check("Original bodies continue moving after release",moved>150)
	check("Bodies and release preserve the written field",field==h.flow.grid.vector_field)
	check("Dropped point returns to the dock",h.point.position.distance_to(h.HOME)<.01)
	h.toggle_play();await snapshot("after-release",h.to_global(Vector3(0,2.9,4.2)),h.to_global(Vector3(0,.8,.6)),66)
	h.caps[2].pressed.emit();check("Nearby tour button returns to original scenarios",not h.edit_mode and h.flow.scenario=="tour")
	await snapshot("original-tour",h.to_global(Vector3(0,2.9,4.2)),h.to_global(Vector3(0,.8,.6)),66)
	observations={"edited_cells":h.changed.count(1),"moved_bodies":moved,"agents":200,"headset_tested":false}
	complete=true;pointer.queue_free()
func finish()->void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":complete and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if complete and failures.is_empty() else 1)

