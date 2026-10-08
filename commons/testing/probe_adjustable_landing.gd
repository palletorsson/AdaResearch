extends "res://commons/testing/probe_transformation_opening.gd"
## Actual embedded museum, native slider/reset signals, real capsule crossings.

func _initialize() -> void:
	map_name = "Trans_Introduction"
	_run.call_deferred()

func check_crossings(grid: Node3D) -> void:
	await super.check_crossings(grid)
	var banks := by_script(grid,"/adjustable_landing.gd")
	check("one adjustable landing loaded", banks.size() == 1)
	if banks.size() != 1: return
	var bank = banks[0]
	var rc = by_script(grid,"/rotation_cube.gd")[0]
	var bridge_before: Transform3D = rc.static_body.global_transform
	var deck := grid.global_position.y + 0.5
	check("landing starts at deck", absf(bank.landing.global_position.y + 0.1 - deck) < 0.002)
	var slider: Node3D = bank.slider
	check("control height is reachable", slider.global_position.y-deck > 0.9 and slider.global_position.y-deck < 1.3, slider.global_position.y-deck)
	bank.slider.set_normalized_value(1.0)
	bank.slider.slider_moved.emit(Vector3.ZERO)
	check("native slider selects far bank", is_equal_approx(bank.target_displacement,1.0))
	for i in 260: await tick()
	check("bank translates exactly one metre", is_equal_approx(bank.displacement,1.0),bank.displacement)
	check("bank remains level after moving", absf(bank.landing.global_position.y+0.1-deck)<0.002)
	check("bridge transform remains untouched", rc.static_body.global_transform.is_equal_approx(bridge_before))
	var leading_edge: float = bank.landing.global_position.z - 1.5
	check("far bank leaves 0.70m surface gap at aligned pose", absf(leading_edge-collider_bounds(rc).end.z-0.7)<0.002)
	var walker := CharacterBody3D.new()
	walker.collision_layer = 0
	walker.collision_mask = 1
	walker.floor_snap_length = 0.15
	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.22; capsule.height=1.6
	cs.shape=capsule; cs.position.y=0.8; walker.add_child(cs);root.add_child(walker)
	walker.global_position=grid.to_global(Vector3(5,0.52,15))
	var lowest: float = walker.global_position.y
	for i in 135:
		await physics_frame
		walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,2)
		walker.move_and_slide()
		lowest=minf(lowest,walker.global_position.y)
		await process_frame
	check("same straight-walking capsule loses support at far setting",lowest < deck-0.3,lowest-deck)
	measurements["far_setting_capsule_drop_m"]=deck-lowest
	# Walk the permanent aisle with the landing still displaced.
	walker.global_position=grid.to_global(Vector3(2,0.52,16))
	walker.velocity=Vector3.ZERO;lowest=walker.global_position.y
	for i in 195:
		await physics_frame
		walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,2)
		walker.move_and_slide();lowest=minf(lowest,walker.global_position.y)
		await process_frame
	check("left bypass remains physically walkable",grid.to_local(walker.global_position).z>22.0 and lowest>deck-0.02)
	var button=bank.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	for i in 260: await tick()
	check("native RESET restores overlap",is_zero_approx(bank.displacement))
	check("RESET synchronizes slider",is_zero_approx(float(bank.slider.get_normalized_value())))
	walker.global_position=grid.to_global(Vector3(5,0.52,15))
	walker.velocity=Vector3.ZERO;lowest=walker.global_position.y
	for i in 220:
		await physics_frame
		walker.velocity=Vector3(0,walker.velocity.y-9.8/60.0,2)
		walker.move_and_slide();lowest=minf(lowest,walker.global_position.y)
		await process_frame
	check("reset crossing supports same capsule through the far bank to the exit",grid.to_local(walker.global_position).z>22.0 and lowest>deck-0.02)
	walker.queue_free()

func finish() -> void:
	var output := "res://doc/space/transformation-experiments-2026-09-16/landing-checks.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"measurements":measurements,"actual_endless_museum":true,"headset_tested":false},"  "))
	print("[landing] ",checks.size()-failures.size(),"/",checks.size()," passed")
	quit(0 if failures.is_empty() else 1)
