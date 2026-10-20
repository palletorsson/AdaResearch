extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-where-the-value-arrives/learner/sandbox_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/sandbox_museum.gd"

func pair_is(values: Array, l: float, p: float) -> bool:
    return is_equal_approx(values[0],l) and is_equal_approx(values[1],p)

func move_handles(l: Node, p: Node, a: float, b: float) -> void:
    l._slider.slider_moved.emit(a*l.rail_length)
    p._slider.slider_moved.emit((b+1)*0.5*p.rail_length)

func press(wiring: Node, index: int) -> void:
    wiring.buttons[index].get_node("InteractableAreaButton").button_pressed.emit(null)

func hand(study: Node3D, term: int, fraction: float) -> void:
    study.buttons[term].pressed.emit()
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position=study.to_global(Vector3(-1.17,study.LOW+fraction*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()

func photo(study: Node3D, name: String) -> void:
    await snapshot(name,study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/qfep_reactor.gd")
    var l := find_scene("/lambda_slider.gd")
    var p := find_scene("/phi_slider.gd")
    var field := find_scene("/reactive_particle_field.gd")
    check("installed reactor handles and independent field retained",original!=null and l!=null and p!=null and field!=null)
    if original==null or l==null or p==null or field==null:return
    var wiring: Node3D=original._wiring_study
    check("only two same-hall sources bound and initially cut",wiring!=null and wiring.lambda_source==l and wiring.phi_source==p and not wiring.connected and not original.is_in_group("qfep_reactive"))
    if wiring==null:return
    original.set_process(false)
    var independent_values: Array=[field.current_lambda,field.current_phi]
    move_handles(l,p,0.85,0.7)
    check("installed offered values change while receiver holds",pair_is([l.lambda,p.phi],0.85,0.7) and pair_is([original.current_lambda,original.current_phi],0.4,0.0))
    check("installed readout reads both sides of the route",wiring.readout.text.contains("handles 0.85 / +0.70") and wiring.readout.text.contains("used 0.40 / +0.00"))
    press(wiring,0)
    var material: ParticleProcessMaterial=original.particle_system.process_material
    check("installed CONNECT delivers current inputs immediately",wiring.connected and pair_is([original.current_lambda,original.current_phi],0.85,0.7) and is_equal_approx(material.initial_velocity_max,0.44))
    var light: Color=original.core_mesh.material_override.albedo_color
    move_handles(l,p,0.85,-0.7)
    var dark: Color=original.core_mesh.material_override.albedo_color
    check("installed phi darkens colour without changing speed",dark.r<light.r and dark.g<light.g and dark.b<light.b and is_equal_approx(material.initial_velocity_max,0.44))
    press(wiring,0)
    move_handles(l,p,0.15,0.6)
    var phase: float=original.pulse_phase
    original._process(0.1)
    check("installed CUT keeps inputs while animation continues",not wiring.connected and pair_is([original.current_lambda,original.current_phi],0.85,-0.7) and original.pulse_phase!=phase)
    await snapshot("existing-cut",original.global_position+Vector3(2,2.2,-5.4),original.global_position+Vector3(0,-0.2,-1.4),80)
    press(wiring,0)
    check("installed reconnect sends present pair",pair_is([original.current_lambda,original.current_phi],0.15,0.6) and is_equal_approx(material.initial_velocity_max,0.16))
    # Repeat checks the CPU trace at matching steps, not GPU particle identity.
    move_handles(l,p,0.85,0.6)
    press(wiring,1)
    for i in 20:original._process(0.01)
    var first: Transform3D=original.core_mesh.transform
    phase=original.pulse_phase
    press(wiring,1)
    for i in 20:original._process(0.01)
    check("installed REPEAT reproduces CPU jitter with same steps",first==original.core_mesh.transform and phase==original.pulse_phase and pair_is([original.current_lambda,original.current_phi],0.85,0.6) and wiring.connected)
    check("independent particle field receives neither input",[field.current_lambda,field.current_phi]==independent_values)
    var field_time: float=field.time
    field._physics_process(0.1)
    check("independent field still advances its own time",field.time>field_time)
    await snapshot("existing",original.global_position+Vector3(2,2.2,-5.4),original.global_position+Vector3(0,-0.2,-1.4),80)
    # Missing local source fails closed; restoration does not auto-connect.
    var source_parent: Node=l.get_parent()
    source_parent.remove_child(l)
    check("missing local handle fails closed",not wiring.discover_sources() and not wiring.connected)
    source_parent.add_child(l)
    check("restored pair remains cut until explicit connection",wiring.discover_sources() and not wiring.connected)
    var held_original: Array=[original.current_lambda,original.current_phi]
    var launcher=load(LAUNCHER)
    var study=launcher.mount(hall,load(LESSON))
    study.set_process(false)
    await tick()
    var bodies: Array[RID]=[]
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner bay has supported clear approach",placeable(study.transform,bodies))
    var bench_bounds: AABB=hall.global_transform*study.transform*AABB(Vector3(-1.48,0.88,-0.98),Vector3(2.96,1.7,1.96))
    var separate:=true
    for node in [original,l,p,field]:
        var bounds: AABB=museum.call("_seat_extent",node)
        separate=separate and not bench_bounds.intersects(bounds)
    check("learner bench does not overlap the retained artifacts",separate)
    var packed=load("res://doc/book/studies/qfep-lineage/sandbox.tscn").instantiate()
    check("F6 scene uses tested launcher",packed.get_script()==launcher)
    packed.free()
    check("working copy belongs to real hall",study.get_parent()==hall and study.buttons.size()==5)
    var id: int=study.point.get_instance_id()
    var cube_id: int=study.cube.get_instance_id()
    await hand(study,0,0.85)
    await hand(study,1,0.85)
    study.buttons[4].pressed.emit()
    var kept: Dictionary=study.model.kept.duplicate(true)
    check("native CUT shows different offered and used pairs",pair_is(study.model.offered,0.85,0.7) and pair_is(study.receiver.values,0.4,0.0))
    study.buttons[3].pressed.emit()
    study._process(1.0)
    await photo(study,"cut")
    study.buttons[2].pressed.emit()
    study.buttons[3].pressed.emit()
    study._process(1.0)
    check("native CONNECT moves cube with newly received speed",pair_is(study.receiver.values,0.85,0.7) and is_equal_approx(study.receiver.distance,0.44))
    await photo(study,"connected")
    study.buttons[2].pressed.emit()
    await hand(study,0,0.15)
    await hand(study,1,0.8)
    study.buttons[3].pressed.emit()
    study._process(1.0)
    check("native CUT and REPEAT preserve used pair and motion",not study.model.connected and pair_is(study.model.offered,0.15,0.6) and pair_is(study.receiver.values,0.85,0.7) and is_equal_approx(study.receiver.distance,0.44))
    await photo(study,"held")
    study.buttons[2].pressed.emit()
    study.buttons[3].pressed.emit()
    study._process(1.0)
    check("native reconnect uses current offered pair",pair_is(study.receiver.values,0.15,0.6) and is_equal_approx(study.receiver.distance,0.16))
    check("native KEEP preserves earlier disagreement",study.model.kept==kept)
    await photo(study,"reconnected")
    study.set_process(true)
    var elapsed: float=study.receiver.elapsed
    await create_timer(0.2).timeout
    study.set_process(false)
    check("learner also advances with real process frames",study.receiver.elapsed>elapsed)
    check("same point and cube persist after frames",study.point.get_instance_id()==id and study.cube.get_instance_id()==cube_id and study.point.position.distance_to(study.point_home)<0.001)
    check("learner does not broadcast to installed objects",[original.current_lambda,original.current_phi]==held_original and [field.current_lambda,field.current_phi]==independent_values)
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    observations.comparison={"kept":kept,"current":study.model.reading()}
    await snapshot("hall",study.to_global(Vector3(-1,3.2,3)),study.to_global(Vector3(-0.8,1.0,-2.0)),85)
    observations.tested_code={}
    for file in ["routed_receiver.gd","input_route.gd","sandbox_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String=LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://doc/book/studies/qfep-lineage/sandbox.tscn","res://commons/interfaces/qfep/qfep_reactor.gd","res://commons/interfaces/qfep/sandbox_wiring_study.gd","res://commons/interfaces/qfep/lambda_slider.gd","res://commons/interfaces/qfep/phi_slider.gd","res://commons/interfaces/qfep/reactive_particle_field.gd","res://commons/maps/QFEP_Sandbox/map_data.json","res://tools/probes/qfep_sandbox_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Actual museum, fresh printed code, synthetic rail/button/hand events. Automatic animation paused for matched-step comparisons and captures; learner also checked on process frames. No independent reader, headset, complete walking-route or GPU-particle identity claim."
