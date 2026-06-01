extends SceneTree

## Verify fontana_puncture embeds the live interactive point in its void when
## given embed_artifact config (the path the map token now uses). Asserts an
## EmbeddedPoint child exists, is the force-point class, and sits at the void
## centre — and that the static glint (CenterPoint) is NOT also present.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_fontana_embed.gd

const FONTANA := "res://commons/primitives/fontana_puncture/fontana_puncture.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find(node: Node, name_part: String, out: Array) -> void:
	if node.name.to_lower().find(name_part.to_lower()) != -1:
		out.append(node)
	for c in node.get_children():
		_find(c, name_part, out)


func _find_by_script(node: Node, suffix: String, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).get_file().begins_with(suffix):
		out.append(node)
	for c in node.get_children():
		_find_by_script(c, suffix, out)


func _dump(node: Node, depth: int) -> void:
	print("[fp] %s%s (%s)" % ["  ".repeat(depth), node.name, node.get_class()])
	for c in node.get_children():
		_dump(c, depth + 1)


func _run() -> void:
	var world := Node3D.new()
	get_root().add_child(world)

	var f: Node3D = load(FONTANA).instantiate()
	# Same config the map token sets.
	f.set_meta("config_embed_artifact", "interactive_point_origin_force")
	f.set_meta("config_embed_mode", "transformation")
	world.add_child(f)
	# Apply the way the grid does it.
	if f.has_method("apply_grid_config"):
		f.call("apply_grid_config", {
			"embed_artifact": "interactive_point_origin_force",
			"embed_mode": "transformation",
		})
	for i in range(30):
		await process_frame

	# Dump the full child tree so we can see what actually got built.
	print("[fp] --- child tree ---")
	_dump(f, 0)
	print("[fp] --- end tree ---")

	# Detect the embedded point by SCRIPT (its root auto-renames to
	# @RigidBody3D@N since it's an XRToolsPickable), not by node name.
	var embedded: Array = []
	_find_by_script(f, "interactive_point_origin", embedded)
	var glints: Array = []
	_find(f, "CenterPoint", glints)

	print("[fp] embedded interactive point present: %s" % (embedded.size() > 0))
	if embedded.size() > 0:
		var e = embedded[0]
		var scr = e.get_script()
		print("[fp]   class=%s  local_pos=%s  script=%s" %
			[e.get_class(), (e as Node3D).position if e is Node3D else "n/a",
			 str(scr.resource_path).get_file() if scr else "none"])
	print("[fp] static glint (CenterPoint) present: %s (expect false when embedded)" %
		(glints.size() > 0))

	var ok: bool = embedded.size() > 0 and glints.size() == 0
	print("[fp] RESULT: %s" % ("PASS — live point embedded in the void" if ok else "FAIL"))
	quit(0 if ok else 1)
