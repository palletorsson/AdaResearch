extends SceneTree
## Planned series: three terrain seeds, three sphere radii, two repeatability runs.
## Physics and meshes come from the verified artifact unchanged.
const OUT := "res://ada_run/landscape-size-series/"
const SEEDS := [1729,1730,1731]
var trials:Array = []
var failures:Array[String] = []
var hashes:Dictionary = {}
func _initialize() -> void:run.call_deferred()
func require(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error("SERIES "+message)
func save_progress(status:String) -> void:
	var f=FileAccess.open(OUT+"results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"status":status,"planned_trials":18,"completed_trials":trials.size(),"failures":failures,"source_sha256":hashes,"engine":Engine.get_version_info(),"physics_hz":Engine.physics_ticks_per_second,"time_scale":Engine.time_scale,"physics_engine":ProjectSettings.get_setting("physics/3d/physics_engine","DEFAULT"),"trials":trials},"  "));f.close()
func vec(v:Vector3) -> Array:return [v.x,v.y,v.z]
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for p in ["commons/artifacts/landscape_flow_bench/landscape_flow_bench.gd","commons/artifacts/landscape_flow_bench/landscape_flow_bench.tscn","commons/artifacts/timing_machines/machine_stage.gd","commons/testing/landscape_flow_workshop.gd","commons/testing/landscape_flow_workshop.tscn","commons/testing/run_landscape_size_series.gd","project.godot"]:
		hashes[p]=FileAccess.get_sha256("res://"+p)
	require(is_equal_approx(Engine.time_scale,1.0),"series requires unscaled simulation time")
	require(Engine.physics_ticks_per_second==60,"series requires 60 physics ticks/s")
	if not failures.is_empty():save_progress("failed");quit(1);return
	var scene=load("res://commons/testing/landscape_flow_workshop.tscn").instantiate();root.add_child(scene);current_scene=scene
	await create_timer(0.5).timeout
	var bench=scene.get_node("LandscapeFlowBench");var cam=scene.cam
	# Inspection camera remains fixed so pictures can be compared directly.
	cam.position=Vector3(4.0,6.0,9.2);cam.look_at(Vector3(0,1.0,0));scene.set_process(false)
	var trial_no=0
	for seed_index in SEEDS.size():
		var field_seed=SEEDS[seed_index]
		for repeat_index in 2:
			# Rotate radius order within seed blocks; order is recorded, not treated as randomness.
			for offset in 3:
				var ri=(offset+seed_index+repeat_index)%3
				bench.seed_value=field_seed;bench.amp_index=1;bench.angle_index=1;bench.window_index=1;bench.radius_index=ri
				bench.rebuild();bench.reveal=false;bench.refresh()
				await physics_frame;await physics_frame;await process_frame
				var samples=[]
				for field in bench.surfaces:samples.append(Array(field))
				bench.release();trial_no+=1
				var trial={"trial":trial_no,"seed":field_seed,"repeat":repeat_index+1,"radius_index":ri,"radius_m":bench.RADII[ri],"initial_positions":[],"samples":samples,"timeline":[],"exit_observations":[]}
				for b in bench.bodies:trial.initial_positions.append(vec(b.position))
				var previous_states=bench.states.duplicate();var last_sample=-1
				print("SERIES START ",trial_no,"/18 seed ",field_seed," radius ",bench.RADII[ri]," repeat ",repeat_index+1)
				while bench.running:
					await physics_frame
					for i in bench.states.size():
						if bench.states[i]!=previous_states[i]:
							trial.exit_observations.append({"body":i,"tray":i/32,"slot":i%32,"observed_at_tick":bench.ticks,"outcome":bench.states[i]});previous_states[i]=bench.states[i]
					if bench.ticks%60==0 and bench.ticks!=last_sample:
						trial.timeline.append(bench.snapshot());last_sample=bench.ticks
				trial["result"]=bench.snapshot();trial["states"]=bench.states.duplicate();trial["final_positions"]=[]
				await physics_frame;await process_frame
				for b in bench.bodies:trial.final_positions.append(vec(b.position))
				require(bench.ticks==720,"trial %d ended at expected deadline"%trial_no)
				require(bench.bodies.size()==128,"trial %d kept complete batch"%trial_no)
				for mode in 4:
					var c=bench.counts(mode);require(c[0]+c[1]+c[2]==32,"trial %d accounts for tray %d"%[trial_no,mode])
				# Preselected figures: first repeat at seed 1729, all three radii.
				if seed_index==0 and repeat_index==0:
					var path="seed-1729-radius-%d.png"%roundi(bench.RADII[ri]*1000)
					await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+path);trial["capture"]=path
				trials.append(trial);save_progress("running")
				print("SERIES END ",trial_no," ",JSON.stringify(trial.result.counts))
	for p in hashes:require(hashes[p]==FileAccess.get_sha256("res://"+p),"source stayed fixed: "+p)
	save_progress("complete" if failures.is_empty() else "failed")
	print("SERIES COMPLETE ",trials.size()," failures ",failures.size());quit(0 if failures.is_empty() else 1)
