extends Node
## The live launcher (2026-09-10): runs a Waves/Chance/Noise probe under PROJECT
## STARTUP instead of `--script`, so every autoload the project declares exists
## and scripts that name one (XR Tools' pickable, grab_sphere) compile. The
## probe itself is a Node script generated from the SceneTree original by
## tools/port_wcn_probes_live.py.
##
##   godot --path . --xr-mode off --rendering-method gl_compatibility --position 4000,4000 \
##         --log-file <log> res://commons/testing/probe_live.tscn -- --probe=intro --capture
##
## --probe=<intro|random_definition|noise_pair|pendulum|sine_space>. Everything
## after `--` reaches the probe through OS.get_cmdline_user_args() as before.
func _ready() -> void:
	var name := ""
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--probe="):
			name = str(a).get_slice("=", 1)
	if name.is_empty():
		push_error("probe_live: pass --probe=<name> after --")
		get_tree().quit(3)
		return
	var path := "res://commons/testing/probe_wcn_%s_live.gd" % name
	var script: GDScript = load(path)
	if script == null:
		push_error("probe_live: no such probe " + path)
		get_tree().quit(3)
		return
	# the autoloads are up: record it, so a report can say which startup it ran under
	var seen: Array = []
	for n in ["TextManager", "GameManager", "XRToolsUserSettings", "MapProgressionManager"]:
		if get_tree().root.get_node_or_null(n) != null: seen.append(n)
	print("[probe_live] autoloads present: ", seen)
	var probe: Node = script.new()
	probe.name = "Probe_" + name
	probe.set_meta("autoloads_present", seen)
	add_child(probe)
