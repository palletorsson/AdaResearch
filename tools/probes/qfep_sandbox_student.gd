extends "res://tools/probes/qfep_introduction_student.gd"

func set_hand(study: Node3D, term: int, fraction: float) -> void:
    study.buttons[term].pressed.emit()
    await drag(study,Vector3(2,study.LOW+fraction*study.TRAVEL,-2))
    study.point.on_desktop_drop(study)
    for i in 3:await physics_frame

func pair_is(values: Array, l: float, p: float) -> bool:
    return is_equal_approx(values[0],l) and is_equal_approx(values[1],p)

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"route_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position=Vector3(12,3,-7)
    parent.rotation=Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study = load(folder+"sandbox_study.gd").new()
    parent.add_child(study)
    study.set_process(false)
    await process_frame
    check("initialized CUT state and separate labels",not study.model.connected and study.offered_label.text.contains("0.40") and study.used_label.text.contains("0.40"))
    check("five declared actions and explicit receiver",study.buttons.size()==5 and study.model.receiver==study.receiver)
    var point_id: int=study.point.get_instance_id()
    var cube_id: int=study.cube.get_instance_id()
    await set_hand(study,0,0.85)
    await set_hand(study,1,0.85)
    check("local hand changes offered pair while CUT holds used pair",pair_is(study.model.offered,0.85,0.7) and study.receiver.values==[0.4,0.0])
    study.buttons[4].pressed.emit()
    var kept: Dictionary=study.model.kept.duplicate(true)
    study.buttons[2].pressed.emit()
    check("CONNECT immediately delivers present pair",study.model.connected and pair_is(study.receiver.values,0.85,0.7) and is_equal_approx(study.receiver.speed(),0.44))
    var light: Color=study.cube.material_override.albedo_color
    await set_hand(study,1,0.15)
    var dark: Color=study.cube.material_override.albedo_color
    check("phi changes received lightness alone",pair_is(study.receiver.values,0.85,-0.7) and dark.r<light.r and dark.g<light.g and dark.b<light.b and is_equal_approx(study.receiver.speed(),0.44))
    study.buttons[2].pressed.emit()
    await set_hand(study,0,0.15)
    await set_hand(study,1,0.8)
    check("CUT retains earlier received pair through new offers",not study.model.connected and pair_is(study.receiver.values,0.85,-0.7) and pair_is(study.model.offered,0.15,0.6))
    study.buttons[3].pressed.emit()
    check("REPEAT resets time and distance only",study.receiver.elapsed==0 and study.receiver.distance==0 and pair_is(study.receiver.values,0.85,-0.7) and not study.model.connected)
    study._process(1.0)
    check("CUT cube continues at retained speed",is_equal_approx(study.receiver.distance,0.44) and is_equal_approx(study.cube.position.x,0.24))
    study.buttons[2].pressed.emit()
    check("reconnect delivers current values rather than replaying events",pair_is(study.receiver.values,0.15,0.6) and is_equal_approx(study.receiver.speed(),0.16))
    check("KEEP survives delivery repeat and subsequent movement",study.model.kept==kept)
    # Hold guards actions, but does not freeze the receiver's clock.
    await drag(study,Vector3(0,study.LOW+0.6*study.TRAVEL,0))
    var used: Array=study.receiver.values.duplicate()
    var offered: Array=study.model.offered.duplicate()
    var clock: float=study.receiver.elapsed
    for button in study.buttons:button.pressed.emit()
    check("button actions wait for release",study.selected==1 and study.model.connected and study.receiver.values==used and study.model.offered==offered and study.receiver.elapsed==clock and study.model.kept==kept)
    study.point.on_desktop_drop(study)
    # Independent task: establish a pair, cut, then offer another.
    await set_hand(study,0,0.25)
    await set_hand(study,1,0.25)
    study.buttons[2].pressed.emit()
    await set_hand(study,0,0.9)
    await set_hand(study,1,0.75)
    check("independent task forms disagreement through hand and gate",not study.model.connected and pair_is(study.model.offered,0.9,0.5) and pair_is(study.receiver.values,0.25,-0.5))
    check("independent task predicts received speed .2",is_equal_approx(study.receiver.speed(),0.2) and study.used_label.text.contains("0.25 / -0.50"))
    study.buttons[2].pressed.emit()
    check("independent reconnect changes speed to .46",pair_is(study.receiver.values,0.9,0.5) and is_equal_approx(study.receiver.speed(),0.46))
    var state: Dictionary=study.model.reading()
    study.redraw()
    check("redraw cannot advance or change either pair",study.model.reading()==state)
    check("same sphere cube and explicit receiver persist",study.point.get_instance_id()==point_id and study.cube.get_instance_id()==cube_id and study.model.receiver==study.receiver and study.point.position.distance_to(study.point_home)<0.001)
    # Match only the mappings the text reconstructs, not particle histories.
    var original=load("res://commons/interfaces/qfep/qfep_reactor.gd").new()
    original._create_core()
    original._create_particles()
    original._create_light()
    var matched := true
    for l: float in [0.0,0.15,0.3,0.4,0.5,0.85,1.0]:
        for p: float in [-1.0,0.0,1.0]:
            original.set_lambda(l)
            original.set_phi(p)
            original._update_visuals()
            study.receiver.set_value(0,l)
            study.receiver.set_value(1,p)
            matched = matched and study.receiver.colour().is_equal_approx(original.core_mesh.material_override.albedo_color)
            matched = matched and is_equal_approx(study.receiver.speed(),original.particle_system.process_material.initial_velocity_max)
    check("twenty-one colour and speed pairs match installed reactor",matched)
    original.free()
    parent.free()
    await process_frame
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Fresh printed reconstruction; author-operated synthetic controls; matched installed colour and speed mappings, not particle histories or independent learner understanding."},"  "))
    quit(0 if failures.is_empty() else 1)
