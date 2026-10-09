extends SceneTree

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

func make(variant := "row") -> Node3D:
    var study: Node3D = load("res://" + group + "/" + variant + "/lesson.gd").new()
    world.add_child(study)
    return study

func mesh_count(study: Node3D) -> int:
    var result := 0
    for child in study.get_children():
        if child is MeshInstance3D:
            result += 1
    return result

func find_label(study: Node3D, address: String) -> Label3D:
    for child in study.get_children():
        if child is Label3D and child.text == address:
            return child
    return null

func values_are(study: Node3D, value: int) -> bool:
    for row in study.grid_data:
        for entry in row:
            if entry != value:
                return false
    return true

func actor(at: Vector3, name: String, layer: int) -> CharacterBody3D:
    var body := CharacterBody3D.new()
    body.collision_layer = layer
    body.collision_mask = 0
    if not name.is_empty():
        body.add_to_group(name)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.18
    shape.height = 1.5
    collision.shape = shape
    body.add_child(collision)
    body.position = world.to_local(at)
    world.add_child(body)
    return body

func settle() -> void:
    for i in 5:
        await physics_frame
        await process_frame

func geometry() -> void:
    for variant in ["row", "plane", "spaced", "turned", "choice", "empty_width", "empty_depth", "single"]:
        var study := make(variant)
        var w: int = study.width
        var d: int = study.depth
        check(variant + "/count", mesh_count(study) == w * d)
        check(variant + "/outer_lengths", study.grid_data.size() == w and study.cubes.size() == w)
        check(variant + "/all_present", values_are(study, 1))
        var ids: Array[int] = []
        var positions_ok := true
        var sensors_ok := true
        var labels_ok := true
        var resources_ok := true
        var mesh_ids: Array[int] = []
        var shape_ids: Array[int] = []
        for x in w:
            check(variant + "/inner_length_" + str(x), study.grid_data[x].size() == d and study.cubes[x].size() == d)
            for z in d:
                var cube: MeshInstance3D = study.cubes[x][z]
                var expected := Vector3(x * study.spacing, 0.8, z * study.spacing)
                positions_ok = positions_ok and cube.position.is_equal_approx(expected)
                positions_ok = positions_ok and cube.global_position.is_equal_approx(study.to_global(expected))
                ids.append(cube.get_instance_id())
                resources_ok = resources_ok and not mesh_ids.has(cube.mesh.get_instance_id())
                mesh_ids.append(cube.mesh.get_instance_id())
                var area: Area3D = cube.get_child(0)
                var hitbox: CollisionShape3D = area.get_child(0)
                resources_ok = resources_ok and not shape_ids.has(hitbox.shape.get_instance_id())
                shape_ids.append(hitbox.shape.get_instance_id())
                sensors_ok = sensors_ok and area.collision_layer == 0 and area.collision_mask == 524289
                sensors_ok = sensors_ok and cube.mesh.size == Vector3.ONE and hitbox.shape.size == Vector3.ONE
                sensors_ok = sensors_ok and area.global_transform.is_equal_approx(cube.global_transform)
                labels_ok = labels_ok and find_label(study, "[%d, %d]" % [x, z]) != null
        var distinct := true
        for i in ids.size():
            for j in range(i + 1, ids.size()):
                distinct = distinct and ids[i] != ids[j]
        check(variant + "/independent_nodes", distinct)
        check(variant + "/independent_meshes_and_shapes", resources_ok)
        check(variant + "/placement_in_rotated_host", positions_ok)
        check(variant + "/matching_sensors", sensors_ok)
        check(variant + "/persistent_labels", labels_ok)
        var display := "grid_data[x][z]"
        for x in w:
            display += "\n" + str(study.grid_data[x])
        check(variant + "/readout_initialized", study.readout.text == display)
        if variant in ["turned", "choice"]:
            var selected := Vector2i(1, 0) if variant == "turned" else Vector2i(2, 1)
            var angle := 45.0 if variant == "turned" else 30.0
            var turns_ok := true
            for x in w:
                for z in d:
                    var expected_angle: float = angle if Vector2i(x, z) == selected else 0.0
                    turns_ok = turns_ok and is_equal_approx(study.cubes[x][z].rotation_degrees.y, expected_angle)
            check(variant + "/only_selected_turns", turns_ok)
        study.collect(-1, 0)
        study.collect(0, -1)
        study.collect(w, 0)
        study.collect(0, d)
        check(variant + "/out_of_bounds_ignored", values_are(study, 1))
        study.free()

func record_changes() -> void:
    var study := make("plane")
    var same_cube: MeshInstance3D = study.cubes[1][0]
    var second_reference: MeshInstance3D = study.cubes[1][0]
    second_reference.rotation_degrees.y = 30.0
    check("reference/second_name_same_body", same_cube == second_reference and is_equal_approx(same_cube.rotation_degrees.y, 30.0))
    check("reference/neighbour_independent", is_zero_approx(study.cubes[2][0].rotation_degrees.y))
    var old: MeshInstance3D = study.cubes[1][2]
    var kept_ids: Array[int] = []
    var kept_poses: Array[Transform3D] = []
    for x in 4:
        for z in 4:
            if Vector2i(x, z) != Vector2i(1, 2):
                kept_ids.append(study.cubes[x][z].get_instance_id())
                kept_poses.append(study.cubes[x][z].transform)
    study.collect(1, 2)
    check("collection/immediate_zero_and_null", study.grid_data[1][2] == 0 and study.cubes[1][2] == null)
    check("collection/queued", old.is_queued_for_deletion())
    study.collect(1, 2)
    await process_frame
    check("collection/freed_after_frame", not is_instance_valid(old))
    check("collection/study_survives", is_instance_valid(study))
    check("collection/fifteen_bodies", mesh_count(study) == 15)
    var cursor := 0
    var untouched := true
    for x in 4:
        check("collection/length_" + str(x), study.grid_data[x].size() == 4 and study.cubes[x].size() == 4)
        for z in 4:
            if Vector2i(x, z) != Vector2i(1, 2):
                untouched = untouched and study.grid_data[x][z] == 1
                untouched = untouched and study.cubes[x][z].get_instance_id() == kept_ids[cursor]
                untouched = untouched and study.cubes[x][z].transform == kept_poses[cursor]
                cursor += 1
    check("collection/neighbours_identical", untouched)
    check("collection/address_label_remains", find_label(study, "[1, 2]") != null)
    check("collection/readout_correct", study.readout.text == "grid_data[x][z]\n[1, 1, 1, 1]\n[1, 1, 0, 1]\n[1, 1, 1, 1]\n[1, 1, 1, 1]")
    study.free()
    study = make()
    var neighbours := [study.cubes[0][0], study.cubes[1][0], study.cubes[3][0]]
    study.collect(2, 0)
    study.collect(2, 0)
    await process_frame
    check("row/one_zero_kept_length", study.grid_data == [[1], [1], [0], [1]] and study.cubes.size() == 4)
    check("row/last_not_renumbered", study.cubes[3][0] == neighbours[2] and study.cubes[3][0].position.is_equal_approx(Vector3(4.8, 0.8, 0)))
    check("row/label_survives", find_label(study, "[2, 0]") != null)
    for x in 4:
        study.collect(x, 0)
    await process_frame
    check("row/all_collected_slots_remain", study.grid_data == [[0], [0], [0], [0]] and mesh_count(study) == 0)
    check("row/all_labels_remain", study.get_child_count() == 5)
    study.free()
    study = make("single")
    study.collect(0, 0)
    study.collect(0, 0)
    await process_frame
    check("single/last_cube_collected", study.grid_data == [[0]] and study.cubes == [[null]] and is_instance_valid(study.readout))
    study.free()

func overlaps() -> void:
    for kind in ["desktop", "xr", "prop", "wrong_layer"]:
        var study := make("plane")
        var target: Vector3 = study.cubes[1][2].global_position
        var layer := 524288 if kind == "xr" else 1
        if kind == "wrong_layer":
            layer = 2
        var body_group := "player_body" if kind == "xr" else "em_walker"
        if kind == "prop":
            body_group = "prop"
        var player := actor(target + Vector3(0, 0, 12), body_group, layer)
        await settle()
        check("physics/" + kind + "_outside", values_are(study, 1))
        player.global_position = target
        await settle()
        var accepts: bool = kind in ["desktop", "xr"]
        check("physics/" + kind + "_entry", (study.grid_data[1][2] == 0) == accepts)
        check("physics/" + kind + "_body_count", mesh_count(study) == (15 if accepts else 16))
        check("physics/" + kind + "_transpose_untouched", study.grid_data[2][1] == 1)
        check("physics/" + kind + "_label_kept", find_label(study, "[1, 2]") != null)
        player.free()
        study.free()
    var pair := make()
    var at: Vector3 = pair.cubes[2][0].global_position
    var first := actor(at + Vector3(0, 0, 12), "em_walker", 1)
    var second := actor(at + Vector3(0, 0, 12), "player_body", 524288)
    await settle()
    first.global_position = at
    second.global_position = at
    await settle()
    check("physics/two_players_one_collection", pair.grid_data == [[1], [1], [0], [1]] and mesh_count(pair) == 3)
    first.free()
    second.free()
    pair.free()
    var moved := make()
    var cube: MeshInstance3D = moved.cubes[2][0]
    var former := cube.global_position
    cube.position.z += 3.0
    var walker := actor(former, "em_walker", 1)
    await settle()
    check("physics/old_position_no_longer_collects", moved.grid_data[2][0] == 1)
    walker.global_position = cube.global_position
    await settle()
    check("physics/moved_sensor_same_address", moved.grid_data == [[1], [1], [0], [1]])
    walker.free()
    moved.free()

func fault_probe() -> void:
    var study := make("plane")
    if group in ["disconnected_signal", "swapped_binding"]:
        var target: Vector3 = study.cubes[1][2].global_position
        var player := actor(target + Vector3(0, 0, 12), "em_walker", 1)
        await settle()
        player.global_position = target
        await settle()
        check("fault/collects_named_address", study.grid_data[1][2] == 0 and study.grid_data[2][1] == 1)
        player.free()
    elif group == "whole_study_removed":
        study.collect(1, 2)
        await process_frame
        check("fault/study_survives", is_instance_valid(study))
    else:
        study.collect(1, 2)
        await process_frame
        if group == "shift_slot":
            check("fault/retained_length", study.grid_data[1].size() == 4)
        elif group == "shared_rows":
            check("fault/independent_rows", study.grid_data[0][2] == 1)
        elif group == "unrecorded_collection":
            check("fault/presence_updated", study.grid_data[1][2] == 0)
    if is_instance_valid(study):
        study.free()

func run() -> void:
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    world.rotation.y = 0.4
    if group == "normal":
        geometry()
        await record_changes()
        await overlaps()
    else:
        await fault_probe()
    var file := FileAccess.open(report_path, FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks": checks, "failure_ids": failures, "passed": failures.is_empty()}, "  "))
    file.close()
    print("ARRAY CHECKS: ", checks.size(), "; failures: ", failures.size())
    world.free()
    quit(0 if failures.is_empty() else 1)
