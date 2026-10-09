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

func fresh(step: float = 0.25):
    if is_instance_valid(study):
        study.queue_free()
        await frames(2)
    study = load("res://studies/point_grid/grid.gd").new()
    study.grid_size = step
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
        var angle := TAU * i / 120.0
        await place(Vector3(0.12 + 0.7 * sin(angle), 1.25 + 0.38 * sin(angle * 2.0), 0.3 * sin(angle)))
    # Close the scripted route exactly; avoid a floating-point -0.0 in the screenshots.
    await place(Vector3(0.12, 1.25, 0))

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    room = load("res://point_grid.tscn").instantiate()
    root.add_child(room)
    await frames(25)
    study = room.get_node("Study")
    check("Script constructs all seven lesson objects", study.get_child_count() == 7)
    check("Initial address counts grid steps", study.address_readout.text == "address  (0, 5, 0)")
    check("Placed marker converts address back into metres", study.marker.position == Vector3(0, 1.25, 0))
    check("Initial record is seeded without an empty-list read", study.points.size() == 1 and study.points[0] == study.marker.position)
    check("Quarter-metre reference lines match the declared spacing", study.ruling.line_count == 15)
    await capture("before-boundary.png")
    await place(Vector3(0.121, 1.25, 0))
    check("Movement inside an address leaves record unchanged", study.points.size() == 1 and study.marker.position == Vector3(0, 1.25, 0))
    await place(Vector3(0.13, 1.25, 0))
    check("Crossing halfway adds the next address", study.points.size() == 2 and study.address_readout.text == "address  (1, 5, 0)")
    check("One centimetre input change produces a quarter-metre placement change", study.marker.position == Vector3(0.25, 1.25, 0))
    check("Rounding the output does not move the held input", study.point.position == Vector3(0.13, 1.25, 0))
    await capture("after-boundary.png")
    await place(Vector3(0.12, 1.25, 0))
    check("Returning to an address records another ordered visit", study.points.size() == 3 and study.points[0] == study.points[2])
    await frames(35)
    check("Waiting at an address creates no duplicate visits", study.points.size() == 3)
    await place(Vector3(-0.12, 1.25, 0))
    check("Small negative input rounds back to zero", study.marker.position.x == 0 and study.points.size() == 3)
    await place(Vector3(-0.13, 1.25, 0))
    check("Crossing the negative boundary gives a negative address", study.marker.position.x == -0.25 and study.address_readout.text == "address  (-1, 5, 0)")
    await place(Vector3(-0.125, 1.25, 0))
    check("Negative halfway case rounds away from zero", study.marker.position.x == -0.25)
    await place(Vector3(0.125, 1.25, 0))
    check("Positive halfway case rounds away from zero", study.marker.position.x == 0.25)
    await place(Vector3(0.13, 1.63, -0.13))
    check("Each coordinate is rounded independently", study.marker.position == Vector3(0.25, 1.75, -0.25) and study.address_readout.text == "address  (1, 7, -1)")
    check("Snapped path joins consecutive records exactly", joined_correctly())

    await fresh()
    await place(Vector3(0.88, 1.63, 0.38))
    check("A jump records the reached address without filling skipped ones", study.points.size() == 2 and study.drawing.used == 1 and study.marker.position == Vector3(1.0, 1.75, 0.5))
    check("A connection can be diagonal in all three axes", joined_correctly())
    await capture("depth.png")

    await fresh()
    await route()
    var quarter_count: int = study.points.size()
    check("Every retained position lies on the quarter-metre lattice", study.points.all(func(p): return p.is_equal_approx(p.snapped(Vector3.ONE * 0.25))))
    check("Recorded route is ordered and bounded", quarter_count > 10 and quarter_count <= 128 and joined_correctly())
    await capture("quarter.png")
    await fresh(0.5)
    check("Coarser spacing changes the reference and the address", study.ruling.line_count == 8 and study.marker.position == Vector3(0, 1.5, 0) and study.address_readout.text == "address  (0, 3, 0)")
    await route()
    var half_count: int = study.points.size()
    check("The same test movement has fewer address changes on the coarser grid", half_count < quarter_count and half_count > 5)
    check("Coarse route stays on its own lattice", study.points.all(func(p): return p.is_equal_approx(p.snapped(Vector3.ONE * 0.5))) and joined_correctly())
    await capture("half.png")

    await fresh()
    study.capacity = 4
    for i in range(1, 9):
        await place(Vector3(i * 0.25, 1.25, 0))
    check("Inherited capacity keeps only the last four visits in order", study.points.size() == 4 and study.points[0] == Vector3(1.25, 1.25, 0) and study.points[3] == Vector3(2, 1.25, 0))
    check("Renderer remains bounded and reuses its segments", study.drawing.strokes.size() == 3 and joined_correctly())

    await fresh()
    var player = room.player
    player.position = Vector3(0.12, 0, 0.65)
    player.camera.look_at(study.point.global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop input can hold the unsnapped point", study.point.is_picked_up())
    var old_marker: Vector3 = study.marker.position
    player.position.x += 0.75
    await frames(6)
    check("Desktop hold moves across addresses while preserving input", study.marker.position.x != old_marker.x and study.marker.position.is_equal_approx(study.point.position.snapped(Vector3.ONE * 0.25)))
    player.interact()
    await frames(4)
    var released: Vector3 = study.point.position
    var retained = study.points.duplicate()
    await frames(30)
    check("Release freezes the input without an extra alignment rule", not study.point.is_picked_up() and study.point.position == released and study.points == retained)

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
    check("Synthetic XR near grip can hold the input", xr.pickups[0].picked_up_object == study.point)
    pose(tracker, Vector3(0.65, 1.6, -0.3))
    await frames(5)
    check("Synthetic grip updates all three address components", study.marker.position == Vector3(0.75, 1.5, 0.5) and joined_correctly())
    tracker.set_input("grip", 0.0)
    await frames(5)
    retained = study.points.duplicate()
    await frames(25)
    check("Synthetic XR release retains the ordered record", not study.point.is_picked_up() and study.points == retained)
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)

    var bare = load("res://studies/point_grid/grid.gd").new()
    bare.position = Vector3(0, 0, 15)
    root.add_child(bare)
    await frames(3)
    check("Lesson constructs its objects on a bare Node3D", bare.get_child_count() == 7 and bare.points.size() == 1)
    check("Grid addresses stay local when the study is translated", bare.marker.position == Vector3(0, 1.25, 0) and bare.marker.global_position == Vector3(0, 1.25, 15))
    bare.queue_free()
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "quarter_metre_visits": quarter_count, "half_metre_visits": half_count, "physical_headset_tested": false, "screenshots": "Native Godot desktop views; comparisons use scripted positions", "xr_input": "Synthetic grip tracker; no headset"}, "\t"))
    print("Point Grid: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
