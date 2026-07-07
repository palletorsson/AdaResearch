## Standalone runner for tentacle_placer — instantiates the scene,
## turns on debug logging, lets it cycle for `--seconds=N` (default 60),
## then quits. Prints every phase transition + target updates so you
## can see what the state machine is actually doing.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/run_tentacle_standalone.gd -- \
##     --seconds=60 [--quiet-target=true]

extends SceneTree

var _seconds_to_run: float = 60.0
var _print_target_every: float = 0.5  # how often to log target.position
var _scene_path: String = "res://commons/artifacts/tentacle_placer/tentacle_placer.tscn"

func _initialize() -> void:
	for raw_arg in OS.get_cmdline_user_args():
		var arg := str(raw_arg).strip_edges()
		if arg.begins_with("--seconds="):
			_seconds_to_run = float(arg.split("=", true, 1)[1])
		elif arg.begins_with("--every="):
			_print_target_every = float(arg.split("=", true, 1)[1])
	_run.call_deferred()


func _run() -> void:
	print("[runner] loading scene %s" % _scene_path)
	var packed: PackedScene = load(_scene_path)
	if packed == null:
		push_error("Failed to load tentacle_placer.tscn")
		quit(1)
		return
	var inst: Node = packed.instantiate()
	if inst == null:
		push_error("Failed to instantiate tentacle_placer.tscn")
		quit(1)
		return
	# Force debug logging on so we see every transition.
	inst.set("debug_log", true)
	# Three-placement test that Primitives_Polythedra uses.
	inst.set("place_positions", PackedVector3Array([
		Vector3(-1.5, -0.5, 0),
		Vector3(0.0, -0.5, 0),
		Vector3(1.5, -0.5, 0),
	]))
	inst.set("sky_height", 7.0)
	inst.set("travel_speed", 1.5)  # faster for quick standalone test
	inst.set("dwell_seconds", 0.8)
	inst.set("arrive_threshold", 0.2)
	# Add some basic lighting + camera so the scene is renderable.
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.11, 0.14)
	environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	environment.ambient_light_energy = 0.8
	env.environment = environment
	root.add_child(env)
	var dl := DirectionalLight3D.new()
	dl.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
	root.add_child(dl)
	root.add_child(inst)
	print("[runner] tentacle_placer instantiated. running %.1fs..." % _seconds_to_run)

	var t: float = 0.0
	var next_print: float = 0.0
	while t < _seconds_to_run:
		await process_frame
		t += root.get_process_delta_time()
		if t >= next_print:
			var tgt: Marker3D = inst.get_node("Target") if inst.has_node("Target") else null
			var skel: Skeleton3D = inst.get_node("Armature/Skeleton3D") if inst.has_node("Armature/Skeleton3D") else null
			var goal_idx = inst.get("_goal_idx")
			var arrived = inst.get("_arrived")
			var done = inst.get("_cycle_done")
			var pool_size: int = (inst.get("_pyramid_pool") as Array).size()
			var tip_str: String = "(no skel)"
			var gap_str: String = ""
			if skel != null and tgt != null:
				skel.force_update_all_bone_transforms()
				var tip_t: Transform3D = skel.global_transform * skel.get_bone_global_pose(5)
				var tip_pos: Vector3 = tip_t.origin + (tip_t.basis * Vector3(0, 1, 0))
				var gap: float = tip_pos.distance_to(tgt.global_position)
				tip_str = str(tip_pos).pad_decimals(2)
				gap_str = " | gap=%5.2f" % gap
			print("[runner] t=%5.1fs | goal=%d arrived=%s done=%s pyramids=%d | tgt=%s | tip=%s%s"
				% [t, goal_idx, str(arrived), str(done), pool_size,
					str(tgt.position).pad_decimals(2) if tgt else "(null)",
					tip_str, gap_str])
			next_print = t + _print_target_every
	print("[runner] done.")
	quit(0)
