extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[seed-study] ", "PASS " if value else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := ""
    var report := ""
    var mode := "rgb"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report=arg.trim_prefix("--report=")
        if arg.begins_with("--mode="): mode=arg.trim_prefix("--mode=")
    var script=load(source)
    var lesson=script.new()
    lesson.position=Vector3(4,0,7)
    lesson.rotation.y=PI/3
    root.add_child(lesson)
    check("two grids create sixteen cube meshes each", lesson.grids.size()==2 and lesson.grids[0].size()==16 and lesson.grids[1].size()==16)
    check("readout initialized in ready",lesson.label.is_inside_tree() and "48" in lesson.label.text)
    check("inherited point keeps pickup and frozen release",lesson.point.has_method("pick_up") and lesson.point.freeze and lesson.point.release_mode==lesson.point.ReleaseMode.FROZEN)
    check("point retains its original radius",is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    check("colour does not alter the cube's mesh construction",lesson.grids[0][0].mesh is BoxMesh)
    check("each cube owns its material",lesson.grids[0][0].material_override!=lesson.grids[0][1].material_override and lesson.grids[0][0].material_override!=lesson.grids[1][0].material_override)
    var positions: Array=[]
    for panel in lesson.grids:
        for cube in panel: positions.append(cube.position)
    var first: Array=lesson.samples.duplicate(true)
    check("same procedure makes equal panels",first[0]==first[1])
    lesson.replay()
    check("replay retains every stored colour",lesson.samples==first)
    var state: int=lesson.rng.state
    await create_timer(0.15).timeout
    check("waiting spends no draws",lesson.rng.state==state and lesson.samples==first)
    # Generate a flat stream independently, then group by indices outside lesson code.
    var expected:=RandomNumberGenerator.new()
    expected.seed=42
    var stream: Array[float]=[]
    for i in range(49): stream.append(expected.randf())
    lesson.point.position.x=0
    lesson.point.action()
    check("point action enables exactly one discarded draw",lesson.discard_first and "49" in lesson.label.text)
    check("discard leaves the left panel intact",lesson.samples[0]==first[0])
    var match_left:=true
    var match_right:=true
    for i in range(16):
        var j:=i*3
        var left:=mapped(stream[j],stream[j+1],stream[j+2],mode)
        var right:=mapped(stream[j+1],stream[j+2],stream[j+3],mode)
        match_left=match_left and lesson.samples[0][i]==left
        match_right=match_right and lesson.samples[1][i]==right
    check("all unshifted cells match the independently grouped stream",match_left)
    check("all shifted cells match the independently grouped stream",match_right)
    check("shifted procedure consumes exactly 49 draws",lesson.rng.state==expected.state)
    var shifted: Array=lesson.samples.duplicate(true)
    lesson.point.position.x=-0.8
    lesson.point.action()
    check("left trigger repeats the selected mismatch in a rotated host",lesson.samples==shifted and lesson.discard_first)
    lesson.point.position.x=0
    lesson.point.action()
    check("second middle trigger restores the match",not lesson.discard_first and lesson.samples==first)
    lesson.point.position.x=0.8
    lesson.point.action()
    check("right trigger increments seed rather than drawing one",lesson.seed_value==43)
    var second_seed: Array=lesson.samples.duplicate(true)
    lesson.replay()
    check("next seed also repeats",lesson.samples==second_seed)
    var unchanged:=true
    var k:=0
    var assigned:=true
    for panel in range(2):
        for i in range(16):
            unchanged=unchanged and lesson.grids[panel][i].position==positions[k]
            assigned=assigned and lesson.grids[panel][i].material_override.albedo_color==lesson.samples[panel][i]
            k+=1
    check("actions retain every cube position",unchanged)
    check("retained values are the actual material colours",assigned)
    var other=script.new()
    other.side=2
    other.seed_value=731
    root.add_child(other)
    other.discard_first=true
    other.replay()
    expected.seed=731
    for i in range(13):expected.randf()
    check("unprinted two-by-two variation uses 13 shifted draws",other.grids[0].size()==4 and other.rng.state==expected.state and "13" in other.label.text)
    check("instances own separate generators and records",other.rng!=lesson.rng and lesson.samples==second_seed)
    if mode=="gray":
        var grey:=true
        for colour in other.samples[1]:grey=grey and colour.r==colour.g and colour.g==colour.b
        check("edited assignment creates grayscale without dropping requests",grey)
    if mode=="swap":
        check("edited assignment swaps red and blue",first[0][0]==Color(stream[2],stream[1],stream[0]))
    var kept_seed: int=lesson.seed_value
    var kept_point: Node=lesson.point
    var slider=lesson.resolution
    slider.track.move_slider(0.8)
    check("slider selects sixteen-by-sixteen on the existing study",lesson.side==16 and lesson.grids[0].size()==256 and lesson.resolution==slider)
    check("size change preserves seed point and procedure",lesson.seed_value==kept_seed and lesson.point==kept_point and not lesson.discard_first)
    check("larger matrix retains the old colour prefix",lesson.samples[0].slice(0,16)==second_seed[0])
    check("larger matrix stays inside its original panel area",lesson.grids[0][0].position.x>-1.175 and lesson.grids[0][-1].position.x<-.175 and lesson.grids[0][-1].position.y<2.1)
    lesson.point.position.x=0
    lesson.point.action()
    check("large shifted panel consumes 769 requests",lesson.discard_first and "769" in lesson.label.text)
    slider.track.move_slider(0)
    check("slider selects two-by-two and retains discard",lesson.side==2 and lesson.grids[0].size()==4 and lesson.discard_first and "13" in lesson.label.text)
    slider.track.move_slider(0.8*2.0/14.0)
    check("returning to four restores the seeded left picture",lesson.side==4 and lesson.samples[0]==second_seed[0] and lesson.discard_first)
    lesson.point.position.x=0
    lesson.point.action()
    check("returning procedure restores both original pictures",lesson.samples==second_seed)
    # Exercise every actual track detent; the label, state and count must agree.
    var choices_ok:=true
    for size in range(2,17):
        slider.track.move_slider(0.8*float(size-2)/14.0)
        choices_ok=choices_ok and lesson.side==size and lesson.grids[0].size()==size*size and slider.side==size
    check("all fifteen slider choices are reachable",choices_ok)
    slider.track.move_slider(99)
    check("upper track boundary clamps at sixteen",lesson.side==16)
    slider.track.move_slider(-99)
    check("lower track boundary clamps at two",lesson.side==2)
    var handle=slider.track.find_children("*", "RigidBody3D", true, false)[0]
    slider.track.grabbed_handles.append(handle)
    handle.global_position=slider.track.to_global(Vector3(0.8*6.0/14,0,0))
    var held_position: Vector3=handle.global_position
    slider.track._process(0.016)
    check("hand displacement selects eight in a rotated study",lesson.side==8)
    check("moving track does not move the held hand twice",handle.global_position.is_equal_approx(held_position))
    slider.track._process(0.016)
    check("stationary hand keeps its selection",lesson.side==8)
    slider.track.grabbed_handles.clear()
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"mode":mode,"engine":Engine.get_version_info(),"scope":"Printed files reconstructed; actual inherited action method; prescribed point positions. No headset or independent learner claim."},"  "))
    file.close()
    lesson.free();other.free()
    quit(0 if failures.is_empty() else 1)

func mapped(a: float,b: float,c: float,mode: String) -> Color:
    if mode=="gray":return Color(a,a,a)
    if mode=="swap":return Color(c,b,a)
    return Color(a,b,c)
