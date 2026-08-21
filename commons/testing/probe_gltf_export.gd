extends SceneTree
## Can the corpus export to glTF? Four danger classes, one boot:
##   roughrock          — plain procedural mesh (the safe case)
##   matrix_4x4_viewer  — the heavyweight (205k verts, 1000 meshes)
##   science_screen     — SubViewport texture + shaders (the visual risk)
##   laser_measure      — MultiMesh ruler (the structural risk)
## Writes .glb files + a verdict JSON with sizes and node/mesh survival.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_gltf_export.gd

const TOKENS := {
	"roughrock": "",
	"matrix_4x4_viewer": "",
	"science_screen": "",
	"laser_measure": "",
}
const OUT_DIR := "res://ada_run/gltf_probe"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# resolve scenes from the registry
	var reg: Dictionary = {}
	var dir := DirAccess.open("res://commons/artifacts/registry")
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/" + f))
		if not (v is Dictionary):
			continue
		var arts_v: Variant = (v as Dictionary).get("artifacts", v)
		if not (arts_v is Dictionary):
			continue
		for tok in TOKENS:
			if not reg.has(tok) and (arts_v as Dictionary).has(tok):
				var e: Dictionary = (arts_v as Dictionary)[tok]
				var sp := String(e.get("scene_path", e.get("scene", "")))
				if sp != "":
					reg[tok] = sp
	var report: Array = []
	for tok in TOKENS:
		var path: String = reg.get(tok, "")
		if path == "" or not ResourceLoader.exists(path):
			report.append({"token": tok, "why": "no scene"})
			continue
		var inst: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		get_root().add_child(inst)
		await create_timer(0.5).timeout   # the 0.35 s settle law, with margin
		var t0 := Time.get_ticks_msec()
		var gdoc := GLTFDocument.new()
		var gstate := GLTFState.new()
		var err := gdoc.append_from_scene(inst, gstate)
		var out_path: String = OUT_DIR + "/" + tok + ".glb"
		if err == OK:
			err = gdoc.write_to_filesystem(gstate, out_path)
		var ms := Time.get_ticks_msec() - t0
		var size: int = 0
		if FileAccess.file_exists(out_path):
			var f2 := FileAccess.open(out_path, FileAccess.READ)
			size = f2.get_length()
			f2.close()
		# what survived: count meshes in the source vs meshes in the gltf state
		var src := {"meshes": 0, "mmesh": 0, "verts": 0}
		_count(inst, src)
		report.append({"token": tok, "err": err, "ms": ms, "glb_kb": size / 1024,
			"src_meshes": src["meshes"], "src_multimesh": src["mmesh"], "src_verts": src["verts"],
			"gltf_meshes": gstate.meshes.size(), "gltf_nodes": gstate.nodes.size()})
		inst.queue_free()
		await process_frame
	var f := FileAccess.open(OUT_DIR + "/verdict.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, " "))
	f.close()
	print(JSON.stringify(report))
	quit(0)


func _count(n: Node, c: Dictionary) -> void:
	if n is MeshInstance3D:
		c["meshes"] += 1
		var m: Mesh = (n as MeshInstance3D).mesh
		if m != null:
			for s in range(m.get_surface_count()):
				var arr: Array = m.surface_get_arrays(s)
				if arr.size() > Mesh.ARRAY_VERTEX and arr[Mesh.ARRAY_VERTEX] != null:
					c["verts"] += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	elif n is MultiMeshInstance3D:
		c["mmesh"] += 1
	for ch in n.get_children():
		_count(ch, c)
