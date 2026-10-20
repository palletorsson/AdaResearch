extends "res://tools/probes/qfep_introduction_student.gd"

func ticks(n: int) -> void:
    for i in n:
        await physics_frame
        await process_frame

func positions(body: SoftBody3D) -> PackedVector3Array:
    var result := PackedVector3Array()
    var vertices: PackedVector3Array=body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    for i in vertices.size():result.append(body.get_point_transform(i))
    return result

func difference(a: PackedVector3Array,b: PackedVector3Array) -> float:
    var result:=0.0
    for i in a.size():result=maxf(result,a[i].distance_to(b[i]))
    return result

func set_hand(study: Node3D, term: int, fraction: float) -> void:
    study.buttons[term].pressed.emit()
    await drag(study,Vector3(-1.12,study.LOW+fraction*study.TRAVEL,0.22))
    study.point.on_desktop_drop(study)
    await ticks(3)

func specimen(parent: Node3D, at: Vector3, stiffness: float) -> SoftBody3D:
    var body:=SoftBody3D.new()
    var mesh:=SphereMesh.new()
    mesh.radius=0.16
    mesh.height=0.32
    mesh.radial_segments=16
    mesh.rings=12
    body.mesh=mesh
    body.linear_stiffness=stiffness
    body.total_mass=0.5
    body.simulation_precision=8
    body.pressure_coefficient=1.2
    body.damping_coefficient=0.1
    body.collision_layer=0
    body.collision_mask=0
    body.set_point_pinned(0,true)
    body.position=at
    parent.add_child(body)
    return body

func relative_positions(body: SoftBody3D) -> PackedVector3Array:
    var result:=positions(body)
    var origin:Vector3=result[0]
    for i in result.size():result[i]-=origin
    return result

func engine_comparison() -> Dictionary:
    var host:=Node3D.new()
    root.add_child(host)
    var a:=specimen(host,Vector3(0,10,0),0.5)
    var b:=specimen(host,Vector3(2,10,0),0.5)
    var c:=specimen(host,Vector3(4,10,0),0.1)
    var d:=specimen(host,Vector3(6,10,0),0.9)
    # Different properties after creation; no mesh recreation or space reset.
    a.linear_stiffness=0.1
    b.linear_stiffness=0.9
    await ticks(2)
    for body in [a,b,c,d]:body.apply_central_impulse(Vector3(0.08,0,0))
    await ticks(40)
    var live:=difference(relative_positions(a),relative_positions(b))
    var built:=difference(relative_positions(c),relative_positions(d))
    check("runtime stiffness readbacks can differ without changing matched motion",is_equal_approx(a.linear_stiffness,0.1) and is_equal_approx(b.linear_stiffness,0.9) and live<0.0001)
    check("stiffness set before construction changes physical response",built>0.001 and built>live*10.0)
    host.free()
    return {"runtime_change_difference":live,"construction_difference":built}

func run() -> void:
    var args:=OS.get_cmdline_user_args()
    var folder:String=args[0]
    receipt=args[1]
    load(folder+"morphology_checks.gd").new().run()
    check("prepared project selects Jolt",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
    var parent:=Node3D.new()
    parent.position=Vector3(12,3,-7)
    parent.rotation=Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study=load(folder+"synthesis_study.gd").new()
    parent.add_child(study)
    study.set_process(false)
    await ticks(3)
    check("initialized coefficients and five actions",study.buttons.size()==5 and study.readout.text.contains("Stiffness request 0.500") and is_equal_approx(study.body.damping_coefficient,0.1005))
    var walls:=0
    for child in study.get_children():
        if child is StaticBody3D:walls+=1
    check("explicit soft mesh and six fixed boundaries",study.body is SoftBody3D and study.body.mesh!=null and walls==6)
    check("control sphere excluded from soft-body contacts",(study.body.collision_mask & study.point.collision_layer)==0)
    var point_id:int=study.point.get_instance_id()
    var body_id:int=study.body.get_instance_id()
    var mesh_id:int=study.body.mesh.get_instance_id()
    await set_hand(study,0,0.2)
    await set_hand(study,1,0.9)
    var r:Dictionary=study.model.reading()
    check("independent first pair formed through local hand height",is_equal_approx(r.values[0],0.2) and is_equal_approx(r.values[1],0.8))
    check("independent first live pressure and damping reach receiver",is_equal_approx(study.body.pressure_coefficient,1.2) and absf(study.body.damping_coefficient-0.0209)<0.00001)
    check("requested drag .03 reads back zero on this backend",is_equal_approx(r.drag,0.03) and study.body.drag_coefficient==0.0)
    study.buttons[4].pressed.emit()
    var kept:Dictionary=study.model.kept.duplicate(true)
    await set_hand(study,0,0.8)
    await set_hand(study,1,0.1)
    check("independent second pair retains pressure while changing damping",is_equal_approx(study.body.pressure_coefficient,1.2) and is_equal_approx(study.body.damping_coefficient,0.1801) and study.body.drag_coefficient==0.0)
    check("KEEP does not follow later values",study.model.kept==kept)
    await set_hand(study,0,0.5)
    var stiffness:float=study.body.linear_stiffness
    var baseline:float=study.model.reading().baseline
    await set_hand(study,1,1.0)
    check("phi leaves stiffness and pressure baseline unchanged",is_equal_approx(study.body.linear_stiffness,stiffness) and study.model.reading().baseline==baseline)
    check("pulse is active at the midpoint",study.model.active())
    var before:=positions(study.body)
    study.buttons[2].pressed.emit()
    var after:=positions(study.body)
    check("STEADY changes pressure without rewriting vertices",difference(before,after)<0.00001 and is_equal_approx(study.body.pressure_coefficient,1.5) and not study.model.pulsing)
    study.buttons[3].pressed.emit()
    before=positions(study.body)
    await ticks(45)
    after=positions(study.body)
    var motion:float=difference(before,after)
    check("real Jolt vertices move under steady pressure after NUDGE",motion>0.001 and is_equal_approx(study.body.pressure_coefficient,1.5))
    var finite:=true
    for pos in after:finite=finite and pos.is_finite()
    check("physical response remains finite",finite)
    var state:Dictionary=study.model.reading()
    study.redraw()
    check("redraw does not advance model time",study.model.reading()==state)
    await drag(study,Vector3(1,study.LOW+study.TRAVEL+1,0))
    check("upper hand range clamps signed phi",study.model.values[1]==1.0)
    var held_values:Array=study.model.values.duplicate()
    var held_mode:bool=study.model.pulsing
    for button in study.buttons:button.pressed.emit()
    check("button actions wait for release",study.selected==1 and study.model.values==held_values and study.model.pulsing==held_mode and study.model.kept==kept)
    await drag(study,Vector3(1,study.LOW-1,0))
    check("lower hand range clamps signed phi",study.model.values[1]==-1.0)
    study.point.on_desktop_drop(study)
    await ticks(3)
    check("same sphere soft body and mesh retained",study.point.get_instance_id()==point_id and study.body.get_instance_id()==body_id and study.body.mesh.get_instance_id()==mesh_id)
    check("inherited parking survives physics override",study.point.position.distance_to(study.point_home)<0.001)
    # Test installed property mappings without constructing unrelated museum apparatus.
    var original=load("res://commons/artifacts/queer_morphology_specimen/queer_morphology_specimen.gd").new()
    original._soft_body=SoftBody3D.new()
    var matched:=true
    for l:float in [0.0,0.2,0.3,0.5,0.7,0.8,1.0]:
        for p:float in [-1.0,0.0,1.0]:
            for pulse:bool in [false,true]:
                original.breathing_enabled=pulse
                original._breathing_time=1.7
                original.lambda=l
                original.phi=p
                study.model.set_value(0,l)
                study.model.set_value(1,p)
                study.model.pulsing=pulse
                study.model.elapsed=1.7
                study.model.apply_to(study.body)
                matched=matched and is_equal_approx(study.body.linear_stiffness,original._soft_body.linear_stiffness)
                matched=matched and is_equal_approx(study.body.pressure_coefficient,original._soft_body.pressure_coefficient)
                matched=matched and is_equal_approx(study.body.damping_coefficient,original._soft_body.damping_coefficient)
                matched=matched and is_equal_approx(study.body.drag_coefficient,original._soft_body.drag_coefficient)
    check("forty-two parameter and mode combinations match installed mappings",matched)
    original._soft_body.free()
    original.free()
    parent.free()
    await process_frame
    var comparison:Dictionary=await engine_comparison()
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"maximum_vertex_movement":motion,"engine_comparison":comparison,"scope":"Fresh printed code; author-operated synthetic inputs and Jolt motion, not independent learner understanding, headset reach or identical physical trajectories."},"  "))
    quit(0 if failures.is_empty() else 1)
