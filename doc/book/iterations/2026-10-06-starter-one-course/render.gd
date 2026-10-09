extends SceneTree
var room: Node3D
var out: String

func _initialize() -> void:
    call_deferred("run")

func scene(name: String) -> Node3D:
    if is_instance_valid(room):
        room.queue_free()
        await process_frame
    room = load("res://"+name+".tscn").instantiate()
    root.add_child(room)
    current_scene = room
    await create_timer(0.3).timeout
    room.player.set_physics_process(false)
    return room.get_node("PointStudy")

func shot(name: String, eye: Vector3, target: Vector3) -> void:
    room.player.camera.global_position = eye
    room.player.camera.look_at(target)
    room.player.camera.fov = 58
    await create_timer(0.12).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out+"/"+name+".png")
    print("CAPTURE ",name)

func run() -> void:
    out = OS.get_cmdline_user_args()[0]
    root.size = Vector2i(1440,900)
    var coords := await scene("point_coordinates")
    await shot("coordinates",Vector3(1.4,1.8,2.3),coords.to_global(Vector3(0,1.38,0)))
    var lines := await scene("point_lines")
    var eye := Vector3(0.4,1.75,2.8)
    var target := lines.to_global(Vector3(0.25,1.3,0))
    await shot("lines-forward",eye,target)
    lines.hide()
    var reversed: Node3D = load("res://lessons/Point_Lines/line_reversed.gd").new()
    reversed.position = lines.position
    room.add_child(reversed)
    await shot("lines-reversed",eye,target)
    var grid := await scene("point_grid")
    await shot("grid-fine",Vector3(1.4,2.1,2.5),grid.to_global(Vector3(0,1.42,0)))
    grid.grid_step = 0.5
    grid._place_on_grid()
    await shot("grid-coarse",Vector3(1.4,2.1,2.5),grid.to_global(Vector3(0,1.42,0)))
    var poly := await scene("point_polyhedra")
    var centre: Vector3 = (poly.points[0]+poly.points[1]+poly.points[2])/3
    eye = poly.to_global(centre+Vector3(0.55,0.22,1.8))
    target = poly.to_global(centre)
    await shot("polyhedra-closed",eye,target)
    poly.faces.pop_front()
    poly.body.show_faces(poly.points,poly.faces)
    poly.message.text = "%d positions; %d faces." % [poly.points.size(), poly.faces.size()]
    await shot("polyhedra-open",eye,target)
    var cube := await scene("point_cube")
    eye = cube.to_global(Vector3(1.85,2.0,3.4))
    target = cube.to_global(Vector3(0,1.2,0))
    await shot("cube-flat",eye,target)
    cube.second.points[6].z += 0.35
    cube.second.show_faces(cube.second.points,cube.second.faces)
    await shot("cube-crease",eye,target)
    var column := await scene("primitive_column")
    await shot("columns",Vector3(3.5,2.5,4.1),column.to_global(Vector3(0,1.1,0)))
    room.queue_free()
    await process_frame
    room = load("res://resolution_colonnade.tscn").instantiate()
    root.add_child(room)
    current_scene = room
    await create_timer(0.3).timeout
    room.player.set_physics_process(false)
    await shot("colonnade-card",Vector3(-5.8,1.65,1.2),Vector3(-6.8,1.2,-2.3))
    quit()
