extends SceneTree

var world := Node3D.new()
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var group := "normal"
var report_path := ""

const POSITIONS := [Vector3(0, 0.30, 0), Vector3(0, 1.075, 0), Vector3(0, 2.025, 0), Vector3(0, 2.975, 0), Vector3(0, 3.45, 0)]
const DIMENSIONS := [Vector3(1.10, 0.60, 1.10), Vector3(0.95, 0.95, 0.95), Vector3(0.95, 0.95, 0.95), Vector3(0.85, 0.95, 0.85), Vector3(0.85, 0.95, 0.85)]
const COLOURS := [Color(0.78, 0.60, 0.30), Color(0.80, 0.16, 0.16), Color(0.16, 0.36, 0.80)]
const ASSIGNMENTS := {
    "one": [0, 0, 0, 0, 0],
    "grouped": [1, 1, 2, 1, 2],
    "recoloured": [1, 1, 2, 1, 2],
    "alternating": [1, 2, 1, 2, 1],
    "choice": [2, 0, 1, 0, 2],
}

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

func make(variant := "one") -> Node3D:
    var study: Node3D = load("res://" + group + "/" + variant + "/lesson.gd").new()
    world.add_child(study)
    return study

func colours(study: Node3D) -> Array[Color]:
    var values: Array[Color] = []
    for part in study.parts:
        values.append(part.material_override.albedo_color)
    return values

func appearance_is(study: Node3D, slots: Array, palette: Array) -> bool:
    for i in 5:
        if not study.parts[i].material_override.albedo_color.is_equal_approx(palette[slots[i]]):
            return false
    return true

func snapshot(study: Node3D) -> Array:
    var data: Array = []
    for part in study.parts:
        data.append([part.get_instance_id(), part.mesh.get_instance_id(), part.material_override.get_instance_id(), part.transform, part.global_transform, part.mesh.get_aabb()])
    return data

func same_geometry(study: Node3D, before: Array) -> bool:
    if study.get_child_count() != before.size() or study.parts.size() != before.size():
        return false
    var now := snapshot(study)
    for i in now.size():
        if now[i] != before[i]:
            return false
    return true

func configurations() -> void:
    for variant: String in ASSIGNMENTS:
        var study := make(variant)
        check(variant + "/five_parts", study.parts.size() == 5 and study.get_child_count() == 5)
        var expected_palette := COLOURS.duplicate()
        if variant == "recoloured":
            expected_palette[1] = Color(0.90, 0.22, 0.48)
        check(variant + "/assigned_colours", appearance_is(study, ASSIGNMENTS[variant], expected_palette))
        check(variant + "/assignment_retained", study.colour_slots == ASSIGNMENTS[variant])
        var node_ids: Array[int] = []
        var material_ids: Array[int] = []
        var mesh_ids: Array[int] = []
        var previous_top := 0.0
        for i in 5:
            var part: MeshInstance3D = study.parts[i]
            var material: StandardMaterial3D = part.material_override
            check(variant + "/local_position_" + str(i), part.position.is_equal_approx(POSITIONS[i]))
            check(variant + "/world_position_" + str(i), part.global_position.is_equal_approx(world.to_global(POSITIONS[i])))
            check(variant + "/unchanged_basis_" + str(i), part.basis.is_equal_approx(Basis.IDENTITY))
            var box: AABB = part.mesh.get_aabb()
            var dimensions_ok: bool = box.size.is_equal_approx(DIMENSIONS[i])
            if part.mesh is SphereMesh:
                # The default finite ring mesh misses the exact equator. Check the
                # requested dimensions exactly; allow <2 mm only in its sampled X/Z bounds.
                var difference: Vector3 = DIMENSIONS[i] - box.size
                dimensions_ok = is_equal_approx(part.mesh.radius * 2.0, DIMENSIONS[i].x) and is_equal_approx(part.mesh.height, DIMENSIONS[i].y) and is_equal_approx(box.size.y, DIMENSIONS[i].y) and difference.x >= 0 and difference.x < 0.002 and difference.z >= 0 and difference.z < 0.002
            check(variant + "/dimensions_" + str(i), dimensions_ok)
            check(variant + "/touching_levels_" + str(i), is_equal_approx(part.position.y + box.position.y, previous_top))
            previous_top = part.position.y + box.end.y
            check(variant + "/opaque_matte_" + str(i), is_equal_approx(material.roughness, 0.55) and is_zero_approx(material.metallic) and not material.emission_enabled and is_equal_approx(material.albedo_color.a, 1.0) and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED)
            node_ids.append(part.get_instance_id())
            material_ids.append(material.get_instance_id())
            mesh_ids.append(part.mesh.get_instance_id())
        check(variant + "/height_4_4", is_equal_approx(previous_top, 4.4))
        var unique := true
        for i in 5:
            for j in i:
                unique = unique and node_ids[i] != node_ids[j] and material_ids[i] != material_ids[j] and mesh_ids[i] != mesh_ids[j]
        check(variant + "/independent_parts_and_resources", unique)
        check(variant + "/familiar_shapes", study.parts[0].mesh is BoxMesh and study.parts[1].mesh is BoxMesh and study.parts[2].mesh is SphereMesh and study.parts[3].mesh is BoxMesh and study.parts[4].mesh is SphereMesh)
        check(variant + "/sphere_and_dome", not study.parts[2].mesh.is_hemisphere and study.parts[4].mesh.is_hemisphere)
        check(variant + "/no_scene_dependencies", study.find_children("*", "CollisionObject3D", true, false).is_empty() and study.find_children("*", "Camera3D", true, false).is_empty() and study.find_children("*", "Light3D", true, false).is_empty())
        var before := snapshot(study)
        study.apply_colours()
        study.apply_colours()
        check(variant + "/repaint_preserves_objects_geometry_and_pose", same_geometry(study, before))
        check(variant + "/repaint_preserves_assignments", appearance_is(study, ASSIGNMENTS[variant], expected_palette))
        study.free()

func live_edits() -> void:
    var study := make()
    var other := make()
    var before := snapshot(study)
    var other_before := snapshot(other)
    var original_palette: Array = study.palette.duplicate()
    var original_colours := colours(study)
    study.colour_slots.assign([1, 1, 2, 1, 2])
    check("live/assignment_waits_for_apply", colours(study) == original_colours)
    study.apply_colours()
    check("live/grouped_colours", appearance_is(study, ASSIGNMENTS.grouped, COLOURS))
    check("live/reassignment_preserves_geometry", same_geometry(study, before))
    check("live/assignment_does_not_edit_palette", study.palette == original_palette)
    check("live/second_study_unchanged", appearance_is(other, ASSIGNMENTS.one, COLOURS) and same_geometry(other, other_before))
    var prior := colours(study)
    study.palette[1] = Color(0.90, 0.22, 0.48)
    check("live/palette_value_is_copied", colours(study) == prior)
    study.apply_colours()
    var pink_palette := COLOURS.duplicate()
    pink_palette[1] = Color(0.90, 0.22, 0.48)
    check("live/palette_updates_assigned_group_only", appearance_is(study, ASSIGNMENTS.grouped, pink_palette))
    check("live/palette_edit_preserves_assignment", study.colour_slots == ASSIGNMENTS.grouped)
    check("live/palette_edit_preserves_geometry", same_geometry(study, before))
    check("live/second_palette_independent", other.palette == COLOURS)
    prior = colours(study)
    study.parts[0].material_override.albedo_color = Color.WHITE
    var independent := true
    for i in range(1, 5):
        independent = independent and study.parts[i].material_override.albedo_color.is_equal_approx(prior[i])
    check("live/one_material_edit_is_local", independent)
    check("live/material_edit_preserves_palette", study.palette == pink_palette)
    study.apply_colours()
    check("live/reapply_restores_assigned_value", appearance_is(study, ASSIGNMENTS.grouped, pink_palette))
    study.colour_slots.assign([2, 0, 1, 0, 2])
    study.apply_colours()
    check("live/independent_composition", appearance_is(study, ASSIGNMENTS.choice, pink_palette))
    check("live/composition_preserves_geometry", same_geometry(study, before))
    study.colour_slots.assign([0, 0, 0, 0, 0])
    study.apply_colours()
    check("live/return_to_one_colour", appearance_is(study, ASSIGNMENTS.one, pink_palette))
    study.free()
    other.free()

func run() -> void:
    world.position = Vector3(3, 0.7, -2)
    world.rotation.y = 0.4
    root.add_child(world)
    configurations()
    live_edits()
    world.free()
    FileAccess.open(report_path, FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures, "group": group}, "  "))
    print("COLOUR CHECKS ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
