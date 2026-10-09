extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	var e=find_scene("/prefab_overflow.gd")
	check("Prefab overflow replaces the existing conveyor in this hall",e!=null)
	if e==null:return
	await snapshot("setup",e.to_global(Vector3(5.8,2.2,-6.8)),e.to_global(Vector3(-0.5,1.8,0)),72)
	e.action("FEED / PAUSE");await create_timer(12).timeout
	await snapshot("the-queue",e.to_global(Vector3(3.7,2.1,-1.7)),e.to_global(Vector3(-0.8,1.6,-0.8)),77)
	var origin=XROrigin3D.new();root.add_child(origin)
	var controller=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=e.gate_grip.global_position;e.gate_grip.pick_up(hand)
	e.gate_grip.action_pressed.emit(e.gate_grip)
	var from=controller.global_position
	for i in range(150):
		controller.global_position=from.lerp(e.to_global(Vector3(-1.6,1.8,2.8)),minf(float(i)/90,1))
		await physics_frame
	await snapshot("pull-and-flood",e.to_global(Vector3(3.5,2.0,3.4)),e.to_global(Vector3(-1,1.4,0.3)),79)
	await create_timer(6).timeout
	e.gate_grip.action_released.emit(e.gate_grip);e.gate_grip.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	await create_timer(5).timeout
	await snapshot("aftermath",e.to_global(Vector3(5.7,5.1,6.5)),e.to_global(Vector3(-0.5,0.8,0.2)),75)
	check("Actual museum cargo travelled beyond the gate",e.passed_gate.size()>0)
	check("Actual museum keeps spilled props",e.spilled.size()>0)
	observations.overflow={"delivered":e.admitted,"beyond_gate":e.passed_gate.size(),"spilled":e.spilled.size(),"gate_angle":e.gate.rotation.y,"receiver_angle":e.receiver.rotation.x}
