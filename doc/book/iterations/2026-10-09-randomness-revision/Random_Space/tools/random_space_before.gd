extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var mixer=find_scene("/noise_mixer.gd")
    check("installed mixer exists",mixer!=null)
    if mixer==null:return
    observations.mixer=xyz(hall.to_local(mixer.global_position))
    observations.mixer_scale=xyz(mixer.global_basis.get_scale())
    observations.artifacts=[]
    for n in hall.find_children("*","Node3D",true,false):
        if n.get_script()!=null and str(n.get_script().resource_path).ends_with(".gd") and n.has_meta("em_artifact"):
            observations.artifacts.append({"path":str(n.get_script().resource_path),"at":xyz(hall.to_local(n.global_position))})
    await snapshot("hall-before",hall.to_global(Vector3(6.5,16,0)),hall.to_global(Vector3(6.5,0,11)),63)
    await snapshot("mixer-before",mixer.global_position+Vector3(0,1.3,1.5),mixer.global_position,60)
