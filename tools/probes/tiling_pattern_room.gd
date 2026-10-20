extends "res://doc/book/iterations/2026-09-28-pattern-a-facing-return/probe.gd"
var student_completed:=false
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true)
    await super.landing_checks()
    if not completed:return
    if driver:driver.release();driver.set_physics_process(false)
    if actor:actor.hide();actor.set_process(false);actor.set_physics_process(false);actor.global_position=Vector3(0,-100,0)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var script=load(spec.lesson)
    if script==null or not script.can_instantiate():check("printed learner loads",false);return
    var learner=script.new()
    learner.transform=hall.global_transform.affine_inverse()*ui.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0,3.2))
    hall.add_child(learner)
    var foot:Vector3=learner.to_global(Vector3(0,0,2.5))
    var support:=floor_at(foot)
    check("learner approach has floor support",not support.is_empty() and absf(support.position.y-foot.y)<.05)
    var capsule:=CapsuleShape3D.new();capsule.height=1.7;capsule.radius=.28
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1|4;query.transform.origin=foot+Vector3.UP*.88
    var overlaps:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
    check("learner approach has standing clearance",overlaps.is_empty())
    observations["learner_approach_colliders"]=[]
    for hit in overlaps:observations.learner_approach_colliders.append(str(hit.collider.get_path()))
    await create_timer(.3).timeout
    check("point retains initial pose after physics",learner.control.position.is_equal_approx(Vector3(0,1.15,1.9)))
    await student_photo("student-translation",learner)
    var source_before:Array=learner.source.duplicate(true)
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=learner.control.global_transform;learner.control.pick_up(pickup);await tick()
    await move_hand(controller,learner.to_global(Vector3(-.6,1.15,1.9)))
    check("simulated grip selects READ RULE",learner.control.is_picked_up() and learner.operation()=="READ RULE")
    check("hover changes neither stored source nor reader",learner.source==source_before and not learner.reflected)
    learner.control.action();await tick()
    check("held action reflects the read without mutating source",learner.reflected and learner.source==source_before and learner.value_at(Vector2i(3,1))==1)
    await student_photo("student-reflection",learner)
    await move_hand(controller,learner.to_global(Vector3(.6,1.15,1.9)))
    check("held point selects FLIP SOURCE",learner.operation()=="FLIP SOURCE")
    learner.control.action();await tick()
    check("source flip leaves reader on and changes stored row",learner.reflected and learner.source==[[0,1,0],[1,0,0]] and learner.value_at(Vector2i(3,1))==0)
    await student_photo("student-source-flipped",learner)
    learner.control.action();await tick()
    check("second source flip restores starting rows",learner.source==source_before and learner.reflected)
    await move_hand(controller,learner.grid.to_global(Vector3(.96,.33,.32)))
    check("held point selects reflected source column two",learner.selected_address()==Vector2i(3,1) and learner.label.text.contains("source row 1, column 2"))
    learner.control.action();await tick()
    check("reflected painting edits original column two",learner.source==[[0,1,0],[0,0,2]])
    await student_photo("student-reflected-edit",learner)
    await move_hand(controller,learner.to_global(Vector3(0,1.15,1.9)))
    var kept:Array=learner.source.duplicate(true);learner.control.action();await tick()
    check("neutral hand position performs no operation",learner.source==kept and learner.reflected)
    learner.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("release retains inherited frozen behaviour",learner.control.freeze and not learner.control.is_picked_up())
    var location:Transform3D=learner.transform
    learner.hide();learner.queue_free();origin.queue_free();await tick()
    var transfer=load(spec.lesson.replace('/printed/','/symmetric/')).new();transfer.transform=location;hall.add_child(transfer)
    var colours:Array=[]
    for i in 25:colours.append(transfer.grid.instances.get_instance_color(i))
    var sym_source:Array=transfer.source.duplicate(true)
    transfer.toggle_reader();await tick()
    var identical:=true
    for i in 25:identical=identical and transfer.grid.instances.get_instance_color(i)==colours[i]
    check("separate symmetric program hides reflected rule in its colours",transfer.reflected and transfer.source==sym_source and identical)
    transfer.flip_source();check("symmetric rows also conceal source reversal",transfer.source==sym_source)
    await student_photo("student-symmetric",transfer)
    transfer.edit(Vector2i(3,1));transfer.toggle_reader();await tick()
    check("breaking symmetry reveals the read difference",transfer.source==[[0,1,0],[2,0,0]] and not transfer.reflected and transfer.value_at(Vector2i(3,1))==2)
    observations["student"]={"printed":spec.lesson,"temporary_hall_local":xyz(location.origin),"relative_to_station":[0,0,3.2],"scope":"Temporary learner display inside the existing bay. Installed controls use pointer events; learner uses simulated XR Tools pickup and held action. No physical headset claim."}
    transfer.queue_free();student_completed=true
func move_hand(controller:Node3D,target:Vector3)->void:
    controller.global_position=target
    for i in 8:await tick()
func student_photo(title:String,s:Node3D)->void:
    await snapshot(title,s.to_global(Vector3(0,2.2,3.0)),s.to_global(Vector3(0,1,.7)),54)
func finish()->void:
    check("printed learner and symmetric transfer completed",student_completed)
    super.finish()
