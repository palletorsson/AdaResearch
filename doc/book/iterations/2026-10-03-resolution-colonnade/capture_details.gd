extends SceneTree
var view := Camera3D.new()
var out: String
func _initialize():
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()
func frames(n: int):
    for i in n: await process_frame
    await RenderingServer.frame_post_draw
func run():
    var room = load("res://resolution_colonnade.tscn").instantiate()
    root.add_child(room)
    root.add_child(view)
    view.current = true
    view.fov = 80
    await frames(35)
    view.position = Vector3(-4.1,1.8,0.2)
    view.look_at(Vector3(-6.8,1.9,-2.8))
    await frames(20)
    root.get_texture().get_image().save_png(out.path_join("four.png"))
    view.position = Vector3(9.5,1.8,-15.8)
    view.look_at(Vector3(6.8,2.8,-18.8))
    await frames(20)
    root.get_texture().get_image().save_png(out.path_join("sixteen.png"))
    room.queue_free()
    view.queue_free()
    await frames(5)
    quit()
