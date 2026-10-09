# Runs exact printed code with real XRTools and deterministic synthetic input.
extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world: Node3D

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, id: String, description: String) -> void:
    checks.append({"id": id, "passed": ok, "description": description})
    if not ok:
        failures.append(id)

func frames(count: int = 3) -> void:
    for i in count:
        await physics_frame
        await process_frame

func make_lesson(path: String) -> Node3D:
    var lesson: Node3D = load(path).new()
    lesson.position = Vector3(2, 0.4, -1)
    lesson.rotation.y = 0.35
    world.add_child(lesson)
    return lesson

func make_controller(at: Vector3) -> XRController3D:
    var controller := XRController3D.new()
    controller.position = at
    world.add_child(controller)
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.name = "Pickup"
    pickup.hand_offset_mode = 4
    pickup.ranged_enable = false
    controller.add_child(pickup)
    return controller

func same_values(actual: Array, wanted: Array) -> bool:
    if actual.size() != wanted.size():
        return false
    for i in wanted.size():
        if not Vector3(actual[i]).is_equal_approx(Vector3(wanted[i])):
            return false
    return true

func check_segments(lesson: Node3D, values: Array, id: String) -> void:
    var nodes: Array[Node] = lesson.grid_trail.get_children()
    check(nodes.size() == maxi(values.size() - 1, 0), id + "/pairs", "One renderer per neighbouring pair; no discarded entries.")
    var endpoints_ok := nodes.size() == maxi(values.size() - 1, 0)
    var colours_ok := true
    for i in mini(nodes.size(), maxi(values.size() - 1, 0)):
        var segment: MeshInstance3D = nodes[i]
        var a: Vector3 = values[i]
        var b: Vector3 = values[i+1]
        var length := a.distance_to(b)
        endpoints_ok = endpoints_ok and segment.visible == (length > 0.0001)
        if length > 0.0001:
            var half: float = segment.mesh.height * 0.5
            endpoints_ok = endpoints_ok and is_equal_approx(segment.mesh.height, length)
            endpoints_ok = endpoints_ok and segment.to_global(Vector3(0, -half, 0)).distance_to(lesson.to_global(a)) < 0.001
            endpoints_ok = endpoints_ok and segment.to_global(Vector3(0, half, 0)).distance_to(lesson.to_global(b)) < 0.001
        colours_ok = colours_ok and segment.material_override.albedo_color.is_equal_approx(Color(0.25, 0.85, 0.60))
    check(endpoints_ok, id + "/geometry", "Green cylinders end at the expected station-local snapped positions; coincident pairs are hidden.")
    check(colours_ok, id + "/finish", "Only the derived rendering receives green.")

func verify_quantization(path: String, flat: bool = false) -> void:
    var lesson := make_lesson(path)
    lesson.set_process(false)
    await frames()
    check(lesson.addresses.get_typed_builtin() == TYPE_VECTOR3I, "flat/types/addresses" if flat else "types/addresses", "Addresses use integer triples.")
    check(lesson.snapped_positions.get_typed_builtin() == TYPE_VECTOR3, "flat/types/derived" if flat else "types/derived", "Placed positions remain Vector3 values in metres.")
    var source: Array[Vector3] = [Vector3(-0.126, 0.124, 0.376), Vector3(-0.125, 0.125, -0.125), Vector3(0.125, -0.125, 0.125), Vector3(0.126, -0.126, 0.374), Vector3(0.13, -0.13, 0.37), Vector3(-0.126, 0.124, 0.376)]
    var fine: Array[Vector3i] = [Vector3i(-1,0,2), Vector3i(-1,1,-1), Vector3i(1,-1,1), Vector3i(1,-1,1), Vector3i(1,-1,1), Vector3i(-1,0,2)]
    var coarse: Array[Vector3i] = [Vector3i(0,0,1), Vector3i(0,0,0), Vector3i(0,0,0), Vector3i(0,0,1), Vector3i(0,0,1), Vector3i(0,0,1)]
    if flat:
        for i in fine.size():
            fine[i].y = 0
            coarse[i].y = 0
    lesson.positions.assign(source)
    for pitch in [0.25, 0.5, 0.25]:
        var prefix := ("flat/" if flat else "quant/") + str(pitch) + "/" + str(checks.size())
        var expected: Array[Vector3i] = fine if pitch == 0.25 else coarse
        var placed: Array[Vector3] = []
        for cell in expected:
            placed.append(Vector3(cell) * pitch)
        lesson.grid_step = pitch
        lesson._redraw_grid()
        await frames()
        check(same_values(lesson.positions, source), prefix + "/source_kept", "Rounding leaves every original value and its order intact.")
        check(same_values(lesson.addresses, expected), prefix + "/addresses", "Manual oracle matches negatives, exact half-cell ties, neighbouring boundaries, repeats and return visits.")
        check(same_values(lesson.snapped_positions, placed), prefix + "/placed", "Each address becomes the expected local position at this pitch.")
        check_segments(lesson, placed, prefix)
    var stable: Array = lesson.snapped_positions.duplicate()
    lesson.position += Vector3(6, 2, -3)
    lesson.rotation.y += 0.7
    lesson._redraw_grid()
    await frames()
    check(same_values(lesson.snapped_positions, stable), "flat/frame" if flat else "frame/local_snapshot", "Moving the station does not change its local derived positions.")
    check_segments(lesson, stable, "flat/moved" if flat else "frame/moved")
    lesson.positions.clear()
    lesson._redraw_grid()
    await frames()
    check(lesson.addresses.is_empty() and lesson.snapped_positions.is_empty() and lesson.grid_trail.get_child_count() == 0, "flat/empty" if flat else "edge/empty", "Empty records yield empty arrays and no segments.")
    lesson.positions.append(Vector3(0.13, 1.12, -0.13))
    lesson._redraw_grid()
    await frames()
    check(lesson.addresses.size() == 1 and lesson.snapped_positions.size() == 1 and lesson.grid_trail.get_child_count() == 0, "flat/single" if flat else "edge/single", "One retained entry has an address but no neighbouring line.")
    if not flat:
        var lone: Array = lesson.positions.duplicate()
        for pitch in [0.0, -0.25]:
            lesson.grid_step = pitch
            lesson._redraw_grid()
            await frames()
            check(lesson.addresses.is_empty() and lesson.snapped_positions.is_empty() and same_values(lesson.positions, lone), "edge/invalid_" + str(pitch), "Nonpositive pitch produces no division and leaves the source intact.")
    lesson.queue_free()
    await frames()

func verify_integration(path: String) -> void:
    var lesson := make_lesson(path)
    var incoming := make_lesson("res://incoming.gd")
    await frames(6)
    var point: Node3D = lesson.point
    var body_id := point.get_instance_id()
    var mesh: MeshInstance3D = point.get_child(0)
    var collision: CollisionShape3D = point.get_child(1)
    check(mesh.mesh.radius == incoming.point.get_child(0).mesh.radius and mesh.mesh.height == incoming.point.get_child(0).mesh.height and collision.shape.radius == incoming.point.get_child(1).shape.radius and point.freeze == incoming.point.freeze, "carry/body", "The original sphere construction and pickup/release settings remain.")
    var original_resource := mesh.mesh
    check(lesson.positions == incoming.positions and lesson.trail.get_child_count() == 0, "carry/seed", "Both programs start with the same local seed and empty pink trace.")
    incoming.queue_free()
    await frames(4)
    var controller := make_controller(point.global_position)
    var pickup: Node3D = controller.get_node("Pickup")
    await frames(6)
    pickup._update_closest_object()
    check(pickup.closest_object == point, "xr/target", "Unmodified XRTools overlap finds this sphere.")
    pickup._pick_up_object(point)
    check(point.is_picked_up() and pickup.picked_up_object == point, "xr/pickup", "The actual grab library holds the original sphere.")
    var route: Array[Vector3] = [Vector3(0, 1.12, 0)]
    for x in [0.02,0.04,0.06]:
        controller.global_position = lesson.to_global(Vector3(x,1.12,0))
        await frames(6)
        if x > 0.05:
            route.append(Vector3(x,1.12,0))
        check(same_values(lesson.positions,route), "sampling/"+str(x), "The inherited threshold compares to the last retained sample.")
    for p in [Vector3(0.36,1.42,0.18),Vector3(-0.18,1.18,0.36),Vector3(0,1.12,0)]:
        controller.global_position = lesson.to_global(p)
        await frames(6)
        route.append(p)
    check(same_values(lesson.positions,route), "drawing/source", "A real grab-driver route supplies Grid's actual ordered trace.")
    var before: Array = lesson.positions.duplicate()
    var fine: Array = lesson.snapped_positions.duplicate()
    var pink_ids: Array[int] = []
    for segment in lesson.trail.get_children():
        pink_ids.append(segment.get_instance_id())
    pickup._on_button_pressed(pickup.action_button_action)
    await frames(6)
    check(lesson.grid_step == 0.5, "action/xr_pitch", "The actual pickup tool action button emits the inherited action signal and switches pitch.")
    check(same_values(lesson.positions,before) and not same_values(lesson.snapped_positions,fine), "action/same_record", "Changing pitch derives a different result from this retained drawing.")
    var pink_preserved: bool = lesson.trail.get_child_count() == pink_ids.size()
    for i in mini(pink_ids.size(),lesson.trail.get_child_count()):
        pink_preserved = pink_preserved and lesson.trail.get_child(i).get_instance_id() == pink_ids[i]
    check(pink_preserved, "action/pink_nodes", "Switching pitch does not rebuild or erase the pink source drawing.")
    var event := InputEventAction.new()
    event.action = "ui_accept"
    event.pressed = true
    Input.parse_input_event(event)
    await frames(6)
    event.pressed = false
    Input.parse_input_event(event)
    await frames(3)
    check(lesson.grid_step == 0.25 and same_values(lesson.snapped_positions,fine), "action/desktop_pitch", "One ui_accept event returns to the finer result from the same source.")
    var wanted := "LOCAL " + str(lesson.to_local(point.global_position)) + "\nWORLD " + str(point.global_position)
    wanted += "\nPOINTS " + str(route.size()) + "\nPITCH 0.25 m\nLAST ADDRESS " + str(lesson.addresses[-1])
    check(lesson.readout.text == wanted, "readout/current", "The initialized label shows local/world point, retained count, pitch and last retained address.")
    pickup.drop_object()
    controller.position += Vector3(1,0,0)
    await frames(8)
    check(point.freeze and not point.is_picked_up() and same_values(lesson.positions,before), "release/record", "Release keeps the same point and source record as the empty hand moves.")
    controller.global_position = point.global_position
    await frames(6)
    pickup._update_closest_object()
    pickup._pick_up_object(point)
    controller.global_position = lesson.to_global(Vector3(0.36,1.12,-0.18))
    await frames(6)
    check(lesson.positions.size() == before.size()+1 and same_values(lesson.positions.slice(0,before.size()),before), "resume/history", "Re-grabbing extends the existing source instead of replacing it.")
    check(point.get_instance_id() == body_id and mesh.mesh == original_resource and is_equal_approx(collision.shape.radius, 0.14), "carry/identity", "Both derivations and another pickup leave the live point and its resource identities intact.")
    pickup.drop_object()
    controller.queue_free()
    lesson.queue_free()
    await frames(4)
    var restarted := make_lesson(path)
    await frames(4)
    check(restarted.positions.size() == 1 and restarted.addresses.size() == 1, "lifetime/new_station", "A new station starts with its seed; no cross-scene persistence is invented.")
    restarted.queue_free()
    await frames()

func run() -> void:
    world = Node3D.new()
    root.add_child(world)
    var args := OS.get_cmdline_user_args()
    var mode := args[1]
    var script := "res://grid.gd" if mode == "positive" else "res://" + mode + ".gd"
    await verify_quantization(script)
    if mode == "positive":
        await verify_quantization("res://flat_y.gd",true)
        await verify_integration(script)
    var report := {"passed":failures.is_empty(),"checks":checks,"failure_ids":failures,"mode":mode}
    var file := FileAccess.open(args[0],FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"\t"))
    file.close()
    print("TRACE TO GRID ",mode,": ",checks.size()," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
