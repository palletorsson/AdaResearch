extends SceneTree
## Isolated manual input session. Records only this test, never the user's F5 save.
var room
var out: String
var elapsed := 0.0
var records: Array = []

func _initialize() -> void:
    out = OS.get_cmdline_user_args()[0]
    start.call_deferred()

func start() -> void:
    room = load("res://study.tscn").instantiate()
    root.add_child(room)
    room.inspect(4)
    room.clear_brush()
    room.brush_radius = .11
    room.update_detail()
    process_frame.connect(record_frame)

func record_frame() -> void:
    elapsed += room.get_process_delta_time()
    if elapsed < 2.0:
        return
    elapsed = 0.0
    var state := {"count": room.brush_count, "style": room.brush_style, "depth": room.brush_depth, "drawing": room.drawing}
    if not records.is_empty() and records.back() == state:
        return
    records.append(state)
    room.save_drawing(out.path_join("manual-drawing.save"))
    FileAccess.open(out.path_join("manual-session.json"), FileAccess.WRITE).store_string(JSON.stringify(records, "\t"))
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out.path_join("manual-latest.png"))
