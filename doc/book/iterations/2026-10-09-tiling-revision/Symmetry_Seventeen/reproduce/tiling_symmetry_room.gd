extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
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
    await snapshot(name,s.to_global(Vector3(-1.2,2.4,3.9)),s.to_global(Vector3(.05,1.2,.9)),55)
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true);root.size=Vector2i(1440,1000)
    var grid:Node3D=hall.get_node_or_null("SimGrid_Symmetry_Seventeen")
    for i in 3600:
        if grid==null or grid.has_meta("stage_grid_ready"):break
        await process_frame
    museum.call("flush_stamps");await create_timer(.6).timeout
    var player:Node3D=museum.get("_player")
    if player:player.hide();player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    ui=find_scene("/symmetry_compare_lesson.gd")
    check("installed symmetry comparison loaded",ui!=null)
    if ui==null:return
    check("sixteen source addresses, four colours and six actions",ui.buttons.size()==26)
    check("legacy competing editor suspended",not ui.puzzle.visible and ui.puzzle.process_mode==Node.PROCESS_MODE_DISABLED)
    var source:Array=ui.puzzle.get_pattern_data()
    var held:PackedByteArray=ui.held.material_override.albedo_texture.get_image().get_data()
    await press("PM")
    var pm:PackedByteArray=ui.live.material_override.albedo_texture.get_image().get_data()
    check("PM changes image and preserves source",pm!=held and ui.puzzle.get_pattern_data()==source)
    check("PM odd block reverses source column",ui.puzzle._get_tiled_color(4,0)==source[0][3])
    await press("PG")
    check("PG adds wrapped two-row shift",ui.puzzle._get_tiled_color(4,0)==source[2][3] and ui.puzzle._get_tiled_color(5,2)==source[0][2])
    check("PG image differs from PM",ui.live.material_override.albedo_texture.get_image().get_data()!=pm)
    check("held P1 image survives both rule changes",ui.held.material_override.albedo_texture.get_image().get_data()==held)
    await snapshot("installed-p1-pg",ui.to_global(Vector3(0,2,5.1)),ui.to_global(Vector3(0,1.3,-.5)),62)
    await press("HOLD")
    var glide:PackedByteArray=ui.held.material_override.albedo_texture.get_image().get_data()
    await press("paint_3");await press("cell_1_0")
    check("real pointer paints source address",ui.puzzle.get_cell(1,0)==3)
    check("held PG owns pixels while live wall and floor share new render",ui.held.material_override.albedo_texture.get_image().get_data()==glide and ui.live.material_override.albedo_texture==ui.station._carpet_material.albedo_texture and ui.live.material_override.albedo_texture.get_image().get_data()!=glide)
    await press("UNDO");check("UNDO restores painted source",ui.puzzle.get_pattern_data()==source)
    await press("UNDO");check("UNDO restores former held P1",ui.held.material_override.albedo_texture.get_image().get_data()==held)
    await press("HOLD");await press("RESET")
    check("RESET returns source and P1, keeps held PG",ui.group_index==0 and ui.puzzle.get_pattern_data()==source and ui.held.material_override.albedo_texture.get_image().get_data()==glide)
    await snapshot("installed-console",ui.to_global(Vector3(0,1.7,2)),ui.to_global(Vector3(0,1.15,.6)),55)
    # Restore the source and original held view after the inspection.
    await press("HOLD")
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var learner=load(spec.lesson).new()
    learner.transform=hall.global_transform.affine_inverse()*ui.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0,3.5));hall.add_child(learner)
    await create_timer(.3).timeout
    var shape:=CapsuleShape3D.new();shape.height=1.7;shape.radius=.25
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    observations["approaches"]=[]
    for offset in [Vector3(0,0,3),Vector3(-.6,0,2.9),Vector3(.6,0,2.9)]:
        var foot:Vector3=learner.to_global(offset);var support:=floor_at(foot)
        query.transform.origin=foot+Vector3.UP*.9
        var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,12)
        var names:Array=[]
        for hit in hits:names.append(str(hit.collider.get_path()))
        observations.approaches.append({"foot":xyz(foot),"colliders":names,"support_y":support.position.y if not support.is_empty() else null})
        check("learner standing approach supported and clear "+str(offset),not support.is_empty() and absf(support.position.y-foot.y)<.08 and hits.is_empty())
    check("single inherited receiver built in the museum",learner.grid.cells.size()==25 and learner.find_children("*","MultiMeshInstance3D",true,false).size()==1)
    await photo("student-p1",learner)
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=learner.control.global_transform;learner.control.pick_up(pickup);await tick()
    await move_hand(controller,learner.to_global(Vector3(0,1.15,2.5)))
    check("pickup names central rule control without acting",learner.control.is_picked_up() and learner.operation()=="RULE" and learner.rule==0)
    learner.control.action();await tick()
    check("first held trigger selects PM",learner.rule==1 and learner.reflected and learner.source==[[0,1,0],[0,0,1]])
    await photo("student-pm",learner)
    learner.control.action();await tick()
    check("second held trigger selects PG",learner.rule==2 and learner.source_address(Vector2i(3,0))==Vector2i(2,1))
    await move_hand(controller,learner.to_global(Vector3(.32,1.12,0)))
    check("held point identifies glided source row one column two",learner.selected_address()==Vector2i(3,0) and learner.label.text.contains("source row 1, column 2"))
    await photo("student-pg",learner)
    learner.control.action();await tick()
    check("held trigger paints original source entry through glide",learner.source==[[0,1,0],[0,0,2]] and learner.value_at(Vector2i(3,0))==2)
    await photo("student-painted-glide",learner)
    await move_hand(controller,learner.to_global(Vector3(-.6,1.15,2.5)));learner.control.action();await tick()
    await move_hand(controller,learner.to_global(Vector3(.6,1.15,2.5)));learner.control.action();await tick()
    await move_hand(controller,learner.to_global(Vector3(.6,2.2,1.44)))
    check("glide survives inherited wall and width operations",learner.wall and learner.width_index==1 and learner.rule==2 and learner.selected_address()==Vector2i(3,0))
    await photo("student-wall",learner)
    learner.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("release retains the earlier frozen-point behaviour",learner.control.freeze and not learner.control.is_picked_up())
    var place:Transform3D=learner.transform;learner.hide();learner.queue_free();origin.queue_free();await tick()
    var transfer=load(spec.lesson.replace('/printed/','/four_rows/')).new();transfer.transform=place;hall.add_child(transfer)
    transfer.cycle_rule();transfer.cycle_rule();transfer._process(0)
    check("four-row program shifts by two rows",transfer.source_address(Vector2i(3,0))==Vector2i(2,2) and transfer.source_address(Vector2i(4,2))==Vector2i(1,0))
    await photo("student-four-rows",transfer)
    observations["learner"]={"source":spec.lesson,"temporary_hall_local":xyz(place.origin),"relative_to_console":[0,0,3.5],"scope":"Temporary display; actual XR Tools pickup, held action and release driven by simulated controller. No physical headset claim."}
    transfer.queue_free();completed=true
func finish()->void:
    check("installed comparison and learner completed",completed)
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Native museum, actual installed pointer callbacks, simulated XR Tools pickup/action/release, temporary reconstructed learner and independent four-row source. Not a full symmetry classification or headset test."},"  "))
    quit(0 if failures.is_empty() else 1)
