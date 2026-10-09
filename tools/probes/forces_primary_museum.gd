extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
    await super.landing_checks()
    camera.set_cull_mask_value(19,false)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
    var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/force_halls/curation.json"))
    var primary=""
    for row in plan.halls:
        if row.map==map_id:primary=row.tutorial_artifact
    var node: Node3D
    for r in museum.get("_edit_records"):
        if r.get("seg")==hall and r.get("token")==primary:node=r.get("node");break
    check("primary lesson artifact is present: "+primary,node!=null)
    if node==null:return
    var e=node
    if e.get("kind") in ["mass","springs","mutual","vortex","liquids"]:
        var distance: float=e.extent.y*0.5+1
        if e.kind=="mass":e.buttons["PUSH 1 s"].pressed.emit();await create_timer(1.1).timeout
        await snapshot("primary",e.to_global(Vector3(-2,1.7,-distance)),e.to_global(Vector3(0,1.8,0)),75)
        if e.kind in ["springs","mutual","vortex"]:
            check("focused comparison starts in the real hall",e.lesson_focus)
            var id="PAIR / FIVE" if e.kind=="mutual" else "ONE / MANY"
            e.buttons[id].pressed.emit();await create_timer(0.2).timeout
            check("real local button restores the full experiment",not e.lesson_focus and e.bodies.all(func(b):return b.visible))
            await snapshot("expanded",e.to_global(Vector3(-4,3.5,-distance)),e.to_global(Vector3(0,1.5,0)),75)
        if e.kind=="liquids":
            check("drag is the initial liquid lesson",not e.buoyancy_enabled)
            e.buttons.DROP.pressed.emit();await create_timer(0.8).timeout
            await snapshot("dropped",e.to_global(Vector3(0,2,-distance)),e.to_global(Vector3(0,2,0)),85)
    elif map_id=="Vectors_Act1_WhatAVectorIs":
        await snapshot("primary",node.to_global(Vector3(-2,1.7,-3.4)),node.to_global(Vector3(0,1.3,0)),65)
    elif map_id=="VFM_05_Launch":
        var chamber=find_scene("/launch_chamber.gd")
        check("launch has the analytic chamber",chamber!=null)
        if chamber!=null:
            chamber.act("PAIR");chamber.act("PATH");chamber.act("PARTS");chamber.act("FIRE")
            await create_timer(0.4).timeout;chamber.set_process(false)
            await snapshot("primary",chamber.to_global(Vector3(6.5,2,5)),chamber.to_global(Vector3(-1,2,0)),80)
    elif map_id=="Vectors_Act5_ForceAsPlace":
        await snapshot("primary",node.to_global(Vector3(-1,1.7,-11.6)),node.to_global(Vector3(-3.8,1.4,-9)),68)
    else:
        var distance=15.0 if map_id=="VFM_08_Arena" else 8.0
        await snapshot("primary",node.to_global(Vector3(-3,2.2,-distance)),node.to_global(Vector3(0,1.3,0)),78)
    observations.lesson_primary=primary
    observations.scope="Primary artifact and actual local controls, museum desktop renders; no headset test."
    var order=["Vectors_Act1_WhatAVectorIs","VFM_05_Launch","VFM_03_Motion","Vectors_Act3_FieldsAndMotion","Vectors_Act4a_KineticForces","Vectors_Act4b_Oscillation","Change_Choreography","VFM_07_Gravity","VFM_09_Legs","VFM_08_Arena","Vectors_Act5_ForceAsPlace"]
    var files=["01_vectors","02_launch","03_mass","04_field","05_drag","06_spring","07_phase","08_attraction","09_support","10_impulse","11_flight"]
    var study=load("res://doc/book/studies/forces-point-lineage/"+files[order.find(map_id)]+".gd").new()
    study.name="PointStudy"
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
    study.position=Vector3(float(data.map_info.dimensions.width)*0.5,0,7.6)
    hall.add_child(study)
    await create_timer(0.1).timeout
    if study.buttons.has("FIRE"):study.buttons.FIRE.pressed.emit()
    if study.buttons.has("PUSH 1 s"):study.buttons["PUSH 1 s"].pressed.emit()
    await create_timer(0.25).timeout
    check("exact printed student script constructs in its actual museum hall",study.get_child_count()>0)
    check("student study has the museum floor under its origin",not floor_at(study.global_position).is_empty())
    await snapshot("student",study.to_global(Vector3(3,2,-4)),study.to_global(Vector3(0,1.2,0)),72)
    study.queue_free()
