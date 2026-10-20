extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON="res://doc/book/iterations/2026-10-12-qfep-a-body-keeps-moving/learner/synthesis_study.gd"
const LAUNCHER="res://doc/book/studies/qfep-lineage/synthesis_museum.gd"

func positions(body: SoftBody3D) -> PackedVector3Array:
    var result:=PackedVector3Array()
    var vertices:PackedVector3Array=body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    for i in vertices.size():result.append(body.get_point_transform(i))
    return result

func difference(a: PackedVector3Array,b: PackedVector3Array) -> float:
    var result:=0.0
    for i in a.size():result=maxf(result,a[i].distance_to(b[i]))
    return result

func hand(study: Node3D,term: int,fraction: float) -> void:
    study.buttons[term].pressed.emit()
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position=study.to_global(Vector3(-1.12,study.LOW+fraction*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()
    study.redraw()

func press(original: Node3D,index: int) -> void:
    original._control_panel.find_child("Btn_%d" % index,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)

func photo(study: Node3D,name: String) -> void:
    study.redraw()
    await snapshot(name,study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)

func landing_checks() -> void:
    var start:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original:=find_scene("/queer_morphology_specimen.gd")
    check("installed specimen and local controls retained",original!=null and original._soft_body!=null and original._lambda_slider!=null and original._phi_slider!=null)
    if original==null:return
    press(original,1)
    check("installed PAIR B supplies declared values",is_equal_approx(original.lambda,0.5) and is_zero_approx(original.phi) and is_equal_approx(original._pressure_baseline,1.5))
    var clock:float=original._breathing_time
    await create_timer(0.15).timeout
    check("installed pressure clock advances on physics frames",original._breathing_time>clock)
    var before:=positions(original._soft_body)
    press(original,3)
    check("installed STEADY preserves positions at the operation",not original.breathing_enabled and is_equal_approx(original._soft_body.pressure_coefficient,1.5) and difference(before,positions(original._soft_body))<0.00001)
    original._lambda_slider.set_normalized_value(0.2)
    original._lambda_slider.slider_moved.emit(0.0)
    original._phi_slider.set_normalized_value(0.9)
    original._phi_slider.slider_moved.emit(0.0)
    check("installed rail callbacks reach pressure and damping",is_equal_approx(original._pressure_baseline,1.2) and is_equal_approx(original._soft_body.damping_coefficient,0.0209))
    check("installed drag request also remains unused",is_zero_approx(original._soft_body.drag_coefficient))
    original._update_state_label()
    check("installed plate shows property readbacks",original._live_values.text.contains("drag 0.000") and original._live_values.text.contains("pressure base 1.200"))
    await snapshot("existing",original.to_global(Vector3(1.1,1.15,1.9)),original.to_global(Vector3(0.15,0.45,0)),65)
    var held_original:Array=[original.lambda,original.phi]
    var launcher=load(LAUNCHER)
    var study=launcher.mount(hall,load(LESSON))
    study.set_process(false)
    await tick()
    var bodies:Array[RID]=[]
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner bay has supported clear approach",placeable(study.transform,bodies))
    var bounds:AABB=hall.global_transform*study.transform*AABB(Vector3(-1.48,0.88,-0.98),Vector3(2.96,1.7,1.96))
    check("learner bench does not overlap original specimen",not bounds.intersects(museum.call("_seat_extent",original)))
    var separate:=true
    for child in hall.find_children("*","Node3D",true,false):
        if child.has_meta("artifact_lookup_name"):
            separate=separate and not bounds.intersects(museum.call("_seat_extent",child))
    check("learner bench separated from all retained artifact bounds",separate)
    var packed=load("res://doc/book/studies/qfep-lineage/synthesis.tscn").instantiate()
    check("F6 scene references tested launcher",packed.get_script()==launcher)
    packed.free()
    check("working copy belongs to real hall",study.get_parent()==hall and study.buttons.size()==5)
    var point_id:int=study.point.get_instance_id()
    var body_id:int=study.body.get_instance_id()
    await photo(study,"opening")
    before=positions(study.body)
    study.buttons[2].pressed.emit()
    check("learner steady operation preserves current vertices",not study.model.active() and difference(before,positions(study.body))<0.00001)
    study.buttons[3].pressed.emit()
    before=positions(study.body)
    await create_timer(0.3).timeout
    check("native mesh keeps moving under steady pressure",difference(before,positions(study.body))>0.001 and is_equal_approx(study.body.pressure_coefficient,1.5))
    await photo(study,"steady")
    await hand(study,0,0.2)
    await hand(study,1,0.9)
    study.buttons[4].pressed.emit()
    var kept:Dictionary=study.model.kept.duplicate(true)
    check("native first independent pair reaches body",is_equal_approx(study.body.pressure_coefficient,1.2) and absf(study.body.damping_coefficient-0.0209)<0.00001)
    check("native readout exposes backend limits",study.readout.text.contains("built 0.500") and study.readout.text.contains("Drag request 0.030 / engine 0.000 (unused)"))
    study.buttons[3].pressed.emit()
    await photo(study,"comparison-a")
    await hand(study,0,0.8)
    await hand(study,1,0.1)
    check("native second pair keeps pressure with different damping",is_equal_approx(study.body.pressure_coefficient,1.2) and absf(study.body.damping_coefficient-0.1801)<0.00001)
    check("native KEEP stays separate from current settings",study.model.kept==kept and study.model.values!=kept.values)
    study.buttons[3].pressed.emit()
    await photo(study,"comparison-b")
    check("same inherited sphere and soft receiver retained",study.point.get_instance_id()==point_id and study.body.get_instance_id()==body_id and study.point.position.distance_to(study.point_home)<0.001)
    check("learner does not broadcast to installed specimen",held_original==[original.lambda,original.phi])
    var inside:=true
    for pos in positions(study.body):
        var local:Vector3=study.to_local(pos)
        inside=inside and local.x>=-0.19 and local.x<=0.99 and local.y>=0.96 and local.y<=1.68 and absf(local.z)<=0.49
    check("simulated vertices remain inside outlined boundaries",inside)
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    observations.comparison={"kept":kept,"current":study.model.reading(),"built_stiffness":study.built_stiffness,"engine_drag":study.body.drag_coefficient}
    await snapshot("hall",study.to_global(Vector3(-1,3.2,3)),study.to_global(Vector3(-0.8,1.0,-2)),85)
    observations.tested_code={}
    for file in ["morphology_map.gd","synthesis_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path:String=LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://doc/book/studies/qfep-lineage/synthesis.tscn","res://commons/artifacts/queer_morphology_specimen/queer_morphology_specimen.gd","res://commons/maps/QFEP_Synthesis/map_data.json","res://tools/probes/qfep_synthesis_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Actual museum and freshly printed code. Synthetic hands, rails, buttons; actual ongoing soft-body physics. No physical headset, independent learner or complete route validation. No identical trajectory claim."
