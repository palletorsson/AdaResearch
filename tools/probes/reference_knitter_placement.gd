extends "res://tools/probes/void_transfer_probe.gd"
## Diagnose the real gravity route against the trial slabs, not an empty world.
func run() -> void:
	trial = "matter_logic_reference"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	level = 1;await start(false);level = 33;game.place_player(game.spawn_for(level));await frames(30)
	var work: Node3D = station("source_gravity_knitter");var console: Node3D = work.get_node("Controls");var foot: Vector3 = console.to_global(Vector3(0,0,1.65));foot.y = game.building.spec.levels[level]+.06;game.place_player(foot);await frames(15)
	await press(work.buttons.STEP.get_node("PushButton"))
	var trace: Array = []
	for frame in range(1100):
		if frame%30==0 and is_instance_valid(work.ball):
			var at: Vector3 = work.ball.global_position;var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.4,1);ray.exclude = [work.ball.get_rid()];var hit := work.get_world_3d().direct_space_state.intersect_ray(ray)
			trace.append({"seconds":work.phase_time,"local":work.arr(work.to_local(at)),"world":work.arr(at),"below":str(hit.collider.get_path()) if not hit.is_empty() else "none"})
		if work.stitched>0 or work.jams>0:break
		await frames(1)
	check("actual-floor first marble reaches a trough",work.stitched==1 and work.errors==0 and work.jams==0)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"stitched":work.stitched,"jams":work.jams,"errors":work.errors,"trace":trace,"origin":work.arr(work.global_position)}
	FileAccess.open(out.path_join("knitter-placement-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));game.queue_free();await frames(12);print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
