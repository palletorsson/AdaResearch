extends SceneTree

var out: String
var checks: Array = []
var failed := false
var room
var study
const SOURCE = "res://studies/trans_pre/motion.gd"
const LINEAR = "var t := pingpong(elapsed / leg_seconds + 0.5, 1.0)"
const SINE = "var t := (sin(TAU * elapsed / (2.0 * leg_seconds)) + 1.0) / 2.0"

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(label: String, passed: bool):
    checks.append({"check": label, "passed": passed})
    if not passed:
        failed = true
        push_error(label)

func frames(count := 3):
    for i in count:
        await physics_frame
    await process_frame
    await RenderingServer.frame_post_draw

func capture(filename: String):
    await frames()
    check("Native room capture: " + filename, root.get_texture().get_image().save_png(out.path_join(filename)) == OK)

func edit(changes: Dictionary):
    var code := GDScript.new()
    code.source_code = FileAccess.get_file_as_string(SOURCE)
    for before in changes:
        check("Printed edit target exists: " + before, code.source_code.contains(before))
        code.source_code = code.source_code.replace(before, changes[before])
    check("Actual edited learner source compiles", code.reload() == OK)
    if is_instance_valid(study):
        study.free()
    study = code.new()
    study.position = Vector3(0, 0, -0.7)
    room.add_child(study)
    study.set_process(false)
    await frames()

func pose(seconds: float):
    study.elapsed = 0.0
    study.cube.position = study.centre
    study.cube.rotation = Vector3.ZERO
    study.cube.scale = Vector3.ONE
    study._process(seconds)

func near(a: float, b: float) -> bool:
    return abs(a - b) < 0.00005

func uniform(value: float) -> bool:
    return study.cube.scale.is_equal_approx(Vector3.ONE * value)

func run():
    room = load("res://trans_pre.tscn").instantiate()
    root.add_child(room)
    study = room.get_node("Study")
    study.set_process(false)
    await frames(18)
    room.player.position = Vector3(0.4, 0, 3.0)
    room.player.camera.look_at(Vector3(0, 1.4, -0.7))
    pose(2.0)
    check("Stage zero: elapsed seconds advance while all transforms stay still", near(study.elapsed, 2.0) and study.cube.position == study.centre and study.cube.rotation.is_zero_approx() and uniform(1.0))
    check("Code-created mesh has the documented size and one attached orientation mark", study.cube.mesh.size.is_equal_approx(Vector3.ONE * 0.6) and study.cube.get_child_count() == 1)
    await capture("still.png")

    await edit({"var stage := 0": "var stage := 1"})
    var samples_ok := true
    for sample in [[0.0, 1.3], [0.75, 1.55], [1.5, 1.3], [2.25, 1.05], [3.0, 1.3]]:
        pose(sample[0])
        samples_ok = samples_ok and near(study.cube.position.y, sample[1]) and study.cube.position.x == 0 and study.cube.position.z == 0 and study.cube.rotation.is_zero_approx() and uniform(1.0)
    check("Stage one: independent midpoint/end/return values; no rotation or scaling", samples_ok)
    pose(0.75)
    await capture("rise.png")
    pose(2.25)
    await capture("fall.png")
    pose(0.375)
    var linear_quarter: float = study.cube.position.y
    await capture("linear.png")

    await edit({"var stage := 0": "var stage := 1", "var travel := 0.25": "var travel := 0.4"})
    pose(0.75)
    var high_correct: bool = near(study.cube.position.y, 1.7)
    pose(2.25)
    check("Printed extent edit reaches 0.9 and 1.7 at the same times", high_correct and near(study.cube.position.y, 0.9))

    await edit({"var stage := 0": "var stage := 1", "var leg_seconds := 1.5": "var leg_seconds := 3.0"})
    pose(1.5)
    high_correct = near(study.cube.position.y, 1.55)
    pose(4.5)
    var low_correct: bool = near(study.cube.position.y, 1.05)
    pose(6.0)
    check("Printed duration edit doubles the period to six seconds without changing endpoints", high_correct and low_correct and near(study.cube.position.y, 1.3))

    await edit({"var stage := 0": "var stage := 2"})
    pose(1.0)
    check("Stage two: one eighth of a turn after one second, with the previous translation and unit scale", study.cube.basis.is_equal_approx(Basis(Vector3.UP, TAU / 8.0)) and near(study.cube.position.y, 1.4666666667) and uniform(1.0))
    pose(2.0)
    check("Stage two quarter-turn keeps the local centre on its path", study.cube.basis.is_equal_approx(Basis(Vector3.UP, PI / 2.0)) and near(study.cube.position.y, 1.1333333333))
    pose(0.75)
    await capture("turn.png")
    pose(8.0)
    check("Eight-second rotation returns the marked face to its orientation", study.cube.basis.is_equal_approx(Basis.IDENTITY))
    await edit({"var stage := 0": "var stage := 2", "TAU / 8.0": "TAU / 4.0"})
    pose(4.0)
    check("Printed rate edit gives a four-second full turn", study.cube.basis.is_equal_approx(Basis.IDENTITY))

    await edit({"var stage := 0": "var stage := 3"})
    pose(0.75)
    high_correct = near(study.cube.position.y, 1.55) and uniform(1.3)
    await capture("large.png")
    pose(2.25)
    check("Stage three links the documented height and uniform scale extrema", high_correct and near(study.cube.position.y, 1.05) and uniform(0.7))
    await capture("small.png")
    var vertices: PackedVector3Array = study.cube.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
    pose(0.0)
    for i in 3600:
        study._process(1.0 / 60.0)
    check("Sixty seconds of updates do not accumulate scale or rewrite the mesh", uniform(1.0) and study.cube.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == vertices)
    pose(0.0)
    for i in 30:
        study._process(1.0 / 30.0)
    var thirty: Transform3D = study.cube.transform
    pose(0.0)
    for i in 120:
        study._process(1.0 / 120.0)
    check("Different frame partitions give the same pose after one second", study.cube.transform.is_equal_approx(thirty))
    var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1.4, 0), Vector3(0, 1.4, -2))
    check("This study does not introduce an implicit cube or backdrop collider", study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    ray = PhysicsRayQueryParameters3D.create(Vector3(1, 0.5, 0), Vector3(1, -0.5, 0))
    check("Prepared room floor still supports the visitor", not study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    await edit({"var stage := 0": "var stage := 3", "var pulse := 0.3": "var pulse := 0.1"})
    pose(0.75)
    high_correct = uniform(1.1)
    pose(2.25)
    check("Printed pulse edit changes only scale extent", high_correct and uniform(0.9) and near(study.cube.position.y, 1.05))

    await edit({"var stage := 0": "var stage := 1", LINEAR: SINE})
    samples_ok = true
    for sample in [[0.0, 1.3], [0.75, 1.55], [1.5, 1.3], [2.25, 1.05], [3.0, 1.3]]:
        pose(sample[0])
        samples_ok = samples_ok and near(study.cube.position.y, sample[1])
    check("Actual printed sine replacement preserves initial position, extrema times and period", samples_ok)
    pose(0.375)
    check("Between the same endpoints, sine has a different progress at the same time", near(study.cube.position.y, 1.4767766953) and study.cube.position.y > linear_quarter)
    await capture("sine.png")
    pose(0.74)
    var before_top: float = study.cube.position.y
    pose(0.75)
    check("Sine approaches its end more slowly than linear motion", abs(study.cube.position.y - before_top) < 0.0001)
    await edit({"var stage := 0": "var stage := 1", LINEAR: SINE, "var leg_seconds := 1.5": "var leg_seconds := 3.0"})
    pose(1.5)
    high_correct = near(study.cube.position.y, 1.55)
    pose(6.0)
    check("Sine's printed duration edit keeps its extent and gives a six-second return", high_correct and near(study.cube.position.y, 1.3))
    await edit({"var stage := 0": "var stage := 1", LINEAR: SINE, "var travel := 0.25": "var travel := 0.4"})
    pose(0.75)
    high_correct = near(study.cube.position.y, 1.7)
    pose(2.25)
    check("Sine's printed extent edit keeps the period and reaches 0.9 / 1.7", high_correct and near(study.cube.position.y, 0.9))

    var bare = load(SOURCE).new()
    bare.position = Vector3(30, 0, 0)
    root.add_child(bare)
    bare.set_process(false)
    check("Original script constructs on an empty Node3D with direct references", bare.cube.get_parent() == bare and bare.readout.get_parent() == bare and bare.stage == 0)
    bare.free()

    await edit({"var stage := 0": "var stage := 3"})
    pose(0.0)
    var video_dir: String = OS.get_cmdline_user_args()[1]
    var video_ok := true
    for frame in 240:
        # Fixed simulation steps, native Godot rendering. The film represents eight seconds.
        if frame > 0:
            study._process(1.0 / 30.0)
        await process_frame
        await RenderingServer.frame_post_draw
        video_ok = video_ok and root.get_texture().get_image().save_png(video_dir.path_join("%04d.png" % frame)) == OK
    check("240 native frames recorded at the actual stage-three script's fixed 30 Hz progression", video_ok)
    room.queue_free()
    await frames()
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "godot": Engine.get_version_info().string, "physical_headset_tested": false, "scene": "trans_pre.tscn", "video_frames": 240, "evidence": "Printed edits compiled and run in the freshly extracted student room; deterministic native rendering."}, "\t"))
    print("Trans_Pre: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
