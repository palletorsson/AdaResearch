extends "res://tools/probes/shader_state_museum.gd"
var study:Node3D
func settle_study()->void:
    var field=study.field
    while field.busy or field.pending_steps>0 or field.pending_reset>=0 or not field.brush_queue.is_empty():await process_frame
    await RenderingServer.frame_post_draw
func press(key:String)->void:
    study.buttons[key].get_node("InteractableAreaButton").button_pressed.emit(null)
func run()->void:
    var launcher=load("res://doc/book/studies/shaders-lineage/state_museum.gd")
    root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(150).timeout.connect(func():quit(98))
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
    museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
    launcher.configure(museum,output+"learner_control.json")
    var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output+"learner_control.json"))
    check(settings.first_map=="Shader_10_ReactionDiffusion" and not settings.has("travel"),"Launcher selects State without stale travel")
    museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
    while not bool(museum.get("_museum_core_ready")):await process_frame
    museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
    for node in museum.get_children():
        if node is Node3D and str(node.get_meta("em_map",""))=="Shader_10_ReactionDiffusion":hall=node
    check(hall!=null,"Actual State hall loads")
    if hall==null:quit(1);return
    var old:Camera3D=museum.get("_cam")
    if old:
        for timer in old.find_children("*","Timer",true,false):timer.stop()
    study=launcher.mount(hall,launcher.LESSON)
    check(study!=null,"Launcher mounts exact printed program beside retained-state chamber")
    if study==null:quit(1);return
    chamber=study.get_parent();origin=chamber.global_position-hall.global_basis*Vector3(12.5,0,12.5)
    camera=Camera3D.new();root.add_child(camera);await tick();await settle_study()
    var field=study.field
    check(study.control.is_inside_tree() and study.cube.is_inside_tree() and study.readout.is_inside_tree(),"Learner creates own point, cube, field and readout")
    check(study.find_children("*","Camera3D",true,false).is_empty(),"Learner relies on museum camera")
    var museum_state:PackedByteArray=chamber.field.state_texture.get_image().get_data()
    check(field!=chamber.field and study.material!=chamber.material,"Learner and installed wall have separate records")
    var supported:=true;var clear:=true;var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.24
    var path:Array[Vector3]=[Vector3(0,0,6.9),Vector3(4,0,6.9),Vector3(5.5,0,6.9),Vector3(5.5,0,5.3)]
    for i in range(1,path.size()):
        var n:=ceili(path[i-1].distance_to(path[i])/.25)
        for j in range(n+1):
            var p:Vector3=chamber.to_global(path[i-1].lerp(path[i],float(j)/n))
            var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.3,p-Vector3.UP*.7,1);ray.exclude=[museum.get("_player").get_rid()]
            supported=supported and not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
            var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.86;query.exclude=ray.exclude
            var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
            for hit in hits:print("BLOCKED ",hit.collider.get_path()," at ",chamber.to_local(p))
            clear=clear and hits.is_empty()
    check(supported,"Learner approach has floor every quarter metre")
    check(clear,"Standing body clears learner controls and side approach")
    press("CLEAR");await settle_study()
    var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
    hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
    check(study.control.is_picked_up(),"Carried point accepts synthetic XR pickup")
    hand.global_position=study.to_global(Vector3(-.3,2.0,1.2));await tick();study.control.action();await settle_study()
    var marked:Image=field.state_texture.get_image()
    check(field.decode(marked.get_pixel(33,24)).y>.99 and field.decode(marked.get_pixel(24,33)).y<.001,"Rotated hall maps held point to expected asymmetric XY address")
    study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check(study.control.freeze and field.state_texture.get_image().get_data()==marked.get_data(),"Release leaves point frozen and its mark retained")
    press("STEP");await settle_study()
    check(field.iterations==1 and field.state_texture.get_image().get_data()!=marked.get_data(),"Nearby STEP receiver updates the marked record")
    var held:PackedByteArray=field.state_texture.get_image().get_data();press("INK");await tick()
    check(study.alternate_ink and field.state_texture.get_image().get_data()==held,"INK receiver changes display without changing data")
    press("RUN/HOLD");await create_timer(.15).timeout;press("RUN/HOLD");await settle_study()
    check(field.iterations>1 and not field.running,"RUN/HOLD receivers advance and then retain the field")
    press("RESET");await settle_study()
    check(field.iterations==0 and not field.running,"RESET receiver restores held seed")
    check(chamber.field.state_texture.get_image().get_data()==museum_state,"Learner controls leave installed wall's record unchanged")
    check(chamber.receivers.size()==3 and chamber.receivers.all(func(n):return n.material_override==chamber.material),"Existing wall, sphere and cube remain intact")
    var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(-.6,.9,1)),study.to_global(Vector3(-.6,.9,-1)),1)
    await physics_frame;var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
    check(not hit.is_empty() and hit.collider==study.cube,"Learner cube remains solid in the museum")
    # Grow both separate fields to show their relation at equal model counts.
    field.step(6000);chamber.field.step(6000);await settle_study();await settle()
    check(field.state_texture.get_image().get_data()==chamber.field.state_texture.get_image().get_data(),"Learner and installed solver agree after equal seeded 6000 steps")
    check(study.material.get_shader_parameter("state_texture")==field.state_texture,"Finished texture reaches learner receivers")
    museum.get("_player").hide();xr.queue_free();await tick()
    var offset:Vector3=study.position
    await photo("student",offset+Vector3(1.15,1.9,3.1),offset+Vector3(0,1.35,0),75)
    press("INK");await photo("other-ink",offset+Vector3(1.15,1.9,3.1),offset+Vector3(0,1.35,0),75)
    await photo("in-the-hall",Vector3(8,3.3,9),Vector3(0,2.4,-1.7),88)
    await photo("wall",Vector3(.6,1.7,2),Vector3(0,3,-3.8),95)
    var passed:bool=checks.all(func(c):return c.passed)
    var out:=FileAccess.open(output+"report.json",FileAccess.WRITE);out.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Exact learner mounted in real museum; synthetic pickup/action/release and press receivers; GPU field and route checks. No independent student, physical headset, human learning or onward travel claim."},"\t"));out.close();quit(0 if passed else 1)
