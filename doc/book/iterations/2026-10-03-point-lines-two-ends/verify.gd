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
    # process_frame is emitted before node _process callbacks; inspect the drawn frame.
    await RenderingServer.frame_post_draw

func capture(name: String):
    await frames(8)
    await RenderingServer.frame_post_draw
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func line_meets_ends(label: String):
    var half: Vector3 = study.segment.basis.y * study.segment.mesh.height * 0.5
    check(label + " starts at A", (study.segment.position - half).is_equal_approx(study.a.position))
    check(label + " ends at B", (study.segment.position + half).is_equal_approx(study.b.position))

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    room = load("res://point_lines.tscn").instantiate()
    root.add_child(room)
    await frames(30)
    study = room.get_node("Study")
    check("Lesson creates two handles and three drawing nodes", study.get_child_count() == 5)
    check("Initial distance is 1.5 metres", study.distance_readout.text == "1.50 m")
    check("Handles keep the same parent frame", study.a.get_parent() == study and study.b.get_parent() == study)
    line_meets_ends("Horizontal segment")
    await capture("room.png")

    study.b.position.x = 0.25
    await frames(3)
    print("one metre readout: ", study.distance_readout.text)
    check("One edited X component produces one metre", study.distance_readout.text == "1.00 m")
    study.b.position = Vector3(-0.75, 2.62, 0)
    await frames(3)
    check("Vertical turn preserves length", absf(study.segment.mesh.height - 1.5) < 0.00001)
    line_meets_ends("Vertical segment")
    await capture("upright.png")
    study.b.position = Vector3(-0.75, -0.38, 0)
    await frames(3)
    line_meets_ends("Downward segment")
    study.b.position = Vector3(0.75, 1.8, 0.8)
    await frames(3)
    line_meets_ends("Segment with depth")
    await capture("depth.png")

    study.b.position = study.a.position
    await frames(3)
    print("coincident readout: ", study.distance_readout.text, " visible=", study.segment.visible)
    check("Coincidence reads zero and hides the segment", study.distance_readout.text == "0.00 m" and not study.segment.visible)
    study.b.position = Vector3(0.75, 1.12, 0)
    await frames(3)
    check("Separating the ends restores the segment", study.segment.visible and study.distance_readout.text == "1.50 m")

    var player = room.player
    player.position = Vector3(0.75, 0, 0.65)
    player.camera.look_at(study.b.global_position)
    await frames(3)
    player.interact()
    await frames(3)
    check("Desktop aim picks up endpoint B", study.b.is_picked_up() and player.grabber.picked_up_object == study.b)
    var original: Vector3 = study.b.global_position
    player.position.x += 0.6
    await frames(5)
    check("Desktop hold moves the endpoint", study.b.global_position.distance_to(original) > 0.4)
    line_meets_ends("Held endpoint segment")
    check("Readout follows the moved endpoint", study.distance_readout.text == "%.2f m" % (study.b.position - study.a.position).length())
    player.interact()
    await frames(3)
    var released: Vector3 = study.b.global_position
    await frames(35)
    check("Release leaves endpoint in place", not study.b.is_picked_up() and study.b.freeze and study.b.global_position.distance_to(released) < 0.00001)

    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker, Vector3(-0.75, 1.12, -0.7))
    room.add_child(xr)
    await frames(10)
    tracker.set_input("grip", 1.0)
    await frames(5)
    check("Synthetic XR near grip picks up endpoint A", xr.pickups[0].picked_up_object == study.a and study.a.is_picked_up())
    pose(tracker, Vector3(-1.25, 1.5, -0.7))
    await frames(5)
    check("Synthetic grip moves endpoint without reparenting", study.a.get_parent() == study and study.a.global_position.y > 1.3)
    line_meets_ends("XR held segment")
    tracker.set_input("grip", 0.0)
    await frames(4)
    released = study.a.global_position
    await frames(30)
    check("Synthetic XR release keeps the chosen position", not study.a.is_picked_up() and study.a.global_position.distance_to(released) < 0.00001)
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)

    var reverse := GDScript.new()
    reverse.source_code = FileAccess.get_file_as_string("res://studies/point_lines/line.gd").replace("b.position - a.position", "a.position - b.position")
    check("Reverse subtraction edit compiles", reverse.reload() == OK)
    var bare := Node3D.new()
    bare.set_script(reverse)
    bare.position = Vector3(0, 0, 15)
    root.add_child(bare)
    await frames(3)
    check("Complete lesson constructs its nodes on a bare Node3D", bare.get_child_count() == 5)
    check("Reversal changes displacement but not distance", bare.displacement_readout.text == str(Vector3(-1.5, 0, 0)) and bare.distance_readout.text == "1.50 m")
    bare.queue_free()
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "physical_headset_tested": false, "xr_input": "Synthetic grip tracker; no headset"}, "\t"))
    print("Point Lines: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
