extends "res://tools/probes/overlapping_rooms.gd"
var corners: Node3D
var walker: CharacterBody3D
var hand: Node3D
var transfer_offset_valid := true

func capture(name: String, eye: Vector3, target: Vector3, fov := 70.0) -> void:
	wing.move_together(eye-wing.eye_position());overlap.have_eye=false
	camera.global_position=eye;camera.look_at(target);camera.fov=fov;camera.current=true
	if hand!=null and wing.point.held() and name!="room-above":
		# Aim the real hand camera with the inspection view; let the existing hand
		# code position its object. No extra sphere is staged for the photograph.
		hand.cam.global_basis=camera.global_basis;hand._hold_distance=1.1
		for i in range(32):hand._process(0.016)
		overlap.last_point=wing.point.global_position
		check("native hand follows camera for "+name,wing.point.global_position.distance_to(hand.cam.global_position-hand.cam.global_basis.z*1.1)<0.012)
		observations[name+"_point"]={"camera_local":xyz(camera.to_local(wing.point.global_position)),"visible":wing.point.is_visible_in_tree()}
	overlap.update_visibility(camera)
	# The overhead camera is a survey view, so the visitor's hat/body should not
	# obscure the room plan. Restore every original visibility after the photo.
	var hidden: Array=[]
	if name=="room-above":
		for item in walker.find_children("*","GeometryInstance3D",true,false):
			if item.visible:hidden.append(item);item.visible=false
		var wardrobe:Node=museum.get("_wardrobe")
		if wardrobe!=null:
			var costume:Node3D=wardrobe.get("costume")
			if costume!=null and costume.visible:hidden.append(costume);costume.visible=false
	var carry_frame := func():
		if hand!=null and wing.point.held() and name!="room-above":
			hand.cam.global_basis=camera.global_basis
			hand._process(0.016)
	process_frame.connect(carry_frame)
	await snapshot(name,eye,target,fov)
	process_frame.disconnect(carry_frame)
	if name=="carried-point":
		observations["point_after_capture"]={"local":xyz(camera.to_local(wing.point.global_position)),"scale":xyz(wing.point.global_basis.get_scale()),"visible":wing.point.is_visible_in_tree(),"mesh_visible":overlap.point_surface.is_visible_in_tree(),"layers":overlap.point_surface.layers,"camera_mask":camera.cull_mask,"material":str(overlap.point_surface.material_override),"parent":str(wing.point.get_parent().get_path())}
		check("native hand keeps the point in view across rendered frames",camera.to_local(wing.point.global_position).distance_to(Vector3(0,0,-1.1))<0.08)
	for item in hidden:item.visible=true

func portal(a: int,b: int) -> Dictionary:
	for link in overlap.links:
		if link.from==a and link.to==b: return link
	return {}

func walk_to(target: Vector3) -> bool:
	# Move the real museum collision body, never substitute a test point camera.
	for step in range(300):
		var d:=target-walker.global_position; d.y=0
		if d.length()<0.015: return true
		d=d.limit_length(0.055)
		if walker.test_move(walker.global_transform,d): return false
		walker.global_position+=d
		if wing.point.held(): wing.point.global_position+=d
		overlap.update(0.016)
	return false

func walk_through(link: Dictionary) -> bool:
	var from: int=link.from
	var before: Vector3=wing.point.global_position-wing.eye_position()
	var direction: Vector3=-link.source.global_basis.z*0.055
	for step in range(45):
		if walker.test_move(walker.global_transform,direction): return false
		walker.global_position+=direction
		if wing.point.held(): wing.point.global_position+=direction
		overlap.update(0.016)
		if overlap.sector!=from:
			transfer_offset_valid=(wing.point.global_position-wing.eye_position()).distance_to(before)<0.0002
			# Step clear of the threshold. A real physics tick registers new rooms.
			walker.global_position+=direction*10
			if wing.point.held(): wing.point.global_position+=direction*10
			await tick(); overlap.update(0.016)
			return overlap.sector==link.to
	return false

func landing_checks() -> void:
	var start:=Time.get_ticks_msec()
	while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<35000:
		museum.call("_drain_stamps"); museum.call("_drain_cartridge_nodes"); await tick()
	wing=find_scene("/noneuclidean_wing.gd")
	check("installed museum wing present",wing!=null)
	if wing==null:return
	while not wing.built:await tick()
	wing.set_process(false); overlap=wing.overlap; corners=overlap.corners
	walker=museum.get("_player")
	for n in walker.find_children("*","Node3D",true,false):
		if n.has_method("_grab_held"): hand=n; break
	check("native museum hand present",hand!=null)
	if hand==null:return
	hand.set_process(false); wing.visit(0)
	var identity: int=wing.point.get_instance_id()
	await capture("entrance",overlap.lobby.to_global(Vector3(4.7,1.7,1.7)),corners.entrance.to_global(Vector3(0,1.6,-3)),76)
	check("only two corner rooms initially built",corners.resident.size()==2)
	walker.global_position=corners.entrance.to_global(Vector3(0,0.05,1.2))
	wing.point.global_position=wing.eye_position()+Vector3(0.35,-0.3,-0.5)
	hand._grab_held(wing.point); overlap.have_eye=false; overlap.update(0.016)
	check("walk through new museum entrance",await walk_through(portal(-1,2)))
	var directions: Array=[]
	for depth in range(12):
		var room: Node3D=corners.resident[depth].room
		directions.append(room.global_basis.z)
		check("room %d has a supported landing"%depth,not floor_at(room.to_global(Vector3(0,0,4.9))).is_empty())
		check("room %d keeps same live held point"%depth,wing.point.get_instance_id()==identity and hand._held==wing.point and overlap.point_sector==depth+2)
		check("room %d prepares next room"%depth,corners.resident.has(depth+1))
		if depth<2:
			await capture("room-%d-entry"%(depth+1),room.to_global(Vector3(0,1.7,4.7)),room.to_global(Vector3(0,1.65,-2)),82)
			# A collision ray verifies the next threshold is behind the inner room.
			var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,corners.resident[depth].exit.to_global(Vector3(0,1.7,0)),1)
			var hit:=room.get_world_3d().direct_space_state.intersect_ray(ray)
			check("inner room hides next door from entry %d"%depth,not hit.is_empty() and hit.collider.get_parent().name=="BlindCorner")
		if not await walk_to(room.to_global(Vector3(0,0.05,0))):check("clear physical path to corner %d"%depth,false);return
		if depth in [0,1,4]:
			await capture("corner-%d"%(depth+1),room.to_global(Vector3(-0.1,1.7,0)),room.to_global(Vector3(7.5,1.55,0)),80)
			check("door becomes visible after turn %d"%depth,portal(depth+2,depth+3).view.visible)
			if depth==0:await capture("carried-point",room.to_global(Vector3(-0.1,1.7,0)),room.to_global(Vector3(4,0.3,0)),76)
		if not await walk_to(room.to_global(Vector3(4.9,0.05,0))):check("clear physical path after corner %d"%depth,false);return
		check("walk into newly generated room %d"%(depth+2),await walk_through(portal(depth+2,depth+3)))
		check("translation preserves hand offset %d"%depth,transfer_offset_valid)
		check("bounded cache %d"%depth,corners.resident.size()<=5)
	check("four right turns restore heading in a different numbered room",directions[0].is_equal_approx(directions[4]) and corners.opened_depth>=12)
	# Leave the point in room 13; travel six rooms further. The real object and
	# its physical sector must survive eviction of unrelated rooms.
	hand._drop_held();var kept:Vector3=wing.point.global_position
	for depth in range(12,18):
		overlap.cross(portal(depth+2,depth+3));await tick()
	check("dropped point survives distant room creation",wing.point.get_instance_id()==identity and wing.point.global_position.is_equal_approx(kept) and corners.resident.has(12) and overlap.point_sector==14)
	check("distant point does not increase cache beyond five",corners.high_water<=5)
	for depth in range(18,12,-1):overlap.cross(portal(depth+2,depth+1));await tick()
	check("backtracking restores the room containing the same point",overlap.sector==14 and wing.point.global_position.is_equal_approx(kept))
	hand._grab_held(wing.point)
	for depth in range(12,0,-1):
		var room:Node3D=corners.resident[depth].room
		# Actual reverse collision path through two recently regenerated rooms.
		if depth<3:
			walker.global_position=room.to_global(Vector3(4.8,0.05,0))
			wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.3,0)
			overlap.have_eye=false;overlap.update(0.016)
			check("reverse walk round corner %d"%depth,await walk_to(room.to_global(Vector3(0,0.05,0))) and await walk_to(room.to_global(Vector3(0,0.05,4.9))))
			check("reverse doorway %d"%depth,await walk_through(portal(depth+2,depth+1)))
		else:overlap.cross(portal(depth+2,depth+1));await tick()
	check("first room restored with its original identity",corners.resident[0].room.name=="CornerRoom0001" and overlap.sector==2)
	var first:Node3D=corners.resident[0].room
	await capture("room-above",first.to_global(Vector3(-8,12,11)),first.to_global(Vector3(0,0.7,0)),68)
	await capture("point-returned",first.to_global(Vector3(0,1.7,0)),first.to_global(Vector3(0,1.5,7)),76)
	check("return aperture visible",portal(2,-1).view.visible)
	camera.look_at(camera.global_position+Vector3.UP+first.global_basis*Vector3.LEFT)
	overlap.update_visibility(camera)
	check("turning away culls corner previews",overlap.stats.portals==0)
	check("walk the final return approach",await walk_to(first.to_global(Vector3(0,0.05,4.9))))
	check("walk back into original pavilion",await walk_through(portal(2,-1)))
	hand._drop_held();overlap.update(0.016)
	check("same point back in original museum pavilion",overlap.sector==-1 and overlap.point_sector==-1 and wing.point.get_instance_id()==identity)
	check("no previews carry physics or behaviour",overlap.links.all(func(l):return l.view.find_children("*","PhysicsBody3D",true,false).is_empty()))
	wing.visit(1);overlap.update(0.016)
	check("next chamber hides all generated corner rooms",corners.resident.values().all(func(d):return not d.room.visible))
	observations["generated"]=corners.generated;observations["furthest_room"]=corners.opened_depth+1
	observations["max_resident_rooms"]=corners.high_water
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["scope"]="12 consecutive physical right-turn traversals; 19 room addresses; backward regeneration and point persistence. Desktop hand/walker; no headset claim."
	complete=true

func finish() -> void:
	check("corner probe completed",complete)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("CORNER ROOMS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
