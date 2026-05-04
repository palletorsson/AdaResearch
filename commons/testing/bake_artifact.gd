extends SceneTree

## Bake any artifact-wrapper scene to a PackedScene.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/bake_artifact.gd -- \
##     --scene=<artifact.tscn> \
##     --apply-config='{"config_path": "res://commons/generated/gallery_best_of/configs/lsystem-gallery__ls21_cpfg_weeping_plant.json"}' \
##     --out=res://commons/generated/gallery_best_of/scenes/<gallery>__<entry>.tscn \
##     --wait=2
##
## What it does:
##   1. Instantiate the artifact scene (e.g. lsystem_artifact.tscn)
##   2. Add it to the scene tree
##   3. Call apply_grid_config with the supplied parameters
##   4. Wait for build to settle (--wait seconds, default 2)
##   5. Pack the resulting Node3D as a PackedScene and save to --out
##
## The output .tscn carries all the built geometry inline. Loading it via
## prebaked_loader is instant — the grammar's Sim.build doesn't run again.
##
## Use vr_preview=false in apply_config to bake at full fidelity (the live
## wrappers default to vr_preview=true; we want the high-quality version
## saved, not the preview-quality version).

var _scene_path: String = ""
var _apply_config: Dictionary = {}
var _out_path: String = ""
var _wait: float = 2.0


func _initialize() -> void:
	_parse_args()
	if _scene_path.is_empty() or _out_path.is_empty():
		push_error("bake_artifact: --scene= and --out= required")
		quit(1); return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"): continue
		var eq := a.find("=")
		if eq <= 2: continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"scene":   _scene_path = val
			"out":     _out_path = val
			"wait":    if val.is_valid_float(): _wait = float(val)
			"apply-config":
				var j := JSON.new()
				if j.parse(val) == OK and j.data is Dictionary:
					_apply_config = j.data


func _run() -> void:
	if not ResourceLoader.exists(_scene_path):
		push_error("bake_artifact: scene not found: %s" % _scene_path)
		quit(1); return
	var ps := load(_scene_path)
	if not (ps is PackedScene):
		push_error("bake_artifact: not a PackedScene: %s" % _scene_path)
		quit(1); return

	var inst: Node = (ps as PackedScene).instantiate()
	root.add_child(inst)
	if inst.has_method("apply_grid_config"):
		inst.apply_grid_config(_apply_config)
	else:
		push_warning("bake_artifact: scene has no apply_grid_config — config ignored")

	# Settle: wait for the build to finish (mesh ops, RD sim, etc.).
	await create_timer(maxf(_wait, 0.1)).timeout
	await process_frame
	await process_frame

	# Re-parent: PackedScene.pack only works on a node whose entire subtree
	# has the SAME owner. We set owner recursively here so all generated
	# children get serialized.
	_set_owner_recursive(inst, inst)

	var packed := PackedScene.new()
	var err := packed.pack(inst)
	if err != OK:
		push_error("bake_artifact: PackedScene.pack failed (err=%d)" % err)
		quit(2); return

	var save_err := ResourceSaver.save(packed, _out_path)
	if save_err != OK:
		push_error("bake_artifact: ResourceSaver.save failed (err=%d) for %s" % [save_err, _out_path])
		quit(3); return

	var node_count := _count_descendants(inst)
	print("bake_artifact: OK saved %s  (%d descendant nodes)" % [_out_path, node_count])
	quit(0)


func _set_owner_recursive(node: Node, root_node: Node) -> void:
	for c in node.get_children():
		c.owner = root_node
		_set_owner_recursive(c, root_node)


func _count_descendants(node: Node) -> int:
	var n := 0
	var stack: Array = [node]
	while not stack.is_empty():
		var cur = stack.pop_back()
		for c in cur.get_children():
			n += 1
			stack.append(c)
	return n
