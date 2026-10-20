extends SceneTree

var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[entropy-study] ","PASS " if value else "FAIL ",title)

func run() -> void:
    await process_frame
    var source: String
    var report: String
    var mode: String="sampled"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
    var script=load(source)
    var lesson=script.new()
    lesson.position=Vector3(6,0,9)
    lesson.rotation.y=-PI/2
    root.add_child(lesson)
    check("ready builds both full rows and four bars",lesson.rows.size()==2 and lesson.rows[0].size()==16 and lesson.rows[1].size()==16 and lesson.bars.size()==4)
    check("all labels are initialized",lesson.title.text!="" and lesson.view_label.text!="" and lesson.captions[0].text!="")
    check("carried point remains frozen and pickable",lesson.point.has_method("pick_up") and lesson.point.freeze and is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    check("cells own their materials",lesson.rows[0][0].material_override!=lesson.rows[0][1].material_override and lesson.rows[0][0].material_override!=lesson.rows[1][0].material_override)
    var initial: Array[int]=lesson.record.duplicate()
    var generator:=RandomNumberGenerator.new()
    generator.seed=42
    var expected: Array[int]=[]
    for i in range(16):
        expected.append(generator.randi_range(0,3) if mode=="sampled" else (i%4 if mode=="cycle" else 0))
    check("record follows the declared sampled or edited procedure",initial==expected)
    if mode=="sampled":check("sampler makes exactly sixteen bounded integer requests",lesson.rng.state==generator.state)
    else:check("regular-pattern edit makes no random requests",lesson.rng.state==generator.state)
    var known: Array[int]=[0,1,0,2]
    check("counts use symbol IDs as addresses",lesson.counts_of(known)==[2,1,1,0])
    var balanced: Array[int]=[4,4,4,4]
    var single: Array[int]=[16,0,0,0]
    var unequal: Array[int]=[8,4,2,2]
    check("four equal shares give two bits",is_equal_approx(lesson.entropy_of(balanced),2.0))
    check("one observed symbol and zero-count terms give finite zero",is_finite(lesson.entropy_of(single)) and is_zero_approx(lesson.entropy_of(single)))
    check("nonuniform shares give the hand-calculated 1.75 bits",absf(lesson.entropy_of(unequal)-1.75)<0.000001)
    var state: int=lesson.rng.state
    await create_timer(0.1).timeout
    check("waiting preserves sample and generator state",lesson.record==initial and lesson.rng.state==state)
    var counts: Array[int]=lesson.counts_of(initial)
    var h: float=lesson.entropy_of(counts)
    lesson.point.position.x=0
    lesson.point.action()
    var sorted_expected: Array[int]=initial.duplicate()
    sorted_expected.sort()
    check("middle trigger sorts the copy",lesson.sorted_view and lesson.shown==sorted_expected)
    check("sorting preserves original order",lesson.record==initial)
    check("sorting makes no random requests",lesson.rng.state==state)
    check("sorting preserves counts and entropy",lesson.counts_of(lesson.shown)==counts and is_equal_approx(lesson.entropy_of(lesson.counts_of(lesson.shown)),h))
    var original_picture:=true
    for i in range(16):original_picture=original_picture and lesson.rows[0][i].material_override.albedo_color==lesson.palette[initial[i]]
    check("original row still displays original positions",original_picture)
    lesson.shown[0]=(lesson.shown[0]+1)%4
    check("editing the copy cannot alter the original",lesson.record==initial)
    lesson.draw_state()
    lesson.point.position.x=-1.2
    lesson.point.action()
    check("replay reconstructs the sample and retains selected sort mode",lesson.record==initial and lesson.sorted_view and lesson.shown==sorted_expected)
    lesson.point.position.x=0
    lesson.point.action()
    check("second sort trigger returns the original copy",not lesson.sorted_view and lesson.shown==initial)
    lesson.point.position.x=1.2
    lesson.point.action()
    check("right trigger chooses next integer seed",lesson.seed_value==43)
    var next: Array[int]=lesson.record.duplicate()
    lesson.new_sample()
    check("new seed also reconstructs consistently",lesson.record==next)
    # A perfectly periodic counterexample to equating this number with unpredictability.
    lesson.record.clear()
    for i in range(16):lesson.record.append(i%4)
    lesson.sorted_view=true
    lesson.draw_state()
    check("periodic witness has maximum marginal entropy",lesson.counts_of(lesson.record)==balanced and is_equal_approx(lesson.entropy_of(lesson.counts_of(lesson.record)),2))
    check("periodic witness has fifteen unlike adjacent pairs; sorted has three",lesson.neighbour_changes(lesson.record)==15 and lesson.neighbour_changes(lesson.shown)==3)
    var bars_valid:=true
    for bar in lesson.bars:bars_valid=bars_valid and bar.visible and is_equal_approx(bar.scale.y,0.175) and is_equal_approx(bar.position.y-bar.scale.y*0.5,0.95)
    check("balanced bars show quarter height on fixed common baseline",bars_valid)
    var kept: Array[int]=lesson.record.duplicate()
    lesson.palette[0]=Color(0.6,0.5,0.3)
    lesson.draw_state()
    check("palette edit leaves categorical measurement unchanged",lesson.record==kept and is_equal_approx(lesson.entropy_of(lesson.counts_of(lesson.record)),2))
    lesson.record.fill(0)
    lesson.draw_state()
    check("single-symbol record has no unlike neighbours",lesson.neighbour_changes(lesson.record)==0 and lesson.neighbour_changes(lesson.shown)==0)
    check("zero-count bars are hidden while their category labels remain",lesson.bars[0].visible and not lesson.bars[1].visible and not lesson.bars[2].visible and not lesson.bars[3].visible and lesson.captions[3].text=="3: 0")
    check("full sample in one category has full bar height",is_equal_approx(lesson.bars[0].scale.y,0.7))
    var other=script.new()
    other.sample_count=12
    other.palette.resize(3)
    other.seed_value=731
    root.add_child(other)
    other.record.clear()
    for i in range(12):other.record.append(i%3)
    other.sorted_view=true
    other.draw_state()
    check("three-category transfer changes alphabet and ceiling",other.bars.size()==3 and other.counts_of(other.record)==[4,4,4] and absf(other.entropy_of(other.counts_of(other.record))-log(3.0)/log(2.0))<0.000001)
    check("three-category transfer retains eleven versus two adjacent changes",other.neighbour_changes(other.record)==11 and other.neighbour_changes(other.shown)==2)
    check("instances retain independent records and generators",lesson.record[0]==0 and lesson.record[-1]==0 and lesson.rng!=other.rng)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"mode":mode,"engine":Engine.get_version_info(),"scope":"Fresh printed-file reconstruction and authored variations. Inherited action() at prescribed poses; no physical headset or independent learner."},"  "))
    file.close()
    lesson.free();other.free()
    quit(0 if failures.is_empty() else 1)
