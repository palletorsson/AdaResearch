extends SceneTree

var world := Node3D.new()
var camera_parent := Node3D.new()
var camera: Camera3D
var prefix := "res://normal/"
var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func close(a: Vector3, b: Vector3) -> bool:
    return a.distance_to(b) < 0.0001

func make(state := "complete", variant := "base") -> Node3D:
    var packed: PackedScene = load(prefix + state + "/" + variant + "/study.tscn")
    var study: Node3D = packed.instantiate()
    study.position = Vector3(2, 0, -3)
    study.rotation.y = 0.8
    world.add_child(study)
    study.set_process(false)
    return study

func bounds(body: MeshInstance3D, study: Node3D) -> AABB:
    var shape: AABB = body.mesh.get_aabb()
    var low := study.to_local(body.to_global(shape.get_endpoint(0)))
    var high := low
    for i in range(1, 8):
        var p := study.to_local(body.to_global(shape.get_endpoint(i)))
        low = low.min(p)
        high = high.max(p)
    return AABB(low, high-low)

func opening(study: Node3D) -> Vector3:
    var left := bounds(study.pivot.get_child(0), study)
    var right := bounds(study.pivot.get_child(1), study)
    var top := bounds(study.pivot.get_child(2), study)
    return Vector3(right.position.x-left.end.x, top.position.y, top.size.z)

func put_camera(study: Node3D, offset: Vector3) -> void:
    camera.global_position = study.pivot.global_position + offset

func incoming_scale() -> void:
    var study := make("incoming")
    check("incoming/base_opening", close(opening(study), Vector3(0.45, 0.6, 0.2)))
    var reference: Transform3D = study.point.global_transform
    study.apply_pose(Vector3(4, 4, 4))
    check("incoming/enlarged_opening", close(opening(study), Vector3(1.8, 2.4, 0.8)))
    study.apply_pose(Vector3(4, 1, 1))
    check("incoming/width_only", close(opening(study), Vector3(1.8, 0.6, 0.2)))
    check("incoming/fixed_reference", study.point.global_transform.is_equal_approx(reference))
    check("incoming/no_clock", not study.has_method("_process"))
    study.free()

func range_and_geometry() -> void:
    for variant in ["base", "reach", "width", "reverse"]:
        var study := make("complete", variant)
        var far_limit := 6.0 if variant == "reach" else 4.0
        var distances := [far_limit + 0.25, far_limit, (far_limit + 1.0) / 2.0, 1.0, 0.75, 0.0, far_limit]
        var factors := [1.0, 1.0, 2.5, 4.0, 4.0, 4.0, 1.0]
        var labels := ["beyond_far", "far", "midpoint", "near", "inside_near", "at_origin", "return"]
        var reference: Transform3D = study.point.global_transform
        var mesh: Mesh = study.pivot.get_child(0).mesh
        check(variant+"/initial_scale", close(study.pivot.scale, Vector3.ONE))
        check(variant+"/same_hierarchy", study.pivot.get_child_count()==3 and study.point.get_parent()==study)
        check(variant+"/same_class", study.pivot.get_child(0).get_script().resource_path.ends_with("box_body.gd"))
        for i in distances.size():
            var f: float = factors[i] if variant != "reverse" else 5.0-factors[i]
            var vector := Vector3(f, 1, 1) if variant == "width" else Vector3.ONE*f
            # Exercise the public response independently from the camera adapter.
            study.respond(distances[i])
            check(variant+"/"+labels[i]+"/factor", close(study.pivot.scale, vector))
            check(variant+"/"+labels[i]+"/opening", close(opening(study), Vector3(0.45, 0.6, 0.2)*vector))
        study.respond(1.0)
        var width_fits := opening(study).x >= 0.65
        var height_fits := opening(study).y >= 0.65
        check(variant+"/sphere_clearance", (width_fits and height_fits) == (variant in ["base", "reach"]))
        check(variant+"/threshold_on_floor", absf(bounds(study.pivot.get_child(0), study).position.y) < 0.0001)
        check(variant+"/mesh_retained", study.pivot.get_child(0).mesh == mesh)
        check(variant+"/reference_unchanged", study.point.global_transform.is_equal_approx(reference))
        check(variant+"/reference_nominal_size", is_equal_approx(study.point.mesh.radius, 0.325) and is_equal_approx(study.point.mesh.height, 0.65))
        check(variant+"/stored_dimensions", close(study.pivot.get_child(0).mesh.size, Vector3(0.12, 0.6, 0.2)))
        check(variant+"/stored_positions", close(study.pivot.get_child(0).position, Vector3(-0.285, 0.3, 0)))
        check(variant+"/visual_only", study.find_children("*", "CollisionObject3D", true, false).is_empty())
        study.free()

func camera_input() -> void:
    var study := make()
    check("input/active_camera", study.get_viewport().get_camera_3d() == camera)
    put_camera(study, Vector3(0, 0, 2.5))
    study._process(0.016)
    check("input/world_frames", close(study.pivot.scale, Vector3.ONE*2.5))
    put_camera(study, Vector3(0, 3.0, 2.5))
    study._process(0.016)
    check("input/height_ignored", close(study.pivot.scale, Vector3.ONE*2.5))
    put_camera(study, Vector3(1.5, 0, 2.0))
    study._process(0.016)
    check("input/diagonal_length", close(study.pivot.scale, Vector3.ONE*2.5))
    put_camera(study, Vector3(0, 0, -2.5))
    study._process(0.016)
    check("input/behind_same_distance", close(study.pivot.scale, Vector3.ONE*2.5))
    camera.rotation = Vector3(0.3, 1.2, -0.1)
    study._process(0.016)
    check("input/looking_direction_ignored", close(study.pivot.scale, Vector3.ONE*2.5))
    study._process(0.001)
    study._process(3.0)
    check("response/no_accumulation", close(study.pivot.scale, Vector3.ONE*2.5))
    put_camera(study, Vector3(0, 0, 4))
    study._process(0.016)
    check("response/retreat_restores", close(study.pivot.scale, Vector3.ONE))
    check("response/no_nodes_created", study.get_child_count()==2 and study.pivot.get_child_count()==3)
    var other := make()
    study.respond(1.0)
    check("instances/independent_frame", close(other.pivot.scale, Vector3.ONE))
    check("instances/independent_mesh", other.pivot.get_child(0).mesh != study.pivot.get_child(0).mesh)
    study.free()
    other.free()

func camera_lifetime() -> void:
    camera.free()
    var study := make()
    study._process(0.01)
    check("camera/absent_at_start", close(study.pivot.scale, Vector3.ONE))
    camera = Camera3D.new()
    camera_parent.add_child(camera)
    camera.make_current()
    put_camera(study, Vector3(0, 1.6, 1))
    study._process(0.01)
    check("camera/late_arrival", close(study.pivot.scale, Vector3.ONE*4))
    camera.free()
    study._process(0.01)
    check("camera/freed_keeps_last_pose", close(study.pivot.scale, Vector3.ONE*4))
    # Use an actual engine XR camera, with deterministic test positions and XR off.
    var origin := XROrigin3D.new()
    root.add_child(origin)
    origin.position = Vector3(-4, 0, 7)
    origin.rotation.y = 0.6
    camera = XRCamera3D.new()
    origin.add_child(camera)
    camera.make_current()
    put_camera(study, Vector3(0, 1.7, 2.5))
    study._process(0.01)
    check("camera/xr_type_selected", study.get_viewport().get_camera_3d() is XRCamera3D)
    check("camera/replacement_xr_position", close(study.pivot.scale, Vector3.ONE*2.5))
    study.free()
    origin.free()
    camera = Camera3D.new()
    camera_parent.add_child(camera)
    camera.make_current()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://"+args[0]+"/"
    root.add_child(world)
    world.position = Vector3(7, 0, 5)
    world.rotation.y = 0.4
    root.add_child(camera_parent)
    camera_parent.position = Vector3(-8, 2, 3)
    camera_parent.rotation.y = -0.7
    camera = Camera3D.new()
    camera_parent.add_child(camera)
    camera.make_current()
    incoming_scale()
    range_and_geometry()
    camera_input()
    camera_lifetime()
    var live := make()
    put_camera(live, Vector3(0, 1.6, 2.5))
    live.set_process(true)
    await process_frame
    await process_frame
    check("runtime/live_approach", close(live.pivot.scale, Vector3.ONE*2.5))
    put_camera(live, Vector3(0, 1.6, 4))
    await process_frame
    await process_frame
    check("runtime/live_retreat", close(live.pivot.scale, Vector3.ONE))
    live.free()
    camera_parent.free()
    world.free()
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size(), " FAILURES ", failures.size())
    quit(0 if failures.is_empty() else 1)
