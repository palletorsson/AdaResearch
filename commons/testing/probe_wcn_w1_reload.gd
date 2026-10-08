extends SceneTree
## W1 reload / unload / nearby-instance probe (doc/research/waves-chance-noise, 2026-09-10).
## Astra's step 3: "Check reset/reload/unload and two nearby instances." The museum
## probes stand one hall; this one instantiates the two changed artifact scenes twice
## each, three metres apart, under a bare root: are the two records and the two
## passages independent, does freeing one leave the other running, and does a freed
## instance take everything it built with it (no orphan panels, readouts or marks)?
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_w1_reload.gd
##
## Writes res://ada_run/waves_chance_noise/probe_w1_reload.json. Exit 1 on any failure.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const OUT := "res://ada_run/waves_chance_noise/probe_w1_reload.json"

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-reload] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var stage := Node3D.new(); stage.name = "Stage"
	root.add_child(stage); current_scene = stage
	var baseline_children: int = root.get_child_count()

	# ── A. two pendulums, three metres apart ──────────────────────────────────
	var ps: PackedScene = load("res://algorithms/wavefunctions/oscillation_driver/PendulumWave.tscn")
	var pa: Node3D = ps.instantiate(); pa.name = "PendA"; pa.position = Vector3(0, 0, 0)
	var pb: Node3D = ps.instantiate(); pb.name = "PendB"; pb.position = Vector3(3, 0, 0)
	stage.add_child(pa); stage.add_child(pb)
	await create_timer(2.0).timeout
	check(pa.get_node_or_null("Camera3D") == null and pa.get_node_or_null("WorldEnvironment") == null and pa.get_node_or_null("DirectionalLight3D") == null,
		"an embedded pendulum frees its standalone camera, environment and sun")
	var na: int = int(pa.call("sample_count")); var nb: int = int(pb.call("sample_count"))
	check(na > 60 and nb > 60, "both records fill (%d, %d)" % [na, nb])
	pb.call("set_sampler", "coarse")
	await create_timer(1.0).timeout
	check(str(pa.get("sampler")) == "fine" and str(pb.get("sampler")) == "coarse", "a sampler switch on one does not reach the other")
	# ~40 marks/s (alternating one- and two-tick gaps at 60 Hz) over ~3 s of timers: 115-125
	check(int(pa.call("sample_count")) >= 112, "the untouched record kept filling (%d)" % int(pa.call("sample_count")))
	pa.call("reset_experiment")
	await physics_frame
	check(int(pa.call("sample_count")) <= 1 and int(pb.call("sample_count")) > 3, "RESET on one empties one record only (%d, %d)" % [int(pa.call("sample_count")), int(pb.call("sample_count"))])
	check(absf(float(pa.call("experiment_time"))) < 0.05 and float(pb.call("experiment_time")) > 2.5, "and zeroes one clock only (%.2f, %.2f)" % [float(pa.call("experiment_time")), float(pb.call("experiment_time"))])
	# unload one, the other continues
	var marks_b: MultiMeshInstance3D = pb.get_node_or_null("Marks")
	var mm_b: MultiMesh = marks_b.multimesh if marks_b != null else null
	pa.queue_free()
	await process_frame; await process_frame
	check(not is_instance_valid(pa), "a freed pendulum is gone")
	var t1: float = float(pb.call("experiment_time"))
	await create_timer(0.5).timeout
	check(float(pb.call("experiment_time")) > t1 + 0.4, "the remaining pendulum keeps its clock running")
	check(mm_b != null and mm_b.visible_instance_count == int(pb.call("sample_count")), "its marks match its count (%d)" % int(pb.call("sample_count")))
	# reload: a fresh instance in the same place starts from its own zero
	var pc: Node3D = ps.instantiate(); pc.name = "PendC"; pc.position = Vector3(0, 0, 0)
	stage.add_child(pc)
	await physics_frame; await physics_frame
	check(float(pc.call("experiment_time")) < 0.1 and int(pc.call("sample_count")) <= 2, "a reloaded pendulum starts from zero, unaffected by the one that stood there")
	check(str(pc.get("sampler")) == "fine", "with the default sampler")
	pb.queue_free(); pc.queue_free()
	await process_frame; await process_frame
	check(stage.get_child_count() == 0, "freeing both leaves nothing under the stage (%d children)" % stage.get_child_count())

	# ── B. two corridors, side by side ────────────────────────────────────────
	var cs: PackedScene = load("res://algorithms/wavefunctions/sine_wall/sine_wall_corridor.tscn")
	var ca: Node3D = cs.instantiate(); ca.name = "CorA"; ca.position = Vector3(0, 2, 0)
	var cb: Node3D = cs.instantiate(); cb.name = "CorB"; cb.position = Vector3(4, 2, 0)
	stage.add_child(ca); stage.add_child(cb)
	await process_frame; await process_frame
	check(ca.get_node_or_null("Camera3D") == null and ca.get_node_or_null("WorldEnvironment") == null and ca.get_node_or_null("DirectionalLight3D") == null and ca.get_node_or_null("FillLight") != null,
		"an embedded corridor frees camera, environment and sun and keeps its fill light")
	check(ca.get_node_or_null("Panel") != null and cb.get_node_or_null("Panel") != null and ca.get_node_or_null("Readout") != null, "both corridors build their own panel and readout")
	var la: MeshInstance3D = ca.get_node_or_null("LeftWall"); var lb: MeshInstance3D = cb.get_node_or_null("LeftWall")
	check(la != null and lb != null and la.mesh != lb.mesh, "the two corridors do not share a wall mesh")
	check(la != null and lb != null and la.material_override != null and la.material_override != lb.material_override, "nor a wall material")
	ca.call("set_phase_offset", PI)
	await process_frame
	check(absf(float((ca.call("contract") as Dictionary).phase_offset) - PI) < 0.001 and absf(float((cb.call("contract") as Dictionary).phase_offset) - 0.6) < 0.001,
		"a PHASE change on one leaves the other's offset alone")
	ca.call("toggle_animation")
	var pb0: float = float((cb.call("contract") as Dictionary).phase)
	for i in range(15): await process_frame
	check(not bool(ca.call("is_animating")) and bool(cb.call("is_animating")) and float((cb.call("contract") as Dictionary).phase) > pb0,
		"FREEZE on one stops one; the other keeps running")
	ca.call("reset_declared")
	await process_frame
	check(bool(ca.call("is_animating")) and absf(float((ca.call("contract") as Dictionary).phase_offset) - 0.6) < 0.001, "RESET returns one corridor to its declared values")
	# unload one; the other keeps its panel and its motion
	ca.queue_free()
	await process_frame; await process_frame
	check(not is_instance_valid(ca) and cb.get_node_or_null("Panel") != null, "freeing one corridor leaves the other's panel standing")
	var pb1: float = float((cb.call("contract") as Dictionary).phase)
	for i in range(10): await process_frame
	check(float((cb.call("contract") as Dictionary).phase) > pb1, "and the other keeps animating")
	# reload in place
	var cc: Node3D = cs.instantiate(); cc.name = "CorC"; cc.position = Vector3(0, 2, 0)
	stage.add_child(cc)
	await process_frame; await process_frame
	var ccc: Dictionary = cc.call("contract")
	check(absf(float(ccc.amplitude) - 0.2) < 0.001 and absf(float(ccc.phase_offset) - 0.6) < 0.001 and absf(float(ccc.phase)) < 0.05, "a reloaded corridor starts from its declared values and phase near zero")
	cb.queue_free(); cc.queue_free()
	await process_frame; await process_frame
	check(stage.get_child_count() == 0, "freeing both corridors leaves nothing under the stage (%d children)" % stage.get_child_count())
	check(root.get_child_count() == baseline_children, "no orphan nodes were parented to the root (%d vs %d)" % [root.get_child_count(), baseline_children])
	measurements["orphans"] = root.get_child_count() - baseline_children
	_finish()

func _finish() -> void:
	var report := {"checks": checks, "failures": failures, "measurements": measurements,
		"scope": "artifact scenes under a bare root, not the museum hall; two instances 3-4 m apart; unload/reload of one",
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-reload] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
