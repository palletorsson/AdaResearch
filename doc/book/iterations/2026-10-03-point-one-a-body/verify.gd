extends SceneTree
## Check the learner's edits with the supplied player's actual collision body.

var out: String
var room
var checks: Array = []
var failed := false

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

func edited(file: String, replacements: Dictionary) -> Node3D:
    var source := FileAccess.get_file_as_string("res://studies/point_one/" + file)
    for original in replacements:
        source = source.replace(original, replacements[original])
    var script := GDScript.new()
    script.source_code = source
    check(file + " edited code compiles", script.reload() == OK)
    var node := Node3D.new()
    node.set_script(script)
    return node

func walk(x: float) -> float:
    room.player.position = Vector3(x, 0.02, 2.0)
    room.player.rotation = Vector3.ZERO
    room.player.velocity = Vector3.ZERO
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    Input.action_press("move_forward")
    await frames(112)
    Input.action_release("move_forward")
    await frames(2)
    return room.player.position.z

func variant(replacements: Dictionary) -> Node3D:
    var node := edited("solid.gd", replacements)
    node.position = Vector3(2, 0, -0.4)
    room.add_child(node)
    await frames(3)
    return node

func run():
    room = load("res://point_one.tscn").instantiate()
    root.add_child(room)
    await frames(35)
    check("Shared floor supports the player", absf(room.player.position.y) < 0.05)
    check("Setup objects are absent in this lesson", room.test_cube == null)
    room.reset_cube()
    var absent = room.get_node("Position")
    var visible = room.get_node("Visible")
    var solid = room.get_node("Solid")
    check("A stored position creates no hidden object", absent.get_child_count() == 0)
    check("Visible point contains only a mesh node", visible.get_child_count() == 1 and visible.get_child(0) is MeshInstance3D)
    check("The two visible markers initially match", is_equal_approx(visible.get_child(0).mesh.radius, solid.get_child(0).mesh.radius))
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out.path_join("room.png"))
    check("Player crosses the empty position", await walk(-2) < -0.8)
    check("Player crosses the visible surface", await walk(0) < -0.8)
    var normal_stop: float = await walk(2)
    check("Player stops at the solid point", normal_stop > -0.15 and normal_stop < 0.1)
    solid.queue_free()
    await frames(3)

    var wider = await variant({"sphere_shape.radius = radius": "sphere_shape.radius = 0.5"})
    var wider_stop: float = await walk(2)
    check("Larger invisible boundary stops player earlier", wider_stop > normal_stop + 0.25)
    check("Boundary edit leaves visible radius unchanged", is_equal_approx(wider.get_child(0).mesh.radius, 0.14))
    room.get_node("KeyLight").light_energy = 0
    var unlit_stop: float = await walk(2)
    check("Removing light does not remove the boundary", absf(unlit_stop - wider_stop) < 0.02)
    room.get_node("KeyLight").light_energy = room.key_energy
    wider.queue_free()
    await frames(3)

    var both = await variant({"var radius := 0.14": "var radius := 0.3"})
    var both_stop: float = await walk(2)
    check("One radius changes both shapes", is_equal_approx(both.get_child(0).mesh.radius, 0.3) and is_equal_approx(both.get_child(1).get_child(0).shape.radius, 0.3))
    check("Growing both shapes moves the stopping point", both_stop > normal_stop + 0.1)
    both.queue_free()
    await frames(3)
    var smaller = await variant({"var radius := 0.14": "var radius := 0.3", "sphere_shape.radius = radius": "sphere_shape.radius = 0.07"})
    var small_stop: float = await walk(2)
    check("Small boundary permits closer approach to large surface", small_stop < both_stop - 0.18 and small_stop > -0.2)
    smaller.queue_free()

    var raised := edited("visible.gd", {"1.12": "1.7", "var radius := 0.14": "var radius := 0.3"})
    root.add_child(raised)
    check("Visible code works on a bare Node3D", raised.get_child_count() == 1)
    check("Position edit moves the marker", is_equal_approx(raised.get_child(0).position.y, 1.7))
    check("Height remains twice the edited radius", is_equal_approx(raised.get_child(0).mesh.height, 0.6))
    raised.queue_free()
    var unseen := edited("position.gd", {"1.12": "1.7"})
    root.add_child(unseen)
    check("Changing stored data alone still creates no surface", unseen.get_child_count() == 0 and is_equal_approx(unseen.point_position.y, 1.7))
    unseen.queue_free()
    room.queue_free()
    await frames(3)
    FileAccess.open(out.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "physical_headset_tested": false}, "\t"))
    print("Point One: ", checks.size(), " checks; passed: ", not failed)
    quit(1 if failed else 0)
