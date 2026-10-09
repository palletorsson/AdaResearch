extends SceneTree

var out: String
var checks: Array = []
var failed := false
var room
var gallery
var view := Camera3D.new()

func _initialize():
    out = OS.get_cmdline_user_args()[0]
    root.size = Vector2i(1600,1000)
    run.call_deferred()

func check(label: String, passed: bool):
    checks.append({"check":label,"passed":passed})
    if not passed:
        failed = true
        push_error(label)

func frames(n: int):
    for i in n:
        await physics_frame
    await process_frame
    await RenderingServer.frame_post_draw

func shot(name: String, at: Vector3, target: Vector3, fov: float = 70.0):
    view.position = at
    view.fov = fov
    view.look_at(target)
    await frames(10)
    check("Native capture " + name,root.get_texture().get_image().save_png(out.path_join(name))==OK)

func run():
    room = load("res://resolution_colonnade.tscn").instantiate()
    root.add_child(room)
    await frames(30)
    gallery = room.gallery
    root.add_child(view)
    view.current = true
    check("Twenty-five distinct column instances",gallery.columns.size()==25)
    var prescribed_heights := true
    var actual_heights: Array[float] = []
    var silhouettes: Array[int] = []
    var on_plinths := true
    var clearance := true
    var finite := true
    var total_triangles := 0
    var counts: Array = []
    for row in 5:
        for col in 5:
            var column = gallery.columns[row*5+col]
            prescribed_heights = prescribed_heights and is_equal_approx(column.height,gallery.HEIGHTS[row][col])
            if not actual_heights.has(column.height):
                actual_heights.append(column.height)
            if not silhouettes.has(column.profile_kind):
                silhouettes.append(column.profile_kind)
            var bounds: AABB = column.column_mesh.get_aabb()
            on_plinths = on_plinths and absf(bounds.position.y)<0.001 and absf(bounds.size.y-column.height)<0.001 and is_equal_approx(column.position.y,0.22)
            clearance = clearance and bounds.position.x >= -0.93 and bounds.end.x <= 0.93 and bounds.position.z >= -0.93 and bounds.end.z <= 0.93 and bounds.end.y+column.position.y < 6.56
            check("Resolution pair %d/%d" % [col,row],column.radial_segments==gallery.COUNTS[col] and column.profile_rings==gallery.COUNTS[row])
            total_triangles += column.triangle_count
            counts.append(column.triangle_count)
            for surface in column.column_mesh.get_surface_count():
                var arrays: Array = column.column_mesh.surface_get_arrays(surface)
                var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
                var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
                finite = finite and vertices.size()>0 and vertices.size()==normals.size()
                for i in vertices.size():
                    finite = finite and vertices[i].is_finite() and normals[i].is_finite() and is_equal_approx(normals[i].length(),1.0)
    check("Generated heights match the authored arrangement",prescribed_heights)
    check("Five profile families and at least twenty different heights",silhouettes.size()==5 and actual_heights.size()>=20)
    check("All bodies start on their plinths and reach their stated heights",on_plinths)
    check("Every profile stays within its plinth and below the crossbeams",clearance)
    check("All mesh vertices and flat normals are finite and populated",finite)
    var increases := true
    for row in 5:
        for col in 4:
            increases = increases and counts[row*5+col]<counts[row*5+col+1]
    for row in 4:
        for col in 5:
            increases = increases and counts[row*5+col]<counts[(row+1)*5+col]
    check("Either resolution axis independently increases triangle count",increases)
    # Hold height and sampling fixed: the silhouette must change independently.
    var profile_signatures: Array[int] = []
    for kind in 5:
        var probe = load("res://studies/resolution_colonnade/resolution_totem.gd").new()
        probe.profile_kind = kind
        probe.column_height = 4.67
        probe.collisions = false
        probe.visible = false
        root.add_child(probe)
        var signature := hash(probe.column_mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX])
        if not profile_signatures.has(signature):
            profile_signatures.append(signature)
        probe.queue_free()
    check("Five different profiles exist at the same height and resolution",profile_signatures.size()==5)
    var world: PhysicsDirectSpaceState3D = gallery.get_world_3d().direct_space_state
    var floors := true
    var aisle := true
    for z in range(-21,4):
        var floor_query := PhysicsRayQueryParameters3D.create(Vector3(1.7,0.4,z),Vector3(1.7,-0.3,z),1)
        var hit := world.intersect_ray(floor_query)
        floors = floors and not hit.is_empty() and absf(hit.position.y)<0.01
        var passage := PhysicsRayQueryParameters3D.create(Vector3(1.7,1.0,z),Vector3(1.7,1.0,z-1),1)
        aisle = aisle and world.intersect_ray(passage).is_empty()
    check("Continuous floor supports the central aisle",floors)
    check("Column geometry leaves the centre aisle unobstructed",aisle)
    var col_hit := world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-6.8,1.0,-1.0),Vector3(-6.8,1.0,-3.0),1))
    check("Columns have solid collision",not col_hit.is_empty())
    # Move the actual player for the entire aisle with normal walking input.
    room.player.position = gallery.spawn
    room.player.rotation = Vector3.ZERO
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    Input.action_press("move_forward")
    await frames(820)
    Input.action_release("move_forward")
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    print("Walk ended at: ",room.player.position," physics ticks: ",Engine.physics_ticks_per_second)
    check("Desktop body walks to the far end without falling or blocking",room.player.position.z < -17.5 and room.player.position.y > -0.05)
    room.reset_arrival()
    await frames(5)
    check("Return control restores entrance position",room.player.position.distance_to(gallery.spawn)<0.1)
    room.player.position.y = -4
    await frames(5)
    check("Leaving the floor recovers to the entrance",room.player.position.y > -0.05)
    await shot("arrival.png",Vector3(1.7,1.7,3.6),Vector3(1.7,2.75,-15.0),76)
    await shot("colonnade.png",Vector3(8.8,1.8,1.9),Vector3(-2.6,2.65,-11.0),76)
    await shot("four.png",Vector3(-4.1,1.8,0.2),Vector3(-6.8,1.9,-2.8),80)
    await shot("sixteen.png",Vector3(9.5,1.8,-15.8),Vector3(6.8,2.8,-18.8),80)
    await shot("light.png",Vector3(1.7,1.7,-16.0),Vector3(-0.8,5.0,-20.5),83)
    room.queue_free()
    await frames(4)
    var controlled = load("res://studies/resolution_colonnade/gallery.gd").new()
    controlled.varied_forms = false
    controlled.own_environment = false
    root.add_child(controlled)
    var uniform: bool = controlled.columns.size()==25
    for column in controlled.columns:
        uniform = uniform and column.profile_kind==0 and is_equal_approx(column.height,4.67) and is_equal_approx(column.width_factor,1.0)
    check("Equal-form resolution comparison remains available",uniform)
    controlled.queue_free()
    view.queue_free()
    await frames(4)
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":not failed,"checks":checks,"column_triangles":total_triangles,"per_column_triangles":counts,"physical_headset_tested":false,"desktop_walk_tested":true,"source":"Native Godot gallery, code-created geometry"},"\t"))
    print("Colonnade: ",checks.size()," checks; passed: ",not failed,"; triangles: ",total_triangles)
    quit(1 if failed else 0)
