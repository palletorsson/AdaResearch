extends "res://tools/probes/transformation_encounters.gd"
## Existing museum artifacts; printed edits substituted only in this process.
class SuppliedGrabber extends Node3D:
    var picked_up_ranged := false

var frame: Node3D
var held: Node3D
var cards: Array = []

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(2.5).timeout
    var station := find_scene("/point_condition.gd")
    frame = find_scene("/CoordinateSystem3M.gd")
    for node in hall.find_children("*", "Node3D", true, false):
        if node.has_method("show_coordinates") and node.get("readout_channel") == "point_one_main": cards.append(node)
    check("existing held station, coordinate frame and two cards loaded", station != null and frame != null and cards.size() == 2)
    if station == null or frame == null or cards.size() != 2: return
    held = station.point
    check("named frame follows the existing pickable", frame._find_point() == held and held.has_method("pick_up") and held.has_method("let_go"))
    check("one frame unit spans 1.5 museum metres", frame.global_basis.get_scale().is_equal_approx(Vector3.ONE * 1.5))
    check("station scale preserves the starting-position metre values", station.global_basis.get_scale().is_equal_approx(Vector3.ONE))
    await snapshot("held-point", station.global_position + Vector3(0.6,1.65,-1.55), station.global_position + Vector3(0,1.2,0), 55)
    await snapshot("coordinates-basin", frame.global_position + Vector3(4,1.65,-4), frame.global_position + Vector3(0,0.25,-1), 66)

    var station_parent := station.get_parent()
    var placement := station.transform
    var original_source: String = station.get_script().source_code
    var start: Vector3 = held.global_position
    var edit := GDScript.new()
    edit.source_code = original_source.replace("held.position = CENTRE", "held.position = CENTRE + Vector3(0, 0.5, 0)")
    check("printed starting-position edit compiles", edit.reload() == OK)
    station.free()
    station = edit.new()
    station.condition = "held"
    station.transform = placement
    station_parent.add_child(station)
    held = station.point
    await tick()
    check("same held variant begins half a metre higher", held.global_position.is_equal_approx(start + Vector3.UP * 0.5))
    check("surface and collider stay attached with equal radii", is_equal_approx(held.get_node("MeshInstance3D/Sphere").radius,0.07) and is_equal_approx(held.get_node("CollisionShape3D").shape.radius,0.07))
    check("station label remains in place", station.transform.is_equal_approx(placement))
    await snapshot("raised-point", station.global_position + Vector3(0.6,1.65,-1.55), station.global_position + Vector3(0,1.2,0), 55)
    station.free()
    var restored := GDScript.new()
    restored.source_code = original_source
    restored.reload()
    station = restored.new()
    station.condition = "held"
    station.transform = placement
    station_parent.add_child(station)
    held = station.point
    await tick()
    check("restored point starts at original position and reporting resumes", held.global_position.is_equal_approx(start) and frame._find_point() == held)

    var grabber := SuppliedGrabber.new()
    root.add_child(grabber)
    grabber.global_transform = held.global_transform
    held.pick_up(grabber)
    grabber.global_position += Vector3(0.4,0.15,0.25)
    await settle()
    check("supplied grab carries the production point", held.is_picked_up() and held.global_position.distance_to(start) > 0.3)
    check_cards(2, "after movement")
    check("parent-local point address differs from frame-local address", not held.position.is_equal_approx(frame.to_local(held.global_position)))
    var old_frame := frame.global_transform
    var world_before := held.global_position
    var local_before := frame.to_local(world_before)
    frame.global_position += Vector3.RIGHT * 1.5
    await settle()
    check("moving reference leaves world position fixed", held.global_position.is_equal_approx(world_before))
    check("moving reference by 1.5 m changes local X by one", frame.to_local(held.global_position).is_equal_approx(local_before - Vector3.RIGHT))
    check_cards(2, "after moving reference")
    frame.global_transform = old_frame
    await settle()

    # Choose nearby positions differing by 0.003 m that round to the same hundredth.
    grabber.global_position = frame.global_position + Vector3(1.231,1.12,-1.231)
    grabber.global_position.x = floorf(grabber.global_position.x) + 0.231
    await settle()
    var world_card: Node3D
    for card in cards:
        if card.space == "world": world_card = card
    var first_report: String = world_card.get_node("Value").text
    var first_position := held.global_position
    grabber.global_position.x += 0.003
    await settle()
    check("two-decimal report can stay still while position moves", first_report == world_card.get_node("Value").text and held.global_position.distance_to(first_position) > 0.002)
    await card_picture("two-decimals",world_card)
    var report_position := held.global_position
    var revised_cards: Array = []
    for card in cards:
        var source: String = card.get_script().source_code
        var old := 't = "x = %.2f\\ny = %.2f\\nz = %.2f" % [p.x, p.y, p.z]'
        var new := 't = "x = %.3f\\ny = %.3f\\nz = %.3f" % [p.x, p.y, p.z]'
        check("printed formatting line exists", source.contains(old))
        var script := GDScript.new()
        script.source_code = source.replace(old,new)
        check("three-decimal card source compiles", script.reload() == OK)
        var parent: Node = card.get_parent()
        var card_transform: Transform3D = card.transform
        var reference: String = card.space
        var size: float = card.display_scale
        card.free()
        var replacement: Node3D = script.new()
        replacement.space = reference
        replacement.readout_channel = "point_one_main"
        replacement.display_scale = size
        replacement.transform = card_transform
        parent.add_child(replacement)
        revised_cards.append(replacement)
        if reference == "world": world_card = replacement
    cards = revised_cards
    await settle()
    check_cards(3, "after formatting edit")
    check("formatting edit leaves the held position unchanged", held.global_position.is_equal_approx(report_position))
    await card_picture("three-decimals",world_card)
    held.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
    check("supplied release lets go", not held.is_picked_up())
    observations["frame_world"] = xyz(frame.global_position)
    observations["same_position"] = xyz(report_position)
    observations["two_decimals"] = first_report
    observations["three_decimals"] = world_card.get_node("Value").text
    grabber.queue_free()

func settle() -> void:
    for i in range(12): await physics_frame
    await process_frame

func check_cards(digits: int, when: String) -> void:
    for card in cards:
        var value: Vector3 = held.global_position if card.space == "world" else frame.to_local(held.global_position)
        var pattern := "x = %.2f\ny = %.2f\nz = %.2f" if digits == 2 else "x = %.3f\ny = %.3f\nz = %.3f"
        check(card.space + " card " + when, card.get_node("Value").text == pattern % [value.x,value.y,value.z])

func card_picture(name: String, card: Node3D) -> void:
    await snapshot(name,card.to_global(Vector3(0.25,0.05,2.7)),card.global_position,48)

func finish() -> void:
    var report := {"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Actual museum hall and pickable; synthetic holder uses supplied pickup/release. Printed edits compiled and substituted in memory at existing placements. No production artifacts changed; no physical headset or learner test."}
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("COORDINATES EXISTING POINT ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
