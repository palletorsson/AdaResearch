extends SceneTree
## COLLATION fold logic, held headless against the REAL map_tool_editor.gd
## (2026-08-23, the spin + custom-bind pass): rotation-agnostic run keys, the
## spin classifier (uniform per-member turn), bound+spin composition, and the
## token rotation surgery. Pure-function calls on a bare instance — no editor,
## no scene, no map touched.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_collation_fold.gd

const OUT := "res://ada_run/collation_fold_probe.txt"

func _initialize() -> void:
	var fails: Array = []
	var ed: Node = (load("res://commons/scenes/map_tool_editor.gd") as GDScript).new()

	# 1. run key ignores rotation, keeps name + y-offset
	if ed.call("_fold_key", "laser_measure:90") != ed.call("_fold_key", "laser_measure:180"):
		fails.append("fold_key: rotation should not split a run")
	if ed.call("_fold_key", "laser_measure:90") == ed.call("_fold_key", "draw_dot:90"):
		fails.append("fold_key: different names must split")
	if ed.call("_fold_key", "laser_measure:0:0.5") == ed.call("_fold_key", "laser_measure:0:1.0"):
		fails.append("fold_key: different y-offsets must split")

	# 2. pure spin run: three lasers fanning 45° apiece
	var f1: Dictionary = ed.call("_col_classify", ["laser_measure:0", "laser_measure:45", "laser_measure:90"])
	if str(f1.get("mode")) != "plain" or int(f1.get("spin", 0)) != 45:
		fails.append("spin run misread: %s" % str(f1))

	# 3. non-uniform rotations refuse the fold
	var f2: Dictionary = ed.call("_col_classify", ["laser_measure:0", "laser_measure:90", "laser_measure:45"])
	if str(f2.get("mode")) != "none":
		fails.append("non-uniform spin folded: %s" % str(f2))

	# 4. bound + spin ride together (draw_dot inks fanning 90° apiece)
	var f3: Dictionary = ed.call("_col_classify",
		["draw_dot:0#ink:cyan", "draw_dot:90#ink:amber", "draw_dot:180#ink:lime"])
	if str(f3.get("mode")) != "bound" or str(f3.get("axis")) != "ink" \
			or int(f3.get("spin", 0)) != 90 or str((f3.get("values", []) as Array)) != str(["cyan", "amber", "lime"]):
		fails.append("bound+spin misread: %s" % str(f3))

	# 5. identical run stays plain with no spin
	var f4: Dictionary = ed.call("_col_classify", ["draw_dot:0#ink:cyan", "draw_dot:0#ink:cyan"])
	if str(f4.get("mode")) != "plain" or int(f4.get("spin", 0)) != 0:
		fails.append("plain run misread: %s" % str(f4))

	# 6. token rotation surgery: wraps at 360, preserves config + y, births a
	# rot field on a bare name, leaves clusters alone
	if str(ed.call("_tok_add_rot", "laser_measure:270#claim:datum", 90)) != "laser_measure:0#claim:datum":
		fails.append("add_rot wrap: %s" % str(ed.call("_tok_add_rot", "laser_measure:270#claim:datum", 90)))
	if str(ed.call("_tok_add_rot", "draw_dot", 45)) != "draw_dot:45":
		fails.append("add_rot bare: %s" % str(ed.call("_tok_add_rot", "draw_dot", 45)))
	if str(ed.call("_tok_add_rot", "laser_measure:90:0.5", 90)) != "laser_measure:180:0.5":
		fails.append("add_rot y-offset: %s" % str(ed.call("_tok_add_rot", "laser_measure:90:0.5", 90)))
	if str(ed.call("_tok_add_rot", "cluster:bench:90", 90)) != "cluster:bench:90":
		fails.append("add_rot must leave clusters alone")

	# 7. custom-bind values reach the token like any bound axis
	if str(ed.call("_tok_set_config", "draw_dot:0", "grain", "coarse")) != "draw_dot:0#grain:coarse":
		fails.append("set_config custom key: %s" % str(ed.call("_tok_set_config", "draw_dot:0", "grain", "coarse")))

	ed.free()
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(PackedStringArray(fails)))
	out.close()
	print("COLLATION FOLD: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(PackedStringArray(fails))))
	quit(0 if fails.is_empty() else 1)
