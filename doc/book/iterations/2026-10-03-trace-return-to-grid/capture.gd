extends SceneTree
const Memory = preload("res://prepared/trace_memory.gd")
var out: String

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func run():
    Memory.path = FileAccess.get_file_as_string(out.path_join("saved-record-path.txt"))
    var original := Memory.read_trace()
    var before := FileAccess.get_sha256(Memory.path)
    var passed := not original.is_empty()
    for step in [0.25, 0.5]:
        var room = load("res://point_grid.tscn").instantiate()
        var study = room.get_node("Study")
        study.grid_size = step
        root.add_child(room)
        for i in 20:
            await physics_frame
        await process_frame
        await RenderingServer.frame_post_draw
        passed = passed and study.source_points == original
        var name := "quarter.png" if step == 0.25 else "half.png"
        passed = passed and root.get_texture().get_image().save_png(out.path_join(name)) == OK
        room.queue_free()
        await process_frame
        await process_frame
    passed = passed and FileAccess.get_sha256(Memory.path) == before
    FileAccess.open(out.path_join("capture-verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"same_saved_record":true,"record_sha256":before}))
    quit(0 if passed else 1)
