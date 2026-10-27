extends "res://tools/probes/void_transfer_probe.gd"
## Narrow regression for added fixed deck supports. Existing input/unlock tests
## remain in native-checks.json; this run uses control methods and actual gravity.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	OS.set_environment("VOID_INVENTORY_PATH",out.path_join("support-test-inventory-"+str(Time.get_ticks_usec())+".json"))
	level=7;take_photos=true
	game=load("res://commons/void/void.tscn").instantiate();root.add_child(game);current_scene=game
	game.body.scripted_input=true;await frames(70)
	var gate: Node3D=station("matter-and")
	var supports: Array=gate.get_children().filter(func(n):return "PlanksSupportCube" in str(n.name))
	check("six actual independently editable source cube supports",supports.size()==6 and supports.all(func(n):return n.scene_file_path=="res://commons/artifacts/primitive_encounters/platform_block.tscn" and gate.part_defaults.has(str(n.name))))
	for support in supports:
		var hit := ray(support.global_position+Vector3(0,1.01,0),support.global_position+Vector3(0,.8,0))
		check(str(support.name)+" meets deck underside at 0.94 m",not hit.is_empty() and is_equal_approx(hit.position.y-gate.global_position.y,.94))
	for x in [-1.6,1.6]:
		var at: Vector3=gate.to_global(Vector3(x,1.1,-.5))
		check("logical gap remains physically open at "+str(x),ray(at,at-Vector3.UP*.6).is_empty())
	for value in [Vector2i.ZERO,Vector2i(0,1),Vector2i(1,0),Vector2i.ONE]:
		gate.reset_gate();gate.set_gate(0,value.x==1);gate.set_gate(1,value.y==1);gate.release_ball()
		for i in 1050:
			await frames(1)
			if gate.outcome>=0:break
		check("supported deck still computes physical AND "+str(value),gate.outcome==(1 if value==Vector2i.ONE else 0))
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180);game.atmosphere.environment.fog_enabled=false
	await photo("04-supported-planks-cube-floor7",gate.to_global(Vector3(6,2.8,3.2)),gate.to_global(Vector3(.8,.9,-.5)))
	FileAccess.open(out.path_join("support-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual saved main floor7, six source supports, deck contact, open logical gaps, four gravity-driven outcomes. Control methods invoked; prior real desktop/XR input tests retained."},"  "))
	print("MATTER_SUPPORTS_RESULT ",failed)
	game.queue_free();await frames(6);quit(0 if failed.is_empty() else 1)
