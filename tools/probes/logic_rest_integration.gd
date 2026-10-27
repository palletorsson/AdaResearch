extends "res://tools/probes/logic_object_controls.gd"
## Let a real AND ball stop naturally, then observe the production reset.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	OS.set_environment("VOID_INVENTORY_PATH",out.path_join("rest-integration-inventory.json"))
	await start(false);await visit_logic_floor(21)
	var work: Node3D=station("logic-and")
	await tap_cube(work,0);await tap_cube(work,1);await frames(45);await lift_stop(work)
	var saw_wait := false
	var peak_wait := 0.0
	for i in 3600:
		if work.rest_reset.resting_seconds>0:saw_wait=true
		peak_wait=maxf(peak_wait,work.rest_reset.resting_seconds)
		if not work.launcher.active:break
		await frames(1)
	check("real test ball reaches a rested state",saw_wait)
	check("production countdown waits about ten rested seconds",peak_wait>=9.9)
	check("production reset restores launch, input cubes and target",not work.launcher.active and work.outcome==-1 and work.inputs==Vector2i.ZERO and work.target.transform.is_equal_approx(work.target_rest))
	check("automatic reset retains observed lesson evidence",work.observations.get("11",-1)==1)
	var ball_state: Array = []
	for ball in work.launcher.balls:ball_state.append({"position":ball.global_position,"linear":ball.linear_velocity,"angular":ball.angular_velocity,"sleeping":ball.sleeping})
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"peak_rest_wait":peak_wait,"observations":work.observations,"balls":ball_state,"scope":"One real Jolt AND run, natural ball rest and production ten-second automatic reset. No imposed ball velocity or physical-headset claim."}
	FileAccess.open(out.path_join("rest-integration.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
