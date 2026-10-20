extends "res://tools/probes/transformation_encounters.gd"
func press(ui:Node3D,id:String)->void:
    var area:Node3D=ui.buttons[id].get_node("InteractableAreaButton")
    XRToolsPointerEvent.pressed(camera,area,area.global_position)
    XRToolsPointerEvent.released(camera,area,area.global_position)
    await tick()
func move_hand(controller:Node3D,p:Vector3)->void:
    controller.global_position=p
    for i in 8:await tick()
func photo(name:String,s:Node3D)->void:
    await snapshot(name,s.to_global(Vector3(0,2.6,5.4)),s.to_global(Vector3(0,1.5,.3)),55)
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true);root.size=Vector2i(1440,1000)
    var context:Node3D;var carrier:Node3D
    for i in 3600:
        for n in hall.find_children("*","Node3D",true,false):
            if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/carrier_comparison.gd"):
                if n.mode=="carrier":carrier=n
                else:context=n
        if context!=null and carrier!=null and carrier.material!=null and context.bridge!=null:break
        await process_frame
    museum.call("flush_stamps");await create_timer(.6).timeout
    var player:Node3D=museum.get("_player")
    if player:player.hide();player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    check("both installed comparisons loaded",context!=null and carrier!=null)
    if context==null or carrier==null:return
    observations["context_world"]=xyz(context.global_position);observations["carrier_world"]=xyz(carrier.global_position)
    var grey:=Color(.5,.5,.5)
    check("installed targets and connector assigned same unshaded grey",context.samples.all(func(v):return v.material_override.albedo_color==grey and v.material_override.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED) and context.bridge.material_override.albedo_color==grey)
    var positions:Array=[]
    for v in context.samples:positions.append(v.transform)
    await snapshot("installed-context",context.to_global(Vector3(0,2.3,8)),context.to_global(Vector3(0,1.6,0)),58)
    await press(context,"SWAP")
    check("real SWAP exchanges installed surrounds",context.swapped and context.backgrounds[0].material_override.albedo_color==Color(.9,.9,.9) and context.backgrounds[1].material_override.albedo_color==Color(.1,.1,.1))
    await press(context,"SURROUNDS");await press(context,"CONNECT")
    check("real SURROUNDS and CONNECT retain grey target values",context.neutral and context.connected and context.bridge.visible and context.backgrounds.all(func(v):return v.material_override.albedo_color==grey) and context.samples.all(func(v):return v.material_override.albedo_color==grey))
    check("target bodies stay at same poses",context.samples[0].transform==positions[0] and context.samples[1].transform==positions[1])
    await snapshot("installed-equal",context.to_global(Vector3(0,2.3,8)),context.to_global(Vector3(0,1.6,0)),58)
    await press(context,"UNDO");check("real UNDO removes last connector change",not context.connected and context.neutral and context.swapped)
    await press(context,"RESET");check("real RESET restores context",not context.connected and not context.neutral and not context.swapped)
    check("plane and curve share one shader material",carrier.samples[0].material_override==carrier.samples[1].material_override)
    var texture:PackedByteArray=carrier.material.get_shader_parameter("motif").get_image().get_data()
    var arr:Array=carrier.samples[1].mesh.surface_get_arrays(0)
    var vertices:PackedVector3Array=arr[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arr[Mesh.ARRAY_NORMAL];var uv:PackedVector2Array=arr[Mesh.ARRAY_TEX_UV]
    var length:=0.0
    for i in 64:length+=vertices[(i+1)*2].distance_to(vertices[i*2])
    check("both carriers have four metre horizontal surface span",is_equal_approx(carrier.samples[0].mesh.size.x,4.0) and absf(length-4.0)<.002)
    check("curve UV spans open half-cylinder with distinct ends",uv[0]==Vector2.ZERO and uv[128]==Vector2(1,0) and vertices[0].distance_to(vertices[128])>2.5)
    await snapshot("installed-flat",carrier.to_global(Vector3(0,2.0,3.5)),carrier.to_global(Vector3(0,1.6,0)),110)
    await press(carrier,"REPEAT SIZE");await press(carrier,"GRID")
    check("repeat control halves physical horizontal repeat span",carrier.material.get_shader_parameter("repeats")==8.0 and carrier.material.get_shader_parameter("show_grid"))
    await snapshot("installed-spacing",carrier.to_global(Vector3(-.5,2.0,3.5)),carrier.to_global(Vector3(0,1.6,0)),110)
    await press(carrier,"FLAT / SHADED")
    var left:Vector3=carrier.material.get_shader_parameter("light_direction")
    await snapshot("installed-shaded-left",carrier.to_global(Vector3(0,2.0,3.5)),carrier.to_global(Vector3(0,1.6,0)),110)
    await press(carrier,"LIGHT SIDE")
    var right:Vector3=carrier.material.get_shader_parameter("light_direction")
    check("shader control changes side retaining y z magnitude",right.x==-left.x and right.y==left.y and right.z==left.z and is_equal_approx(right.length(),left.length()))
    check("plane unchanged alignment while curved edge reverses",is_equal_approx(Vector3.BACK.dot(left.normalized()),Vector3.BACK.dot(right.normalized())) and normals[0].dot(left.normalized())>normals[0].dot(right.normalized()))
    check("all carrier controls retain pixels and geometry",carrier.material.get_shader_parameter("motif").get_image().get_data()==texture and carrier.samples[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices)
    await snapshot("installed-shaded-right",carrier.to_global(Vector3(0,2.0,3.5)),carrier.to_global(Vector3(0,1.6,0)),110)
    await press(carrier,"UNDO");check("carrier UNDO recovers left direction",not carrier.right_light)
    await press(carrier,"RESET");check("carrier RESET recovers initial repeat and flat state",not carrier.shaded and not carrier.grid and not carrier.dense)
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var s=load(spec.lesson).new()
    s.transform=hall.global_transform.affine_inverse()*context.global_transform*Transform3D(Basis.IDENTITY,Vector3(6.8,0,3))
    hall.add_child(s);await create_timer(.3).timeout
    var capsule:=CapsuleShape3D.new();capsule.radius=.25;capsule.height=1.7
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1|4
    observations["approaches"]=[]
    for frame in [context,carrier,s]:
        var offset:=Vector3(0,0,3.5)
        var foot:Vector3=frame.to_global(offset);query.transform.origin=foot+Vector3.UP*.9
        var support:=floor_at(foot);var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,12)
        var names:Array=[]
        for hit in hits:names.append(str(hit.collider.get_path()))
        observations.approaches.append({"foot":xyz(foot),"colliders":names,"support_y":support.position.y if not support.is_empty() else null})
        check("supported clear approach "+str(frame.name),not support.is_empty() and absf(support.position.y-foot.y)<.08 and hits.is_empty())
    await photo("student-source",s)
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=s.control.global_transform;s.control.pick_up(pickup);await tick()
    await move_hand(controller,s.reference.to_global(Vector3(.32,.22,0)));s.control.action();await tick()
    check("held point selects pink for both targets",s.control.is_picked_up() and s.selected==Vector2i(1,0) and s.targets.all(func(v):return v.material_override.albedo_color==Color("fc62ad")))
    var kept:Array=s.source.duplicate(true)
    await move_hand(controller,s.to_global(Vector3(-.6,1.15,2.8)));s.control.action();await tick()
    check("held SWAP keeps both targets and source",s.swapped and s.targets.all(func(v):return v.material_override.albedo_color==Color("fc62ad")) and s.source==kept)
    await move_hand(controller,s.to_global(Vector3(.6,1.15,2.8)));s.control.action();await tick()
    check("held CONNECT shares pink connector",s.bridge.visible and s.bridge.material_override.albedo_color==Color("fc62ad"))
    await photo("student-connected",s)
    await move_hand(controller,s.to_global(Vector3(0,1.15,2.8)));s.control.action();await tick()
    check("held EQUAL matches surrounds and retains reference",s.equal and s.surrounds.all(func(v):return v.material_override.albedo_color==Color("fc62ad")) and s.reference.cells.size()==25)
    await photo("student-equal",s)
    s.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("point releases frozen",not s.control.is_picked_up() and s.control.freeze)
    var transform:Transform3D=s.transform;s.queue_free();await process_frame
    var edited=load(str(spec.lesson).replace('/printed/','/grey_mint/')).new();edited.transform=transform;hall.add_child(edited);await tick()
    check("independent grey comparison also runs inside museum",edited.targets.all(func(v):return v.material_override.albedo_color==grey))
    await photo("student-grey-edit",edited)
    edited.control.global_position=edited.reference.to_global(Vector3(.64,.22,.32));edited.control.action();await tick()
    check("independent source edit selects mint in museum",edited.targets.all(func(v):return v.material_override.albedo_color==Color("55f3cf")))
