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
    var grid:Node3D=hall.get_node_or_null("SimGrid_Array_Patterns")
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
    ui=find_scene("/tunnel_address_lesson.gd")
    check("installed address tunnel loaded",ui!=null)
    if ui==null:return
    check("tunnel keeps fixed four-by-four source and six controls",ui.source_cells.size()==16 and ui.buttons.size()==6 and ui.tunnel._gs==4)
    var source:Array=ui.tunnel._motif.duplicate(true)
    var surfaces:Array=[]
    for n in ui.tunnel.get_children():
        if n is MeshInstance3D:surfaces.append(n)
    var base_state:Dictionary=ui.state().duplicate(true)
    for i in 4:await press("COL +")
    check("four actual button presses wrap source column",ui.column==5 and ui.readout.text.contains("SOURCE [2,1]"))
    check("column action leaves source data unchanged",ui.tunnel._motif==source)
    await snapshot("installed-tunnel",ui.to_global(Vector3(-.5,2.4,4.3)),ui.to_global(Vector3(.8,1.4,-1.2)),66)
    await press("FACE")
    check("actual FACE button chooses right wall",ui.face==1 and ui.readout.text.begins_with("RIGHT WALL") and is_equal_approx(ui.marker.position.x,1.78))
    var wall:Node3D=surfaces[2]
    var p:Vector3=wall.to_local(ui.marker.global_position)
    var uv:=Vector2(p.x/6+.5,.5-p.y/3.2)
    var repeats:Vector2=ui.tunnel._mats[2].get_shader_parameter("tile_reps")
    check("wall marker and rendered UV address agree",Vector2i(floori(uv.x*repeats.x),floori(uv.y*repeats.y))==Vector2i(ui.column,ui.row))
    await snapshot("installed-wall",ui.to_global(Vector3(-.9,1.5,-.2)),ui.to_global(Vector3(1.75,1.8,-3.2)),70)
    var before_size:Dictionary=ui.state().duplicate(true)
    await press("CELL SIZE")
    check("actual size button changes pitch and four-cell motif width",is_equal_approx(ui.pitch,.6) and ui.readout.text.contains("MOTIF 2.4 m"))
    check("fixed floor receives six by ten intervals",ui.tunnel._mats[0].get_shader_parameter("tile_reps").is_equal_approx(Vector2(6,10)))
    check("fixed wall retains partial row at its edge",ui.tunnel._mats[2].get_shader_parameter("tile_reps").is_equal_approx(Vector2(10,3.2/.6)))
    await snapshot("installed-console",ui.to_global(Vector3(3,.9,3.5)),ui.to_global(Vector3(3,.3,1.7)),54)
    await press("UNDO")
    check("UNDO restores complete prior settings",ui.state()==before_size)
    var collider_count:int=ui.find_children("*","StaticBody3D",true,false).size()
    await press("GRID")
    check("GRID hides drawn joints, keeps walls and fixed source",not ui.show_grid and is_zero_approx(ui.tunnel._mats[0].get_shader_parameter("study_grid")) and collider_count==ui.find_children("*","StaticBody3D",true,false).size() and ui.tunnel._motif==source)
    await press("UNDO")
    check("UNDO restores drawn joints",ui.show_grid)
    while not ui.history.is_empty():await press("UNDO")
    check("installed controls return to arrival settings",ui.state()==base_state)
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var script=load(spec.lesson)
    var learner=script.new();learner.position=Vector3(11.5,0,15.5);hall.add_child(learner)
    await create_timer(.3).timeout
    var shape:=CapsuleShape3D.new();shape.height=1.7;shape.radius=.25
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    observations["approaches"]=[]
    for offset in [Vector3(0,0,3),Vector3(-.6,0,2.9),Vector3(.6,0,2.9),Vector3(-.5,0,1)]:
        var foot:Vector3=learner.to_global(offset)
        var support:=floor_at(foot);query.transform.origin=foot+Vector3.UP*.9
        var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,12)
        var names:Array=[]
        for hit in hits:names.append(str(hit.collider.get_path()))
        observations.approaches.append({"foot":xyz(foot),"colliders":names,"support_y":support.position.y if not support.is_empty() else null})
        check("temporary learner approach supported and clear "+str(offset),not support.is_empty() and absf(support.position.y-foot.y)<.08 and hits.is_empty())
    check("native learner carries frozen point and twenty-five cells",learner.grid.cells.size()==25 and learner.control.position.is_equal_approx(Vector3(0,1.15,2.5)))
    await photo("student-table",learner)
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=learner.control.global_transform;learner.control.pick_up(pickup);await tick()
    await move_hand(controller,learner.to_global(Vector3(.32,1.12,.32)))
    check("actual pickup follows hand onto table address",learner.control.is_picked_up() and learner.selected_address()==Vector2i(3,1))
    await move_hand(controller,learner.to_global(Vector3(-.6,1.15,2.5)))
    check("held point names FACE, hover does not turn",learner.operation()=="FACE" and not learner.wall)
    learner.control.action();await tick()
    check("held trigger turns existing grid",learner.wall)
    await move_hand(controller,learner.to_global(Vector3(.6,1.88,.96)))
    check("held point finds same address on wall",learner.selected_address()==Vector2i(3,1) and learner.label.text.contains("source row 1, column 0"))
    await photo("student-wall",learner)
    await move_hand(controller,learner.to_global(Vector3(.6,1.15,2.5)));learner.control.action();await tick()
    check("held trigger enlarges intervals to forty-eight centimetres",learner.width_index==1 and learner.label.text.contains("SOURCE WIDTH 1.44 m"))
    await move_hand(controller,learner.to_global(Vector3(.6,1.72,1.44)))
    check("world hand still selects original source after resizing",learner.selected_address()==Vector2i(3,1) and learner.source==[[0,1,0],[0,0,1]])
    await photo("student-wall-wide",learner)
    learner.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("release retains inherited frozen behaviour",learner.control.freeze and not learner.control.is_picked_up())
    var place:Transform3D=learner.transform;learner.hide();learner.queue_free();origin.queue_free();await tick()
    var transfer=load(spec.lesson.replace('/printed/','/narrower/')).new();transfer.transform=place;hall.add_child(transfer)
    transfer.toggle_face();transfer.toggle_width();await tick()
    transfer.control.global_position=transfer.to_global(Vector3(.6,1.84,1.08));transfer._process(0)
    check("separate narrower example selects same cell at new physical position",transfer.selected_address()==Vector2i(3,1) and transfer.label.text.contains("SOURCE WIDTH 1.08 m"))
    await photo("student-narrower",transfer)
    observations["learner"]={"source":spec.lesson,"temporary_hall_local":xyz(place.origin),"scope":"Temporary display in existing museum, actual XR Tools pickup/held action/release driven by a simulated controller. No physical headset claim."}
    transfer.queue_free();completed=true
func finish()->void:
    check("installed tunnel and learner comparison completed",completed)
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Real museum, installed pointer controls, temporary printed learner, simulated XR Tools input, standing-clearance samples. Not headset or human-learning certification."},"  "))
    quit(0 if failures.is_empty() else 1)
