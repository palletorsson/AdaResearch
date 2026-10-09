extends SceneTree

const Memory = preload("res://prepared/trace_memory.gd")
var out: String
var checks: Array = []
var failed := false
var room
var study

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    Memory.path = out.path_join("test-record-" + str(OS.get_process_id()) + ".json")
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

func open_room(scene: String, step: float = 0.25):
    if is_instance_valid(room):
        room.queue_free()
        await frames(3)
    room = load(scene).instantiate()
    study = room.get_node("Study")
    if scene == "res://point_grid.tscn":
        study.grid_size = step
    root.add_child(room)
    await frames(20)

func capture(name: String):
    await frames(5)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name)) == OK)

func pose(tracker: XRPositionalTracker, at: Vector3):
    tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run():
    check("No record exists for this isolated run", Memory.read_trace().is_empty())
    await open_room("res://point_grid.tscn")
    check("Grid shows an honest empty state without a sample substitute", study.source_points.is_empty() and study.grid_points.is_empty() and "Draw in Point Trace" in study.comparison.message.text)
    await capture("empty.png")
    var bad := FileAccess.open(Memory.path, FileAccess.WRITE)
    bad.store_string("{broken")
    bad.close()
    check("Malformed record is rejected without constructing a gesture", Memory.read_trace().is_empty())
    bad = FileAccess.open(Memory.path, FileAccess.WRITE)
    bad.store_string(JSON.stringify({"version":1,"frame":"wrong frame","points":[[0,1,0],[1,1,0]]}))
    bad.close()
    check("A mismatched coordinate frame is rejected", Memory.read_trace().is_empty())

    var tiny: Array[Vector3] = [Vector3(0.0000000123, 1, 0), Vector3(-0.0000000099, 1, 0)]
    check("Snapshot preserves very small coordinates exactly", Memory.save_trace(tiny) == OK and Memory.read_trace() == tiny)

    await open_room("res://point_trace.tscn")
    var player = room.player
    player.position = Vector3(-0.75, 0, 0.65)
    player.camera.look_at(study.point.global_position)
    await frames(3)
    player.interact()
    await frames(4)
    check("Desktop pickup reaches the Trace point", study.point.is_picked_up())
    for delta in [Vector2(100, 0), Vector2(0, -100), Vector2(-100, 0), Vector2(0, 100)]:
        var event := InputEventMouseMotion.new()
        event.relative = delta
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        player._unhandled_input(event)
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        await frames(4)
    check("Injected mouse motion creates a trace through the actual hold", study.points.size() >= 5)
    player.interact()
    await frames(4)
    var mouse_record = study.points.duplicate()
    check("Desktop release saves the exact retained list", Memory.read_trace() == mouse_record)
    check("Release reports the successful handoff in the room", study.memory.status.text == "Saved for Point Grid")
    var saved_hash := FileAccess.get_sha256(Memory.path)
    study.points[0] += Vector3(9, 0, 0)
    check("Saved record is a snapshot, independent of subsequent list changes", Memory.read_trace() == mouse_record and FileAccess.get_sha256(Memory.path) == saved_hash)
    study.points[0] = mouse_record[0]
    await open_room("res://point_grid.tscn")
    check("Grid reuses the actual mouse trace rather than starting another recording", study.source_points == mouse_record)
    check("Mapping preserves one entry per source entry", study.grid_points.size() == mouse_record.size())
    check("Source array remains unchanged after mapping", study.source_points == Memory.read_trace())
    check("Each drawing uses the same fit", study.comparison.original.scale == study.comparison.rounded.scale)
    check("Comparison separation is a display translation only", (study.comparison.rounded.position - study.comparison.original.position).is_equal_approx(Vector3(2.44, 0, 0)))
    study.source_points[0] += Vector3(1, 0, 0)
    check("Grid's loaded list cannot mutate the saved file", FileAccess.get_sha256(Memory.path) == saved_hash and Memory.read_trace() == mouse_record)

    var fixture: Array[Vector3] = [Vector3(0.12, 1.25, 0), Vector3(0.13, 1.25, 0), Vector3(-0.12, 1.25, 0), Vector3(-0.13, 1.25, 0), Vector3(-0.125, 1.25, 0), Vector3(0.125, 1.25, 0)]
    check("A later valid save replaces the previous snapshot", Memory.save_trace(fixture) == OK and Memory.read_trace() == fixture)
    await open_room("res://point_grid.tscn")
    var expected: Array[Vector3] = [Vector3(0,1.25,0),Vector3(0.25,1.25,0),Vector3(0,1.25,0),Vector3(-0.25,1.25,0),Vector3(-0.25,1.25,0),Vector3(0.25,1.25,0)]
    check("Mapping handles boundaries, negatives and exact halfway values", study.grid_points == expected)
    check("Repeated grid positions retain their entries and order", study.grid_points.size() == fixture.size() and study.grid_points[3] == study.grid_points[4])
    check("Equal neighbouring outputs draw no spurious segment", not study.comparison.rounded.strokes[3].get_child(0).visible)
    saved_hash = FileAccess.get_sha256(Memory.path)
    var before = study.source_points.duplicate()
    await open_room("res://point_grid.tscn", 0.5)
    check("Coarser spacing starts again from the original source", study.source_points == before and study.grid_points.size() == before.size())
    check("Coarser output changes while the saved data stays fixed", study.grid_points != expected and FileAccess.get_sha256(Memory.path) == saved_hash)
    await open_room("res://point_grid.tscn", 0.25)
    check("Returning to a spacing reproduces the original result", study.grid_points == expected)
    check("A too-short save leaves the previous drawing intact", Memory.save_trace([Vector3.ZERO]) != OK and FileAccess.get_sha256(Memory.path) == saved_hash)
    await open_room("res://point_grid.tscn", 0)
    check("Invalid spacing is reported without dividing by zero", study.grid_points.is_empty() and "positive" in study.comparison.message.text)

    await open_room("res://point_trace.tscn")
    var xr = load("res://prepared/xr_player.gd").new()
    var tracker := XRControllerTracker.new()
    tracker.name = "left_hand"
    tracker.type = XRServer.TRACKER_CONTROLLER
    tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
    XRServer.add_tracker(tracker)
    pose(tracker, study.point.global_position)
    xr.camera.position.y = 1.65 # Synthetic head height; keep the XR body on the floor.
    room.add_child(xr)
    room.player.camera.current = true
    await frames(10)
    tracker.set_input("grip", 1.0)
    await frames(5)
    check("Synthetic XR grip reaches the same recording point", xr.pickups[0].picked_up_object == study.point)
    for i in range(1, 101):
        var angle := PI + TAU * i / 100.0
        pose(tracker, Vector3(0.75 * cos(angle), 1.25 + 0.4 * sin(angle), -0.7 + 0.18 * sin(2 * angle)))
        await frames(2)
    tracker.set_input("grip", 0.0)
    await frames(5)
    var xr_record = study.points.duplicate()
    check("Synthetic XR release saves the exact hand trace", xr_record.size() > 20 and Memory.read_trace() == xr_record and study.memory.status.text == "Saved for Point Grid")
    check("New release replaces rather than appends to the earlier drawing", Memory.read_trace().size() == xr_record.size())
    await capture("trace-saved.png")
    xr.queue_free()
    await frames(3)
    XRServer.remove_tracker(tracker)
    saved_hash = FileAccess.get_sha256(Memory.path)
    await open_room("res://point_grid.tscn")
    check("Grid loads the released synthetic hand trace", study.source_points == xr_record)
    var fine = study.grid_points.duplicate()
    var fit: Vector3 = study.comparison.original.scale
    await capture("quarter.png")
    await open_room("res://point_grid.tscn", 0.5)
    check("Both views keep their source-based fit when spacing changes", study.comparison.original.scale == fit and study.comparison.rounded.scale == fit)
    check("Coarse hand-trace mapping retains the original and its sample count", study.source_points == xr_record and study.grid_points.size() == xr_record.size() and study.grid_points != fine)
    check("Repeated Grid runs never overwrite the saved gesture", FileAccess.get_sha256(Memory.path) == saved_hash)
    await capture("half.png")
    FileAccess.open(out.path_join("saved-record-path.txt"), FileAccess.WRITE).store_string(Memory.path)
    room.queue_free()
    await frames(3)
    var report := {"passed": not failed, "checks": checks, "writer_process_id": OS.get_process_id(), "saved_points": xr_record.size(), "saved_sha256": saved_hash, "physical_headset_tested": false, "desktop_input": "Mouse-motion events injected into the real desktop player handler", "xr_input": "Synthetic tracked poses and grip; no headset", "screenshots": "Native Godot views of the SAME trace saved by synthetic grip release"}
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
    print("Trace return: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
