extends "res://tools/probes/transformation_encounters.gd"

func heights(columns: Array) -> Array:
    var out:=[]
    for col in columns:out.append(col.mesh.size.y)
    return out

func move_slider(node: Node,index: int,value: float) -> void:
    var slider=node.find_child("Param_"+str(index),true,false)
    slider.set_normalized_value(value)
    slider.slider_moved.emit(value)

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var bench=find_scene("/perlin_noise_bridge.gd")
    check("installed comparison exists",bench!=null)
    if bench==null:return
    observations.artifacts=[]
    for rec in museum.get("_edit_records"):
        var n=rec.get("node")
        if is_instance_valid(n) and rec.get("seg")==hall:
            observations.artifacts.append({"token":rec.get("token"),"hall_local":xyz(hall.to_local(n.global_position))})
    observations.noise_defaults={"fractal_type":bench._noise.fractal_type,"octaves":bench._noise.fractal_octaves,"frequency":bench._noise.frequency}
    await snapshot("hall-before",hall.to_global(Vector3(6,25,1)),hall.to_global(Vector3(6,0,19)),65)
    bench._seed_val=42;bench._frequency=2.0;bench._octaves=3;bench._rebuild_grids()
    var white:=heights(bench._white_columns)
    var field:=heights(bench._perlin_columns)
    check("two installed16by16grids",white.size()==256 and field.size()==256)
    var rng:=RandomNumberGenerator.new();rng.seed=42
    var noise:=FastNoiseLite.new();noise.noise_type=FastNoiseLite.TYPE_PERLIN;noise.seed=42;noise.frequency=0.2;noise.fractal_octaves=3
    var source_ok:=true
    for i in range(256):
        source_ok=source_ok and is_equal_approx(white[i],maxf(rng.randf()*0.15,0.002))
        source_ok=source_ok and is_equal_approx(field[i],maxf((noise.get_noise_2d(i%16,i/16)+1)*0.5*0.15,0.002))
    check("source heights match seeded uniform and configured Perlin",source_ok)
    check("installed noise explicitly Perlin and defaultFBM",bench._noise.noise_type==FastNoiseLite.TYPE_PERLIN and bench._noise.fractal_type==FastNoiseLite.FRACTAL_FBM)
    await snapshot("installed-comparison",bench.to_global(Vector3(0,1.7,0.95)),bench.to_global(Vector3(0,1,0)),48)
    move_slider(bench,1,0.0)
    check("frequency slider reaches0.05 actual fieldfrequency",is_equal_approx(bench._noise.frequency,0.05))
    check("frequency keeps every white column",heights(bench._white_columns)==white)
    check("frequency changes coherent heights",heights(bench._perlin_columns)!=field)
    var low:=heights(bench._perlin_columns)
    move_slider(bench,0,1.0)
    check("octaves slider reaches six and leaves white unchanged",bench._octaves==6 and heights(bench._white_columns)==white)
    check("octaves changes coherent result",heights(bench._perlin_columns)!=low)
    move_slider(bench,2,1.0)
    check("seed slider names99 and changes independent record",bench._seed_val==99 and heights(bench._white_columns)!=white)
    bench._seed_val=42;bench._frequency=2.0;bench._octaves=3;bench._rebuild_grids()
    check("same settings reproduce both records",heights(bench._white_columns)==white and heights(bench._perlin_columns)==field)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec)
    observations.scope="Real hall with explicit slider signals; no headset or blind learner acceptance."

func study_checks(spec: Dictionary) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(3,0,12);study.rotation.y=PI/2
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
    var saved: Array=study.records.duplicate(true);var state: int=study.rng.state
    check("printed learner supplies64matched records128columns",saved.size()==64 and study.columns.size()==128)
    observations.student_gaps={"frequency_01":{"white":study.neighbour_gap("white"),"field":study.neighbour_gap("field")}}
    await snapshot("student-low-frequency",study.to_global(Vector3(0,2.35,2.1)),study.to_global(Vector3(0,1.2,0)),82)
    study.point.global_position=study.to_global(Vector3(0,1.12,1));study.point.action()
    var same_white:=true;var field_changed:=false
    for i in range(64):
        same_white=same_white and study.records[i].white==saved[i].white and study.records[i].at==saved[i].at
        field_changed=field_changed or study.records[i].field!=saved[i].field
    check("inherited frequency action keeps white record and RNG",is_equal_approx(study.frequency,0.3) and same_white and study.rng.state==state and field_changed)
    observations.student_gaps.frequency_03={"white":study.neighbour_gap("white"),"field":study.neighbour_gap("field")}
    await snapshot("student-high-frequency",study.to_global(Vector3(0,2.35,2.1)),study.to_global(Vector3(0,1.2,0)),82)
    var changed: Array=study.records.duplicate(true)
    study.point.global_position=study.to_global(Vector3(-0.8,1.12,1));study.point.action()
    check("inherited replay keeps current frequency",study.records==changed and is_equal_approx(study.frequency,0.3))
    study.point.global_position=study.to_global(Vector3(0.8,1.12,1));study.point.action()
    check("inherited next seed changes comparison",study.sample_seed==43 and study.records!=changed)
    for r in study.records:r.white=(r.at.x+r.at.y)%2;r.field=r.white
    study.rebuild()
    check("authored checkerboard has gap one",is_equal_approx(study.neighbour_gap("white"),1) and is_equal_approx(study.neighbour_gap("field"),1))
    await snapshot("student-checkerboard",study.to_global(Vector3(0,2.35,2.1)),study.to_global(Vector3(0,1.2,0)),82)
    for r in study.records:r.white=0.0 if r.at.x<4 else 1.0;r.field=r.white
    study.rebuild()
    check("same histogram split has gap1over14",is_equal_approx(study.neighbour_gap("white"),1.0/14) and is_equal_approx(study.neighbour_gap("field"),1.0/14))
    await snapshot("student-split",study.to_global(Vector3(0,2.35,2.1)),study.to_global(Vector3(0,1.2,0)),82)
    study.sample_seed=42;study.frequency=0.1;study.replay()
    check("replay restores sampled grids after authored changes",study.records==saved and study.rng.state==state)
    await snapshot("hall-with-study",hall.to_global(Vector3(6,25,1)),hall.to_global(Vector3(6,0,19)),65)
    observations.interaction_scope="PointBody.action at supplied poses, not physical grab driver or headset. Temporary study, production unchanged."
    study.free()
