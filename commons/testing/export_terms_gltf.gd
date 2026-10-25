extends SceneTree
## Export the grammar's terms AS GODOT BUILDS THEM, to .glb (Palle, 25 Oct: "we can load the glbs
## from godot instead of three?"). A viewer then shows Godot's own geometry, not a re-implementation.
## Every MeshInstance3D is renamed "o<NNN>_<name>" in the tree's order — the order the builder made
## them — so a viewer can play the construction from the file alone. Scaffold parts are already gone
## (composite.gd frees them after the build): the file is the finished thing.
##
##   godot --path . --xr-mode off --script res://commons/testing/export_terms_gltf.gd -- --out=<dir> [--terms=a,b,c]
## Writes <out>/mod_<term>.glb and <out>/mod_terms_manifest.json. Windowed, as the capture tools are.

const COMPOSITE := "res://commons/modular/composite.tscn"
const TERMS := "res://commons/modular/terms.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := ""
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--terms="):
			only = a.trim_prefix("--terms=").split(",", false)
	if out == "":
		print("EXPORT_TERMS needs --out=<dir>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERMS))
	var ids: Array = Array(only) if only.size() > 0 else (doc["terms"] as Dictionary).keys()
	var manifest := {}
	var scene: PackedScene = load(COMPOSITE)
	for id in ids:
		var term := str(id)
		if term.find("handmade_pallet") >= 0 or not (doc["terms"] as Dictionary).has(term):
			continue
		var inst: Node3D = scene.instantiate()
		inst.set("term", term)
		root.add_child(inst)
		await process_frame
		await process_frame
		inst.process_mode = Node.PROCESS_MODE_DISABLED   # built: hold it still, physics would move it
		var n := 0
		for mi in _meshes(inst):
			mi.name = "o%03d_%s" % [n, mi.name]
			n += 1
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		var err := gltf.append_from_scene(inst, state)
		var path := "%s/mod_%s.glb" % [out, term]
		if err == OK:
			err = gltf.write_to_filesystem(state, path)
		manifest[term] = {"ok": err == OK, "meshes": n}
		print("EXPORT_TERMS %s %s meshes=%d" % [term, "ok" if err == OK else "error %d" % err, n])
		inst.queue_free()
		await process_frame
	var f := FileAccess.open(out + "/mod_terms_manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, " "))
	f.close()
	print("EXPORT_TERMS done %d terms" % manifest.size())
	quit(0)


func _meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out
