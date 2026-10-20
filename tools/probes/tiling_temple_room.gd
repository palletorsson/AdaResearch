extends "res://tools/probes/transformation_encounters.gd"
var temple:Node3D
var panel:Node3D
func press(text:String)->void:
    for item in panel._items:
        if item.label==text:
            var area:Node3D=item.node.get_node("InteractableAreaButton")
            XRToolsPointerEvent.pressed(camera,area,area.global_position)
            XRToolsPointerEvent.released(camera,area,area.global_position)
            await tick();return
    check("button exists: "+text,false)
func move_hand(controller:Node3D,p:Vector3)->void:
    controller.global_position=p
    for i in 8:await tick()
func photo(name:String,s:Node3D)->void:
    await snapshot(name,s.to_global(Vector3(0,2.5,4.8)),s.to_global(Vector3(0,1.35,.4)),55)
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true);root.size=Vector2i(1440,1000)
    var grid:Node3D=hall.get_node_or_null("SimGrid_Pattern_Temple")
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
    temple=find_scene("/pattern_temple.gd")
    check("installed temple loaded",temple!=null)
    if temple==null:return
    observations["temple_world"]=xyz(temple.global_position)
    for n in temple.find_children("*","Node3D",true,false):
        if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/control_panel.gd"):panel=n;break
    check("temple has eight grouped receivers and eight real controls",temple.materials.size()==8 and panel!=null and panel._items.size()==8)
    var ids:Array=[];var coherent:=true
    for i in 8:
        ids.append(temple.materials[i].get_instance_id())
        for mesh in temple.meshes[i]:coherent=coherent and mesh.material_override==temple.materials[i]
    var unique:Dictionary={}
    for id in ids:unique[id]=true
    check("materials independent across groups, shared within group",unique.size()==8 and coherent)
    var start:Array=temple.dressing.duplicate(true);var target:int=temple.target
    await snapshot("court-before",temple.to_global(Vector3(0,1.7,-5.8)),temple.to_global(Vector3(0,3.1,2.5)),76)
    await press("TARGET")
    var selected:int=(target+1)%8
    check("real TARGET changes selection without changing recipes",temple.target==selected and temple.dressing==start and temple.marker.position==temple.marks[selected])
    await press("SOURCE");await press("PALETTE");await press("SEED")
    var local_only:=true
    for i in 8:
        if i!=selected:local_only=local_only and temple.dressing[i]==start[i]
    check("SOURCE PALETTE SEED callbacks edit only selected group",local_only and temple.dressing[selected].source==(start[selected].source+1)%temple.sources.size() and temple.dressing[selected].palette==(start[selected].palette+1)%4 and temple.dressing[selected].seed==1)
    await press("ALL")
    var copied:Array=temple.dressing.duplicate(true);var equal:=true
    for i in 8:equal=equal and copied[i]==copied[selected]
    check("ALL copies selected recipe to every group",equal)
    await snapshot("court-all",temple.to_global(Vector3(0,1.7,-5.8)),temple.to_global(Vector3(0,3.1,2.5)),76)
    await press("PALETTE")
    local_only=true
    for i in 8:
        if i!=selected:local_only=local_only and temple.dressing[i]==copied[i]
    check("later palette edit stays local after ALL",local_only and temple.dressing[selected].palette!=copied[selected].palette)
    check("ALL never replaces the group materials",temple.materials[selected].get_instance_id()==ids[selected] and temple.materials[0].get_instance_id()==ids[0])
    await press("AGE");check("AGE changes selected weather parameters",temple.dressing[selected].age==1 and is_equal_approx(float(temple.materials[selected].get_shader_parameter("stain_amount")),.15))
    var before_clean:Array=temple.dressing.duplicate(true)
    await press("CLEAN")
    var clean:=true
    for i in 8:
        clean=clean and temple.dressing[i].age==0
        before_clean[i].age=0
    check("CLEAN resets age only, not source or palette",clean and temple.dressing==before_clean)
    await snapshot("court-one-different",temple.to_global(Vector3(0,2.8,-5.3)),temple.to_global(Vector3(1,3.6,1)),82)
    await snapshot("desk",panel.to_global(Vector3(0,.6,1.4)),panel.global_position,53)
    # Restore only this isolated runtime. Production files are never edited.
    temple.dressing=start.duplicate(true);temple.target=target
    for i in 8:temple._dress(i)
    temple._move_marker()
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var s=load(spec.lesson).new()
    s.transform=hall.global_transform.affine_inverse()*temple.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0,1))
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
    await photo("student-independent",s)
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=s.control.global_transform;s.control.pick_up(pickup);await tick()
    await move_hand(controller,s.receivers[0].to_global(Vector3(.96,.3,0)))
    check("held point selects table address",s.control.is_picked_up() and s.selected_address()==Vector2i(3,0))
    s.control.action();await tick()
    check("held trigger paints table only",s.recipes[0].source[1][2]==2 and s.recipes[1].source[1][2]==1)
    await photo("student-table-painted",s)
    await move_hand(controller,s.to_global(Vector3(.6,1.15,2.5)));s.control.action();await tick()
    check("held ALL copies recipe",s.recipes[0]==s.recipes[1])
    await photo("student-copied",s)
    await move_hand(controller,s.to_global(Vector3(-.6,1.15,2.5)));s.control.action();await tick()
    await move_hand(controller,s.receivers[1].to_global(Vector3(.96,.3,0)))
    check("held point reads wall in its own frame",s.target==1 and s.selected_address()==Vector2i(3,0))
    s.control.action();await tick()
    check("held wall edit after copying leaves table intact",s.recipes[1].source[1][2]==0 and s.recipes[0].source[1][2]==2)
    await photo("student-diverged",s)
    s.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("released point stays available",not s.control.is_picked_up() and s.control.freeze)
