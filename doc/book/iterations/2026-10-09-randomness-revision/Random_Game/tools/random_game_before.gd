extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var crossing=find_scene("/random_cycle_cube.gd")
    check("crossing exists",crossing!=null and crossing.stand=="chasm")
    if crossing==null:return
    observations.crossing=xyz(hall.to_local(crossing.global_position))
    observations.state=crossing.crossing_state()
    await snapshot("crossing-before",hall.to_global(Vector3(7,3.4,2)),hall.to_global(Vector3(9.5,0,6.5)),65)
    await snapshot("hall-before",hall.to_global(Vector3(9.5,24,-3)),hall.to_global(Vector3(9.5,0,24)),68)
    observations.labels=[]
    for n in hall.find_children("*","Label3D",true,false):
        if n.text.contains("CUE") or n.text.contains("REPLAY"):observations.labels.append({"text":n.text,"path":str(n.get_path())})
