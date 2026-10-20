extends SceneTree

const Triangle = preload("surface_triangle.gd")
const Line = preload("line_skin.gd")
const Hand = preload("synthetic_hand.gd")
var Pointer
var Scene
const OUT = "res://doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/ghost/student/attempt_02_engine.json"
var checks: Array = []
var observations: Dictionary = {}
var host
var pointer: Node3D
var hand

func _initialize() -> void:
    run.call_deferred()

func check(id: String, ok: bool, detail = null) -> void:
    checks.append({"id": id, "pass": ok, "detail": detail})
    print("CHECK ", id, " ", "PASS" if ok else "FAIL", " ", str(detail))

func near(a: float, b: float, tol: float = 0.001) -> bool:
    return absf(a-b) <= tol

func near2(a: Vector2, b: Vector2, tol: float = 0.00002) -> bool:
    return a.distance_to(b) <= tol

func near3(a: Vector3, b: Vector3, tol: float = 0.00002) -> bool:
    return a.distance_to(b) <= tol

func xyz(v: Vector3) -> Array:
    return [v.x,v.y,v.z]

func coords(values: Array) -> Array:
    var result := []
    for value in values: result.append([value.x,value.y])
    return result

func same_pairs(a: Array, b: Array) -> bool:
    if a.size() != b.size(): return false
    for i in range(a.size()):
        if not near2(a[i],b[i]): return false
    return true

func frames(count: int = 3) -> void:
    for i in range(count):
        await physics_frame
        await process_frame

func press_button(word: String) -> void:
    var area = host.get_node(word + "/InteractableAreaButton")
    Pointer.pressed(pointer, area, area.global_position)
    check("button_"+word+"_press_"+str(checks.size()), area.pressed, "real supplied pointer callback chain; synthetic event source")
    Pointer.released(pointer, area, area.global_position)
    check("button_"+word+"_release_"+str(checks.size()), not area.pressed)
    await frames(2)

func key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await frames(2)
    event = InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = false
    Input.parse_input_event(event)
    await frames(1)

func move_hand(local_target: Vector3, count: int = 5) -> void:
    hand.local_target = local_target
    await frames(count)

func numerical() -> void:
    var model = Triangle.new()
    model.points.assign([Vector2.ZERO,Vector2(1,0),Vector2(0,1)])
    var plane = model.measure()
    check("reference_plane_valid", plane.valid)
    check("reference_plane_angles", near(plane.angles[0],90) and near(plane.angles[1],45) and near(plane.angles[2],45), plane.angles)
    check("reference_plane_sum", near(plane.sum,180), plane.sum)
    var saved = model.points.duplicate()
    model.spherical = true
    var curved = model.measure()
    observations.reference_sphere = curved
    check("reference_sphere_angles", near(curved.angles[0],90) and near(curved.angles[1],54.735610317245) and near(curved.angles[2],54.735610317245), curved.angles)
    check("reference_sphere_sum", near(curved.sum,199.47122063449), curved.sum)
    check("mode_keeps_pairs_numerical", same_pairs(saved,model.points))
    var max_radius_error := 0.0
    var max_plane_error := 0.0
    var max_tangent_dot := 0.0
    var max_tangent_length_error := 0.0
    var endpoints_ok := true
    var count := 0
    for i in range(3):
        var a: Vector3 = model.corner(model.points[i])
        var b: Vector3 = model.corner(model.points[(i+1)%3])
        var normal := a.cross(b).normalized()
        var samples: Array[Vector3] = model.edge(i)
        endpoints_ok = endpoints_ok and near3(samples[0],a) and near3(samples[-1],b)
        for sample in samples:
            max_radius_error = maxf(max_radius_error,absf(sample.length()-1))
            max_plane_error = maxf(max_plane_error,absf(normal.dot(sample)))
            count += 1
        var tangent: Vector3 = model.tangent(a,b)
        max_tangent_dot = maxf(max_tangent_dot,absf(a.dot(tangent)))
        max_tangent_length_error = maxf(max_tangent_length_error,absf(tangent.length()-1))
    check("sphere_all_edge_endpoints",endpoints_ok)
    check("sphere_75_samples_unit_radius",count == 75 and max_radius_error < 0.000002,{"count":count,"max_error":max_radius_error})
    check("sphere_75_samples_great_circle_plane",max_plane_error < 0.000002,max_plane_error)
    check("sphere_tangent_perpendicular",max_tangent_dot < 0.000002,max_tangent_dot)
    check("sphere_tangent_unit",max_tangent_length_error < 0.000002,max_tangent_length_error)
    var pole := Vector3.UP
    var octant := [pole,Vector3.RIGHT,Vector3.BACK]
    var octant_angles := []
    for i in range(3):
        var u: Vector3 = model.tangent(octant[i],octant[(i+1)%3])
        var v: Vector3 = model.tangent(octant[i],octant[(i+2)%3])
        octant_angles.append(rad_to_deg(atan2(u.cross(v).length(),u.dot(v))))
    check("direct_octant_three_right_angles",near(octant_angles[0],90) and near(octant_angles[1],90) and near(octant_angles[2],90),octant_angles)
    var lengths := []
    for pieces in [1,24,96]:
        var samples: Array[Vector3] = model.edge(0,pieces)
        var length := 0.0
        for i in range(samples.size()-1): length += samples[i].distance_to(samples[i+1])
        lengths.append(length)
    check("drawing_refinement_converges_from_below",lengths[0] < lengths[1] and lengths[1] < lengths[2] and lengths[2] < PI/4, lengths)
    check("drawing_refinement_preserves_measurement", near(model.measure().sum,curved.sum))
    check("zero_piece_count_clamped",model.edge(0,0).size()==2)
    check("negative_piece_count_clamped",model.edge(0,-7).size()==2)
    model.points.assign([Vector2.ZERO,Vector2(.5,0),Vector2(0,.5)])
    var half_sphere = model.measure()
    observations.variation_half_sphere = half_sphere
    check("own_variation_half_sphere_angles",near(half_sphere.angles[0],90) and near(half_sphere.angles[1],48.1896851042) and near(half_sphere.angles[2],48.1896851042),half_sphere.angles)
    check("own_variation_half_sphere_sum",near(half_sphere.sum,186.3793702083),half_sphere.sum)
    check("own_variation_spherical_excess_shrinks",half_sphere.sum > 180 and half_sphere.sum < curved.sum)
    var half_arc := acos(clampf(model.corner(model.points[0]).dot(model.corner(model.points[1])),-1,1))
    check("own_variation_sphere_arc_does_not_halve",absf(half_arc - PI/8) > .05,half_arc)
    model.spherical = false
    var half_plane = model.measure()
    check("own_variation_plane_angles_preserved",near(half_plane.angles[0],90) and near(half_plane.angles[1],45) and near(half_plane.angles[2],45),half_plane.angles)
    check("own_variation_plane_length_halves",near(model.corner(model.points[0]).distance_to(model.corner(model.points[1])),.5))
    var cases := [
        [Vector2.ZERO,Vector2.ZERO,Vector2.ONE],
        [Vector2(-1,0),Vector2.ZERO,Vector2(1,0)],
        [Vector2.ZERO,Vector2(1,0),Vector2(.5,.000001)]
    ]
    for spherical in [false,true]:
        model.spherical = spherical
        for i in range(cases.size()):
            model.points.assign(cases[i])
            var refused = model.measure()
            check("degeneracy_mode_"+str(spherical)+"_case_"+str(i),not refused.valid and refused.angles.is_empty())
        model.points.assign([Vector2.ZERO,Vector2(1,0),Vector2(.5,.02)])
        check("degeneracy_recovers_mode_"+str(spherical),model.measure().valid)
    var line = Line.new()
    line.show_segment(Vector3.ZERO,Vector3.ZERO,0)
    check("line_zero_hidden",not line.visible)
    line.show_segment(Vector3(1,2,3),Vector3(0,2,0),2)
    check("line_vertical_recovers",line.visible and near(line.mesh.height,2) and near3(line.position,Vector3(1,3,3)) and near3(line.basis.y,Vector3.UP))
    line.free()

func run() -> void:
    await frames(3)
    Pointer = load("res://addons/godot-xr-tools/events/pointer_event.gd")
    Scene = load("res://doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/ghost/student/reconstructed.tscn")
    numerical()
    host = Scene.instantiate()
    host.position = Vector3(2.3,-.4,1.7)
    host.rotation = Vector3(.23,.61,-.17)
    root.add_child(host)
    pointer = Node3D.new()
    root.add_child(pointer)
    hand = Hand.new()
    root.add_child(hand)
    hand.frame = host
    await frames(5)
    for word in ["Plane","Sphere","Reset"]:
        for component in ["HandPoseArea","InteractableAreaButton/Rumbler"]:
            var child = host.get_node(word+"/"+component)
            var script = child.get_script()
            check("dependency_"+word+"_"+component,script != null and script.can_instantiate(),"script attached and can instantiate")
    check("host_named_attachment",host.name == "SurfaceStudy")
    check("host_unit_scale",near3(host.scale,Vector3.ONE))
    check("host_three_points",host.points.size()==3)
    check("host_72_cylinders",host.edges.size()==72)
    check("host_corner_labels_and_readout",host.labels.size()==3 and host.readout != null and host.readout.text.contains("PLANE / straight edges"))
    check("host_plane_mesh",host.plane.mesh is BoxMesh and near3(host.plane.mesh.size,Vector3(2.4,.04,2.4)))
    check("host_sphere_mesh",host.sphere.mesh is SphereMesh and near(host.sphere.mesh.radius,.75))
    check("host_plane_visibility_and_face",host.plane.visible and not host.sphere.visible and host.face.mesh != null)
    var ids := []
    var body_setup := true
    var frame_error := 0.0
    for i in range(3):
        var point = host.points[i]
        ids.append(point.get_instance_id())
        body_setup = body_setup and point.freeze and point.collision_layer == 4 and point.collision_mask == 0 and point.get_child(0).mesh is SphereMesh and point.get_child(1).shape is SphereShape3D
        frame_error = maxf(frame_error,point.global_position.distance_to(host.to_global(host.display(host.model.corner(host.model.points[i])))))
    check("host_point_body_mesh_collision_freeze",body_setup)
    check("host_transformed_frame_positions",frame_error < .00002,frame_error)
    var all_edges := true
    for edge in host.edges: all_edges = all_edges and edge.visible and edge.mesh is CylinderMesh and edge.mesh.height > 0
    check("host_initialized_edge_geometry",all_edges)
    var record = host.model.points.duplicate()
    var plane_measure = host.model.measure()
    await press_button("Sphere")
    check("sphere_button_selects_mode",host.model.spherical)
    check("sphere_button_preserves_pairs",same_pairs(record,host.model.points))
    var ids_after := []
    for point in host.points: ids_after.append(point.get_instance_id())
    check("sphere_button_preserves_instances",ids==ids_after)
    check("sphere_host_visual_state",host.sphere.visible and not host.plane.visible and host.face.mesh == null and host.readout.text.contains("SPHERE / great-circle edges"))
    check("sphere_default_sum_prediction",near(host.model.measure().sum,213.456909662684),host.model.measure().sum)
    await press_button("Plane")
    check("plane_button_restores_mode_and_measurement",not host.model.spherical and near(host.model.measure().sum,plane_measure.sum) and same_pairs(record,host.model.points))
    await key(KEY_S)
    check("keyboard_s_selects_sphere",host.model.spherical)
    hand.point = host.points[2]
    hand.local_target = host.CENTRE + Vector3(.24,.4,-.12)
    hand.active = true
    host.points[2].on_desktop_grab(hand)
    await frames(8)
    check("sustained_hand_callback_reports_held",host.points[2].held() and host.any_held())
    check("sustained_driver_many_frames",hand.render_ticks >= 8 and hand.physics_ticks >= 8,{"render":hand.render_ticks,"physics":hand.physics_ticks})
    check("spherical_transformed_inverse",near2(host.model.points[2],Vector2(.6,-.3)),coords(host.model.points))
    check("held_point_can_leave_surface",host.points[2].global_position.distance_to(host.to_global(host.display(host.model.corner(host.model.points[2])))) > .2)
    var held_record = host.model.points.duplicate()
    await press_button("Plane")
    check("mode_button_refused_while_held",host.model.spherical and same_pairs(held_record,host.model.points))
    await press_button("Reset")
    check("reset_button_refused_while_held",same_pairs(held_record,host.model.points))
    await key(KEY_P)
    check("keyboard_mode_refused_while_held",host.model.spherical)
    await key(KEY_R)
    check("keyboard_reset_refused_while_held",same_pairs(held_record,host.model.points))
    await move_hand(host.CENTRE + Vector3(2,.5,-3))
    check("hand_chart_bounds",near2(host.model.points[2],Vector2(1,-1)),coords(host.model.points))
    var bounded_record = host.model.points.duplicate()
    await move_hand(host.CENTRE + Vector3(.3,-.1,.2))
    check("lower_chart_refuses_keeps_record",host.hand_refused and same_pairs(bounded_record,host.model.points))
    check("lower_chart_refusal_visible_in_readout",host.readout.text.contains("Hand outside upper chart: last record kept."),host.readout.text)
    await move_hand(host.CENTRE + Vector3(.3,.019,.2))
    check("guard_below_point_zero_two_refuses",host.hand_refused and same_pairs(bounded_record,host.model.points))
    var exact_accepted: bool = host.record_hand(2,host.CENTRE + Vector3(0,.02,0))
    check("exact_guard_boundary_refuses",not exact_accepted)
    await move_hand(host.CENTRE + Vector3(.0021,.021,-.0042))
    check("guard_above_recovers",not host.hand_refused and near2(host.model.points[2],Vector2(.1,-.2)),coords(host.model.points))
    check("recovery_readout",not host.readout.text.contains("Hand outside upper chart"))
    hand.active = false
    host.points[2].on_desktop_drop(hand)
    check("drop_clears_held",not host.points[2].held())
    for i in range(6):
        await frames(1)
        check("sphere_release_frame_"+str(i),near3(host.points[2].global_position,host.to_global(host.display(host.model.corner(host.model.points[2])))))
    await press_button("Reset")
    check("reset_after_release_keeps_sphere",host.model.spherical and same_pairs(record,host.model.points))
    await key(KEY_P)
    check("keyboard_p_selects_plane",not host.model.spherical)
    hand.local_target = Vector3(.2,2.5,-.35)
    hand.active = true
    host.points[2].on_desktop_grab(hand)
    await frames(6)
    check("plane_sustained_transformed_inverse",near2(host.model.points[2],Vector2(.2,-.35)),coords(host.model.points))
    check("plane_held_body_height_is_hand",near(host.to_local(host.points[2].global_position).y,2.5))
    hand.active = false
    host.points[2].on_desktop_drop(hand)
    for i in range(6):
        await frames(1)
        check("plane_release_frame_"+str(i),near3(host.to_local(host.points[2].global_position),Vector3(.2,1.12,-.35)))
    await key(KEY_R)
    check("keyboard_r_resets_and_keeps_plane",not host.model.spherical and same_pairs(record,host.model.points))
    host.model.points.assign([Vector2(-1,0),Vector2.ZERO,Vector2(1,0)])
    host.redraw()
    check("host_degenerate_face_removed",host.face.mesh==null)
    check("host_degenerate_readout",host.readout.text.contains("No triangle reading"))
    check("host_degenerate_corner_labels",host.labels[0].text=="A: —" and host.labels[1].text=="B: —" and host.labels[2].text=="C: —")
    host.model.points.assign([Vector2.ZERO,Vector2.ZERO,Vector2(1,1)])
    host.redraw()
    check("host_coincident_refusal_and_hidden_edge",host.readout.text.contains("No triangle reading") and not host.edges[0].visible)
    host.model.points.assign([Vector2.ZERO,Vector2(.5,0),Vector2(0,.5)])
    host.redraw()
    check("host_separation_face_readout_recover",host.face.mesh != null and host.readout.text.contains("Sum 180.00") and host.edges[0].visible)
    await press_button("Sphere")
    check("host_variation_spherical_readout",host.readout.text.contains("Sum 186.38") and host.face.mesh == null and host.sphere.visible,host.readout.text)
    var host_radius_error := 0.0
    var cylinder_endpoint_error := 0.0
    for i in range(3):
        host_radius_error = maxf(host_radius_error,absf(host.to_local(host.points[i].global_position).distance_to(host.CENTRE)-host.RADIUS))
        var samples: Array[Vector3] = host.model.edge(i,host.PIECES)
        for j in range(host.PIECES):
            var edge = host.edges[i*host.PIECES+j]
            var start: Vector3 = edge.position - edge.basis.y * edge.mesh.height * .5
            var end: Vector3 = edge.position + edge.basis.y * edge.mesh.height * .5
            cylinder_endpoint_error = maxf(cylinder_endpoint_error,start.distance_to(host.display(samples[j])))
            cylinder_endpoint_error = maxf(cylinder_endpoint_error,end.distance_to(host.display(samples[j+1])))
    check("host_transformed_sphere_radius",host_radius_error < .00002,host_radius_error)
    check("host_all_cylinder_endpoints",cylinder_endpoint_error < .00002,cylinder_endpoint_error)
    observations.final_readout = host.readout.text
    observations.synthetic_driver = {"render_ticks":hand.render_ticks,"physics_ticks":hand.physics_ticks}
    observations.host_transform = {"position":xyz(host.position),"rotation":xyz(host.rotation),"scale":xyz(host.scale)}
    var failures := 0
    for assertion in checks:
        if not assertion["pass"]: failures += 1
    var result := {"attempt":2,"checks":checks,"assertion_count":checks.size(),"pass_count":checks.size()-failures,"fail_count":failures,"observations":observations,"evidence":"real Godot SceneTree; synthetic controls and hand; no actual pointer ray or headset"}
    var output := FileAccess.open(OUT,FileAccess.WRITE)
    output.store_string(JSON.stringify(result,"  "))
    output.close()
    print("RESULT ",JSON.stringify({"assertions":checks.size(),"failures":failures}))
    host.queue_free()
    pointer.queue_free()
    hand.queue_free()
    await process_frame
    quit(0 if failures==0 else 1)
