extends SceneTree
## The artifact's OWN config, ruled by hand.
## BITE: C on a body that declares a DNA axis cycles its value, writes
##   `config` on the ruling, previews it on the node, and autosaves.
## GATE: C on a singleton says so and writes nothing.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_config_edit.gd
const P := "res://ada_run/_trial_em_overrides_cfg.json"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	if FileAccess.file_exists(P): DirAccess.remove_absolute(ProjectSettings.globalize_path(P))
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_overrides_path", P)
	m.set("_edit_mode", true)
	get_root().add_child(m)
	await create_timer(1.5).timeout
	var recs: Array = m.get("_edit_records")
	var with_axis := -1
	var without := -1
	for i in range(recs.size()):
		var rd: Dictionary = recs[i]
		if String(rd.get("kind", "artifact")) not in ["artifact", ""]: continue
		var ax: Dictionary = m.call("_axes_for", String(rd.get("token", "")))
		if ax.is_empty():
			if without < 0: without = i
		elif with_axis < 0:
			with_axis = i
	if with_axis < 0: print("EM CONFIG: SKIP — no placed body declares an axis"); quit(0); return
	# BITE
	m.set("_edit_sel", with_axis)
	var tok := String((recs[with_axis] as Dictionary).get("token", ""))
	var axes: Dictionary = m.call("_axes_for", tok)
	var axis := String(axes.keys()[0])
	m.call("_edit_handle_key", KEY_C)
	await create_timer(1.2).timeout
	var ovs: Array = m.get("_edit_overrides")
	var found: Dictionary = {}
	for o in ovs:
		if String((o as Dictionary).get("token", "")) == tok and (o as Dictionary).get("config") is Dictionary:
			found = o
	if found.is_empty():
		fails.append("BITE: C wrote no config ruling for %s" % tok)
	else:
		var cfg: Dictionary = found["config"]
		if not cfg.has(axis): fails.append("BITE: the ruling has no value for %s (%s)" % [axis, str(cfg)])
		else:
			var vals: Array = axes[axis]
			if not vals.has(String(cfg[axis])): fails.append("BITE: %s is not a declared value of %s" % [str(cfg[axis]), axis])
		var node: Node3D = (recs[with_axis] as Dictionary).get("node") as Node3D
		if node != null and is_instance_valid(node) and not node.has_meta("config_" + axis):
			fails.append("BITE: the body was not reconfigured (no config_%s meta)" % axis)
	if not FileAccess.file_exists(P):
		fails.append("BITE: the config ruling did not autosave")
	# GATE
	if without >= 0:
		m.set("_edit_sel", without)
		var before: int = (m.get("_edit_overrides") as Array).size()
		m.call("_edit_handle_key", KEY_C)
		await create_timer(0.3).timeout
		if (m.get("_edit_overrides") as Array).size() != before:
			fails.append("GATE: C on a singleton wrote a ruling")
	get_root().remove_child(m); m.queue_free()
	if FileAccess.file_exists(P): DirAccess.remove_absolute(ProjectSettings.globalize_path(P))
	if fails.is_empty(): print("EM CONFIG: PASS — C cycles a declared axis, rules `config`, previews it, autosaves; a singleton is refused")
	else:
		print("EM CONFIG: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
