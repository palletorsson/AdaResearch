extends "res://commons/testing/probe_color_recovery.gd"

func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)

func run() -> void:
	await museum("Array_Patterns")
	var ui:Node3D=current_scene.find_child("TunnelAddressLesson",true,false)
	check(ui!=null,"primary tunnel loads the address lesson")
	if not ui:quit(1);return
	var t:Node3D=ui.tunnel;var cam:Camera3D=current_scene.get("_cam");var player:CharacterBody3D=current_scene.get("_player")
	player.set_physics_process(false);current_scene.get("_feel").set_process(false)
	var wardrobe:Node=current_scene.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	player.global_position+=ui.to_global(Vector3(0,1.7,4.5))-cam.global_position;cam.look_at(ui.to_global(Vector3(0,1.5,-2)))
	for i in 20:current_scene.call("_cull_artifacts");await process_frame
	check(t.tunnel_length==6 and t._mats.size()==4,"six-metre tube uses four surfaces")
	check(ui.get_parent().find_children("*","Node3D",true,false).filter(func(n):return n.get_script() and n.get_script().resource_path.ends_with("/display_console.gd")).is_empty(),"retired generic console cannot obstruct or modify the lesson")
	check(t._motif==ui.SOURCE and t._gs==4 and t.group_index==0,"same asymmetric four-by-four source returns in translation")
	check(not t.auto_run and not t.is_processing() and t._reveal==1.3,"address lesson starts fully visible without automatic reveal")
	check(ui.source_cells.size()==16 and ui.buttons.size()==6,"source array and six reachable pointer operations")
	if not ui.buttons.has("UNDO"):quit(1);return
	var source:PackedByteArray=t._pattern_tex.get_image().get_data()
	check(ui.buttons.UNDO.global_position.y>0.65 and ui.buttons.FACE.global_position.y<1.8,"panel controls stand in the reachable band")
	var initial:Dictionary=ui.state()
	for i in 4:press(ui,"COL +",cam)
	check(ui.column==initial.column+4 and ui.column%4==initial.column%4,"four surface columns return to the same source column")
	check(t._pattern_tex.get_image().get_data()==source,"address selection changes no stored pattern pixels")
	press(ui,"FACE",cam)
	check(ui.face==1 and is_equal_approx(ui.marker.position.x,1.78),"face control moves the indicator onto the right wall")
	check(ui.readout.text.contains("SOURCE [%d,%d]"%[ui.row%4,ui.column%4]),"readout names row and column in source order")
	var surfaces:Array=[]
	for n in t.get_children():
		if n is MeshInstance3D:surfaces.append(n)
	for face_id in 2:
		ui.face=face_id;ui.refresh()
		var mesh:MeshInstance3D=surfaces[0 if face_id==0 else 2]
		var point:Vector3=mesh.to_local(ui.marker.global_position)
		var extent:Vector2=mesh.mesh.size
		var uv=Vector2(point.x/extent.x+0.5,0.5-point.y/extent.y)
		var addr=uv*mesh.material_override.get_shader_parameter("tile_reps")
		check(int(floor(addr.x))==ui.column and int(floor(addr.y))==ui.row,"marker and actual quad UV address agree on face %d"%face_id)
	var before:Dictionary=ui.state();var marker_pos:Vector3=ui.marker.position
	press(ui,"CELL SIZE",cam)
	check(is_equal_approx(ui.pitch,0.6) and t._pattern_tex.get_image().get_data()==source,"cell spacing changes without regenerating the source")
	check(t._mats[0].get_shader_parameter("tile_reps").is_equal_approx(Vector2(6,10)),"sixty-centimetre floor cells use six by ten intervals")
	press(ui,"UNDO",cam)
	check(ui.state()==before and ui.marker.position.is_equal_approx(marker_pos),"undo restores address, face and physical spacing")
	press(ui,"GRID",cam)
	check(not ui.show_grid and t._mats[0].get_shader_parameter("study_grid")==0 and t._pattern_tex.get_image().get_data()==source,"hide grid removes drawn joints while preserving colour source")
	press(ui,"UNDO",cam)
	check(ui.show_grid,"grid visibility is reversible")
	var floor:MeshInstance3D
	for n in t.get_children():
		if n is MeshInstance3D and n.position.y<0.1:floor=n
	check(floor!=null and floor.position.y>0,"printed floor is above the grid floor")
	var shape=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.5
	var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1;q.exclude=[player.get_rid()]
	q.transform.origin=ui.to_global(Vector3(0,0.82,1));q.motion=ui.global_basis*Vector3(0,0,-8)
	await physics_frame
	check(t.get_world_3d().direct_space_state.cast_motion(q)[0]>0.99,"body can cross the entrance, tunnel and far exit")
	var ray=PhysicsRayQueryParameters3D.create(ui.to_global(Vector3(0,1.5,-3)),ui.to_global(Vector3(2.3,1.5,-3)),1);ray.exclude=[player.get_rid()]
	check(not t.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"right wall has collision independent of printed joints")
	q.transform.origin=ui.to_global(Vector3(3,0.82,3));q.motion=Vector3.ZERO
	check(t.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"standing body fits in front of the side console")
	var grid:Node3D=ui
	while grid and not grid.name.begins_with("SimGrid_"):grid=grid.get_parent()
	q.transform.origin=grid.to_global(Vector3(16,0,12));q.transform.origin.y=ui.global_position.y+0.82;q.motion=grid.global_basis*Vector3(8,0,0)
	check(t.get_world_3d().direct_space_state.cast_motion(q)[0]>0.99,"museum side aisle connects through the bay doorway")
	check(ui.get_parent().GROUPS[4]=="CM" and ui.get_parent().GROUPS[7]=="PGG","generic tunnel group labels match the engine enumeration")
	ui.column=1;ui.row=10;ui.face=0;ui.pitch=0.4;ui.show_grid=true;ui.refresh()
	await capture(cam,ui.to_global(Vector3(-0.5,2.4,4.3)),ui.to_global(Vector3(0.8,1.4,-1.2)),"tunnel_address_bay")
	await capture(cam,ui.to_global(Vector3(3,1.8,3.5)),ui.to_global(Vector3(3,1.3,1.7)),"tunnel_address_console")
	await capture(cam,ui.to_global(Vector3(0,1.6,-1)),ui.to_global(Vector3(0.4,1.5,-5.5)),"tunnel_address_inside")
	var f=FileAccess.open("res://ada_run/probe_tunnel_addresses.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("TUNNEL_ADDRESSES ",checks," checks / ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
