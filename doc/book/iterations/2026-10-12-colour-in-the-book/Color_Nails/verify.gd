extends SceneTree

const CASES := {
    "start": Color(0.8, 0.2, 0.6),
    "red": Color(1, 0, 0),
    "wide": Color(0.4, 0.2, 0.6),
    "outside": Color(0, 1, 0.5),
    "choice": Color(0.2, 0.8, 0.6),
    "transfer": Color(0.8, 0.2, 0.6),
}
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world := Node3D.new()
var group := ""
var report_path := ""

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    group = args[0]
    report_path = args[1]
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func frames(count := 5) -> void:
    for i in count:
        await physics_frame
        await process_frame

func make(variant := "start") -> Node3D:
    var study: Node3D = load("res://" + group + "/" + variant + "/lesson.gd").new()
    study.position = Vector3(4, 1, -3)
    study.rotation = Vector3(0.2, 0.6, 0)
    world.add_child(study)
    return study

func geometry(study: Node3D) -> Array:
    return [study.preview.get_instance_id(), study.preview.mesh.get_instance_id(), study.preview.transform, study.preview.mesh.size, study.swatch.get_instance_id()]

func run() -> void:
    root.add_child(world)
    for variant: String in CASES:
        var study := make(variant)
        await frames()
        var expected: Color = CASES[variant]
        check(variant + "/material_assignment", study.swatch.albedo_color.is_equal_approx(expected))
        check(variant + "/local_frame_readout", study.readout.text == "RGB %.2f  %.2f  %.2f" % [expected.r, expected.g, expected.b])
        check(variant + "/preview_receiver", study.preview.material_override == study.swatch and study.preview.mesh is BoxMesh)
        check(variant + "/preview_geometry", study.preview.mesh.size.is_equal_approx(Vector3(0.32, 0.32, 0.04)) and study.preview.position.is_equal_approx(Vector3(-0.35, 0.3, 0)))
        check(variant + "/one_familiar_point", study.point is RigidBody3D and study.point.has_method("pick_up") and study.point.get_child_count() == 2)
        check(variant + "/same_radius", is_equal_approx(study.point.get_child(0).mesh.radius, 0.14) and is_equal_approx(study.point.get_child(1).shape.radius, 0.14))
        check(variant + "/pickup_settings", study.point.freeze and study.point.release_mode == 1 and not study.point.can_ranged_grab)
        var guides := []
        for child in study.get_children():
            if child is MeshInstance3D and child.mesh is CylinderMesh:
                guides.append(child)
        check(variant + "/three_guides", guides.size() == 3)
        check(variant + "/guide_extents", is_equal_approx(guides[0].mesh.height, 1.2 if variant == "wide" else 0.6) and is_equal_approx(guides[1].mesh.height, 0.6) and is_equal_approx(guides[2].mesh.height, 0.6))
        var before := geometry(study)
        var point_before: Transform3D = study.point.global_transform
        var colour_before: Color = study.swatch.albedo_color
        check(variant + "/origin", study.colour_at(Vector3.ZERO, Vector3(0.6, 0.6, 0.6)).is_equal_approx(Color.BLACK))
        check(variant + "/opposite", study.colour_at(Vector3(0.6, 0.6, 0.6), Vector3(0.6, 0.6, 0.6)).is_equal_approx(Color.WHITE))
        check(variant + "/red_axis", study.colour_at(Vector3(0.6, 0, 0), Vector3(0.6, 0.6, 0.6)).is_equal_approx(Color.RED))
        check(variant + "/clamped_outside", study.colour_at(Vector3(-0.2, 0.9, 0.3), Vector3(0.6, 0.6, 0.6)).is_equal_approx(Color(0, 1, 0.5)))
        check(variant + "/unequal_dimensions", study.colour_at(Vector3(1, 1, 6), Vector3(2, 4, 8)).is_equal_approx(Color(0.5, 0.25, 0.75)))
        check(variant + "/pure_calculation", study.point.global_transform == point_before and study.swatch.albedo_color == colour_before and geometry(study) == before)
        study.point.global_position = study.to_global(Vector3(0.18, 0.24, 0.42))
        await frames()
        var moved := Color(0.15 if variant == "wide" else 0.3, 0.4, 0.7)
        check(variant + "/moved_point_updates", study.swatch.albedo_color.is_equal_approx(moved))
        study.point.global_position = study.to_global(Vector3(0.24, 0.24, 0.42))
        await frames()
        check(variant + "/one_axis_one_channel", study.swatch.albedo_color.is_equal_approx(Color(0.2 if variant == "wide" else 0.4, 0.4, 0.7)))
        check(variant + "/recolour_keeps_geometry", geometry(study) == before)
        if variant == "transfer":
            check("transfer/two_receivers", study.other_material != study.swatch and study.other.material_override == study.other_material)
            check("transfer/same_returned_value", study.other_material.albedo_color.is_equal_approx(study.swatch.albedo_color))
            study.swatch.roughness = 0.9
            check("transfer/independent_finish", is_equal_approx(study.other_material.roughness, 0.35))
        study.queue_free()
        await frames(2)
    var study := make()
    await frames()
    var controller := XRController3D.new()
    controller.position = study.point.global_position
    world.add_child(controller)
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    pickup.ranged_enable = false
    controller.add_child(pickup)
    await frames(8)
    pickup._update_closest_object()
    check("grab/near_selection", pickup.closest_object == study.point)
    pickup._pick_up_object(pickup.closest_object)
    check("grab/held", study.point.is_picked_up() and pickup.picked_up_object == study.point)
    controller.global_position = study.to_global(Vector3(0.12, 0.48, 0.36))
    await frames(8)
    check("grab/real_driver_moves_point", study.point.global_position.distance_to(controller.global_position) < 0.001)
    check("grab/held_position_to_colour", study.swatch.albedo_color.is_equal_approx(Color(0.2, 0.8, 0.6)))
    pickup.drop_object()
    await frames()
    var released: Vector3 = study.point.global_position
    var retained: Color = study.swatch.albedo_color
    controller.global_position += Vector3(2, 2, 2)
    await frames(8)
    check("grab/released_and_frozen", not study.point.is_picked_up() and study.point.freeze)
    check("grab/released_colour_stays", study.point.global_position.is_equal_approx(released) and study.swatch.albedo_color.is_equal_approx(retained))
    controller.queue_free()
    study.queue_free()
    await frames(2)
    var first := make()
    var second := make()
    await frames()
    first.swatch.albedo_color = Color.YELLOW
    check("ownership/independent_instances", first.swatch != second.swatch and second.swatch.albedo_color.is_equal_approx(Color(0.8, 0.2, 0.6)))
    first.queue_free()
    second.queue_free()
    await frames(2)
    world.free()
    FileAccess.open(report_path, FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("NAILS CHECKS ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
