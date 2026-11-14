extends SceneTree
## Runs a probe script given by path (a scratch copy of an older commons/testing/probe_stickers.gd, its OUT pointed at a
## scratch folder) as the root's child, as its .tscn would: to read an older set of checks against the code as it is.
## The caller redirects APPDATA (user:// is then not the real one) and sets VOID_EDITOR_URL to a dead port.
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/stickers_fix2_runold.gd -- \
##     --probe=<path of the probe copy> --no-bridges

func _initialize() -> void:
	var path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--probe="):
			path = a.substr(a.find("=") + 1)
	var script: Script = load(path) if path != "" else null
	if script == null:
		push_error("stickers_fix2_runold: no probe script at '%s'" % path)
		quit(2)
		return
	var n := Node3D.new()
	n.name = "ProbeStickers"
	n.set_script(script)
	root.add_child.call_deferred(n)
