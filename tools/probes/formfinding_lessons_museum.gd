extends "res://tools/probes/transformation_encounters.gd"

const PRIMARY = {"Descent":"descent_landscape_lab", "Catenary":"cable_builder", "Relaxation":"verlet_workbench", "Equilibrium":"calder_mobile", "Annealing":"simulated_annealing", "Forge":"balance_puzzle"}

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var key=map_id.trim_prefix("FormFinding_")
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
    var w: float=data.map_info.dimensions.width
    var d: float=data.map_info.dimensions.depth
    var origin=hall.global_position+Vector3(0,0,4)
    var walker=museum.get("_player")
    if walker is Node3D:walker.visible=false
    var walk_camera=museum.get("_cam")
    if walk_camera is Node3D:walk_camera.visible=false
    observations.artifacts=[]
    var primary: Node3D
    for record in museum.get("_edit_records"):
        var node=record.get("node")
        if not is_instance_valid(node) or record.get("seg")!=hall:continue
        var bounds: AABB=museum.call("_seat_extent",node)
        observations.artifacts.append({"token":record.get("token"),"position":xyz(node.global_position-origin),"scale":xyz(node.scale),"bounds_position":xyz(bounds.position-origin),"bounds_size":xyz(bounds.size)})
        if record.get("token")==PRIMARY[key]:primary=node
    check("primary present",primary!=null)
    await snapshot("above",origin+Vector3(w*0.25,12,0),origin+Vector3(w*0.5,0,d*0.5),70)
    await snapshot("entry",origin+Vector3(w*0.5,1.7,1.0),origin+Vector3(w*0.5,1.5,d*0.7),75)
    if primary!=null:
        await snapshot("primary",primary.global_position+Vector3(-2,2,-4),primary.global_position+Vector3.UP*1.1,68)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):
        var lesson=load(spec.lesson).new()
        var at: Array=spec.bay
        lesson.position=Vector3(at[0],at[1],at[2])
        hall.add_child(lesson)
        await create_timer(0.3).timeout
        check("study bay floor",not floor_at(lesson.global_position).is_empty())
        if lesson.has_method("step_once"):
            for i in 12:lesson.step_once()
        await snapshot("student",lesson.to_global(Vector3(0,1.8,-3.5)),lesson.to_global(Vector3(0,1.3,0)),65)
        observations.lesson=spec.lesson
        observations.bay=at
        lesson.queue_free()
    observations.scope="Actual six-hall museum inventory and captures; study placement when requested. No physical headset test."

