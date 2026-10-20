extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world := Node3D.new()
var group: String
var report_path: String
var config: Dictionary
var prefix: String

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    group = args[0]
    report_path = args[1]
    config = JSON.parse_string(FileAccess.get_file_as_string("res://cases.json"))
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    var full_id := prefix + "/" + id
    checks.append({"id": full_id, "passed": ok})
    if not ok:
        failures.append(full_id)
        print("FAIL ", full_id)

func near(a: Color, b: Color) -> bool:
    return absf(a.r-b.r) < 0.006 and absf(a.g-b.g) < 0.006 and absf(a.b-b.b) < 0.006 and absf(a.a-b.a) < 0.006

func frames(count := 3) -> void:
    for i in count:
        await physics_frame
        await process_frame

func run() -> void:
    root.mode = Window.MODE_MINIMIZED
    root.add_child(world)
    for item: Dictionary in config[group]:
        var hall: String = item.hall
        var variant: String = item.variant
        prefix = hall + "/" + variant
        var s: Node3D = load("res://" + item.path + "/lesson.gd").new()
        s.position = Vector3(7, 0.2, -4)
        s.rotation.y = 0.45
        world.add_child(s)
        s.set_process(false)
        s.set_physics_process(false)
        await frames()
        match hall:
            "Color_Rainbow": test_rainbow(s, variant)
            "Color_Pillar": test_pillar(s, variant)
            "Color_Grid_Pallet": test_grid(s, variant)
            "Color_Paint": await test_paint(s, variant)
            "Color_Walls": await test_walls(s, variant)
        if hall in ["Color_Grid_Pallet", "Color_Walls"]:
            await test_pointer_console(s, hall)
        s.queue_free()
        await frames(2)
    world.free()
    FileAccess.open(report_path, FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)

func test_pointer_console(s: Node3D, hall: String) -> void:
    var controls: Node3D
    for child in s.get_children():
        if child.has_method("activate"):
            controls = child
    check("console_present", controls != null)
    if controls == null:
        return
    var targets: Array = controls.buttons
    check("console_count", targets.size() == (5 if hall == "Color_Grid_Pallet" else 2))
    var pointer := Node3D.new()
    s.add_child(pointer)
    var events = load("res://addons/godot-xr-tools/events/pointer_event.gd")
    for target: StaticBody3D in targets:
        var query := PhysicsRayQueryParameters3D.create(target.to_global(Vector3(0,0,0.3)), target.global_position, 1)
        var hit := s.get_world_3d().direct_space_state.intersect_ray(query)
        check("target_" + str(targets.find(target)) + "_reachable", not hit.is_empty() and hit.collider == target)
    if hall == "Color_Grid_Pallet":
        s.select_address(Vector2i(4,4))
        events.released(pointer, targets[0], targets[0].global_position)
        check("release_does_not_select", s.selected == Vector2i(4,4))
        events.pressed(pointer, targets[0], targets[0].global_position)
        events.pressed(pointer, targets[1], targets[1].global_position)
        check("pointer_wraps_address", s.selected == Vector2i(0,0))
        var ink: Color = s.palettes[s.palette_index].current_colour()
        events.pressed(pointer, targets[2], targets[2].global_position)
        check("pointer_leaves_colour", near(s.grid.read(s.selected),ink))
        var old: int = s.palette_index
        events.pressed(pointer, targets[3], targets[3].global_position)
        check("pointer_changes_palette", s.palette_index == (old+1)%2)
        events.pressed(pointer, targets[4], targets[4].global_position)
        var palette: Array = s.palettes[s.palette_index].colours
        check("pointer_applies_rule", near(s.grid.read(Vector2i(2,1)),palette[3%palette.size()]))
    else:
        var before: bool = s.filter_mode
        events.released(pointer, targets[0], targets[0].global_position)
        check("release_does_not_toggle", s.filter_mode == before)
        events.pressed(pointer, targets[0], targets[0].global_position)
        check("pointer_switches_filter", s.filter_mode != before)
        var other: Color = s.panes[1].surface.albedo_color
        var first: Color = s.panes[0].surface.albedo_color
        events.pressed(pointer, targets[1], targets[1].global_position)
        check("pointer_changes_only_first", not near(first,s.panes[0].surface.albedo_color) and near(other,s.panes[1].surface.albedo_color))
    pointer.queue_free()
    await frames()

func test_rainbow(s: Node3D, variant: String) -> void:
    var count := 2 if variant == "two" else (4 if variant == "four" else (1 if variant == "one" else 3))
    check("count", s.bands.size() == count)
    check("opening", is_equal_approx(s.bands[0].inner_radius, 0.7))
    check("fixed_outer", is_equal_approx(s.bands[-1].outer_radius, 1.3))
    for i in s.bands.size():
        var band: MeshInstance3D = s.bands[i]
        check("width_" + str(i), is_equal_approx(band.outer_radius-band.inner_radius, 0.6/count))
        check("colour_" + str(i), near(band.material_override.albedo_color, s.palette[i]))
        var arrays: Array = band.mesh.surface_get_arrays(0)
        var valid := true
        var lo := INF
        var hi := 0.0
        for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
            valid = valid and p.is_finite() and absf(p.z) < 0.001 and p.y > -0.001
            lo = minf(lo, p.length())
            hi = maxf(hi, p.length())
        check("mesh_radii_" + str(i), valid and absf(lo-band.inner_radius) < 0.001 and absf(hi-band.outer_radius) < 0.001)
        if i > 0:
            check("joined_" + str(i), is_equal_approx(band.inner_radius, s.bands[i-1].outer_radius))
            check("own_material_" + str(i), band.material_override != s.bands[i-1].material_override)

func test_pillar(s: Node3D, variant: String) -> void:
    s._process(0)
    var value := 0.0 if variant == "low" else (1.0 if variant in ["high", "beyond"] else 0.5)
    check("initial_colour", near(s.swatch.albedo_color, Color(0.375*value, value, 0.71875*value)))
    check("local_frame", s.to_local(s.point.global_position).is_equal_approx(s.start))
    check("original_body", s.point.get_child(0).mesh is SphereMesh and is_equal_approx(s.point.get_child(0).mesh.radius, 0.14))
    check("low_height", s.hand_to_field(Vector3(3, 0.65, 7)).is_equal_approx(Vector3(3, 0.46, 7)))
    check("high_height", s.hand_to_field(Vector3(3, 1.85, 7)).is_equal_approx(Vector3(3, 4.6, 7)))
    check("height_clamped", is_equal_approx(s.hand_to_field(Vector3(3, 5, 7)).y, 4.6) and is_equal_approx(s.hand_to_field(Vector3(3, -3, 7)).y, 0.46))
    check("hsv_origin", s.hsv_at(Vector3(0, 0.46, 0)).is_equal_approx(Vector3(0, 0.25, 0)))
    check("hsv_far", s.hsv_at(Vector3(12.8, 4.6, 19.2)).is_equal_approx(Vector3(0.85, 1, 1)))
    check("hsv_bounded", s.hsv_at(Vector3(100, 100, -1)).is_equal_approx(Vector3(0.85, 0.25, 1)))
    var before: Color = s.swatch.albedo_color
    s.colour_at(Vector3(0, 0.46, 0))
    check("pure_function", near(before, s.swatch.albedo_color))
    s.point.global_position = s.to_global(Vector3(0, 1.85, 19.2))
    s._process(0)
    check("moving_point_red", near(s.swatch.albedo_color, Color.RED))
    s.point.global_position = s.to_global(Vector3(0, 1.25, 19.2))
    s._process(0)
    check("height_changes_value", near(s.swatch.albedo_color, Color(0.5, 0, 0)))

func test_grid(s: Node3D, variant: String) -> void:
    var n := 1 if variant == "one" else (4 if variant == "four" else 3)
    check("palette_length", s.palettes[0].colours.size() == n)
    check("all_addresses", s.grid.cells.size() == 25 and s.grid.instances.instance_count == 25)
    var valid := true
    var transforms := []
    for z in 5:
        for x in 5:
            var expected: Color = s.palettes[0].colours[(x+z)%n]
            valid = valid and near(s.grid.read(Vector2i(x,z)), expected)
            transforms.append(s.grid.instances.get_instance_transform(s.grid.cells[Vector2i(x,z)]))
    check("rule_all_cells", valid)
    var old: Color = s.grid.read(Vector2i(4, 4))
    s.select_address(Vector2i(4,4))
    check("selection_does_not_paint", near(old, s.grid.read(Vector2i(4,4))) and s.palettes[0].index == 0)
    s.select_address(Vector2i(-1,50))
    check("invalid_selection_ignored", s.selected == Vector2i(4,4))
    check("invalid_write_rejected", not s.grid.write(Vector2i(-1,50), Color.RED))
    s.paint_selected()
    var ink: Color = s.palettes[0].colours[0]
    check("paint_before_advance", near(s.grid.read(Vector2i(4,4)), ink) and s.palettes[0].index == 1%n)
    s.select_address(Vector2i(1,1))
    check("retention", near(s.grid.read(Vector2i(4,4)), ink))
    s.next_palette()
    check("switch_no_advance", s.palettes[0].index == 1%n and s.palettes[1].index == 0)
    s.paint_selected()
    check("independent_palettes", s.palettes[0].index == 1%n and s.palettes[1].index == 1 and near(s.grid.read(Vector2i(1,1)), Color(0.8,0.2,0.6)))
    s.apply_rule()
    check("rule_overwrites", near(s.grid.read(Vector2i(4,4)), Color(0.8,0.2,0.6)) and s.palettes[1].index == 1)
    s.palettes[1].next_colour()
    check("wrap", s.palettes[1].index == 0)
    var now := []
    for z in 5:
        for x in 5:
            now.append(s.grid.instances.get_instance_transform(s.grid.cells[Vector2i(x,z)]))
    check("unchanged_geometry", transforms == now)
    var choices: Array[Color] = [Color.RED, Color.BLUE]
    var fresh = s.Palette.new(choices)
    choices[0] = Color.GREEN
    check("owns_choices", fresh.current_colour() == Color.RED)

func paint_centre(s: Node3D) -> Color:
    return s.canvas.image.get_pixel(256,160)

func test_paint(s: Node3D, variant: String) -> void:
    var initial: Color = paint_centre(s)
    check("blank_canvas", initial == Color.WHITE)
    check("original_body", s.point.get_child(0).mesh is SphereMesh and is_equal_approx(s.point.get_child(0).mesh.radius, 0.14))
    check("uv_corners", s.canvas.uv_at(s.canvas.to_global(Vector3(-2,0,-1.25))).is_equal_approx(Vector2.ZERO) and s.canvas.uv_at(s.canvas.to_global(Vector3(2,0,1.25))).is_equal_approx(Vector2.ONE))
    check("uv_roundtrip", s.canvas.uv_at(s.canvas.world_at(Vector2(0.2,0.8))).is_equal_approx(Vector2(0.2,0.8)))
    s.set_action("spray", true)
    s.manual_step(0.1)
    check("unheld_cannot_paint", not s.active and not s.spraying and paint_centre(s) == initial)
    s.set_held(true)
    s.set_action("other", true)
    check("named_action", not s.active)
    s.set_action("spray", true)
    s.manual_step(0.1)
    if variant == "short":
        check("range_miss", not s.painting and paint_centre(s) == initial)
        s.max_distance = 3.0
        s.manual_step(0.1)
    check("ray_hits_receiver", s.spraying and s.painting and s.canvas.deposits == 1)
    var first := paint_centre(s)
    check("deposit_between_white_and_ink", first.g < 1 and first.g > s.ink.g)
    s.manual_step(0.1)
    check("accumulates", paint_centre(s).g < first.g)
    var kept := paint_centre(s)
    s.set_action("spray", false)
    s.manual_step(0.1)
    check("release_keeps_mark", paint_centre(s) == kept and not s.painting)
    s.set_action("spray", true)
    s.set_held(false)
    s.manual_step(0.1)
    check("drop_clears_action", not s.active and paint_centre(s) == kept)
    var target: Vector3 = s.canvas.world_at(Vector2(0.2,0.8))
    var forward: Vector3 = -s.canvas.global_basis.y.normalized()
    check("outside_rejected", not s.canvas.draw_spray(s.canvas.world_at(Vector2(2,0.8)), forward, 0.06, Color.RED, 0.5))
    check("back_rejected", not s.canvas.draw_spray(target, -forward, 0.06, Color.RED, 0.5))
    check("invalid_radius_rejected", not s.canvas.draw_spray(target, forward, 0, Color.RED, 0.5))
    check("invalid_amount_rejected", not s.canvas.draw_spray(target, forward, 0.06, Color.RED, 0))
    var deposits: int = s.canvas.deposits
    s.automatic_step(0,0.1)
    check("automatic_same_receiver", s.canvas.deposits == deposits+1 and paint_centre(s).g < kept.g)
    var blocker := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.6,0.6,0.1)
    shape.shape = box
    blocker.add_child(shape)
    s.add_child(blocker)
    blocker.position = Vector3(0,1.5,0.5)
    await frames()
    s.set_held(true)
    s.set_action("spray",true)
    deposits = s.canvas.deposits
    s.manual_step(0.1)
    check("first_hit_blocks", not s.painting and s.canvas.deposits == deposits)
    blocker.queue_free()
    await frames()
    # Native XR Tools driver, synthetic controller: test the installed signal contract.
    s.set_held(false)
    var controller := XRController3D.new()
    world.add_child(controller)
    controller.global_transform = s.point.global_transform
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    pickup.ranged_enable = false
    controller.add_child(pickup)
    await frames(8)
    pickup._update_closest_object()
    check("xr_near_selection", pickup.closest_object == s.point)
    if pickup.closest_object != null:
        pickup._pick_up_object(pickup.closest_object)
        check("xr_pickup_signal", s.held and s.point.is_picked_up())
        s.point.action()
        check("xr_action_signal", s.active)
        s.point.action_release()
        check("xr_release_signal", not s.active)
        s.point.action()
        pickup.drop_object()
        check("xr_drop_signal", not s.held and not s.active)
    controller.queue_free()
    await frames()

func wall_hit(s: Node3D) -> Dictionary:
    return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(s.to_global(Vector3(-0.7,1.25,2)), s.to_global(Vector3(-0.7,1.25,-2))))

func test_walls(s: Node3D, variant: String) -> void:
    check("two_panes", s.panes.size() == 2)
    check("independent_materials", s.panes[0].surface != s.panes[1].surface)
    var alpha := 0.2 if variant == "thin" else (1.0 if variant == "full" else 0.52)
    check("alpha", is_equal_approx(s.panes[0].surface.albedo_color.a, alpha))
    check("alpha_mode", s.panes[0].surface.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
    check("palette_unchanged", s.palettes[0].current_colour().a == 1.0)
    check("filter_collision", wall_hit(s).get("collider") == s.panes[0])
    var shape: Shape3D = s.panes[0].boundary.shape
    var transforms := [s.panes[0].transform, s.panes[1].transform]
    var second: Color = s.panes[1].surface.albedo_color
    s.change_first()
    check("first_palette_advances", near(s.panes[0].surface.albedo_color, Color(1,0.8,0.15,alpha)))
    check("second_unchanged", near(s.panes[1].surface.albedo_color, second) and s.palettes[1].index == 0)
    s.toggle_filter()
    await frames()
    check("opaque_mode", s.panes[0].surface.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and s.panes[0].surface.albedo_color.a == 1)
    check("opaque_collision", wall_hit(s).get("collider") == s.panes[0])
    check("same_geometry", transforms == [s.panes[0].transform, s.panes[1].transform] and s.panes[0].boundary.shape == shape and shape.size.is_equal_approx(Vector3(2,2.5,0.04)))
    s.toggle_filter()
    check("filter_returns", is_equal_approx(s.panes[0].surface.albedo_color.a,alpha))
    s.opacity = 5
    check("bounded_opacity", s.surface_colour(Color.RED, true).a == 1)
    s.opacity = -2
    check("bounded_zero", s.surface_colour(Color.RED, true).a == 0)
