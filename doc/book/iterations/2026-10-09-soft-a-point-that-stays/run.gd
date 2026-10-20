extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-soft-a-point-that-stays/printed/"
const OUT := "res://doc/book/iterations/2026-10-09-soft-a-point-that-stays/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("SOFT LESSON ","PASS " if ok else "FAIL ",title)
func ticks(n: int = 2) -> void:
	for i in n: await physics_frame; await process_frame
func positions(body: SoftBody3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for i in body.rest_points.size(): result.append(body.get_point_transform(i))
	return result
func max_difference(a: PackedVector3Array, b: PackedVector3Array) -> float:
	var value := 0.0
	for i in a.size(): value = maxf(value,a[i].distance_to(b[i]))
	return value
func run() -> void:
	check("Prepared project selects Jolt",ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics")
	var host := Node3D.new();host.position=Vector3(3,0,-2);host.rotation.y=0.6;root.add_child(host)
	var study = load(DIR+"study.gd").new();host.add_child(study);await ticks()
	var body: SoftBody3D = study.cube
	check("Whole printed host constructs a soft cube and inherited point",body != null and study.point.has_method("pick_up") and study.caption.text.contains("ONE POINT STAYS"))
	check("Mesh supplies geometry and contact without child collision shape",body.get_child_count()==0 and body.mesh != null)
	var original: PackedVector3Array = body.rest_points.duplicate()
	var idx: int = body.anchor_index
	var p: Vector3 = original[idx]
	var nearest := INF
	for v in original:
		if is_equal_approx(v.y,0.15):nearest=minf(nearest,v.x*v.x+v.z*v.z)
	check("Anchor is on the top face nearest its centre",is_equal_approx(p.y,0.15) and is_equal_approx(p.x*p.x+p.z*p.z,nearest))
	check("Declared index is pinned",body.is_point_pinned(idx))
	check("Initial coefficients match the placed cube",is_equal_approx(body.linear_stiffness,0.5) and is_equal_approx(body.damping_coefficient,0.01) and is_equal_approx(body.pressure_coefficient,1.0) and body.simulation_precision==5)
	check("Point collision layer is included",body.collision_mask & study.point.collision_layer != 0)
	var before := positions(body);var anchor: Vector3=before[idx]
	observations.first_anchor=[anchor.x,anchor.y,anchor.z]
	var expected:Vector3=study.to_global(Vector3(0,1.3,0)+p)
	observations.expected_world_anchor=[expected.x,expected.y,expected.z]
	check("Pin agrees with its reference under a translated rotated parent",anchor.distance_to(expected)<0.001)
	var rid: RID=body.get_physics_rid();var mesh_id: int=body.mesh.get_instance_id()
	body.apply_central_impulse(Vector3(0.12,0,0));await ticks(45)
	var moved := positions(body)
	check("Physics changes constituent positions",max_difference(before,moved)>0.002)
	check("Pinned position stays fixed during motion",anchor.distance_to(moved[idx])<0.001)
	check("Reference coordinates remain unchanged",body.rest_points==original)
	check("Deformation retains mesh resource and vertex count",body.mesh.get_instance_id()==mesh_id and body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==original.size())
	study.act("STIFFNESS")
	check("Stiffness changes independently",is_equal_approx(body.linear_stiffness,0.1) and is_equal_approx(body.damping_coefficient,0.01) and is_equal_approx(body.pressure_coefficient,1.0))
	study.act("DAMPING")
	check("Damping changes independently",is_equal_approx(body.damping_coefficient,0.1) and is_equal_approx(body.linear_stiffness,0.1))
	study.act("PRESSURE")
	check("Pressure can be removed",is_zero_approx(body.pressure_coefficient))
	await ticks(10);var state_before_reset:=positions(body)
	study.act("RESET");var state_after_reset:=positions(body)
	check("Settings reset retains the same simulated body",body.get_physics_rid()==rid and study.cube==body)
	check("Reset does not rewind vertex positions",max_difference(state_before_reset,state_after_reset)<0.0001)
	check("Reset restores coefficients and retains attachment",is_equal_approx(body.linear_stiffness,0.5) and is_equal_approx(body.damping_coefficient,0.01) and is_equal_approx(body.pressure_coefficient,1.0) and body.is_point_pinned(idx))
	var event:=InputEventKey.new();event.keycode=KEY_2;event.pressed=true;study._unhandled_key_input(event)
	check("Keyboard reaches the same damping operation",is_equal_approx(body.damping_coefficient,0.1))
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await ticks();hand.global_position+=Vector3(0.1,0.1,0);await ticks()
	check("Supplied XRTools grip carries the same point",study.point.is_picked_up())
	var stiffness:float=body.linear_stiffness;study.point.action();await ticks()
	check("Held trigger changes stiffness",not is_equal_approx(stiffness,body.linear_stiffness))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks()
	check("Release parks the point in the host frame",study.point.position.is_equal_approx(Vector3(0.45,1.3,0.25)))
	body.set_point_pinned(idx,false);await ticks(30)
	check("Removing the pin fails the fixed-position invariant",anchor.distance_to(body.get_point_transform(idx))>0.02)
	observations.maximum_motion=max_difference(before,moved)
	var low=load(OUT+"variation/study.gd").new();low.position=Vector3(2,0,0);host.add_child(low);await ticks(3)
	check("Subdivision edit creates fewer vertices",low.cube.rest_points.size()<original.size() and low.cube.rest_points.size()==96 and original.size()==216)
	var low_pin:Vector3=low.cube.get_point_transform(low.cube.anchor_index)
	check("Subdivision edit selects a top-face point",is_equal_approx(low.cube.rest_points[low.cube.anchor_index].y,0.15))
	low.cube.apply_central_impulse(Vector3(.1,0,0));await ticks(30)
	check("Subdivision edit retains its selected pin during physics",low_pin.distance_to(low.cube.get_point_transform(low.cube.anchor_index))<0.001)
	low.queue_free();await ticks()
	var touch=load(DIR+"study.gd").new();touch.position=Vector3(2,0,0);host.add_child(touch)
	var control=load(DIR+"study.gd").new();control.position=Vector3(4,0,0);host.add_child(control)
	control.cube.collision_mask &= ~4
	touch.point.on_desktop_grab(host);control.point.on_desktop_grab(host)
	await ticks(45)
	var touch_before:=positions(touch.cube);var control_before:=positions(control.cube)
	var touch_pin:Vector3=touch.cube.get_point_transform(touch.cube.anchor_index)
	var contact_difference:=0.0
	for step in 110:
		var probe_at:=Vector3(0,1.25,0.35-step*.006)
		touch.point.global_position=touch.to_global(probe_at);control.point.global_position=control.to_global(probe_at)
		await ticks(1)
		var contact:=positions(touch.cube);var no_contact:=positions(control.cube)
		for i in contact.size():contact_difference=maxf(contact_difference,((contact[i]-touch_before[i])-(no_contact[i]-control_before[i])).length())
	check("Inherited point contact changes motion versus disabled-contact control",contact_difference>0.01)
	check("Hand-like contact retains the anchor",touch_pin.distance_to(touch.cube.get_point_transform(touch.cube.anchor_index))<0.001)
	observations.point_contact_difference=contact_difference
	observations.vertices={"divisions_4":216,"divisions_2":96}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Native Jolt whole host, fixed-point invariant and released-pin negative control; supplied XRTools grip/action/release. No physical headset or measured material calibration."},"  "))
	origin.queue_free();host.queue_free();await ticks();quit(0 if failures.is_empty() else 1)
