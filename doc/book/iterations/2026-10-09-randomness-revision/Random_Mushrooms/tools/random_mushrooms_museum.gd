extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var bed=find_scene("/mushrooms.gd")
    check("installed specimen bed exists",bed!=null)
    if bed==null:return
    observations.artifacts=[]
    for rec in museum.get("_edit_records"):
        var n=rec.get("node")
        if is_instance_valid(n) and rec.get("seg")==hall:
            observations.artifacts.append({"token":rec.get("token"),"hall_local":xyz(hall.to_local(n.global_position))})
    await snapshot("hall-before",hall.to_global(Vector3(8,24,0)),hall.to_global(Vector3(8,0,14)),64)
    bed.set_population_seed(42)
    await tick()
    var saved: Array=bed.instances().duplicate(true)
    var ground: Dictionary=bed.ground_signature()
    var state: int=bed._pop_rng.state
    var st: Dictionary=bed.get_specimen_state()
    observations.population=st
    check("six templates in six metre specimen bed",st.templates==6 and st.meadow_size==6 and st.stand=="specimen")
    var scattered:=0
    for r in saved:
        if r.kind=="scattered":scattered+=1
    check("accepted plus rejected accounts for80 scattered candidates",scattered+st.rejected==80 and st.candidates==80)
    check("one ring and two clusters requested",st.rings.size()==1 and st.clusters.size()==2)
    await snapshot("specimens",bed.to_global(Vector3(0,2.3,6.9)),bed.to_global(Vector3(0,0.9,3.4)),55)
    await snapshot("bed-varied",bed.to_global(Vector3(0,4,3.7)),bed.to_global(Vector3(0,0.3,0)),70)
    bed.regrow()
    check("REGROW reproduces every record and ground",bed.instances()==saved and bed.ground_signature()==ground and bed._pop_rng.state==state)
    bed.set_size_variation(false)
    var flat: Array=bed.instances()
    var same:=flat.size()==saved.size()
    for i in range(mini(flat.size(),saved.size())):
        var a: Dictionary=flat[i].duplicate();var b: Dictionary=saved[i].duplicate()
        same=same and is_equal_approx(a.scale,1.0)
        a.erase("scale");b.erase("scale");same=same and a==b
    check("SIZE removes only instance scale",same and bed.ground_signature()==ground and bed._pop_rng.state==state)
    await snapshot("bed-unit-scale",bed.to_global(Vector3(0,4,3.7)),bed.to_global(Vector3(0,0.3,0)),70)
    bed.set_size_variation(true)
    check("SIZE restores all earlier scales",bed.instances()==saved)
    for k in range(6):
        bed.show_template(k)
        var expected:=0
        for r in saved:
            if r.template==k:expected+=1
        check("SHOW names copies of template"+str(k),bed.highlighted_count()==expected)
    bed.set_population_seed(43)
    check("another seed changes the population",bed.instances()!=saved)
    bed.set_population_seed(42)
    check("return seed recovers original population",bed.instances()==saved)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec)
    observations.scope="Production controls and supplied point actions; not headset or blind learner acceptance."

func study_checks(spec: Dictionary) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(3,0,7);study.rotation.y=PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    check("learner root has floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,1.8))
    check("learner approach has floor",not floor_at(approach).is_empty())
    var shape:=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("learner approach is body sized and clear",obstacles.is_empty())
    var saved: Array=study.records.duplicate(true)
    var state: int=study.rng.state
    check("printed learner has twelve bodies",saved.size()==12 and study.bodies.size()==12)
    await snapshot("student-varied",study.to_global(Vector3(0,2.5,4.3)),study.to_global(Vector3(0,1.05,0)),48)
    study.point.global_position=study.to_global(Vector3(0,1.12,1));study.point.action()
    check("inherited action removes size without resampling",not study.vary_size and study.records==saved and study.rng.state==state)
    await snapshot("student-unit-scale",study.to_global(Vector3(0,2.5,4.3)),study.to_global(Vector3(0,1.05,0)),48)
    study.point.global_position=study.to_global(Vector3(-0.8,1.12,1));study.point.action()
    check("inherited REPLAY retains record and SIZE setting",study.records==saved and not study.vary_size)
    study.point.global_position=study.to_global(Vector3(0.8,1.12,1));study.point.action()
    check("inherited NEXT SEED changes population",study.population_seed==43 and study.records!=saved)
    study.population_seed=42;study.vary_size=true
    study.recipes.append({"cap":0.12,"stem":0.35,"colour":Color(0.9,0.9,0.8)})
    study.regrow()
    check("third recipe is constructed in this seeded population",study.records.any(func(r):return r.kind==2))
    await snapshot("student-third-recipe",study.to_global(Vector3(0,2.5,4.3)),study.to_global(Vector3(0,1.05,0)),48)
    observations.student_records=study.records
    await snapshot("hall-with-study",hall.to_global(Vector3(8,24,0)),hall.to_global(Vector3(8,0,14)),64)
    observations.interaction_scope="PointBody.action() at supplied poses; not headset or physical grab driver."
    study.free()
