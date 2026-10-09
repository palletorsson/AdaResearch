extends "res://tools/probes/transformation_encounters.gd"
## Printed edits on the existing corridor artifacts, with the museum's own walker.
var points := {}
var originals := {}
var original_source: String
var switch: Node3D
var walker: CharacterBody3D

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(2.0).timeout
    for node in hall.find_children("*", "Node3D", true, false):
        if node.get_script() != null and str(node.get_script().resource_path).ends_with("/point_condition.gd"):
            points[node.condition] = node
    check("the four existing corridor conditions are loaded", points.size() == 4 and points.has("absent") and points.has("visible") and points.has("solid") and points.has("pedestal"))
    if points.size() != 4: return
    walker = museum.get("_player")
    switch = find_scene("/point_sun_switch.gd")
    check("museum walker and existing light switch are available", walker != null and switch != null)
    if walker == null or switch == null: return
    original_source = points.visible.get_script().source_code.replace("\r", "")
    for kind in points:
        var node: Node3D = points[kind]
        var layers := 1
        var no_ambient := false
        if node.point != null:
            layers = node.point.layers
            no_ambient = node.point.material_override.disable_ambient_light
        originals[kind] = {"parent":node.get_parent(), "transform":node.transform, "layers":layers, "no_ambient":no_ambient}
        observations[kind] = xyz(node.global_position)
    check("empty station has its label but no hidden body", points.absent.point == null and points.absent.get_child_count() == 1 and points.absent.get_child(0) is Label3D)
    check("small meshes start with equal radii and heights", is_equal_approx(points.visible.point.mesh.radius,0.14) and is_equal_approx(points.solid.point.mesh.radius,0.14) and is_equal_approx(points.visible.point.mesh.height,0.28))
    var absent_result: Dictionary = await approach("absent")
    var visible_result: Dictionary = await approach("visible")
    var normal_result: Dictionary = await approach("solid")
    check("actual walker crosses the labelled absence", absent_result.hit == "")
    check("actual walker crosses the visible sphere", visible_result.hit == "")
    check("actual walker meets the solid sphere", normal_result.hit == "PointCollision")
    observations["baseline_contact"] = normal_result
    await corridor_picture()
    await sphere_picture("absence", "absent")
    await sphere_picture("surface", "visible")
    await sphere_picture("solid", "solid")

    if not await substitute({"const CENTRE := Vector3(0, 1.12, 0)":"const CENTRE := Vector3(0, 1.7, 0)"}): return
    check("height edit moves both small surfaces", is_equal_approx(points.visible.point.position.y,1.7) and is_equal_approx(points.solid.point.position.y,1.7))
    check("height edit also moves the solid boundary", is_equal_approx(points.solid.get_node("PointCollision").position.y,1.7))
    check("edited position still creates no sphere at the empty station", points.absent.point == null and points.absent.get_child_count() == 1)
    check("pedestal centre uses its separate value", is_equal_approx(points.pedestal.point.position.y,1.4))
    await sphere_picture("raised", "visible")

    if not await substitute({"const RADIUS := 0.14":"const RADIUS := 0.3"}): return
    check("radius edit grows both small meshes with correct full height", is_equal_approx(points.visible.point.mesh.radius,0.3) and is_equal_approx(points.solid.point.mesh.radius,0.3) and is_equal_approx(points.solid.point.mesh.height,0.6))
    check("same value grows the small solid boundary", is_equal_approx(shape("solid").radius,0.3))
    check("large pedestal sphere keeps its own dimensions", is_equal_approx(points.pedestal.point.mesh.radius,0.65) and is_equal_approx(shape("pedestal").radius,0.65))
    visible_result = await approach("visible")
    var grown_result: Dictionary = await approach("solid")
    check("enlarged visible sphere remains passable", visible_result.hit == "")
    check("enlarged solid sphere stops the same walker earlier", grown_result.hit == "PointCollision" and grown_result.distance_to_centre > normal_result.distance_to_centre + 0.1)
    await sphere_picture("grown", "solid")

    if not await substitute({"sphere_shape.radius = radius":"sphere_shape.radius = radius * 2.0"}): return
    check("boundary edit leaves both rendered radii unchanged", is_equal_approx(points.solid.point.mesh.radius,0.14) and is_equal_approx(points.pedestal.point.mesh.radius,0.65))
    check("shared boundary edit doubles both collision spheres", is_equal_approx(shape("solid").radius,0.28) and is_equal_approx(shape("pedestal").radius,1.3))
    var wider_result: Dictionary = await approach("solid")
    check("invisible growth stops the same walker earlier", wider_result.hit == "PointCollision" and wider_result.distance_to_centre > normal_result.distance_to_centre + 0.08)
    observations["enlarged_boundary_contact"] = wider_result

    if not await substitute({}): return
    var restored_result: Dictionary = await approach("solid")
    check("restored source restores matching shape and contact", is_equal_approx(points.solid.point.mesh.radius,shape("solid").radius) and absf(restored_result.distance_to_centre-normal_result.distance_to_centre)<0.02)
    var pointer := Node3D.new()
    root.add_child(pointer)
    XRToolsPointerEvent.pressed(pointer,switch.button,switch.button.global_position)
    XRToolsPointerEvent.released(pointer,switch.button,switch.button.global_position)
    await tick()
    check("existing wall button removes the directional sun", not switch.enabled and not switch.sun.visible)
    var dark_result: Dictionary = await approach("solid")
    check("turning off sunlight preserves collision and fill", dark_result.hit == "PointCollision" and absf(dark_result.distance_to_centre-normal_result.distance_to_centre)<0.02 and switch.fill.visible)
    await sphere_picture("sun-off", "solid")
    switch.set_sun_enabled(true)
    pointer.free()
    check("production artifact source remains unchanged", FileAccess.get_file_as_string("res://commons/primitives/point/point_condition.gd").replace("\r", "") == original_source)

func shape(kind: String) -> SphereShape3D:
    return points[kind].get_node("PointCollision").get_child(0).shape

func approach(kind: String) -> Dictionary:
    var at: Vector3 = points[kind].global_position
    walker.global_position = at + Vector3(0,0.03,-1.2)
    walker.velocity = Vector3.ZERO
    await physics_frame
    var hit: KinematicCollision3D = walker.move_and_collide(Vector3(0,0,2.4))
    return {"hit":str(hit.get_collider().name) if hit != null else "", "distance_to_centre":at.z-walker.global_position.z}

func substitute(edits: Dictionary) -> bool:
    var source := original_source
    for old in edits:
        check("printed replacement exists uniquely in source", source.count(old) == 1)
        source = source.replace(old,edits[old])
    var script := GDScript.new()
    script.source_code = source
    var valid := script.reload() == OK
    check("actual artifact with printed edits compiles", valid)
    if not valid: return false
    for kind in points:
        points[kind].free()
        var node: Node3D = script.new()
        node.condition = kind
        node.transform = originals[kind].transform
        originals[kind].parent.add_child(node)
        # The actual sun binds on a fresh run by source path. In-memory variants
        # have no source path; retain the original renderer settings for captures.
        for mesh in node.find_children("*","MeshInstance3D",true,false):
            mesh.layers = originals[kind].layers
            mesh.material_override.disable_ambient_light = originals[kind].no_ambient
        points[kind] = node
    await tick()
    return true

func corridor_picture() -> void:
    await snapshot("corridor", points.absent.global_position+Vector3(1.0,1.65,-0.9), points.solid.global_position+Vector3(0,1.0,0),67)

func sphere_picture(name: String, kind: String) -> void:
    var at: Vector3 = points[kind].global_position
    walker.global_position = at+Vector3(0,0.03,-3.0)
    await snapshot(name, at+Vector3(1.1,1.60,-1.6), at+Vector3(0,1.02,0),55)

func finish() -> void:
    var report := {"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Existing museum hall; printed source substitutions in memory at original placements, actual desktop CharacterBody3D sweeps and existing switch event. Original renderer masks retained for dynamic script variants. No physical headset or learner test."}
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("POINT ONE EXISTING POINTS ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
