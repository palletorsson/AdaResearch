extends "res://tools/probes/logic_sequence.gd"
## Real gate physics with object touch and the lift-stop's pointer drag.
## Pointer events are diagnostic delivery; hand contact uses a physics collider.
func tap_cube(work: Node3D,index: int) -> void:
	var sensor: Area3D=work.cubes[index].get_node("TouchInput")
	var at := sensor.global_position
	sensor.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,sensor,at,at))
	await frames(3)
func lift_stop(work: Node3D) -> void:
	var handle: Node3D=work.launcher.handle
	var at := handle.global_position
	for kind in [XRToolsPointerEvent.Type.PRESSED,XRToolsPointerEvent.Type.MOVED,XRToolsPointerEvent.Type.RELEASED]:
		var to: Vector3 = at+work.launcher.global_basis.y*.15 if kind!=XRToolsPointerEvent.Type.PRESSED else at
		handle.pointer_event(XRToolsPointerEvent.new(kind,pointer,handle,to,to))
		await frames(2)
func case_object(work: Node3D,bits: String) -> void:
	work.reset_gate();await frames(30)
	for i in bits.length():
		if bits[i]=="1":await tap_cube(work,i)
	check(work.operator+" / object touches select "+bits,str(work.inputs.x)+(str(work.inputs.y) if bits.length()>1 else "")==bits)
	await frames(45);await lift_stop(work)
	check(work.operator+" / drag stop starts observation",work.launcher.active)
	for i in 1200:
		if work.outcome!=-1:break
		await frames(1)
	check(work.operator+" / physical truth "+bits,work.outcome==work.required_observations[bits])
func reset_clock_checks() -> void:
	var ball := RigidBody3D.new();ball.gravity_scale=0;game.add_child(ball)
	var timer = load("res://commons/interactables/settled_ball_reset.gd").new()
	var restored := [0]
	timer.balls=func():return [ball]
	timer.take_started=func():return true
	timer.restore=func():restored[0]+=1
	game.add_child(timer);timer.set_physics_process(false)
	timer._physics_process(9.9);await frames(1)
	check("rest reset waits the full ten seconds",restored[0]==0 and timer.resting_seconds>9.8)
	ball.linear_velocity=Vector3(1,0,0);timer._physics_process(.2)
	check("renewed ball motion restarts the countdown",timer.resting_seconds==0 and restored[0]==0)
	ball.linear_velocity=Vector3.ZERO
	timer._physics_process(10);await frames(2)
	check("ten rested seconds restore one take",restored[0]==1 and timer.resting_seconds==0)
	timer.interaction_busy=func():return true
	timer._physics_process(12);await frames(2)
	check("held controls prevent automatic reset",restored[0]==1)
	timer.queue_free();ball.queue_free()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_logic_photos=true
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1440,900)
	OS.set_environment("VOID_INVENTORY_PATH",out.path_join("object-controls-inventory-"+str(Time.get_ticks_usec())+".json"))
	for use_xr in [false,true]:
		await start(use_xr)
		for i in [21,22]:
			await visit_logic_floor(i)
			for a in game.building.content.data.floors[i].artifacts:
				if not str(a.artifact).begins_with("matter_spring_"):continue
				var work: Node3D=station(a.id)
				var tag: String = ("XR / " if xr else "Desktop / ")+work.operator
				check(tag+" / no push buttons or button console",work.buttons.is_empty() and not work.has_node("Controls/SteelControlNamePlate"))
				check(tag+" / editable object members retained",work.part_defaults.has("Controls") and work.part_defaults.has("InputX") and work.part_defaults.has("SpringLauncher"))
				check(tag+" / automatic rest reset is ten seconds",is_equal_approx(work.rest_reset.wait_seconds,10))
				# Keep automatic reset out of the truth-case observation window.
				work.rest_reset.set_physics_process(false)
				if not xr:
					for bits in work.required_observations:await case_object(work,str(bits))
					check(tag+" / original inventory recipe still earned",game.prefab_inventory.unlocked(a.artifact))
				work.reset_gate();await frames(30)
				var hand := StaticBody3D.new();hand.collision_layer=1<<17;hand.collision_mask=0
				var hit := CollisionShape3D.new();hit.shape=SphereShape3D.new();hit.shape.radius=.035;hand.add_child(hit)
				game.add_child(hand);hand.global_position=work.cubes[0].global_position
				await frames(4)
				check(tag+" / hand-layer contact changes actual cube state",work.inputs.x==1 and not work.cubes[0].freeze)
				hand.queue_free();await frames(3)
				work.reset_gate()
			if take_logic_photos and not xr:
				var work: Node3D=station(game.building.content.data.floors[i].artifacts[0].id)
				var cam := Camera3D.new();cam.fov=55;game.add_child(cam)
				cam.global_position=work.to_global(Vector3(2.7,2.2,4.8));cam.look_at(work.to_global(Vector3(0,1.2,0)));cam.make_current()
				var shown: Array[int]=[i];game.building.show_floor_window(shown)
				await frames(3);await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(out.path_join("objects-"+str(i)+".png"))
				cam.queue_free();game.camera.make_current()
		if not xr:await reset_clock_checks()
		game.queue_free();await frames(12)
		if xr:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Desktop/synthetic XR loading; explicit pointer drag/touch events, real hand-layer collision and Jolt truth cases; timer boundary checks. Not physical-headset acceptance."}
	FileAccess.open(out.path_join("object-controls-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
