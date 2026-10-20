extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(.8).timeout
    var stream = museum.get("_portal_stream")
    if stream != null:
        stream.set_process(false)
        stream.set_physics_process(false)
    var player = museum.get("_player")
    if player is Node3D:
        player.hide()
        player.set_process(false)
        player.set_physics_process(false)
        player.global_position = Vector3(0,-100,0)
    camera.set_cull_mask_value(19,false)
    var wardrobe = museum.get("_wardrobe")
    if wardrobe != null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    for child in museum.get_children():
        if child is Node3D and child.has_meta("em_map") and child != hall:child.hide()
    var trio := find_scene("/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd")
    var orb := find_scene("/dark_sphere/dark_sphere.gd")
    var synthesis := find_scene("/synthesis/synthesis_stand.gd")
    check("installed trio and both orb encounters remain",trio != null and orb != null and synthesis != null)
    if trio == null:return
    observations.inventory=[]
    for rec in museum.get("_edit_records"):
        var node=rec.get("node")
        if is_instance_valid(node) and hall.is_ancestor_of(node):observations.inventory.append({"key":rec.get("token",""),"position":xyz(hall.to_local(node.global_position))})
    observations.installed_field={"seed":trio._noise.seed,"frequency":trio._noise.frequency,"fractal_type":trio._noise.fractal_type,"octaves":trio._noise.fractal_octaves,"gain":trio._noise.fractal_gain,"lacunarity":trio._noise.fractal_lacunarity}
    check("trio begins with anonymous driver plates",not trio._revealed and trio._trio.size()==3 and trio._trio[0].plate.text=="?")
    await snapshot("encounter",trio.to_global(Vector3(0,1.7,5.3)),trio.to_global(Vector3(0,1.45,0)),73)
    var pointer:=Node3D.new()
    root.add_child(pointer)
    await press(trio,"Btn_0",pointer)
    var held:float=trio.time
    var orb_time:float=orb.get("_time_elapsed")
    var meshes:Array=[]
    for data in trio._trio:meshes.append(data.shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate())
    await create_timer(.4).timeout
    check("real FREEZE pointer event holds the local clock",trio._frozen and trio.time==held)
    check("orb's independent clock continues",float(orb.get("_time_elapsed"))>orb_time)
    await press(trio,"Btn_2",pointer)
    var yaw:float=trio._trio[0].node.rotation.y
    await create_timer(.4).timeout
    check("SPIN turns held geometry",trio._trio[0].node.rotation.y!=yaw and trio.time==held)
    for i in range(3):check("SPIN preserves shaft local vertices "+str(i),meshes[i]==trio._trio[i].shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
    await press(trio,"Btn_2",pointer)
    for data in trio._trio:data.node.rotation.y=0
    await press(trio,"Btn_3",pointer)
    check("MARBLE changes the material alone",not trio._marble_on and meshes[0]==trio._trio[0].shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
    await press(trio,"Btn_1",pointer)
    check("REVEAL names each actual driver",trio._revealed and trio._trio[0].plate.text==str(trio._trio[0].driver).to_upper())
    await snapshot("matte-revealed",trio.to_global(Vector3(0,1.7,5.3)),trio.to_global(Vector3(0,1.45,0)),73)
    await snapshot("readout",trio.to_global(Vector3(-1.1,1.65,2.6)),trio._readout.global_position,65)
    observations.mesh_entries=[]
    for data in trio._trio:observations.mesh_entries.append({"driver":data.driver,"phase":data.phase,"drop":data.drop,"vertices":data.shaft.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()})
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=26
    await snapshot("overhead",hall.to_global(Vector3(7,26,18)),hall.to_global(Vector3(7,0,11)),60)
    camera.projection=Camera3D.PROJECTION_PERSPECTIVE
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    if spec.has("lesson"):
        var study=load(spec.lesson).new()
        study.position=Vector3(4.5,0,14.5)
        study.rotation.y=PI
        hall.add_child(study)
        study.set_process(false)
        study.time=PI/(2*.9)
        study.draw_values()
        var foot:Vector3=study.to_global(Vector3(0,0,1.6))
        var support:=floor_at(foot)
        observations.learner_host={"hall_local_metres":xyz(study.position),"yaw":180,"support":xyz(support.get("position",Vector3.ZERO))}
        check("learner approach has a floor",not support.is_empty() and absf(support.position.y-foot.y)<.05)
        var shape:=CapsuleShape3D.new()
        shape.height=1.7;shape.radius=.28
        var query:=PhysicsShapeQueryParameters3D.new()
        query.shape=shape;query.collision_mask=1|4
        query.transform.origin=foot+Vector3.UP*.88
        check("learner approach has standing clearance",hall.get_world_3d().direct_space_state.intersect_shape(query,4).is_empty())
        await create_timer(.5).timeout
        check("learner control survives physics at its intended position",study.control.position.is_equal_approx(Vector3(0,1,1)))
        check("native student top matches quarter-cycle prediction",is_equal_approx(study.shafts[1].points[-1].y,1.7))
        await snapshot("student",study.to_global(Vector3(0,1.65,3.7)),study.to_global(Vector3(0,1.4,0)),61)
        await grip_check(study)
        study.queue_free()
    pointer.queue_free()
    observations.scope="Actual museum and temporary printed reconstruction; simulated pointer and XR Tools grip, not physical headset evidence."

func press(trio:Node3D,key:String,pointer:Node3D)->void:
    var event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
    var target:Node3D=trio.find_child(key,true,false).get_node("InteractableAreaButton")
    for kind in [2,3]:target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
    await process_frame

func grip_check(study:Node3D)->void:
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
    controller.add_child(pickup)
    controller.global_transform=study.control.global_transform
    study.control.pick_up(pickup)
    await tick()
    controller.global_position+=study.global_basis*Vector3(.3,.2,0)
    for i in 6:await tick()
    check("carried point follows simulated controller",study.control.is_picked_up() and study.control.global_position.distance_to(controller.global_position)<.05)
    study.control.action()
    var t:float=study.time
    study._process(.3)
    check("held point action pauses printed study",not study.playing and study.time==t)
    study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
    await tick()
    check("control releases frozen",not study.control.is_picked_up() and study.control.freeze)
    origin.queue_free()
