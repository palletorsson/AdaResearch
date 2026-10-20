extends "res://tools/probes/transformation_encounters.gd"

func press(terrain: Node, index: int) -> void:
    var area=terrain._comparison_panel.find_child("Btn_"+str(index),true,false).get_node("InteractableAreaButton")
    area.button_pressed.emit(area)

func field_total(terrain: Node) -> float:
    var result:=0.0
    for row in terrain.pheromone_grid:
        for v in row:result+=v
    return result

func heights(terrain: Node) -> Array:
    var result:=[]
    for row in terrain.vertex_grid:
        for v in row:result.append(v.y)
    return result

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var terrain=find_scene("/pheromone_terrain.gd")
    check("installed pheromone terrain exists",terrain!=null)
    if terrain==null:return
    var deadline:=Time.get_ticks_msec()+5000
    while not terrain._terrain_ready and Time.get_ticks_msec()<deadline:await process_frame
    check("four walkers forty percent guidance and paused comparison",terrain._terrain_ready and terrain.comparison and terrain.walker_count==4 and is_equal_approx(terrain.pheromone_attraction,0.4) and not terrain.is_processing())
    observations.terrain=xyz(hall.to_local(terrain.global_position))
    await snapshot("hall-before",hall.to_global(Vector3(6.5,15,1)),hall.to_global(Vector3(6.5,0,10)),62)
    press(terrain,0)
    var start: Array=terrain.walkers.duplicate(true)
    check("ATTRACT clears field and starts at step zero",terrain.rule=="trail" and terrain._comparison_steps==0 and is_zero_approx(field_total(terrain)))
    press(terrain,2)
    check("one step deposits at four departing addresses",terrain._comparison_steps==1 and is_equal_approx(field_total(terrain),2.4))
    var deposits_ok:=true
    for w in start:deposits_ok=deposits_ok and terrain.pheromone_grid[w.y][w.x]>=0.6 and terrain.vertex_grid[w.y][w.x].y>=0.2
    check("source deposits and raises departures before moving",deposits_ok)
    press(terrain,4);press(terrain,3)
    var batch_path: Array=terrain.walkers.duplicate(true)
    var batch_field: Array=terrain.pheromone_grid.duplicate(true)
    var batch_heights:=heights(terrain);var state: int=terrain._rng.state
    press(terrain,4)
    for i in range(20):press(terrain,2)
    check("20 singles equal one batch in actual hall",terrain.walkers==batch_path and terrain.pheromone_grid==batch_field and heights(terrain)==batch_heights and terrain._rng.state==state)
    for i in range(24):press(terrain,3)
    var attract_field: Array=terrain.pheromone_grid.duplicate(true)
    var attract_heights:=heights(terrain)
    observations.attract={"steps":terrain._comparison_steps,"scent_total":field_total(terrain),"raised_vertices":attract_heights.filter(func(v):return v>0).size()}
    await snapshot("installed-attract",hall.to_global(Vector3(6.5,6.5,4.2)),hall.to_global(Vector3(6.5,0.2,7.5)),60)
    press(terrain,1)
    check("AVOID restarts same seeded walker positions",terrain.rule=="avoid" and terrain._comparison_steps==0 and terrain.walkers==start)
    for i in range(25):press(terrain,3)
    check("equal500 steps change scent and accumulated shape",terrain._comparison_steps==500 and terrain.pheromone_grid!=attract_field and heights(terrain)!=attract_heights)
    observations.avoid={"steps":terrain._comparison_steps,"scent_total":field_total(terrain),"raised_vertices":heights(terrain).filter(func(v):return v>0).size()}
    await snapshot("installed-avoid",hall.to_global(Vector3(6.5,6.5,4.2)),hall.to_global(Vector3(6.5,0.2,7.5)),60)
    var retained:=heights(terrain);state=terrain._rng.state
    terrain._decay_pheromones(100000);terrain._update_mesh()
    check("source scent can fade while height and RNG remain",is_zero_approx(field_total(terrain)) and heights(terrain)==retained and terrain._rng.state==state)
    press(terrain,4)
    check("source REPLAY keeps AVOID while clearing both records",terrain.rule=="avoid" and terrain._comparison_steps==0 and heights(terrain).all(func(v):return is_zero_approx(v)))
    press(terrain,0)
    for i in range(25):press(terrain,3)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    var study=load(spec.lesson).new()
    study.position=Vector3(10.1,0,6.2);study.rotation.y=-PI/2
    hall.add_child(study);await tick()
    check("learner origin has floor support",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,1.35))
    check("learner approach has floor support",not floor_at(approach).is_empty())
    var shape:=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    var obstacles:=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("learner standing approach is clear",obstacles.is_empty())
    study.point.global_position=study.to_global(Vector3(-0.3,1.12,0.85));study.point.action()
    check("point STEP advances one",study.path.size()==2)
    study.point.global_position=study.to_global(Vector3(0.3,1.12,0.85));study.point.action()
    check("point plus20 advances twenty",study.path.size()==22)
    study.point.global_position=study.to_global(Vector3(-0.9,1.12,0.85));study.point.action()
    check("point replay clears the experiment",study.path.size()==1 and study.visits.all(func(v):return v==0))
    study.point.position=Vector3(0,1.12,0.85);study.advance(100)
    var eye: Vector3=study.to_global(Vector3(0,2.55,2.7));var target: Vector3=study.to_global(Vector3(0,1.05,0))
    await snapshot("student-attract",eye,target,67)
    var original_field: Array=study.field.duplicate();var original_visits: Array=study.visits.duplicate();var original_path: Array=study.path.duplicate()
    study.fade(100000);study.redraw()
    check("learner erasing scent retains visits and recorded path",study.field.all(func(v):return is_zero_approx(v)) and study.visits==original_visits and study.path==original_path)
    await snapshot("student-scent-erased",eye,target,67)
    study.point.global_position=study.to_global(Vector3(0.9,1.12,0.85));study.point.action()
    check("point RULE selects AVOID and resets",study.avoid and study.path.size()==1)
    study.point.position=Vector3(0,1.12,0.85);study.advance(100)
    check("same100step learner comparison changes retained visits",study.visits!=original_visits and study.field!=original_field)
    await snapshot("student-avoid",eye,target,67)
    study.change_rule();study.advance(100)
    check("learner returning to ATTRACT replays path",study.path==original_path and study.visits==original_visits)
    await snapshot("hall-with-study",hall.to_global(Vector3(6.5,15,1)),hall.to_global(Vector3(6.5,0,10)),62)
    observations.scope="Actual museum button signals and temporary printed reconstruction, supplied PointBody actions. No physical headset or independent learner."
    study.free()
