extends SceneTree
## The reference wall, tried end to end: every default token hangs, a nudge
## saved through the scene's own _save() lands in the rules file, em_props
## reads the hand height back, and deleting the file restores the code
## convention — the gate, both ways. Any pre-existing rules file is backed
## up and restored, so the trial leaves the working tree as it found it.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_prop_wall_rules.gd

const EmProps := preload("res://commons/scenes/em/em_props.gd")
const EmPlinths := preload("res://commons/scenes/em/em_plinths.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var backup: String = ""
	if FileAccess.file_exists(EmProps.RULES_PATH):
		backup = FileAccess.get_file_as_string(EmProps.RULES_PATH)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(EmProps.RULES_PATH))
	var band_backup: String = ""
	if FileAccess.file_exists(EmPlinths.STANDING_RULES):
		band_backup = FileAccess.get_file_as_string(EmPlinths.STANDING_RULES)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(EmPlinths.STANDING_RULES))
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}
	EmPlinths._band_loaded = false
	EmPlinths._band_hand = {}

	var ps: PackedScene = load("res://commons/scenes/prop_reference_wall.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	get_root().add_child(inst)
	for i in range(3):
		await create_timer(0.2).timeout

	var records: Array = inst.get("_records")
	var want: int = EmProps.mount_defaults().size() + 5  # + the band handles
	if records.size() != want:
		fails.append("wall hangs %d records, expected %d (props + 5 band handles)" % [records.size(), want])

	# the hand: raise wall_clock to 1.90 and save through the scene's own code
	var clock_i: int = -1
	for i in range(records.size()):
		if String((records[i] as Dictionary).get("token", "")) == "wall_clock":
			clock_i = i
			break
	if clock_i < 0:
		fails.append("no wall_clock on the reference wall")
	else:
		((records[clock_i] as Dictionary)["node"] as Node3D).position.y = 1.90
		inst.set("_dirty", true)
		inst.call("_save")
		if not FileAccess.file_exists(EmProps.RULES_PATH):
			fails.append("_save wrote nothing")
		else:
			EmProps._hand_loaded = false
			EmProps._hand_rules = {}
			var got: float = EmProps._ruled_y("wall_clock", 2.25)
			if absf(got - 1.90) > 0.001:
				fails.append("em_props reads %.3f for wall_clock, hand said 1.90" % got)
			var other: float = EmProps._ruled_y("whiteboard", 1.30)
			if absf(other - 1.30) > 0.001:
				fails.append("whiteboard moved to %.3f without a rule" % other)

	# ── the band: raise target_centre to 1.25 and save through the scene ─────
	var tc_i: int = -1
	for i in range(records.size()):
		if String((records[i] as Dictionary).get("key", "")) == "target_centre":
			tc_i = i
			break
	if tc_i < 0:
		fails.append("no target_centre handle on the wall")
	else:
		((records[tc_i] as Dictionary)["node"] as Node3D).position.y = 1.25
		inst.set("_dirty", true)
		inst.call("_save")
		EmPlinths._band_loaded = false
		EmPlinths._band_hand = {}
		var got_tc: float = EmPlinths.band("target_centre", 1.15)
		if absf(got_tc - 1.25) > 0.001:
			fails.append("em_plinths reads target_centre %.3f, hand said 1.25" % got_tc)
		if absf(EmPlinths.band("min_lift", 0.25) - 0.25) > 0.001:
			fails.append("min_lift moved without a rule")

	# the gate: no files -> code conventions, exactly
	if FileAccess.file_exists(EmProps.RULES_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(EmProps.RULES_PATH))
	if FileAccess.file_exists(EmPlinths.STANDING_RULES):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(EmPlinths.STANDING_RULES))
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}
	EmPlinths._band_loaded = false
	EmPlinths._band_hand = {}
	if absf(EmProps._ruled_y("wall_clock", 2.25) - 2.25) > 0.001:
		fails.append("rules file deleted but wall_clock did not return to code height")
	if absf(EmPlinths.band("target_centre", 1.15) - 1.15) > 0.001:
		fails.append("standing rules deleted but target_centre did not return to code")

	if backup != "":
		var f := FileAccess.open(EmProps.RULES_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	if band_backup != "":
		var bf := FileAccess.open(EmPlinths.STANDING_RULES, FileAccess.WRITE)
		bf.store_string(band_backup)
		bf.close()
	get_root().remove_child(inst)
	inst.queue_free()

	if fails.is_empty():
		print("PROP WALL RULES: PASS — %d tokens hung, hand rule round-trips, gate holds" % want)
	else:
		print("PROP WALL RULES: FAIL %d" % fails.size())
		for f2 in fails:
			print("  - " + f2)
	quit(0 if fails.is_empty() else 1)
