extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var board=find_scene("/monte_carlo_dartboard.gd")
    if board==null:
        push_error("Monte Carlo board not found in Examples of Randomness")
        return
    var console=board.find_child("ReachConsole",true,false)
    observations.board=xyz(hall.to_local(board.global_position))
    observations.button_shape=board.get_meta("config_button_shape", "missing")
    if console!=null:
        await snapshot("rectangular-buttons",console.to_global(Vector3(0,0.45,1.05)),console.global_position,50)
    await snapshot("dartboard-in-examples",board.to_global(Vector3(1.8,2.1,3.6)),board.to_global(Vector3(0,1.05,0.4)),57)
    await snapshot("examples-hall",hall.to_global(Vector3(7.5,13,3)),hall.to_global(Vector3(7.5,0,17)),65)
