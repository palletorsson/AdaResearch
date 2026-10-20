extends "res://tools/probes/transformation_encounters.gd"

const STUDY := "res://doc/book/iterations/2026-10-09-soft-bodies-three-attachments/student/study.tscn"

func physical_pins(body: SoftBody3D) -> Array[int]:
	var selected: Array[int] = []
	for i in body.rest_points.size():
		if body.is_point_pinned(i): selected.append(i)
	return selected

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false)
		stream.set_physics_process(false)
	var player = museum.get("_player")
	if player is Node3D:
		player.hide()
		player.set_process(false)
		player.set_physics_process(false)
		player.global_position = Vector3(0, -100, 0)
	camera.set_cull_mask_value(19, false)
	var exposure := CameraAttributesPractical.new()
	exposure.exposure_multiplier = 0.45
	camera.attributes = exposure
	var desk = find_scene("/timing_machines/soft_workshop.gd")
	check("Cloth's actual workshop exists", desk != null and desk.chapter == "cloth")
	if desk == null: return
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"))
	var cell := Vector2.ZERO
	for room in plan.plans:
		if room.map == map_id:
			for artifact in room.artifacts:
				if artifact.token == "soft_workshop_console": cell = Vector2(artifact.cell[0], artifact.cell[1])
	var map_origin: Vector3 = desk.global_position - hall.global_basis * Vector3(cell.x+0.5, 0, cell.y+0.5)
	var study = load(STUDY).instantiate()
	study.transform = Transform3D(desk.global_basis * Basis(Vector3.UP, 0.25), map_origin+hall.global_basis*Vector3(12.5,0,10.5))
	root.add_child(study)
	await tick()
	check("Two complete bodies, point and caption initialize", study.bodies.size()==2 and study.point != null and not study.caption.text.is_empty())
	check("Prepared museum uses Jolt", ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	var a: SoftBody3D = study.bodies[0]
	var b: SoftBody3D = study.bodies[1]
	check("Both sheets have the same 112 reference positions", a.rest_points.size()==112 and a.rest_points==b.rest_points)
	check("Triangle connectivity stays identical", a.mesh.get_mesh_arrays()[Mesh.ARRAY_INDEX]==b.mesh.get_mesh_arrays()[Mesh.ARRAY_INDEX])
	var same := true
	for property in ["total_mass", "linear_stiffness", "damping_coefficient", "pressure_coefficient", "simulation_precision", "collision_layer", "collision_mask"]:
		same = same and a.get(property)==b.get(property)
	check("Only the attachment arrangement differs in the recipes", same and a.basis==b.basis and a.position.y==b.position.y)
	check("Physical pin sets are two versus three with no leftover row pins", physical_pins(a)==a.pins and a.pins.size()==2 and physical_pins(b)==b.pins and b.pins.size()==3)
	var corner: int = study.nearest(b.rest_points, Vector3(0.6,0.7,0))
	check("Upper-right corner is held only in the reference", a.is_point_pinned(corner) and not b.is_point_pinned(corner))
	var initial := PackedVector3Array()
	for i in b.pins: initial.append(b.get_point_transform(i))
	var free_start := b.get_point_transform(corner)
	var index_stability := true
	for target in study.THREE:
		index_stability = index_stability and study.nearest(b.rest_points,target) in b.pins
	check("Selection stays in the local reference frame under the transformed host", index_stability)
	for i in 120: await tick()
	var error := 0.0
	for j in b.pins.size(): error = maxf(error, initial[j].distance_to(b.get_point_transform(b.pins[j])))
	var moved := free_start.distance_to(b.get_point_transform(corner))
	check("Three selected points stay within one millimetre", error < 0.001)
	check("Released upper-right corner moves more than five millimetres", moved > 0.005)
	observations.comparison = {"a_pins":a.pins,"b_pins":b.pins,"free_corner":corner,"free_corner_motion_m":moved,"largest_pin_error_m":error,"wait_physics_callbacks":120}
	check("Temporary learner approach has museum floor", not floor_at(study.to_global(Vector3(0,0.01,2))).is_empty())
	await snapshot("three-places",study.to_global(Vector3(0.15,2.3,4.9)),study.to_global(Vector3(0,1.6,0)),46)
	await snapshot("in-the-hall",study.to_global(Vector3(3.9,4.1,5.7)),study.to_global(Vector3(0,1.3,0)),59)
	var origin := XROrigin3D.new()
	root.add_child(origin)
	var hand := XRController3D.new()
	origin.add_child(hand)
	var pickup = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	hand.add_child(pickup)
	hand.global_position = study.point.global_position
	study.point.pick_up(pickup)
	await tick()
	check("Inherited PointBody grips through XRTools", study.point.held() and study.point.is_picked_up())
	var point_id: int = study.point.get_instance_id()
	var body_id: int = b.get_instance_id()
	study.point.action()
	await tick()
	check("Held trigger reconstructs bodies and keeps the same point", study.bodies[1].get_instance_id()!=body_id and study.point.get_instance_id()==point_id)
	check("Rebuild preserves the chosen two and three attachment rules", physical_pins(study.bodies[0]).size()==2 and physical_pins(study.bodies[1]).size()==3)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	await tick()
	await tick()
	check("Release parks the point in the transformed host", not study.point.held() and study.point.global_position.distance_to(study.to_global(study.PARK))<0.001)
	var frozen_body: SoftBody3D = study.bodies[1]
	var old_id := frozen_body.get_instance_id()
	var event := InputEventKey.new()
	event.keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await tick()
	check("Actual keyboard R also rebuilds", study.bodies[1].get_instance_id()!=old_id)
	observations.scope = "Author-operated new composition from printed Cloth code. New host only; no blind learner or physical-headset claim. Study is temporary inside the existing museum."
	check("All planned composition checks completed", true)
