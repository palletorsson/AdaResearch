extends "res://tools/probes/transformation_encounters.gd"
var ui:Node3D
func press(id:String)->void:
    var area:Node3D=ui.buttons[id].get_node("InteractableAreaButton")
    XRToolsPointerEvent.pressed(camera,area,area.global_position)
    XRToolsPointerEvent.released(camera,area,area.global_position)
    await tick()
func move_hand(controller:Node3D,p:Vector3)->void:
    controller.global_position=p
    for i in 8:await tick()
func photo(name:String,s:Node3D)->void:
    await snapshot(name,s.to_global(Vector3(-.6,3.1,4.4)),s.to_global(Vector3(0,1.1,.5)),55)
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true);root.size=Vector2i(1440,1000)
    for i in 3600:
        ui=find_scene("/layer_pattern_lesson.gd")
        if ui!=null and ui.ready_for_use:break
        await process_frame
    museum.call("flush_stamps");await create_timer(.6).timeout
    var player:Node3D=museum.get("_player")
    if player:player.hide();player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    check("installed paired layer lesson ready",ui!=null and ui.ready_for_use)
    if ui==null or not ui.ready_for_use:return
    observations["ui_world"]=xyz(ui.global_position)
    check("installed counts are 16 source and 64 volume cells",ui.flat.size()==16 and ui.voxels.size()==64 and ui.values.size()==4)
    var source:Array=ui.SOURCE.duplicate(true)
    check("repeat fills four source copies",ui.values.all(func(sheet):return sheet==source))
    var positions:Dictionary={};var ids:Dictionary={}
    for key in ui.voxels:positions[key]=ui.voxels[key].position;ids[key]=ui.voxels[key].get_instance_id()
    await snapshot("installed-repeat",ui.to_global(Vector3(1,4.5,9.5)),ui.to_global(Vector3(-1,1.4,1.5)),60)
    await press("X +");await press("Z +");await press("LAYER +")
    check("real pointer selects independent x z y indices",ui.x_index==1 and ui.z_index==1 and ui.layer==1)
    check("source and volume frames show the repeated lookup",ui.markers[0].position==Vector3(1,.25,1) and ui.markers[1].position==Vector3(1,1.25,1))
    await press("REPEAT / SHIFT")
    check("height shifts source column with four-column wrap",ui.values[1][1][1]==source[1][2] and ui.values[3][2][3]==source[2][2])
    check("source marker moves while volume address stays",ui.markers[0].position==Vector3(2,.25,1) and ui.markers[1].position==Vector3(1,1.25,1))
    check("installed zero remains a pale visible cube",ui.voxels[Vector3i(0,0,3)].visible and ui.voxels[Vector3i(0,0,3)].get_node("CubeBaseMesh").material_override.albedo_color==ui.PALETTE[0])
    await snapshot("installed-shift",ui.to_global(Vector3(1,4.5,9.5)),ui.to_global(Vector3(-1,1.4,1.5)),60)
    var values:Array=ui.values.duplicate(true)
    await press("SLICE / ALL")
    check("installed slice shows16 keeps64 nodes and values",ui.voxels.values().filter(func(c):return c.visible).size()==16 and ui.voxels.size()==64 and ui.values==values)
    var unmoved:=true
    for key in ui.voxels:unmoved=unmoved and ui.voxels[key].position==positions[key] and ui.voxels[key].get_instance_id()==ids[key]
    check("installed changes never move or rebuild cubes",unmoved and ui.SOURCE==source)
    await snapshot("installed-slice",ui.to_global(Vector3(1,4.5,9.5)),ui.to_global(Vector3(-1,1.4,1.5)),60)
    await snapshot("installed-console",ui.to_global(Vector3(-1,1.7,6.6)),ui.mount.global_position,55)
    await press("UNDO");check("UNDO restores ALL view",not ui.slice_only)
    await press("UNDO");check("UNDO restores repeat values",not ui.shifted and ui.values[1]==source)
    for i in 4:await press("LAYER +")
    check("installed layer index wraps through four",ui.layer==1)
    # Return to start without changing any production file.
    ui.x_index=0;ui.z_index=0;ui.layer=0;ui.shifted=false;ui.slice_only=false;ui.history.clear();ui.refresh()
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var s=load(spec.lesson).new()
    s.transform=hall.global_transform.affine_inverse()*ui.global_transform*Transform3D(Basis.IDENTITY,Vector3(2.5,0,8))
    hall.add_child(s);await create_timer(.3).timeout
    var capsule:=CapsuleShape3D.new();capsule.radius=.25;capsule.height=1.7
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1|4
    observations["approaches"]=[]
    for offset in [Vector3(0,0,3),Vector3(-.6,0,2.9),Vector3(.6,0,2.9)]:
        var foot:Vector3=s.to_global(offset);query.transform.origin=foot+Vector3.UP*.9
        var support:=floor_at(foot);var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,12)
        var names:Array=[]
        for hit in hits:names.append(str(hit.collider.get_path()))
        observations.approaches.append({"foot":xyz(foot),"colliders":names,"support_y":support.position.y if not support.is_empty() else null})
        check("supported clear learner approach "+str(offset),not support.is_empty() and absf(support.position.y-foot.y)<.08 and hits.is_empty())
    await photo("student-repeat",s)
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=s.control.global_transform;s.control.pick_up(pickup);await tick()
    await move_hand(controller,s.to_global(Vector3(-.6,1.15,2.5)));s.control.action();await tick()
    check("held point advances selected layer",s.control.is_picked_up() and s.layer==1)
    await move_hand(controller,s.layers[1].to_global(Vector3(1.28,.22,.96)))
    check("held point reports repeated volume address and value",s.selected_address()==Vector2i(4,3) and s.label.text.contains("VOLUME [1][3][4] <- SOURCE [1][1] = 0"))
    await move_hand(controller,s.to_global(Vector3(.6,1.15,2.5)));s.control.action();await tick()
    await move_hand(controller,s.layers[1].to_global(Vector3(1.28,.22,.96)))
    check("held SHIFT changes lookup without changing address",s.shifted and s.selected_address()==Vector2i(4,3) and s.label.text.contains("VOLUME [1][3][4] <- SOURCE [1][2] = 1"))
    await photo("student-shift",s)
    var kept:Array=s.values.duplicate(true)
    await move_hand(controller,s.to_global(Vector3(0,1.15,2.5)));s.control.action();await tick()
    check("held SLICE leaves100 values and four receivers",s.slice_only and s.values==kept and s.layers.size()==4 and s.layers.filter(func(g):return g.visible).size()==1)
    await move_hand(controller,s.layers[1].to_global(Vector3(1.28,.22,.96)))
    await photo("student-slice",s)
    s.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("point releases frozen",not s.control.is_picked_up() and s.control.freeze)
