extends SceneTree
## BAKE THE CONTACT FRAMES. tools/contact_forms.py marches two bodies meeting, made four ways, into
## ada_run/contact_forms/<name>.bin (format ISO2, vertex colour as data: r = how much of body A, g = a face the cut
## made, b = the join's band, a = ambient occlusion). This turns them into what the game loads: frames/<name>.res,
## one ArrayMesh each, simplified by the engine's own meshoptimizer to its triangle budget, with distance LODs, and
## frames/index.json, the order of the frames and the gap each stands for.
##
##   python tools/contact_forms.py
##   godot --headless --path . --xr-mode off --script res://commons/artifacts/contact_study/bake_frames.gd
##
## The meshes are derived: run both steps again after a change to a body or to the reach of the join.
const SOURCE := "res://ada_run/contact_forms/"
const TARGET := "res://commons/artifacts/contact_study/frames/"


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE + "manifest.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET))
	# --only=within: that one part again, the rest of the index kept as it is
	if OS.get_cmdline_user_args().has("--only=within"):
		var kept: Variant = JSON.parse_string(FileAccess.get_file_as_string(TARGET + "index.json"))
		if kept is Dictionary and manifest.has("within"):
			kept["bytes"] = int(kept.get("bytes", 0)) - int((kept.get("within", {}) as Dictionary).get("bytes", 0))
			kept["within"] = _within(manifest.within)
			kept["bytes"] = int(kept.bytes) + int(kept.within.bytes)
			_write(kept)
		quit()
		return
	var index := {"k": manifest.k, "cell": manifest.cell, "lean_degrees": manifest.lean_degrees, "a_at": manifest.a_at,
		"b_at_contact": manifest.b_at_contact, "parts": {}, "frames": {}}
	var total := 0
	for part: String in manifest.parts:
		var made := _bake(part, int(manifest.parts[part].get("budget", 0)))
		index.parts[part] = made
		total += int(made.bytes)
		print("[bake_frames] ", part, " ", JSON.stringify(made))
	for strategy: String in manifest.frames:
		var rows := []
		for row: Dictionary in manifest.frames[strategy]:
			var made := _bake(str(row.file), int(row.get("budget", 0)))
			made["gap"] = row.gap
			made["file"] = row.file
			for key in ["pieces", "handles"]:
				if row.has(key): made[key] = int(row[key])
			if row.has("centre"): made["centre"] = row.centre
			rows.append(made)
			total += int(made.bytes)
			print("[bake_frames] ", row.file, " ", JSON.stringify(made))
		index.frames[strategy] = rows
	# the field: one version for a place on its floor; and what the bake found out about that floor
	if manifest.has("field"):
		var places := []
		for row: Dictionary in manifest.field:
			var made := _bake(str(row.file), int(row.get("budget", 0)))
			for key in ["file", "x", "z", "reach", "gap"]: made[key] = row[key]
			for key in ["pieces", "handles"]: made[key] = int(row[key])
			places.append(made)
			total += int(made.bytes)
			print("[bake_frames] ", row.file, " ", JSON.stringify(made))
		index["field"] = places
	for key in ["inside", "lines", "field_rule", "states"]:
		if manifest.has(key): index[key] = manifest[key]
	# the heads as a room: one mesh, and what the tool measured of it
	if manifest.has("within"):
		index["within"] = _within(manifest.within)
		total += int(index.within.bytes)
	index["bytes"] = total
	_write(index)
	print("[bake_frames] ", total, " bytes in all")
	quit()


func _within(row: Dictionary) -> Dictionary:
	var made := _bake(str(row.file), int(row.get("budget", 0)))
	for key: String in row:
		if not made.has(key): made[key] = row[key]
	print("[bake_frames] ", row.file, " ", JSON.stringify({"triangles": made.triangles, "bytes": made.bytes}))
	return made


func _write(index: Dictionary) -> void:
	var file := FileAccess.open(TARGET + "index.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(index, "\t", false))
	file.close()


func _bake(name: String, budget: int) -> Dictionary:
	var f := FileAccess.open(SOURCE + name + ".bin", FileAccess.READ)
	if f == null or f.get_buffer(4).get_string_from_ascii() != "ISO2": return {"error": "no bin", "bytes": 0}
	var nv := f.get_32()
	var ni := f.get_32()
	f.get_32(); f.get_32()
	var pos := f.get_buffer(nv * 12).to_float32_array()
	var nrm := f.get_buffer(nv * 12).to_float32_array()
	var col := f.get_buffer(nv * 16).to_float32_array()
	var idx := f.get_buffer(ni * 4).to_int32_array()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	verts.resize(nv); normals.resize(nv); colours.resize(nv)
	for i in nv:
		verts[i] = Vector3(pos[3 * i], pos[3 * i + 1], pos[3 * i + 2])
		normals[i] = Vector3(nrm[3 * i], nrm[3 * i + 1], nrm[3 * i + 2])
		colours[i] = Color(col[4 * i], col[4 * i + 1], col[4 * i + 2], col[4 * i + 3])
	# the bench winds each face counter-clockwise seen from outside; Godot's front faces are clockwise
	for t in ni / 3:
		var keep := idx[3 * t + 1]
		idx[3 * t + 1] = idx[3 * t + 2]
		idx[3 * t + 2] = keep
	var arrays := _simplify(verts, normals, colours, idx, budget)
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if budget > 0: im.generate_lods(25.0, 60.0, [])
	var mesh: ArrayMesh = im.get_mesh()
	mesh.resource_name = name
	var path := TARGET + name + ".res"
	var err := ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
	return {"triangles_marched": ni / 3, "triangles": int((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3),
		"bytes": FileAccess.get_file_as_bytes(path).size(), "saved": err == OK}


## The first of the engine's own simplifications with no more than `budget` triangles, its vertices compacted
## (as commons/artifacts/iso_prefabs/bake_forms.gd does). A budget of 0 keeps the mesh as marched.
func _simplify(verts: PackedVector3Array, normals: PackedVector3Array, colours: PackedColorArray, idx: PackedInt32Array, budget: int) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = idx
	if budget <= 0 or idx.size() / 3 <= budget: return arrays
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	im.generate_lods(25.0, 60.0, [])
	var out: Array = im.get_surface_arrays(0)
	var best: PackedInt32Array = out[Mesh.ARRAY_INDEX]
	for l in im.get_surface_lod_count(0):
		var lod := im.get_surface_lod_indices(0, l)
		best = lod
		if lod.size() / 3 <= budget: break
	var remap := {}
	var v2 := PackedVector3Array()
	var n2 := PackedVector3Array()
	var c2 := PackedColorArray()
	var i2 := PackedInt32Array()
	var ov: PackedVector3Array = out[Mesh.ARRAY_VERTEX]
	var on: PackedVector3Array = out[Mesh.ARRAY_NORMAL]
	var oc: PackedColorArray = out[Mesh.ARRAY_COLOR]
	i2.resize(best.size())
	for k in best.size():
		var v: int = best[k]
		if not remap.has(v):
			remap[v] = v2.size()
			v2.append(ov[v])
			n2.append(on[v])
			c2.append(oc[v])
		i2[k] = remap[v]
	var compact := []
	compact.resize(Mesh.ARRAY_MAX)
	compact[Mesh.ARRAY_VERTEX] = v2
	compact[Mesh.ARRAY_NORMAL] = n2
	compact[Mesh.ARRAY_COLOR] = c2
	compact[Mesh.ARRAY_INDEX] = i2
	return compact
