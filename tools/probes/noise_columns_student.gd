extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[columns learner] ", "PASS " if ok else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := ""
    var report := ""
    var changed := false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source = arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
        if arg == "--changed": changed = true
    var study = load(source).new()
    study.position = Vector3(4, 0, 7)
    study.rotation.y = PI / 3
    root.add_child(study)
    study.set_process(false)
    var gain := .35 if changed else .70
    check("entry creates three shafts, its own label and the inherited control", study.shafts.size() == 3 and study.label.is_inside_tree() and study.control.has_method("pick_up"))
    check("declared field has explicit seed, type, frequency and no layers", study.noise.seed == 31415 and study.noise.noise_type == FastNoiseLite.TYPE_SIMPLEX and is_equal_approx(study.noise.frequency, .35) and study.noise.fractal_type == FastNoiseLite.FRACTAL_NONE)
    check("control begins at its declared local position", study.control.position.is_equal_approx(Vector3(0,1,1)))
    await create_timer(.25).timeout
    check("physics retains the control's initial position in a rotated host", study.control.position.is_equal_approx(Vector3(0,1,1)) and study.control.freeze)
    var first = study.shafts[0]
    var rest: Array = first.rest.duplicate()
    var faces: Array = first.faces.duplicate()
    check("Bernini construction has 138 positions and 272 triangles", rest.size() == 138 and faces.size() == 272)
    check("all shafts use the same receiver recipe", study.shafts[1].rest == rest and study.shafts[2].faces == faces)
    var indices_ok := true
    for face in faces:
        for index in [face.x,face.y,face.z]: indices_ok = indices_ok and index >= 0 and index < rest.size()
    check("all face indices refer to a stored position", indices_ok)
    check("sine fixture at start is one half", is_equal_approx(study.driver("periodic", 0), .5))
    check("sine fixture at quarter period is one", is_equal_approx(study.driver("periodic", PI / (2*.9)), 1))
    check("sine fixture at three quarter period is zero", is_zero_approx(study.driver("periodic", 3*PI / (2*.9))))
    check("sine returns after TAU/.9", is_equal_approx(study.driver("periodic", 1.25), study.driver("periodic",1.25 + TAU/.9)))
    check("held value ignores elapsed time", is_equal_approx(study.driver("held",0),.1) and is_equal_approx(study.driver("held",99),.1))
    var field_value: float = study.driver("field", 8.25)
    study.driver("field", 127)
    check("field queries have no draw history", study.driver("field",8.25) == field_value)
    check("time selects the declared two-dimensional address", is_equal_approx(field_value,clampf(study.noise.get_noise_2d(8.25*.55,0)*.5+.5,0,1)))
    var samples := []
    var bounded := true
    for i in range(200):
        var v: float = study.driver("field",i*.1)
        samples.append(v)
        bounded = bounded and v >= 0 and v <= 1
    check("field is bounded and varies along the chosen path", bounded and samples.max()-samples.min() > .05)
    check("field does not copy the sine's period at this witness address", absf(field_value-study.driver("field",8.25+TAU/.9)) > .001)
    study.time = PI / (2*.9)
    study.draw_values()
    check("quarter-period top has predicted height", is_equal_approx(study.shafts[1].points[-1].y,2.4-gain))
    check("baseline drop is one tenth of the selected gain", is_equal_approx(first.points[-1].y,2.4-gain*.1))
    first.receive(1.0,gain)
    var positions: Array = first.points.duplicate()
    check("foot stays and quarter-height receives half the drop", is_zero_approx(first.points[0].y) and is_equal_approx(first.points[4*8].y,.6-gain*.5))
    check("receiver changes height but not local X/Z", xz_same(first))
    first.receive(1.0,gain)
    check("same input cannot accumulate deformation", first.points == positions and first.rest == rest)
    first.receive(0.0,gain)
    check("zero value restores the original positions", first.points == rest)
    first.receive(.9,0)
    check("zero gain restores positions without changing faces", first.points == rest and first.faces == faces)
    first.receive(.5,gain)
    check("rendered triangle vertices match the stored positions", rendered(first))
    check("display mesh has no supporting collider", first.find_children("*","CollisionObject3D",true,false).is_empty())
    study.time = 0.0
    study.draw_values()
    study.next_update = 1.0/12.0
    var mesh_id: int = first.mesh.get_instance_id()
    study._process(.01)
    check("between updates the clock advances while mesh holds", is_equal_approx(study.time,.01) and first.mesh.get_instance_id() == mesh_id)
    study._process(.09)
    check("crossing the update interval displays current values", is_equal_approx(study.time,.1) and first.mesh.get_instance_id() != mesh_id and is_equal_approx(study.phases[1],sin(.09)*.5+.5))
    var held_mesh: int = first.mesh.get_instance_id()
    var held_values: Array = study.phases.duplicate()
    study._process(.01)
    var t: float = study.time
    study.control.action()
    study._process(2.0)
    check("inherited trigger holds time and last displayed mesh", not study.playing and study.time == t and first.mesh.get_instance_id() == held_mesh and study.phases == held_values)
    check("paused label reports held status", " / HELD / " in study.label.text)
    var other = load(source).new()
    root.add_child(other)
    other.set_process(false)
    other._process(.5)
    check("pause is local to one instance", is_equal_approx(other.time,.5) and study.time == t and other.noise != study.noise)
    study.control.action()
    study._process(.5)
    check("trigger resumes from held time", study.playing and is_equal_approx(study.time,t+.5))
    if changed:
        var same_inputs: float = study.driver("periodic",2.0)
        first.receive(same_inputs,.7)
        var full: Array = first.points.duplicate()
        first.receive(same_inputs,study.top_drop)
        var halved := true
        for i in range(rest.size()): halved = halved and is_equal_approx(rest[i].y-first.points[i].y,(rest[i].y-full[i].y)*.5)
        check("edited program halves displacement at every stored position", halved)
    var file := FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"changed":changed,"engine":Engine.get_version_info(),"scope":"Exact printed code in prepared museum project; author-informed automated learner reconstruction, not headset or human learning evidence."},"  "))
    file.close()
    study.free();other.free()
    quit(0 if failures.is_empty() else 1)

func xz_same(s: MeshInstance3D) -> bool:
    for i in range(s.rest.size()):
        if not Vector2(s.rest[i].x,s.rest[i].z).is_equal_approx(Vector2(s.points[i].x,s.points[i].z)):return false
    return true

func rendered(s: MeshInstance3D) -> bool:
    var vertices: PackedVector3Array = s.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    var i := 0
    for face in s.faces:
        for index in [face.x,face.y,face.z]:
            if not vertices[i].is_equal_approx(s.points[index]):return false
            i += 1
    return i == vertices.size()
