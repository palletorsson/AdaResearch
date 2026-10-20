extends "res://tools/probes/transformation_encounters.gd"

func bounds_of(demo: Node3D) -> AABB:
    var result: AABB=demo._columns[0].cubes[0].get_aabb()
    result.position+=demo._columns[0].cubes[0].position
    for cube in demo._columns[0].cubes:
        var bounds: AABB=cube.get_aabb()
        bounds.position+=cube.position
        result=result.merge(bounds)
    return result

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var demo:=find_scene("/seed_replay_demo.gd")
    check("museum contains seed matrices",demo!=null)
    if demo==null:return
    check("default matrices are eight by eight",demo.grid_cols==8 and demo.grid_rows==8)
    demo.restore_museum_state({"seed":42,"extra_on":false,"side":8})
    var first: PackedColorArray=demo.column_colors(0)
    var before:=bounds_of(demo)
    var slider=demo.find_child("Param_1",true,false)
    check("matrix slider available in live console",slider!=null)
    if slider==null:return
    var knob=slider.get("_slider")
    var slider_id: int=slider.get_instance_id()
    observations.slider_height=slider.global_position.y-hall.global_position.y
    check("resolution slider is at hand height",observations.slider_height>0.8 and observations.slider_height<1.5)
    await snapshot("museum-8",demo.to_global(Vector3(0,2.0,4.4)),demo.to_global(Vector3(0,1.9,0)),53)
    knob.move_slider(knob.slider_limit_max)
    await tick()
    check("real slider chooses sixteen by sixteen",demo.grid_cols==16 and demo.column_colors(0).size()==256)
    check("resizing preserves the seed and stream prefix",demo.current_seed()==42 and demo.column_colors(0).slice(0,64)==first)
    var after:=bounds_of(demo)
    check("panel width and height stay fixed",absf(before.size.x-after.size.x)<0.0001 and absf(before.size.y-after.size.y)<0.0001 and absf(before.position.x-after.position.x)<0.0001 and absf(before.position.y-after.position.y)<0.0001)
    check("held slider remains the same node across rebuilds",slider.get_instance_id()==slider_id)
    check("larger replicas still match",demo.column_colors(0)==demo.column_colors(1))
    await snapshot("museum-16",demo.to_global(Vector3(0,2.0,4.4)),demo.to_global(Vector3(0,1.9,0)),53)
    demo.toggle_extra_draw()
    check("extra draw still changes only right matrix",demo.column_colors(0).slice(0,64)==first and demo.column_colors(0)!=demo.column_colors(1) and demo.draws_per_grid()==768)
    var state: Dictionary=demo.capture_museum_state()
    var shifted: PackedColorArray=demo.column_colors(1)
    knob.move_slider(knob.slider_limit_min)
    await tick()
    check("real slider chooses two by two",demo.grid_cols==2 and demo.column_colors(0).size()==4)
    check("smaller matrix keeps seed and extra draw",demo.current_seed()==42 and demo.extra_on())
    demo.restore_museum_state(state)
    await tick()
    check("visit state restores resolution and picture",demo.grid_cols==16 and demo.column_colors(1)==shifted and is_equal_approx(slider.get_normalized_value(),1))
    var choices_ok:=true
    for size in range(2,17):
        knob.move_slider(float(size-2)/14*knob.slider_limit_max)
        choices_ok=choices_ok and demo.grid_cols==size and demo.column_colors(0).size()==size*size
        await tick()
    check("all fifteen physical slider detents reachable",choices_ok)
    demo.set_grid_side(8)
    demo.toggle_extra_draw()
    check("returning to eight recovers both original grids",demo.column_colors(0)==first and demo.column_colors(1)==first)
    var study=load("res://doc/book/iterations/2026-10-09-random-matrix-size/extracted/01_seed_picture.gd").new()
    study.position=Vector3(10.5,0,18.5)
    study.rotation.y=-PI/2
    hall.add_child(study)
    await tick()
    check("student matrix bay has floor",not floor_at(study.global_position).is_empty())
    check("printed eight-by-eight picture matches the museum",PackedColorArray(study.samples[0])==first)
    await snapshot("student-8",study.to_global(Vector3(0,1.6,3.7)),study.to_global(Vector3(0,1.45,0)),52)
    study.resolution.track.move_slider(0.8)
    await tick()
    check("student slider works inside the museum",study.side==16 and study.grids[0].size()==256)
    await snapshot("student-16",study.to_global(Vector3(0,1.6,3.7)),study.to_global(Vector3(0,1.45,0)),52)
    study.resolution.track.move_slider(0.8*2.0/14)
    await snapshot("student-4",study.to_global(Vector3(0,1.6,3.7)),study.to_global(Vector3(0,1.45,0)),52)
    study.queue_free()
    observations.scope="Actual museum, live slider driver events, printed reconstruction. No headset acceptance."
