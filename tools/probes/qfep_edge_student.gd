extends "res://tools/probes/qfep_introduction_student.gd"

func fields(study: Node3D) -> Array:
    return [study.model.coarse.a.duplicate(),study.model.coarse.b.duplicate(),
        study.model.fine.a.duplicate(),study.model.fine.b.duplicate(),
        study.model.coarse.ticks,study.model.fine.ticks]

func release(study: Node3D) -> void:
    study.point.on_desktop_drop(study)
    for i in 3:await physics_frame

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"step_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position=Vector3(12,3,-7)
    parent.rotation=Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study = load(folder+"edge_study.gd").new()
    parent.add_child(study)
    await process_frame
    check("initialized labels and independent textures",study.readout.text.contains("time 0.0 / 0.0") and study.textures.size()==2 and study.textures[0]!=study.textures[1])
    check("five declared button actions",study.buttons.size()==5)
    var full_screens := 0
    for child in study.get_children():
        if child is MeshInstance3D and child.material_override != null and child.material_override.albedo_texture in study.textures:
            var uv: PackedVector2Array = child.mesh.get_mesh_arrays()[Mesh.ARRAY_TEX_UV]
            if uv.size()==4 and Vector2.ZERO in uv and Vector2.ONE in uv:full_screens+=1
    check("both screens map the whole image onto one face",full_screens==2)
    var start := fields(study)
    var point_id: int=study.point.get_instance_id()
    var texture_id: int=study.textures[0].get_instance_id()
    for i in 10:study.buttons[0].pressed.emit()
    check("ten batches reach sixty model units with 200 and 400 steps",study.model.coarse.ticks==200 and study.model.fine.ticks==400 and is_equal_approx(study.model.reading().fine_time,60.0))
    study.buttons[4].pressed.emit()
    var record: Dictionary=study.model.kept.duplicate(true)
    study.buttons[3].pressed.emit()
    check("timestep change restarts the identical initial fields",study.model.dt==0.15 and fields(study)==start)
    for i in 10:study.buttons[0].pressed.emit()
    var refined: float=study.model.difference()
    check("selected seed lambda .4 time60 has smaller B difference at half dt",refined>0.0 and refined<record.rms)
    check("fine pair reaches same duration with 400 and 800 steps",study.model.coarse.ticks==400 and study.model.fine.ticks==800 and is_equal_approx(study.model.reading().fine_time,record.fine_time))
    check("KEEP retained settings and both earlier fields",study.model.kept==record)
    var before := fields(study)
    await drag(study,Vector3(2,study.LOW+0.7*study.TRAVEL,-2))
    check("transformed hand maps locally to lambda .7",is_equal_approx(study.model.weight,0.7))
    check("changing lambda leaves fields and clocks untouched",fields(study)==before)
    for button in study.buttons:button.pressed.emit()
    check("buttons wait for point release",fields(study)==before and study.model.dt==0.15 and study.model.kept==record)
    await release(study)
    study.buttons[1].pressed.emit()
    check("restart retains current weight and dt",is_equal_approx(study.model.weight,0.7) and study.model.dt==0.15 and fields(study)==start)
    study.buttons[2].pressed.emit()
    check("new seed changes both beginnings together",study.model.coarse.b!=start[1] and study.model.coarse.b==study.model.fine.b and study.model.coarse.ticks==0)
    for i in 3:study.buttons[0].pressed.emit()
    check("independent time18 task needs 120 and 240 steps",study.model.coarse.ticks==120 and study.model.fine.ticks==240 and is_equal_approx(study.model.reading().fine_time,18.0))
    before=fields(study)
    study.redraw()
    for i in 4:await process_frame
    check("painting and ordinary frames do not advance or alter state",fields(study)==before)
    check("palette saturates without changing the field",study.tint(1.0)==study.tint(1.5) and fields(study)==before)
    check("same sphere and textures survive resets and drawing",study.point.get_instance_id()==point_id and study.textures[0].get_instance_id()==texture_id and study.point.position.distance_to(study.point_home)<0.001)
    # A matched instance of the installed solver, without building its display.
    var original=load("res://commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd").new()
    original.grid_size=32
    original.lambda=study.model.weight
    original.seed_value=study.model.seed_value
    original.time_step=study.model.dt
    original.comparison_study=true
    original._init_grid()
    original._seed_pattern()
    original._reset_comparison()
    for i in 120:original._advance_tick()
    check("reconstruction matches installed coarse arrays at same grid seed parameters time",original._grid_a==study.model.coarse.a and original._grid_b==study.model.coarse.b)
    check("reconstruction matches installed fine arrays and RMS",original._fine_a==study.model.fine.a and original._fine_b==study.model.fine.b and is_equal_approx(original.comparison_error(),study.model.difference()))
    original.free()
    var metrics={"grid":32,"seed":record.seed,"lambda":record.weight,"model_time":record.coarse_time,"rms_dt_03_015":record.rms,"rms_dt_015_0075":refined}
    parent.free()
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"metrics":metrics,"scope":"Author-operated fresh printed reconstruction and synthetic inputs. Matched installed solver on same 32x32 grid. Not an independent learner or headset test."},"  "))
    quit(0 if failures.is_empty() else 1)
