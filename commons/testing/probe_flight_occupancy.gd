extends SceneTree
## array_flight_lab (Tutorial_3D): its lattice's children and its values table, at default and
## (after the change) under config_occupancy, written to ada_run/array_occupancy/flight_<label>.json.
##   godot --headless --script res://commons/testing/probe_flight_occupancy.gd -- <label> [rule]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var label: String = args[0] if args.size() > 0 else "now"
	var lab: Node3D = load("res://commons/artifacts/regularity/array_flight_lab.tscn").instantiate()
	if args.size() > 1:
		lab.set_meta("config_occupancy", args[1])
	root.add_child(lab)
	for i in 6:
		await process_frame
	var grid: Node3D = lab.get("grid")
	var children: Array = []
	for c in grid.get_children():
		children.append([str(c.name), snappedf(c.position.x, 0.0001), snappedf(c.position.y, 0.0001), snappedf(c.position.z, 0.0001)])
	var out := {"label": label, "children": children, "values": (lab.get("values") as Array).duplicate(true),
		"readout": (lab.get("readout") as Label).text if lab.get("readout") != null else ""}
	var dir := ProjectSettings.globalize_path("res://ada_run/array_occupancy")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("flight_%s.json" % label), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)
