extends SceneTree
const Memory = preload("res://prepared/trace_memory.gd")
var out: String

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func run():
    Memory.path = FileAccess.get_file_as_string(out.path_join("saved-record-path.txt"))
    var previous = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("verification.json")))
    var room = load("res://point_grid.tscn").instantiate()
    root.add_child(room)
    await process_frame
    await process_frame
    var study = room.get_node("Study")
    var checks: Array = [
        {"check":"This reader is a different engine process", "passed": OS.get_process_id() != previous.writer_process_id},
        {"check":"Trace survives stopping the previous process", "passed": study.source_points.size() == previous.saved_points and study.source_points == Memory.read_trace()},
        {"check":"Grid maps the persisted trace after restart", "passed": study.grid_points.size() == study.source_points.size() and study.grid_points.size() > 1},
        {"check":"Restart and read leave the saved bytes unchanged", "passed": FileAccess.get_sha256(Memory.path) == previous.saved_sha256}
    ]
    var passed := checks.all(func(c): return c.passed)
    FileAccess.open(out.path_join("restart-verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "reader_process_id": OS.get_process_id(), "checks": checks}, "\t"))
    room.queue_free()
    await process_frame
    print("Restart: ", checks.size(), " checks; passed: ", passed)
    quit(0 if passed else 1)
