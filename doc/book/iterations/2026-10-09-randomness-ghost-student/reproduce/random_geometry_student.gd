extends SceneTree
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[geometry] ", "PASS " if ok else "FAIL ", title)
func values(study, key: String) -> Array:
    var out := []
    for record in study.records: out.append(record[key])
    return out
func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report=arg.trim_prefix("--report=")
    var script=load(source)
    var study=script.new();study.position=Vector3(8,0,6);study.rotation.y=PI/2;root.add_child(study)
    var initial_seed: int=study.sample_seed
    var initial_frequency: float=study.frequency
    var initial_gap: float=study.cell_gap
    check("ready supplies paired grids labels and inherited point",study.records.size()==64 and study.columns.size()==128 and not study.status.text.is_empty() and study.point.has_method("pick_up"))
    check("one explicit Perlin layer",study.noise.noise_type==FastNoiseLite.TYPE_PERLIN and study.noise.fractal_type==FastNoiseLite.FRACTAL_NONE)
    var expected:=RandomNumberGenerator.new();expected.seed=initial_seed
    var field:=FastNoiseLite.new();field.noise_type=FastNoiseLite.TYPE_PERLIN;field.fractal_type=FastNoiseLite.FRACTAL_NONE;field.seed=initial_seed;field.frequency=initial_frequency
    var addresses_ok:=true;var white_ok:=true;var field_ok:=true
    for i in range(64):
        var r: Dictionary=study.records[i]
        addresses_ok=addresses_ok and r.at==Vector2i(i%8,i/8)
        white_ok=white_ok and is_equal_approx(r.white,expected.randf())
        field_ok=field_ok and is_equal_approx(r.field,(field.get_noise_2d(i%8,i/8)+1.0)*0.5)
    check("all matching addresses are complete and row ordered",addresses_ok)
    check("independent record uses exactly64 seeded draws",white_ok and study.rng.state==expected.state)
    check("field record matches declared signed to unsigned map",field_ok)
    var render_ok:=true
    for side in range(2):
        for i in range(64):
            var key: String="white" if side==0 else "field"
            var h: float=maxf(study.records[i][key]*0.65,0.01)
            var col: MeshInstance3D=study.columns[side*64+i]
            var centre: float=-0.86 if side==0 else 0.86
            var at:=Vector3(centre+(i%8-3.5)*initial_gap,0.9+h/2.0,(i/8-3.5)*initial_gap)
            render_ok=render_ok and col.mesh.size.is_equal_approx(Vector3(0.13,h,0.13)) and col.position.is_equal_approx(at)
    check("every column preserves the shared height scale and table base",render_ok)
    var shared_colours:=true
    for c in study.columns:shared_colours=shared_colours and c.material_override.albedo_color.is_equal_approx(Color(0.22,0.22,0.22))
    check("neutral material does not encode either value",shared_colours)
    var gap_ok:=true
    for key in ["white","field"]:
        var total:=0.0
        for row in range(8):
            for x in range(7):total+=absf(study.records[row*8+x][key]-study.records[row*8+x+1][key])
        for row in range(7):
            for x in range(8):total+=absf(study.records[row*8+x][key]-study.records[(row+1)*8+x][key])
        gap_ok=gap_ok and is_equal_approx(study.neighbour_gap(key),total/112.0)
    check("gap agrees with independent112-edge enumeration",gap_ok)
    observations.initial_gaps={"white":study.neighbour_gap("white"),"field":study.neighbour_gap("field")}
    var saved: Array=study.records.duplicate(true);var state: int=study.rng.state
    study.rebuild();study.rebuild()
    check("drawing consumes no sample and keeps records",study.records==saved and study.rng.state==state and study.columns.size()==128)
    var answer: float=study.noise.get_noise_2d(2.5,3.25)
    study.noise.get_noise_2d(72.3,-5.2)
    check("field query order does not change a repeated answer",is_equal_approx(answer,study.noise.get_noise_2d(2.5,3.25)) and study.rng.state==state)
    var white: Array=values(study,"white")
    var old_field: Array=values(study,"field")
    study.toggle_frequency()
    check("frequency keeps independent values and RNG state",values(study,"white")==white and study.rng.state==state)
    check("frequency changes field values at retained addresses",values(study,"field")!=old_field and values(study,"at")==saved.map(func(r):return r.at))
    observations.other_frequency={"frequency":study.frequency,"white":study.neighbour_gap("white"),"field":study.neighbour_gap("field")}
    study.toggle_frequency()
    check("frequency return restores all records",study.records==saved and is_equal_approx(study.frequency,initial_frequency))
    var first: Vector3=study.columns[0].position
    study.cell_gap=initial_gap+0.03;study.rebuild()
    check("physical spacing changes positions without sampling",study.records==saved and study.rng.state==state and not study.columns[0].position.is_equal_approx(first))
    study.cell_gap=initial_gap;study.replay()
    check("replay restores record and RNG",study.records==saved and study.rng.state==state)
    study.next_seed()
    check("next seed changes both procedures and keeps frequency",study.sample_seed==initial_seed+1 and values(study,"white")!=white and values(study,"field")!=old_field and is_equal_approx(study.frequency,initial_frequency))
    study.sample_seed=initial_seed;study.replay()
    check("returning seed restores both grids",study.records==saved)
    for r in study.records:r.white=(r.at.x+r.at.y)%2;r.field=r.white
    study.rebuild()
    check("checkerboard has unit gap in both fields",is_equal_approx(study.neighbour_gap("white"),1.0) and is_equal_approx(study.neighbour_gap("field"),1.0))
    check("zero marker and unit column have known heights",is_equal_approx(study.columns[0].mesh.size.y,0.01) and is_equal_approx(study.columns[1].mesh.size.y,0.65))
    var zeroes:=0;var ones:=0
    for r in study.records:
        r.white=0.0 if r.at.x<4 else 1.0;r.field=r.white
        if r.white==0:zeroes+=1
        else:ones+=1
    study.rebuild()
    check("same histogram split grid has gap one fourteenth",zeroes==32 and ones==32 and is_equal_approx(study.neighbour_gap("white"),1.0/14.0) and is_equal_approx(study.neighbour_gap("field"),1.0/14.0))
    for r in study.records:r.white=0.37;r.field=0.37
    study.rebuild()
    check("constant fixture has zero gaps and unstretched heights",is_zero_approx(study.neighbour_gap("white")) and is_zero_approx(study.neighbour_gap("field")) and is_equal_approx(study.columns[0].mesh.size.y,0.37*0.65))
    study.replay()
    check("replay recovers sampled grids after authored fixture",study.records==saved and study.rng.state==state)
    study.point.global_position=study.to_global(Vector3(0,1.12,1));study.point.action()
    check("trigger frequency follows rotated local frame",not is_equal_approx(study.frequency,initial_frequency) and values(study,"white")==white and study.rng.state==state)
    var changed: Array=study.records.duplicate(true)
    study.point.global_position=study.to_global(Vector3(-0.8,1.12,1));study.point.action()
    check("trigger replay retains current frequency and records",study.records==changed)
    study.point.global_position=study.to_global(Vector3(0.8,1.12,1));study.point.action()
    check("trigger next seed uses inherited action",study.sample_seed==initial_seed+1)
    changed=study.records.duplicate(true);state=study.rng.state
    study.point.position=Vector3(0,1.12,1);study.point.dropped.emit(study.point)
    await physics_frame;await process_frame
    check("moving dropping and waiting leave samples alone",study.records==changed and study.rng.state==state)
    var other=script.new();root.add_child(other)
    var other_records: Array=other.records.duplicate(true);study.next_seed()
    check("instances own their fields and records",other.records==other_records and other.noise!=study.noise and other.rng!=study.rng)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"source":source,"engine":Engine.get_version_info(),"scope":"Author-informed exact printed code and edits; supplied inherited actions, not physical grab or headset."},"  "))
    file.close();study.free();other.free();quit(0 if failures.is_empty() else 1)
