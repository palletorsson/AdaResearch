extends SceneTree
## ca_rule_explorer as CA_Introduction places it (#study:neighbours #rule:90), stepped headless:
## the live cells of each generation and whether the history is Pascal's triangle mod 2, written to
## ada_run/ca_ring/<label>.json. Args: <label> [rule] [seed: single|pair]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var label: String = args[0] if args.size() > 0 else "now"
	var rule: int = int(args[1]) if args.size() > 1 else 90
	var explorer: Node3D = load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.tscn").instantiate()
	explorer.set_meta("config_study", "neighbours")
	explorer.set_meta("config_rule", rule)
	root.add_child(explorer)
	for i in 3:
		await process_frame
	if args.size() > 2 and args[2] == "pair":
		explorer.call("toggle_seed")
	var width: int = explorer.get("cells_x")
	var alive: Array = []
	var rows: Array = []
	var row0: Array = explorer.get("_current_row")
	rows.append(row0.map(func(b): return 1 if b else 0))
	for g in 40:
		explorer.call("step")
		var r: Array = explorer.get("_current_row")
		rows.append(r.map(func(b): return 1 if b else 0))
	for r in rows:
		alive.append((r as Array).count(1))
	var out := {"label": label, "rule": rule, "width": width, "auto_run": explorer.get("auto_run"), "alive": alive, "rows": rows}
	var dir := ProjectSettings.globalize_path("res://ada_run/ca_ring")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("%s.json" % label), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)
