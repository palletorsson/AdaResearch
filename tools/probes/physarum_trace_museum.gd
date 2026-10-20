extends "res://tools/probes/transformation_encounters.gd"
var complete := false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream= museum.get("_portal_stream")
	if stream!=null: stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player= museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure:=CameraAttributesPractical.new();exposure.exposure_multiplier=.65;camera.attributes=exposure
	var host:=find_scene("/physarum_trace_gallery.gd")
	check("Physarum trace gallery loads in its real hall",host!=null)
	if host==null:return
	check("Only one original Physarum colony runs in the hall",hall.find_children("*","Node3D",true,false).filter(func(n):return n.get_script()!=null and n.get_script().resource_path.ends_with("physarum/PhysarumColony.gd")).size()==1)
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	var corners:Array[Vector3]=[Vector3(-9,0,0),Vector3(-6,0,0),Vector3(-6,0,-1),Vector3(0,0,-1),Vector3(0,0,3.4),Vector3(2.5,0,3.4),Vector3(2.5,0,2.65)]
	var supported:=true;var clear:=true
	for i in range(corners.size()-1):
		var count:=ceili(corners[i].distance_to(corners[i+1])/.15)
		for j in range(count+1):
			var p:=host.to_global(corners[i].lerp(corners[i+1],float(j)/count))
			supported=supported and not floor_at(p).is_empty()
			var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.transform.origin=p+Vector3.UP*.9
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
			if not hits.is_empty():clear=false;print("TRACE BLOCK ",host.to_local(p)," ",hits[0].collider.get_path())
	check("Continuous floor from original hall to drawing position",supported)
	check("Standing approach and drawing position are clear",clear)
	var reachable:=true
	for z in [.9,1.45,2.15]:
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.transform.origin=host.to_global(Vector3(4.1,.9,z))
		reachable=reachable and hall.get_world_3d().direct_space_state.intersect_shape(q).is_empty() and not floor_at(host.to_global(Vector3(4.1,0,z))).is_empty()
	check("Hand point and both side controls have standing access",reachable)
	check("Hand surface and point are around one metre high",host.PAD.y>1 and host.HOME.y<1.3)
	var elapsed:=Time.get_ticks_msec()
	await create_timer(32).timeout
	observations.growth_wall_seconds=(Time.get_ticks_msec()-elapsed)/1000.0
	var colony=host.source.colony
	check("Original colony develops a nonempty field",colony.grid.grid.count(0.0)<60000)
	check("Original anchor carousel still advances",colony.dist_mode!=0)
	host.toggle_play()
	await snapshot("wall",host.to_global(Vector3(0,1.7,4.1)),host.to_global(Vector3(0,3.1,-3.7)),79)
	await snapshot("hall-above",host.to_global(Vector3(-8,27,15)),host.to_global(Vector3(-7,0,0)),65)
	await snapshot("controls",host.to_global(Vector3(4.4,1.9,2.8)),host.to_global(Vector3(2.8,1.05,1.5)),66)
	# Paint a loop via the real held point/action hook while colony is paused.
	var pointer:=Node3D.new();root.add_child(pointer);host.point.on_desktop_grab(pointer)
	host.point.global_position=host.to_global(host.PAD+Vector3(.37,.2,0));await tick();host.point.action()
	for i in range(61):
		var a:=float(i)/60*TAU
		host.point.global_position=host.to_global(host.PAD+Vector3(cos(a)*.37,.20,sin(a)*.32))
		await create_timer(.055).timeout
	host.point.action_release()
	check("Held point action writes into the colony inside the museum",host.input_mark_count>60 and host.written_cells>100)
	var marks:int=host.input_mark_count
	await snapshot("hand-mark",host.to_global(Vector3(3.6,2.05,2.7)),host.to_global(host.PAD),62)
	await snapshot("mark-on-wall",host.to_global(Vector3(0,1.7,4.1)),host.to_global(Vector3(0,3.1,-3.7)),79)
	host.point.on_desktop_drop(pointer);host.toggle_play()
	var before:PackedFloat32Array=colony.grid.grid.duplicate()
	await create_timer(8).timeout
	check("Released point adds no further marks",host.input_mark_count==marks)
	check("Original colony evolves the written field after release",colony.grid.grid!=before)
	check("Dropped point returns to its dock",host.point.position.distance_to(host.HOME)<.01)
	host.toggle_play()
	await snapshot("after-release",host.to_global(Vector3(0,1.7,4.1)),host.to_global(Vector3(0,3.1,-3.7)),79)
	observations.marks=marks;observations.headset_tested=false;observations.original_agents=colony.num_agents
	complete=true;pointer.queue_free()
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":complete and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if complete and failures.is_empty() else 1)
