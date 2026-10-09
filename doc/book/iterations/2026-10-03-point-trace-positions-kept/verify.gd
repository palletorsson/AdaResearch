extends SceneTree

var out: String
var checks: Array = []
var failed := false
var room
var study

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(label: String, passed: bool):
    checks.append({"check": label, "passed": passed})
    if not passed:
        failed = true
        push_error(label)

func frames(count: int):
    for i in count:
        await physics_frame
    await process_frame
    await RenderingServer.frame_post_draw

func capture(name: String):
    await frames(8)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func fresh():
    if is_instance_valid(study):
        study.queue_free()
        await frames(2)
    study = load("res://studies/point_trace/trace.gd").new()
    study.position = Vector3(0, 0, -0.7)
    room.add_child(study)
    await frames(3)

func place(at: Vector3):
    study.point.position = at
    await frames(2)

func joined_correctly() -> bool:
    if study.drawing.used != study.points.size() - 1:
        return false
    for i in range(study.drawing.used):
        var segment = study.drawing.strokes[i].get_child(0)
        var half: Vector3 = segment.basis.y * segment.mesh.height * 0.5
        if not (segment.position - half).is_equal_approx(study.points[i]):
            return false
        if not (segment.position + half).is_equal_approx(study.points[i + 1]):
            return false
    return true

func route():
    for i in range(1, 121):
        var angle := PI + TAU * i / 120.0
        await place(Vector3(0.75 * cos(angle), 1.25 + 0.48 * sin(angle), 0.22 * sin(angle * 2.0)))

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    room = load("res://point_trace.tscn").instantiate()
    root.add_child(room)
    await frames(25)
    study = room.get_node("Study")
    check("Point, drawing and readout constructed by the script", study.get_child_count() == 3)
    check("Ordered list is typed Vector3", study.points.get_typed_builtin() == TYPE_VECTOR3)
    check("Ready stores exactly one initial position", study.points.size() == 1 and study.points[0] == Vector3(-0.75, 1.25, 0))
    check("No segment exists before a second position", study.drawing.used == 0)
    await frames(35)
    check("Frames passing while still do not add samples", study.points.size() == 1)
    await place(Vector3(-0.72, 1.25, 0))
    check("A three centimetre move stays below the threshold", study.points.size() == 1)
    await place(Vector3(-0.69, 1.25, 0))
    check("Six centimetres from the saved position stays below threshold", study.points.size() == 1)
    await place(Vector3(-0.669, 1.25, 0))
    check("Accumulated separation admits a second position", study.points.size() == 2)
    check("Stored Vector3 does not follow its moved handle", study.points[0] == Vector3(-0.75, 1.25, 0))
    check("First saved pair is rendered exactly", joined_correctly())
    await place(Vector3(-0.669, 1.8, 0.2))
    await place(Vector3(0.2, 1.8, -0.2))
    check("Four entries produce three ordered segments", study.points.size() == 4 and joined_correctly())
    check("Counter reads retained entries", study.readout.text == "4 positions kept")

    await fresh()
    await route()
    var fine_count: int = study.points.size()
    check("Fine route retains multiple samples without hitting capacity", fine_count > 25 and fine_count < 128)
    check("Fine route rendering follows the saved list", joined_correctly())
    await capture("fine.png")
    await fresh()
    study.spacing = 0.25
    await route()
    var coarse_count: int = study.points.size()
    check("Same route at wider spacing keeps fewer samples", coarse_count < fine_count / 2 and coarse_count > 5)
    check("Coarse route joins samples rather than interpolating extra ones", joined_correctly())
    await capture("coarse.png")
    var saved = study.points.duplicate()
    var pool_count: int = study.drawing.strokes.size()
    await frames(80)
    check("Waiting retains the exact record", study.points == saved)
    check("Waiting allocates no new rendering nodes", study.drawing.strokes.size() == pool_count)

    await fresh()
    study.capacity = 4
    for i in range(1, 9):
        await place(Vector3(-0.75 + i * 0.15, 1.25, 0))
    check("Capacity removes oldest positions and retains order", study.points.size() == 4 and study.points[0].is_equal_approx(Vector3(0, 1.25, 0)) and study.points[3].is_equal_approx(Vector3(0.45, 1.25, 0)))
    check("Renderer has bounded reusable segments", study.drawing.strokes.size() == 3 and joined_correctly())
    study.drawing.clear()
    check("Clearing display does not clear the stored list", study.points.size() == 4 and not study.drawing.strokes[0].visible)
    await place(Vector3(0.7, 1.25, 0))
    check("Next sample restores only retained connections", joined_correctly() and study.drawing.strokes[0].visible)

    await fresh()
    study.capacity = 32
    await route()
    check("Museum memory experiment reaches 32 retained positions", study.points.size() == 32 and study.drawing.used == 31)
    await capture("memory.png")
    saved = study.points.duplicate()
    await frames(35)
    check("Capacity is not a timer; waiting removes nothing", study.points == saved)

    await fresh()
    var player = room.player
    player.position = Vector3(-0.75, 0, 0.65)
    player.camera.look_at(study.point.global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop aim can hold the recording point", study.point.is_picked_up() and player.grabber.picked_up_object == study.point)
    var held_count: int = study.points.size()
    player.position.x += 0.6
    await frames(5)
    check("Moving a held point adds saved positions", study.points.size() > held_count and joined_correctly())
    player.interact()
    await frames(4)
    saved = study.points.duplicate()
    await frames(35)
    check("Desktop release freezes the handle and retains the route", not study.point.is_picked_up() and study.point.freeze and study.points == saved)

    await fresh()
    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker, study.point.global_position)
    room.add_child(xr)
    await frames(10)
    tracker.set_input("grip", 1.0)
    await frames(5)
    check("Synthetic XR near grip holds the recording point", xr.pickups[0].picked_up_object == study.point)
    held_count = study.points.size()
    pose(tracker, Vector3(-0.2, 1.5, -0.4))
    await frames(5)
    check("Synthetic XR movement updates the trace in the same frame", study.points.size() > held_count and study.point.get_parent() == study and joined_correctly())
    tracker.set_input("grip", 0.0)
    await frames(5)
    saved = study.points.duplicate()
    await frames(25)
    check("Synthetic XR release preserves the saved route", not study.point.is_picked_up() and study.points == saved)
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)

    var bare = load("res://studies/point_trace/trace.gd").new()
    bare.position = Vector3(0, 0, 15)
    root.add_child(bare)
    await frames(3)
    bare.point.position += Vector3(0.5, 0, 0)
    await frames(3)
    check("Lesson runs on a bare Node3D without scene-authored objects", bare.points.size() == 2 and bare.drawing.used == 1 and bare.get_child_count() == 3)
    bare.queue_free()
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "fine_positions": fine_count, "coarse_positions": coarse_count, "physical_headset_tested": false, "screenshots": "Real Godot rendering of the same scripted route; not a headset recording", "xr_input": "Synthetic grip tracker; no headset"}, "\t"))
    print("Point Trace: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
