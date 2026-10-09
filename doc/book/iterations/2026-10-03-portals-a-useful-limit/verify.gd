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

func open_room(divisions: int, tolerance: float = 0.01):
    if is_instance_valid(room):
        room.queue_free()
        await frames(3)
    var edited := GDScript.new()
    edited.source_code = FileAccess.get_file_as_string("res://studies/primitive_portals/perimeter.gd").replace("var divisions := 6", "var divisions := " + str(divisions)).replace("var tolerance := 0.01", "var tolerance := " + str(tolerance))
    check("Printed settings compile: %d / %.3f" % [divisions,tolerance],edited.reload()==OK)
    room = load("res://primitive_portals.tscn").instantiate()
    study = room.get_node("Study")
    # Replacing a script does not free its unattached Node-valued fields.
    study.display.free()
    study.set_script(edited)
    root.add_child(room)
    await frames(12)
    room.player.position = Vector3(0.2,0,2.0)
    room.player.camera.position.y = 1.9
    room.player.camera.look_at(Vector3(0,1.65,-1.2))

func capture(name: String):
    await frames(3)
    check("Capture " + name, root.get_texture().get_image().save_png(out.path_join(name))==OK)

func strokes_match() -> bool:
    var count: int = study.points.size()
    var strokes: Array = study.display.polygon_segments
    if strokes.size() != count:
        return false
    for i in count:
        var a: Vector3 = study.points[i]
        var b: Vector3 = study.points[(i+1)%count]
        var segment = strokes[i]
        if not segment.position.is_equal_approx((a+b)*0.5) or not is_equal_approx(segment.mesh.height,a.distance_to(b)):
            return false
    return true

func run():
    var gaps: Array[float] = []
    var counts: Array[int] = [6,12,24,48]
    for count in counts:
        await open_room(count)
        var radii := true
        for point in study.points:
            radii = radii and is_equal_approx(point.length(),1.0) and point.z==0.0
        check("%d ordered samples remain on the unit circle in XY" % count,radii and study.points.size()==count and study.points[0].is_equal_approx(Vector3.RIGHT) and not study.points[0].is_equal_approx(study.points[count-1]))
        var analytic := 2.0*count*sin(PI/count)
        check("%d side measured perimeter agrees with the independent chord formula" % count,absf(study.perimeter-analytic)<0.000002 and study.gap>0)
        check("%d drawn segments include the last-to-first edge; guide stays at 256" % count,strokes_match() and study.display.reference_segments.size()==256)
        check("%d sides has the expected tolerance decision" % count,study.display.within_tolerance==(count==48))
        gaps.append(study.gap)
        await capture("sides-%d.png" % count)
    check("Doubling sides decreases the measured shortfall across all four trials",gaps[0]>gaps[1] and gaps[1]>gaps[2] and gaps[2]>gaps[3] and gaps[2]>0.01 and gaps[3]<=0.01)
    var previous_points: Array[Vector3] = study.points.duplicate()
    var previous_perimeter: float = study.perimeter
    await open_room(48,0.001)
    check("Tighter tolerance changes the decision without changing geometry or perimeter",study.points==previous_points and study.perimeter==previous_perimeter and not study.display.within_tolerance)
    await capture("tighter-tolerance.png")
    # Independent polygon checks prevent a regular-polygon shortcut from passing.
    var triangle: Array[Vector3] = [Vector3.ZERO,Vector3(3,0,0),Vector3(3,4,0)]
    var copy: Array[Vector3] = triangle.duplicate()
    check("A 3-4-5 triangle includes its five-unit closing edge",is_equal_approx(study.polygon_perimeter(triangle),12.0))
    check("Perimeter calculation leaves its input unchanged",triangle==copy)
    var moved: Array[Vector3] = []
    for point in triangle:
        moved.append(point+Vector3(10,20,-5))
    check("Translating the sample list does not change its perimeter",is_equal_approx(study.polygon_perimeter(moved),12.0))
    var twice: Array[Vector3] = study.CircleSamples.points_on_circle(48,2.0)
    check("Doubling radius doubles the measured perimeter",is_equal_approx(study.polygon_perimeter(twice),2.0*previous_perimeter))
    study.display.show_polygon(study.points,study.radius,study.perimeter,study.gap,study.tolerance)
    await frames(3)
    check("Redrawing neither mutates the point list nor accumulates strokes",study.points==previous_points and study.display.content.get_child_count()==304 and strokes_match())
    var query := PhysicsRayQueryParameters3D.create(study.global_position+Vector3(0,0,0.1),study.global_position-Vector3(0,0,0.1))
    check("The diagram has no face or collider across its centre",study.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    var bare = load("res://studies/primitive_portals/perimeter.gd").new()
    bare.position = Vector3(20,2,0)
    root.add_child(bare)
    await frames(4)
    check("Lesson runs on a bare Node3D without scene lookups",bare.points.size()==6 and is_equal_approx(bare.perimeter,6.0) and bare.display.polygon_segments.size()==6)
    bare.queue_free()
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":not failed,"checks":checks,"physical_headset_tested":false,"screenshots":"Native Godot 4.6 student room; no simulated museum grid","input":"No new pickup or UI controls; parameter edits rerun _ready"},"\t"))
    print("Portals: ",checks.size()," checks; passed: ",not failed)
    quit(1 if failed else 0)
