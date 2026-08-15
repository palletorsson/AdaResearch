extends SceneTree
## In-situ prop editing, tried: inside the museum, select a wall prop record,
## press UP twice, F5, and read prop_wall_rules.json back — the token's rule
## moved by +0.10 AND every other rule the corridor wrote is still there
## (a museum save MERGES, never rewrites). Then the corridor's own reader
## sees the new height. The rules file is backed up and restored.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_prop_insitu.gd

const EmProps := preload("res://commons/scenes/em/em_props.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var path := String(EmProps.RULES_PATH)
	var backup: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	# seed a known corridor rule so the MERGE claim is testable
	var seed: Dictionary = {"schema": "adaresearch.prop_wall_rules.v1",
		"rules": {"whiteboard": {"h": 1.11}}}
	var sf := FileAccess.open(path, FileAccess.WRITE)
	sf.store_string(JSON.stringify(seed, "\t"))
	sf.close()
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}

	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_edit_mode", true)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(5):
		await create_timer(0.2).timeout

	var records: Array = inst.get("_edit_records")
	var pi: int = -1
	for i in range(records.size()):
		if String((records[i] as Dictionary).get("kind", "")) == "prop":
			pi = i
			break
	if pi < 0:
		fails.append("no prop records in the museum — em_props dressed nothing rulable, or records not collected")
		_verdict(fails, backup, path)
		return
	var tok := String((records[pi] as Dictionary).get("token", ""))
	var node: Node3D = (records[pi] as Dictionary).get("node") as Node3D
	var h0: float = node.position.y
	inst.set("_edit_sel", pi)
	inst.call("_edit_handle_key", KEY_UP)
	inst.call("_edit_handle_key", KEY_UP)
	var h1: float = node.position.y
	if absf((h1 - h0) - 0.10) > 0.001:
		fails.append("two UPs moved %s by %.3f, expected +0.10" % [tok, h1 - h0])
	# LEFT is refused for a prop — the node must not move in x
	var x0: float = node.position.x
	inst.call("_edit_handle_key", KEY_LEFT)
	if absf(node.position.x - x0) > 0.001:
		fails.append("LEFT moved a wall prop — refusal did not hold")
	inst.call("_edit_handle_key", KEY_F5)

	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var rules: Dictionary = (doc as Dictionary).get("rules", {})
	if not rules.has(tok):
		fails.append("F5 wrote no rule for %s" % tok)
	elif absf(float((rules[tok] as Dictionary).get("h", -1)) - h1) > 0.002:
		fails.append("rule for %s says %.3f, live node at %.3f" % [tok, (rules[tok] as Dictionary).get("h", -1), h1])
	if not rules.has("whiteboard") or absf(float((rules["whiteboard"] as Dictionary).get("h", -1)) - 1.11) > 0.001:
		fails.append("the corridor's whiteboard rule was CLOBBERED by the museum save")
	# the shared reader sees it
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}
	if absf(EmProps._ruled_y(tok, 0.0) - h1) > 0.002:
		fails.append("em_props._ruled_y reads %.3f for %s after save, expected %.3f" % [EmProps._ruled_y(tok, 0.0), tok, h1])

	get_root().remove_child(inst)
	inst.queue_free()
	_verdict(fails, backup, path)


func _verdict(fails: Array[String], backup: String, path: String) -> void:
	if backup != "":
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}
	if fails.is_empty():
		print("PROP IN SITU: PASS — selected in the museum, ruled by UP, merged on F5, read back by em_props")
	else:
		print("PROP IN SITU: FAIL %d" % fails.size())
		for f2 in fails:
			print("  - " + f2)
	quit(0 if fails.is_empty() else 1)
