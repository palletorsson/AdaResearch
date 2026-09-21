extends SceneTree
## Run after guarded installation. Loads shipped scenes and drives their real
## sampling methods with the actual grab/tip nodes. It bypasses controller input;
## pickup ergonomics, VR legibility and room access still require a walk.

const OUTPUT := "res://ada_run/museum_iteration/evidence/snap_and_pen.json"
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func make_artifact(scene_path: String, at: Vector3 = Vector3.ZERO) -> Node3D:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		failures.append("Could not load " + scene_path)
		return null
	var artifact: Node3D = packed.instantiate() as Node3D
	artifact.position = at
	get_root().add_child(artifact)
	artifact.set_process(false)
	artifact.set("record_only_when_grabbed", false)
	artifact.set("data_table_update_interval", 0.0)
	return artifact


func drive(artifact: Node3D, target: Vector3, delta: float = 0.2) -> void:
	var handle: Node3D = artifact.get("_grab_point") as Node3D
	var tip: Node3D = artifact.get("_draw_sphere") as Node3D
	if handle == null or tip == null:
		failures.append("Missing grab/tip on " + artifact.name)
		return
	handle.global_position += target - tip.global_position
	artifact.call("_process", delta)


func points(artifact: Node3D) -> Array:
	return artifact.get("_trail_points") as Array


func label(artifact: Node3D) -> String:
	var readout: Label3D = artifact.get("_data_table_label") as Label3D
	return readout.text if readout != null else ""


func millimetres(text: String, prefix: String) -> float:
	# Accept the engine's legitimate 5/5.0 formatting while checking quantity
	# and unit, rather than teaching the probe one particular decimal spelling.
	var start: int = text.find(prefix)
	if start < 0:
		return INF
	var remaining: String = text.substr(start + prefix.length()).get_slice("\n", 0)
	var parts: PackedStringArray = remaining.split(" ")
	if parts.size() < 2 or parts[1].strip_edges() != "mm" or not parts[0].is_valid_float():
		return INF
	return parts[0].to_float()


func test_snap(room_id: String, height: float) -> void:
	var artifact: Node3D = make_artifact("res://commons/primitives/point/grab_sphere_point_snap.tscn", Vector3(0, height, 0))
	if artifact == null:
		return
	check(is_equal_approx(float(artifact.get("grid_size")), 0.05), room_id + ": shipped grid spacing is 0.05m")
	check(artifact.get_node("GrabPoint/DrawSphere").position.is_equal_approx(Vector3(0, 0, -0.12)), room_id + ": actual visible-tip offset is present")
	drive(artifact, Vector3(0.049, 0, 0))
	drive(artifact, Vector3(0.101, 0, 0))
	drive(artifact, Vector3(-0.101, 0, 0))
	var rows: String = label(artifact)
	check(rows.contains("Spacing: 0.05 m"), room_id + ": spacing is readable")
	check(rows.contains("RETAINED (m)") and rows.contains("LATTICE INDEX") and not rows.contains("raw"), room_id + ": table identifies stored quantities")
	check(rows.contains("(0.05,0.00,0.00) | (1,0,0)"), room_id + ": first positive lattice point is distinct")
	check(rows.contains("(0.10,0.00,0.00) | (2,0,0)"), room_id + ": adjacent lattice point is distinct")
	check(rows.contains("(-0.10,0.00,0.00) | (-2,0,0)"), room_id + ": negative signed lattice index is correct")
	var retained: int = points(artifact).size()
	artifact.call("_process", 1.0)
	check(points(artifact).size() == retained, room_id + ": a pause creates no sample")
	# The tip must land at its recorded coordinate even with a rotated artifact.
	artifact.rotation_degrees = Vector3(0, 37, 0)
	var handle: Node3D = artifact.get("_grab_point") as Node3D
	var tip: Node3D = artifact.get("_draw_sphere") as Node3D
	var local_tip: Vector3 = tip.position
	handle.global_position = Vector3(-0.133, height + 0.287, -0.183)
	var expected: Vector3 = artifact.call("snap_position_to_grid", tip.global_position)
	artifact.call("_on_grab_point_dropped", handle)
	check(tip.global_position.is_equal_approx(expected), room_id + ": released visible tip lands on lattice")
	check((points(artifact)[-1] as Vector3).is_equal_approx(expected), room_id + ": released tip equals last retained row")
	check(tip.position.is_equal_approx(local_tip), room_id + ": drop preserves local marker offset")
	artifact.set("record_only_when_grabbed", true)
	artifact.call("_process", 0.2)
	var released_readout: Label3D = artifact.get("_data_table_label") as Label3D
	check(released_readout != null and released_readout.visible, room_id + ": released table remains visible for observation")
	check(tip.global_position.is_equal_approx(expected), room_id + ": idle frame preserves released marker agreement")
	artifact.set("record_only_when_grabbed", false)
	observations.append({"room": room_id, "spacing_m": artifact.get("grid_size"), "table": label(artifact), "dropped_tip": str(tip.global_position)})
	# Precision adapts to smaller pitches; these are controlled probe settings.
	for pitch in [0.025, 0.005]:
		artifact.set("grid_size", pitch)
		artifact.set("min_segment_distance", pitch * 0.1)
		artifact.call("clear_trail")
		drive(artifact, Vector3(pitch * 1.1, 0, 0))
		drive(artifact, Vector3(pitch * 2.1, 0, 0))
		var digits: int = int(artifact.call("_grid_decimal_places"))
		check(digits >= 3, room_id + ": sub-centimetre spacing has sufficient decimals")
		check(label(artifact).contains("(1,0,0)") and label(artifact).contains("(2,0,0)"), room_id + ": changed spacing retains adjacent distinct indices")
	artifact.set("trail_max_points", 2)
	for step in range(3):
		handle.global_position += Vector3(0.053, 0, 0)
		artifact.call("_on_grab_point_dropped", handle)
	check(points(artifact).size() == 2 and label(artifact).contains("Retained: 2 / 2"), room_id + ": dropping also respects retained capacity")
	artifact.queue_free()


func test_pen(scene_name: String) -> void:
	var artifact: Node3D = make_artifact("res://commons/primitives/point/" + scene_name + ".tscn")
	if artifact == null:
		return
	check(int(artifact.get("trail_max_points")) == 4096, scene_name + ": scene capacity is 4096")
	check(is_equal_approx(float(artifact.get("min_segment_distance")), 0.005), scene_name + ": scene movement threshold is 5mm")
	check(is_zero_approx(float(artifact.get("resolution_mm"))), scene_name + ": scene grid resolution defaults off")
	var tip: Node3D = artifact.get("_draw_sphere") as Node3D
	var handle: Node3D = artifact.get("_grab_point") as Node3D
	handle.global_position -= tip.global_position
	artifact.call("clear_trail")
	drive(artifact, Vector3(0.002, 0, 0))
	check(points(artifact).is_empty(), scene_name + ": sub-threshold movement is not retained")
	drive(artifact, Vector3(0.006, 0, 0))
	check(points(artifact).size() == 1, scene_name + ": sufficient movement records one sample")
	artifact.call("_process", 5.0)
	check(points(artifact).size() == 1, scene_name + ": five-second pause retains existing record without adding positions")
	check(label(artifact).contains("Retained: 1 / 4096") and is_equal_approx(millimetres(label(artifact), "Move: >= "), 5.0) and label(artifact).contains("Grid: off"), scene_name + ": label exposes the actual defaults")
	artifact.call("apply_grid_config", {"grain": "coarse"})
	drive(artifact, Vector3(0.020, 0, 0))
	check(points(artifact).size() == 1, scene_name + ": coarse grain rejects movement below 30mm")
	drive(artifact, Vector3(0.045, 0, 0))
	check(points(artifact).size() == 2, scene_name + ": coarse grain accepts movement beyond 30mm")
	check(is_equal_approx(millimetres(label(artifact), "Move: >= "), 30.0), scene_name + ": label follows effective grain")
	artifact.call("apply_grid_config", {"grain": "0.001", "resolution": "40"})
	artifact.call("clear_trail")
	drive(artifact, Vector3(0.082, 0, 0))
	drive(artifact, Vector3(0.089, 0, 0))
	check(points(artifact).size() == 1, scene_name + ": distinct raw samples in one lattice cell are deduplicated")
	drive(artifact, Vector3(0.121, 0, 0))
	check(points(artifact).size() == 2, scene_name + ": entering another lattice cell records another position")
	check(is_equal_approx(millimetres(label(artifact), "Grid: "), 40.0), scene_name + ": effective resolution is visible")
	artifact.set("trail_max_points", 3)
	for step in range(1, 8):
		drive(artifact, Vector3(0.16 + float(step) * 0.041, 0, 0))
	check(points(artifact).size() == 3, scene_name + ": a low-capacity probe keeps only the newest three samples")
	check(label(artifact).contains("Retained: 3 / 3") and not label(artifact).contains("4 / 3"), scene_name + ": count is refreshed after eviction")
	observations.append({"scene": scene_name, "table": label(artifact), "retained": points(artifact).size()})
	artifact.queue_free()


func test_time_domain_exception() -> void:
	var artifact: Node3D = make_artifact("res://commons/primitives/point/draw_dot_time_domain.tscn")
	if artifact == null:
		return
	check(is_equal_approx(float(artifact.get("sample_interval")), 0.05), "time recorder: scene sample gate is 0.05s")
	check(is_equal_approx(float(artifact.get("fade_duration")), 20.0), "time recorder: scene fade window is 20s")
	artifact.call("_process", 0.025)
	check(points(artifact).is_empty(), "time recorder: closed sample gate adds no point")
	artifact.call("_process", 0.025)
	check(points(artifact).size() == 1, "time recorder: stationary tip is sampled when clock opens")
	for step in range(18):
		artifact.call("_process", 0.025)
	check(points(artifact).size() == 10, "time recorder: stationary half-second yields ten timer samples")
	var retained: Array = points(artifact)
	check((retained[0] as Vector3).z > (retained[-1] as Vector3).z, "time recorder: older samples recede along Z")
	var text: String = label(artifact)
	check(text.contains("Sample gate:") and text.contains("Z drift:") and text.contains("Fade:"), "time recorder: label names its timer and time axis")
	check(not text.contains("Move:") and not text.contains("Grid:"), "time recorder: does not inherit a false movement/grid contract")
	artifact.set("trail_max_points", 3)
	artifact.call("_process", 0.05)
	check(points(artifact).size() == 3 and label(artifact).contains("Retained: 3 / 3"), "time recorder: table counts after capacity eviction")
	artifact.set("fade_duration", 0.06)
	artifact.call("_process", 0.05)
	artifact.call("_process", 0.05)
	check(points(artifact).size() <= 2, "time recorder: configured fade removes old timer samples")
	observations.append({"scene": "draw_dot_time_domain", "table": label(artifact), "retained": points(artifact).size(), "contract_exception": "timer sampling including stationary positions"})
	artifact.queue_free()


func _run() -> void:
	test_snap("Point_One", 0.0)
	test_snap("Point_Line_Grid", 0.7)
	test_pen("draw_dot")
	test_pen("draw_stick")
	test_time_domain_exception()
	await process_frame
	var result: Dictionary = {"ok": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations,
		"scope": "Actual scene scripts with manually moved grab nodes; controller ergonomics, room reachability and VR legibility remain unverified."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	print("MUSEUM_SNAP_PEN_PROBE " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
