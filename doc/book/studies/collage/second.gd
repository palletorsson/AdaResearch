extends SceneTree
## Measures one second at a frame rate of your choice. From this folder:
##   godot --headless --path . --xr-mode off --fixed-fps 30 --script res://second.gd
## --fixed-fps makes a frame last 1/30 s of the study's own time, however long the
## computer takes over it. The first frames of a run are uneven all the same (a
## run at 30 began 0.025, 0.033, 0.042, 0.029, 0.030, 0.033 s), so the script
## waits 60 frames before it measures. Then it runs the limb for one second,
## twice: once from organism_frames.gd, where the angle grows by 0.01 a frame, and
## once from organism.gd, where it grows by speed * delta. It prints both angles
## and where the toe ended, and keeps them in second.json under the frame rate,
## beside the rates measured before.

const TOE := "Organism/Hip/Upper/Lower/Foot/Toe"

func _initialize() -> void: run.call_deferred()

## One study, run until one second of its own time has passed.
func one_second(script_path: String) -> Dictionary:
	var study: Node3D = load("res://organism.tscn").instantiate()
	var organism: Node3D = study.get_node("Organism")
	if organism.get_script().resource_path != script_path:
		organism.set_script(load(script_path))
	await process_frame
	root.add_child(study)   # the study's first frame is this one
	var frames := 0
	var seconds := 0.0
	while seconds < 0.9999:
		await process_frame
		frames += 1
		seconds += root.get_process_delta_time()
	var toe: Vector3 = study.get_node(TOE).global_position
	var result := {
		"frames": frames, "seconds": snappedf(seconds, 0.0001), "angle_rad": snappedf(organism.angle, 0.0001),
		"angle_deg": snappedf(rad_to_deg(organism.angle), 0.01),
		"toe": [snappedf(toe.x, 0.001), snappedf(toe.y, 0.001), snappedf(toe.z, 0.001)],
	}
	study.free()
	return result

func run() -> void:
	for i in 60:
		await process_frame
	var per_frame := await one_second("res://organism_frames.gd")
	var per_second := await one_second("res://organism.gd")
	var rate := str(per_frame["frames"])
	print("%s frames in one second" % rate)
	print("  angle += 0.01          -> %.4f rad (%.2f degrees), toe at %s" % [per_frame["angle_rad"], per_frame["angle_deg"], per_frame["toe"]])
	print("  angle += speed * delta -> %.4f rad (%.2f degrees), toe at %s" % [per_second["angle_rad"], per_second["angle_deg"], per_second["toe"]])
	var record := {}
	if FileAccess.file_exists("res://second.json"):
		record = JSON.parse_string(FileAccess.get_file_as_string("res://second.json"))
	record[rate] = {"per_frame": per_frame, "per_second": per_second}
	FileAccess.open("res://second.json", FileAccess.WRITE).store_string(JSON.stringify(record, "  "))
	quit(0)
