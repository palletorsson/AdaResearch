extends SceneTree

const PALE := Color(0.9, 0.9, 0.9)
const TARGETS := {
    "separate": Vector3(-1, 1.5, 0),
    "blue": Vector3(-1, 1.5, 0),
    "overlap": Vector3(1, 1.5, 0),
    "away": Vector3(-1, 1.5, 5),
    "choice": Vector3(0, 2, 0),
}
var world := Node3D.new()
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var group := "normal"
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

func make(variant := "separate") -> Node3D:
    var study: Node3D = load("res://" + group + "/" + variant + "/lesson.gd").new()
    world.add_child(study)
    return study

func board_state(study: Node3D) -> Array:
    return [study.board.get_instance_id(), study.board.mesh.get_instance_id(), study.surface.get_instance_id(), study.board.transform, study.board.global_transform, study.board.mesh.get_aabb(), study.surface.albedo_color, study.surface.roughness]

func points_at(lamp: SpotLight3D, world_target: Vector3) -> bool:
    var expected := lamp.global_position.direction_to(world_target)
    return (-lamp.global_basis.z).normalized().dot(expected) > 0.99999

func run() -> void:
    world.position = Vector3(7, 0.4, -3)
    world.rotation.y = 0.65
    root.add_child(world)
    for variant: String in TARGETS:
        var study := make(variant)
        var baseline := board_state(study)
        var colour := Color.BLUE if variant == "blue" else Color.RED
        check(variant + "/one_board_two_lights", study.get_child_count() == 3 and study.board is MeshInstance3D and study.first_light is SpotLight3D and study.second_light is SpotLight3D)
        check(variant + "/familiar_box", study.board.mesh is BoxMesh and study.board.mesh.size.is_equal_approx(Vector3(4.4, 2.4, 0.12)))
        check(variant + "/board_pose", study.board.position.is_equal_approx(Vector3(0, 1.5, 0)) and study.board.basis.is_equal_approx(Basis.IDENTITY))
        check(variant + "/material_unchanged", study.surface.albedo_color.is_equal_approx(PALE) and study.board.material_override == study.surface)
        check(variant + "/material_receives_light", study.surface.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and not study.surface.emission_enabled and study.surface.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and is_equal_approx(study.surface.roughness, 1.0))
        check(variant + "/distinct_lights", study.first_light != study.second_light)
        check(variant + "/first_light_colour", study.first_light.light_color.is_equal_approx(colour))
        check(variant + "/second_stays_green", study.second_light.light_color.is_equal_approx(Color.GREEN))
        check(variant + "/first_position_fixed", study.first_light.position.is_equal_approx(Vector3(-1, 1.5, 2.5)))
        check(variant + "/second_position_fixed", study.second_light.position.is_equal_approx(Vector3(1, 1.5, 2.5)))
        check(variant + "/first_world_target", points_at(study.first_light, study.to_global(TARGETS[variant])))
        check(variant + "/second_world_target", points_at(study.second_light, study.to_global(Vector3(1, 1.5, 0))))
        for i in 2:
            var lamp: SpotLight3D = study.first_light if i == 0 else study.second_light
            check(variant + "/range_angle_energy_" + str(i), is_equal_approx(lamp.spot_range, 6) and is_equal_approx(lamp.spot_angle, 18) and is_equal_approx(lamp.light_energy, 2.5) and lamp.shadow_enabled and lamp.visible)
        var first_position: Vector3 = study.first_light.global_position
        var second_transform: Transform3D = study.second_light.global_transform
        study.first_light.light_color = Color(0.8, 0.2, 0.6)
        check(variant + "/light_edit_preserves_surface", board_state(study) == baseline)
        check(variant + "/light_edit_is_independent", study.second_light.light_color.is_equal_approx(Color.GREEN))
        study.first_light.look_at(study.to_global(Vector3(0, 2, 0)))
        check(variant + "/live_aim_changes_direction", points_at(study.first_light, study.to_global(Vector3(0, 2, 0))))
        check(variant + "/live_aim_keeps_position", study.first_light.global_position.is_equal_approx(first_position))
        check(variant + "/live_aim_keeps_second", study.second_light.global_transform.is_equal_approx(second_transform))
        check(variant + "/live_aim_keeps_surface", board_state(study) == baseline)
        study.free()
    var first := make()
    var second := make()
    var second_state := board_state(second)
    first.surface.albedo_color = Color(0.8, 0.3, 0.6)
    check("ownership/materials_are_independent", board_state(second) == second_state)
    check("ownership/surface_edit_does_not_recolour_light", first.first_light.light_color.is_equal_approx(Color.RED) and first.second_light.light_color.is_equal_approx(Color.GREEN))
    first.free()
    second.free()
    world.free()
    FileAccess.open(report_path, FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("FLASHLIGHT CHECKS ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
