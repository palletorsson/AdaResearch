extends SceneTree
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(title: String, passed: bool) -> void:
    checks.append({"name":title,"passed":passed})
    if not passed:failures.append(title)
    print("[space] ","PASS " if passed else "FAIL ",title)
func close_arrays(a: Array,b: Array) -> bool:
    if a.size()!=b.size():return false
    for i in range(a.size()):
        if absf(float(a[i])-float(b[i]))>0.000001:return false
    return true
func close_images(a: Image,b: Image) -> bool:
    if a.get_size()!=b.get_size():return false
    for y in range(a.get_height()):
        for x in range(a.get_width()):
            if absf(a.get_pixel(x,y).r-b.get_pixel(x,y).r)>0.004:return false
    return true
func run() -> void:
    await process_frame
    var source: String;var report: String;var gain:=1.0
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--quarter-sum":gain=0.25
    var script=load(source);var study=script.new()
    study.position=Vector3(8,0,6);study.rotation.y=PI/2;root.add_child(study)
    var original_lac: float=study.lacunarity;var original_per: float=study.persistence
    var size: int=study.SIDE
    check("ready supplies three screens a full grid and carried point",study.screens.size()==3 and study.raw.size()==size*size and study.parts.size()==1 and study.point.has_method("pick_up"))
    var aligned:=0
    for caption in study.find_children("*","Label3D",true,false):
        var x: float=caption.position.x
        if (caption.text=="REPLAY" and x< -0.65) or (caption.text=="OCT" and x>= -0.65 and x<0) or (caption.text=="WEIGHT" and x>=0 and x<0.65) or (caption.text=="SEED" and x>=0.65):aligned+=1
    check("each action label lies inside its own trigger zone",aligned==4)
    var reference=load("res://commons/artifacts/noise_mixer/noise_mixer.gd").new()
    reference.seed_value=study.sample_seed;reference._rng.seed=study.sample_seed;reference._generate_octave_offsets()
    check("all eight seeded offsets match source",study.offsets==reference._octave_offsets and study.rng.state==reference._rng.state)
    var offsets: Array=study.offsets.duplicate();var rng_state: int=study.rng.state
    var kernel_ok:=true
    for p in [Vector2.ZERO,Vector2(0.2,-0.3),Vector2(42.5,67.25),Vector2(-90.5,3.75)]:
        kernel_ok=kernel_ok and is_equal_approx(study.wave(p.x,p.y),reference._sin_noise(p.x,p.y))
    check("base kernel is the actual five-sine function",kernel_ok)
    reference.lacunarity=original_lac;reference.persistence=original_per;reference.base_frequency=study.base_frequency
    var source_ok:=true;var parts_ok:=true;var prefix_ok:=true;var previous: Array=[]
    for count in range(1,5):
        study.layer_count=count;study.sample_fields();reference.octaves=count
        for i in range(previous.size()):prefix_ok=prefix_ok and study.parts[i]==previous[i]
        for y in range(size):
            for x in range(size):
                var index: int=y*size+x;var sum:=0.0
                for part in study.parts:sum+=part[index]
                parts_ok=parts_ok and is_equal_approx(study.raw[index],sum*gain)
                source_ok=source_ok and absf(study.raw[index]-reference._fbm(float(x)/size,float(y)/size)*gain)<0.000001
        previous=study.parts.duplicate(true)
    check("every cell in one through four layers agrees with source sum",source_ok)
    check("retained parts account for the complete sum",parts_ok)
    check("adding layers preserves earlier contributions",prefix_ok)
    check("parameter sampling spends no random draws",study.offsets==offsets and study.rng.state==rng_state)
    var saved: Array=study.raw.duplicate();var parts: Array=study.parts.duplicate(true)
    study.redraw();study.redraw()
    check("redrawing preserves raw values and every contribution",study.raw==saved and study.parts==parts and study.rng.state==rng_state)
    study.layer_count=1;study.sample_fields();var one: Array=study.raw.duplicate()
    study.lacunarity=3;study.persistence=0.7;study.sample_fields()
    check("one layer ignores lacunarity and persistence",study.raw==one)
    study.layer_count=2;study.sample_fields();var changed: Array=study.raw.duplicate()
    study.persistence=0.3;study.sample_fields()
    check("persistence changes only later weighted contributions",study.parts[0]==parts[0] and not close_arrays(study.raw,changed))
    changed=study.raw.duplicate();study.lacunarity=1.5;study.sample_fields()
    check("lacunarity changes later fields while retaining first",study.parts[0]==parts[0] and not close_arrays(study.raw,changed))
    study.lacunarity=original_lac;study.persistence=original_per;study.layer_count=4;study.sample_fields()
    check("return to settings recovers exact prior sum",study.raw==saved and study.parts==parts and study.offsets==offsets)
    var max_abs:=0.0
    for value in study.raw:max_abs=maxf(max_abs,absf(value))
    check("declared settings fit fixed display range",max_abs<3)
    var quarter: Array=[]
    for value in study.raw:quarter.append(value*0.25)
    check("positive rescaling preserves stretched picture",close_images(study.picture(study.raw,true),study.picture(quarter,true)))
    check("positive rescaling changes fixed-scale picture",not close_images(study.picture(study.raw,false),study.picture(quarter,false)))
    var zeros: Array=[];zeros.resize(size*size);zeros.fill(0.0)
    var flat: Image=study.picture(zeros,true);var neutral: Image=study.picture(zeros,false)
    check("constant field uses guarded black stretch and neutral fixed grey",is_zero_approx(flat.get_pixel(0,0).r) and absf(neutral.get_pixel(0,0).r-0.5)<0.004)
    var fixture: Array=zeros.duplicate();fixture[0]=-3.0;fixture[1]=3.0
    var image: Image=study.picture(fixture,false)
    check("fixed scale maps declared endpoints",is_zero_approx(image.get_pixel(0,0).r) and is_equal_approx(image.get_pixel(1,0).r,1))
    image=study.picture(study.raw,true)
    check("stretched extrema use full pixel range",image.get_pixel(study.raw.find(study.raw.min())%size,study.raw.find(study.raw.min())/size).r<0.004 and image.get_pixel(study.raw.find(study.raw.max())%size,study.raw.find(study.raw.max())/size).r>0.996)
    var sample_index: int=(size/2)*size+size/2
    var expected_last: float=clampf((study.parts.back()[sample_index]+3)/6,0,1)
    var last: Image=study.screens[0].material_override.albedo_texture.get_image()
    check("first screen shows last contribution using fixed scale",absf(last.get_pixel(size/2,size/2).r-expected_last)<0.004)
    check("middle screen shows retained sum",close_images(study.screens[1].material_override.albedo_texture.get_image(),study.picture(study.raw,false)))
    check("right screen stretches the same sum",close_images(study.screens[2].material_override.albedo_texture.get_image(),image))
    study.replay()
    check("replay preserves selected settings and recovers offsets sum",study.layer_count==4 and study.raw==saved and study.offsets==offsets and study.rng.state==rng_state)
    study.next_seed()
    check("next seed changes offsets without changing layer settings",study.sample_seed==reference.seed_value+1 and study.layer_count==4 and study.offsets!=offsets and study.raw!=saved)
    study.sample_seed=reference.seed_value;study.replay()
    check("returning seed recovers exact field",study.raw==saved and study.offsets==offsets)
    # The coordinates of an old grid are even-indexed entries of a doubled grid.
    var nested_ok:=true
    for y in range(size):
        for x in range(size):
            nested_ok=nested_ok and is_equal_approx(reference._fbm(float(2*x)/(2*size),float(2*y)/(2*size))*gain,study.raw[y*size+x])
    check("double resolution retains old coordinate values",nested_ok)
    study.layer_count=1;study.sample_fields();rng_state=study.rng.state
    study.point.position=Vector3(-0.3,1.13,0.3);study.point.dropped.emit(study.point)
    await physics_frame;await process_frame
    check("move release and waiting do not change field",study.layer_count==1 and study.rng.state==rng_state)
    study.point.global_position=study.to_global(Vector3(-0.3,1.13,0.3));study.point.action()
    check("OCT action uses the local coordinate frame",study.layer_count==2)
    study.point.global_position=study.to_global(Vector3(0.3,1.13,0.3));study.point.action()
    check("WEIGHT action changes amplitude ratio without draws",is_equal_approx(study.persistence,0.3) and study.rng.state==rng_state)
    study.point.global_position=study.to_global(Vector3(-0.9,1.13,0.3));study.point.action()
    check("point replay keeps settings",study.layer_count==2 and is_equal_approx(study.persistence,0.3) and study.offsets==offsets)
    study.point.global_position=study.to_global(Vector3(0.9,1.13,0.3));study.point.action()
    check("point seed advances once",study.sample_seed==reference.seed_value+1)
    study.layer_count=4;study.next_layer()
    check("layer control cycles back to one",study.layer_count==1)
    var other=script.new();root.add_child(other)
    check("instances keep separate field and generator state",other.layer_count==1 and other.sample_seed==reference.seed_value and other.rng!=study.rng)
    observations={"size":size,"source_samples_compared":size*size*4,"gain":gain,"original_lacunarity":original_lac,"original_persistence":original_per,"raw_range_at_four":[saved.min(),saved.max()],"pixel_scope":"RGBA8 tolerance one channel step; raw sum tolerance 1e-6"}
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"source":source,"engine":Engine.get_version_info(),"scope":"Exact printed code; author-informed source comparison and supplied actions, not physical headset."},"  "))
    study.free();other.free();reference.free();quit(0 if failures.is_empty() else 1)
