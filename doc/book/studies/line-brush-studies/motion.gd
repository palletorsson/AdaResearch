extends SceneTree
## Native orbit frames. This changes only the camera, never the stored drawing.
var room
var out: String

func _initialize() -> void:
    out = OS.get_cmdline_user_args()[0]
    DirAccess.make_dir_recursive_absolute(out)
    run.call_deferred()

func run() -> void:
    room = load("res://gallery.tscn").instantiate()
    root.add_child(room)
    for i in 8:
        await process_frame
    room.reset_example(2)
    room.width = .18
    room.rebuild()
    room.inspect(3)
    room.canvas.hide()
    room.distance = 9.0
    room.pitch = .09
    var original = room.strokes.duplicate(true)
    for i in 96:
        room.yaw = TAU * i / 96.0
        room.update_camera()
        await process_frame
        await RenderingServer.frame_post_draw
        var error = root.get_texture().get_image().save_png(out.path_join("orbit-%03d.png" % i))
        assert(error == OK)
    assert(room.strokes == original)
    print("96 native camera orbit frames; stored drawing unchanged.")
    quit()
